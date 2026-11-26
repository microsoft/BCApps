// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Sales.Document;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

codeunit 8845 "Sales Installment Correction"
{
    Access = Internal;
    Permissions = tabledata "Cust. Ledger Entry" = rm;

    var
        OwnershipErr: Label 'The posted installment schedule and customer entries do not match the invoice.';
        UnpaidErr: Label 'Automatic correction requires every installment to be fully unpaid. Select open installments manually using Applies-to ID.';
        AllocationErr: Label 'Select individual installment entries using Applies-to ID when posting a partial credit or crediting a partly paid installment invoice.';

    internal procedure CheckInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; RequireUnpaid: Boolean)
    var
        Plan: Record "Sales Installment Plan";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InstallmentCount: Integer;
        Sequence: Integer;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
    begin
        if IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then
            exit;
        Plan.Get(SalesInvoiceHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Posted);
        Plan.TestField("Posted Invoice No.", SalesInvoiceHeader."No.");
        Plan.TestField("Posted Invoice SystemId", SalesInvoiceHeader.SystemId);
        Plan.TestField("Currency Code", SalesInvoiceHeader."Currency Code");
        PlanLine.SetCurrentKey("Plan ID", "Installment No.");
        PlanLine.SetRange("Plan ID", Plan.ID);
        InstallmentCount := PlanLine.Count();
        CustLedgerEntry.SetRange("Installment Plan ID", Plan.ID);
        if (InstallmentCount = 0) or (CustLedgerEntry.Count() <> InstallmentCount) then
            Error(OwnershipErr);
        CustLedgerEntry.SetAutoCalcFields("Original Amount", "Original Amt. (LCY)", "Remaining Amount");
        PlanLine.FindSet();
        repeat
            Sequence += 1;
            PlanLine.TestField("Installment No.", Sequence);
            CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
            CustLedgerEntry.TestField("Installment Plan ID", Plan.ID);
            CustLedgerEntry.TestField("Installment No.", Sequence);
            CustLedgerEntry.TestField("No. of Installments", InstallmentCount);
            CustLedgerEntry.TestField("Invoice Entry No.", SalesInvoiceHeader."Cust. Ledger Entry No.");
            CustLedgerEntry.TestField("Document Type", CustLedgerEntry."Document Type"::Invoice);
            CustLedgerEntry.TestField("Document No.", SalesInvoiceHeader."No.");
            CustLedgerEntry.TestField("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
            CustLedgerEntry.TestField("Currency Code", SalesInvoiceHeader."Currency Code");
            CustLedgerEntry.TestField("Due Date", PlanLine."Due Date");
            CustLedgerEntry.TestField("Original Amount", PlanLine.Amount);
            CustLedgerEntry.TestField("Original Amt. (LCY)", PlanLine."Amount (LCY)");
            if RequireUnpaid then begin
                if not CustLedgerEntry.Open or (CustLedgerEntry."Remaining Amount" <> PlanLine.Amount) then
                    Error(UnpaidErr);
                CustLedgerEntry.TestField("Applies-to ID", '');
            end;
            TotalAmount += PlanLine.Amount;
            TotalAmountLCY += PlanLine."Amount (LCY)";
        until PlanLine.Next() = 0;
        SalesInvoiceHeader.TestField("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        Plan.TestField(Amount, TotalAmount);
        Plan.TestField("Amount (LCY)", TotalAmountLCY);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        SalesInvoiceHeader.TestField("Amount Including VAT", TotalAmount);
        OnAfterCheckInvoice(SalesInvoiceHeader);
    end;

    internal procedure PrepareCreditApplication(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplicationID: Code[50];
    begin
        if not GetCreditInvoice(SalesHeader, SalesInvoiceHeader) then
            exit;
        SalesHeader.TestField("Bill-to Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        SalesHeader.TestField("Currency Code", SalesInvoiceHeader."Currency Code");
        CustLedgerEntry.LockTable();
        if not SalesInvoiceHeader.IsFullyOpen() then
            Error(AllocationErr);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        if GenJournalLine.Amount <> -SalesInvoiceHeader."Amount Including VAT" then
            Error(AllocationErr);
        CheckInvoice(SalesInvoiceHeader, true);
        ApplicationID := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ApplicationID));
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount");
        CustLedgerEntry.FindSet(true);
        repeat
            CustLedgerEntry."Applies-to ID" := ApplicationID;
            CustLedgerEntry."Amount to Apply" := CustLedgerEntry."Remaining Amount";
            CustLedgerEntry."Accepted Payment Tolerance" := 0;
            CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
            CustLedgerEntry.Modify(true);
        until CustLedgerEntry.Next() = 0;
        // Keep the document link on the credit memo for native cancellation and navigation.
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::" ";
        GenJournalLine."Applies-to Doc. No." := '';
        GenJournalLine."Applies-to ID" := ApplicationID;
    end;

    local procedure GetCreditInvoice(SalesHeader: Record "Sales Header"; var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        if (SalesHeader."Document Type" <> SalesHeader."Document Type"::"Credit Memo") or
           (SalesHeader."Applies-to Doc. Type" <> SalesHeader."Applies-to Doc. Type"::Invoice) or
           (SalesHeader."Applies-to Doc. No." = '') or (SalesHeader."Applies-to ID" <> '')
        then
            exit(false);
        if not SalesInvoiceHeader.Get(SalesHeader."Applies-to Doc. No.") then
            exit(false);
        exit(not IsNullGuid(SalesInvoiceHeader."Installment Plan ID"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeCopySalesHeaderFromPostedInvoice', '', false, false)]
    local procedure PrepareReplacementSchedule(var ToSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if (ToSalesHeader."Document Type" <> ToSalesHeader."Document Type"::Invoice) or
           IsNullGuid(SalesInvoiceHeader."Installment Plan ID")
        then
            exit;
        CheckInvoice(SalesInvoiceHeader, false);
        // Customer validation must see the frozen rules before it validates payment terms.
        ToSalesHeader."Installment Plan ID" := SalesInvoiceHeader."Installment Plan ID";
        ToSalesHeader.Validate("Payment Terms Code", SalesInvoiceHeader."Payment Terms Code");
        ToSalesHeader.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnCopySalesDocOnAfterTransferPostedInvoiceFields', '', false, false)]
    local procedure ClearCreditSchedule(var ToSalesHeader: Record "Sales Header"; SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then
            exit;
        CheckInvoice(SalesInvoiceHeader, false);
        if ToSalesHeader."Document Type" = ToSalesHeader."Document Type"::"Credit Memo" then
            Clear(ToSalesHeader."Installment Plan ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeUpdateCustLedgEntry', '', false, false)]
    local procedure SetCreditDocumentLink(var ToSalesHeader: Record "Sales Header"; var IsHandled: Boolean; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if IsHandled or (ToSalesHeader."Document Type" <> ToSalesHeader."Document Type"::"Credit Memo") or
           (FromDocType <> "Sales Document Type From"::"Posted Invoice")
        then
            exit;
        SalesInvoiceHeader.Get(FromDocNo);
        if IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then
            exit;
        CheckInvoice(SalesInvoiceHeader, false);
        ToSalesHeader."Bal. Account No." := '';
        if SalesInvoiceHeader.IsFullyOpen() then begin
            ToSalesHeader."Applies-to Doc. Type" := ToSalesHeader."Applies-to Doc. Type"::Invoice;
            ToSalesHeader."Applies-to Doc. No." := SalesInvoiceHeader."No.";
        end;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnBeforeCreateCreditMemoCopyDocument', '', false, false)]
    local procedure CheckCreditCopy(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CheckInvoice(SalesInvoiceHeader, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnBeforeSalesHeaderInsert', '', false, false)]
    local procedure CheckCorrectionSource(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CheckInvoice(SalesInvoiceHeader, false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnAfterTestCorrectInvoiceIsAllowed', '', false, false)]
    local procedure CheckAutomaticCorrection(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        CheckInvoice(SalesInvoiceHeader, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnBeforeUnapplyCostApplication', '', false, false)]
    local procedure CheckBeforeCostUnapplication(InvNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        SalesInvoiceHeader.Get(InvNo);
        if not IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then
            CorrectPostedSalesInvoice.TestCorrectInvoiceIsAllowed(SalesInvoiceHeader, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnRunOnBeforePostCorrectiveSalesCrMemo', '', false, false)]
    local procedure SuppressCorrectionCommit(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SuppressCommit: Boolean)
    begin
        if not IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then begin
            CheckInvoice(SalesInvoiceHeader, true);
            SuppressCommit := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforePostCommitSalesDoc', '', false, false)]
    local procedure SuppressCreditCommit(var SalesHeader: Record "Sales Header"; var CommitIsSuppressed: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if GetCreditInvoice(SalesHeader, SalesInvoiceHeader) then
            CommitIsSuppressed := true;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckInvoice(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
    end;
}
