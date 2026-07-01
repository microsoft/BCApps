// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;

codeunit 7000088 "CRT Cust. Ledger Entry"
{

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnAfterValidateEvent, 'Due Date', false, false)]
    local procedure DueDateOnAfterValidate(var Rec: Record "Cust. Ledger Entry"; var xRec: Record "Cust. Ledger Entry"; CurrFieldNo: Integer)
    var
        DocumentMisc: Codeunit "Document-Misc";
    begin
        if Rec."Document Situation" <> Rec."Document Situation"::" " then
            DocumentMisc.UpdateReceivableDueDate(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnAfterValidateEvent, 'Payment Method Code', false, false)]
    local procedure PaymentMethodCodeOnAfterValidate(var Rec: Record "Cust. Ledger Entry"; var xRec: Record "Cust. Ledger Entry"; CurrFieldNo: Integer)
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        if Rec."Payment Method Code" <> xRec."Payment Method Code" then begin
            Rec.ValidatePaymentMethod();
            CarteraDoc.UpdatePaymentMethodCode(
                Rec."Document No.", Rec."Customer No.", Rec."Bill No.", Rec."Payment Method Code")
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnAfterCopyCustLedgerEntryFromGenJnlLine, '', false, false)]
    local procedure OnAfterCopyCustLedgerEntryFromGenJnlLine(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        CustLedgerEntry."Bill No." := GenJournalLine."Bill No.";
        CustLedgerEntry."Applies-to Bill No." := GenJournalLine."Applies-to Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnSetApplyToFiltersOnBeforeSetFilters, '', false, false)]
    local procedure OnSetApplyToFiltersOnBeforeSetFilters(var Rec: Record "Cust. Ledger Entry")
    begin
        Rec.SetFilter("Document Situation", '<>%1', Rec."Document Situation"::"Posted BG/PO");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnAfterSetAppliesToDocFilters, '', false, false)]
    local procedure OnAfterSetAppliesToDocFilters(var Rec: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        Rec.SetRange("Bill No.", GenJnlLine."Applies-to Bill No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", OnAfterClearDocumentFilters, '', false, false)]
    local procedure OnAfterClearDocumentFilters(var Rec: Record "Cust. Ledger Entry")
    begin
        Rec.SetRange("Bill No.");
    end;
}