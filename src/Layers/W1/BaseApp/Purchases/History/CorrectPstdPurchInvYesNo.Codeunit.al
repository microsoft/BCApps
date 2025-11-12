// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Purchases.Document;
using System.Utilities;

codeunit 1324 "Correct PstdPurchInv (Yes/No)"
{
    Permissions = TableData "Purch. Inv. Header" = rm,
                  TableData "Purch. Cr. Memo Hdr." = rm;
    TableNo = "Purch. Inv. Header";

    trigger OnRun()
    begin
        CorrectInvoice(Rec);
    end;

    var
        CorrectPostedInvoiceQst: Label 'The posted purchase invoice will be canceled, and a new version of the purchase invoice will be created so that you can make the correction.\ \Do you want to continue?';
        CorrectPostedInvoiceFromSingleOrderQst: Label 'The invoice was posted from an order. The invoice will be cancelled, and the order will open so that you can make the correction.\ \Do you want to continue?';
        CorrectPostedInvoiceFromDeletedOrderQst: Label 'The invoice was posted from an order. The order has been deleted, and the invoice will be cancelled. You can create a new invoice or order by using the Copy Document action.\ \Do you want to continue?';
        CorrectPostedInvoiceFromMultipleOrderQst: Label 'The invoice was posted from multiple orders. It will now be cancelled, and you can make a correction manually in the original orders.\ \Do you want to continue?';

    procedure CorrectInvoice(var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        RelatedOrderNo: Code[20];
        MultipleOrderRelated: Boolean;
        PurchaseHeaderExists: Boolean;
    begin
        CorrectPostedPurchInvoice.TestCorrectInvoiceIsAllowed(PurchInvHeader, false);
        GetRelatedOrder(PurchInvHeader, RelatedOrderNo, MultipleOrderRelated);
        if RelatedOrderNo = '' then
            exit(CancelPostedInvoiceAndOpenNewPurchaseInvoice(PurchInvHeader));

        PurchaseHeaderExists := PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, RelatedOrderNo);
        case true of
            MultipleOrderRelated:
                exit(CancelPostedInvoice(PurchInvHeader, Format(CorrectPostedInvoiceFromMultipleOrderQst)));
            not PurchaseHeaderExists:
                exit(CancelPostedInvoice(PurchInvHeader, Format(CorrectPostedInvoiceFromDeletedOrderQst)));
            else
                exit(CancelPostedInvoiceAndOpenPurchaseOrder(PurchInvHeader, PurchaseHeader))
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoiceAndOpenNewPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        IsHandled: Boolean;
    begin
        if ConfirmManagement.GetResponse(CorrectPostedInvoiceQst, false) then begin
            CorrectPostedPurchInvoice.CancelPostedInvoiceStartNewInvoice(PurchInvHeader, PurchaseHeader);
            IsHandled := false;
            OnCancelPostedInvoiceOnBeforeShowPurchaseInvoice(PurchaseHeader, IsHandled, PurchInvHeader);
            if not IsHandled then
                PAGE.Run(PAGE::"Purchase Invoice", PurchaseHeader);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoiceAndOpenPurchaseOrder(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        if ConfirmManagement.GetResponse(CorrectPostedInvoiceFromSingleOrderQst, false) then begin
            if not CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader) then
                exit(false);

            PurchaseHeader.Find();
            PAGE.Run(PAGE::"Purchase Order", PurchaseHeader);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CancelPostedInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; ConfirmationText: Text): Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        if ConfirmManagement.GetResponse(ConfirmationText, true) then
            exit(CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader));

        exit(false);
    end;

    local procedure GetRelatedOrder(PurchInvHeader: Record "Purch. Inv. Header"; var RelatedOrderNo: Code[20]; var MultipleOrderRelated: Boolean)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        MultipleOrderRelated := false;
        RelatedOrderNo := '';

        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.SetFilter("Order No.", '<>''''');
        if PurchInvLine.FindFirst() then begin
            RelatedOrderNo := PurchInvLine."Order No.";
            PurchInvLine.SetFilter("Order No.", '<>''''&<>%1', PurchInvLine."Order No.");
            MultipleOrderRelated := not PurchInvLine.IsEmpty();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelPostedInvoiceOnBeforeShowPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PurchInvHeader: Record "Purch. Inv. Header")
    begin
    end;
}

