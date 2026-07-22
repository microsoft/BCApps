// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;

codeunit 7000188 "CRTVendEntryApplyPostedEntries"
{
    var
        ApplicationEntryDescriptionLbl: Label 'Application of %1 %2', Comment = '%1 = Document Type, %2 = Document No.';
        ApplicationBillDescriptionLbl: Label 'Application of %1 %2/%3', Comment = '%1 = Document Type, %2 = Document No., %3 = Bill No.';
        CarteraApplyPositionErr: Label 'To apply a set of entries containing bills, the cursor should be positioned on an entry different than bill type or Invoice to cartera type.';
        UnapplyBlankedDocTypeErr: Label 'You cannot unapply the entries because one entry has a blank document type.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", 'OnBeforeApply', '', false, false)]
    local procedure OnBeforeApply(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var DocumentNo: Code[20]; var ApplicationDate: Date)
    begin
        if (VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Bill) or
           ((VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Invoice) and
            (VendorLedgerEntry."Document Situation" = VendorLedgerEntry."Document Situation"::Cartera) and
            (VendorLedgerEntry."Document Status" = VendorLedgerEntry."Document Status"::Open))
        then
            Error(CarteraApplyPositionErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", 'OnBeforePostApplyVendLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyVendLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        if VendorLedgerEntry."Document Type" <> VendorLedgerEntry."Document Type"::Bill then
            GenJournalLine.Description := StrSubstNo(ApplicationEntryDescriptionLbl, VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.")
        else
            GenJournalLine.Description := StrSubstNo(ApplicationBillDescriptionLbl, VendorLedgerEntry."Document Type", VendorLedgerEntry."Document No.", VendorLedgerEntry."Bill No.");

        GenJnlPostLine.SetIDBillSettlement(BeAppliedToBill(VendorLedgerEntry));
        GenJnlPostLine.SetIDInvoiceSettlement(BeAppliedToInvoice(VendorLedgerEntry));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", 'OnAfterCheckInitialDocumentType', '', false, false)]
    local procedure OnAfterCheckInitialDocumentType(var DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        if DtldVendLedgEntry."Initial Document Type" = DtldVendLedgEntry."Initial Document Type"::" " then
            Error(UnapplyBlankedDocTypeErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"VendEntry-Apply Posted Entries", 'OnPostUnApplyVendorOnAfterDtldVendLedgEntrySetFilters', '', false, false)]
    local procedure OnPostUnApplyVendorOnAfterDtldVendLedgEntrySetFilters(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; DetailedVendorLedgEntry2: Record "Detailed Vendor Ledg. Entry")
    begin
        if DetailedVendorLedgEntry.FindSet() then
            repeat
                if DetailedVendorLedgEntry."Initial Document Type" = DetailedVendorLedgEntry."Initial Document Type"::" " then
                    Error(UnapplyBlankedDocTypeErr);
            until DetailedVendorLedgEntry.Next() = 0;
    end;

    local procedure BeAppliedToBill(VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry."Applies-to ID" = '' then
            exit(false);

        VendorLedgerEntry2.SetCurrentKey("Applies-to ID", "Document Type");
        VendorLedgerEntry2.SetRange("Applies-to ID", VendorLedgerEntry."Applies-to ID");
        VendorLedgerEntry2.SetRange("Document Type", VendorLedgerEntry."Document Type"::Bill);
        exit(not VendorLedgerEntry2.IsEmpty());
    end;

    local procedure BeAppliedToInvoice(VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    var
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry."Applies-to ID" = '' then
            exit(false);

        VendorLedgerEntry2.SetCurrentKey("Applies-to ID", "Document Type");
        VendorLedgerEntry2.SetRange("Applies-to ID", VendorLedgerEntry."Applies-to ID");
        VendorLedgerEntry2.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        exit(not VendorLedgerEntry2.IsEmpty());
    end;
}
