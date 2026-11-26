// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Bank.Reconciliation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reminder;
using System.Utilities;

codeunit 134497 "ERM Installment Collections"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Installments] [Collections]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInstallments: Codeunit "Library - ERM Installments";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        ManualSelectionErr: Label 'has more than one open installment', Locked = true;
        StatementEntryXPathTok: Label 'DataItem[Column[@name="DocNo_DtldCustLedgEntries"]="%1"]', Locked = true, Comment = '%1 = Invoice number';

    [Test]
    procedure OverdueReminderCollectsOnlyTheRemainingDueInstallment()
    var
        Invoice: Record "Sales Invoice Header";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        Entry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO] Reminders demand only the unpaid portion of installments already due.
        // [GIVEN] A three-installment invoice with a partial payment against its first obligation.
        CreatePostedInvoice(Invoice, '', false);
        ConfigureReminders(Invoice."Bill-to Customer No.");
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 10);

        // [WHEN] Overdue-only reminder lines are suggested before the second installment falls due.
        SuggestReminder(ReminderHeader, Invoice, CalcDate('<45D>', Invoice."Document Date"), true);

        // [THEN] Only the first installment's remaining 31.67 is demanded; future balances are unchanged.
        FilterReminderLines(ReminderLine, ReminderHeader."No.");
        Assert.AreEqual(1, ReminderLine.Count(), 'Future installments must not be demanded.');
        ReminderLine.FindFirst();
        GetInstallment(Entry, Invoice."Installment Plan ID", 1);
        ReminderLine.TestField("Entry No.", Entry."Entry No.");
        ReminderLine.TestField("Remaining Amount", 31.67);
        ReminderLine.TestField("No. of Reminders", 1);
        VerifyRemaining(Invoice."Installment Plan ID", 2, 41.67);
        VerifyRemaining(Invoice."Installment Plan ID", 3, 41.66);
    end;

    [Test]
    procedure InstallmentReminderProgressionFlow()
    var
        Invoice: Record "Sales Invoice Header";
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        Entry: Record "Cust. Ledger Entry";
        ReminderIssue: Codeunit "Reminder-Issue";
    begin
        // [SCENARIO] An installment reminder flow preserves informational future balances, advances only overdue levels, and excludes settled installments.
        // [GIVEN] An unpaid invoice with only its first installment overdue.
        CreatePostedInvoice(Invoice, '', false);
        ConfigureReminders(Invoice."Bill-to Customer No.");

        // [WHEN] Flow step 1: Reminder suggestion includes installments not yet due.
        SuggestReminder(ReminderHeader, Invoice, CalcDate('<45D>', Invoice."Document Date"), false);

        // [THEN] Future installments appear only as informational balances with no fee or reminder level.
        FilterReminderLines(ReminderLine, ReminderHeader."No.");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Not Due");
        Assert.AreEqual(2, ReminderLine.Count(), 'Future installments may appear only as native informational lines.');
        ReminderLine.CalcSums("Remaining Amount");
        Assert.AreEqual(83.33, ReminderLine."Remaining Amount", 'Informational balances must not repeat the invoice total.');
        ReminderLine.FindSet();
        repeat
            ReminderLine.TestField("No. of Reminders", 0);
            ReminderLine.TestField(Amount, 0);
        until ReminderLine.Next() = 0;

        // [WHEN] Flow step 2: The suggested reminder is issued.
        ReminderIssue.Set(ReminderHeader, false, ReminderHeader."Document Date");
        LibraryERM.RunReminderIssue(ReminderIssue);

        // [THEN] Only the overdue installment advances to the first issued reminder level.
        GetInstallment(Entry, Invoice."Installment Plan ID", 1);
        Entry.TestField("Last Issued Reminder Level", 1);
        GetInstallment(Entry, Invoice."Installment Plan ID", 2);
        Entry.TestField("Last Issued Reminder Level", 0);
        GetInstallment(Entry, Invoice."Installment Plan ID", 3);
        Entry.TestField("Last Issued Reminder Level", 0);

        // [WHEN] Flow step 3: After issuing the first reminder, another is suggested when the second installment becomes overdue.
        SuggestReminder(ReminderHeader, Invoice, CalcDate('<75D>', Invoice."Document Date"), true);

        // [THEN] The first and second installments have independent reminder levels.
        FilterReminderLines(ReminderLine, ReminderHeader."No.");
        Assert.AreEqual(2, ReminderLine.Count(), 'Only the first two installments are overdue.');
        GetInstallment(Entry, Invoice."Installment Plan ID", 1);
#pragma warning disable AA0210 // Lines are already scoped to a single reminder and customer ledger entry type.
        ReminderLine.SetRange("Entry No.", Entry."Entry No.");
#pragma warning restore AA0210
        ReminderLine.FindFirst();
        ReminderLine.TestField("No. of Reminders", 2);
        GetInstallment(Entry, Invoice."Installment Plan ID", 2);
#pragma warning disable AA0210 // Lines are already scoped to a single reminder and customer ledger entry type.
        ReminderLine.SetRange("Entry No.", Entry."Entry No.");
#pragma warning restore AA0210
        ReminderLine.FindFirst();
        ReminderLine.TestField("No. of Reminders", 1);
        VerifyRemaining(Invoice."Installment Plan ID", 3, 41.66);

        // [WHEN] Flow step 4: The previously reminded first installment is settled and reminders are suggested again.
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 41.67);
        SuggestReminder(ReminderHeader, Invoice, CalcDate('<80D>', Invoice."Document Date"), true);

        // [THEN] Only the second installment is still demanded.
        FilterReminderLines(ReminderLine, ReminderHeader."No.");
        Assert.AreEqual(1, ReminderLine.Count(), 'A settled installment must no longer be collected.');
        ReminderLine.FindFirst();
        ReminderLine.TestField("Entry No.", Entry."Entry No.");
        ReminderLine.TestField("Remaining Amount", 41.67);
    end;

    [Test]
    procedure FinanceChargesUseOnlyOverdueRemainingBalances()
    var
        Invoice: Record "Sales Invoice Header";
        Customer: Record Customer;
        PostingGroup: Record "Customer Posting Group";
        InvoiceLine: Record "Sales Invoice Line";
        Terms: Record "Finance Charge Terms";
        Header: Record "Finance Charge Memo Header";
        Line: Record "Finance Charge Memo Line";
        Entry: Record "Cust. Ledger Entry";
        FinanceChargeMake: Codeunit "FinChrgMemo-Make";
    begin
        // [SCENARIO] Finance charges use each overdue installment's remaining balance, not the invoice total.
        // [GIVEN] A partly paid first installment and 12 percent open-entry finance charge terms.
        CreatePostedInvoice(Invoice, '', false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 10);
        LibraryERM.CreateFinanceChargeTerms(Terms);
        Terms.Validate("Interest Calculation", Terms."Interest Calculation"::"Open Entries");
        Terms.Validate("Interest Calculation Method", Terms."Interest Calculation Method"::"Balance Due");
        Terms.Validate("Interest Rate", 12);
        Terms.Validate("Minimum Amount (LCY)", 0);
        Terms.Validate("Additional Fee (LCY)", 0);
        Evaluate(Terms."Grace Period", '<0D>');
        Evaluate(Terms."Due Date Calculation", '<14D>');
        Terms.Modify(true);
        Customer.Get(Invoice."Bill-to Customer No.");
        Customer.Validate("Fin. Charge Terms Code", Terms.Code);
        Customer.Modify(true);
        InvoiceLine.SetRange("Document No.", Invoice."No.");
        InvoiceLine.SetRange(Type, InvoiceLine.Type::"G/L Account");
        InvoiceLine.FindFirst();
        PostingGroup.Get(Customer."Customer Posting Group");
        PostingGroup.Validate("Interest Account", InvoiceLine."No.");
        PostingGroup.Modify(true);
        LibraryERM.CreateFinanceChargeMemoHeader(Header, Customer."No.");
        Header.Validate("Document Date", CalcDate('<45D>', Invoice."Document Date"));
        Header.Modify(true);

        // [WHEN] Finance charges are suggested before the other installments are due.
        FinanceChargeMake.SuggestLines(Header, Entry);
        Assert.IsTrue(FinanceChargeMake.Code(), 'Native finance charge suggestion must succeed.');

        // [THEN] Only the overdue balance of 31.67 incurs interest of 3.80.
        Line.SetRange("Finance Charge Memo No.", Header."No.");
        Line.SetRange(Type, Line.Type::"Customer Ledger Entry");
        Assert.AreEqual(1, Line.Count(), 'Future installments must not incur interest.');
        Line.FindFirst();
        GetInstallment(Entry, Invoice."Installment Plan ID", 1);
        Line.TestField("Entry No.", Entry."Entry No.");
        Line.TestField("Remaining Amount", 31.67);
        Line.TestField(Amount, 3.80);
        VerifyRemaining(Invoice."Installment Plan ID", 2, 41.67);
        VerifyRemaining(Invoice."Installment Plan ID", 3, 41.66);
        // [WHEN] The first installment is settled and charges are suggested after the second falls due.
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 31.67);
        Header.Validate("Document Date", CalcDate('<75D>', Invoice."Document Date"));
        Header.Modify(true);
        Clear(FinanceChargeMake);
        Entry.Reset();
        FinanceChargeMake.SuggestLines(Header, Entry);
        Assert.IsTrue(FinanceChargeMake.Code(), 'Native finance charge resuggestion must succeed.');
        // [THEN] Only the second installment's remaining 41.67 incurs interest of 5.
        Assert.AreEqual(1, Line.Count(), 'Settled and future installments must not incur open-entry interest.');
        Line.FindFirst();
        GetInstallment(Entry, Invoice."Installment Plan ID", 2);
        Line.TestField("Entry No.", Entry."Entry No.");
        Line.TestField("Remaining Amount", 41.67);
        Line.TestField(Amount, 5);
    end;

    [Test]
    procedure StatementPreservesLogicalInvoiceTotalsAndSeparateDueBalances()
    var
        Invoice: Record "Sales Invoice Header";
        Customer: Record Customer;
        Statement: Report "Standard Statement";
        Blob: Codeunit "Temp Blob";
        Output: OutStream;
        Input: InStream;
        Value: Variant;
        RowAmount: Decimal;
        OriginalTotal: Decimal;
        RemainingTotal: Decimal;
        RowCount: Integer;
    begin
        // [SCENARIO] Customer statements retain separately due balances without multiplying logical invoice totals.
        // [GIVEN] An invoice of 125 with 10 paid against its first installment.
        CreatePostedInvoice(Invoice, '', false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 10);
        Customer.Get(Invoice."Bill-to Customer No.");
        Customer.SetRecFilter();
        Statement.SetTableView(Customer);
        Statement.InitializeRequest(
            true, true, true, false, true, false, '<1M>', 0, false,
            Invoice."Posting Date", CalcDate('<45D>', Invoice."Document Date"));
        Blob.CreateOutStream(Output);

        // [WHEN] A statement is generated while only the first installment is overdue.
        Statement.SaveAs('', ReportFormat::Xml, Output);

        // [THEN] Three rows total 125 originally and 115 remaining, with only 31.67 overdue.
        Blob.CreateInStream(Input);
        LibraryReportDataset.LoadFromInStream(Input);
        LibraryReportDataset.SetXmlNodeList(
            StrSubstNo(StatementEntryXPathTok, Invoice."No."));
        while LibraryReportDataset.GetNextRow() do begin
            RowCount += 1;
            LibraryReportDataset.FindCurrentRowValue('Amt_DtldCustLedgEntries', Value);
            Evaluate(RowAmount, Format(Value), 9);
            OriginalTotal += RowAmount;
            LibraryReportDataset.FindCurrentRowValue('RemainAmt_DtldCustLedgEntries', Value);
            Evaluate(RowAmount, Format(Value), 9);
            RemainingTotal += RowAmount;
        end;
        Assert.AreEqual(3, RowCount, 'One logical invoice must retain its three separately due obligations.');
        Assert.AreEqual(125, OriginalTotal, 'Statement rows must not repeat the full invoice amount per installment.');
        Assert.AreEqual(115, RemainingTotal, 'Statement rows must include only the actual remaining installment balances.');
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists('OverdueBalance', 31.67);
    end;

    [Test]
    procedure AutomaticReconciliationRequiresSelectionForSharedInvoiceReferences()
    var
        Invoice: Record "Sales Invoice Header";
        Header: Record "Bank Acc. Reconciliation";
        Line: Record "Bank Acc. Reconciliation Line";
        Applied: Record "Applied Payment Entry";
        MatchPayments: Codeunit "Match Bank Payments";
        Amounts: array[3] of Decimal;
        Index: Integer;
    begin
        // [SCENARIO] An invoice reference and receipt amount cannot silently choose among open installments.
        // [GIVEN] Three open installments sharing one invoice reference and receipts matching equal, residual, or total amounts.
        CreatePostedInvoice(Invoice, '', false);
        ConfigureMatchingRules();
        Amounts[1] := 41.67;
        Amounts[2] := 41.66;
        Amounts[3] := 125;
        for Index := 1 to ArrayLen(Amounts) do begin
            CreateReconciliation(Header, Line, Invoice."No.", Amounts[Index]);
            Commit();
            MatchPayments.SetApplyEntries(true);

            // [WHEN] Automatic reconciliation tries to select obligations using the shared reference.
            asserterror MatchPayments.Code(Line);

            // [THEN] Manual selection is required and no applications or balance changes survive.
            Assert.ExpectedError(ManualSelectionErr);
            Applied.FilterAppliedPmtEntry(Line);
            Assert.IsTrue(Applied.IsEmpty(), 'Neither equal amounts, a unique residual, nor a full invoice reference may choose installments automatically.');
            Line.Get(Line."Statement Type", Line."Bank Account No.", Line."Statement No.", Line."Statement Line No.");
            Line.TestField("Applied Amount", 0);
            VerifyRemaining(Invoice."Installment Plan ID", 1, 41.67);
            VerifyRemaining(Invoice."Installment Plan ID", 2, 41.67);
            VerifyRemaining(Invoice."Installment Plan ID", 3, 41.66);
            Clear(MatchPayments);
        end;
    end;

    [Test]
    procedure DuplicateExternalReferencesCannotChooseAnInstallment()
    var
        Invoice: Record "Sales Invoice Header";
        OtherInvoice: Record "Sales Invoice Header";
        Header: Record "Bank Acc. Reconciliation";
        Line: Record "Bank Acc. Reconciliation Line";
        Applied: Record "Applied Payment Entry";
        MatchPayments: Codeunit "Match Bank Payments";
        ExternalNo: Code[35];
    begin
        // [SCENARIO] A shared external reference cannot choose an invoice or installment for reconciliation.
        // [GIVEN] Two installment invoices share an external reference matching one receipt.
        ExternalNo := LibraryUtility.GenerateGUID();
        CreatePostedInvoice(Invoice, ExternalNo, false);
        CreatePostedInvoice(OtherInvoice, ExternalNo, false);
        ConfigureMatchingRules();
        CreateReconciliation(Header, Line, ExternalNo, 41.67);
        Commit();
        MatchPayments.SetApplyEntries(true);

        // [WHEN] Automatic reconciliation attempts to match that reference.
        asserterror MatchPayments.Code(Line);

        // [THEN] Explicit selection is required and neither invoice is applied or reduced.
        Assert.ExpectedError(ManualSelectionErr);
        Applied.FilterAppliedPmtEntry(Line);
        Assert.IsTrue(Applied.IsEmpty(), 'A shared external reference must not choose an invoice or installment.');
        VerifyRemaining(Invoice."Installment Plan ID", 1, 41.67);
        VerifyRemaining(OtherInvoice."Installment Plan ID", 1, 41.67);
    end;

    [Test]
    procedure ManualReconciliationPostsOnlySelectedInstallments()
    var
        Invoice: Record "Sales Invoice Header";
        Header: Record "Bank Acc. Reconciliation";
        Line: Record "Bank Acc. Reconciliation Line";
        Entry: Record "Cust. Ledger Entry";
        Applied: Record "Applied Payment Entry";
        BankPost: Codeunit "Bank Acc. Reconciliation Post";
    begin
        // [SCENARIO] Manually reconciling selected installments preserves payments on unselected obligations.
        // [GIVEN] A partly paid final installment and a receipt explicitly selecting the first two installments.
        CreatePostedInvoice(Invoice, '', false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 3, 10);
        CreateReconciliation(Header, Line, Invoice."No.", 83.34);
        GetInstallment(Entry, Invoice."Installment Plan ID", 1);
        SelectReconciliationEntry(Line, Entry);
        GetInstallment(Entry, Invoice."Installment Plan ID", 2);
        SelectReconciliationEntry(Line, Entry);
        Applied.FilterAppliedPmtEntry(Line);
        Assert.AreEqual(2, Applied.Count(), 'A multi-installment receipt must identify both selected entries.');

        // [WHEN] The reconciliation is posted.
        BankPost.Run(Header);

        // [THEN] Only the selected installments close and the final installment retains its remaining 31.66.
        VerifyRemaining(Invoice."Installment Plan ID", 1, 0);
        VerifyRemaining(Invoice."Installment Plan ID", 2, 0);
        VerifyRemaining(Invoice."Installment Plan ID", 3, 31.66);
        Invoice.CalcFields("Remaining Amount");
        Assert.AreEqual(31.66, Invoice."Remaining Amount", 'Native reconciliation must preserve the earlier non-selected payment and invoice grouping.');
    end;

    [Test]
    [HandlerFunctions('MatchSummaryHandler')]
    procedure LastOpenInstallmentRetainsNativeAutomaticMatching()
    var
        Invoice: Record "Sales Invoice Header";
        Header: Record "Bank Acc. Reconciliation";
        Line: Record "Bank Acc. Reconciliation Line";
        Entry: Record "Cust. Ledger Entry";
        Applied: Record "Applied Payment Entry";
        MatchPayments: Codeunit "Match Bank Payments";
        BankPost: Codeunit "Bank Acc. Reconciliation Post";
    begin
        // [SCENARIO] Native automatic reconciliation remains available when only one installment is open.
        // [GIVEN] The first two installments are settled and a receipt matches the last obligation.
        CreatePostedInvoice(Invoice, '', false);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 1, 41.67);
        LibraryInstallments.PayInstallment(Invoice."Installment Plan ID", 2, 41.67);
        ConfigureMatchingRules();
        CreateReconciliation(Header, Line, Invoice."No.", 41.66);
        MatchPayments.SetApplyEntries(true);

        // [WHEN] Automatic reconciliation matches the receipt.
        MatchPayments.Code(Line);

        // [THEN] Exactly the final installment is selected.
        Applied.FilterAppliedPmtEntry(Line);
        Assert.AreEqual(1, Applied.Count(), 'The last open installment has no intra-invoice allocation ambiguity.');
        Applied.FindFirst();
        GetInstallment(Entry, Invoice."Installment Plan ID", 3);
        Applied.TestField("Applies-to Entry No.", Entry."Entry No.");
        // [WHEN] The matched reconciliation is posted.
        BankPost.Run(Header);
        // [THEN] The final obligation and logical invoice are closed.
        VerifyRemaining(Invoice."Installment Plan ID", 3, 0);
        Invoice.CalcFields("Remaining Amount", Closed);
        Invoice.TestField("Remaining Amount", 0);
        Invoice.TestField(Closed, true);
    end;

    [Test]
    [HandlerFunctions('MatchSummaryHandler')]
    procedure OrdinaryInvoiceRetainsNativeAutomaticReconciliation()
    var
        Invoice: Record "Sales Invoice Header";
        Header: Record "Bank Acc. Reconciliation";
        Line: Record "Bank Acc. Reconciliation Line";
        Entry: Record "Cust. Ledger Entry";
        Applied: Record "Applied Payment Entry";
        MatchPayments: Codeunit "Match Bank Payments";
        BankPost: Codeunit "Bank Acc. Reconciliation Post";
    begin
        // [SCENARIO] Ordinary invoices retain native automatic matching and settlement.
        // [GIVEN] A non-installment invoice and a receipt for its full amount.
        CreatePostedInvoice(Invoice, '', true);
        ConfigureMatchingRules();
        CreateReconciliation(Header, Line, Invoice."No.", 125);
        MatchPayments.SetApplyEntries(true);

        // [WHEN] Automatic reconciliation matches the receipt.
        MatchPayments.Code(Line);

        // [THEN] Its single native ledger entry is selected.
        Applied.FilterAppliedPmtEntry(Line);
        Assert.AreEqual(1, Applied.Count(), 'Ordinary invoices must retain native automatic matching.');
        Applied.FindFirst();
        Applied.TestField("Applies-to Entry No.", Invoice."Cust. Ledger Entry No.");
        // [WHEN] The reconciliation is posted.
        BankPost.Run(Header);
        // [THEN] The ordinary invoice entry has no remaining balance and is closed.
        Entry.Get(Invoice."Cust. Ledger Entry No.");
        Entry.CalcFields("Remaining Amount");
        Entry.TestField("Remaining Amount", 0);
        Entry.TestField(Open, false);
    end;

    local procedure CreatePostedInvoice(var Invoice: Record "Sales Invoice Header"; ExternalNo: Code[35]; Ordinary: Boolean)
    var
        Header: Record "Sales Header";
        Line: Record "Sales Line";
        PlanLine: Record "Sales Installment Plan Line";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryInstallments.CreateInvoice(Header, Line, '');
        if ExternalNo = '' then
            ExternalNo := LibraryUtility.GenerateGUID();
        Header.Validate("External Document No.", ExternalNo);
        if Ordinary then begin
            LibraryERM.CreatePaymentTerms(PaymentTerms);
            Header.Validate("Payment Terms Code", PaymentTerms.Code);
        end else begin
            PlanLine.SetRange("Plan ID", Header."Installment Plan ID");
            PlanLine.FindSet(true);
            repeat
                PlanLine."Discount %" := 0;
                Clear(PlanLine."Discount Date Calculation");
                PlanLine.Modify(true);
            until PlanLine.Next() = 0;
        end;
        Header.Modify(true);
        Invoice.Get(LibrarySales.PostSalesDocument(Header, true, true));
    end;

    local procedure ConfigureReminders(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        Terms: Record "Reminder Terms";
        Level: Record "Reminder Level";
        Index: Integer;
    begin
        LibraryERM.CreateReminderTerms(Terms);
        Terms.Validate("Minimum Amount (LCY)", 0);
        Terms.Validate("Post Interest", false);
        Terms.Validate("Post Additional Fee", false);
        Terms.Modify(true);
        for Index := 1 to 2 do begin
            LibraryERM.CreateReminderLevel(Level, Terms.Code);
            Evaluate(Level."Grace Period", '<0D>');
            Evaluate(Level."Due Date Calculation", '<0D>');
            Level.Validate("Additional Fee (LCY)", 0);
            Level.Modify(true);
        end;
        Customer.Get(CustomerNo);
        Customer.Validate("Reminder Terms Code", Terms.Code);
        Customer.Modify(true);
    end;

    local procedure SuggestReminder(var Header: Record "Reminder Header"; Invoice: Record "Sales Invoice Header"; DocumentDate: Date; OverdueOnly: Boolean)
    var
        Entry: Record "Cust. Ledger Entry";
        LineFeeFilter: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        Clear(Header);
        LibraryERM.CreateReminderHeader(Header);
        Header.Validate("Customer No.", Invoice."Bill-to Customer No.");
        Header.Validate("Posting Date", DocumentDate);
        Header.Validate("Document Date", DocumentDate);
        Header.Validate("Due Date", DocumentDate);
        Header.Modify(true);
        ReminderMake.SuggestLines(Header, Entry, OverdueOnly, false, LineFeeFilter);
        Assert.IsTrue(ReminderMake.Code(), 'Native reminder suggestion must succeed.');
    end;

    local procedure FilterReminderLines(var Line: Record "Reminder Line"; ReminderNo: Code[20])
    begin
        Line.Reset();
        Line.SetRange("Reminder No.", ReminderNo);
        Line.SetRange(Type, Line.Type::"Customer Ledger Entry");
    end;

    local procedure ConfigureMatchingRules()
    var
        Rule: Record "Bank Pmt. Appl. Rule";
        Settings: Record "Bank Pmt. Appl. Settings";
        Index: Integer;
    begin
        Settings.GetOrInsert();
        Settings."Cust. Ledger Entries Matching" := true;
        Settings."Vendor Ledger Entries Matching" := false;
        Settings."Bank Ledger Entries Matching" := false;
        Settings."Empl. Ledger Entries Matching" := false;
        Settings."Enable Apply Immediatelly" := false;
        Settings.Modify(true);
        Rule.DeleteAll(true);
        for Index := 1 to 2 do begin
            Rule.Init();
            Rule."Match Confidence" := Rule."Match Confidence"::High;
            Rule.Priority := Index;
            if Index = 1 then
                Rule."Doc. No./Ext. Doc. No. Matched" := Rule."Doc. No./Ext. Doc. No. Matched"::Yes
            else
                Rule."Doc. No./Ext. Doc. No. Matched" := Rule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple";
            Rule.Insert(true);
        end;
    end;

    local procedure CreateReconciliation(var Header: Record "Bank Acc. Reconciliation"; var Line: Record "Bank Acc. Reconciliation Line"; Reference: Text[140]; Amount: Decimal)
    begin
        LibraryERM.CreateBankAccReconciliation(
            Header, LibraryERM.CreateBankAccountNo(), Header."Statement Type"::"Payment Application");
        Header."Post Payments Only" := true;
        Header.Modify(true);
        LibraryERM.CreateBankAccReconciliationLn(Line, Header);
        Line.Validate("Transaction Text", Reference);
        Line.Validate("Transaction Date", WorkDate());
        Line.Validate("Statement Amount", Amount);
        Line.Modify(true);
        Line.SetRecFilter();
    end;

    local procedure SelectReconciliationEntry(Line: Record "Bank Acc. Reconciliation Line"; Entry: Record "Cust. Ledger Entry")
    var
        Applied: Record "Applied Payment Entry";
    begin
        Applied.Init();
        Applied.TransferFromBankAccReconLine(Line);
        Applied.Validate("Account Type", Applied."Account Type"::Customer);
        Applied.Validate("Account No.", Entry."Customer No.");
        Applied.Validate("Applies-to Entry No.", Entry."Entry No.");
        Applied.Validate("Match Confidence", Applied."Match Confidence"::Manual);
        Applied.Insert(true);
    end;

    local procedure GetInstallment(var Entry: Record "Cust. Ledger Entry"; PlanID: Guid; Sequence: Integer)
    var
        Line: Record "Sales Installment Plan Line";
    begin
        Line.SetRange("Plan ID", PlanID);
        Line.SetRange("Installment No.", Sequence);
        Line.FindFirst();
        Entry.Get(Line."Cust. Ledger Entry No.");
    end;

    local procedure VerifyRemaining(PlanID: Guid; Sequence: Integer; Expected: Decimal)
    var
        Entry: Record "Cust. Ledger Entry";
    begin
        GetInstallment(Entry, PlanID, Sequence);
        Entry.CalcFields("Remaining Amount");
        Entry.TestField("Remaining Amount", Expected);
        Entry.TestField(Open, Expected <> 0);
    end;

    [MessageHandler]
    procedure MatchSummaryHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'applied') > 0, 'Expected the native matching summary.');
    end;
}
