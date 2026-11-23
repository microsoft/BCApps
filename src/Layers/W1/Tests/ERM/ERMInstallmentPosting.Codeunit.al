// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Integration.Entity;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

codeunit 134493 "ERM Installment Posting"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Installments] [Sales] [Posting]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInstallments: Codeunit "Library - ERM Installments";
        InstallmentPosting: Codeunit "Installment Posting";
        SalesInstallmentHistory: Codeunit "Sales Installment History";
        FailureSequence: Integer;
        ForcedFailureErr: Label 'Forced installment posting failure.', Locked = true;

    [Test]
    procedure DisabledFeatureIgnoresGlobalRulesForSalesInvoiceAndJournal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        OrdinaryTerms: Record "Payment Terms";
        InstallmentTermsCode: Code[10];
    begin
        // [SCENARIO] Disabled global rules neither create a sales schedule nor restrict ordinary journal use.
        // [GIVEN] An ordinary sales invoice and disabled global installment rules.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        InstallmentTermsCode := SalesHeader."Payment Terms Code";
        LibraryERM.CreatePaymentTerms(OrdinaryTerms);
        SalesHeader.Validate("Payment Terms Code", OrdinaryTerms.Code);
        SalesHeader.Modify(true);
        LibraryInstallments.SetFeatureEnabled(false);

        // [WHEN] Installment payment terms are selected while the feature is disabled.
        SalesHeader.Validate("Payment Terms Code", InstallmentTermsCode);
        SalesHeader.Modify(true);
        // [THEN] No global plan is created and ordinary customer journal validation accepts the terms.
        Assert.IsTrue(IsNullGuid(SalesHeader."Installment Plan ID"), 'Disabled global rules must not create a sales installment plan.');
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
        GenJournalLine."Payment Terms Code" := InstallmentTermsCode;
        InstallmentPosting.CheckJournalLine(GenJournalLine);
    end;

    [Test]
    procedure PostingSplitsOnlyReceivablesAndPreservesDiscountedInvoiceTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Plan: Record "Sales Installment Plan";
        PlanLine: Record "Sales Installment Plan Line";
        TempPreviewLine: Record "Sales Installment Plan Line" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DimensionValue: Record "Dimension Value";
        DiscountByType: Codeunit "Sales - Calc Discount By Type";
        LibraryDimension: Codeunit "Library - Dimension";
        SalesInstallmentMgt: Codeunit "Sales Installment Mgt.";
    begin
        // [SCENARIO] Installment posting splits receivables without multiplying discounted revenue, profit, or VAT.
        // [GIVEN] A previewed installment invoice with dimensions, an invoice discount, and negative profit.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        LibraryDimension.CreateDimWithDimValue(DimensionValue);
        SalesHeader.Validate(
            "Dimension Set ID", LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code));
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
        SalesLine.Validate("Dimension Set ID", SalesHeader."Dimension Set ID");
        SalesLine.Validate("Unit Cost (LCY)", 120);
        SalesLine.Modify(true);
        DiscountByType.ApplyInvDiscBasedOnAmt(10, SalesHeader);
        Plan.Get(SalesHeader."Installment Plan ID");
        SalesInstallmentMgt.CalculatePreview(SalesHeader, TempPreviewLine);

        // [WHEN] The invoice is posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The posted schedule matches the preview and financial totals are allocated or posted exactly once.
        VerifyPostedSchedule(SalesInvoiceHeader, Plan.ID);
        TempPreviewLine.FindSet();
        repeat
            PlanLine.Get(Plan.ID, TempPreviewLine."Line No.");
            Assert.AreEqual(TempPreviewLine.Amount, PlanLine.Amount, 'Fresh preview must match each posted document amount.');
            Assert.AreEqual(TempPreviewLine."Amount (LCY)", PlanLine."Amount (LCY)", 'Fresh preview must match each posted LCY amount.');
            Assert.AreEqual(TempPreviewLine."Due Date", PlanLine."Due Date", 'Fresh preview must match each posted due date.');
            Assert.AreEqual(
                TempPreviewLine."Original Pmt. Disc. Possible", PlanLine."Original Pmt. Disc. Possible",
                'Fresh preview must match each posted discount eligibility.');
        until TempPreviewLine.Next() = 0;
        Plan.Get(Plan.ID);
        Assert.AreEqual(112.5, Plan.Amount, 'The schedule must include VAT and the invoice discount exactly once.');
        CustLedgerEntry.SetRange("Installment Plan ID", Plan.ID);
        CustLedgerEntry.CalcSums("Sales (LCY)", "Profit (LCY)", "Inv. Discount (LCY)");
        Assert.AreEqual(90, CustLedgerEntry."Sales (LCY)", 'Sales must not be multiplied by the number of installments.');
        Assert.AreEqual(-30, CustLedgerEntry."Profit (LCY)", 'Negative profit must reconcile independently.');
        Assert.AreEqual(10, CustLedgerEntry."Inv. Discount (LCY)", 'Invoice discount must reconcile independently.');
        GLEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        GLEntry.SetRange("G/L Account No.", SalesLine."No.");
        Assert.AreEqual(1, GLEntry.Count(), 'The sales account must be posted once.');
        GLEntry.FindFirst();
        Assert.AreEqual(-90, GLEntry.Amount, 'Revenue must retain the native invoice amount.');
        VATEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        Assert.AreEqual(1, VATEntry.Count(), 'VAT must be posted once.');
    end;

    [Test]
    procedure ForeignCurrencyPostingKeepsIndependentLCYResidualAndCurrencyFactors()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Plan: Record "Sales Installment Plan";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CurrencyFactor: Decimal;
    begin
        // [SCENARIO] Foreign-currency posting allocates LCY residuals independently while retaining original currency factors.
        // [GIVEN] An installment invoice whose document and LCY amounts have different rounding residuals.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 0.3, 0.3));
        SalesLine.Validate("Unit Price", 100.03);
        SalesLine.Modify(true);
        Plan.Get(SalesHeader."Installment Plan ID");
        CurrencyFactor := SalesHeader."Currency Factor";

        // [WHEN] The foreign-currency invoice is posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The final LCY residual is independent of the rounded document amount and every entry retains both factors.
        VerifyPostedSchedule(SalesInvoiceHeader, Plan.ID);
        PlanLine.SetRange("Plan ID", Plan.ID);
        PlanLine.FindLast();
        Assert.AreNotEqual(
            Round(PlanLine.Amount / CurrencyFactor, 0.01), PlanLine."Amount (LCY)",
            'The final LCY residual must not be derived from its rounded document-currency amount.');
        CustLedgerEntry.SetRange("Installment Plan ID", Plan.ID);
        CustLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(CurrencyFactor, CustLedgerEntry."Original Currency Factor", 'The factor must not be allocated.');
            Assert.AreEqual(CurrencyFactor, CustLedgerEntry."Adjusted Currency Factor", 'The original factor must be retained.');
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure PostingRecalculatesToleranceCapsPerEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Installments] [Posting]
        // [SCENARIO] Payment tolerance caps and discount grace dates are calculated per installment.
        // [GIVEN] An unblocked customer and installments with different amounts and nonzero tolerance settings.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        GLSetup.Get();
        GLSetup."Payment Tolerance %" := 2;
        GLSetup."Max. Payment Tolerance Amount" := 0.5;
        Evaluate(GLSetup."Payment Discount Grace Period", '<5D>');
        GLSetup.Modify();
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer."Block Payment Tolerance" := false;
        Customer.Modify(true);
        PlanLine.Get(SalesHeader."Installment Plan ID", 10000);
        PlanLine."Payment %" := 10;
        PlanLine.Modify(true);
        PlanLine.Get(SalesHeader."Installment Plan ID", 20000);
        PlanLine."Payment %" := 20;
        PlanLine.Modify(true);

        // [WHEN] The installment invoice is posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] Each entry has its own percentage-based tolerance, capped amount, and discount grace date.
        VerifyPostedSchedule(SalesInvoiceHeader, SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.FindSet();
        repeat
            if CustLedgerEntry."Installment No." = 1 then
                Assert.AreEqual(0.25, CustLedgerEntry."Max. Payment Tolerance", 'The percentage must use this installment, not the invoice total.')
            else
                Assert.AreEqual(0.5, CustLedgerEntry."Max. Payment Tolerance", 'The native cap must apply independently to each installment.');
            if CustLedgerEntry."Pmt. Discount Date" = 0D then
                Assert.AreEqual(0D, CustLedgerEntry."Pmt. Disc. Tolerance Date", 'No discount date must mean no discount tolerance date.')
            else
                Assert.AreEqual(
                    CalcDate(GLSetup."Payment Discount Grace Period", CustLedgerEntry."Pmt. Discount Date"),
                    CustLedgerEntry."Pmt. Disc. Tolerance Date", 'Each installment must retain its own grace-period date.');
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure PostingHonorsCustomerPaymentToleranceBlock()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [Installments] [Posting]
        // [SCENARIO] A customer payment tolerance block suppresses tolerance on every installment.
        // [GIVEN] An installment invoice with nonzero tolerance settings and a customer blocking payment tolerance.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        GLSetup.Get();
        GLSetup."Payment Tolerance %" := 2;
        GLSetup."Max. Payment Tolerance Amount" := 0.5;
        Evaluate(GLSetup."Payment Discount Grace Period", '<5D>');
        GLSetup.Modify();
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer."Block Payment Tolerance" := true;
        Customer.Modify(true);

        // [WHEN] The installment invoice is posted.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] All installment entries have zero payment tolerance and no discount tolerance date.
        VerifyPostedSchedule(SalesInvoiceHeader, SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(0, CustLedgerEntry."Max. Payment Tolerance", 'The customer block must apply to every installment.');
            Assert.AreEqual(0D, CustLedgerEntry."Pmt. Disc. Tolerance Date", 'The customer block must also suppress discount tolerance dates.');
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure AuxiliaryAmountsAllocateNegativeProfitAndFinalResidualIndependently()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
    begin
        // [SCENARIO] Each posting amount is allocated independently, including negative profit and final-line residuals.
        // [GIVEN] Three installment rules and journal totals requiring distinct rounding residuals.
        LibraryInstallments.Initialize();
        LibraryInstallments.CreateTemporaryRules(TempPlanLine);
        GenJournalLine."Document Date" := WorkDate();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine.Amount := 100.01;
        GenJournalLine."Amount (LCY)" := 200.03;
        GenJournalLine."Source Currency Amount" := 100.01;
        GenJournalLine."Sales/Purch. (LCY)" := 180.05;
        GenJournalLine."Profit (LCY)" := -10.01;
        GenJournalLine."Inv. Discount (LCY)" := 0.05;

        // [WHEN] Installment posting amounts are calculated.
        InstallmentPosting.CalculatePostingLines(GenJournalLine, TempPlanLine);

        // [THEN] Every total reconciles and the final installment absorbs each amount's own residual.
        TempPlanLine.CalcSums(Amount, "Amount (LCY)", "Source Currency Amount", "Sales (LCY)", "Profit (LCY)", "Inv. Discount (LCY)");
        Assert.AreEqual(100.01, TempPlanLine.Amount, 'Document amounts must reconcile.');
        Assert.AreEqual(200.03, TempPlanLine."Amount (LCY)", 'LCY amounts must reconcile independently.');
        Assert.AreEqual(100.01, TempPlanLine."Source Currency Amount", 'Source currency must reconcile independently.');
        Assert.AreEqual(180.05, TempPlanLine."Sales (LCY)", 'Sales must reconcile independently.');
        Assert.AreEqual(-10.01, TempPlanLine."Profit (LCY)", 'Negative profit must reconcile independently.');
        Assert.AreEqual(0.05, TempPlanLine."Inv. Discount (LCY)", 'Invoice discount must reconcile independently.');
        TempPlanLine.FindLast();
        Assert.AreEqual(33.33, TempPlanLine.Amount, 'The final line must take the document residual.');
        Assert.AreEqual(66.67, TempPlanLine."Amount (LCY)", 'The final line must take the independent LCY residual.');
        Assert.AreEqual(-3.33, TempPlanLine."Profit (LCY)", 'The final line must take the negative profit residual.');
        Assert.AreEqual(0.01, TempPlanLine."Inv. Discount (LCY)", 'The final line must take the invoice discount residual.');
    end;

    [Test]
    procedure RoundedZeroLCYInstallmentHasNoPaymentDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempPlanLine: Record "Sales Installment Plan Line" temporary;
    begin
        // [SCENARIO] An installment rounded to zero LCY has no payment discount.
        // [GIVEN] Three installment rules and a positive document amount worth only 0.01 LCY.
        LibraryInstallments.Initialize();
        LibraryInstallments.CreateTemporaryRules(TempPlanLine);
        GenJournalLine."Document Date" := WorkDate();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine.Amount := 100;
        GenJournalLine."Amount (LCY)" := 0.01;

        // [WHEN] Installment posting amounts are calculated.
        InstallmentPosting.CalculatePostingLines(GenJournalLine, TempPlanLine);

        // [THEN] A zero-LCY installment has no discount and the final installment takes the LCY residual.
        TempPlanLine.FindFirst();
        Assert.AreEqual(0, TempPlanLine."Amount (LCY)", 'A positive document installment may round to zero LCY.');
        Assert.AreEqual(0, TempPlanLine."Original Pmt. Disc. Possible", 'Native zero-LCY discount exclusion must be preserved.');
        TempPlanLine.FindLast();
        Assert.AreEqual(0.01, TempPlanLine."Amount (LCY)", 'The final installment must absorb the LCY residual.');
    end;

    [Test]
    procedure FailureAfterSecondInstallmentRollsBackFinancialEntriesAndSnapshot()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostingObserver: Codeunit "ERM Installment Posting";
        SalesPost: Codeunit "Sales-Post";
        PlanID: Guid;
        PostingNo: Code[20];
    begin
        // [SCENARIO] Failed installment posting rolls back completely and can be retried without duplicate invoices.
        // [GIVEN] A draft invoice and an injected failure after posting its second installment.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PreparePostingAttempt(SalesHeader);
        PlanID := SalesHeader."Installment Plan ID";
        PostingNo := SalesHeader."Posting No.";
        Commit();
        PostingObserver.SetFailureSequence(2);
        BindSubscription(PostingObserver);
        SalesPost.SetSuppressCommit(true);

        // [WHEN] Posting reaches the injected failure.
        asserterror SalesPost.Run(SalesHeader);

        // [THEN] Financial entries and posted snapshot state roll back, leaving the original draft.
        Assert.ExpectedError(ForcedFailureErr);
        UnbindSubscription(PostingObserver);
        VerifyDraftAfterRollback(PlanID, PostingNo);

        // [WHEN] Posting is retried without the failing subscriber.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Clear(SalesPost);
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);

        // [THEN] Exactly one complete posted invoice and schedule are created.
        SalesInvoiceHeader.Get(PostingNo);
        VerifyPostedSchedule(SalesInvoiceHeader, PlanID);
        SalesInvoiceHeader.SetRange("Installment Plan ID", PlanID);
        Assert.AreEqual(1, SalesInvoiceHeader.Count(), 'Retry must create exactly one complete posted invoice.');
    end;

    [Test]
    procedure PostingPreviewRollsBackPostedPlanAndEveryInstallment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        PlanID: Guid;
        PostingNo: Code[20];
    begin
        // [SCENARIO] Posting preview leaves no posted installment state or financial entries.
        // [GIVEN] A draft installment invoice prepared for posting in preview mode.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PreparePostingAttempt(SalesHeader);
        PlanID := SalesHeader."Installment Plan ID";
        PostingNo := SalesHeader."Posting No.";
        Commit();
        SalesPost.SetPreviewMode(true);

        // [WHEN] The posting preview runs.
        asserterror SalesPost.Run(SalesHeader);

        // [THEN] Preview completion rolls back every installment and preserves the draft snapshot.
        Assert.ExpectedError('Preview mode.');
        VerifyDraftAfterRollback(PlanID, PostingNo);
    end;

    [Test]
    procedure OrdinaryInvoiceRemainsSingleWhenReusableRulesAreAdded()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentTerms: Record "Payment Terms";
        OriginalRule: Record "Payment Term Installment";
        Rule: Record "Payment Term Installment";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesPost: Codeunit "Sales-Post";
        PostedNo: Code[20];
    begin
        // [SCENARIO] Adding reusable rules does not retroactively split an ordinary invoice or leak prior posting context.
        // [GIVEN] A reused posting codeunit and an ordinary invoice whose terms gain installment rules after selection.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PreparePostingAttempt(SalesHeader);
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        OriginalRule.SetRange("Payment Terms Code", SalesHeader."Payment Terms Code");
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
        OriginalRule.FindSet();
        repeat
            Rule := OriginalRule;
            Rule."Payment Terms Code" := PaymentTerms.Code;
            Rule.Insert(true);
        until OriginalRule.Next() = 0;
        PreparePostingAttempt(SalesHeader);
        PostedNo := SalesHeader."Posting No.";

        // [WHEN] The ordinary follow-up invoice is posted without reselecting its terms.
        SalesPost.Run(SalesHeader);

        // [THEN] It retains one self-grouped native receivable without an installment plan.
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", PostedNo);
        Assert.AreEqual(1, CustLedgerEntry.Count(), 'The ordinary follow-up invoice must post once.');
        CustLedgerEntry.FindFirst();
        Assert.IsTrue(IsNullGuid(CustLedgerEntry."Installment Plan ID"), 'No installment context may leak into an ordinary invoice.');
        Assert.AreEqual(CustLedgerEntry."Entry No.", CustLedgerEntry."Invoice Entry No.", 'An ordinary entry must identify only itself.');
        SalesInvoiceHeader.Get(PostedNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        VerifyInvoiceBalance(SalesInvoiceHeader, CustLedgerEntry."Remaining Amount", false);
    end;

    [Test]
    procedure PostedScheduleCannotBeModifiedRenamedOrMovedToAnotherPlan()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Plan: Record "Sales Installment Plan";
        PlanLine: Record "Sales Installment Plan Line";
        PlanID: Guid;
    begin
        // [SCENARIO] Posted schedule ownership and conditions cannot be changed through record operations.
        // [GIVEN] A posted installment schedule and a separate draft plan.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PlanID := SalesHeader."Installment Plan ID";
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        Commit();

        // [WHEN] Attempts are made to reset its status, rename the plan, or move a posted line.
        // [THEN] Every attempt is rejected as a change to an immutable posted schedule.
        Plan.Get(PlanID);
        Plan.Status := Plan.Status::Draft;
        asserterror Plan.Modify(false);
        Assert.ExpectedError('Posted installment schedules cannot be changed');

        Plan.Get(PlanID);
        asserterror Plan.Rename(CreateGuid());
        Assert.ExpectedError('Posted installment schedules cannot be changed');

        PlanLine.SetRange("Plan ID", PlanID);
        PlanLine.FindFirst();
        asserterror PlanLine.Rename(SalesHeader."Installment Plan ID", 40000);
        Assert.ExpectedError('Posted installment schedules cannot be changed');
    end;

    [Test]
    procedure CopyPostedInvoiceClonesRulesWithoutLedgerLinksOrPostedAmounts()
    var
        SourceHeader: Record "Sales Header";
        TargetHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Rule: Record "Payment Term Installment";
        Plan: Record "Sales Installment Plan";
        PlanLine: Record "Sales Installment Plan Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        SourcePlanID: Guid;
        PostedNo: Code[20];
    begin
        // [SCENARIO] Copying a posted invoice creates an independent draft from frozen rules without posted amounts or links.
        // [GIVEN] A posted installment invoice whose reusable rules have changed and a target sales invoice.
        LibraryInstallments.CreateInvoice(SourceHeader, SalesLine, '');
        SourcePlanID := SourceHeader."Installment Plan ID";
        Rule.Get(SourceHeader."Payment Terms Code", 10000);
        PostedNo := LibrarySales.PostSalesDocument(SourceHeader, true, true);
        Rule."Payment %" := 20;
        Rule.Modify();
        LibraryInstallments.CreateInvoice(TargetHeader, SalesLine, '');
        CopyDocumentMgt.SetProperties(true, false, false, false, true, false, false);

        // [WHEN] The posted invoice is copied to the target.
        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", PostedNo, TargetHeader);

        // [THEN] The target owns a fresh draft with frozen source rules and the posted source remains unchanged.
        TargetHeader.Get(TargetHeader."Document Type", TargetHeader."No.");
        Assert.AreNotEqual(SourcePlanID, TargetHeader."Installment Plan ID", 'A copy must never share posted ownership.');
        Plan.Get(TargetHeader."Installment Plan ID");
        Assert.AreEqual(Plan.Status::Draft, Plan.Status, 'The copied schedule must start as a fresh draft.');
        Assert.AreEqual(TargetHeader.SystemId, Plan."Source SystemId", 'The copied invoice must own its snapshot.');
        Assert.IsTrue(IsNullGuid(Plan."Posted Invoice SystemId"), 'Posted target identity must not be copied.');
        PlanLine.Get(Plan.ID, 10000);
        Assert.AreEqual(33.33333, PlanLine."Payment %", 'Copying must retain posted rules, not changed reusable setup.');
        Assert.AreEqual(0, PlanLine."Cust. Ledger Entry No.", 'Ledger links must not be copied.');
        Assert.AreEqual(0, PlanLine.Amount, 'Posted amounts must not be copied.');
        Plan.Get(SourcePlanID);
        Assert.AreEqual(Plan.Status::Posted, Plan.Status, 'The original posted snapshot must remain unchanged.');
    end;

    [Test]
    procedure JournalCannotSilentlyUseGlobalTermsAsASingleReceivable()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        // [SCENARIO] Direct journals cannot silently post installment terms as a single customer receivable.
        // [GIVEN] A customer invoice journal line carrying global installment terms.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
            GenJournalLine."Account Type"::Customer, SalesHeader."Bill-to Customer No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", SalesLine."No.", 100);
        GenJournalLine."Payment Terms Code" := SalesHeader."Payment Terms Code";
        GenJournalLine.Modify(true);
        Commit();

        // [WHEN] The customer-account journal line is posted.
        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] Posting requires the supported standalone sales invoice flow.
        Assert.ExpectedError('full standalone sales invoices only');
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := SalesLine."No.";
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Customer;
        GenJournalLine."Bal. Account No." := SalesHeader."Bill-to Customer No.";
        GenJournalLine.Amount := -100;
        GenJournalLine."Amount (LCY)" := -100;

        // [WHEN] The same posting is attempted with the customer as the balancing account.
        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] The unsupported balancing-account flow is rejected too.
        Assert.ExpectedError('full standalone sales invoices only');
    end;

    [Test]
    procedure InstallmentInvoiceCannotApplyDuringPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
    begin
        // [FEATURE] [Installments] [Posting]
        // [SCENARIO] An installment invoice cannot apply customer entries during posting.
        // [GIVEN] A complete installment invoice with a sales line and posting setup.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PreparePostingAttempt(SalesHeader);
        SalesHeader."Applies-to ID" := 'INSTALLMENT';
        SalesHeader.Modify(true);

        // [WHEN] The invoice is posted with an Applies-to ID.
        asserterror SalesPost.Run(SalesHeader);

        // [THEN] Posting is rejected specifically because of the Applies-to ID.
        Assert.ExpectedError('Applies-to ID');
    end;

    [Test]
    procedure InstallmentInvoiceCannotBeAppliedByDocumentNumber()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        CustomerNo: Code[20];
        PostedNo: Code[20];
    begin
        // [SCENARIO] A shared invoice document number cannot implicitly choose an installment for payment.
        // [GIVEN] A posted installment invoice and a receipt identifying only its document number.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        CustomerNo := SalesHeader."Bill-to Customer No.";
        PostedNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := CustomerNo;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := PostedNo;

        // [WHEN] The receipt is posted.
        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine);

        // [THEN] Posting requires individual installment selection using Applies-to ID.
        Assert.ExpectedError('Select individual installment entries using Applies-to ID');
    end;

    [Test]
    procedure ManualPaymentUsingAppliesToIDClosesOnlyTheSelectedInstallment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OtherCustLedgerEntry: Record "Cust. Ledger Entry";
        PlanID: Guid;
        ApplicationID: Code[50];
    begin
        // [SCENARIO] An explicitly selected payment closes only its target installment.
        // [GIVEN] A posted invoice with its final installment selected by Applies-to ID for the full remaining amount.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PlanID := SalesHeader."Installment Plan ID";
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        CustLedgerEntry.SetRange("Installment No.", 3);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        ApplicationID := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Applies-to ID" := ApplicationID;
        CustLedgerEntry."Amount to Apply" := CustLedgerEntry."Remaining Amount";
        CustLedgerEntry.Modify(true);
        // [WHEN] The selected receipt is posted.
        PostPaymentWithAppliesToID(CustLedgerEntry, ApplicationID, CustLedgerEntry."Remaining Amount", WorkDate());

        // [THEN] Only the selected final installment closes and the other two remain open.
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        Assert.IsFalse(CustLedgerEntry.Open, 'Only the explicitly selected installment must be paid.');
        OtherCustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        OtherCustLedgerEntry.SetRange(Open, true);
        Assert.AreEqual(2, OtherCustLedgerEntry.Count(), 'The other installments must remain open.');
    end;

    [Test]
    procedure PartialPaymentDiscountSettlementAndUnapplyPreserveSchedule()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        // [FEATURE] [Installments] [Application] [Payment Discount]
        // [SCENARIO] Native discount eligibility belongs to an installment, not each partial receipt or the whole invoice.
        // [GIVEN] A posted installment of 41.67 with an eligible 0.83 discount and two later installments.
        CreateSettlementInvoice(SalesHeader, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        PlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 10000);
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");

        // [WHEN] A receipt pays only 10 of that installment.
        LibraryInstallments.PayInstallment(PlanLine."Plan ID", 1, 10);

        // [THEN] No proportional discount is granted and the original discount remains available.
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(31.67, CustLedgerEntry."Remaining Amount", 'A partial receipt must reduce only the selected balance.');
        Assert.AreEqual(0.83, CustLedgerEntry."Remaining Pmt. Disc. Possible", 'A partial receipt must preserve native discount eligibility.');
        FilterLastApplicationDetails(DetailedCustLedgEntry, CustLedgerEntry);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Payment Discount");
        Assert.IsTrue(DetailedCustLedgEntry.IsEmpty(), 'The partial receipt must not grant a proportional discount.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 115, false);

        // [WHEN] Another eligible receipt settles the remaining liability less the original discount.
        LibraryInstallments.PayInstallment(PlanLine."Plan ID", 1, 30.84);

        // [THEN] This installment closes with its native discount while later installments remain open.
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.IsFalse(CustLedgerEntry.Open, 'Discount eligibility must not depend on settling later installments.');
        Assert.AreEqual(0, CustLedgerEntry."Remaining Amount", 'The receipt and discount must close the selected installment.');
        FilterLastApplicationDetails(DetailedCustLedgEntry, CustLedgerEntry);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Payment Discount");
        DetailedCustLedgEntry.CalcSums(Amount);
        Assert.AreEqual(-0.83, DetailedCustLedgEntry.Amount, 'Only the selected installment discount must be realized.');
        CustomerPostingGroup.Get(CustLedgerEntry."Customer Posting Group");
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Payment Disc. Debit Acc.");
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0.83, GLEntry.Amount, 'Native discount expense must reconcile to the installment discount.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 83.33, false);
        PlanLine.Get(PlanLine."Plan ID", PlanLine."Line No.");
        Assert.AreEqual(41.67, PlanLine.Amount, 'Settlement must not rewrite the original obligation.');
        Assert.AreEqual(0.83, PlanLine."Original Pmt. Disc. Possible", 'Settlement must not rewrite the original discount.');

        // [WHEN] The final receipt application and its discount are unapplied.
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.Get(CustEntryApplyPostedEntries.FindLastApplEntry(CustLedgerEntry."Entry No."));
        ApplyUnapplyParameters."Document No." := DetailedCustLedgEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := WorkDate();
        CustEntryApplyPostedEntries.PostUnApplyCustomerCommit(DetailedCustLedgEntry, ApplyUnapplyParameters, false);

        // [THEN] The earlier partial receipt remains applied and the original discount becomes available again.
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.IsTrue(CustLedgerEntry.Open, 'Unapplication must reopen the discounted installment.');
        Assert.AreEqual(31.67, CustLedgerEntry."Remaining Amount", 'Unapplication must preserve the earlier partial receipt.');
        Assert.AreEqual(0.83, CustLedgerEntry."Remaining Pmt. Disc. Possible", 'Unapplication must restore the native discount.');
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, 'Unapplication must reverse the discount expense.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 115, false);
    end;

    [Test]
    procedure MultiInstallmentReceiptUnapplyAndReapplyPreservesSchedule()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        ApplicationID: Code[50];
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Installments] [Application] [Unapplication]
        // [SCENARIO] One receipt spanning all installments can be unapplied and reapplied without changing their identities.
        // [GIVEN] A posted invoice with three installments and no payment discounts.
        CreateSettlementInvoice(SalesHeader, '');
        PlanLine.SetRange("Plan ID", SalesHeader."Installment Plan ID");
        PlanLine.FindSet(true);
        repeat
            PlanLine."Discount %" := 0;
            PlanLine.Modify(true);
        until PlanLine.Next() = 0;
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        ApplicationID := LibraryUtility.GenerateGUID();
        PlanLine.FindSet();
        repeat
            CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
            CustLedgerEntry."Applies-to ID" := ApplicationID;
            CustLedgerEntry."Amount to Apply" := PlanLine.Amount;
            CustLedgerEntry.Modify(true);
        until PlanLine.Next() = 0;
        PaymentNo := PostPaymentWithAppliesToID(CustLedgerEntry, ApplicationID, 125, WorkDate());
        VerifyInvoiceBalance(SalesInvoiceHeader, 0, true);
        LibraryERM.FindCustomerLedgerEntry(PaymentEntry, PaymentEntry."Document Type"::Payment, PaymentNo);
        DetailedCustLedgEntry.Get(CustEntryApplyPostedEntries.FindLastApplEntry(PaymentEntry."Entry No."));
        ApplyUnapplyParameters."Document No." := PaymentNo;
        ApplyUnapplyParameters."Posting Date" := WorkDate();

        // [WHEN] The native application transaction is unapplied through the posted-entry service.
        CustEntryApplyPostedEntries.PostUnApplyCustomerCommit(DetailedCustLedgEntry, ApplyUnapplyParameters, false);

        // [THEN] Every installment reopens on its original ledger link and the invoice balance is restored.
        VerifyInvoiceBalance(SalesInvoiceHeader, 125, false);
        PlanLine.FindSet();
        repeat
            CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
            CustLedgerEntry.CalcFields("Remaining Amount");
            Assert.IsTrue(CustLedgerEntry.Open, 'Unapplication must reopen every installment in the application transaction.');
            Assert.AreEqual(PlanLine."Plan ID", CustLedgerEntry."Installment Plan ID", 'Unapplication must retain plan ownership.');
            Assert.AreEqual(PlanLine."Installment No.", CustLedgerEntry."Installment No.", 'Unapplication must retain the installment sequence.');
            Assert.AreEqual(PlanLine."Due Date", CustLedgerEntry."Due Date", 'Unapplication must retain the original due date.');
            Assert.AreEqual(PlanLine.Amount, CustLedgerEntry."Remaining Amount", 'Unapplication must restore each original balance.');
        until PlanLine.Next() = 0;
        PaymentEntry.Get(PaymentEntry."Entry No.");
        PaymentEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(-125, PaymentEntry."Remaining Amount", 'Unapplication must restore the original receipt.');

        // [WHEN] The same receipt is explicitly reapplied to the same installment entries.
        LibraryERM.SetApplyCustomerEntry(PaymentEntry, PaymentEntry."Remaining Amount");
        PlanLine.FindSet();
        repeat
            CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
            CustLedgerEntry.Validate("Amount to Apply", PlanLine.Amount);
            CustLedgerEntry.Modify(true);
            CustLedgerEntry.SetRecFilter();
            LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        until PlanLine.Next() = 0;
        LibraryERM.PostCustLedgerApplication(PaymentEntry);

        // [THEN] The original invoice closes again without creating replacement installments.
        VerifyInvoiceBalance(SalesInvoiceHeader, 0, true);
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        Assert.AreEqual(3, CustLedgerEntry.Count(), 'Reapplication must reuse the three original receivables.');
        CustLedgerEntry.SetRange(Open, true);
        Assert.IsTrue(CustLedgerEntry.IsEmpty(), 'The reapplied receipt must close every selected installment.');
    end;

    [Test]
    procedure InvoiceBalancesFiltersAndAPIStatusFollowEveryInstallment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Aggregate: Record "Sales Invoice Entity Aggregate";
        PlanLine: Record "Sales Installment Plan Line";
        APIMockEvents: Codeunit "API Mock Events";
        PlanID: Guid;
        SourceID: Guid;
    begin
        // [SCENARIO] Logical invoice balances and API status reflect every installment, not only the final anchor.
        // [GIVEN] An API-enabled installment invoice without payment discounts.
        BindSubscription(APIMockEvents);
        APIMockEvents.SetIsAPIEnabled(true);
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PlanID := SalesHeader."Installment Plan ID";
        SourceID := SalesHeader.SystemId;
        PlanLine.SetRange("Plan ID", PlanID);
        PlanLine.FindSet(true);
        repeat
            PlanLine."Discount %" := 0;
            Clear(PlanLine."Discount Date Calculation");
            PlanLine.Modify(true);
        until PlanLine.Next() = 0;
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        VerifyInvoiceBalance(SalesInvoiceHeader, 125, false);
        // [WHEN] The first and final anchor installments are settled.
        LibraryInstallments.PayInstallment(PlanID, 1, 41.67);
        VerifyInvoiceBalance(SalesInvoiceHeader, 83.33, false);
        LibraryInstallments.PayInstallment(PlanID, 3, 41.66);
        // [THEN] The middle obligation keeps the invoice Open with its original API identity.
        VerifyInvoiceBalance(SalesInvoiceHeader, 41.67, false);
        Aggregate.Get(SalesInvoiceHeader."No.", true);
        Assert.AreEqual(SourceID, Aggregate.Id, 'The API identity must remain the original draft identity.');
        Assert.AreEqual(Aggregate.Status::Open, Aggregate.Status, 'Paying the anchor must not mark the invoice paid.');
        // [WHEN] The middle installment is partly paid.
        LibraryInstallments.PayInstallment(PlanID, 2, 10);
        // [THEN] The invoice remains open for its residual balance.
        VerifyInvoiceBalance(SalesInvoiceHeader, 31.67, false);
        // [WHEN] The remaining non-anchor balance is settled.
        LibraryInstallments.PayInstallment(PlanID, 2, 31.67);
        // [THEN] The logical invoice closes and API status becomes Paid.
        VerifyInvoiceBalance(SalesInvoiceHeader, 0, true);
        Aggregate.Get(SalesInvoiceHeader."No.", true);
        Assert.AreEqual(Aggregate.Status::Paid, Aggregate.Status, 'A non-anchor settlement must refresh API status.');
        UnbindSubscription(APIMockEvents);
    end;

    [Test]
    procedure CustomerEntryEditsPreserveInvoiceSummary()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
        SummaryDueDate: Date;
    begin
        // [SCENARIO] Harmless customer entry edits preserve invoice summary dates.
        // [GIVEN] A posted installment invoice and a middle entry with changed hold and application selections.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SummaryDueDate := SalesInvoiceHeader."Due Date";
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.SetRange("Installment No.", 2);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry."On Hold" := 'X';
        CustLedgerEntry."Applies-to ID" := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Amount to Apply" := 10;

        // [WHEN] The ordinary customer entry edit is saved.
        CustEntryEdit.Run(CustLedgerEntry);

        // [THEN] The logical invoice summary due date is preserved.
        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        Assert.AreEqual(SummaryDueDate, SalesInvoiceHeader."Due Date", 'Entry edits must not replace the invoice summary date.');
    end;

    [Test]
    procedure CustomerEntryEditRejectsInstallmentDueDateChange()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
        EntryDueDate: Date;
    begin
        // [SCENARIO] The customer entry edit codeunit rejects changes to posted installment due dates.
        // [GIVEN] A posted installment invoice and a middle entry with a changed due date.
        LibraryInstallments.CreatePostedInvoice(SalesInvoiceHeader, '', true);
        LibraryInstallments.GetInstallment(CustLedgerEntry, SalesInvoiceHeader."Installment Plan ID", 2);
        EntryDueDate := CustLedgerEntry."Due Date";
        CustLedgerEntry."Due Date" := EntryDueDate + 1;

        // [WHEN] A posted installment due date is changed through the edit codeunit.
        asserterror CustEntryEdit.Run(CustLedgerEntry);

        // [THEN] The change is rejected before detailed entry dates are altered.
        Assert.ExpectedError('Changing posted installment payment conditions is not supported');
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.FindFirst();
        Assert.AreEqual(EntryDueDate, DetailedCustLedgEntry."Initial Entry Due Date", 'The edit must fail before changing detailed entries.');
    end;

    [Test]
    procedure CustomerEntryValidationRejectsInstallmentDueDateChange()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryDueDate: Date;
    begin
        // [SCENARIO] Direct field validation rejects changes to posted installment due dates.
        // [GIVEN] A posted installment invoice and its middle customer entry.
        LibraryInstallments.CreatePostedInvoice(SalesInvoiceHeader, '', true);
        LibraryInstallments.GetInstallment(CustLedgerEntry, SalesInvoiceHeader."Installment Plan ID", 2);
        EntryDueDate := CustLedgerEntry."Due Date";

        // [WHEN] Direct due-date validation is attempted.
        asserterror CustLedgerEntry.Validate("Due Date", EntryDueDate + 1);

        // [THEN] The posted-condition restriction rejects the change.
        Assert.ExpectedError('Changing posted installment payment conditions is not supported');
    end;

    [Test]
    procedure PostedHeaderEditsDoNotOverwriteTheAnchorInstallmentDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesInvHeaderEdit: Codeunit "Sales Inv. Header - Edit";
        AnchorDueDate: Date;
    begin
        // [SCENARIO] Posted invoice header edits preserve the anchor installment's own payment conditions.
        // [GIVEN] A posted installment invoice with a changed posting description.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.");
        AnchorDueDate := CustLedgerEntry."Due Date";
        SalesInvoiceHeader."Posting Description" := LibraryUtility.GenerateGUID();

        // [WHEN] The harmless header edit is saved.
        SalesInvHeaderEdit.Run(SalesInvoiceHeader);

        // [THEN] The anchor installment keeps its original due date.
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        Assert.AreEqual(AnchorDueDate, CustLedgerEntry."Due Date", 'A harmless header edit must not change the final installment.');
        SalesInvoiceHeader."Due Date" += 1;
        // [WHEN] The posted header's due date is changed.
        asserterror SalesInvHeaderEdit.Run(SalesInvoiceHeader);
        // [THEN] The posted installment condition change is rejected.
        Assert.ExpectedError('Changing posted installment payment conditions is not supported');
    end;

    [Test]
    procedure ImplicitNonPaymentApplicationStillRejectsInstallments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // [FEATURE] [Installments] [Application] [Posting Guard]
        // [SCENARIO] Enabling oldest-first receipts does not enable implicit applications from other document types.
        // [GIVEN] An oldest-first customer with a posted installment invoice.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::Customer, Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -125);

        // [WHEN] A blank-document-type journal line tries to apply implicitly.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The unsupported application is rejected without reducing the invoice balance.
        Assert.ExpectedError('supported only for customer receipts');
        VerifyInvoiceBalance(SalesInvoiceHeader, 125, false);
    end;

    [Test]
    procedure OldestReceiptUsesInstallmentSequenceAndMixedInvoiceDueDates()
    var
        SalesHeader: Record "Sales Header";
        OrdinarySalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OrdinaryInvoice: Record "Sales Invoice Header";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Installments] [Application] [Apply to Oldest]
        // [SCENARIO] Oldest-first receipts respect sequence for equal due dates and due dates across ordinary invoices.
        // [GIVEN] Two installments due on day 30, an ordinary invoice due on day 45, and a final installment due on day 90.
        CreateSettlementInvoice(SalesHeader, '');
        ClearInstallmentDiscounts(SalesHeader."Installment Plan ID");
        PlanLine.Get(SalesHeader."Installment Plan ID", 20000);
        Evaluate(PlanLine."Due Date Calculation", '<30D>');
        PlanLine.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        SalesInvoiceLine.FindFirst();
        LibrarySales.CreateSalesHeader(OrdinarySalesHeader, OrdinarySalesHeader."Document Type"::Invoice, SalesInvoiceHeader."Bill-to Customer No.");
        OrdinarySalesHeader.Validate("Payment Terms Code", '');
        OrdinarySalesHeader.Validate("Prices Including VAT", false);
        OrdinarySalesHeader.Validate("Due Date", WorkDate() + 45);
        OrdinarySalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
            SalesLine, OrdinarySalesHeader, SalesLine.Type::"G/L Account", SalesInvoiceLine."No.", 1);
        SalesLine.Validate("Unit Price", 8);
        SalesLine.Modify(true);
        OrdinaryInvoice.Get(LibrarySales.PostSalesDocument(OrdinarySalesHeader, true, true));
        EnableOldestApplication(SalesInvoiceHeader."Bill-to Customer No.");
        PlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 10000);
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");

        // [WHEN] An implicit receipt covers the first installment.
        PostPaymentWithAppliesToID(CustLedgerEntry, '', 41.67, WorkDate());

        // [THEN] Sequence one closes before the installment with the same due date.
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
        Assert.IsFalse(CustLedgerEntry.Open, 'Equal due dates must be resolved by installment sequence.');
        PlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 20000);
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
        Assert.IsTrue(CustLedgerEntry.Open, 'The second installment must remain open after the first receipt.');

        // [WHEN] Another receipt covers the second installment and the ordinary invoice.
        PostPaymentWithAppliesToID(CustLedgerEntry, '', 51.67, WorkDate());

        // [THEN] The ordinary invoice closes before the final, later-due installment.
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
        Assert.IsFalse(CustLedgerEntry.Open, 'The next installment must be settled first.');
        VerifyInvoiceBalance(OrdinaryInvoice, 0, true);
        VerifyInvoiceBalance(SalesInvoiceHeader, 41.66, false);
        PlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 30000);
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(41.66, CustLedgerEntry."Remaining Amount", 'The later installment must not take precedence over the ordinary invoice.');
    end;

    [Test]
    procedure OldestReceiptLeavesExcessUnappliedAfterAllInstallmentsClose()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentEntry: Record "Cust. Ledger Entry";
        PaymentNo: Code[20];
    begin
        // [FEATURE] [Installments] [Application] [Apply to Oldest]
        // [SCENARIO] Overpayment closes the invoice without inventing another installment.
        // [GIVEN] An oldest-first customer with a 125 invoice and no installment discounts.
        CreateSettlementInvoice(SalesHeader, '');
        ClearInstallmentDiscounts(SalesHeader."Installment Plan ID");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        EnableOldestApplication(SalesInvoiceHeader."Bill-to Customer No.");
        PlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 10000);
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");

        // [WHEN] An implicit receipt pays 140.
        PaymentNo := PostPaymentWithAppliesToID(CustLedgerEntry, '', 140, WorkDate());

        // [THEN] All installments close and 15 remains on the original receipt.
        VerifyInvoiceBalance(SalesInvoiceHeader, 0, true);
        LibraryERM.FindCustomerLedgerEntry(PaymentEntry, PaymentEntry."Document Type"::Payment, PaymentNo);
        PaymentEntry.CalcFields("Remaining Amount");
        Assert.IsTrue(PaymentEntry.Open, 'Excess cash must remain available for native application.');
        Assert.AreEqual(-15, PaymentEntry."Remaining Amount", 'Overpayment must not be absorbed into an installment.');
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        Assert.AreEqual(3, CustLedgerEntry.Count(), 'Overpayment must not create another installment entry.');
    end;

    [Test]
    procedure OldestReceiptDoesNotGrantExpiredInstallmentDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Installments] [Application] [Payment Discount]
        // [SCENARIO] Automatic application cannot grant an expired installment discount.
        // [GIVEN] An oldest-first customer and a first installment whose 0.83 discount has expired.
        CreateSettlementInvoice(SalesHeader, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        EnableOldestApplication(SalesInvoiceHeader."Bill-to Customer No.");
        PlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 10000);
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");

        // [WHEN] A receipt pays the discounted amount after the installment's due date.
        PostPaymentWithAppliesToID(CustLedgerEntry, '', 40.84, WorkDate() + 31);

        // [THEN] The expired discount remains payable and later installments are unchanged.
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.IsTrue(CustLedgerEntry.Open, 'An expired discount must not close the installment.');
        Assert.AreEqual(0.83, CustLedgerEntry."Remaining Amount", 'The unpaid discount amount must remain outstanding.');
        DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Payment Discount");
        Assert.IsTrue(DetailedCustLedgEntry.IsEmpty(), 'No expired payment discount may be posted.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 84.16, false);
    end;

    [Test]
    procedure ForeignCurrencyOldestReceiptGainCanBeUnappliedAndReapplied()
    begin
        // [FEATURE] [Installments] [Application] [Currency]
        // [SCENARIO] A realized gain belongs to the applied installment throughout its application lifecycle.
        // [GIVEN] A foreign-currency invoice at rate 1.
        // [WHEN] An oldest-first receipt at rate 0.5 is applied, unapplied, and reapplied.
        // [THEN] The 41.67 realized gain reverses and reposts without changing the original schedule.
        VerifyForeignCurrencySettlement(0.5, 41.67);
    end;

    [Test]
    procedure ForeignCurrencyOldestReceiptLossCanBeUnappliedAndReapplied()
    begin
        // [FEATURE] [Installments] [Application] [Currency]
        // [SCENARIO] A realized loss belongs to the applied installment throughout its application lifecycle.
        // [GIVEN] A foreign-currency invoice at rate 1.
        // [WHEN] An oldest-first receipt at rate 2 is applied, unapplied, and reapplied.
        // [THEN] The rounded 20.83 realized loss reverses and reposts without changing the original schedule.
        VerifyForeignCurrencySettlement(2, -20.83);
    end;

    [Test]
    procedure InstallmentUnderpaymentWithinToleranceClosesOnlySelectedEntry()
    begin
        // [FEATURE] [Installments] [Application] [Payment Tolerance]
        // [SCENARIO] Accepted native tolerance is evaluated per selected installment.
        // [GIVEN] A 41.67 installment with a 0.50 tolerance cap and an unblocked customer.
        // [WHEN] A selected-entry receipt pays 41.17.
        // [THEN] The 0.50 tolerance closes only that installment.
        VerifyInstallmentUnderpayment(false, 41.17, 0);
    end;

    [Test]
    procedure CustomerToleranceBlockPreservesInstallmentUnderpayment()
    begin
        // [FEATURE] [Installments] [Application] [Payment Tolerance]
        // [SCENARIO] A customer's tolerance block is respected during actual installment settlement.
        // [GIVEN] The same tolerance setup but a customer blocking payment tolerance.
        // [WHEN] A selected-entry receipt pays 41.17 of a 41.67 installment.
        // [THEN] The 0.50 shortfall remains outstanding without tolerance entries.
        VerifyInstallmentUnderpayment(true, 41.17, 0.5);
    end;

    [Test]
    procedure InstallmentUnderpaymentAboveToleranceRemainsOutstanding()
    begin
        // [FEATURE] [Installments] [Application] [Payment Tolerance]
        // [SCENARIO] An invoice-wide tolerance must not override an individual installment's cap.
        // [GIVEN] A 41.67 installment with a 0.50 tolerance cap.
        // [WHEN] A selected-entry receipt leaves a 0.52 shortfall, beyond the cap and native rounding allowance.
        // [THEN] The installment remains open and no tolerance is posted.
        VerifyInstallmentUnderpayment(false, 41.15, 0.52);
    end;

    [Test]
    procedure OldestCustomerCannotApplyDuringInstallmentInvoicePosting()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Installments] [Application] [Posting Guard]
        // [SCENARIO] Later receipt support does not enable automatic application during installment invoice posting.
        // [GIVEN] An unposted installment invoice whose customer uses Apply to Oldest.
        CreateSettlementInvoice(SalesHeader, '');
        EnableOldestApplication(SalesHeader."Bill-to Customer No.");

        // [WHEN] The installment invoice is posted.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The existing customer application-method guard prevents financial posting.
        Assert.ExpectedError('Application Method');
        CustLedgerEntry.SetRange("Installment Plan ID", SalesHeader."Installment Plan ID");
        Assert.IsTrue(CustLedgerEntry.IsEmpty(), 'The unsupported invoice-time application must not post installments.');
    end;

    [Test]
    procedure PaymentServiceEligibilityAndChangesRejectInstallmentInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentServiceSetup: Record "Payment Service Setup";
    begin
        // [SCENARIO] Payment-service changes are unavailable for global installment invoices.
        // [GIVEN] A posted installment invoice.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        // [WHEN] Payment-service eligibility is checked.
        // [THEN] The action is not offered.
        Assert.IsFalse(PaymentServiceSetup.CanChangePaymentService(SalesInvoiceHeader), 'Payment-service actions must not be offered for global plans.');

        // [WHEN] A payment-service change is requested directly.
        asserterror PaymentServiceSetup.ChangePaymentServicePostedInvoice(SalesInvoiceHeader);

        // [THEN] The unsupported change is rejected.
        Assert.ExpectedError('Payment services are not supported for global installment invoices');
    end;

    [Test]
    procedure SalesInstallmentRetainsBigIntegerLedgerEntryNumbers()
    var
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        AppliedCustomerEntries: Page "Applied Customer Entries";
        EntryNo: BigInteger;
        DetailedEntryNo: BigInteger;
    begin
        // [SCENARIO] Recording, grouping and selecting a sales installment preserves an entry number beyond the Integer range.
        // [GIVEN] A customer installment and its initial detailed entry have a large ledger entry number.
        if CustLedgerEntry.FindLast() then
            EntryNo := CustLedgerEntry."Entry No.";
        if EntryNo < 2147483647 then
            EntryNo := 2147483647;
        EntryNo += 1;
        if DetailedCustLedgEntry.FindLast() then
            DetailedEntryNo := DetailedCustLedgEntry."Entry No.";
        DetailedEntryNo += 1;
        PlanLine."Plan ID" := CreateGuid();
        PlanLine."Line No." := 10000;
        PlanLine."Installment No." := 1;
        PlanLine.Amount := 100;
        PlanLine."Amount (LCY)" := 100;
        PlanLine.Insert();
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := EntryNo;
        CustLedgerEntry."Installment Plan ID" := PlanLine."Plan ID";
        CustLedgerEntry."Installment No." := PlanLine."Installment No.";
        CustLedgerEntry."No. of Installments" := 1;
        CustLedgerEntry.Insert();
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := DetailedEntryNo;
        DetailedCustLedgEntry."Cust. Ledger Entry No." := EntryNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry.Amount := PlanLine.Amount;
        DetailedCustLedgEntry."Amount (LCY)" := PlanLine."Amount (LCY)";
        DetailedCustLedgEntry.Insert();

        // [WHEN] The posted installment is recorded and its invoice group is restored.
        InstallmentPosting.RecordPostedLine(PlanLine, CustLedgerEntry, 1);
        CustLedgerEntry."Invoice Entry No." := 0;
        CustLedgerEntry.Modify();
        DetailedCustLedgEntry."Invoice Entry No." := 0;
        DetailedCustLedgEntry.Modify();
        SalesInstallmentHistory.SetInvoiceGroup(PlanLine."Plan ID", EntryNo);
        AppliedCustomerEntries.SetInvoiceEntryNo(EntryNo);

        // [THEN] The plan relation and both ledger group anchors retain the full entry number.
        PlanLine.Get(PlanLine."Plan ID", PlanLine."Line No.");
        PlanLine.TestField("Cust. Ledger Entry No.", EntryNo);
        PlanLine.Validate("Cust. Ledger Entry No.", EntryNo);
        CustLedgerEntry.Get(EntryNo);
        CustLedgerEntry.TestField("Invoice Entry No.", EntryNo);
        DetailedCustLedgEntry.Get(DetailedEntryNo);
        DetailedCustLedgEntry.TestField("Invoice Entry No.", EntryNo);
    end;

    [Test]
    procedure BackfillRestoresExistingInstallmentGroupsWithoutChangingAmounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO] Invoice grouping backfill repairs existing installment links idempotently without changing financial amounts.
        // [GIVEN] A valid posted schedule whose customer and detailed entries have missing invoice grouping anchors.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry."Invoice Entry No." := 0;
            CustLedgerEntry.Modify();
            DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
            DetailedCustLedgEntry.ModifyAll("Invoice Entry No.", 0);
        until CustLedgerEntry.Next() = 0;

        // [WHEN] Invoice grouping backfill is run twice.
        Assert.IsTrue(SalesInstallmentHistory.BackfillInvoiceGroups(), 'Valid posted plans must complete the backfill.');
        Assert.IsTrue(SalesInstallmentHistory.BackfillInvoiceGroups(), 'Repeating a completed backfill must succeed.');

        // [THEN] Every entry shares the correct final anchor and original invoice amounts are unchanged.
        VerifyInvoiceBalance(SalesInvoiceHeader, 125, false);
        CustLedgerEntry.FindSet();
        repeat
            Assert.AreEqual(SalesInvoiceHeader."Cust. Ledger Entry No.", CustLedgerEntry."Invoice Entry No.", 'Existing installments must share the exact final anchor.');
            DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
            DetailedCustLedgEntry.FindFirst();
            Assert.AreEqual(SalesInvoiceHeader."Cust. Ledger Entry No.", DetailedCustLedgEntry."Invoice Entry No.", 'Existing detailed entries must join the same group.');
            CustLedgerEntry.CalcFields("Original Amount");
            Assert.AreEqual(CustLedgerEntry."Original Amount", DetailedCustLedgEntry.Amount, 'Backfill must not change financial amounts.');
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    procedure BackfillReportsMissingPostedInvoiceWithoutFailing()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO] Backfill reports an incomplete plan when its posted invoice is missing rather than raising an error.
        // [GIVEN] A posted installment plan whose invoice header has been deleted.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.Delete();

        // [WHEN] Invoice grouping backfill runs.
        // [THEN] It reports incomplete work without failing.
        Assert.IsFalse(SalesInstallmentHistory.BackfillInvoiceGroups(), 'A missing posted invoice must leave the backfill incomplete.');
    end;

    [Test]
    procedure BackfillReportsMissingLedgerAnchorWithoutFailing()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [SCENARIO] Backfill reports an incomplete plan when its ledger anchor is missing rather than raising an error.
        // [GIVEN] A posted installment invoice whose anchor ledger entry has been deleted.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.");
        CustLedgerEntry.Delete();

        // [WHEN] Invoice grouping backfill runs.
        // [THEN] It reports incomplete work without failing.
        Assert.IsFalse(SalesInstallmentHistory.BackfillInvoiceGroups(), 'A missing ledger anchor must leave the backfill incomplete.');
    end;

    [Test]
    procedure BackfillReportsReplacedPostedInvoiceWithoutFailing()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [SCENARIO] Backfill rejects a posted invoice whose identity no longer matches the original plan.
        // [GIVEN] A posted installment invoice replaced by a header with the same number but a new SystemId.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.Delete();
        Clear(SalesInvoiceHeader.SystemId);
        SalesInvoiceHeader.Insert();

        // [WHEN] Invoice grouping backfill runs.
        // [THEN] The mismatched identity leaves work incomplete without raising an error.
        Assert.IsFalse(SalesInstallmentHistory.BackfillInvoiceGroups(), 'A replaced posted invoice must leave the backfill incomplete.');
    end;

    [Test]
    procedure BackfillReportsMismatchedAnchorAndContinuesWithValidPlans()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OtherSalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [SCENARIO] Backfill skips an invalid invoice anchor but continues repairing other valid plans.
        // [GIVEN] One invoice points to another plan's anchor and that valid second plan has missing grouping links.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        OtherSalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader."Cust. Ledger Entry No." := OtherSalesInvoiceHeader."Cust. Ledger Entry No.";
        SalesInvoiceHeader.Modify();
        CustLedgerEntry.SetRange("Installment Plan ID", OtherSalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry."Invoice Entry No." := 0;
            CustLedgerEntry.Modify();
            DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
            DetailedCustLedgEntry.ModifyAll("Invoice Entry No.", 0);
        until CustLedgerEntry.Next() = 0;

        // [WHEN] Invoice grouping backfill processes both plans.
        Assert.IsFalse(SalesInstallmentHistory.BackfillInvoiceGroups(), 'A mismatched anchor must leave the backfill incomplete.');

        // [THEN] The overall result is incomplete but the valid invoice's grouped balance is restored.
        VerifyInvoiceBalance(OtherSalesInvoiceHeader, 125, false);
    end;

    [Test]
    procedure LateJournalPostingRejectsAnInstallmentTargetBeforeChangingTheJournal()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PostLateGenJournalLines: Codeunit "Post Late Gen. Journal Lines";
    begin
        // [SCENARIO] Late journal posting rejects installment invoices before modifying application fields.
        // [GIVEN] A receipt journal line referring to a posted installment invoice's preassigned number.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader."Your Reference" := 'LATE';
        SalesInvoiceHeader.Modify(true);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, SalesInvoiceHeader."Bill-to Customer No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -125);
        GenJournalLine.Description := SalesInvoiceHeader."Pre-Assigned No.";
        GenJournalLine.Modify(true);
        Commit();

        // [WHEN] Late journal posting tries to resolve and apply the receipt.
        asserterror PostLateGenJournalLines.Run();

        // [THEN] Posting is rejected with journal application fields and invoice balance unchanged.
        Assert.ExpectedError('Late journal posting is not supported for global installment invoices');
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        Assert.AreEqual('', GenJournalLine."Applies-to Doc. No.", 'The guard must run before setting journal application fields.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 125, false);
    end;

    [Test]
    procedure CorrectiveCreditCopyPostsOneCreditAcrossAllInstallments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectionHeader: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        CreditEntry: Record "Cust. Ledger Entry";
        CreditNo: Code[20];
    begin
        // [SCENARIO] A native full corrective credit remains one ordinary credit while settling all invoice installments.
        // [GIVEN] An unpaid posted installment invoice and its native corrective credit copy without plan ownership.
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        Assert.IsTrue(
            CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, CorrectionHeader),
            'An unpaid installment invoice must support a native corrective credit copy.');
        Assert.IsTrue(IsNullGuid(CorrectionHeader."Installment Plan ID"), 'A credit memo must not own or borrow an installment schedule.');
        // [WHEN] The corrective credit is posted.
        CreditNo := LibrarySales.PostSalesDocument(CorrectionHeader, true, true);

        // [THEN] One native credit closes against all original obligations and the logical invoice is fully settled.
        LibraryERM.FindCustomerLedgerEntry(CreditEntry, CreditEntry."Document Type"::"Credit Memo", CreditNo);
        Assert.IsTrue(IsNullGuid(CreditEntry."Installment Plan ID"), 'The credit must remain one native customer entry.');
        Assert.IsFalse(CreditEntry.Open, 'The full credit must close against all original installments.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 0, true);
    end;

    local procedure CreateSettlementInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, CurrencyCode);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Validate("Block Payment Tolerance", true);
        Customer.Modify(true);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Modify(true);
    end;

    local procedure PostPaymentWithAppliesToID(CustLedgerEntry: Record "Cust. Ledger Entry"; ApplicationID: Code[50]; Amount: Decimal; PostingDate: Date): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
    begin
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        if CustLedgerEntry."Currency Code" <> '' then
            GenJournalLine.Validate("Currency Code", CustLedgerEntry."Currency Code");
        GenJournalLine.Validate("Applies-to ID", ApplicationID);
        if ApplicationID <> '' then
            PaymentToleranceMgt.PmtTolGenJnl(GenJournalLine);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure ClearInstallmentDiscounts(PlanID: Guid)
    var
        PlanLine: Record "Sales Installment Plan Line";
    begin
        PlanLine.SetRange("Plan ID", PlanID);
        PlanLine.FindSet(true);
        repeat
            PlanLine."Discount %" := 0;
            Clear(PlanLine."Discount Date Calculation");
            PlanLine.Modify(true);
        until PlanLine.Next() = 0;
    end;

    local procedure EnableOldestApplication(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
    end;

    local procedure SelectInstallment(var CustLedgerEntry: Record "Cust. Ledger Entry"; PlanID: Guid; Sequence: Integer) ApplicationID: Code[50]
    begin
        CustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        CustLedgerEntry.SetRange("Installment No.", Sequence);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        ApplicationID := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Applies-to ID" := ApplicationID;
        CustLedgerEntry."Amount to Apply" := CustLedgerEntry."Remaining Amount";
        CustLedgerEntry.Modify(true);
    end;

    local procedure FilterLastApplicationDetails(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.Get(CustEntryApplyPostedEntries.FindLastApplEntry(CustLedgerEntry."Entry No."));
        DetailedCustLedgEntry.TestField("Transaction No.");
        DetailedCustLedgEntry.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.SetRange("Transaction No.", DetailedCustLedgEntry."Transaction No.");
    end;

    local procedure VerifyForeignCurrencySettlement(PaymentExchangeRate: Decimal; ExpectedAdjustment: Decimal)
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OriginalPlanLine: Record "Sales Installment Plan Line";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GLEntry: Record "G/L Entry";
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        PaymentNo: Code[20];
        ApplicationID: Code[50];
    begin
        CreateSettlementInvoice(SalesHeader, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));
        ClearInstallmentDiscounts(SalesHeader."Installment Plan ID");
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        OriginalPlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 10000);
        CustLedgerEntry.Get(OriginalPlanLine."Cust. Ledger Entry No.");
        EnableOldestApplication(SalesInvoiceHeader."Bill-to Customer No.");
        LibraryERM.CreateExchangeRate(SalesInvoiceHeader."Currency Code", WorkDate() + 1, PaymentExchangeRate, 1);

        PaymentNo := PostPaymentWithAppliesToID(CustLedgerEntry, '', OriginalPlanLine.Amount, WorkDate() + 1);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        Assert.IsFalse(CustLedgerEntry.Open, 'The foreign-currency receipt must close the oldest installment.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 83.33, false);
        FilterLastApplicationDetails(DetailedCustLedgEntry, CustLedgerEntry);
        DetailedCustLedgEntry.SetFilter("Entry Type", '%1|%2',
            DetailedCustLedgEntry."Entry Type"::"Realized Gain", DetailedCustLedgEntry."Entry Type"::"Realized Loss");
        DetailedCustLedgEntry.CalcSums("Amount (LCY)");
        Assert.AreEqual(ExpectedAdjustment, DetailedCustLedgEntry."Amount (LCY)", 'Currency effects must use the selected installment, not the invoice total.');
        Currency.Get(SalesInvoiceHeader."Currency Code");
        GLEntry.SetRange("G/L Account No.", Currency."Realized Gains Acc.");
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(-ExpectedAdjustment, GLEntry.Amount, 'Realized currency G/L postings must reconcile.');
        LibraryERM.FindCustomerLedgerEntry(PaymentEntry, PaymentEntry."Document Type"::Payment, PaymentNo);
        DetailedCustLedgEntry.Reset();
        DetailedCustLedgEntry.Get(CustEntryApplyPostedEntries.FindLastApplEntry(PaymentEntry."Entry No."));
        ApplyUnapplyParameters."Document No." := PaymentNo;
        ApplyUnapplyParameters."Posting Date" := WorkDate() + 1;

        CustEntryApplyPostedEntries.PostUnApplyCustomerCommit(DetailedCustLedgEntry, ApplyUnapplyParameters, false);

        CustLedgerEntry.Get(OriginalPlanLine."Cust. Ledger Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(OriginalPlanLine.Amount, CustLedgerEntry."Remaining Amount", 'Unapplication must restore the installment in document currency.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 125, false);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, 'Unapplication must reverse the realized currency posting.');
        ApplicationID := SelectInstallment(CustLedgerEntry, OriginalPlanLine."Plan ID", 1);
        PaymentEntry.Get(PaymentEntry."Entry No.");
        PaymentEntry.CalcFields("Remaining Amount");
        PaymentEntry.Validate("Applying Entry", true);
        PaymentEntry.Validate("Applies-to ID", ApplicationID);
        PaymentEntry.Validate("Amount to Apply", PaymentEntry."Remaining Amount");
        PaymentEntry.Modify(true);
        Assert.IsTrue(CustEntryApplyPostedEntries.Apply(PaymentEntry, ApplyUnapplyParameters), 'The original foreign-currency receipt must be reapplied.');

        VerifyInvoiceBalance(SalesInvoiceHeader, 83.33, false);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(-ExpectedAdjustment, GLEntry.Amount, 'Reapplication must restore the native realized currency posting.');
        PlanLine.Get(OriginalPlanLine."Plan ID", OriginalPlanLine."Line No.");
        Assert.AreEqual(OriginalPlanLine.SystemId, PlanLine.SystemId, 'The original schedule identity must survive the currency lifecycle.');
        Assert.AreEqual(OriginalPlanLine.Amount, PlanLine.Amount, 'Original document-currency allocations must remain immutable.');
        Assert.AreEqual(OriginalPlanLine."Amount (LCY)", PlanLine."Amount (LCY)", 'Original LCY allocations must remain immutable.');
        Assert.AreEqual(OriginalPlanLine."Cust. Ledger Entry No.", PlanLine."Cust. Ledger Entry No.", 'Reapplication must use the original ledger link.');
    end;

    local procedure VerifyInstallmentUnderpayment(BlockTolerance: Boolean; ReceiptAmount: Decimal; ExpectedRemaining: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        GLSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationID: Code[50];
    begin
        CreateSettlementInvoice(SalesHeader, '');
        ClearInstallmentDiscounts(SalesHeader."Installment Plan ID");
        GLSetup.Get();
        GLSetup."Payment Tolerance %" := 2;
        GLSetup."Max. Payment Tolerance Amount" := 0.5;
        GLSetup."Payment Tolerance Warning" := false;
        GLSetup."Pmt. Disc. Tolerance Warning" := false;
        GLSetup."Payment Tolerance Posting" := GLSetup."Payment Tolerance Posting"::"Payment Tolerance Accounts";
        GLSetup.Modify(true);
        Customer.Get(SalesHeader."Bill-to Customer No.");
        Customer.Validate("Block Payment Tolerance", BlockTolerance);
        Customer.Modify(true);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        ApplicationID := SelectInstallment(CustLedgerEntry, SalesInvoiceHeader."Installment Plan ID", 1);

        PostPaymentWithAppliesToID(CustLedgerEntry, ApplicationID, ReceiptAmount, WorkDate());

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(ExpectedRemaining, CustLedgerEntry."Remaining Amount", 'The selected installment must honor its own tolerance and customer block.');
        Assert.AreEqual(ExpectedRemaining <> 0, CustLedgerEntry.Open, 'Only accepted native tolerance can close the shortfall.');
        FilterLastApplicationDetails(DetailedCustLedgEntry, CustLedgerEntry);
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Payment Tolerance");
        DetailedCustLedgEntry.CalcSums(Amount);
        if ExpectedRemaining = 0 then
            Assert.AreEqual(-0.5, DetailedCustLedgEntry.Amount, 'The accepted installment shortfall must post once as native tolerance.')
        else
            Assert.AreEqual(0, DetailedCustLedgEntry.Amount, 'Blocked or excessive shortfalls must not post tolerance.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 83.33 + ExpectedRemaining, false);
    end;

    local procedure VerifyInvoiceBalance(SalesInvoiceHeader: Record "Sales Invoice Header"; ExpectedRemaining: Decimal; ExpectedClosed: Boolean)
    var
        FilteredInvoice: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        SalesInvoiceHeader.CalcFields(Closed, "Remaining Amount");
        Assert.AreEqual(ExpectedRemaining, SalesInvoiceHeader."Remaining Amount", 'The invoice FlowField must include every installment.');
        Assert.AreEqual(ExpectedRemaining, SalesInvoiceHeader.GetRemainingAmount(), 'Existing API/report helpers must agree with the FlowField.');
        Assert.AreEqual(ExpectedClosed, SalesInvoiceHeader.Closed, 'Closure must reflect the complete invoice.');
        FilteredInvoice.SetRange("No.", SalesInvoiceHeader."No.");
        FilteredInvoice.SetRange(Closed, ExpectedClosed);
        Assert.IsFalse(FilteredInvoice.IsEmpty(), 'The existing Open/Paid filter must include the correct invoice.');
        FilteredInvoice.SetRange(Closed, not ExpectedClosed);
        Assert.IsTrue(FilteredInvoice.IsEmpty(), 'The opposite Open/Paid filter must not include the invoice.');
    end;

    local procedure PreparePostingAttempt(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Ship := true;
        SalesHeader.Invoice := true;
        SalesHeader."Posting No." := LibraryUtility.GenerateGUID();
        SalesHeader.Modify(true);
    end;

    local procedure VerifyPostedSchedule(SalesInvoiceHeader: Record "Sales Invoice Header"; PlanID: Guid)
    var
        Plan: Record "Sales Installment Plan";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        Plan.Get(PlanID);
        Assert.AreEqual(Plan.Status::Posted, Plan.Status, 'Posting must transition the owned snapshot.');
        Assert.AreEqual(PlanID, SalesInvoiceHeader."Installment Plan ID", 'The posted invoice must retain the same plan ID.');
        Assert.AreEqual(SalesInvoiceHeader.SystemId, Plan."Posted Invoice SystemId", 'Posted ownership must use SystemId.');
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Assert.AreEqual(SalesInvoiceHeader."Amount Including VAT", Plan.Amount, 'The final schedule must reconcile to the posted invoice.');
        PlanLine.SetCurrentKey("Plan ID", "Installment No.");
        PlanLine.SetRange("Plan ID", PlanID);
        Assert.AreEqual(3, PlanLine.Count(), 'Posting must retain all snapshot rules.');
        CustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        Assert.AreEqual(3, CustLedgerEntry.Count(), 'There must be one real receivable per installment.');
        PlanLine.FindSet();
        repeat
            CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
            CustLedgerEntry.CalcFields("Original Amount", "Original Amt. (LCY)");
            Assert.AreEqual(PlanLine.Amount, CustLedgerEntry."Original Amount", 'Document amounts must match the linked ledger.');
            Assert.AreEqual(PlanLine."Amount (LCY)", CustLedgerEntry."Original Amt. (LCY)", 'LCY amounts must match independently.');
            Assert.AreEqual(PlanLine."Due Date", CustLedgerEntry."Due Date", 'Each receivable must have its own due date.');
            Assert.AreEqual(PlanLine."Pmt. Discount Date", CustLedgerEntry."Pmt. Discount Date", 'Discount dates must be installment-specific.');
            Assert.AreEqual(PlanLine."Original Pmt. Disc. Possible", CustLedgerEntry."Original Pmt. Disc. Possible", 'Discounts must be calculated per entry.');
            Assert.AreEqual(PlanLine."Installment No.", CustLedgerEntry."Installment No.", 'Ledger sequence must match the schedule.');
            Assert.AreEqual(3, CustLedgerEntry."No. of Installments", 'The ledger must retain the installment count.');
            Assert.AreEqual(PlanID, CustLedgerEntry."Installment Plan ID", 'Every linked entry must belong to this plan.');
            Assert.AreEqual(SalesInvoiceHeader."Bill-to Customer No.", CustLedgerEntry."Customer No.", 'The bill-to customer must be preserved.');
            Assert.AreEqual(SalesInvoiceHeader."No.", CustLedgerEntry."Document No.", 'The invoice number must be preserved.');
            Assert.AreEqual(SalesInvoiceHeader."External Document No.", CustLedgerEntry."External Document No.", 'External matching metadata must be preserved.');
            Assert.AreEqual(SalesInvoiceHeader."Currency Code", CustLedgerEntry."Currency Code", 'The invoice currency must be preserved.');
            Assert.AreEqual(SalesInvoiceHeader."Dimension Set ID", CustLedgerEntry."Dimension Set ID", 'Header dimensions must be preserved on every receivable.');
            Assert.IsTrue(CustLedgerEntry.Open and CustLedgerEntry.Positive, 'Each installment must start as an open positive obligation.');
            DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
            DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Initial Entry");
            Assert.AreEqual(1, DetailedCustLedgEntry.Count(), 'There must be one initial detailed entry per installment.');
            DetailedCustLedgEntry.FindFirst();
            Assert.AreEqual(PlanLine."Due Date", DetailedCustLedgEntry."Initial Entry Due Date", 'Detailed due dates must not repeat the header summary.');
        until PlanLine.Next() = 0;
        PlanLine.FindLast();
        Assert.AreEqual(PlanLine."Cust. Ledger Entry No.", SalesInvoiceHeader."Cust. Ledger Entry No.", 'The legacy anchor must be the final plan sequence.');
        PlanLine.CalcSums(Amount, "Amount (LCY)");
        Assert.AreEqual(Plan.Amount, PlanLine.Amount, 'Persisted document allocations must reconcile.');
        Assert.AreEqual(Plan."Amount (LCY)", PlanLine."Amount (LCY)", 'Persisted LCY allocations must reconcile.');
        VerifyInvoiceBalance(SalesInvoiceHeader, Plan.Amount, false);
    end;

    local procedure VerifyDraftAfterRollback(PlanID: Guid; PostingNo: Code[20])
    var
        Plan: Record "Sales Installment Plan";
        PlanLine: Record "Sales Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
    begin
        Plan.Get(PlanID);
        Assert.AreEqual(Plan.Status::Draft, Plan.Status, 'Failure or preview must leave the owned snapshot in Draft.');
        Assert.IsTrue(IsNullGuid(Plan."Posted Invoice SystemId"), 'Posted ownership must roll back.');
        PlanLine.SetRange("Plan ID", PlanID);
        PlanLine.SetFilter("Cust. Ledger Entry No.", '<>0');
        Assert.IsTrue(PlanLine.IsEmpty(), 'No partial installment links may remain.');
        PlanLine.SetRange("Cust. Ledger Entry No.");
        PlanLine.SetFilter(Amount, '<>0');
        Assert.IsTrue(PlanLine.IsEmpty(), 'No calculated posting amounts may remain in the draft.');
        CustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        Assert.IsTrue(CustLedgerEntry.IsEmpty(), 'Every installment ledger entry must roll back.');
        DetailedCustLedgEntry.SetRange("Document No.", PostingNo);
        Assert.IsTrue(DetailedCustLedgEntry.IsEmpty(), 'Detailed entries must roll back.');
        SalesInvoiceHeader.SetRange("Installment Plan ID", PlanID);
        Assert.IsTrue(SalesInvoiceHeader.IsEmpty(), 'The posted invoice must roll back.');
        GLEntry.SetRange("Document No.", PostingNo);
        Assert.IsTrue(GLEntry.IsEmpty(), 'Revenue, VAT, and control-account postings must roll back together.');
    end;

    procedure SetFailureSequence(Sequence: Integer)
    begin
        FailureSequence := Sequence;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterCustLedgEntryInsert', '', false, false)]
    local procedure FailAfterInstallment(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        if (FailureSequence <> 0) and not IsNullGuid(CustLedgerEntry."Installment Plan ID") then
            if CustLedgerEntry."Installment No." = FailureSequence then
                Error(ForcedFailureErr);
    end;
}
