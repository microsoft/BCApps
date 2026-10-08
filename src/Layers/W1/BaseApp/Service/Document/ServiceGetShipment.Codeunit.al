// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Foundation.Attachment;
using Microsoft.Service.History;

codeunit 5932 "Service-Get Shipment"
{
    TableNo = "Service Line";

    trigger OnRun()
    begin
        ServiceHeader.Get(Rec."Document Type", Rec."Document No.");
        ServiceHeader.TestField("Document Type", ServiceHeader."Document Type"::Invoice);

        Clear(ServiceShptLine);
        ServiceShptLine.SetCurrentKey("Bill-to Customer No.");
        ServiceShptLine.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceShptLine.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        ServiceShptLine.SetRange("Currency Code", ServiceHeader."Currency Code");
        OnAfterSetServiceShptLineFilters(ServiceShptLine, ServiceHeader);
        ServiceShptLine.FilterGroup(2);

        GetServiceShipments.SetTableView(ServiceShptLine);
        GetServiceShipments.SetServiceHeader(ServiceHeader);
        GetServiceShipments.LookupMode(true);
        GetServiceShipments.RunModal();
    end;

    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShptHeader: Record "Service Shipment Header";
        ServiceShptLine: Record "Service Shipment Line";
        GetServiceShipments: Page "Get Service Shipment Lines";
        LineListHasAttachments: Dictionary of [Code[20], Boolean];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The %1 on the %2 %3 and the %4 %5 must be the same.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CreateInvLines(var ServiceShptLine2: Record "Service Shipment Line")
    var
        TransferLine: Boolean;
        OrderNoList: List of [Code[20]];
    begin
        ServiceShptLine2.SetFilter("Qty. Shipped Not Invoiced", '<>0');
        if ServiceShptLine2.Find('-') then begin
            ServiceLine.LockTable();
            ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
            ServiceLine.SetRange("Document No.", ServiceHeader."No.");
            ServiceLine."Document Type" := ServiceHeader."Document Type";
            ServiceLine."Document No." := ServiceHeader."No.";
            repeat
                if ServiceShptHeader."No." <> ServiceShptLine2."Document No." then begin
                    ServiceShptHeader.Get(ServiceShptLine2."Document No.");
                    TransferLine := true;
                    if ServiceShptHeader."Currency Code" <> ServiceHeader."Currency Code" then begin
                        Message(
                          Text001,
                          ServiceHeader.FieldCaption("Currency Code"),
                          ServiceHeader.TableCaption(), ServiceHeader."No.",
                          ServiceShptHeader.TableCaption, ServiceShptHeader."No.");
                        TransferLine := false;
                    end;
                    if ServiceShptHeader."Bill-to Customer No." <> ServiceHeader."Bill-to Customer No." then begin
                        Message(
                          Text001,
                          ServiceHeader.FieldCaption("Bill-to Customer No."),
                          ServiceHeader.TableCaption(), ServiceHeader."No.",
                          ServiceShptHeader.TableCaption, ServiceShptHeader."No.");
                        TransferLine := false;
                    end;
                end;
                if TransferLine then begin
                    ServiceShptLine := ServiceShptLine2;
                    CheckServiceShipmentLineVATBusPostingGroup(ServiceShptLine, ServiceHeader);
                    ServiceShptLine.InsertInvLineFromShptLine(ServiceLine);
                    CopyDocumentAttachments(ServiceShptLine2, ServiceLine);
                    OnCreateInvLinesOnAfterServiceShptLineInsertInvLineFromShptLine(ServiceShptLine, ServiceShptLine2, ServiceShptHeader, ServiceLine, ServiceHeader);
                end;
                if ServiceShptLine2."Order No." <> '' then
                    if not OrderNoList.Contains(ServiceShptLine2."Order No.") then
                        OrderNoList.Add(ServiceShptLine2."Order No.");
            until ServiceShptLine2.Next() = 0;
            CopyDocumentAttachments(OrderNoList, ServiceHeader);
            OnAfterCreateInvLines(ServiceHeader);
        end;
    end;

    local procedure CheckServiceShipmentLineVATBusPostingGroup(ServiceShipmentLine: Record "Service Shipment Line"; ServiceHeader: Record "Service Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServiceShipmentLineVATBusPostingGroup(ServiceShipmentLine, ServiceHeader, IsHandled);
        if IsHandled then
            exit;

        ServiceShipmentLine.TestField("VAT Bus. Posting Group", ServiceHeader."VAT Bus. Posting Group");
    end;

    procedure GetServiceOrderInvoices(var TempServiceInvoiceHeader: Record "Service Invoice Header" temporary; OrderNo: Code[20])
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoicesByOrder: Query "Service Invoices By Order";
    begin
        TempServiceInvoiceHeader.Reset();
        TempServiceInvoiceHeader.DeleteAll();

        ServiceInvoicesByOrder.SetRange(Order_No_, OrderNo);
        ServiceInvoicesByOrder.SetFilter(Quantity, '<>0');
        ServiceInvoicesByOrder.Open();

        while ServiceInvoicesByOrder.Read() do begin
            ServiceInvoiceHeader.Get(ServiceInvoicesByOrder.Document_No_);
            TempServiceInvoiceHeader := ServiceInvoiceHeader;
            TempServiceInvoiceHeader.Insert();
        end;
    end;

    procedure SetServiceHeader(var ServiceHeader2: Record "Service Header")
    begin
        ServiceHeader.Get(ServiceHeader2."Document Type", ServiceHeader2."No.");
        ServiceHeader.TestField("Document Type", ServiceHeader."Document Type"::Invoice);
    end;

    local procedure CopyDocumentAttachments(var ServiceShipmentLine: Record "Service Shipment Line"; var ServiceLine2: Record "Service Line")
    var
        OrderServiceLine: Record "Service Line";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
    begin
        if (ServiceShipmentLine."Order No." = '') or (ServiceShipmentLine."Order Line No." = 0) then
            exit;
        if not AnyLineHasAttachments(ServiceShipmentLine."Order No.") then
            exit;
        OrderServiceLine.ReadIsolation := IsolationLevel::ReadCommitted;
        OrderServiceLine.SetLoadFields("Document Type", "Document No.", "Line No.");
        if OrderServiceLine.Get(OrderServiceLine."Document Type"::Order, ServiceShipmentLine."Order No.", ServiceShipmentLine."Order Line No.") then
            DocumentAttachmentMgmt.CopyAttachments(OrderServiceLine, ServiceLine2);
    end;

    local procedure CopyDocumentAttachments(OrderNoList: List of [Code[20]]; var ServiceHeader2: Record "Service Header")
    var
        OrderServiceHeader: Record "Service Header";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        OrderNo: Code[20];
    begin
        OrderServiceHeader.ReadIsolation := IsolationLevel::ReadCommitted;
        OrderServiceHeader.SetLoadFields("Document Type", "No.");
        foreach OrderNo in OrderNoList do
            if OrderHasAttachments(OrderNo) then
                if OrderServiceHeader.Get(OrderServiceHeader."Document Type"::Order, OrderNo) then
                    DocumentAttachmentMgmt.CopyAttachments(OrderServiceHeader, ServiceHeader2);
    end;

    local procedure OrderHasAttachments(DocumentNo: Code[20]): Boolean
    begin
        exit(EntityHasAttachments(DocumentNo, Database::"Service Header"));
    end;

    local procedure AnyLineHasAttachments(DocumentNo: Code[20]): Boolean
    begin
        if not LineListHasAttachments.ContainsKey(DocumentNo) then
            LineListHasAttachments.Add(DocumentNo, EntityHasAttachments(DocumentNo, Database::"Service Line"));
        exit(LineListHasAttachments.Get(DocumentNo));
    end;

    local procedure EntityHasAttachments(DocumentNo: Code[20]; TableNo: Integer): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.ReadIsolation := IsolationLevel::ReadUncommitted;
        DocumentAttachment.SetRange("Table ID", TableNo);
        DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Order);
        DocumentAttachment.SetRange("No.", DocumentNo);
        exit(not DocumentAttachment.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvLines(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetServiceShptLineFilters(var ServiceShipmentLine: Record "Service Shipment Line"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvLinesOnAfterServiceShptLineInsertInvLineFromShptLine(var ServiceShptLine: Record "Service Shipment Line"; var ServiceShptLine2: Record "Service Shipment Line"; var ServiceShptHeader: Record "Service Shipment Header"; var ServiceLine: Record "Service Line"; var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServiceShipmentLineVATBusPostingGroup(ServiceShipmentLine: Record "Service Shipment Line"; ServiceHeader: Record "Service Header"; var IsHandled: Boolean)
    begin
    end;
}

