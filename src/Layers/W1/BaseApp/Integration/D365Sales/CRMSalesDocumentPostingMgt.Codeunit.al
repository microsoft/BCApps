// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.D365Sales;

using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Integration.Dataverse;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;

codeunit 5346 "CRM Sales Document Posting Mgt"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        CRMSalesOrderId: Guid;
        DeletedCoupledOrderNo: Code[20];
        DeletedCoupledOrderYourReference: Text[35];
        CRMOrderHasBeenPostedMsg: Label '%1 ''%2'' has been posted in %3.', Comment = '%1=Document Type;%2=Document Id;%3=The name of our product';
        CRMInvoiceHasBeenPostedMsg: Label 'Invoice ''%1'' for order ''%2'' has been posted in %3.', Comment = '%1=Invoice number;%2=Order number;%3=The name of our product';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeDeleteAfterPosting', '', false, false)]
    local procedure SetSalesOrderIdsOnSalesHeaderDeletion(var SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; var SkipDelete: Boolean; CommitIsSuppressed: Boolean; EverythingInvoiced: Boolean; var TempSalesLineGlobal: Record "Sales Line" temporary)
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
    begin
        DeletedCoupledOrderNo := '';
        DeletedCoupledOrderYourReference := '';
        Clear(CRMSalesOrderId);

        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::Order) then
            exit;

        if not CRMIntegrationManagement.IsCRMIntegrationEnabled() then
            exit;

        if CRMIntegrationRecord.FindIDFromRecordID(SalesHeader.RecordId, CRMSalesOrderId) then begin
            DeletedCoupledOrderNo := SalesHeader."No.";
            DeletedCoupledOrderYourReference := SalesHeader."Your Reference";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterPostSalesDoc', '', false, false)]
    local procedure PostCRMSalesDocumentOnAfterPostSalesDoc(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; SalesShptHdrNo: Code[20]; RetRcpHdrNo: Code[20]; SalesInvHdrNo: Code[20]; SalesCrMemoHdrNo: Code[20])
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostCRMSalesDocumentOnAfterPostSalesDoc(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if not CRMConnectionSetup.IsEnabled() then
            exit;

        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;

        Codeunit.Run(Codeunit::"CRM Integration Management");

        AddPostedSalesDocumentToCRMAccountWall(SalesHeader, SalesInvHdrNo);

        if not IsNullGuid(CRMSalesOrderId) then // Should be set by SetOrderOnSalesHeaderDeletion
            SetCRMSalesOrderStateAsInvoiced();
    end;

    local procedure AddPostedSalesDocumentToCRMAccountWall(var SalesHeader: Record "Sales Header"; SalesInvHdrNo: Code[20])
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesOrderHeader: Record "Sales Header";
        CRMPostBuffer: Record "CRM Post Buffer";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        if not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice]) then
            exit;

        if not CRMSetupDefaults.GetAddPostedSalesDocumentToCRMAccountWallConfig() then
            exit;

        Customer.Get(SalesHeader."Sell-to Customer No.");

        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                if (SalesHeader."No." = DeletedCoupledOrderNo) then
                    CreateCRMPostBufferEntry(Customer.RecordId, Database::Customer, CRMPostBuffer.ChangeType::SalesInvHeaderCreated, StrSubstNo(CRMOrderHasBeenPostedMsg, SalesHeader."Document Type", DeletedCoupledOrderYourReference, ProductName.Short()))
                else
                    if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, SalesHeader."No.") then
                        if CRMIntegrationRecord.FindByRecordID(SalesOrderHeader.RecordId) then
                            CreateCRMPostBufferEntry(Customer.RecordId, Database::Customer, CRMPostBuffer.ChangeType::SalesInvHeaderCreated, StrSubstNo(CRMOrderHasBeenPostedMsg, SalesHeader."Document Type", SalesOrderHeader."Your Reference", ProductName.Short()));
            SalesHeader."Document Type"::Invoice:
                if SalesInvoiceHeader.Get(SalesInvHdrNo) then
                    if (SalesInvoiceHeader."Your Reference" <> '') and (SalesInvoiceHeader."Your Reference" = DeletedCoupledOrderYourReference) then
                        CreateCRMPostBufferEntry(Customer.RecordId, Database::Customer, CRMPostBuffer.ChangeType::SalesInvHeaderCreated, StrSubstNo(CRMInvoiceHasBeenPostedMsg, SalesInvoiceHeader."No.", SalesInvoiceHeader."Your Reference", ProductName.Short()))
                    else
                        if SalesOrderHeader.Get(SalesOrderHeader."Document Type"::Order, SalesInvoiceHeader."Order No.") then
                            if CRMIntegrationRecord.FindByRecordID(SalesOrderHeader.RecordId) then
                                CreateCRMPostBufferEntry(Customer.RecordId, Database::Customer, CRMPostBuffer.ChangeType::SalesInvHeaderCreated, StrSubstNo(CRMInvoiceHasBeenPostedMsg, SalesInvoiceHeader."No.", SalesOrderHeader."Your Reference", ProductName.Short()));
        end;
    end;

    local procedure SetCRMSalesOrderStateAsInvoiced()
    var
        CRMSalesorder: Record "CRM Salesorder";
    begin
        if CRMSalesorder.Get(CRMSalesOrderId) then begin
            CRMSalesorder.StateCode := CRMSalesorder.StateCode::Invoiced;
            CRMSalesorder.StatusCode := CRMSalesorder.StatusCode::Invoiced;
            CRMSalesorder.Modify();
        end;

        Clear(CRMSalesOrderId);
    end;

    procedure CheckShippedOrders(var SalesHeaderOrder: Record "Sales Header")
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMConnectionSetup: Record "CRM Connection Setup";
        ConnectionInitialized: Boolean;
    begin
        if not CRMConnectionSetup.IsEnabled() then
            exit;

        if CRMConnectionSetup.IsBidirectionalSalesOrderIntEnabled() then
            exit;

        if SalesHeaderOrder.FindSet() then
            repeat
                if IsSalesOrderFullyInvoiced(SalesHeaderOrder) then
                    if CRMIntegrationRecord.FindIDFromRecordID(SalesHeaderOrder.RecordId, CRMSalesOrderId) then begin
                        if not ConnectionInitialized then begin
                            Codeunit.Run(Codeunit::"CRM Integration Management");
                            ConnectionInitialized := true;
                        end;
                        SetCRMSalesOrderStateAsInvoiced();
                    end;
            until SalesHeaderOrder.Next() = 0;
    end;

    internal procedure IsSalesOrderFullyInvoiced(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Quantity Invoiced", '<>0');
        if SalesLine.FindFirst() then begin
            SalesLine.SetRange("Quantity Invoiced");
            SalesLine.SetFilter("Outstanding Quantity", '<>0');
            if SalesLine.IsEmpty() then begin
                SalesLine.SetRange("Outstanding Quantity");
                SalesLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
                exit(SalesLine.IsEmpty);
            end;
        end;

        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure CreateCRMPostOnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    var
        CRMPostBuffer: Record "CRM Post Buffer";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMConnectionSetup.IsEnabled() then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesDocReleased);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", 'OnAfterReleaseSalesDoc', '', false, false)]
    local procedure CreateACRMPostOnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if PreviewMode then
            exit;

        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMConnectionSetup.IsEnabled() then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesDocReleased);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesShptHeaderInsert', '', false, false)]
    local procedure CreateACRMPostOnAfterSalesShptHeaderInsert(var SalesShipmentHeader: Record "Sales Shipment Header"; SalesHeader: Record "Sales Header"; SuppressCommit: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMConnectionSetup.IsEnabled() then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesShptHeaderCreated);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterSalesInvHeaderInsert', '', false, false)]
    local procedure CreateACRMPostOnAfterSalesInvHeaderInsert(var SalesInvHeader: Record "Sales Invoice Header"; SalesHeader: Record "Sales Header"; CommitIsSuppressed: Boolean)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
        CRMConnectionSetup: Record "CRM Connection Setup";
    begin
        if not (SalesHeader."Document Type" = SalesHeader."Document Type"::Order) then
            exit;

        if not CRMConnectionSetup.IsEnabled() then
            exit;

        CreateCRMPostBufferEntry(SalesHeader.RecordId, CRMPostBuffer.ChangeType::SalesInvHeaderCreated);
    end;

    local procedure CreateCRMPostBufferEntry(RecId: RecordID; ChangeType: Option)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
        [SecurityFiltering(SecurityFilter::Ignored)]
        CRMPostBuffer2: Record "CRM Post Buffer";
    begin
        if not CRMPostBuffer2.WritePermission() then
            exit;

        CRMPostBuffer.ID := CreateGuid();
        CRMPostBuffer."Table ID" := Database::"Sales Header";
        CRMPostBuffer.RecId := RecId;
        CRMPostBuffer.ChangeType := ChangeType;
        CRMPostBuffer.ChangeDateTime := CurrentDateTime;
        CRMPostBuffer.Insert();
    end;

    local procedure CreateCRMPostBufferEntry(RecId: RecordID; TableId: Integer; ChangeType: Option; Message: Text)
    var
        CRMPostBuffer: Record "CRM Post Buffer";
        [SecurityFiltering(SecurityFilter::Ignored)]
        CRMPostBuffer2: Record "CRM Post Buffer";
    begin
        if not CRMPostBuffer2.WritePermission() then
            exit;

        CRMPostBuffer.ID := CreateGuid();
        CRMPostBuffer."Table ID" := TableId;
        CRMPostBuffer.RecId := RecId;
        CRMPostBuffer.ChangeType := ChangeType;
        CRMPostBuffer.ChangeDateTime := CurrentDateTime;
        CRMPostBuffer.Message := CopyStr(Message, 1, MaxStrLen(CRMPostBuffer.Message));
        CRMPostBuffer.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCRMSalesDocumentOnAfterPostSalesDoc(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

