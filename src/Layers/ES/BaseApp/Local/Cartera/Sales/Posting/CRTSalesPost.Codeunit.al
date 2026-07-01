// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;

codeunit 7000096 "CRT Sales-Post"
{
    Access = Internal;

    var
        CannotCreateCarteraDocErr: Label 'You do not have permissions to create Documents in Cartera.\Please, change the Payment Method.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterProcessPostingLines', '', true, true)]
    local procedure OnAfterProcessPostingLines(var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var CustLedgEntry: Record "Cust. Ledger Entry"; InvoicePostingParameters: Record "Invoice Posting Parameters"; SuppressCommit: Boolean; EverythingInvoiced: Boolean; var Window: Dialog; HideProgressWindow: Boolean)
    var
        CarteraSetup: Record "Cartera Setup";
        PaymentMethod: Record "Payment Method";
        InvoiceSplitPayment: Codeunit "Invoice-Split Payment";
#if not CLEAN29
        SalesPost: Codeunit "Sales-Post";
#endif
    begin
        // Create Bills
        if PaymentMethod.Get(SalesHeader."Payment Method Code") then
            if (PaymentMethod."Create Bills" or PaymentMethod."Invoices to Cartera") and
               (not CarteraSetup.ReadPermission) and SalesHeader.Invoice
            then
                Error(CannotCreateCarteraDocErr);

        if SalesHeader.Invoice and (SalesHeader."Bal. Account No." = '') and
           (not SalesHeader.IsCreditDocType()) and CarteraSetup.ReadPermission
        then begin
            OnBeforeCreateCarteraBills(SalesHeader, CustLedgEntry, TotalSalesLine);
#if not CLEAN29
            SalesPost.RunOnBeforeCreateCarteraBills(SalesHeader, CustLedgEntry, TotalSalesLine);
#endif
            InvoiceSplitPayment.SplitSalesInv(
                SalesHeader, CustLedgEntry, Window, InvoicePostingParameters."Source Code",
                InvoicePostingParameters."External Document No.", InvoicePostingParameters."Document No.",
                -(TotalSalesLine."Amount Including VAT" - TotalSalesLine.Amount), HideProgressWindow);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateCarteraBills(SalesHeader: Record "Sales Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var TotalSalesLine: Record "Sales Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnAfterCheckPostRestrictions', '', true, true)]
    local procedure OnAfterCheckPostRestrictions(var SalesHeader: Record "Sales Header")
    begin
        TestSalesEffects(SalesHeader);
    end;

    internal procedure TestSalesEffects(SalesHeader: Record "Sales Header")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        ShowError: Boolean;
        ClosedDocumentErr: Label 'At least one document of %1 No. %2 is closed or in a Bill Group. This will avoid the document to be settled.\The posting process of %3 No. %4 will not settle any document.\ Please remove the lines for the Bill Group before posting.', Comment = '%1 = Document Type, %2 = Document No., %3 = Document Type, %4 = Document No.';
    begin
        ShowError := false;
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then begin
            CustLedgEntry.SetCurrentKey("Document No.", "Document Type", "Customer No.");
            CustLedgEntry.SetFilter("Document Type", '%1|%2', CustLedgEntry."Document Type"::Invoice,
              CustLedgEntry."Document Type"::Bill);
            CustLedgEntry.SetFilter("Document Situation", '<>%1', CustLedgEntry."Document Situation"::" ");
            CustLedgEntry.SetRange("Customer No.", SalesHeader."Bill-to Customer No.");
            CustLedgEntry.SetRange(Open, true);

            if CustLedgEntry.Find('-') then
                repeat
                    if CustLedgEntry."Document Situation" <> CustLedgEntry."Document Situation"::Cartera then
                        if not ((CustLedgEntry."Document Situation" in
                                 [CustLedgEntry."Document Situation"::"Closed Documents",
                                  CustLedgEntry."Document Situation"::"Closed BG/PO"]) and
                                (CustLedgEntry."Document Status" = CustLedgEntry."Document Status"::Rejected))
                        then
                            ShowError := true;
                until CustLedgEntry.Next() = 0;

            if ShowError then
                Error(
                    ClosedDocumentErr,
                    Format(CustLedgEntry."Document Type"),
                    Format(CustLedgEntry."Document No."),
                    Format(SalesHeader."Document Type"),
                    Format(SalesHeader."No."));
        end;
    end;
}
