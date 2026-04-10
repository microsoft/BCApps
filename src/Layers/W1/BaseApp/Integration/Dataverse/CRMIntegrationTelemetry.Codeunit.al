// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;

codeunit 5333 "CRM Integration Telemetry"
{
    Access = Internal;

    trigger OnRun()
    begin
        SendIntegrationStatsTelemetry();
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";

        CRMConnectionCategoryTxt: Label 'AL CRM Connection', Locked = true;
        CRMIntegrationCategoryTxt: Label 'AL CRM Integration', Locked = true;
        EnabledConnectionTelemetryTxt: Label '{"Enabled": "Yes", "AuthenticationType": "%1", "CRMVersion": "%2", "ProxyVersion": "%3", "CRMSolutionInstalled": "%4", "SOIntegration": "%5", "AutoCreateSO": "%6", "AutoProcessSQ": "%7", "ItemAvailablityEnabled": "%8"}', Locked = true;
        DisabledConnectionTelemetryTxt: Label '{"Enabled": "No", "DisableReason": "%1","AuthenticationType": "%2", "ProxyVersion": "%3", "AutoCreateSO": "%4"}', Locked = true;
        IntegrationTableStatsTxt: Label '{"IntegrationName": "%1", "TableID": "%2", "IntTableID": "%3", "TableName": "%4", "IntegrationTableName": "%5", Direction": "%6", "SyncCoupledOnly": "%7", "SyncJobsTotal": "%8", "TotalRecords": "%9", "CoupledRecords": "%10", "CoupledErrors": "%11"}', Locked = true;
        NoPermissionTxt: Label '{"READPERMISSION": "No"}', Locked = true;
        UserOpenedSetupPageTxt: Label 'User is attempting to set up the connection via %1 page.', Locked = true;
        UserDisabledConnectionTxt: Label 'User disabled the connection to %1.', Locked = true;
        UserEnabledConnectionTxt: Label 'User has enabled the connection to D365 Sales', Locked = true;

    local procedure GetEnabledConnectionTelemetryData(CRMConnectionSetup: Record "CRM Connection Setup"): Text
    begin
        exit(
              StrSubstNo(
                EnabledConnectionTelemetryTxt,
                Format(CRMConnectionSetup."Authentication Type"), CRMConnectionSetup."CRM Version", CRMConnectionSetup."Proxy Version", CRMConnectionSetup."Is CRM Solution Installed",
                CRMConnectionSetup."Is S.Order Integration Enabled", CRMConnectionSetup."Auto Create Sales Orders", CRMConnectionSetup."Auto Process Sales Quotes",
                CRMIntegrationManagement.IsItemAvailabilityEnabled()));
    end;

    local procedure GetDisabledConnectionTelemetryData(CRMConnectionSetup: Record "CRM Connection Setup"): Text
    begin
        exit(
              StrSubstNo(
                DisabledConnectionTelemetryTxt,
                CRMConnectionSetup."Disable Reason", Format(CRMConnectionSetup."Authentication Type"), CRMConnectionSetup."Proxy Version", CRMConnectionSetup."Auto Create Sales Orders"));
    end;

    local procedure GetIntegrationStatsTelemetryData() Data: Text
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TableRecRef: RecordRef;
        IntTableRecRef: RecordRef;
        TableData: Text;
        Comma: Text;
    begin
        if not IntegrationTableMapping.ReadPermission then
            exit(NoPermissionTxt);

        Data := '[';
        if IntegrationTableMapping.FindSet() then
            repeat
                TableRecRef.Open(IntegrationTableMapping."Table ID");
                IntTableRecRef.Open(IntegrationTableMapping."Integration Table ID");
                TableData :=
                  StrSubstNo(
                    IntegrationTableStatsTxt, IntegrationTableMapping.Name, IntegrationTableMapping."Table ID", IntegrationTableMapping."Integration Table ID",
                    TableRecRef.Name(), IntTableRecRef.Name(),
                    Format(IntegrationTableMapping.Direction), IntegrationTableMapping."Synch. Only Coupled Records",
                    GetSyncJobsTotal(IntegrationTableMapping.Name), GetTotalRecords(IntegrationTableMapping."Table ID"),
                    GetCoupledRecords(IntegrationTableMapping."Table ID"), GetCoupledErrors(IntegrationTableMapping."Table ID"));
                Data += Comma + TableData;
                Comma := ','
            until IntegrationTableMapping.Next() = 0;
        Data += ']';
    end;

    local procedure GetSyncJobsTotal(Name: Code[20]): Integer
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if not IntegrationSynchJob.ReadPermission then
            exit(-1);
        IntegrationSynchJob.SetRange("Integration Table Mapping Name", Name);
        exit(IntegrationSynchJob.Count);
    end;

    local procedure GetTotalRecords(TableID: Integer) Result: Integer
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        if RecRef.ReadPermission then
            Result := RecRef.Count
        else
            Result := -1;
        RecRef.Close();
    end;

    local procedure GetCoupledRecords(TableID: Integer): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if not CRMIntegrationRecord.ReadPermission then
            exit(-1);
        CRMIntegrationRecord.SetRange("Table ID", TableID);
        exit(CRMIntegrationRecord.Count);
    end;

    local procedure GetCoupledErrors(TableID: Integer): Integer
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        if not CRMIntegrationRecord.ReadPermission then
            exit(-1);
        CRMIntegrationRecord.SetRange("Table ID", TableID);
        CRMIntegrationRecord.SetRange(Skipped, true);
        exit(CRMIntegrationRecord.Count);
    end;

    local procedure SendConnectionTelemetry(CRMConnectionSetup: Record "CRM Connection Setup")
    begin
        if CRMConnectionSetup."Is Enabled" then
            Session.LogMessage('000024X', GetEnabledConnectionTelemetryData(CRMConnectionSetup), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CRMConnectionCategoryTxt)
        else
            Session.LogMessage('000024Y', GetDisabledConnectionTelemetryData(CRMConnectionSetup), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CRMConnectionCategoryTxt);
    end;

    local procedure SendIntegrationStatsTelemetry()
    begin
        Session.LogMessage('000024Z', GetIntegrationStatsTelemetryData(), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CRMIntegrationCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Connection Setup", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertConnectionSetup(var Rec: Record "CRM Connection Setup"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            SendConnectionTelemetry(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"CRM Connection Setup", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyConnectionSetup(var Rec: Record "CRM Connection Setup"; var xRec: Record "CRM Connection Setup"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            SendConnectionTelemetry(Rec);
    end;

    [Scope('OnPrem')]
    procedure LogTelemetryWhenConnectionEnabled()
    begin
        Session.LogMessage('0000CE2', UserEnabledConnectionTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CRMConnectionCategoryTxt);
    end;

    [Scope('OnPrem')]
    procedure LogTelemetryWhenConnectionDisabled()
    var
        CRMProductName: Codeunit "CRM Product Name";
    begin
        Session.LogMessage('00008A0', StrSubstNo(UserDisabledConnectionTxt, CRMProductName.SHORT()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CRMConnectionCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Page, Page::"CRM Connection Setup", 'OnOpenPageEvent', '', false, false)]
    local procedure LogTelemetryOnAfterOpenCRMConnectionSetup(var Rec: Record "CRM Connection Setup")
    var
        CRMConnectionSetup: Page "CRM Connection Setup";
    begin
        Session.LogMessage('00008A1', StrSubstNo(UserOpenedSetupPageTxt, CRMConnectionSetup.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CRMConnectionCategoryTxt)
    end;

    [EventSubscriber(ObjectType::Page, Page::"CRM Connection Setup Wizard", 'OnOpenPageEvent', '', false, false)]
    local procedure LogTelemetryOnAfterOpenCRMConnectionSetupWizard(var Rec: Record "CRM Connection Setup")
    var
        CRMConnectionSetupWizard: Page "CRM Connection Setup Wizard";
    begin
        Session.LogMessage('00008A2', StrSubstNo(UserOpenedSetupPageTxt, CRMConnectionSetupWizard.Caption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CRMConnectionCategoryTxt)
    end;
}

