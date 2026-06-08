// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration.BC14Reimplementation.HistoricalData;
using Microsoft.Finance.GeneralLedger.Ledger;

codeunit 46881 "BC14 Old G/L Entry Migr." implements "BC14 Migrator"
{
    trigger OnRun()
    begin
        TransferData();
    end;

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";
        MigratorNameLbl: Label 'Old G/L Entry Migrator';
        TransferCompletedLbl: Label 'Old G/L Entry archive transfer completed. Entries: %1', Locked = true, Comment = '%1 = Entry count';
        TransferFailedLbl: Label 'Old G/L Entry archive transfer failed. Error: %1. CallStack: %2', Locked = true, Comment = '%1 = Error text, %2 = Call stack';
        EntryTransferOverriddenLbl: Label 'Old G/L Entry transfer was overridden by an extension.', Locked = true;

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // The same source-to-buffer mapping is also registered by the Transaction-phase
        // G/L Entry migrator. CreateReplicationMapping is idempotent on the source/destination
        // pair, so registering it here too keeps this migrator self-contained — the historical
        // archive still works if the Transaction migrator is ever disabled.
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"G/L Entry", Database::"BC14 G/L Entry");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        if not BC14CompanySettings.GetGLModuleEnabled() then
            exit(false);

        // No cutoff configured => the transaction phase re-posts every entry into the live
        // ledger and there is nothing for the read-only archive to add. Skipping keeps the
        // legacy single-ledger experience intact.
        if GetCutoffDate() = 0D then
            exit(false);

        exit(not BC14GLEntry.IsEmpty());
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        BC14OldGLEntry: Record "BC14 Old G/L Entry";
        TotalCount: Integer;
    begin
        ApplyCutoffFilter(BC14GLEntry);
        TotalCount := BC14GLEntry.Count();
        if TotalCount = 0 then
            exit(0);
        exit(Round((TotalCount - BC14OldGLEntry.Count()) / TotalCount * 100, 1));
    end;

    procedure Migrate(): Boolean
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        BC14OldGLEntry: Record "BC14 Old G/L Entry";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        EmptyRecId: RecordId;
        EntryCount: Integer;
        IsMigrated: Boolean;
        FailureMessage: Text;
        FailureCallStack: Text;
    begin
        IsMigrated := false;
        OnMigrateOldGLEntries(IsMigrated);
        if IsMigrated then
            exit(true);

        ApplyCutoffFilter(BC14GLEntry);
        EntryCount := BC14GLEntry.Count();

        BC14OldGLEntry.Truncate();
        // Must commit before Codeunit.Run() with return value - write transactions are not allowed
        Commit();

        if not Codeunit.Run(Codeunit::"BC14 Old G/L Entry Migr.") then begin
            FailureMessage := GetLastErrorText();
            FailureCallStack := GetLastErrorCallStack();
            Session.LogMessage('0000TX3', StrSubstNo(TransferFailedLbl, FailureMessage, FailureCallStack), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14MigrationErrorHandler.LogError(MigratorNameLbl, Database::"BC14 G/L Entry", 'BC14 G/L Entry', '', Database::"BC14 Old G/L Entry", FailureMessage, EmptyRecId);
            OnAfterMigrateOldGLEntries(false);
            exit(false);
        end;

        Session.LogMessage('0000TX4', StrSubstNo(TransferCompletedLbl, EntryCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        BC14MigrationErrorHandler.ResolveErrorForRecord(Database::"BC14 G/L Entry", '');

        OnAfterMigrateOldGLEntries(true);

        exit(true);
    end;

    local procedure TransferData()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        BC14OldGLEntry: Record "BC14 Old G/L Entry";
        BC14HistoricalTransfer: Codeunit "BC14 Historical Transfer";
        EntryDataTransfer: DataTransfer;
        CutoffDate: Date;
        IsConfigured: Boolean;
    begin
        OnConfigureEntryDataTransfer(EntryDataTransfer, IsConfigured);
        if IsConfigured then begin
            Session.LogMessage('0000TX5', EntryTransferOverriddenLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            EntryDataTransfer.CopyRows();
            exit;
        end;

        EntryDataTransfer.SetTables(Database::"BC14 G/L Entry", Database::"BC14 Old G/L Entry");

        BC14HistoricalTransfer.AddMatchingFieldMappings(EntryDataTransfer, Database::"BC14 G/L Entry", Database::"BC14 Old G/L Entry");
        EntryDataTransfer.AddConstantValue(CurrentDateTime(), BC14OldGLEntry.FieldNo("Migrated On"));

        // Strictly before the cutoff. The transaction-phase migrator owns entries on or after it
        // (re-posted into the live ledger), so the partitioning is exact and disjoint — nothing
        // ends up in both the live ledger and the read-only archive.
        CutoffDate := GetCutoffDate();
        EntryDataTransfer.AddSourceFilter(BC14GLEntry.FieldNo("Posting Date"), '<%1', CutoffDate);

        EntryDataTransfer.CopyRows();
    end;

    /// <summary>
    /// Applies the same partitioning filter that <see cref="TransferData"/> uses, so progress and
    /// IsEnabled probes count only the rows that will actually be archived.
    /// </summary>
    local procedure ApplyCutoffFilter(var BC14GLEntry: Record "BC14 G/L Entry")
    var
        CutoffDate: Date;
    begin
        CutoffDate := GetCutoffDate();
        if CutoffDate = 0D then
            exit;
        BC14GLEntry.SetFilter("Posting Date", '<%1', CutoffDate);
    end;

    local procedure GetCutoffDate(): Date
    var
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
    begin
        exit(BC14CompanyInfo.GetHistoricalCutoffDate());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateOldGLEntries(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateOldGLEntries(MigratorSuccess: Boolean)
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
