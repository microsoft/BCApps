// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.PaymentTerms;

codeunit 7000086 "CRT Vendor Ledger Entry"
{
    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterValidateEvent, 'Due Date', false, false)]
    local procedure DueDateOnAfterValidate(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; CurrFieldNo: Integer)
    var
        PaymentTerms: Record "Payment Terms";
        DocMisc: Codeunit "Document-Misc";
    begin
        Rec.CheckBillSituation();
        if PaymentTerms.Get(Rec."Payment Terms Code") then
            PaymentTerms.VerifyMaxNoDaysTillDueDate(Rec."Due Date", Rec."Document Date", Rec.FieldCaption("Due Date"));
        if Rec."Document Situation" <> Rec."Document Situation"::" " then
            DocMisc.UpdatePayableDueDate(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterValidateEvent, 'Amount to Apply', false, false)]
    local procedure AmountToApplyOnAfterValidate(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; CurrFieldNo: Integer)
    begin
        Rec.CheckBillSituation();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterValidateEvent, 'Payment Method Code', false, false)]
    local procedure PaymentMethodCodeOnAfterValidate(var Rec: Record "Vendor Ledger Entry"; var xRec: Record "Vendor Ledger Entry"; CurrFieldNo: Integer)
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        if Rec."Payment Method Code" <> xRec."Payment Method Code" then begin
            Rec.ValidatePaymentMethod();
            CarteraDoc.UpdatePaymentMethodCode(
                Rec."Document No.", Rec."Vendor No.", Rec."Bill No.", Rec."Payment Method Code")
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterCopyVendLedgerEntryFromGenJnlLine, '', false, false)]
    local procedure OnAfterCopyVendLedgerEntryFromGenJnlLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        VendorLedgerEntry."Bill No." := GenJournalLine."Bill No.";
        VendorLedgerEntry."Applies-to Bill No." := GenJournalLine."Applies-to Bill No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterCopyVendLedgerEntryFromCVLedgEntryBuffer, '', false, false)]
    local procedure OnAfterCopyVendLedgerEntryFromCVLedgEntryBuffer(var VendorLedgerEntry: Record "Vendor Ledger Entry"; CVLedgerEntryBuffer: Record "CV Ledger Entry Buffer")
    begin
        VendorLedgerEntry."Bill No." := CVLedgerEntryBuffer."Bill No.";
        VendorLedgerEntry."Document Situation" := CVLedgerEntryBuffer."Document Situation";
        VendorLedgerEntry."Applies-to Bill No." := CVLedgerEntryBuffer."Applies-to Bill No.";
        VendorLedgerEntry."Document Status" := CVLedgerEntryBuffer."Document Status";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterSetAppliesToDocFilters, '', false, false)]
    local procedure OnAfterSetAppliesToDocFilters(var Rec: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line")
    begin
        Rec.SetRange("Bill No.", GenJnlLine."Applies-to Bill No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Ledger Entry", OnAfterClearDocumentFilters, '', false, false)]
    local procedure OnAfterClearDocumentFilters(var Rec: Record "Vendor Ledger Entry")
    begin
        Rec.SetRange("Bill No.");
    end;
}