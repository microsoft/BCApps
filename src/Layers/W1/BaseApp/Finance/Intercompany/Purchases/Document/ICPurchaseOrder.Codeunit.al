// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Outbox;

codeunit 8450 "IC Purchase Order"
{
    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnAfterOpenPage', '', false, false)]
    local procedure OnAfterOpenPage(var PurchaseHeader: Record "Purchase Header")
    var
        IncomingICPurchHeader: Record "Purchase Header";
        ICInboxOutboxMgt: Codeunit ICInboxOutboxMgt;
    begin
        if ICInboxOutboxMgt.IsPurchaseHeaderFromIncomingIC(PurchaseHeader) then begin
            IncomingICPurchHeader.SetRange("IC Direction", IncomingICPurchHeader."IC Direction"::Incoming);
            IncomingICPurchHeader.SetFilter("IC Reference Document No.", '<>%1', '');
            IncomingICPurchHeader.SetRange("Buy-from IC Partner Code", PurchaseHeader."Buy-from IC Partner Code");
            IncomingICPurchHeader.SetRange("Document Type", IncomingICPurchHeader."Document Type"::Invoice);
            IncomingICPurchHeader.SetRange("Vendor Order No.", PurchaseHeader."Vendor Order No.");
            if IncomingICPurchHeader.FindFirst() then
                ICInboxOutboxMgt.ShowDuplicateICDocumentWarning(IncomingICPurchHeader);
        end;
        if (PurchaseHeader."IC Direction" = PurchaseHeader."IC Direction"::Outgoing) and
           (PurchaseHeader."Buy-from IC Partner Code" <> '') and
           (PurchaseHeader."IC Status" = PurchaseHeader."IC Status"::Sent)
        then begin
            IncomingICPurchHeader.Reset();
            IncomingICPurchHeader.SetRange("IC Direction", IncomingICPurchHeader."IC Direction"::Incoming);
            IncomingICPurchHeader.SetRange("Buy-from IC Partner Code", PurchaseHeader."Buy-from IC Partner Code");
            IncomingICPurchHeader.SetRange("Document Type", IncomingICPurchHeader."Document Type"::Invoice);
            IncomingICPurchHeader.SetRange("Your Reference", PurchaseHeader."No.");
            if IncomingICPurchHeader.FindFirst() then
                ICInboxOutboxMgt.ShowDuplicateICDocumentWarning(IncomingICPurchHeader, ICIncomingInvoiceFromOriginalOrderMsg);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnShowPostedConfirmationMessageIC', '', false, false)]
    local procedure OnShowPostedConfirmationMessageIC(var PurchaseHeader: Record "Purchase Header")
    var
        ICFeedback: Codeunit "IC Feedback";
    begin
        ICFeedback.ShowIntercompanyMessage(PurchaseHeader, Enum::"IC Transaction Document Type"::Order);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        ICIncomingInvoiceFromOriginalOrderMsg: Label 'There is an %1 with no. %2 received from intercompany after you sent this order. You can remove this order and post that invoice instead.', Comment = '%1 - either "order", "invoice", or "posted invoice", %2 - a code';
#pragma warning restore AA0470
#pragma warning restore AA0074
}
