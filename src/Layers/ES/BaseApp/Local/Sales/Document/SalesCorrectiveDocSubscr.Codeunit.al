// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Utilities;

#pragma warning disable AS0088
codeunit 7000094 "Sales Corrective Doc. Subscr."
{
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnValidateBillToCustomerNoOnAfterResetSalesLines', '', true, false)]
    local procedure OnValidateBillToCustomerNoOnAfterResetSalesLines(var SalesHeader: Record "Sales Header"; xSalesHeader: Record "Sales Header")
    begin
        if xSalesHeader."Bill-to Customer No." <> SalesHeader."Bill-to Customer No." then
            SalesHeader."Corrected Invoice No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnCopyFromGenJnlLineOnAfterCopyFields', '', true, false)]
    local procedure OnCopyFromGenJnlLineOnAfterCopyFields(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgerEntry."Correction Type" := GenJournalLine."Correction Type";
        CustLedgerEntry."Corrected Invoice No." := GenJournalLine."Corrected Invoice No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice", 'OnPostLedgerEntryOnCopyHeaderFields', '', true, false)]
    local procedure OnPostLedgerEntryOnCopyHeaderFields(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
        GenJnlLine."Correction Type" := SalesHeader."Correction Type";
        GenJnlLine."Corrected Invoice No." := SalesHeader."Corrected Invoice No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Credit Memo Hdr. - Edit", 'OnRunOnAfterCopyHeaderFields', '', true, false)]
    local procedure OnRunOnAfterCopyHeaderFields(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; FromSalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        SalesCrMemoHeader."Correction Type" := FromSalesCrMemoHeader."Correction Type";
        SalesCrMemoHeader."Corrected Invoice No." := FromSalesCrMemoHeader."Corrected Invoice No.";
    end;

    [EventSubscriber(ObjectType::Page, Page::"Pstd. Sales Cr. Memo - Update", 'OnRecordChangedOnAfterCompareFields', '', true, false)]
    local procedure OnRecordChangedOnAfterCompareFields(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; xSalesCrMemoHeader: Record "Sales Cr.Memo Header"; var IsChanged: Boolean)
    begin
        IsChanged := IsChanged or
          (SalesCrMemoHeader."Correction Type" <> xSalesCrMemoHeader."Correction Type") or
          (SalesCrMemoHeader."Corrected Invoice No." <> xSalesCrMemoHeader."Corrected Invoice No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnCopyInvoiceToCreditMemoHeader', '', true, false)]
    local procedure OnCopyInvoiceToCreditMemoHeader(var SalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesHeader."Corrected Invoice No." := SalesInvoiceHeader."No.";
    end;

    [EventSubscriber(ObjectType::Report, Report::"Combine Return Receipts", 'OnCopySalesOrderToCrMemoHeader', '', true, false)]
    local procedure OnCopySalesOrderToCrMemoHeader(var SalesHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header")
    begin
        SalesHeader."Corrected Invoice No." := SalesOrderHeader."Corrected Invoice No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnCheckCorrectedInvoice', '', true, false)]
    local procedure OnCheckCorrectedInvoice(var SalesHeader: Record "Sales Header"; SalesSetup: Record "Sales & Receivables Setup")
    var
        SalesPost: Codeunit "Sales-Post";
        ConfirmManagement: Codeunit "Confirm Management";
        MissingCorrectedInvoiceQst: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        PostingCancelledErr: Label 'The posting process has been cancelled by the user.';
        CorrectiveInvoiceLbl: Label 'Corrective Invoice';
    begin
        if (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo") or
           ((SalesHeader."Document Type" = SalesHeader."Document Type"::"Return Order") and SalesHeader.Invoice)
        then begin
            if SalesSetup."Correct. Doc. No. Mandatory" then
                SalesHeader.TestField("Corrected Invoice No.")
            else begin
                if SalesHeader."Correction Type" in [SalesHeader."Correction Type"::Replacement, SalesHeader."Correction Type"::Removal] then
                    SalesHeader.TestField("Corrected Invoice No.");
                SalesPost.OnCheckCorrectedInvoiceOnBeforeConfirm(SalesHeader);
                if SalesHeader."Corrected Invoice No." = '' then
                    if not ConfirmManagement.GetResponseOrDefault(MissingCorrectedInvoiceQst, true) then
                        Error(PostingCancelledErr);
            end;
            if (SalesHeader."Corrected Invoice No." <> '') and (SalesHeader."Posting Description" = '') then
                SalesHeader."Posting Description" := Format(CorrectiveInvoiceLbl) + ' ' + SalesHeader."No."
        end;
    end;
}
