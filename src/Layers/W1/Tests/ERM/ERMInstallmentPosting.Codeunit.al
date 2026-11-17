// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Bank.Setup;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
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
    procedure PostingSplitsOnlyReceivablesAndPreservesDiscountedInvoiceTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        TempPreviewLine: Record "Installment Plan Line" temporary;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        DimensionValue: Record "Dimension Value";
        DiscountByType: Codeunit "Sales - Calc Discount By Type";
        LibraryDimension: Codeunit "Library - Dimension";
        SalesInstallmentMgt: Codeunit "Sales Installment Mgt.";
    begin
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

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

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
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CurrencyFactor: Decimal;
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 0.3, 0.3));
        SalesLine.Validate("Unit Price", 100.03);
        SalesLine.Modify(true);
        Plan.Get(SalesHeader."Installment Plan ID");
        CurrencyFactor := SalesHeader."Currency Factor";

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

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
        PlanLine: Record "Installment Plan Line";
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
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
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

        InstallmentPosting.CalculatePostingLines(GenJournalLine, TempPlanLine);

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
        TempPlanLine: Record "Installment Plan Line" temporary;
    begin
        LibraryInstallments.Initialize();
        LibraryInstallments.CreateTemporaryRules(TempPlanLine);
        GenJournalLine."Document Date" := WorkDate();
        GenJournalLine."Posting Date" := WorkDate();
        GenJournalLine.Amount := 100;
        GenJournalLine."Amount (LCY)" := 0.01;

        InstallmentPosting.CalculatePostingLines(GenJournalLine, TempPlanLine);

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
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PreparePostingAttempt(SalesHeader);
        PlanID := SalesHeader."Installment Plan ID";
        PostingNo := SalesHeader."Posting No.";
        Commit();
        PostingObserver.SetFailureSequence(2);
        BindSubscription(PostingObserver);
        SalesPost.SetSuppressCommit(true);

        asserterror SalesPost.Run(SalesHeader);

        Assert.ExpectedError(ForcedFailureErr);
        UnbindSubscription(PostingObserver);
        VerifyDraftAfterRollback(PlanID, PostingNo);

        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        Clear(SalesPost);
        SalesPost.SetSuppressCommit(true);
        SalesPost.Run(SalesHeader);

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
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PreparePostingAttempt(SalesHeader);
        PlanID := SalesHeader."Installment Plan ID";
        PostingNo := SalesHeader."Posting No.";
        Commit();
        SalesPost.SetPreviewMode(true);

        asserterror SalesPost.Run(SalesHeader);

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

        SalesPost.Run(SalesHeader);

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
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        PlanID: Guid;
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        PlanID := SalesHeader."Installment Plan ID";
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        Commit();

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
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        SourcePlanID: Guid;
        PostedNo: Code[20];
    begin
        LibraryInstallments.CreateInvoice(SourceHeader, SalesLine, '');
        SourcePlanID := SourceHeader."Installment Plan ID";
        Rule.Get(SourceHeader."Payment Terms Code", 10000);
        PostedNo := LibrarySales.PostSalesDocument(SourceHeader, true, true);
        Rule."Payment %" := 20;
        Rule.Modify();
        LibraryInstallments.CreateInvoice(TargetHeader, SalesLine, '');
        CopyDocumentMgt.SetProperties(true, false, false, false, true, false, false);

        CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::"Posted Invoice", PostedNo, TargetHeader);

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
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := SalesHeader."Bill-to Customer No.";
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Invoice;
        GenJournalLine."Payment Terms Code" := SalesHeader."Payment Terms Code";
        GenJournalLine.Amount := 100;

        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine);

        Assert.ExpectedError('full standalone sales invoices only');
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::"G/L Account";
        GenJournalLine."Account No." := SalesLine."No.";
        GenJournalLine."Bal. Account Type" := GenJournalLine."Bal. Account Type"::Customer;
        GenJournalLine."Bal. Account No." := SalesHeader."Bill-to Customer No.";

        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine);

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
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        CustomerNo := SalesHeader."Bill-to Customer No.";
        PostedNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := CustomerNo;
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::Payment;
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine."Applies-to Doc. No." := PostedNo;

        asserterror GenJnlPostLine.RunWithCheck(GenJournalLine);

        Assert.ExpectedError('Select individual installment entries using Applies-to ID');
    end;

    [Test]
    procedure ManualPaymentUsingAppliesToIDClosesOnlyTheSelectedInstallment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        OtherCustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        PlanID: Guid;
        ApplicationID: Code[50];
    begin
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
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, CustLedgerEntry."Customer No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -CustLedgerEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to ID", ApplicationID);
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        Assert.IsFalse(CustLedgerEntry.Open, 'Only the explicitly selected installment must be paid.');
        OtherCustLedgerEntry.SetRange("Installment Plan ID", PlanID);
        OtherCustLedgerEntry.SetRange(Open, true);
        Assert.AreEqual(2, OtherCustLedgerEntry.Count(), 'The other installments must remain open.');
    end;

    [Test]
    procedure InvoiceBalancesFiltersAndAPIStatusFollowEveryInstallment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Aggregate: Record "Sales Invoice Entity Aggregate";
        PlanLine: Record "Installment Plan Line";
        APIMockEvents: Codeunit "API Mock Events";
        PlanID: Guid;
        SourceID: Guid;
    begin
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
        LibraryInstallments.PayInstallment(PlanID, 1, 41.67);
        VerifyInvoiceBalance(SalesInvoiceHeader, 83.33, false);
        LibraryInstallments.PayInstallment(PlanID, 3, 41.66);
        VerifyInvoiceBalance(SalesInvoiceHeader, 41.67, false);
        Aggregate.Get(SalesInvoiceHeader."No.", true);
        Assert.AreEqual(SourceID, Aggregate.Id, 'The API identity must remain the original draft identity.');
        Assert.AreEqual(Aggregate.Status::Open, Aggregate.Status, 'Paying the anchor must not mark the invoice paid.');
        LibraryInstallments.PayInstallment(PlanID, 2, 10);
        VerifyInvoiceBalance(SalesInvoiceHeader, 31.67, false);
        LibraryInstallments.PayInstallment(PlanID, 2, 31.67);
        VerifyInvoiceBalance(SalesInvoiceHeader, 0, true);
        Aggregate.Get(SalesInvoiceHeader."No.", true);
        Assert.AreEqual(Aggregate.Status::Paid, Aggregate.Status, 'A non-anchor settlement must refresh API status.');
        UnbindSubscription(APIMockEvents);
    end;

    [Test]
    procedure CustomerEntryEditsPreserveInvoiceSummaryAndRejectConditionChanges()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        CustEntryEdit: Codeunit "Cust. Entry-Edit";
        SummaryDueDate: Date;
        EntryDueDate: Date;
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SummaryDueDate := SalesInvoiceHeader."Due Date";
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.SetRange("Installment No.", 2);
        CustLedgerEntry.FindFirst();
        EntryDueDate := CustLedgerEntry."Due Date";
        CustLedgerEntry."On Hold" := 'X';
        CustLedgerEntry."Applies-to ID" := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Amount to Apply" := 10;

        CustEntryEdit.Run(CustLedgerEntry);

        SalesInvoiceHeader.Get(SalesInvoiceHeader."No.");
        Assert.AreEqual(SummaryDueDate, SalesInvoiceHeader."Due Date", 'Entry edits must not replace the invoice summary date.');
        CustLedgerEntry."Due Date" := EntryDueDate + 1;
        asserterror CustEntryEdit.Run(CustLedgerEntry);
        Assert.ExpectedError('Changing posted installment payment conditions is not supported');
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.FindFirst();
        Assert.AreEqual(EntryDueDate, DetailedCustLedgEntry."Initial Entry Due Date", 'The edit must fail before changing detailed entries.');
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        asserterror CustLedgerEntry.Validate("Due Date", EntryDueDate + 1);
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
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.");
        AnchorDueDate := CustLedgerEntry."Due Date";
        SalesInvoiceHeader."Posting Description" := LibraryUtility.GenerateGUID();

        SalesInvHeaderEdit.Run(SalesInvoiceHeader);

        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        Assert.AreEqual(AnchorDueDate, CustLedgerEntry."Due Date", 'A harmless header edit must not change the final installment.');
        SalesInvoiceHeader."Due Date" += 1;
        asserterror SalesInvHeaderEdit.Run(SalesInvoiceHeader);
        Assert.ExpectedError('Changing posted installment payment conditions is not supported');
    end;

    [Test]
    procedure ImplicitOldestApplicationRejectsInstallments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        Customer.Get(SalesInvoiceHeader."Bill-to Customer No.");
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Customer, Customer."No.",
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), -125);

        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        Assert.ExpectedError('Automatic Apply to Oldest is not supported');
        VerifyInvoiceBalance(SalesInvoiceHeader, 125, false);
    end;

    [Test]
    procedure PaymentServiceEligibilityAndChangesRejectInstallmentInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentServiceSetup: Record "Payment Service Setup";
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        Assert.IsFalse(PaymentServiceSetup.CanChangePaymentService(SalesInvoiceHeader), 'Payment-service actions must not be offered for global plans.');

        asserterror PaymentServiceSetup.ChangePaymentServicePostedInvoice(SalesInvoiceHeader);

        Assert.ExpectedError('Payment services are not supported for global installment invoices');
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

        Assert.IsTrue(SalesInstallmentHistory.BackfillInvoiceGroups(), 'Valid posted plans must complete the backfill.');
        Assert.IsTrue(SalesInstallmentHistory.BackfillInvoiceGroups(), 'Repeating a completed backfill must succeed.');

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
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.Delete();

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
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgerEntry.Get(SalesInvoiceHeader."Cust. Ledger Entry No.");
        CustLedgerEntry.Delete();

        Assert.IsFalse(SalesInstallmentHistory.BackfillInvoiceGroups(), 'A missing ledger anchor must leave the backfill incomplete.');
    end;

    [Test]
    procedure BackfillReportsReplacedPostedInvoiceWithoutFailing()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.Delete();
        Clear(SalesInvoiceHeader.SystemId);
        SalesInvoiceHeader.Insert();

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

        Assert.IsFalse(SalesInstallmentHistory.BackfillInvoiceGroups(), 'A mismatched anchor must leave the backfill incomplete.');

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

        asserterror PostLateGenJournalLines.Run();

        Assert.ExpectedError('Late journal posting is not supported for global installment invoices');
        GenJournalLine.Find();
        Assert.AreEqual('', GenJournalLine."Applies-to Doc. No.", 'The guard must run before setting journal application fields.');
        VerifyInvoiceBalance(SalesInvoiceHeader, 125, false);
    end;

    [Test]
    procedure CorrectiveCopyAndNotificationRejectInstallmentInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectionHeader: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        InvoiceNotification: Notification;
        UnsupportedCorrectionErr: Label 'Automatic correction, cancellation, and reversal of installment invoices are not supported.', Locked = true;
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        asserterror CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, CorrectionHeader);

        Assert.ExpectedError(UnsupportedCorrectionErr);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 3, 10);
        InvoiceNotification.Id := CreateGuid();
        InvoiceNotification.SetData(SalesInvoiceHeader.FieldName("No."), SalesInvoiceHeader."No.");

        asserterror CorrectPostedSalesInvoice.CreateCorrectiveCreditMemo(InvoiceNotification);

        Assert.ExpectedError(UnsupportedCorrectionErr);
        VerifyInvoiceBalance(SalesInvoiceHeader, 115, false);
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
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
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
        Plan: Record "Installment Plan";
        PlanLine: Record "Installment Plan Line";
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
