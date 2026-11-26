// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Intercompany;

/// <summary>
/// Extends Purchase Invoice with Intercompany-specific actions.
/// Adds the Reject IC Purchase Invoice action and tracks whether the current invoice is incoming IC.
/// Shows warnings for duplicate intercompany documents when the page opens.
/// </summary>
pageextension 8456 ICPurchaseInvoice extends "Purchase Invoice"
{
    actions
    {
        addafter(Reopen)
        {
            action("Reject IC Purchase Invoice")
            {
                ApplicationArea = Intercompany;
                Caption = 'Reject IC Purchase Invoice';
                Enabled = RejectICPurchaseInvoiceEnabled;
                Image = Cancel;
                ToolTip = 'Deletes the invoice and sends the rejection to the company that created it.';

                trigger OnAction()
                var
                    ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
                begin
                    if not ICInboxOutboxMgt.IsPurchaseHeaderFromIncomingIC(Rec) then
                        exit;
                    if Confirm(SureToRejectMsg) then
                        ICInboxOutboxMgt.RejectAcceptedPurchaseHeader(Rec);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        RejectICPurchaseInvoiceEnabled := ICInboxOutboxMgt.IsPurchaseHeaderFromIncomingIC(Rec);
    end;

    trigger OnOpenPage()
    begin
        CheckIncomingICPurchaseInvoiceDuplicates(Rec);
    end;

    var
        SureToRejectMsg: Label 'Do you want to reject this Intercompany purchase invoice?';
        ICIncomingInvoiceFromOriginalOrderMsg: Label 'This invoice was received through intercompany and it''s related to the purchase %1 with no. %2. You can delete that order and post this invoice.', Comment = '%1 - either "order", "invoice", or "posted invoice", %2 - a code';
        RejectICPurchaseInvoiceEnabled: Boolean;

    local procedure CheckIncomingICPurchaseInvoiceDuplicates(var PurchaseHeader: Record "Purchase Header")
    var
        ICDuplicatePurchHeader: Record "Purchase Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        if not ICInboxOutboxMgt.IsPurchaseHeaderFromIncomingIC(PurchaseHeader) then
            exit;
        ICDuplicatePurchHeader.SetRange("IC Direction", ICDuplicatePurchHeader."IC Direction"::Incoming);
        ICDuplicatePurchHeader.SetRange("IC Reference Document No.", PurchaseHeader."Vendor Order No.");
        ICDuplicatePurchHeader.SetRange("Buy-from IC Partner Code", PurchaseHeader."Buy-from IC Partner Code");
        ICDuplicatePurchHeader.SetRange("Document Type", ICDuplicatePurchHeader."Document Type"::Order);
        if ICDuplicatePurchHeader.FindFirst() then
            ICInboxOutboxMgt.ShowDuplicateICDocumentWarning(ICDuplicatePurchHeader);
        ICDuplicatePurchHeader.Reset();
        if ICDuplicatePurchHeader.Get(ICDuplicatePurchHeader."Document Type"::Order, CopyStr(PurchaseHeader."Your Reference", 1, MaxStrLen(PurchaseHeader."No."))) then
            if (ICDuplicatePurchHeader."IC Direction" = ICDuplicatePurchHeader."IC Direction"::Outgoing) and
               (ICDuplicatePurchHeader."Buy-from IC Partner Code" = PurchaseHeader."Buy-from IC Partner Code") and
               (ICDuplicatePurchHeader."IC Status" = ICDuplicatePurchHeader."IC Status"::Sent) then
                ICInboxOutboxMgt.ShowDuplicateICDocumentWarning(ICDuplicatePurchHeader, ICIncomingInvoiceFromOriginalOrderMsg);
    end;
}
