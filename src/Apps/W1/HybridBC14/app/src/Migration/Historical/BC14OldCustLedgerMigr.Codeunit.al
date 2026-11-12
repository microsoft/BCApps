// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration.BC14Reimplementation.HistoricalData;
using Microsoft.Sales.Receivables;

codeunit 46940 "BC14 Old Cust. Ledger Migr." implements "BC14 Migrator"
{
    trigger OnRun()
    begin
        TransferData();
    end;

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";
        MigratorNameLbl: Label 'Old Customer Ledger Entry Migrator';
        TransferCompletedLbl: Label 'Old Customer Ledger Entry archive transfer completed. Entries: %1', Locked = true, Comment = '%1 = Entry count';
        TransferFailedLbl: Label 'Old Customer Ledger Entry archive transfer failed. Error: %1. CallStack: %2', Locked = true, Comment = '%1 = Error text, %2 = Call stack';
        EntryTransferOverriddenLbl: Label 'Old Customer Ledger Entry transfer was overridden by an extension.', Locked = true;
        TransferResumedLbl: Label 'Old Customer Ledger Entry archive transfer resuming after entry no. %1.', Locked = true, Comment = '%1 = Last archived entry number';
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
        // The same source-to-buffer mappings are also registered by the Transaction-phase customer
        // ledger migrator. CreateReplicationMapping is idempotent on the source/destination pair, so
        // registering them here too keeps this migrator self-contained -- the historical archive still
        // works if the Transaction migrator is ever disabled.
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Cust. Ledger Entry", Database::"BC14 Cust. Ledger Entry");
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Detailed Cust. Ledg. Entry", Database::"BC14 Detailed Cust. LE");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
    begin
        if not BC14CompanySettings.GetReceivablesModuleEnabled() then
            exit(false);

        // No cutoff configured => the transaction phase re-creates every open entry in the live
        // subledger and there is nothing for the read-only archive to add. Skipping keeps the
        // legacy single-ledger experience intact.
        if BC14CompanySettings.GetHistoricalCutoffDate() = 0D then
            exit(false);

        exit(not BC14CustLedgerEntry.IsEmpty());
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14OldCustLedgEntry: Record "BC14 Old Cust. Ledg. Entry";
        TotalCount: Integer;
    begin
        ApplyCutoffFilter(BC14CustLedgerEntry);
        TotalCount := BC14CustLedgerEntry.Count();
        if TotalCount = 0 then
            exit(0);
        exit(Round((TotalCount - BC14OldCustLedgEntry.Count()) / TotalCount * 100, 1));
    end;

    procedure Migrate(): Boolean
    var
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        EmptyRecId: RecordId;
        EntryCount: Integer;
        IsMigrated: Boolean;
        FailureMessage: Text;
        FailureCallStack: Text;
    begin
        IsMigrated := false;
        OnMigrateOldCustLedgerEntries(IsMigrated);
        if IsMigrated then
            exit(true);

        ApplyCutoffFilter(BC14CustLedgerEntry);
        EntryCount := BC14CustLedgerEntry.Count();

        Commit();

        if not Codeunit.Run(Codeunit::"BC14 Old Cust. Ledger Migr.") then begin
            FailureMessage := GetLastErrorText();
            FailureCallStack := GetLastErrorCallStack();
            Session.LogMessage('0000TXS', StrSubstNo(TransferFailedLbl, FailureMessage, FailureCallStack), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14MigrationErrorHandler.LogError(MigratorNameLbl, Database::"BC14 Cust. Ledger Entry", 'BC14 Cust. Ledger Entry', '', Database::"BC14 Old Cust. Ledg. Entry", FailureMessage, EmptyRecId);
            OnAfterMigrateOldCustLedgerEntries(false);
            exit(false);
        end;

        Session.LogMessage('0000TXT', StrSubstNo(TransferCompletedLbl, EntryCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        BC14MigrationErrorHandler.ResolveErrorForRecord(Database::"BC14 Cust. Ledger Entry", '');

        OnAfterMigrateOldCustLedgerEntries(true);

        exit(true);
    end;

    local procedure TransferData()
    var
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
        EntryDataTransfer: DataTransfer;
        CutoffDate: Date;
        LastArchivedEntryNo: Integer;
        IsConfigured: Boolean;
    begin
        OnConfigureEntryDataTransfer(EntryDataTransfer, IsConfigured);
        if IsConfigured then begin
            Session.LogMessage('0000TXU', EntryTransferOverriddenLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            EntryDataTransfer.CopyRows();
            exit;
        end;

        CutoffDate := BC14CompanyInfo.GetHistoricalCutoffDate();

        LastArchivedEntryNo := GetLastArchivedEntryNo();
        if LastArchivedEntryNo > 0 then
            Session.LogMessage('0000TXV', StrSubstNo(TransferResumedLbl, LastArchivedEntryNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // DataTransfer.CopyRows() is only permitted inside platform upgrade/install codeunits. This
        // migration always runs as a background task/session (never an upgrade codeunit), so calling
        // CopyRows() here would always throw "DataTransfer is only usable during upgrade or install".
        // The archive also needs per-entry remaining/ledger amounts summed from the detailed buffer,
        // which a flat CopyRows cannot compute. Always use the per-record batched copy; the
        // OnConfigureEntryDataTransfer override above still lets an upgrade-context caller opt in.
        TransferDataInBatches(CutoffDate, LastArchivedEntryNo);
    end;

    local procedure TransferDataInBatches(CutoffDate: Date; LastArchivedEntryNo: Integer)
    var
        BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry";
        BC14OldCustLedgEntry: Record "BC14 Old Cust. Ledg. Entry";
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

        BC14CustLedgerEntry.SetCurrentKey("Entry No.");
        BC14CustLedgerEntry.SetFilter("Posting Date", '<%1', CutoffDate);
        if LastArchivedEntryNo > 0 then
            BC14CustLedgerEntry.SetFilter("Entry No.", '>%1', LastArchivedEntryNo);
        if not BC14CustLedgerEntry.FindSet() then
            exit;
        repeat
            BC14OldCustLedgEntry.Init();
            BC14OldCustLedgEntry.TransferFields(BC14CustLedgerEntry, true);
            BC14OldCustLedgEntry.Amount := CalcLedgerEntryAmount(BC14CustLedgerEntry."Entry No.");
            BC14OldCustLedgEntry."Remaining Amount" := CalcRemainingAmount(BC14CustLedgerEntry."Entry No.");
            BC14OldCustLedgEntry."Migrated On" := MigratedOn;
            BC14OldCustLedgEntry.Insert(false);
            RowsSinceCommit += 1;

            if (RowsSinceCommit >= MaxBatchSize) or ((CurrentDateTime() - LastCommitAt) >= CommitIntervalMs) then begin
                Commit();
                RowsSinceCommit := 0;
                LastCommitAt := CurrentDateTime();
            end;
        until BC14CustLedgerEntry.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    /// <summary>
    /// Sums the total ledger entry amount from the detailed buffer, mirroring the "Amount" FlowField
    /// on "Cust. Ledger Entry" (detailed entries flagged as the ledger entry amount).
    /// </summary>
    local procedure CalcLedgerEntryAmount(CustLedgerEntryNo: Integer): Decimal
    var
        BC14DetailedCustLE: Record "BC14 Detailed Cust. LE";
    begin
        BC14DetailedCustLE.SetCurrentKey("Cust. Ledger Entry No.");
        BC14DetailedCustLE.SetRange("Cust. Ledger Entry No.", CustLedgerEntryNo);
        BC14DetailedCustLE.SetRange("Ledger Entry Amount", true);
        BC14DetailedCustLE.CalcSums(Amount);
        exit(BC14DetailedCustLE.Amount);
    end;

    /// <summary>
    /// Sums the remaining amount from the detailed buffer. The sum of a customer ledger entry's
    /// detailed entries equals its outstanding (remaining) balance, mirroring the "Remaining Amount"
    /// FlowField on "Cust. Ledger Entry".
    /// </summary>
    local procedure CalcRemainingAmount(CustLedgerEntryNo: Integer): Decimal
    var
        BC14DetailedCustLE: Record "BC14 Detailed Cust. LE";
    begin
        BC14DetailedCustLE.SetCurrentKey("Cust. Ledger Entry No.");
        BC14DetailedCustLE.SetRange("Cust. Ledger Entry No.", CustLedgerEntryNo);
        BC14DetailedCustLE.CalcSums(Amount);
        exit(BC14DetailedCustLE.Amount);
    end;

    local procedure GetLastArchivedEntryNo(): Integer
    var
        BC14OldCustLedgEntry: Record "BC14 Old Cust. Ledg. Entry";
    begin
        BC14OldCustLedgEntry.SetCurrentKey("Entry No.");
        if BC14OldCustLedgEntry.FindLast() then
            exit(BC14OldCustLedgEntry."Entry No.");
        exit(0);
    end;

    /// <summary>
    /// Applies the same partitioning filter that <see cref="TransferData"/> uses, so progress and
    /// IsEnabled probes count only the rows that will actually be archived.
    /// </summary>
    local procedure ApplyCutoffFilter(var BC14CustLedgerEntry: Record "BC14 Cust. Ledger Entry")
    var
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
        CutoffDate: Date;
    begin
        CutoffDate := BC14CompanyInfo.GetHistoricalCutoffDate();
        if CutoffDate = 0D then
            exit;
        BC14CustLedgerEntry.SetFilter("Posting Date", '<%1', CutoffDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateOldCustLedgerEntries(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateOldCustLedgerEntries(MigratorSuccess: Boolean)
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
