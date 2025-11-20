// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Sales.Document;
using System.Utilities;

codeunit 1322 "Correct PstdSalesInv (Yes/No)"
{
    Permissions = TableData "Sales Invoice Header" = rm,
                  TableData "Sales Cr.Memo Header" = rm;
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    begin
        CorrectInvoice(Rec);
    end;

    var
        CorrectPostedInvoiceQst: Label 'The posted sales invoice will be canceled, and a new version of the sales invoice will automatically be created by the system so that you can make the correction.\ \Do you want to continue?';
        CorrectPostedInvoiceFromSingleOrderQst: Label 'The invoice was posted from an order. The invoice will be cancelled, and the order will open so that you can make the correction.\ \Do you want to continue?';
        CorrectPostedInvoiceFromDeletedOrderQst: Label 'The invoice was posted from an order. The order has been deleted, and the invoice will be cancelled. You can create a new invoice or order by using the Copy Document action.\ \Do you want to continue?';
        CorrectPostedInvoiceFromMultipleOrderQst: Label 'The invoice was posted from multiple orders. It will now be cancelled, and you can make a correction manually in the original orders.\ \Do you want to continue?';

    procedure CorrectInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        RelatedOrderNo: Code[20];
        MultipleOrderRelated: Boolean;
        SalesHeaderExists: Boolean;
    begin
        CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, false);
        GetRelatedOrder(SalesInvoiceHeader, RelatedOrderNo, MultipleOrderRelated);
        if RelatedOrderNo = '' then
            exit(CancelPostedInvoiceAndOpenNewSalesInvoice(SalesInvoiceHeader));

        SalesHeaderExists := SalesHeader.Get(SalesHeader."Document Type"::Order, RelatedOrderNo);
        case true of
            MultipleOrderRelated:
                exit(CancelPostedInvoice(SalesInvoiceHeader, Format(CorrectPostedInvoiceFromMultipleOrderQst)));
            not SalesHeaderExists:
                exit(CancelPostedInvoice(SalesInvoiceHeader, Format(CorrectPostedInvoiceFromDeletedOrderQst)));
            else
                exit(CancelPostedInvoiceAndOpenSalesOrder(SalesInvoiceHeader, SalesHeader))
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoiceAndOpenNewSalesInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        SalesHeader: Record "Sales Header";
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        IsHandled: Boolean;
    begin
        if ConfirmManagement.GetResponse(CorrectPostedInvoiceQst, false) then begin
            CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, SalesHeader);
            IsHandled := false;
            OnCorrectInvoiceOnBeforeOpenSalesInvoicePage(SalesHeader, IsHandled, SalesInvoiceHeader);
            if not IsHandled then
                PAGE.Run(PAGE::"Sales Invoice", SalesHeader);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoiceAndOpenSalesOrder(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesHeader: Record "Sales Header"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        IsHandled: Boolean;
    begin
        if ConfirmManagement.GetResponse(CorrectPostedInvoiceFromSingleOrderQst, false) then begin
            if not CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader) then
                exit(false);

            SalesHeader.Find();
            OnCorrectInvoiceOnBeforeOpenSalesOrderPage(SalesHeader, IsHandled);
            if not IsHandled then
                PAGE.Run(PAGE::"Sales Order", SalesHeader);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; ConfirmationText: Text): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        if ConfirmManagement.GetResponse(ConfirmationText, true) then
            exit(CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader));

        exit(false);
    end;

    local procedure GetRelatedOrder(SalesInvoiceHeader: Record "Sales Invoice Header"; var RelatedOrderNo: Code[20]; var MultipleOrderRelated: Boolean)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        MultipleOrderRelated := false;
        RelatedOrderNo := '';

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetFilter("Order No.", '<>''''');
        if SalesInvoiceLine.FindFirst() then begin
            RelatedOrderNo := SalesInvoiceLine."Order No.";
            SalesInvoiceLine.SetFilter("Order No.", '<>''''&<>%1', SalesInvoiceLine."Order No.");
            MultipleOrderRelated := not SalesInvoiceLine.IsEmpty();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectInvoiceOnBeforeOpenSalesInvoicePage(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean; var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectInvoiceOnBeforeOpenSalesOrderPage(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;
}

