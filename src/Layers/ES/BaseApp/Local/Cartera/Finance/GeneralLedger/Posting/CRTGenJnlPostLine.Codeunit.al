// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;

codeunit 7000110 "CRT Gen. Jnl.-Post Line"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnInsertVATOnAfterAssignVATEntryFields', '', true, false)]
    local procedure OnInsertVATOnAfterAssignVATEntryFields(var GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATEntry.SetVATCashRegime(VATPostingSetup, GenJnlLine."Gen. Posting Type".AsInteger());
        if GenJnlLine."Gen. Posting Type" = GenJnlLine."Gen. Posting Type"::Sale then
            if VATProductPostingGroup.Get(GenJnlLine."VAT Prod. Posting Group") then
                VATEntry."Delivery Operation Code" := VATProductPostingGroup."Delivery Operation Code";
        GetSellToBuyFrom(GenJnlLine, VATEntry);
        VATEntry."No Taxable Type" := VATPostingSetup."No Taxable Type";
    end;

    [Scope('OnPrem')]
    procedure GetSellToBuyFrom(GenJnlLine: Record "Gen. Journal Line"; var VATEntry: Record "VAT Entry")
    var
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        if GenJnlLine."Bill-to/Pay-to No." <> '' then begin
            VATEntry."Bill-to/Pay-to No." := GenJnlLine."Bill-to/Pay-to No.";
            exit;
        end;

        if GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::"IC Partner", GenJnlLine."Bal. Account Type"::Employee] then
            exit;
        // Find in the current transaction the customer/vendor this VAT entry is linked to
        GenJnlLine2.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Transaction No.");
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        GenJnlLine2.SetRange("Posting Date", GenJnlLine."Posting Date");
        GenJnlLine2.SetRange("Transaction No.", GenJnlLine."Transaction No.");
        GenJnlLine2.SetFilter(
          "Document Type",
          '%1|%2|%3',
          GenJnlLine2."Document Type"::Invoice,
          GenJnlLine2."Document Type"::"Credit Memo",
          GenJnlLine2."Document Type"::"Finance Charge Memo");
        GenJnlLine2.SetRange("Document No.", GenJnlLine."Document No.");
        case VATEntry.Type of
            VATEntry.Type::Sale:
                GenJnlLine2.SetRange("Account Type", GenJnlLine2."Account Type"::Customer);
            VATEntry.Type::Purchase:
                GenJnlLine2.SetRange("Account Type", GenJnlLine2."Account Type"::Vendor);
            else
                exit;
        end;
        if not GenJnlLine2.Find('-') or (GenJnlLine2.Next() <> 0) then
            Error(
              GenJnlLineNotFoundErr,
              GenJnlLine.FieldCaption(GenJnlLine."Document Type"),
              GenJnlLine.FieldCaption(GenJnlLine."Document No."),
              GenJnlLine.FieldCaption(GenJnlLine."VAT Bus. Posting Group"),
              GenJnlLine.FieldCaption(GenJnlLine."VAT Prod. Posting Group"));
        if GenJnlLine2."Bill-to/Pay-to No." <> '' then
            VATEntry."Bill-to/Pay-to No." := GenJnlLine2."Bill-to/Pay-to No."
        else
            VATEntry."Bill-to/Pay-to No." := GenJnlLine2."Account No.";

        OnAfterGetSellToBuyFrom(VATEntry, GenJnlLine2);
#if not CLEAN29
        GenJnlPostLineEvents.RunOnAfterGetSellToBuyFrom(VATEntry, GenJnlLine2);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSellToBuyFrom(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    var
#if not CLEAN29
        GenJnlPostLineEvents: Codeunit "Gen. Jnl.-Post Line";
#endif
        GenJnlLineNotFoundErr: Label 'Check that all the entries with the same %2 and a %3 and \%4 associated have a Customer/Vendor associated, check that all the lines with the same \%2 have not more than one Customer/Vendor associated, check that all the lines with same \%2 have in the field %1 the same value: Invoice, Credit Memo or Finance Charge Memo.', Comment = 'Field captions: %1 = "Document Type", %2 = "Document No.", %3 = "VAT Bus. Posting Group", %4 = "VAT Prod. Posting Group"';
}
