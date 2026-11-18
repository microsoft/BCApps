// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

codeunit 134496 "ERM Installment Correction"
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
        FailApplication: Boolean;
        FailTracking: Boolean;
        FailurePlanID: Guid;
        ForcedFailureErr: Label 'Forced installment correction failure.', Locked = true;

    [Test]
    procedure CancelUnpaidInvoiceClosesEveryInstallmentAndReversesAccountingOnce()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, false);

        Assert.IsTrue(CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader), 'Native cancellation must succeed.');

        Assert.IsTrue(
            CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No."),
            'Cancellation must retain the native invoice-to-credit relationship.');
        SalesCrMemoHeader.Get(CancelledDocument."Cancelled By Doc. No.");
        Assert.AreEqual(SalesInvoiceHeader."No.", SalesCrMemoHeader."Applies-to Doc. No.", 'The posted credit must retain the original document link.');
        VerifyClosedInvoice(SalesInvoiceHeader, SalesCrMemoHeader."No.");
        VerifyReversedAccounting(SalesInvoiceHeader, SalesCrMemoHeader."No.", SalesLine."No.");
    end;

    [Test]
    procedure CorrectUnpaidInvoiceCreatesIndependentReplacementSchedule()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReplacementInvoice: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        ReplacementHeader: Record "Sales Header";
        Plan: Record "Sales Installment Plan";
        OriginalPlanLine: Record "Sales Installment Plan Line";
        ReplacementPlanLine: Record "Sales Installment Plan Line";
        Rule: Record "Payment Term Installment";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, true);
        Rule.Get(SalesInvoiceHeader."Payment Terms Code", 10000);
        Evaluate(Rule."Due Date Calculation", '<90D>');
        Rule.Modify(true);
        Commit();

        CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, ReplacementHeader);

        Assert.AreNotEqual(SalesInvoiceHeader."Installment Plan ID", ReplacementHeader."Installment Plan ID", 'A replacement must own a new schedule.');
        Plan.Get(ReplacementHeader."Installment Plan ID");
        Assert.AreEqual(Plan.Status::Draft, Plan.Status, 'The replacement schedule must start as a draft.');
        Assert.AreEqual(ReplacementHeader.SystemId, Plan."Source SystemId", 'The replacement must own its draft.');
        OriginalPlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 10000);
        ReplacementPlanLine.Get(Plan.ID, 10000);
        Assert.AreEqual(
            OriginalPlanLine."Due Date Calculation", ReplacementPlanLine."Due Date Calculation",
            'Correction must copy the frozen rules, not changed reusable terms.');
        Assert.AreEqual(0, ReplacementPlanLine."Discount %", 'Replacement terms must retain the original snapshot.');
        ReplacementInvoice.Get(LibrarySales.PostSalesDocument(ReplacementHeader, true, true));

        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 1, 0);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 2, 0);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 0);
        VerifyRemaining(ReplacementInvoice."Installment Plan ID", 1, 41.67);
        VerifyRemaining(ReplacementInvoice."Installment Plan ID", 2, 41.67);
        VerifyRemaining(ReplacementInvoice."Installment Plan ID", 3, 41.66);
        ReplacementPlanLine.Get(Plan.ID, 10000);
        Assert.AreNotEqual(
            OriginalPlanLine."Cust. Ledger Entry No.", ReplacementPlanLine."Cust. Ledger Entry No.",
            'Replacement receivables must not reuse settled original entries.');
    end;

    [Test]
    procedure PartlyPaidCreditRequiresSelectionAndUnapplyPreservesPaymentsAndDiscountTerms()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CreditHeader: Record "Sales Header";
        InvoiceEntry: Record "Cust. Ledger Entry";
        CreditEntry: Record "Cust. Ledger Entry";
        DetailedEntry: Record "Detailed Cust. Ledg. Entry";
        Parameters: Record "Apply Unapply Parameters";
        PlanLine: Record "Sales Installment Plan Line";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
        OriginalDiscount: Decimal;
        CreditNo: Code[20];
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, false);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 3, 10);
        CreateCreditCopy(SalesInvoiceHeader, CreditHeader);
        Assert.AreEqual('', CreditHeader."Applies-to Doc. No.", 'A partly paid credit must not select an arbitrary installment.');
        Assert.AreEqual('', CreditHeader."Applies-to ID", 'The user must select the open entries explicitly.');
        SetCreditAmount(CreditHeader, 16);
        SelectInstallment(CreditHeader, SalesInvoiceHeader."Installment Plan ID", 2, 20);
        GetInstallment(InvoiceEntry, SalesInvoiceHeader."Installment Plan ID", 2);
        OriginalDiscount := InvoiceEntry."Remaining Pmt. Disc. Possible";

        CreditNo := LibrarySales.PostSalesDocument(CreditHeader, true, true);

        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 1, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 2, 21.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 31.66);
        LibraryERM.FindCustomerLedgerEntry(CreditEntry, CreditEntry."Document Type"::"Credit Memo", CreditNo);
        DetailedEntry.SetRange("Document No.", CreditNo);
        DetailedEntry.SetRange("Entry Type", DetailedEntry."Entry Type"::"Payment Discount");
        Assert.IsTrue(DetailedEntry.IsEmpty(), 'A credit is not a cash receipt and must not realize a payment discount.');
        DetailedEntry.Reset();
        DetailedEntry.Get(CustEntryApplyPostedEntries.FindLastApplEntry(CreditEntry."Entry No."));
        Parameters."Document No." := CreditNo;
        Parameters."Posting Date" := WorkDate();

        CustEntryApplyPostedEntries.PostUnApplyCustomerCommit(DetailedEntry, Parameters, false);

        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 1, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 2, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 31.66);
        GetInstallment(InvoiceEntry, SalesInvoiceHeader."Installment Plan ID", 2);
        Assert.AreEqual(OriginalDiscount, InvoiceEntry."Remaining Pmt. Disc. Possible", 'Unapply must restore native discount eligibility.');
        PlanLine.Get(SalesInvoiceHeader."Installment Plan ID", 20000);
        Assert.AreEqual(0.42, PlanLine."Original Pmt. Disc. Possible", 'Credit application must not rewrite the original discount snapshot.');
        CreditEntry.Get(CreditEntry."Entry No.");
        CreditEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(-20, CreditEntry."Remaining Amount", 'Unapply must reopen the one native credit, not reverse its sale or VAT.');
    end;

    [Test]
    procedure NativeCancellationAndCorrectionStillRejectPartlyAndFullyPaidInvoices()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        ReplacementHeader: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, true);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 3, 10);
        Commit();

        asserterror CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);

        Assert.ExpectedError('fully or partially paid');
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 31.66);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 1, 41.67);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 2, 41.67);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 3, 31.66);
        Commit();

        asserterror CorrectPostedSalesInvoice.CancelPostedInvoiceCreateNewInvoice(SalesInvoiceHeader, ReplacementHeader);

        Assert.ExpectedError('fully or partially paid');
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 1, 0);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 2, 0);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 0);
    end;

    [Test]
    procedure PartialUnpaidCreditCannotSilentlyChooseAnAllocationOrder()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CreditHeader: Record "Sales Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        SalesPost: Codeunit "Sales-Post";
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, true);
        Assert.IsTrue(
            CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, CreditHeader),
            'An unpaid invoice must support corrective copying.');
        SetCreditAmount(CreditHeader, 16);
        CreditHeader.Invoice := true;
        CreditHeader.Modify(true);
        Commit();
        SalesPost.SetSuppressCommit(true);

        asserterror SalesPost.Run(CreditHeader);

        Assert.ExpectedError('Select individual installment entries using Applies-to ID');
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 1, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 2, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 41.66);
    end;

    [Test]
    procedure MidApplicationFailureRollsBackCreditAndEveryInstallment()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CreditHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        Observer: Codeunit "ERM Installment Correction";
        SalesPost: Codeunit "Sales-Post";
        PostingNo: Code[20];
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, true);
        Assert.IsTrue(
            CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, CreditHeader),
            'An unpaid invoice must support corrective copying.');
        CreditHeader.Invoice := true;
        CreditHeader."Posting No." := LibraryUtility.GenerateGUID();
        PostingNo := CreditHeader."Posting No.";
        CreditHeader.Modify(true);
        Commit();
        Observer.SetApplicationFailure(SalesInvoiceHeader."Installment Plan ID");
        BindSubscription(Observer);

        asserterror SalesPost.Run(CreditHeader);

        Assert.ExpectedError(ForcedFailureErr);
        UnbindSubscription(Observer);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 1, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 2, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 41.66);
        CustLedgerEntry.SetRange("Installment Plan ID", SalesInvoiceHeader."Installment Plan ID");
        CustLedgerEntry.SetFilter("Applies-to ID", '<>%1', '');
        Assert.IsTrue(CustLedgerEntry.IsEmpty(), 'Generated application selections must roll back with financial changes.');
        SalesCrMemoHeader.SetRange("No.", PostingNo);
        Assert.IsTrue(SalesCrMemoHeader.IsEmpty(), 'No partially posted credit may survive.');
        GLEntry.SetRange("Document No.", PostingNo);
        Assert.IsTrue(GLEntry.IsEmpty(), 'Revenue, VAT, and control postings must roll back together.');
    end;

    [Test]
    procedure TrackingFailureWithDateOrderedSeriesRollsBackCorrectivePosting()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        SalesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CancelledDocument: Record "Cancelled Document";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        Observer: Codeunit "ERM Installment Correction";
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, true);
        SalesSetup.Get();
        NoSeries.Get(SalesSetup."Posted Credit Memo Nos.");
        NoSeries."Date Order" := true;
        NoSeries.Modify();
        Commit();
        Observer.SetTrackingFailure(SalesInvoiceHeader."Installment Plan ID");
        BindSubscription(Observer);

        asserterror CorrectPostedSalesInvoice.Run(SalesInvoiceHeader);

        Assert.ExpectedError(ForcedFailureErr);
        UnbindSubscription(Observer);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 1, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 2, 41.67);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 41.66);
        SalesCrMemoHeader.SetRange("Applies-to Doc. No.", SalesInvoiceHeader."No.");
        Assert.IsTrue(SalesCrMemoHeader.IsEmpty(), 'The credit must roll back if cancellation tracking fails after posting.');
        Assert.IsFalse(
            CancelledDocument.FindSalesCancelledInvoice(SalesInvoiceHeader."No."),
            'Failed cancellation must not leave a cancellation relationship.');
    end;

    [Test]
    [HandlerFunctions('AppliedEntriesHandler')]
    procedure AppliedEntryNotificationIncludesNonAnchorInstallmentPayments()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        InvoiceNotification: Notification;
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, true);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 1, 10);
        LibraryInstallments.PayInstallment(SalesInvoiceHeader."Installment Plan ID", 2, 10);
        InvoiceNotification.Id := CreateGuid();
        InvoiceNotification.SetData(SalesInvoiceHeader.FieldName("No."), SalesInvoiceHeader."No.");

        CorrectPostedSalesInvoice.ShowAppliedEntries(InvoiceNotification);
    end;

    [Test]
    procedure CustomerCreditJournalCannotMasqueradeAsPostedSalesCredit()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        GenJournalLine: Record "Gen. Journal Line";
        InstallmentPosting: Codeunit "Installment Posting";
    begin
        CreatePostedInvoice(SalesInvoiceHeader, SalesLine, true);
        GenJournalLine."Account Type" := GenJournalLine."Account Type"::Customer;
        GenJournalLine."Account No." := SalesInvoiceHeader."Bill-to Customer No.";
        GenJournalLine."Document Type" := GenJournalLine."Document Type"::"Credit Memo";
        GenJournalLine."Document No." := LibraryUtility.GenerateGUID();
        GenJournalLine."Payment Terms Code" := SalesInvoiceHeader."Payment Terms Code";
        GenJournalLine."System-Created Entry" := true;

        asserterror InstallmentPosting.CheckJournalLine(GenJournalLine);

        Assert.ExpectedError('Global installments currently support full standalone sales invoices only');
    end;

    local procedure CreatePostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"; var SalesLine: Record "Sales Line"; WithoutDiscounts: Boolean)
    var
        SalesHeader: Record "Sales Header";
        PlanLine: Record "Sales Installment Plan Line";
    begin
        LibraryInstallments.CreateInvoice(SalesHeader, SalesLine, '');
        SalesHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
        if WithoutDiscounts then begin
            PlanLine.SetRange("Plan ID", SalesHeader."Installment Plan ID");
            PlanLine.FindSet(true);
            repeat
                PlanLine."Discount %" := 0;
                Clear(PlanLine."Discount Date Calculation");
                PlanLine.Modify(true);
            until PlanLine.Next() = 0;
        end;
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateCreditCopy(SalesInvoiceHeader: Record "Sales Invoice Header"; var CreditHeader: Record "Sales Header")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        LibrarySales.CreateSalesHeader(CreditHeader, CreditHeader."Document Type"::"Credit Memo", SalesInvoiceHeader."Bill-to Customer No.");
        CopyDocumentMgt.SetPropertiesForCorrectiveCreditMemo(true);
        CopyDocumentMgt.CopySalesDocForInvoiceCancelling(SalesInvoiceHeader."No.", CreditHeader);
    end;

    local procedure SetCreditAmount(CreditHeader: Record "Sales Header"; UnitPrice: Decimal)
    var
        CreditLine: Record "Sales Line";
    begin
        CreditLine.SetRange("Document Type", CreditHeader."Document Type");
        CreditLine.SetRange("Document No.", CreditHeader."No.");
        CreditLine.SetRange(Type, CreditLine.Type::"G/L Account");
        CreditLine.FindFirst();
        CreditLine.Validate("Unit Price", UnitPrice);
        CreditLine.Modify(true);
    end;

    local procedure SelectInstallment(var CreditHeader: Record "Sales Header"; PlanID: Guid; Sequence: Integer; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ApplicationID: Code[50];
    begin
        GetInstallment(CustLedgerEntry, PlanID, Sequence);
        ApplicationID := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Applies-to ID" := ApplicationID;
        CustLedgerEntry."Amount to Apply" := Amount;
        CustLedgerEntry.Modify(true);
        CreditHeader.Validate("Applies-to Doc. No.", '');
        CreditHeader.Validate("Applies-to ID", ApplicationID);
        CreditHeader.Modify(true);
    end;

    local procedure GetInstallment(var CustLedgerEntry: Record "Cust. Ledger Entry"; PlanID: Guid; Sequence: Integer)
    var
        PlanLine: Record "Sales Installment Plan Line";
    begin
        PlanLine.SetRange("Plan ID", PlanID);
        PlanLine.SetRange("Installment No.", Sequence);
        PlanLine.FindFirst();
        CustLedgerEntry.Get(PlanLine."Cust. Ledger Entry No.");
    end;

    local procedure VerifyRemaining(PlanID: Guid; Sequence: Integer; ExpectedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        GetInstallment(CustLedgerEntry, PlanID, Sequence);
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(ExpectedAmount, CustLedgerEntry."Remaining Amount", 'Only explicitly selected or fully corrected installments may change.');
        Assert.AreEqual(ExpectedAmount <> 0, CustLedgerEntry.Open, 'Installment closure must agree with its own balance.');
    end;

    local procedure VerifyClosedInvoice(SalesInvoiceHeader: Record "Sales Invoice Header"; CreditNo: Code[20])
    var
        CreditEntry: Record "Cust. Ledger Entry";
        Plan: Record "Sales Installment Plan";
    begin
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 1, 0);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 2, 0);
        VerifyRemaining(SalesInvoiceHeader."Installment Plan ID", 3, 0);
        SalesInvoiceHeader.CalcFields("Remaining Amount", Closed);
        Assert.AreEqual(0, SalesInvoiceHeader."Remaining Amount", 'Invoice-wide remaining amount must include every corrected installment.');
        Assert.IsTrue(SalesInvoiceHeader.Closed, 'Correction must close the logical invoice.');
        CreditEntry.SetRange("Document Type", CreditEntry."Document Type"::"Credit Memo");
        CreditEntry.SetRange("Document No.", CreditNo);
        CreditEntry.SetRange("Customer No.", SalesInvoiceHeader."Bill-to Customer No.");
        Assert.AreEqual(1, CreditEntry.Count(), 'Correction must create exactly one credit entry, not a mirrored credit schedule.');
        CreditEntry.FindFirst();
        CreditEntry.CalcFields("Original Amount", "Remaining Amount");
        Assert.AreEqual(-125, CreditEntry."Original Amount", 'The native credit must reverse the complete invoice once.');
        Assert.AreEqual(0, CreditEntry."Remaining Amount", 'The credit must be fully applied across the original entries.');
        Assert.IsTrue(IsNullGuid(CreditEntry."Installment Plan ID"), 'The corrective credit must not have a schedule.');
        Plan.Get(SalesInvoiceHeader."Installment Plan ID");
        Assert.AreEqual(Plan.Status::Posted, Plan.Status, 'The original posted snapshot must remain immutable.');
        Assert.AreEqual(125, Plan.Amount, 'Correction must not rewrite the original schedule amount.');
    end;

    local procedure VerifyReversedAccounting(SalesInvoiceHeader: Record "Sales Invoice Header"; CreditNo: Code[20]; SalesAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
    begin
        GLEntry.SetFilter("Document No.", '%1|%2', SalesInvoiceHeader."No.", CreditNo);
        GLEntry.SetRange("G/L Account No.", SalesAccountNo);
        Assert.AreEqual(2, GLEntry.Count(), 'The original sale and its correction must each post revenue once.');
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(0, GLEntry.Amount, 'Corrective revenue must reverse the original amount exactly.');
        VATEntry.SetFilter("Document No.", '%1|%2', SalesInvoiceHeader."No.", CreditNo);
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        Assert.AreEqual(2, VATEntry.Count(), 'VAT must be posted once per document, not once per installment.');
        VATEntry.CalcSums(Amount, Base);
        Assert.AreEqual(0, VATEntry.Amount, 'Corrective VAT must reverse the original amount exactly.');
        Assert.AreEqual(0, VATEntry.Base, 'The taxable base must reverse exactly.');
    end;

    procedure SetApplicationFailure(PlanID: Guid)
    begin
        FailApplication := true;
        FailurePlanID := PlanID;
    end;

    procedure SetTrackingFailure(PlanID: Guid)
    begin
        FailTracking := true;
        FailurePlanID := PlanID;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Correct Posted Sales Invoice", 'OnBeforeSetTrackInfoForCancellation', '', false, false)]
    local procedure FailBeforeCancellationTracking(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if FailTracking and (SalesInvoiceHeader."Installment Plan ID" = FailurePlanID) then
            Error(ForcedFailureErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Cust. Ledger Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure FailDuringApplication(var Rec: Record "Cust. Ledger Entry")
    begin
        if FailApplication and (Rec."Installment Plan ID" = FailurePlanID) and
           (Rec."Installment No." = 2) and not Rec.Open
        then
            Error(ForcedFailureErr);
    end;

    [ModalPageHandler]
    procedure AppliedEntriesHandler(var AppliedEntries: TestPage "Applied Customer Entries")
    begin
        Assert.IsTrue(AppliedEntries.First(), 'The first non-anchor payment must be visible.');
        AppliedEntries."Document Type".AssertEquals('Payment');
        Assert.IsTrue(AppliedEntries.Next(), 'The second non-anchor payment must be visible.');
        AppliedEntries."Document Type".AssertEquals('Payment');
        Assert.IsFalse(AppliedEntries.Next(), 'Applied payments must not be duplicated across installment entries.');
    end;
}
