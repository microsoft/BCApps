// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;

codeunit 7000095 "CRT Purch.-Post"
{

    var
        CannotCreateCarteraDocErr: Label 'You do not have permissions to create Documents in Cartera.\Please, change the Payment Method.';
        ClosedDocumentErr: Label 'At least one document of %1 No. %2 is closed or in a Payment Order. This will avoid the document to be settled.\The posting process of %3 No. %4 will not settle any document.\Please remove the lines for the Payment Order before posting.', Comment = '%1 = Document Type, %2 = Document No., %3 = Purchase Document Type, %4 = Purchase No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterProcessPostingLines', '', true, true)]
    local procedure OnAfterProcessPostingLines(var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var VendLedgEntry: Record "Vendor Ledger Entry"; InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean; EverythingInvoiced: Boolean; var Window: Dialog)
    var
        CarteraSetup: Record "Cartera Setup";
        PaymentMethod: Record "Payment Method";
        InvoiceSplitPayment: Codeunit "Invoice-Split Payment";
#if not CLEAN29
        PurchPost: Codeunit "Purch.-Post";
#endif
    begin
        if PaymentMethod.Get(PurchHeader."Payment Method Code") then
            if (PaymentMethod."Create Bills" or PaymentMethod."Invoices to Cartera") and
               (not CarteraSetup.ReadPermission) and PurchHeader.Invoice
            then
                Error(CannotCreateCarteraDocErr);

        if PurchHeader.Invoice and (PurchHeader."Bal. Account No." = '') and
           not PurchHeader.IsCreditDocType() and CarteraSetup.ReadPermission
        then begin
            OnBeforeCreateCarteraBills(PurchHeader, VendLedgEntry, TotalPurchLine, SuppressCommit);
#if not CLEAN29
            PurchPost.RunOnBeforeCreateCarteraBills(PurchHeader, VendLedgEntry, TotalPurchLine, SuppressCommit);
#endif
            InvoiceSplitPayment.SplitPurchInv(
              PurchHeader, VendLedgEntry, Window, InvoicePostingParameters."Source Code",
              InvoicePostingParameters."External Document No.", InvoicePostingParameters."Document No.",
              -(TotalPurchLine."Amount Including VAT" - TotalPurchLine.Amount));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCarteraBills(PurchHeader: Record "Purchase Header"; var VendLedgEntry: Record "Vendor Ledger Entry"; var TotalPurchLine: Record "Purchase Line"; CommitIsSupressed: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterCheckPostRestrictions', '', true, true)]
    local procedure OnAfterCheckPostRestrictions(var PurchaseHeader: Record "Purchase Header")
    begin
        TestPurchEffects(PurchaseHeader);
    end;

    internal procedure TestPurchEffects(PurchHeader: Record "Purchase Header")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        ShowError: Boolean;
    begin
        ShowError := false;
        if PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo" then begin
            VendLedgEntry.SetCurrentKey("Document No.", "Document Type", "Vendor No.");
            VendLedgEntry.SetFilter("Document Type", '%1|%2', VendLedgEntry."Document Type"::Invoice,
              VendLedgEntry."Document Type"::Bill);
            VendLedgEntry.SetFilter("Document Situation", '<>%1', VendLedgEntry."Document Situation"::" ");
            VendLedgEntry.SetRange("Vendor No.", PurchHeader."Pay-to Vendor No.");
            VendLedgEntry.SetRange(Open, true);
            if VendLedgEntry.FindSet() then
                repeat
                    if VendLedgEntry."Document Situation" <> VendLedgEntry."Document Situation"::Cartera then
                        if not ((VendLedgEntry."Document Situation" in
                                 [VendLedgEntry."Document Situation"::"Closed Documents",
                                  VendLedgEntry."Document Situation"::"Closed BG/PO"]) and
                                (VendLedgEntry."Document Status" = VendLedgEntry."Document Status"::Rejected))
                        then
                            ShowError := true;
                until (VendLedgEntry.Next() = 0) or ShowError;

            if ShowError then
                Error(
                    ClosedDocumentErr,
                    Format(VendLedgEntry."Document Type"), Format(VendLedgEntry."Document No."),
                    Format(PurchHeader."Document Type"), Format(PurchHeader."No."));
        end;
    end;
}