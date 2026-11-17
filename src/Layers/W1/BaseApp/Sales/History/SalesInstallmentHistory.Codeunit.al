// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Receivables;

codeunit 8843 "Sales Installment History"
{
    Permissions = tabledata "Cust. Ledger Entry" = rm,
                  tabledata "Detailed Cust. Ledg. Entry" = rm;

    var
        EditErr: Label 'Changing posted installment payment conditions is not supported.';
        PaymentServiceErr: Label 'Payment services are not supported for global installment invoices.';
        AutomaticApplicationErr: Label 'Use Applies-to ID to select installment entries. Automatic Apply to Oldest is not supported for global installments.';
        LatePostingErr: Label 'Late journal posting is not supported for global installment invoices.';
        IncompleteBackfillMsg: Label 'Installment invoice grouping could not be completed because a posted invoice or customer ledger anchor is missing or inconsistent. The upgrade tag was not set.', Locked = true;

    internal procedure SetInvoiceGroup(PlanID: Guid; InvoiceEntryNo: Integer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AnchorEntry: Record "Cust. Ledger Entry";
    begin
        AnchorEntry.Get(InvoiceEntryNo);
        AnchorEntry.TestField("Installment Plan ID");
        AnchorEntry.TestField("Installment Plan ID", PlanID);
        CustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        DetailedCustLedgEntry.SetFilter("Invoice Entry No.", '<>%1', InvoiceEntryNo);
        if CustLedgerEntry.FindSet(true) then
            repeat
                DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
                DetailedCustLedgEntry.ModifyAll("Invoice Entry No.", InvoiceEntryNo);
                if CustLedgerEntry."Invoice Entry No." <> InvoiceEntryNo then begin
                    CustLedgerEntry."Invoice Entry No." := InvoiceEntryNo;
                    CustLedgerEntry.Modify();
                end;
            until CustLedgerEntry.Next() = 0;
    end;

    internal procedure BackfillInvoiceGroups() Complete: Boolean
    var
        Plan: Record "Installment Plan";
    begin
        Complete := true;
        Plan.SetRange(Status, Plan.Status::Posted);
        if Plan.FindSet() then
            repeat
                if not BackfillInvoiceGroup(Plan) then
                    Complete := false;
            until Plan.Next() = 0;
        if not Complete then
            Session.LogMessage('InstallmentGroupBackfillIncomplete', IncompleteBackfillMsg, Verbosity::Warning,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'AL SaaS Upgrade');
    end;

    local procedure BackfillInvoiceGroup(Plan: Record "Installment Plan"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        AnchorEntry: Record "Cust. Ledger Entry";
    begin
        if IsNullGuid(Plan.ID) then
            exit(false);
        if not SalesInvoiceHeader.Get(Plan."Posted Invoice No.") then
            exit(false);
        if (SalesInvoiceHeader.SystemId <> Plan."Posted Invoice SystemId") or
           (SalesInvoiceHeader."Installment Plan ID" <> Plan.ID)
        then
            exit(false);
        if not AnchorEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.") then
            exit(false);
        if AnchorEntry."Installment Plan ID" <> Plan.ID then
            exit(false);
        SetInvoiceGroup(Plan.ID, AnchorEntry."Entry No.");
        exit(true);
    end;

    procedure ShowSchedule(SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
    begin
        Plan.Get(SalesInvoiceHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Posted);
        Plan.TestField("Posted Invoice SystemId", SalesInvoiceHeader.SystemId);
        PlanLine.FilterGroup(2);
        PlanLine.SetRange("Plan ID", Plan.ID);
        PlanLine.FilterGroup(0);
        Page.Run(Page::"Posted Installment Schedule", PlanLine);
    end;

    procedure CheckPaymentService(PlanID: Guid)
    begin
        if not IsNullGuid(PlanID) then
            Error(PaymentServiceErr);
    end;

    procedure CheckLatePosting(SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if not IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then
            Error(LatePostingErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure InitializeCustomerGroup(var Rec: Record "Cust. Ledger Entry")
    begin
        if not Rec.IsTemporary() then
            Rec."Invoice Entry No." := Rec."Entry No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Detailed Cust. Ledg. Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure InitializeDetailedGroup(var Rec: Record "Detailed Cust. Ledg. Entry")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if Rec.IsTemporary() then
            exit;
        Rec."Invoice Entry No." := Rec."Cust. Ledger Entry No.";
        // Initial entries are grouped when installment posting completes.
        if (Rec."Entry Type" = Rec."Entry Type"::"Initial Entry") or
           (Rec."Initial Document Type" <> Rec."Initial Document Type"::Invoice)
        then
            exit;
        CustLedgerEntry.SetLoadFields("Invoice Entry No.");
        if CustLedgerEntry.Get(Rec."Cust. Ledger Entry No.") then
            if CustLedgerEntry."Invoice Entry No." <> 0 then
                Rec."Invoice Entry No." := CustLedgerEntry."Invoice Entry No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckCustomerConditions(var Rec: Record "Cust. Ledger Entry")
    var
        SavedEntry: Record "Cust. Ledger Entry";
    begin
        if Rec.IsTemporary() then
            exit;
        SavedEntry.Get(Rec."Entry No.");
        if IsNullGuid(SavedEntry."Installment Plan ID") then
            exit;
        if (Rec."Installment Plan ID" <> SavedEntry."Installment Plan ID") or
           (Rec."Installment No." <> SavedEntry."Installment No.") or
           (Rec."No. of Installments" <> SavedEntry."No. of Installments") or
           (Rec."Due Date" <> SavedEntry."Due Date") or
           (Rec."Pmt. Discount Date" <> SavedEntry."Pmt. Discount Date") or
           (Rec."Pmt. Disc. Tolerance Date" <> SavedEntry."Pmt. Disc. Tolerance Date") or
           (Rec."Direct Debit Mandate ID" <> SavedEntry."Direct Debit Mandate ID") or
           (Rec."Payment Method Code" <> SavedEntry."Payment Method Code") or
           (Rec."Payment Reference" <> SavedEntry."Payment Reference")
        then
            Error(EditErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Invoice Header", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckInvoiceConditions(var Rec: Record "Sales Invoice Header")
    var
        SavedInvoice: Record "Sales Invoice Header";
    begin
        if Rec.IsTemporary() then
            exit;
        SavedInvoice.Get(Rec."No.");
        if IsNullGuid(SavedInvoice."Installment Plan ID") then
            exit;
        if (Rec."Installment Plan ID" <> SavedInvoice."Installment Plan ID") or
           (Rec."Due Date" <> SavedInvoice."Due Date") or
           (Rec."Payment Terms Code" <> SavedInvoice."Payment Terms Code") or
           (Rec."Payment Discount %" <> SavedInvoice."Payment Discount %") or
           (Rec."Pmt. Discount Date" <> SavedInvoice."Pmt. Discount Date") or
           (Rec."Payment Method Code" <> SavedInvoice."Payment Method Code") or
           (Rec."Payment Reference" <> SavedInvoice."Payment Reference") or
           (Rec."Dispute Status" <> SavedInvoice."Dispute Status") or
           (Rec."Promised Pay Date" <> SavedInvoice."Promised Pay Date") or
           (Rec."Payment Service Set ID" <> SavedInvoice."Payment Service Set ID")
        then
            Error(EditErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cust. Entry-Edit", 'OnBeforeOnRun', '', false, false)]
    local procedure CheckCustomerEdit(var CustLedgerEntryRec: Record "Cust. Ledger Entry")
    begin
        CheckCustomerConditions(CustLedgerEntryRec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnBeforeValidateEvent', 'Due Date', false, false)]
    local procedure CheckCustomerDueDate(var Rec: Record "Cust. Ledger Entry")
    var
        SavedEntry: Record "Cust. Ledger Entry";
    begin
        if Rec.IsTemporary() then
            exit;
        if SavedEntry.Get(Rec."Entry No.") then
            if not IsNullGuid(SavedEntry."Installment Plan ID") then
                CheckCustomerConditions(Rec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Cust. Entry-Edit", 'OnBeforeUpdateSalesInvoiceHeader', '', false, false)]
    local procedure SkipInvoiceSummaryUpdate(var UpdateSalesInvoiceCustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
        if not IsNullGuid(UpdateSalesInvoiceCustLedgerEntry."Installment Plan ID") then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Inv. Header - Edit", 'OnRunOnBeforeAssignValues', '', false, false)]
    local procedure CheckPostedInvoiceEdit(SalesInvoiceHeaderRec: Record "Sales Invoice Header")
    begin
        CheckInvoiceConditions(SalesInvoiceHeaderRec);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnPrepareTempCustLedgEntryOnBeforeTempOldCustLedgEntryInsert', '', false, false)]
    local procedure CheckAutomaticApplication(var CustLedgerEntry: Record "Cust. Ledger Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        if not IsNullGuid(CustLedgerEntry."Installment Plan ID") and
           (GenJournalLine."Applies-to ID" = '') and (GenJournalLine."Applies-to Doc. No." = '')
        then
            Error(AutomaticApplicationErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Payment Service Setup", 'OnCanChangePaymentServiceOnAfterGetRecordRef', '', false, false)]
    local procedure DisableInvoicePaymentService(DocumentRecordRef: RecordRef; var Result: Boolean; var IsHandled: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if DocumentRecordRef.Number <> Database::"Sales Invoice Header" then
            exit;
        DocumentRecordRef.SetTable(SalesInvoiceHeader);
        if not IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then begin
            Result := false;
            IsHandled := true;
        end;
    end;
}
