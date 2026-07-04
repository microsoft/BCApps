// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.ReceivablesPayables;

codeunit 7000112 "CRTCustEntryApplyPostedEnt"
{
    var
        ApplicationEntryDescriptionLbl: Label 'Application of %1 %2', Comment = '%1 = Document Type, %2 = Document No.';
        ApplicationBillDescriptionLbl: Label 'Application of %1 %2/%3', Comment = '%1 = Document Type, %2 = Document No., %3 = Bill No.';
        CarteraApplyPositionErr: Label 'To apply a set of entries containing bills, rejected invoices or invoices to cartera, the cursor should be positioned on an entry different than bill type, rejected invoice or invoices to cartera.';
        UnapplyBlankedDocTypeErr: Label 'You cannot unapply the entries because one entry has a blank document type.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforeApply', '', false, false)]
    local procedure OnBeforeApply(var CustLedgerEntry: Record "Cust. Ledger Entry"; var DocumentNo: Code[20]; var ApplicationDate: Date)
    begin
        if (CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Bill) or
           ((CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice) and
            (CustLedgerEntry."Document Situation" = CustLedgerEntry."Document Situation"::"Closed BG/PO") and
            (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::Rejected)) or
           ((CustLedgerEntry."Document Type" = CustLedgerEntry."Document Type"::Invoice) and
            (CustLedgerEntry."Document Situation" = CustLedgerEntry."Document Situation"::Cartera) and
            (CustLedgerEntry."Document Status" = CustLedgerEntry."Document Status"::Open))
        then
            Error(CarteraApplyPositionErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnBeforePostApplyCustLedgEntry', '', false, false)]
    local procedure OnBeforePostApplyCustLedgEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; ApplyUnapplyParameters: Record "Apply Unapply Parameters")
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Bill then
            GenJournalLine.Description := StrSubstNo(ApplicationEntryDescriptionLbl, CustLedgerEntry."Document Type", CustLedgerEntry."Document No.")
        else
            GenJournalLine.Description := StrSubstNo(ApplicationBillDescriptionLbl, CustLedgerEntry."Document Type", CustLedgerEntry."Document No.", CustLedgerEntry."Bill No.");

        GenJnlPostLine.SetIDBillSettlement(IsToSetIDBillSettlement(CustLedgerEntry));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnAfterCheckInitialDocumentType', '', false, false)]
    local procedure OnAfterCheckInitialDocumentType(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        if DtldCustLedgEntry."Initial Document Type" = DtldCustLedgEntry."Initial Document Type"::" " then
            Error(UnapplyBlankedDocTypeErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CustEntry-Apply Posted Entries", 'OnPostUnApplyCustomerCommitOnAfterSetFilters', '', false, false)]
    local procedure OnPostUnApplyCustomerCommitOnAfterSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; DetailedCustLedgEntry2: Record "Detailed Cust. Ledg. Entry")
    begin
        if DetailedCustLedgEntry.FindSet() then
            repeat
                if DetailedCustLedgEntry."Initial Document Type" = DetailedCustLedgEntry."Initial Document Type"::" " then
                    Error(UnapplyBlankedDocTypeErr);
            until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure BeAppliedToBill(CustLedgEntry2: Record "Cust. Ledger Entry"): Boolean
    var
        CustLedgEntry3: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry3.SetCurrentKey("Applies-to ID", "Document Type");
        CustLedgEntry3.SetRange("Applies-to ID", CustLedgEntry2."Applies-to ID");
        CustLedgEntry3.SetRange("Document Type", CustLedgEntry2."Document Type"::Bill);
        exit(not CustLedgEntry3.IsEmpty());
    end;

    local procedure BeAppliedToInvoiceToCartera(CustLedgEntry2: Record "Cust. Ledger Entry"): Boolean
    var
        CustLedgEntry3: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry3.SetCurrentKey("Applies-to ID", "Document Type", "Document Situation", "Document Status");
        CustLedgEntry3.SetRange("Applies-to ID", CustLedgEntry2."Applies-to ID");
        CustLedgEntry3.SetRange("Document Type", CustLedgEntry2."Document Type"::Invoice);
        CustLedgEntry3.SetRange("Document Situation", CustLedgEntry3."Document Situation"::"Closed BG/PO");
        CustLedgEntry3.SetRange("Document Status", CustLedgEntry3."Document Status"::Rejected);
        exit(not CustLedgEntry3.IsEmpty());
    end;

    local procedure IsToSetIDBillSettlement(CustLedgEntry2: Record "Cust. Ledger Entry"): Boolean
    begin
        if CustLedgEntry2."Applies-to ID" = '' then
            exit(false);
        if BeAppliedToBill(CustLedgEntry2) then
            exit(true);
        exit(BeAppliedToInvoiceToCartera(CustLedgEntry2));
    end;
}
