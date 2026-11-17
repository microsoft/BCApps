// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Setup;

codeunit 148233 "Banking FI Reference Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryBanking: Codeunit "Library - Banking FI";
        ExpectedImportedPayment: Record "Ref. Payment - Imported FI";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        ServiceInvoiceNo: Code[20];

    [Test]
    procedure PrepaymentReferenceReachesCustomerLedgerAndMatchesReceipt()
    var
        Header: Record "Sales Header";
        Invoice: Record "Sales Invoice Header";
        Entry: Record "Cust. Ledger Entry";
        Imported: Record "Ref. Payment - Imported FI";
        Journal: Record "Gen. Journal Line";
        Template: Record "Gen. Journal Template";
        Batch: Record "Gen. Journal Batch";
        Bank: Record "Bank Account";
        Payments: Codeunit "Ref. Payment Management FI";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An actual prepayment invoice carries its reference through the customer entry and receipt matching.
        InitializePosting();

        // [GIVEN] A sales order with a configured prepayment account.
        CreatePrepaymentOrder(Header);

        // [WHEN] The prepayment invoice is posted through the production posting codeunit.
        Invoice.Get(LibrarySales.PostSalesPrepaymentInvoice(Header));
        LibraryERM.FindCustomerLedgerEntry(Entry, Entry."Document Type"::Invoice, Invoice."No.");

        // [THEN] A nonempty reference reaches the real customer ledger entry.
        Assert.AreNotEqual('', Invoice."Payment Reference No.", 'Posting must generate the prepayment reference.');
        Assert.AreEqual(Invoice."Payment Reference No.", Entry."Payment Reference No.", 'The customer entry must receive the posted prepayment reference.');

        // [GIVEN] A bank receipt with that reference and an empty journal.
        Imported.SetRange("Posted to G/L", false);
        Imported.DeleteAll();
        Imported.Reset();
        LibraryERM.CreateBankAccount(Bank);
        LibraryERM.CreateGenJournalTemplate(Template);
        LibraryERM.CreateGenJournalBatch(Batch, Template.Name);
        Batch."No. Series" := LibraryERM.CreateNoSeriesCode();
        Batch.Modify();
        Imported."No." := 9197001;
        Imported."Record ID" := 3;
        Imported."Reference No." := Invoice."Payment Reference No.";
        Imported."Filing Code" := 'FI-PREPAYMENT';
        Imported."Banks Posting Date" := WorkDate();
        Imported."Bank Account Code" := Bank."No.";
        Entry.CalcFields("Remaining Amount");
        Imported.Amount := Entry."Remaining Amount";
        Imported.Insert();

        // [WHEN] The real matching routine creates a receipt journal line.
        Payments.MatchLines(Template.Name, Batch.Name);

        // [THEN] Both the imported payment and journal apply to the prepayment entry.
        Imported.Get(9197001);
        Assert.IsTrue(Imported.Matched, 'The prepayment must be discoverable by its replacement reference.');
        Assert.AreEqual(Entry."Entry No.", Imported."Entry No.", 'The bank receipt must match the prepayment customer entry.');
        Journal.SetRange("Journal Template Name", Template.Name);
        Journal.SetRange("Journal Batch Name", Batch.Name);
        Journal.FindFirst();
        Assert.AreEqual(Invoice."Payment Reference No.", Journal."Payment Reference No.", 'The receipt journal must retain the matching reference.');
        Assert.AreEqual(Invoice."No.", Journal."Applies-to Doc. No.", 'The receipt must apply to the actual posted prepayment invoice.');
    end;

    [Test]
    procedure PrepaymentCreditMemoDoesNotReuseInvoiceReference()
    var
        Header: Record "Sales Header";
        Entry: Record "Cust. Ledger Entry";
        CreditMemoNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Moving the customer-entry subscriber must not copy an invoice reference onto a prepayment credit memo.
        InitializePosting();
        CreatePrepaymentOrder(Header);
        LibrarySales.PostSalesPrepaymentInvoice(Header);
        Header.Get(Header."Document Type", Header."No.");

        // [WHEN] The prepayment is reversed with a real credit memo.
        CreditMemoNo := LibrarySales.PostSalesPrepaymentCreditMemo(Header);

        // [THEN] The credit memo does not inherit the invoice-only payment reference.
        LibraryERM.FindCustomerLedgerEntry(Entry, Entry."Document Type"::"Credit Memo", CreditMemoNo);
        Assert.AreEqual('', Entry."Payment Reference No.", 'Invoice reference lookup must not annotate credit memos.');
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPage')]
    procedure PostedServiceInvoiceReferenceAgreesWithLedgerPageAndPrint()
    var
        Invoice: Record "Service Invoice Header";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A posted service invoice displays and prints the reference posted to its customer entry.
        InitializePosting();
        CreateAndPostServiceDocument(Invoice, false);
        Commit();

        // [WHEN] The production service report generates its dataset.
        ServiceInvoiceNo := Invoice."No.";
        Report.Run(Report::"Service - Invoice (FI)", true, false, Invoice);

        // [THEN] Printed, displayed and posted references agree.
        VerifyServiceReference(Invoice, Invoice."Payment Reference No.");
    end;

    [Test]
    [HandlerFunctions('ServiceInvoiceRequestPage')]
    procedure ServiceOrderKeepsPostedReferenceWhenPrintingDisabled()
    var
        Invoice: Record "Service Invoice Header";
        Setup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Disabling reference printing does not clear a service order's posted reference or its page value.
        InitializePosting();
        Setup.Get();
        Setup."Print Payment Reference" := false;
        Setup.Modify();
        CreateAndPostServiceDocument(Invoice, true);
        Commit();

        // [WHEN] The service report is generated with reference printing disabled.
        ServiceInvoiceNo := Invoice."No.";
        Report.Run(Report::"Service - Invoice (FI)", true, false, Invoice);

        // [THEN] Only printing is suppressed; stored, ledger and page references remain intact.
        VerifyServiceReference(Invoice, '');
    end;

    [Test]
    procedure InvoiceDigitsGenerateReference()
    var
        Check: Codeunit "Bank Nos Check FI";
        Reference: Code[20];
    begin
        EnableFeature();
        LibraryBanking.SetInvoiceReferenceSetup();
        Reference := Check.CreateSalesInvReference('INV26874', '');
        Assert.AreEqual('268745', Reference, 'Invoice digits and the 7-3-1 check digit must be preserved.');
        Check.InvReferenceCheck(Reference);
        DisableFeature();
    end;

    [Test]
    procedure CustomerDigitsPrependInvoiceDigits()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Check: Codeunit "Bank Nos Check FI";
        Reference: Code[20];
    begin
        EnableFeature();
        LibraryBanking.SetInvoiceReferenceSetup();
        SalesSetup.Get();
        SalesSetup."Use Customer No. in Reference" := true;
        SalesSetup.Modify();
        Reference := Check.CreateSalesInvReference('INV26874', 'CUST12');
        Assert.AreEqual('1226874', CopyStr(Reference, 1, 7), 'Customer and invoice digits must retain their order.');
        Check.InvReferenceCheck(Reference);
        DisableFeature();
    end;

    [Test]
    procedure CombinedReferenceCannotExceedTwentyCharacters()
    var
        SalesSetup: Record "Sales & Receivables Setup";
        Check: Codeunit "Bank Nos Check FI";
    begin
        EnableFeature();
        LibraryBanking.SetInvoiceReferenceSetup();
        SalesSetup.Get();
        SalesSetup."Use Customer No. in Reference" := true;
        SalesSetup.Modify();
        asserterror Check.CreateSalesInvReference('1234567890', '1234567890');
        Assert.ExpectedError('Reference number cannot be over 20 character long');
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('ImportedPaymentLookupHandler')]
    procedure DefaultLookupShowsUnpostedImportedPayment()
    begin
        VerifyDefaultImportedPaymentLookup(false);
    end;

    [Test]
    [HandlerFunctions('ImportedPaymentLookupHandler')]
    procedure DefaultLookupShowsPostedImportedHistory()
    begin
        VerifyDefaultImportedPaymentLookup(true);
    end;

    local procedure InitializePosting()
    begin
        LibraryBanking.SetCompletedFeatureFixture();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryBanking.SetInvoiceReferenceSetup();
        LibraryReportDataset.Reset();
    end;

    local procedure CreatePrepaymentOrder(var Header: Record "Sales Header")
    var
        Line: Record "Sales Line";
        PostingSetup: Record "General Posting Setup";
        PrepaymentAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesHeader(Header, Header."Document Type"::Order, LibrarySales.CreateCustomerNo());
        Header.Validate("Prepayment %", 50);
        Header.Modify(true);
        LibrarySales.CreateSalesLine(Line, Header, Line.Type::Item, LibraryInventory.CreateItemNo(), 1);
        Line.Validate("Unit Price", 100);
        Line.Modify(true);
        LibraryERM.CreateGLAccount(PrepaymentAccount);
        PrepaymentAccount.Validate("Gen. Prod. Posting Group", Line."Gen. Prod. Posting Group");
        PrepaymentAccount.Validate("VAT Prod. Posting Group", Line."VAT Prod. Posting Group");
        PrepaymentAccount.Modify(true);
        PostingSetup.Get(Line."Gen. Bus. Posting Group", Line."Gen. Prod. Posting Group");
        PostingSetup."Sales Prepayments Account" := PrepaymentAccount."No.";
        PostingSetup.Modify();
    end;

    local procedure CreateAndPostServiceDocument(var Invoice: Record "Service Invoice Header"; IsOrder: Boolean)
    var
        Header: Record "Service Header";
        Setup: Record "Service Mgt. Setup";
    begin
        Setup.Get();
        Setup."Posted Service Invoice Nos." := LibraryERM.CreateNoSeriesCode();
        Setup.Modify();
        if IsOrder then
            LibraryService.CreateServiceDocumentWithItemServiceLine(Header, Header."Document Type"::Order)
        else
            LibraryService.CreateServiceDocumentWithItemServiceLine(Header, Header."Document Type"::Invoice);
        LibraryService.PostServiceOrder(Header, true, false, true);
        Invoice.SetRange("Customer No.", Header."Customer No.");
        Invoice.FindFirst();
    end;

    local procedure VerifyServiceReference(Invoice: Record "Service Invoice Header"; PrintedReference: Code[20])
    var
        Entry: Record "Cust. Ledger Entry";
        InvoicePage: TestPage "Posted Service Invoice";
    begin
        Assert.AreNotEqual('', Invoice."Payment Reference No.", 'The posted service reference must be generated.');
        LibraryERM.FindCustomerLedgerEntry(Entry, Entry."Document Type"::Invoice, Invoice."No.");
        Assert.AreEqual(Invoice."Payment Reference No.", Entry."Payment Reference No.", 'Service customer entries must retain the replacement reference.');
        InvoicePage.OpenView();
        InvoicePage.GoToRecord(Invoice);
        InvoicePage."Payment Reference No.".AssertEquals(Invoice."Payment Reference No.");
        InvoicePage.Close();
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreNotEqual(0, LibraryReportDataset.RowCount(), 'The real service report must produce a dataset.');
        while LibraryReportDataset.GetNextRow() do
            LibraryReportDataset.AssertCurrentRowValueEquals('RefernceNo_ServInvHeader', PrintedReference);
    end;

    [RequestPageHandler]
    procedure ServiceInvoiceRequestPage(var RequestPage: TestRequestPage "Service - Invoice (FI)")
    begin
        RequestPage."Service Invoice Header".SetFilter("No.", ServiceInvoiceNo);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure VerifyDefaultImportedPaymentLookup(Posted: Boolean)
    var
        ImportedPayment: Record "Ref. Payment - Imported FI";
    begin
        EnableFeature();
        Clear(ExpectedImportedPayment);
        ImportedPayment.LockTable();
        if ImportedPayment.FindLast() then
            ExpectedImportedPayment."No." := ImportedPayment."No." + 1
        else
            ExpectedImportedPayment."No." := 1;
        ExpectedImportedPayment."Record ID" := 3;
        ExpectedImportedPayment."Filing Code" := 'FI-LOOKUP';
        ExpectedImportedPayment."Reference No." := '268745';
        ExpectedImportedPayment."Banks Posting Date" := WorkDate();
        ExpectedImportedPayment.Amount := 123.45;
        ExpectedImportedPayment.Matched := true;
        ExpectedImportedPayment."Posted to G/L" := Posted;
        ExpectedImportedPayment.Insert();

        ImportedPayment := ExpectedImportedPayment;
        ImportedPayment.SetRecFilter();
        Page.RunModal(0, ImportedPayment);
        DisableFeature();
    end;

    [ModalPageHandler]
    procedure ImportedPaymentLookupHandler(var ImportedPayments: TestPage "Ref. Payment - Import FI")
    begin
        ImportedPayments."Filing Code".AssertEquals(ExpectedImportedPayment."Filing Code");
        ImportedPayments."Reference No.".AssertEquals(ExpectedImportedPayment."Reference No.");
        ImportedPayments."Banks Posting Date".AssertEquals(ExpectedImportedPayment."Banks Posting Date");
        ImportedPayments.Amount.AssertEquals(ExpectedImportedPayment.Amount);
    end;

    local procedure EnableFeature()
    begin
#if not CLEAN30
        LibraryBanking.SetFeatureEnabled(true);
        BindSubscription(LibraryBanking);
#endif
    end;

    local procedure DisableFeature()
    begin
#if not CLEAN30
        UnbindSubscription(LibraryBanking);
#endif
    end;
}
