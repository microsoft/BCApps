// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Posting;
using Microsoft.Utilities;

codeunit 8849 "Purchase Installment Correction"
{
    Access = Internal;
    Permissions = tabledata "Vendor Ledger Entry" = rm;

    var
        OwnershipErr: Label 'The posted installment schedule and vendor entries do not match the invoice.';
        UnpaidErr: Label 'Automatic correction requires every installment to be fully unpaid. Select open installments manually using Applies-to ID.';
        AllocationErr: Label 'Select individual installment entries using Applies-to ID when posting a partial credit or crediting a partly paid installment invoice.';

    internal procedure CheckInvoice(PurchInvHeader: Record "Purch. Inv. Header"; RequireUnpaid: Boolean)
    var
        Plan: Record "Purchase Installment Plan";
        PlanLine: Record "Purchase Installment Plan Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InstallmentCount: Integer;
        Sequence: Integer;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
    begin
        if IsNullGuid(PurchInvHeader."Installment Plan ID") then
            exit;
        Plan.Get(PurchInvHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Posted);
        Plan.TestField("Posted Invoice No.", PurchInvHeader."No.");
        Plan.TestField("Posted Invoice SystemId", PurchInvHeader.SystemId);
        Plan.TestField("Currency Code", PurchInvHeader."Currency Code");
        PlanLine.SetCurrentKey("Plan ID", "Installment No.");
        PlanLine.SetRange("Plan ID", Plan.ID);
        InstallmentCount := PlanLine.Count();
        VendorLedgerEntry.SetRange("Installment Plan ID", Plan.ID);
        if (InstallmentCount = 0) or (VendorLedgerEntry.Count() <> InstallmentCount) then
            Error(OwnershipErr);
        PlanLine.FindSet();
        repeat
            Sequence += 1;
            PlanLine.TestField("Installment No.", Sequence);
            VendorLedgerEntry.Get(PlanLine."Vendor Ledger Entry No.");
            VendorLedgerEntry.TestField("Installment Plan ID", Plan.ID);
            VendorLedgerEntry.TestField("Installment No.", Sequence);
            VendorLedgerEntry.TestField("No. of Installments", InstallmentCount);
            VendorLedgerEntry.TestField("Invoice Entry No.", PurchInvHeader."Vendor Ledger Entry No.");
            VendorLedgerEntry.TestField("Document Type", VendorLedgerEntry."Document Type"::Invoice);
            VendorLedgerEntry.TestField("Document No.", PurchInvHeader."No.");
            VendorLedgerEntry.TestField("Vendor No.", PurchInvHeader."Pay-to Vendor No.");
            VendorLedgerEntry.TestField("Currency Code", PurchInvHeader."Currency Code");
            VendorLedgerEntry.TestField("Due Date", PlanLine."Due Date");
            VendorLedgerEntry.CalcFields("Original Amount", "Original Amt. (LCY)", "Remaining Amount");
            VendorLedgerEntry.TestField("Original Amount", -PlanLine.Amount);
            VendorLedgerEntry.TestField("Original Amt. (LCY)", -PlanLine."Amount (LCY)");
            if RequireUnpaid then begin
                if not VendorLedgerEntry.Open or (VendorLedgerEntry."Remaining Amount" <> -PlanLine.Amount) then
                    Error(UnpaidErr);
                VendorLedgerEntry.TestField("Applies-to ID", '');
            end;
            TotalAmount += PlanLine.Amount;
            TotalAmountLCY += PlanLine."Amount (LCY)";
        until PlanLine.Next() = 0;
        PurchInvHeader.TestField("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
        Plan.TestField(Amount, TotalAmount);
        Plan.TestField("Amount (LCY)", TotalAmountLCY);
        PurchInvHeader.CalcFields("Amount Including VAT");
        PurchInvHeader.TestField("Amount Including VAT", TotalAmount);
    end;

    internal procedure PrepareCreditApplication(PurchaseHeader: Record "Purchase Header"; var GenJournalLine: Record "Gen. Journal Line")
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ApplicationID: Code[50];
    begin
        if not GetCreditInvoice(PurchaseHeader, PurchInvHeader) then
            exit;
        PurchaseHeader.TestField("Pay-to Vendor No.", PurchInvHeader."Pay-to Vendor No.");
        PurchaseHeader.TestField("Currency Code", PurchInvHeader."Currency Code");
        VendorLedgerEntry.LockTable();
        if not PurchInvHeader.IsFullyOpen() then
            Error(AllocationErr);
        PurchInvHeader.CalcFields("Amount Including VAT");
        if GenJournalLine.Amount <> PurchInvHeader."Amount Including VAT" then
            Error(AllocationErr);
        CheckInvoice(PurchInvHeader, true);
        ApplicationID := CopyStr(Format(CreateGuid()), 1, MaxStrLen(ApplicationID));
        VendorLedgerEntry.SetRange("Installment Plan ID", PurchInvHeader."Installment Plan ID");
        VendorLedgerEntry.FindSet(true);
        repeat
            VendorLedgerEntry.CalcFields("Remaining Amount");
            VendorLedgerEntry."Applies-to ID" := ApplicationID;
            VendorLedgerEntry."Amount to Apply" := VendorLedgerEntry."Remaining Amount";
            VendorLedgerEntry."Accepted Payment Tolerance" := 0;
            VendorLedgerEntry."Accepted Pmt. Disc. Tolerance" := false;
            VendorLedgerEntry.Modify(true);
        until VendorLedgerEntry.Next() = 0;
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::" ";
        GenJournalLine."Applies-to Doc. No." := '';
        GenJournalLine."Applies-to ID" := ApplicationID;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterCopyPostedPurchInvoice', '', false, false)]
#pragma warning disable AA0150
    local procedure PrepareCopiedSchedule(var ToPurchaseHeader: Record "Purchase Header"; OldPurchaseHeader: Record "Purchase Header"; PurchInvHeader: Record "Purch. Inv. Header")
    begin
        if IsNullGuid(PurchInvHeader."Installment Plan ID") then
            exit;
        CheckInvoice(PurchInvHeader, false);
        if ToPurchaseHeader."Document Type" = ToPurchaseHeader."Document Type"::"Credit Memo" then
            Clear(ToPurchaseHeader."Installment Plan ID")
        else
            if ToPurchaseHeader."Document Type" = ToPurchaseHeader."Document Type"::Invoice then begin
                ToPurchaseHeader."Installment Plan ID" := PurchInvHeader."Installment Plan ID";
                ToPurchaseHeader.Validate("Payment Terms Code", PurchInvHeader."Payment Terms Code");
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnBeforeUpdateVendLedgEntry', '', false, false)]
    local procedure SetCreditDocumentLink(var ToPurchaseHeader: Record "Purchase Header"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean; FromDocType: Enum "Gen. Journal Document Type"; FromDocNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if IsHandled or (ToPurchaseHeader."Document Type" <> ToPurchaseHeader."Document Type"::"Credit Memo") or
           (FromDocType <> FromDocType::Invoice)
        then
            exit;
        PurchInvHeader.Get(FromDocNo);
        if IsNullGuid(PurchInvHeader."Installment Plan ID") then
            exit;
        CheckInvoice(PurchInvHeader, false);
        ToPurchaseHeader."Bal. Account No." := '';
        if PurchInvHeader.IsFullyOpen() then begin
            ToPurchaseHeader."Applies-to Doc. Type" := ToPurchaseHeader."Applies-to Doc. Type"::Invoice;
            ToPurchaseHeader."Applies-to Doc. No." := PurchInvHeader."No.";
        end;
        IsHandled := true;
    end;
#pragma warning restore AA0150

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Purch Invoice", 'OnAfterTestCorrectInvoiceIsAllowed', '', false, false)]
    local procedure CheckAutomaticCorrection(var PurchInvHeader: Record "Purch. Inv. Header"; Cancelling: Boolean)
    begin
        CheckInvoice(PurchInvHeader, Cancelling);
    end;

    local procedure GetCreditInvoice(PurchaseHeader: Record "Purchase Header"; var PurchInvHeader: Record "Purch. Inv. Header"): Boolean
    begin
        if (PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::"Credit Memo") or
           (PurchaseHeader."Applies-to Doc. Type" <> PurchaseHeader."Applies-to Doc. Type"::Invoice) or
           (PurchaseHeader."Applies-to Doc. No." = '') or (PurchaseHeader."Applies-to ID" <> '')
        then
            exit(false);
        if not PurchInvHeader.Get(PurchaseHeader."Applies-to Doc. No.") then
            exit(false);
        exit(not IsNullGuid(PurchInvHeader."Installment Plan ID"));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostCommitPurchaseDoc', '', false, false)]
    local procedure SuppressCreditCommit(var PurchaseHeader: Record "Purchase Header"; var CommitIsSuppressed: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        if GetCreditInvoice(PurchaseHeader, PurchInvHeader) then
            CommitIsSuppressed := true;
    end;
}
