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
        TransferResumedLbl: Label 'Old G/L Entry archive transfer resuming after entry no. %1.', Locked = true, Comment = '%1 = Last archived entry number';
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
        if BC14CompanySettings.GetHistoricalCutoffDate() = 0D then
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
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
        EntryDataTransfer: DataTransfer;
        CutoffDate: Date;
        LastArchivedEntryNo: Integer;
        IsConfigured: Boolean;
    begin
        OnConfigureEntryDataTransfer(EntryDataTransfer, IsConfigured);
        if IsConfigured then begin
            Session.LogMessage('0000TX5', EntryTransferOverriddenLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            EntryDataTransfer.CopyRows();
            exit;
        end;

        CutoffDate := BC14CompanyInfo.GetHistoricalCutoffDate();

        LastArchivedEntryNo := GetLastArchivedEntryNo();
        if LastArchivedEntryNo > 0 then
            Session.LogMessage('0000TX7', StrSubstNo(TransferResumedLbl, LastArchivedEntryNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // DataTransfer.CopyRows() is only permitted inside platform upgrade/install codeunits. This
        // migration always runs as a background task/session (never an upgrade codeunit), so calling
        // CopyRows() here would always throw "DataTransfer is only usable during upgrade or install"
        // and leave the historical errors unresolved on rerun. Always use the per-record batched
        // copy; the OnConfigureEntryDataTransfer override above still lets an upgrade-context caller
        // opt into DataTransfer.
        TransferDataInBatches(CutoffDate, LastArchivedEntryNo);
    end;

    local procedure TransferDataInBatches(CutoffDate: Date; LastArchivedEntryNo: Integer)
    var
        BC14GLEntry: Record "BC14 G/L Entry";
        BC14OldGLEntry: Record "BC14 Old G/L Entry";
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

        BC14GLEntry.SetCurrentKey("Entry No.");
        BC14GLEntry.SetFilter("Posting Date", '<%1', CutoffDate);
        if LastArchivedEntryNo > 0 then
            BC14GLEntry.SetFilter("Entry No.", '>%1', LastArchivedEntryNo);
        if not BC14GLEntry.FindSet() then
            exit;
        repeat
            BC14OldGLEntry.Init();
            BC14OldGLEntry.TransferFields(BC14GLEntry, true);
            BC14OldGLEntry."Migrated On" := MigratedOn;
            BC14OldGLEntry.Insert(false);
            RowsSinceCommit += 1;

            if (RowsSinceCommit >= MaxBatchSize) or ((CurrentDateTime() - LastCommitAt) >= CommitIntervalMs) then begin
                Commit();
                RowsSinceCommit := 0;
                LastCommitAt := CurrentDateTime();
            end;
        until BC14GLEntry.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure GetLastArchivedEntryNo(): Integer
    var
        BC14OldGLEntry: Record "BC14 Old G/L Entry";
    begin
        BC14OldGLEntry.SetCurrentKey("Entry No.");
        if BC14OldGLEntry.FindLast() then
            exit(BC14OldGLEntry."Entry No.");
        exit(0);
    end;

    /// <summary>
    /// Applies the same partitioning filter that <see cref="TransferData"/> uses, so progress and
    /// IsEnabled probes count only the rows that will actually be archived.
    /// </summary>
    local procedure ApplyCutoffFilter(var BC14GLEntry: Record "BC14 G/L Entry")
    var
        BC14CompanyInfo: Record BC14CompanyMigrationInfo;
        CutoffDate: Date;
    begin
        CutoffDate := BC14CompanyInfo.GetHistoricalCutoffDate();
        if CutoffDate = 0D then
            exit;
        BC14GLEntry.SetFilter("Posting Date", '<%1', CutoffDate);
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
