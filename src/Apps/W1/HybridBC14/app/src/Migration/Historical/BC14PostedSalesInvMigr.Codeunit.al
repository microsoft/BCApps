// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

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
        BC14ArchSalesInvHeader: Record "BC14 Arch. Sales Inv. Header";
        BC14ArchSalesInvLine: Record "BC14 Arch. Sales Inv. Line";
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

        BC14ArchSalesInvLine.Truncate();
        BC14ArchSalesInvHeader.Truncate();
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
        BC14ArchSalesInvHeader: Record "BC14 Arch. Sales Inv. Header";
        BC14HistoricalTransfer: Codeunit "BC14 Historical Transfer";
        HeaderDataTransfer: DataTransfer;
        IsConfigured: Boolean;
    begin
        OnConfigureHeaderDataTransfer(HeaderDataTransfer, IsConfigured);
        if IsConfigured then begin
            Session.LogMessage('0000TX1', HeaderTransferOverriddenLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            HeaderDataTransfer.CopyRows();
            exit;
        end;

        HeaderDataTransfer.SetTables(Database::"BC14 Posted Sales Inv Header", Database::"BC14 Arch. Sales Inv. Header");
        // Explicitly enumerate business fields instead of relying on CopyRows' auto-mapping. Auto-
        // mapping also copies system fields like $systemId, which then collide with the destination
        // table's unique constraint on $systemId during the bulk INSERT pre-flight. By listing only
        // Normal-class fields with id < 2000000000 we leave the system columns untouched, and the
        // platform generates fresh SystemId / SystemCreatedAt / SystemModifiedAt on each new row.
        BC14HistoricalTransfer.AddMatchingFieldMappings(HeaderDataTransfer, Database::"BC14 Posted Sales Inv Header", Database::"BC14 Arch. Sales Inv. Header");
        HeaderDataTransfer.AddConstantValue(CurrentDateTime(), BC14ArchSalesInvHeader.FieldNo("Migrated On"));
        HeaderDataTransfer.CopyRows();
    end;

    local procedure TransferLineData()
    var
        BC14HistoricalTransfer: Codeunit "BC14 Historical Transfer";
        LineDataTransfer: DataTransfer;
        IsConfigured: Boolean;
    begin
        OnConfigureLineDataTransfer(LineDataTransfer, IsConfigured);
        if IsConfigured then begin
            Session.LogMessage('0000TX2', LineTransferOverriddenLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            LineDataTransfer.CopyRows();
            exit;
        end;

        LineDataTransfer.SetTables(Database::"BC14 Posted Sales Inv Line", Database::"BC14 Arch. Sales Inv. Line");
        BC14HistoricalTransfer.AddMatchingFieldMappings(LineDataTransfer, Database::"BC14 Posted Sales Inv Line", Database::"BC14 Arch. Sales Inv. Line");
        LineDataTransfer.CopyRows();
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