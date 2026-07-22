// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration.BC14Reimplementation.HistoricalData;
using Microsoft.Inventory.Ledger;

codeunit 46947 "BC14 Old Item Ledger Migr." implements "BC14 Migrator"
{
    trigger OnRun()
    begin
        TransferData();
    end;

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";
        MigratorNameLbl: Label 'Old Item Ledger Entry Migrator';
        TransferCompletedLbl: Label 'Old Item Ledger Entry archive transfer completed. Entries: %1', Locked = true, Comment = '%1 = Entry count';
        TransferFailedLbl: Label 'Old Item Ledger Entry archive transfer failed. Error: %1. CallStack: %2', Locked = true, Comment = '%1 = Error text, %2 = Call stack';
        EntryTransferOverriddenLbl: Label 'Old Item Ledger Entry transfer was overridden by an extension.', Locked = true;
        TransferResumedLbl: Label 'Old Item Ledger Entry archive transfer resuming after entry no. %1.', Locked = true, Comment = '%1 = Last archived entry number';
        CommitIntervalMs: Integer;
        MaxBatchSize: Integer;

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // Item transactions are migrated read-only only: the entire item ledger (and the value
        // entries needed to compute each entry's actual cost) is archived for reference. Live
        // on-hand inventory is not re-created, so there is no Transaction-phase item migrator.
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Item Ledger Entry", Database::"BC14 Item Ledger Entry");
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Value Entry", Database::"BC14 Value Entry");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
    begin
        if not BC14CompanySettings.GetInventoryModuleEnabled() then
            exit(false);

        exit(not BC14ItemLedgerEntry.IsEmpty());
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14OldItemLedgEntry: Record "BC14 Old Item Ledg. Entry";
        TotalCount: Integer;
    begin
        TotalCount := BC14ItemLedgerEntry.Count();
        if TotalCount = 0 then
            exit(0);
        exit(Round((TotalCount - BC14OldItemLedgEntry.Count()) / TotalCount * 100, 1));
    end;

    procedure Migrate(): Boolean
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        EmptyRecId: RecordId;
        EntryCount: Integer;
        IsMigrated: Boolean;
        FailureMessage: Text;
        FailureCallStack: Text;
    begin
        IsMigrated := false;
        OnMigrateOldItemLedgerEntries(IsMigrated);
        if IsMigrated then
            exit(true);

        EntryCount := BC14ItemLedgerEntry.Count();

        Commit();

        if not Codeunit.Run(Codeunit::"BC14 Old Item Ledger Migr.") then begin
            FailureMessage := GetLastErrorText();
            FailureCallStack := GetLastErrorCallStack();
            Session.LogMessage('0000TY0', StrSubstNo(TransferFailedLbl, FailureMessage, FailureCallStack), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14MigrationErrorHandler.LogError(MigratorNameLbl, Database::"BC14 Item Ledger Entry", 'BC14 Item Ledger Entry', '', Database::"BC14 Old Item Ledg. Entry", FailureMessage, EmptyRecId);
            OnAfterMigrateOldItemLedgerEntries(false);
            exit(false);
        end;

        Session.LogMessage('0000TY1', StrSubstNo(TransferCompletedLbl, EntryCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        BC14MigrationErrorHandler.ResolveErrorForRecord(Database::"BC14 Item Ledger Entry", '');

        OnAfterMigrateOldItemLedgerEntries(true);

        exit(true);
    end;

    local procedure TransferData()
    var
        EntryDataTransfer: DataTransfer;
        LastArchivedEntryNo: Integer;
        IsConfigured: Boolean;
    begin
        OnConfigureEntryDataTransfer(EntryDataTransfer, IsConfigured);
        if IsConfigured then begin
            Session.LogMessage('0000TY2', EntryTransferOverriddenLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            EntryDataTransfer.CopyRows();
            exit;
        end;

        LastArchivedEntryNo := GetLastArchivedEntryNo();
        if LastArchivedEntryNo > 0 then
            Session.LogMessage('0000TY3', StrSubstNo(TransferResumedLbl, LastArchivedEntryNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // DataTransfer.CopyRows() is only permitted inside platform upgrade/install codeunits. This
        // migration always runs as a background task/session (never an upgrade codeunit), so calling
        // CopyRows() here would always throw "DataTransfer is only usable during upgrade or install".
        // The archive also needs a per-entry actual cost summed from the value entry buffer, which a
        // flat CopyRows cannot compute. Always use the per-record batched copy; the
        // OnConfigureEntryDataTransfer override above still lets an upgrade-context caller opt in.
        TransferDataInBatches(LastArchivedEntryNo);
    end;

    local procedure TransferDataInBatches(LastArchivedEntryNo: Integer)
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        BC14OldItemLedgEntry: Record "BC14 Old Item Ledg. Entry";
        MigratedOn: DateTime;
        LastCommitAt: DateTime;
        RowsSinceCommit: Integer;
    begin
        if CommitIntervalMs = 0 then
            CommitIntervalMs := 90000; // 1.5 minutes
        if MaxBatchSize = 0 then
            MaxBatchSize := 10000;

        MigratedOn := CurrentDateTime();
        LastCommitAt := CurrentDateTime();

        BC14ItemLedgerEntry.SetCurrentKey("Entry No.");
        if LastArchivedEntryNo > 0 then
            BC14ItemLedgerEntry.SetFilter("Entry No.", '>%1', LastArchivedEntryNo);
        if not BC14ItemLedgerEntry.FindSet() then
            exit;
        repeat
            BC14OldItemLedgEntry.Init();
            BC14OldItemLedgEntry.TransferFields(BC14ItemLedgerEntry, true);
            BC14OldItemLedgEntry."Cost Amount (Actual)" := CalcCostAmount(BC14ItemLedgerEntry."Entry No.");
            BC14OldItemLedgEntry."Migrated On" := MigratedOn;
            BC14OldItemLedgEntry.Insert(false);
            RowsSinceCommit += 1;

            if (RowsSinceCommit >= MaxBatchSize) or ((CurrentDateTime() - LastCommitAt) >= CommitIntervalMs) then begin
                Commit();
                RowsSinceCommit := 0;
                LastCommitAt := CurrentDateTime();
            end;
        until BC14ItemLedgerEntry.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    /// <summary>
    /// Sums the actual cost of an item ledger entry from its value entries, mirroring the
    /// "Cost Amount (Actual)" FlowField on "Item Ledger Entry".
    /// </summary>
    local procedure CalcCostAmount(ItemLedgerEntryNo: Integer): Decimal
    var
        BC14ValueEntry: Record "BC14 Value Entry";
    begin
        BC14ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        BC14ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        BC14ValueEntry.CalcSums("Cost Amount (Actual)");
        exit(BC14ValueEntry."Cost Amount (Actual)");
    end;

    local procedure GetLastArchivedEntryNo(): Integer
    var
        BC14OldItemLedgEntry: Record "BC14 Old Item Ledg. Entry";
    begin
        BC14OldItemLedgEntry.SetCurrentKey("Entry No.");
        if BC14OldItemLedgEntry.FindLast() then
            exit(BC14OldItemLedgEntry."Entry No.");
        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateOldItemLedgerEntries(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateOldItemLedgerEntries(MigratorSuccess: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before the framework transfers the entries.
    /// Subscribe to take over the transfer entirely: set IsConfigured to true, configure the
    /// DataTransfer yourself (SetTables / AddFieldValue / AddConstantValue / source filters),
    /// and the framework will call CopyRows on it for you. The default path uses a per-record
    /// Insert loop with platform-generated SystemId, so it is not subject to the DataTransfer
    /// pre-flight uniqueness check on source SystemId values.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnConfigureEntryDataTransfer(var EntryDataTransfer: DataTransfer; var IsConfigured: Boolean)
    begin
    end;
}
