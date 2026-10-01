// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved. 
// Licensed under the MIT License. See License.txt in the project root for license information. 
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.C5;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Integration;
using System.Telemetry;

codeunit 1872 "C5 Telemetry"
{
    var
        EmptyZipFileBlobErr: Label 'Oops, it seems the blob is empty.';
        CopyToDatabaseFailedErr: Label 'Something went wrong with copying the zip file to Database.';

        StagingTablesImportStartTxt: Label 'CSV file import to staging tables started.', Locked = true;

        StagingTablesImportFinishTxt: Label 'CSV file import to staging tables finished; duration: %1', Locked = true;
        CloudMigrationLbl: Label 'CloudMigration', Locked = true;
        C5ProductLbl: Label 'C5 2012', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Migration Mgt.", 'OnAfterMigrationFinished', '', true, true)]
    local procedure OnAfterMigrationFinishedSubscriber(var DataMigrationStatus: Record "Data Migration Status"; WasAborted: Boolean; StartTime: DateTime; Retry: Boolean)
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
    begin
        if DataMigrationStatus."Migration Type" <> C5MigrationDashboardMgt.GetC5MigrationTypeTxt() then
            exit;

        if WasAborted or Retry then
            exit;

        SendCompletedMigrationTelemetry(CurrentDateTime());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"C5 Unzip", 'OnZipFileBlobMissing', '', false, false)]
    local procedure OnZipFileBlobMissingSubscriber()
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
    begin
        Session.LogMessage('00001DF', EmptyZipFileBlobErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', C5MigrationDashboardMgt.GetC5MigrationTypeTxt());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"C5 Data Migration Mgt.", 'OnCopyToDataBaseFailed', '', false, false)]
    local procedure OnCopyToDataBaseFailedSubscriber()
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
    begin
        Session.LogMessage('00001IK', CopyToDatabaseFailedErr, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', C5MigrationDashboardMgt.GetC5MigrationTypeTxt());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"C5 Unzip", 'OnUnzipFileError', '', false, false)]
    local procedure OnUnzipFileErrorSubscriber()
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
    begin
        Session.LogMessage('00001IL', GetLastErrorText(), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', C5MigrationDashboardMgt.GetC5MigrationTypeTxt());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"C5 Schema Reader", 'OnDefinitionFileMissing', '', false, false)]
    local procedure OnDefinitionFileMissinggSubscriber()
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
        C5SchemaReader: Codeunit "C5 Schema Reader";
    begin
        Session.LogMessage('00001DG', C5SchemaReader.GetDefinitionFileMissingErrorTxt(), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', C5MigrationDashboardMgt.GetC5MigrationTypeTxt());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"C5 Data Loader", 'OnFillStagingTablesStarted', '', false, false)]
    local procedure OnFillStagingTablesStartedubscriber()
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
    begin
        Session.LogMessage('00001HZ', StagingTablesImportStartTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', C5MigrationDashboardMgt.GetC5MigrationTypeTxt());

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"C5 Data Loader", 'OnFillStagingTablesFinished', '', false, false)]
    local procedure OnFillStagingTablesFinishedSubscriber(DurationAsInt: Integer)
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
    begin
        Session.LogMessage('00001I0', StrSubstNo(StagingTablesImportFinishTxt, DurationAsInt), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', C5MigrationDashboardMgt.GetC5MigrationTypeTxt());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"C5 Wizard Integration", 'OnC5MigrationSelected', '', false, false)]
    local procedure OnC5MigrationSelectedSubscriber()
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
    begin
        Session.LogMessage('00001K5', 'C5 Migration was selected.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', C5MigrationDashboardMgt.GetC5MigrationTypeTxt());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"C5 Wizard Integration", 'OnEntitiesToMigrateSelected', '', false, false)]
    local procedure OnEntitiesToMigrateSelectedSubscriber(var DataMigrationEntity: Record "Data Migration Entity")
    var
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
        EntitiesToMigrateMessage: Text;
        VendorEntityMsg: Label 'vendor: %1; ', Locked = true;
        CustomerEntityMsg: Label 'customer: %1; ', Locked = true;
        GLAccountEntityMsg: Label 'gl_acc: %1; ', Locked = true;
        ItemEntityMsg: Label 'item: %1; ', Locked = true;
        C5LedgerMsg: Label 'C5_ledger_entries: %1; ', Locked = true;
    begin
        DataMigrationEntity.SetRange(Selected, true);
        DataMigrationEntity.SetRange("Table ID", Database::Vendor);

        if DataMigrationEntity.FindFirst() then
            EntitiesToMigrateMessage += StrSubstNo(VendorEntityMsg, DataMigrationEntity."No. of Records");

        DataMigrationEntity.SetRange("Table ID", Database::Customer);
        if DataMigrationEntity.FindFirst() then
            EntitiesToMigrateMessage += StrSubstNo(CustomerEntityMsg, DataMigrationEntity."No. of Records");

        DataMigrationEntity.SetRange("Table ID", Database::"G/L Account");
        if DataMigrationEntity.FindFirst() then
            EntitiesToMigrateMessage += StrSubstNo(GLAccountEntityMsg, DataMigrationEntity."No. of Records");

        DataMigrationEntity.SetRange("Table ID", Database::Item);
        if DataMigrationEntity.FindFirst() then
            EntitiesToMigrateMessage += StrSubstNo(ItemEntityMsg, DataMigrationEntity."No. of Records");

        DataMigrationEntity.SetRange("Table ID", Database::"C5 LedTrans");
        if DataMigrationEntity.FindFirst() then
            EntitiesToMigrateMessage += StrSubstNo(C5LedgerMsg, DataMigrationEntity."No. of Records");

        Session.LogMessage('00001I1', EntitiesToMigrateMessage, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', C5MigrationDashboardMgt.GetC5MigrationTypeTxt());
    end;

    internal procedure GetCompletedMigrationDateTime(var MigrationDateTime: DateTime): Boolean
    var
        DataMigrationStatus: Record "Data Migration Status";
        C5MigrationDashboardMgt: Codeunit "C5 Migr. Dashboard Mgt";
    begin
        DataMigrationStatus.SetRange("Migration Type", C5MigrationDashboardMgt.GetC5MigrationTypeTxt());
        if not DataMigrationStatus.FindSet() then
            exit(false);

        repeat
            if DataMigrationStatus.Status <> DataMigrationStatus.Status::Completed then
                exit(false);
            if DataMigrationStatus.SystemModifiedAt > MigrationDateTime then
                MigrationDateTime := DataMigrationStatus.SystemModifiedAt;
        until DataMigrationStatus.Next() = 0;

        exit(true);
    end;

    internal procedure SendCompletedMigrationTelemetry(MigrationDateTime: DateTime)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        FeatureTelemetry.LogUptake('0000JMQ', 'Cloud Migration', Enum::"Feature Uptake Status"::Used);

        TelemetryDimensions.Add('Category', CloudMigrationLbl);
        TelemetryDimensions.Add('NumberOfCompanies', Format(1, 0, 9));
        TelemetryDimensions.Add('TotalMigrationSize', Format(0, 0, 9));
        TelemetryDimensions.Add('TotalOnPremSize', Format(0, 0, 9));
        TelemetryDimensions.Add('Product', C5ProductLbl);
        TelemetryDimensions.Add('MigrationDateTime', Format(MigrationDateTime, 0, 9));
        FeatureTelemetry.LogUsage('0000JMR', 'Cloud Migration', 'Tenant was cloud migrated', TelemetryDimensions);
    end;
}