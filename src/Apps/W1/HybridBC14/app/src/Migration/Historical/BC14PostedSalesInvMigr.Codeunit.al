// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;
using Microsoft.DataMigration.BC14Reimplementation.HistoricalData;
using Microsoft.Sales.History;

codeunit 46880 "BC14 Posted Sales Inv Migr." implements "BC14 Migrator"
{
    trigger OnRun()
    begin
        TransferData();
    end;

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";
        MigratorNameLbl: Label 'Posted Sales Invoice Migrator';
        TransferCompletedLbl: Label 'Posted Sales Invoice archive transfer completed. Headers: %1, Lines: %2', Locked = true, Comment = '%1 = Header count, %2 = Line count';
        TransferFailedLbl: Label 'Posted Sales Invoice archive transfer failed. Error: %1. CallStack: %2', Locked = true, Comment = '%1 = Error text, %2 = Call stack';
        HeaderTransferOverriddenLbl: Label 'Posted Sales Invoice header transfer was overridden by an extension.', Locked = true;
        LineTransferOverriddenLbl: Label 'Posted Sales Invoice line transfer was overridden by an extension.', Locked = true;
        HeaderTransferResumedLbl: Label 'Posted Sales Invoice header archive transfer resuming after no. %1.', Locked = true, Comment = '%1 = Last archived invoice number';
        LineTransferResumedLbl: Label 'Posted Sales Invoice line archive transfer resuming after document %1 line %2.', Locked = true, Comment = '%1 = Last archived document number, %2 = Last archived line number';
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
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Sales Invoice Header", Database::"BC14 Posted Sales Inv Header");
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Sales Invoice Line", Database::"BC14 Posted Sales Inv Line");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
    begin
        if not BC14CompanySettings.GetReceivablesModuleEnabled() then
            exit(false);

        exit(not BC14PostedSalesInvHeader.IsEmpty());
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14ArchSalesInvHeader: Record "BC14 Arch. Sales Inv. Header";
        TotalCount: Integer;
    begin
        TotalCount := BC14PostedSalesInvHeader.Count();
        if TotalCount = 0 then
            exit(0);
        exit(Round((TotalCount - BC14ArchSalesInvHeader.Count()) / TotalCount * 100, 1));
    end;

    procedure Migrate(): Boolean
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14PostedSalesInvLine: Record "BC14 Posted Sales Inv Line";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        EmptyRecId: RecordId;
        HeaderCount: Integer;
        LineCount: Integer;
        IsMigrated: Boolean;
        FailureMessage: Text;
        FailureCallStack: Text;
    begin
        IsMigrated := false;
        OnMigratePostedSalesInvoices(IsMigrated);
        if IsMigrated then
            exit(true);

        HeaderCount := BC14PostedSalesInvHeader.Count();
        LineCount := BC14PostedSalesInvLine.Count();

        // Note: the archive is NOT truncated here. The transfer is resumable — headers and lines
        // pick up from the last archived row (see TransferData) so a rerun after a failure or
        // timeout continues instead of re-copying everything. A clean wipe is the responsibility
        // of the migration reset path, not of every Migrate() pass.
        // Must commit before Codeunit.Run() with return value - write transactions are not allowed
        Commit();

        if not Codeunit.Run(Codeunit::"BC14 Posted Sales Inv Migr.") then begin
            FailureMessage := GetLastErrorText();
            FailureCallStack := GetLastErrorCallStack();
            Session.LogMessage('0000TX0', StrSubstNo(TransferFailedLbl, FailureMessage, FailureCallStack), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14MigrationErrorHandler.LogError(MigratorNameLbl, Database::"BC14 Posted Sales Inv Header", 'BC14 Posted Sales Inv Header', '', Database::"BC14 Arch. Sales Inv. Header", FailureMessage, EmptyRecId);
            OnAfterMigratePostedSalesInvoices(false);
            exit(false);
        end;

        Session.LogMessage('0000TV9', StrSubstNo(TransferCompletedLbl, HeaderCount, LineCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        BC14MigrationErrorHandler.ResolveErrorForRecord(Database::"BC14 Posted Sales Inv Header", '');

        OnAfterMigratePostedSalesInvoices(true);

        exit(true);
    end;

    local procedure TransferData()
    begin
        TransferHeaderData();
        TransferLineData();
    end;

    local procedure TransferHeaderData()
    var
        BC14PostedSalesInvHeader: Record "BC14 Posted Sales Inv Header";
        BC14ArchSalesInvHeader: Record "BC14 Arch. Sales Inv. Header";
        BC14HistoricalTransfer: Codeunit "BC14 Historical Transfer";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        HeaderDataTransfer: DataTransfer;
        MigratedOn: DateTime;
        LastCommitAt: DateTime;
        LastArchivedNo: Code[20];
        RowsSinceCommit: Integer;
        IsConfigured: Boolean;
    begin
        OnConfigureHeaderDataTransfer(HeaderDataTransfer, IsConfigured);
        if IsConfigured then begin
            Session.LogMessage('0000TX1', HeaderTransferOverriddenLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            HeaderDataTransfer.CopyRows();
            exit;
        end;

        LastArchivedNo := GetLastArchivedHeaderNo();
        if LastArchivedNo <> '' then
            Session.LogMessage('0000TX9', StrSubstNo(HeaderTransferResumedLbl, LastArchivedNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // Fast path: inside Intelligent Cloud migration scope the platform permits cross-extension
        // DataTransfer (destination lives in the BC14 Historical Data extension). Outside that
        // scope (e.g., a background rerun) DataTransfer would be rejected, so fall back to a
        // per-record AL copy via TransferFields.
        if HybridCloudManagement.IsIntelligentCloudEnabled() then begin
            HeaderDataTransfer.SetTables(Database::"BC14 Posted Sales Inv Header", Database::"BC14 Arch. Sales Inv. Header");
            // Explicitly enumerate business fields instead of relying on CopyRows' auto-mapping.
            // Auto-mapping also copies system fields like $systemId, which collide with the
            // destination table's unique constraint on $systemId during the bulk INSERT pre-flight.
            BC14HistoricalTransfer.AddMatchingFieldMappings(HeaderDataTransfer, Database::"BC14 Posted Sales Inv Header", Database::"BC14 Arch. Sales Inv. Header");
            HeaderDataTransfer.AddConstantValue(CurrentDateTime(), BC14ArchSalesInvHeader.FieldNo("Migrated On"));
            if LastArchivedNo <> '' then
                HeaderDataTransfer.AddSourceFilter(BC14PostedSalesInvHeader.FieldNo("No."), '>%1', LastArchivedNo);
            HeaderDataTransfer.CopyRows();
            exit;
        end;

        if CommitIntervalMs = 0 then
            CommitIntervalMs := 90000; // 1.5 minutes
        if MaxBatchSize = 0 then
            MaxBatchSize := 10000;

        MigratedOn := CurrentDateTime();
        LastCommitAt := CurrentDateTime();

        BC14PostedSalesInvHeader.SetCurrentKey("No.");
        if LastArchivedNo <> '' then
            BC14PostedSalesInvHeader.SetFilter("No.", '>%1', LastArchivedNo);
        if not BC14PostedSalesInvHeader.FindSet() then
            exit;
        repeat
            BC14ArchSalesInvHeader.Init();
            BC14ArchSalesInvHeader.TransferFields(BC14PostedSalesInvHeader, true);
            BC14ArchSalesInvHeader."Migrated On" := MigratedOn;
            BC14ArchSalesInvHeader.Insert(false);
            RowsSinceCommit += 1;

            if (RowsSinceCommit >= MaxBatchSize) or ((CurrentDateTime() - LastCommitAt) >= CommitIntervalMs) then begin
                Commit();
                RowsSinceCommit := 0;
                LastCommitAt := CurrentDateTime();
            end;
        until BC14PostedSalesInvHeader.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure TransferLineData()
    var
        BC14PostedSalesInvLine: Record "BC14 Posted Sales Inv Line";
        BC14ArchSalesInvLine: Record "BC14 Arch. Sales Inv. Line";
        BC14HistoricalTransfer: Codeunit "BC14 Historical Transfer";
        HybridCloudManagement: Codeunit "Hybrid Cloud Management";
        LineDataTransfer: DataTransfer;
        LastCommitAt: DateTime;
        LastArchivedDocNo: Code[20];
        LastArchivedLineNo: Integer;
        RowsSinceCommit: Integer;
        IsConfigured: Boolean;
    begin
        OnConfigureLineDataTransfer(LineDataTransfer, IsConfigured);
        if IsConfigured then begin
            Session.LogMessage('0000TX2', LineTransferOverriddenLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            LineDataTransfer.CopyRows();
            exit;
        end;

        GetLastArchivedLine(LastArchivedDocNo, LastArchivedLineNo);
        if LastArchivedDocNo <> '' then
            Session.LogMessage('0000TX8', StrSubstNo(LineTransferResumedLbl, LastArchivedDocNo, LastArchivedLineNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        if HybridCloudManagement.IsIntelligentCloudEnabled() then begin
            LineDataTransfer.SetTables(Database::"BC14 Posted Sales Inv Line", Database::"BC14 Arch. Sales Inv. Line");
            BC14HistoricalTransfer.AddMatchingFieldMappings(LineDataTransfer, Database::"BC14 Posted Sales Inv Line", Database::"BC14 Arch. Sales Inv. Line");
            // CopyRows is atomic, so the line archive is all-or-nothing in the IC path; filtering
            // strictly past the last archived document keeps a rerun-after-success idempotent.
            if LastArchivedDocNo <> '' then
                LineDataTransfer.AddSourceFilter(BC14PostedSalesInvLine.FieldNo("Document No."), '>%1', LastArchivedDocNo);
            LineDataTransfer.CopyRows();
            exit;
        end;

        if CommitIntervalMs = 0 then
            CommitIntervalMs := 90000; // 1.5 minutes
        if MaxBatchSize = 0 then
            MaxBatchSize := 10000;

        LastCommitAt := CurrentDateTime();

        BC14PostedSalesInvLine.SetCurrentKey("Document No.", "Line No.");
        // Start at the boundary document and skip the lines of it that are already archived. The
        // batched fallback can commit mid-document, so the boundary document may be only partially
        // copied; '>=' on Document No. plus the in-loop skip re-copies exactly the missing lines.
        if LastArchivedDocNo <> '' then
            BC14PostedSalesInvLine.SetFilter("Document No.", '>=%1', LastArchivedDocNo);
        if not BC14PostedSalesInvLine.FindSet() then
            exit;
        repeat
            if not ((BC14PostedSalesInvLine."Document No." = LastArchivedDocNo) and (BC14PostedSalesInvLine."Line No." <= LastArchivedLineNo)) then begin
                BC14ArchSalesInvLine.Init();
                BC14ArchSalesInvLine.TransferFields(BC14PostedSalesInvLine, true);
                BC14ArchSalesInvLine.Insert(false);
                RowsSinceCommit += 1;

                if (RowsSinceCommit >= MaxBatchSize) or ((CurrentDateTime() - LastCommitAt) >= CommitIntervalMs) then begin
                    Commit();
                    RowsSinceCommit := 0;
                    LastCommitAt := CurrentDateTime();
                end;
            end;
        until BC14PostedSalesInvLine.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure GetLastArchivedHeaderNo(): Code[20]
    var
        BC14ArchSalesInvHeader: Record "BC14 Arch. Sales Inv. Header";
    begin
        if BC14ArchSalesInvHeader.FindLast() then
            exit(BC14ArchSalesInvHeader."No.");
        exit('');
    end;

    local procedure GetLastArchivedLine(var LastArchivedDocNo: Code[20]; var LastArchivedLineNo: Integer)
    var
        BC14ArchSalesInvLine: Record "BC14 Arch. Sales Inv. Line";
    begin
        if BC14ArchSalesInvLine.FindLast() then begin
            LastArchivedDocNo := BC14ArchSalesInvLine."Document No.";
            LastArchivedLineNo := BC14ArchSalesInvLine."Line No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigratePostedSalesInvoices(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigratePostedSalesInvoices(MigratorSuccess: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before the framework transfers the header rows.
    /// Subscribe to take over the transfer entirely: set IsConfigured to true, configure the
    /// DataTransfer yourself (SetTables / AddFieldValue / AddConstantValue / source filters),
    /// and the framework will call CopyRows on it for you. The default path uses a per-record
    /// Insert loop with platform-generated SystemId, so it is not subject to the DataTransfer
    /// pre-flight uniqueness check on source SystemId values.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnConfigureHeaderDataTransfer(var HeaderDataTransfer: DataTransfer; var IsConfigured: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before the framework transfers the line rows.
    /// Subscribe to take over the transfer entirely: set IsConfigured to true, configure the
    /// DataTransfer yourself, and the framework will call CopyRows on it for you.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnConfigureLineDataTransfer(var LineDataTransfer: DataTransfer; var IsConfigured: Boolean)
    begin
    end;

}