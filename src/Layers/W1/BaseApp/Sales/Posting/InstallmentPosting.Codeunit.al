// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 8842 "Installment Posting"
{
    Permissions = tabledata "Installment Plan" = RIMD,
                  tabledata "Installment Plan Line" = RIMD;

    var
        UnsupportedProducerErr: Label 'Global installments currently support full standalone sales invoices only. Orders, shipment invoices, projects, subscription billing, service documents, and journals are not supported.';
        SourceErr: Label 'The installment posting source does not match the saved invoice and its owned draft plan.';
        ApplicationErr: Label 'Select individual installment entries using Applies-to ID. Applying an installment invoice by document number is not supported.';
        ReconciliationErr: Label 'The posted installment entries do not reconcile with the final invoice schedule.';
        TemporaryRecordErr: Label 'Installment posting calculation requires a temporary plan line record.';
        PostedPlanErr: Label 'Posted installment schedules cannot be changed or deleted.';
        CorrectionErr: Label 'Automatic correction, cancellation, and reversal of installment invoices are not supported.';

    procedure CheckSalesPosting(SalesHeader: Record "Sales Header")
    var
        Plan: Record "Installment Plan";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        GLSetup: Record "General Ledger Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if IsNullGuid(SalesHeader."Installment Plan ID") then
            exit;
        if SalesHeader.IsTemporary() or (SalesHeader."Document Type" <> SalesHeader."Document Type"::Invoice) then
            Error(UnsupportedProducerErr);
        Plan.Get(SalesHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        if (Plan."Source SystemId" <> SalesHeader.SystemId) or
           (Plan."Source Record ID" <> SalesHeader.RecordId()) or
           (Plan."Payment Terms Code" <> SalesHeader."Payment Terms Code") or
           (Plan."Document Date" <> SalesHeader."Document Date") or
           (Plan."Currency Code" <> SalesHeader."Currency Code")
        then
            Error(SourceErr);
        SalesHeader.TestField("Applies-to Doc. No.", '');
        SalesHeader.TestField("Applies-to ID", '');
        SalesHeader.TestField("Bal. Account No.", '');
        SalesHeader.TestField("Prepayment %", 0);
        SalesHeader.TestField(Correction, false);
        SalesHeader.TestField("Tax Area Code", '');
        SalesHeader.TestField("Tax Liable", false);
        SalesHeader.TestField("Direct Debit Mandate ID", '');
        SalesHeader.TestField("Payment Service Set ID", 0);
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer.TestField("Application Method", Customer."Application Method"::Manual);
        if PaymentMethod.Get(SalesHeader."Payment Method Code") then begin
            PaymentMethod.TestField("Bal. Account No.", '');
            PaymentMethod.TestField("Direct Debit", false);
        end;
        GLSetup.Get();
        GLSetup.TestField("Additional Reporting Currency", '');
        GLSetup.TestField("Pmt. Disc. Excl. VAT", false);
        GLSetup.TestField("Adjust for Payment Disc.", false);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                SalesLine.TestField("Shipment No.", '');
                SalesLine.TestField("Return Receipt No.", '');
                SalesLine.TestField("Job No.", '');
                SalesLine.TestField("Job Contract Entry No.", 0);
                SalesLine.TestField("Prepayment Line", false);
                SalesLine.TestField("Prepayment %", 0);
                SalesLine.TestField("Prepmt. Amt. Inv.", 0);
                SalesLine.TestField("VAT Base Discount %", 0);
                SalesLine.TestField("Quantity Invoiced", 0);
                if SalesLine.Type <> SalesLine.Type::" " then begin
                    SalesLine.TestField("Qty. to Invoice", SalesLine.Quantity);
                    if not (SalesLine."VAT Calculation Type" in
                            [SalesLine."VAT Calculation Type"::"Normal VAT", SalesLine."VAT Calculation Type"::"No Taxable VAT"])
                    then
                        Error(UnsupportedProducerErr);
                    if VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group") then
                        VATPostingSetup.TestField("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
                end;
            until SalesLine.Next() = 0;
        OnCheckSalesPosting(SalesHeader);
    end;

    procedure PrepareJournalLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        CheckSalesPosting(SalesHeader);
        GenJournalLine."Installment Plan ID" := SalesHeader."Installment Plan ID";
        Clear(GenJournalLine."Sales Invoice Source SystemId");
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            GenJournalLine."Sales Invoice Source SystemId" := SalesHeader.SystemId;
    end;

    procedure CheckJournalLine(GenJournalLine: Record "Gen. Journal Line")
    var
        Rule: Record "Payment Term Installment";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EmptyGuid: Guid;
        ApplyingCustomerNo: Code[20];
    begin
        if GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer then
            ApplyingCustomerNo := GenJournalLine."Account No."
        else
            if GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::Customer then
                ApplyingCustomerNo := GenJournalLine."Bal. Account No.";
        if (ApplyingCustomerNo <> '') and (GenJournalLine."Applies-to Doc. No." <> '') then begin
            CustLedgerEntry.SetRange("Customer No.", ApplyingCustomerNo);
            CustLedgerEntry.SetRange("Document Type", GenJournalLine."Applies-to Doc. Type");
            CustLedgerEntry.SetRange("Document No.", GenJournalLine."Applies-to Doc. No.");
            CustLedgerEntry.SetFilter("Installment Plan ID", '<>%1', EmptyGuid);
            if not CustLedgerEntry.IsEmpty() then
                Error(ApplicationErr);
        end;
        if not IsNullGuid(GenJournalLine."Installment Plan ID") then begin
            GenJournalLine.TestField("Account Type", GenJournalLine."Account Type"::Customer);
            GenJournalLine.TestField("Document Type", GenJournalLine."Document Type"::Invoice);
            GenJournalLine.TestField("System-Created Entry", true);
            GenJournalLine.TestField("Journal Template Name", '');
            GenJournalLine.TestField("Sales Invoice Source SystemId");
            exit;
        end;
        if not ((GenJournalLine."Account Type" in [GenJournalLine."Account Type"::Customer, GenJournalLine."Account Type"::Vendor]) or
                (GenJournalLine."Bal. Account Type" in [GenJournalLine."Bal. Account Type"::Customer, GenJournalLine."Bal. Account Type"::Vendor])) or
           not (GenJournalLine."Document Type" in [GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo"])
        then
            exit;
        if GenJournalLine."Payment Terms Code" = '' then
            exit;
        Rule.SetRange("Payment Terms Code", GenJournalLine."Payment Terms Code");
        if Rule.IsEmpty() then
            exit;
        // Existing ordinary invoices do not acquire a plan when reusable setup is changed.
        if not IsNullGuid(GenJournalLine."Sales Invoice Source SystemId") then
            if SalesHeader.GetBySystemId(GenJournalLine."Sales Invoice Source SystemId") then
                if (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer) and
                   (GenJournalLine."Document Type" = GenJournalLine."Document Type"::Invoice) and
                   (SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice) and
                   IsNullGuid(SalesHeader."Installment Plan ID") and
                   (SalesHeader."Payment Terms Code" = GenJournalLine."Payment Terms Code") and
                   (SalesHeader."Bill-to Customer No." = GenJournalLine."Account No.") and
                   GenJournalLine."System-Created Entry" and (GenJournalLine."Journal Template Name" = '')
                then
                    if SalesInvoiceHeader.Get(GenJournalLine."Document No.") then
                        if IsNullGuid(SalesInvoiceHeader."Installment Plan ID") and
                           (SalesInvoiceHeader."Draft Invoice SystemId" = SalesHeader.SystemId)
                        then
                            exit;
        Error(UnsupportedProducerErr);
    end;

    procedure PreparePosting(GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var TempPlanLine: Record "Installment Plan Line" temporary): Boolean
    var
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if IsNullGuid(GenJournalLine."Installment Plan ID") then
            exit(false);
        CheckTemporary(TempPlanLine);
        CheckJournalLine(GenJournalLine);
        if Balancing then
            Error(UnsupportedProducerErr);
        Plan.LockTable();
        Plan.Get(GenJournalLine."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        if not SalesHeader.GetBySystemId(GenJournalLine."Sales Invoice Source SystemId") then
            Error(SourceErr);
        if SalesHeader."Installment Plan ID" <> Plan.ID then
            Error(SourceErr);
        CheckSalesPosting(SalesHeader);
        SalesInvoiceHeader.Get(GenJournalLine."Document No.");
        SalesInvoiceHeader.TestField("Installment Plan ID", Plan.ID);
        SalesInvoiceHeader.TestField("Draft Invoice SystemId", SalesHeader.SystemId);
        GenJournalLine.TestField("Account No.", SalesHeader."Bill-to Customer No.");
        GenJournalLine.TestField("Currency Code", SalesHeader."Currency Code");
        GenJournalLine.TestField("Document Date", SalesHeader."Document Date");
        GenJournalLine.TestField("Posting Date", SalesHeader."Posting Date");
        GenJournalLine.TestField("Payment Terms Code", SalesHeader."Payment Terms Code");
        GenJournalLine.TestField("Due Date", SalesHeader."Due Date");
        GenJournalLine.TestField("Additional-Currency Posting", GenJournalLine."Additional-Currency Posting"::None);
        GenJournalLine.TestField("Applies-to Doc. No.", '');
        GenJournalLine.TestField("Applies-to ID", '');
        GenJournalLine.TestField("Bal. Account No.", '');
        GenJournalLine.TestField(Prepayment, false);
        GenJournalLine.TestField(Correction, false);
        GenJournalLine.TestField("Deferral Code", '');
        GenJournalLine.TestField("VAT Amount", 0);
        GenJournalLine.TestField("VAT Amount (LCY)", 0);
        GenJournalLine.TestField("VAT Base Amount", 0);
        GenJournalLine.TestField("VAT Base Amount (LCY)", 0);
        GenJournalLine.TestField("Source Curr. VAT Amount", 0);
        GenJournalLine.TestField("Source Curr. VAT Base Amount", 0);
        GenJournalLine.TestField("Payment Discount %", 0);
        GenJournalLine.TestField("Pmt. Discount Date", 0D);
        GenJournalLine.TestField("Orig. Pmt. Disc. Possible", 0);
        GenJournalLine.TestField("Orig. Pmt. Disc. Possible(LCY)", 0);
        GenJournalLine.TestField("Source Currency Code", GenJournalLine."Currency Code");
        TempPlanLine.Reset();
        TempPlanLine.DeleteAll();
        PlanLine.SetRange("Plan ID", Plan.ID);
        if not PlanLine.FindSet() then
            Error(SourceErr);
        repeat
            TempPlanLine.Init();
            TempPlanLine."Plan ID" := Plan.ID;
            TempPlanLine.CopyRulesFromPlanLine(PlanLine);
            TempPlanLine.Insert();
        until PlanLine.Next() = 0;
        CalculatePostingLines(GenJournalLine, TempPlanLine);
        TempPlanLine.FindSet();
        exit(true);
    end;

    procedure CalculatePostingLines(GenJournalLine: Record "Gen. Journal Line"; var TempPlanLine: Record "Installment Plan Line" temporary)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        InstallmentCalculation: Codeunit "Installment Calculation";
        RemainingSourceAmount: Decimal;
        RemainingSalesLCY: Decimal;
        RemainingProfitLCY: Decimal;
        RemainingInvDiscountLCY: Decimal;
        LastLineNo: Integer;
        LastLine: Boolean;
    begin
        CheckTemporary(TempPlanLine);
        if TempPlanLine.IsEmpty() then
            Error(SourceErr);
        GLSetup.Get();
        Currency.Initialize(GenJournalLine."Currency Code", true);
        InstallmentCalculation.Calculate(
            TempPlanLine, GenJournalLine."Document Date", GenJournalLine."Posting Date", GenJournalLine.Amount, GenJournalLine."Amount (LCY)",
            Currency."Amount Rounding Precision", GLSetup."Amount Rounding Precision", GLSetup."Payment Discount Grace Period");
        TempPlanLine.FindLast();
        LastLineNo := TempPlanLine."Line No.";
        RemainingSourceAmount := GenJournalLine."Source Currency Amount";
        RemainingSalesLCY := GenJournalLine."Sales/Purch. (LCY)";
        RemainingProfitLCY := GenJournalLine."Profit (LCY)";
        RemainingInvDiscountLCY := GenJournalLine."Inv. Discount (LCY)";
        TempPlanLine.FindSet();
        repeat
            LastLine := TempPlanLine."Line No." = LastLineNo;
            TempPlanLine."Source Currency Amount" := Allocate(
                GenJournalLine."Source Currency Amount", RemainingSourceAmount, TempPlanLine."Payment %", LastLine, Currency."Amount Rounding Precision");
            TempPlanLine."Sales (LCY)" := Allocate(
                GenJournalLine."Sales/Purch. (LCY)", RemainingSalesLCY, TempPlanLine."Payment %", LastLine, GLSetup."Amount Rounding Precision");
            TempPlanLine."Profit (LCY)" := Allocate(
                GenJournalLine."Profit (LCY)", RemainingProfitLCY, TempPlanLine."Payment %", LastLine, GLSetup."Amount Rounding Precision");
            TempPlanLine."Inv. Discount (LCY)" := Allocate(
                GenJournalLine."Inv. Discount (LCY)", RemainingInvDiscountLCY, TempPlanLine."Payment %", LastLine, GLSetup."Amount Rounding Precision");
            TempPlanLine.Modify();
        until TempPlanLine.Next() = 0;
    end;

    procedure SetJournalLine(TotalGenJournalLine: Record "Gen. Journal Line"; PlanLine: Record "Installment Plan Line"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine := TotalGenJournalLine;
        GenJournalLine.Amount := PlanLine.Amount;
        GenJournalLine."Amount (LCY)" := PlanLine."Amount (LCY)";
        GenJournalLine."Source Currency Amount" := PlanLine."Source Currency Amount";
        GenJournalLine."Sales/Purch. (LCY)" := PlanLine."Sales (LCY)";
        GenJournalLine."Profit (LCY)" := PlanLine."Profit (LCY)";
        GenJournalLine."Inv. Discount (LCY)" := PlanLine."Inv. Discount (LCY)";
        GenJournalLine."Due Date" := PlanLine."Due Date";
        GenJournalLine."Payment Discount %" := PlanLine."Discount %";
        GenJournalLine."Pmt. Discount Date" := PlanLine."Pmt. Discount Date";
        GenJournalLine."Debit Amount" := PlanLine.Amount;
        GenJournalLine."Credit Amount" := 0;
    end;

    procedure RecordPostedLine(PlanLine: Record "Installment Plan Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; InstallmentCount: Integer)
    var
        SavedPlanLine: Record "Installment Plan Line";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.TestField("Installment Plan ID", PlanLine."Plan ID");
        CustLedgerEntry.TestField("Installment No.", PlanLine."Installment No.");
        CustLedgerEntry.TestField("No. of Installments", InstallmentCount);
        CustLedgerEntry.TestField("Due Date", PlanLine."Due Date");
        CustLedgerEntry.TestField("Pmt. Discount Date", PlanLine."Pmt. Discount Date");
        CustLedgerEntry.TestField("Original Pmt. Disc. Possible", PlanLine."Original Pmt. Disc. Possible");
        CustLedgerEntry.TestField("Sales (LCY)", PlanLine."Sales (LCY)");
        CustLedgerEntry.TestField("Profit (LCY)", PlanLine."Profit (LCY)");
        CustLedgerEntry.TestField("Inv. Discount (LCY)", PlanLine."Inv. Discount (LCY)");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        if DetailedCustLedgEntry.Count() <> 1 then
            Error(ReconciliationErr);
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
        DetailedCustLedgEntry.TestField(Amount, PlanLine.Amount);
        DetailedCustLedgEntry.TestField("Amount (LCY)", PlanLine."Amount (LCY)");
        DetailedCustLedgEntry.TestField("Initial Entry Due Date", PlanLine."Due Date");
        SavedPlanLine.Get(PlanLine."Plan ID", PlanLine."Line No.");
        SavedPlanLine.TestField("Cust. Ledger Entry No.", 0);
        SavedPlanLine := PlanLine;
        SavedPlanLine."Cust. Ledger Entry No." := CustLedgerEntry."Entry No.";
        SavedPlanLine.Modify(true);
    end;

    procedure CompletePosting(GenJournalLine: Record "Gen. Journal Line"; InstallmentCount: Integer)
    var
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInstallmentHistory: Codeunit "Sales Installment History";
    begin
        Plan.Get(GenJournalLine."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Draft);
        PlanLine.SetRange("Plan ID", Plan.ID);
        if PlanLine.Count() <> InstallmentCount then
            Error(ReconciliationErr);
        PlanLine.SetRange("Cust. Ledger Entry No.", 0);
        if not PlanLine.IsEmpty() then
            Error(ReconciliationErr);
        PlanLine.SetRange("Cust. Ledger Entry No.");
        PlanLine.CalcSums(Amount, "Amount (LCY)", "Source Currency Amount", "Sales (LCY)", "Profit (LCY)", "Inv. Discount (LCY)");
        if (PlanLine.Amount <> GenJournalLine.Amount) or (PlanLine."Amount (LCY)" <> GenJournalLine."Amount (LCY)") or
           (PlanLine."Source Currency Amount" <> GenJournalLine."Source Currency Amount") or
           (PlanLine."Sales (LCY)" <> GenJournalLine."Sales/Purch. (LCY)") or
           (PlanLine."Profit (LCY)" <> GenJournalLine."Profit (LCY)") or
           (PlanLine."Inv. Discount (LCY)" <> GenJournalLine."Inv. Discount (LCY)")
        then
            Error(ReconciliationErr);
        SalesInvoiceHeader.Get(GenJournalLine."Document No.");
        SalesInvoiceHeader.TestField("Installment Plan ID", Plan.ID);
        PlanLine.SetCurrentKey("Plan ID", "Installment No.");
        PlanLine.FindLast();
        SalesInstallmentHistory.SetInvoiceGroup(Plan.ID, PlanLine."Cust. Ledger Entry No.");
        Plan.Status := Plan.Status::Posted;
        Plan."Posted Invoice No." := SalesInvoiceHeader."No.";
        Plan."Posted Invoice SystemId" := SalesInvoiceHeader.SystemId;
        Plan."Posting Date" := GenJournalLine."Posting Date";
        Plan.Amount := GenJournalLine.Amount;
        Plan."Amount (LCY)" := GenJournalLine."Amount (LCY)";
        // Source identity remains immutable provenance; posted ownership uses the posted invoice SystemId.
        Plan.Modify(true);
    end;

    procedure GetFinalCustomerEntry(SalesInvoiceHeader: Record "Sales Invoice Header"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
    begin
        Plan.Get(SalesInvoiceHeader."Installment Plan ID");
        Plan.TestField(Status, Plan.Status::Posted);
        Plan.TestField("Posted Invoice SystemId", SalesInvoiceHeader.SystemId);
        PlanLine.SetCurrentKey("Plan ID", "Installment No.");
        PlanLine.SetRange("Plan ID", Plan.ID);
        PlanLine.FindLast();
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
        CustLedgerEntry.TestField("Installment Plan ID", Plan.ID);
        CustLedgerEntry.TestField("Installment No.", PlanLine."Installment No.");
        CustLedgerEntry.TestField("Document No.", SalesInvoiceHeader."No.");
        CustLedgerEntry.TestField("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
    end;

    local procedure Allocate(Total: Decimal; var Remaining: Decimal; Percentage: Decimal; LastLine: Boolean; Precision: Decimal) Amount: Decimal
    begin
        if LastLine then
            Amount := Remaining
        else
            Amount := Round(Total * Percentage / 100, Precision);
        Remaining -= Amount;
    end;

    local procedure CheckTemporary(TempPlanLine: Record "Installment Plan Line" temporary)
    begin
        if not TempPlanLine.IsTemporary() then
            Error(TemporaryRecordErr);
    end;

    local procedure CheckPlanEditable(PlanID: Guid)
    var
        Plan: Record "Installment Plan";
    begin
        if Plan.Get(PlanID) then
            if Plan.Status = Plan.Status::Posted then
                Error(PostedPlanErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Installment Plan", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckPlanModification(var Rec: Record "Installment Plan")
    begin
        if not Rec.IsTemporary() then
            CheckPlanEditable(Rec.ID);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Installment Plan", 'OnBeforeRenameEvent', '', false, false)]
    local procedure CheckPlanRenaming(var Rec: Record "Installment Plan")
    var
        SavedPlan: Record "Installment Plan";
    begin
        if Rec.IsTemporary() then
            exit;
        if SavedPlan.GetBySystemId(Rec.SystemId) then
            CheckPlanEditable(SavedPlan.ID);
        CheckPlanEditable(Rec.ID);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Installment Plan", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure CheckPlanDeletion(var Rec: Record "Installment Plan")
    begin
        if not Rec.IsTemporary() then
            CheckPlanEditable(Rec.ID);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Installment Plan Line", 'OnBeforeInsertEvent', '', false, false)]
    local procedure CheckLineInsertion(var Rec: Record "Installment Plan Line")
    begin
        if not Rec.IsTemporary() then
            CheckPlanEditable(Rec."Plan ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Installment Plan Line", 'OnBeforeModifyEvent', '', false, false)]
    local procedure CheckLineModification(var Rec: Record "Installment Plan Line")
    var
        SavedPlanLine: Record "Installment Plan Line";
    begin
        if Rec.IsTemporary() then
            exit;
        if SavedPlanLine.GetBySystemId(Rec.SystemId) then
            CheckPlanEditable(SavedPlanLine."Plan ID");
        CheckPlanEditable(Rec."Plan ID");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Installment Plan Line", 'OnBeforeRenameEvent', '', false, false)]
    local procedure CheckLineRenaming(var Rec: Record "Installment Plan Line")
    begin
        CheckLineModification(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Installment Plan Line", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure CheckLineDeletion(var Rec: Record "Installment Plan Line")
    begin
        if not Rec.IsTemporary() then
            CheckPlanEditable(Rec."Plan ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnBeforeCreateCorrectiveSalesCrMemo', '', false, false)]
    local procedure CheckCorrectiveInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if not IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then
            Error(CorrectionErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnBeforeUnapplyCostApplication', '', false, false)]
    local procedure CheckCorrectionBeforeCostUnapplication(InvNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if SalesInvoiceHeader.Get(InvNo) then
            if not IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then
                Error(CorrectionErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnAfterTestCorrectInvoiceIsAllowed', '', false, false)]
    local procedure CheckInvoiceCorrection(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if not IsNullGuid(SalesInvoiceHeader."Installment Plan ID") then
            Error(CorrectionErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reversal Entry", 'OnBeforeCheckCust', '', false, false)]
    local procedure CheckCustomerReversal(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        if not IsNullGuid(CustLedgEntry."Installment Plan ID") then
            Error(CorrectionErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesPosting(SalesHeader: Record "Sales Header")
    begin
    end;
}
