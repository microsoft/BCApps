// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using System.Threading;

codeunit 5349 "Auto Create Sales Orders"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        Commit();
        CreateNAVSalesOrdersFromSubmittedCRMSalesorders();
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";
        CrmTelemetryCategoryTok: Label 'AL CRM Integration', Locked = true;
        StartingToCreateSalesOrderTelemetryMsg: Label 'Job queue entry starting to create sales order from %1 order %2.', Locked = true;
        CommittingAfterCreateSalesOrderTelemetryMsg: Label 'Job queue entry committing after processing %1 order %2.', Locked = true;

    local procedure CreateNAVSalesOrdersFromSubmittedCRMSalesorders()
    var
        CRMSalesorder: Record "CRM Salesorder";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        IsHandled: Boolean;
    begin
        IntegrationTableSynch.OnAfterInitSynchJob(TableConnectionType::CRM, Database::"CRM Salesorder");

        IsHandled := false;
        OnBeforeCreateNAVSalesOrdersFromSubmittedCRMSalesorders(CRMSalesorder, IsHandled);
        if IsHandled then
            exit;

        CRMSalesorder.SetRange(StateCode, CRMSalesorder.StateCode::Submitted);
        CRMSalesorder.SetFilter(LastBackofficeSubmit, '%1|%2', 0D, DMY2Date(1, 1, 1900));
        OnCreateNAVSalesOrdersFromSubmittedCRMSalesordersOnAfterCRMSalesorderSetFilters(CRMSalesorder);
        if CRMSalesorder.FindSet(true) then
            repeat
                Session.LogMessage('0000DET', StrSubstNo(StartingToCreateSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                if CODEUNIT.Run(CODEUNIT::"CRM Sales Order to Sales Order", CRMSalesorder) then begin
                    Session.LogMessage('0000DEU', StrSubstNo(CommittingAfterCreateSalesOrderTelemetryMsg, CRMProductName.CDSServiceName(), CRMSalesorder.SalesOrderId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CrmTelemetryCategoryTok);
                    Commit();
                end;
            until CRMSalesorder.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateNAVSalesOrdersFromSubmittedCRMSalesorders(var CRMSalesorder: Record "CRM Salesorder"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNAVSalesOrdersFromSubmittedCRMSalesordersOnAfterCRMSalesorderSetFilters(var CRMSalesorder: Record "CRM Salesorder")
    begin
    end;
}
