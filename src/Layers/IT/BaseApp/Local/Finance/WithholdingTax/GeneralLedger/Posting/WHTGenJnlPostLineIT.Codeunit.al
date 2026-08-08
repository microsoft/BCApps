// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.WithholdingTax;
using Microsoft.Purchases.Payables;

codeunit 12138 "WHT Gen. Jnl.-Post Line IT"
{
    var
        Text1130023: Label 'Because this invoice includes Withholding Tax, it should not be applied directly. Please use the function Payment Journals -> Payments -> Withh.Tax-Soc.Sec.';

    [Scope('OnPrem')]
    procedure CheckWithholdTax(DocType: Option " ",,Invoice,"Credit Memo"; DocNo: Code[20]; GenJnlLine: Record "Gen. Journal Line"; ApplyInGenJnlLine: Boolean)
    var
        ComputedWithholdTax: Record "Computed Withholding Tax";
        TmpWithholdingContribution: Record "Tmp Withholding Contribution";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWithholdTax(DocType, DocNo, GenJnlLine, ApplyInGenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (DocType in [DocType::Invoice, DocType::"Credit Memo"]) and
           (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Payment, GenJnlLine."Document Type"::Refund])
        then begin
            ComputedWithholdTax.Reset();
            ComputedWithholdTax.SetRange("Document No.", DocNo);
            if ComputedWithholdTax.FindFirst() then begin
                if not ApplyInGenJnlLine then
                    UpdateWithholdingTax(ComputedWithholdTax, GenJnlLine."Document No.");

                TmpWithholdingContribution.Reset();
                TmpWithholdingContribution.SetRange("Invoice No.", DocNo);
                if TmpWithholdingContribution.IsEmpty() then
                    if ApplyInGenJnlLine then
                        if (GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"G/L Account") and
                           (GenJnlLine."Payment Method Code" = '')
                        then
                            Error(Text1130023);
            end;
        end;
    end;

    local procedure UpdateWithholdTaxExtDocNo(VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJnlLine: Record "Gen. Journal Line");
    var
        WithholdingTax: Record "Withholding Tax";
        Contributions: Record Contributions;
    begin
        if (VendorLedgerEntry."Document Type" in
            [VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::Refund]) and
           (GenJnlLine."Document Type" in [GenJnlLine."Document Type"::Invoice, GenJnlLine."Document Type"::"Credit Memo"]) and
           (GenJnlLine."External Document No." <> '') and (VendorLedgerEntry."External Document No." = '')
        then begin
            WithholdingTax.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
            WithholdingTax.SetRange("Document No.", VendorLedgerEntry."Document No.");
            WithholdingTax.SetRange("Posting Date", VendorLedgerEntry."Posting Date");
            WithholdingTax.SetRange("External Document No.", '');
            if WithholdingTax.FindFirst() then begin
                WithholdingTax."External Document No." := GenJnlLine."External Document No.";
                WithholdingTax.Modify();
            end;

            Contributions.SetRange("Vendor No.", VendorLedgerEntry."Vendor No.");
            Contributions.SetRange("Document No.", VendorLedgerEntry."Document No.");
            Contributions.SetRange("Posting Date", VendorLedgerEntry."Posting Date");
            Contributions.SetRange("External Document No.", '');
            if Contributions.FindFirst() then begin
                Contributions."External Document No." := GenJnlLine."External Document No.";
                Contributions.Modify();
            end;
        end;
    end;

    local procedure UpdateWithholdingTax(ComputedWithholdTax: Record "Computed Withholding Tax"; DocNo: Code[20])
    var
        WithholdingTax: Record "Withholding Tax";
    begin
        WithholdingTax.SetCurrentKey("Vendor No.", "Document Date", "Document No.");
        WithholdingTax.SetRange("Vendor No.", ComputedWithholdTax."Vendor No.");
        WithholdingTax.SetRange("Document No.", DocNo);
        if WithholdingTax.FindFirst() then begin
            WithholdingTax."External Document No." := ComputedWithholdTax."External Document No.";
            WithholdingTax."Related Date" := ComputedWithholdTax."Related Date";
            WithholdingTax.Modify(true);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempVendLedgEntryOnBeforeCheckAgainstApplnCurrency', '', true, false)]
    local procedure OnPrepareTempVendLedgEntryOnBeforeCheckAgainstApplnCurrency(GenJournalLine: Record "Gen. Journal Line"; OldVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        CheckWithholdTax(OldVendorLedgerEntry."Document Type".AsInteger(), OldVendorLedgerEntry."Document No.", GenJournalLine, true);
        CheckWithholdTax(OldVendorLedgerEntry."Document Type".AsInteger(), OldVendorLedgerEntry."Document No.", GenJournalLine, false);
        UpdateWithholdTaxExtDocNo(OldVendorLedgerEntry, GenJournalLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempVendLedgEntryOnAfterSetFilters', '', true, false)]
    local procedure OnPrepareTempVendLedgEntryOnAfterSetFilters(var OldVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CheckWithholdTax(GenJournalLine."Applies-to Doc. Type".AsInteger(), GenJournalLine."Applies-to Doc. No.", GenJournalLine, true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempVendLedgEntryOnAfterSetFiltersBlankAppliesToDocNo', '', true, false)]
    local procedure OnPrepareTempVendLedgEntryOnAfterSetFiltersBlankAppliesToDocNo(var OldVendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CheckWithholdTax(GenJournalLine."Document Type".AsInteger(), GenJournalLine."Document No.", GenJournalLine, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWithholdTax(DocType: Option " ",,Invoice,"Credit Memo"; DocNo: Code[20]; GenJournalLine: Record "Gen. Journal Line"; ApplyInGenJnlLine: Boolean; var IsHandled: Boolean)
    begin
    end;
}
