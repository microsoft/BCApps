// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 7000094 "CRT Gen. Journal Line"
{
    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo, '', false, false)]
    local procedure OnLookUpAppliesToDocCustOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        GenJournalLine."Applies-to Bill No." := CustLedgerEntry."Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo, '', false, false)]
    local procedure OnLookUpAppliesToDocVendOnAfterUpdateDocumentTypeAndAppliesTo(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        GenJournalLine."Applies-to Bill No." := VendorLedgerEntry."Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnFindFirstCustLedgEntryWithAppliesToDocNoOnAfterSetFilters, '', false, false)]
    local procedure OnFindFirstCustLedgEntryWithAppliesToDocNoOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.SetRange("Bill No.", GenJournalLine."Applies-to Bill No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnFindFirstVendLedgEntryWithAppliesToDocNoOnAfterSetFilters, '', false, false)]
    local procedure OnFindFirstVendLedgEntryWithAppliesToDocNoOnAfterSetFilters(var GenJournalLine: Record "Gen. Journal Line"; AccNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange("Bill No.", GenJournalLine."Applies-to Bill No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate, '', false, false)]
    local procedure OnValidatePaymentTermsCodeOnBeforeCalculatePmtDiscountDate(var GenJournalLine: Record "Gen. Journal Line"; PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
        case GenJournalLine."Document Type" of
            GenJournalLine."Document Type"::Invoice:
                GenJournalLine.AdjustDueDate(PaymentTerms.CalculateMaxDueDate(GenJournalLine."Document Date"));
            GenJournalLine."Document Type"::"Credit Memo":
                GenJournalLine.AdjustDueDate(99991231D);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", OnValidatePaymentTermsCodeOnElseCase, '', false, false)]
    local procedure OnValidatePaymentTermsCodeOnElseCase(var Rec: Record "Gen. Journal Line"; var PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
        if not (Rec."Document Type" = Rec."Document Type"::Bill) then
            exit;

        if (Rec."Payment Terms Code" <> '') and (Rec."Document Date" <> 0D) then begin
            PaymentTerms.Get(Rec."Payment Terms Code");
            Rec."Due Date" := CalcDate(PaymentTerms."Due Date Calculation", Rec."Document Date");
            Rec.AdjustDueDate(99991231D);
        end else
            Rec."Due Date" := Rec."Document Date";
    end;
}
