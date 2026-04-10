// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Threading;

codeunit 5352 "CRM Order Status Update Job"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        UpdateOrders(Rec.GetLastLogEntryNo());
    end;

    var
        CRMProductName: Codeunit "CRM Product Name";

        ConnectionNotEnabledErr: Label 'The %1 connection is not enabled.', Comment = '%1 = CRM product name';
        OrderStatusUpdatedMsg: Label 'Sent messages about status change of sales orders.';
        OrderStatusReleasedTxt: Label 'The order status has changed to Released.';
        OrderShipmentCreatedTxt: Label 'A shipment has been created for the order.';
        OrderInvoiceCreatedTxt: Label 'An invoice has been created for the order.';
        FailedToCreatePostErr: Label 'Failed to create a post on the entity wall of %1 with id %2.', Locked = true;
        CategoryTok: Label 'AL Dataverse Integration', Locked = true;

    local procedure UpdateOrders(JobLogEntryNo: Integer)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionName: Text;
    begin
        CRMConnectionSetup.Get();
        if not CRMConnectionSetup."Is Enabled" then
            Error(ConnectionNotEnabledErr, CRMProductName.FULL());

        ConnectionName := Format(CreateGuid());
        CRMConnectionSetup.RegisterConnectionWithName(ConnectionName);
        SetDefaultTableConnection(
          TABLECONNECTIONTYPE::CRM, CRMConnectionSetup.GetDefaultCRMConnection(ConnectionName));

        UpdateSalesOrders(JobLogEntryNo);

        CRMConnectionSetup.UnregisterConnectionWithName(ConnectionName);
    end;

    local procedure UpdateSalesOrders(JobLogEntryNo: Integer)
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationTableSynch: Codeunit "Integration Table Synch.";
        SynchActionType: Option "None",Insert,Modify,ForceModify,IgnoreUnchanged,Fail,Skip,Delete;
        Counter: Integer;
    begin
        IntegrationTableMapping.SetRange(Type, IntegrationTableMapping.Type::Dataverse);
        IntegrationTableMapping.SetRange("Table ID", DATABASE::"Sales Header");
        if IntegrationTableMapping.FindFirst() then
            IntegrationTableSynch.BeginIntegrationSynchJob(TABLECONNECTIONTYPE::CRM, IntegrationTableMapping, DATABASE::"Sales Header")
        else
            IntegrationTableSynch.BeginIntegrationSynchJobLoging(TABLECONNECTIONTYPE::CRM, CODEUNIT::"CRM Order Status Update Job", JobLogEntryNo, DATABASE::"Sales Header");

        Counter := CreateStatusPostOnModifiedOrders();
        IntegrationTableSynch.UpdateSynchJobCounters(SynchActionType::Modify, Counter);

        IntegrationTableSynch.EndIntegrationSynchJobWithMsg(GetOrderStatusUpdateFinalMessage());
    end;

    procedure GetOrderStatusUpdateFinalMessage(): Text
    begin
        exit(OrderStatusUpdatedMsg);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if Result then
            exit;

        if Sender."Object Type to Run" <> Sender."Object Type to Run"::Codeunit then
            exit;

        if Sender."Object ID to Run" <> CODEUNIT::"CRM Order Status Update Job" then
            exit;

        if not CRMConnectionSetup.Get() then
            exit;

        if not CRMConnectionSetup."Is Enabled" then
            exit;

        CRMPostBuffer.SetFilter("Table ID", Format(DATABASE::"Sales Header") + '|' + Format(Database::Customer));
        if not CRMPostBuffer.IsEmpty() then
            Result := true;
    end;

    [TryFunction]
    local procedure TryCreatePost(var CRMSalesorder: Record "CRM Salesorder"; Message: Text)
    var
        CRMPost: Record "CRM Post";
    begin
        CRMPost.PostId := CreateGuid();
        CRMPost.RegardingObjectId := CRMSalesorder.SalesOrderId;
        CRMPost.RegardingObjectTypeCode := CRMPost.RegardingObjectTypeCode::salesorder;
        CRMPost.Text := CopyStr(Message, 1, MaxStrLen(CRMPost.Text));
        CRMPost.Insert();
    end;

    [TryFunction]
    local procedure TryCreatePost(var CRMAccount: Record "CRM Account"; Message: Text)
    var
        CRMPost: Record "CRM Post";
    begin
        CRMPost.PostId := CreateGuid();
        CRMPost.RegardingObjectId := CRMAccount.AccountId;
        CRMPost.RegardingObjectTypeCode := CRMPost.RegardingObjectTypeCode::account;
        CRMPost.Text := CopyStr(Message, 1, MaxStrLen(CRMPost.Text));
        CRMPost.Insert();
    end;

    local procedure FindCoupledCRMSalesOrder(var CRMSalesorder: Record "CRM Salesorder"; SalesHeader: Record "Sales Header"): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit(false);

        if not CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, CRMSalesorder.SalesOrderId) then
            exit(false);

        if not CRMSalesorder.Find() then
            exit(false);

        exit(true);
    end;

    local procedure FindCoupledCRMAccount(var CRMAccount: Record "CRM Account"; Customer: Record Customer): Boolean
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit(false);

        if not CRMIntegrationRecord.FindIDFromRecordID(Customer.RecordId, CRMAccount.AccountId) then
            exit(false);

        if not CRMAccount.Find() then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CreateStatusPostOnModifiedOrders() CreatedPosts: Integer
    var
        CRMPostBuffer: Record "CRM Post Buffer";
        TempCRMPostBuffer: Record "CRM Post Buffer" temporary;
    begin
        CRMPostBuffer.ReadIsolation := CRMPostBuffer.ReadIsolation::ReadCommitted;
        CRMPostBuffer.SetRange("Table ID", DATABASE::"Sales Header");
        if not CRMPostBuffer.FindSet() then
            exit;

        repeat
            TempCRMPostBuffer.TransferFields(CRMPostBuffer);
            TempCRMPostBuffer.Insert();
        until CRMPostBuffer.Next() = 0;

        if TempCRMPostBuffer.FindSet() then
            repeat
                CreatedPosts += ProcessCRMPostBufferEntry(TempCRMPostBuffer);
            until TempCRMPostBuffer.Next() = 0;
    end;

    local procedure ProcessCRMPostBufferEntry(var TempCRMPostBuffer: Record "CRM Post Buffer" temporary): Integer
    var
        CRMSalesorder: Record "CRM Salesorder";
        CRMAccount: Record "CRM Account";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesHeaderFound: Boolean;
        CustomerFound: Boolean;
    begin
        if TempCRMPostBuffer."Table ID" <> DATABASE::"Sales Header" then
            if TempCRMPostBuffer."Table ID" <> Database::Customer then
                exit(0);

        if SalesHeader.Get(TempCRMPostBuffer.RecId) then
            SalesHeaderFound := true
        else
            if Customer.Get(TempCRMPostBuffer.RecId) then
                CustomerFound := true;

        if not (CustomerFound or SalesHeaderFound) then begin
            DeleteCRMPostBufferEntry(TempCRMPostBuffer);
            exit(0);
        end;

        if SalesHeaderFound then begin
            if SalesHeader."Document Type" <> SalesHeader."Document Type"::Order then
                exit(0);

            if not FindCoupledCRMSalesOrder(CRMSalesorder, SalesHeader) then begin
                DeleteCRMPostBufferEntry(TempCRMPostBuffer);
                exit(0);
            end;

            case TempCRMPostBuffer.ChangeType of
                TempCRMPostBuffer.ChangeType::SalesDocReleased:
                    if not TryCreatePost(CRMSalesorder, OrderStatusReleasedTxt) then begin
                        ClearLastError();
                        Session.LogMessage('0000KOV', StrSubstNo(FailedToCreatePostErr, CRMSalesorder.TableCaption(), CRMSalesorder.OrderNumber), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
                TempCRMPostBuffer.ChangeType::SalesShptHeaderCreated:
                    if not TryCreatePost(CRMSalesorder, OrderShipmentCreatedTxt) then begin
                        ClearLastError();
                        Session.LogMessage('0000KOV', StrSubstNo(FailedToCreatePostErr, CRMSalesorder.TableCaption(), CRMSalesorder.OrderNumber), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
                TempCRMPostBuffer.ChangeType::SalesInvHeaderCreated:
                    if not TryCreatePost(CRMSalesorder, OrderInvoiceCreatedTxt) then begin
                        ClearLastError();
                        Session.LogMessage('0000KOV', StrSubstNo(FailedToCreatePostErr, CRMSalesorder.TableCaption(), CRMSalesorder.OrderNumber), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
                    end;
            end;

            DeleteCRMPostBufferEntry(TempCRMPostBuffer);
            exit(1);
        end;

        if CustomerFound then begin
            if not FindCoupledCRMAccount(CRMAccount, Customer) then begin
                DeleteCRMPostBufferEntry(TempCRMPostBuffer);
                exit(0);
            end;

            if not TryCreatePost(CRMAccount, TempCRMPostBuffer.Message) then begin
                ClearLastError();
                Session.LogMessage('0000M64', StrSubstNo(FailedToCreatePostErr, CRMAccount.TableCaption(), CRMAccount.AccountNumber), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
            end;

            DeleteCRMPostBufferEntry(TempCRMPostBuffer);
            exit(1);
        end;
    end;

    local procedure DeleteCRMPostBufferEntry(var TempCRMPostBuffer: Record "CRM Post Buffer" temporary)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
    begin
        if CRMPostBuffer.Get(TempCRMPostBuffer.ID) then
            CRMPostBuffer.Delete();
    end;
}

