namespace Microsoft.SubscriptionBilling;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;

#pragma warning disable AA0210
// [FEATURE] [Subscription Billing] [Subscription Contract No. on G/L Entry]
codeunit 148457 "Sub. Contr. No. GL Entry Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Access = Internal;

    var
        BillingLine: Record "Billing Line";
        BillingTemplate: Record "Billing Template";
        Customer: Record Customer;
        CustomerContract: Record "Customer Subscription Contract";
        CustomerContractDeferral: Record "Cust. Sub. Contract Deferral";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        ItemServCommitmentPackage: Record "Item Subscription Package";
        PurchaseCrMemoHeader: Record "Purchase Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        SalesCrMemoHeader: Record "Sales Header";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        ServiceCommPackageLine: Record "Subscription Package Line";
        ServiceCommitmentPackage: Record "Subscription Package";
        ServiceCommitmentTemplate: Record "Sub. Package Line Template";
        ServiceObject: Record "Subscription Header";
        Vendor: Record Vendor;
        VendorContract: Record "Vendor Subscription Contract";
        VendorContractDeferral: Record "Vend. Sub. Contract Deferral";
        Assert: Codeunit Assert;
        ContractTestLibrary: Codeunit "Contract Test Library";
        CorrectPostedPurchaseInvoice: Codeunit "Correct Posted Purch. Invoice";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        CorrectedDocumentNo: Code[20];
        PostedDocumentNo: Code[20];
        IsInitialized: Boolean;
        CopyContractDocumentNotAllowedErr: Label 'Copying documents with a link to a contract is not allowed.';
        ContractLineNoMissingErr: Label 'Subscription Contract Line No. should have been carried to the credit memo line.';
        InvoiceNotCancelledErr: Label 'The posted contract invoice should have been cancelled.';

    #region Customer Tests

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPostingSalesInvoiceWithDeferrals()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Posting a contract invoice for a line that creates deferrals fills Subscription Contract No. on the G/L entry of the contract deferral account.
        Initialize();

        // [GIVEN] A customer contract with deferrals and an unposted contract invoice
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');

        // [WHEN] The contract invoice is posted
        PostSalesDocumentAndFetchDeferrals();

        // [THEN] Every G/L entry on the contract deferral account carries the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetCustomerContractAccount(true));
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, CustomerContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPostingSalesInvoiceWithoutDeferrals()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Posting a contract invoice for a line that does not create deferrals fills Subscription Contract No. on the G/L entry of the contract account.
        Initialize();

        // [GIVEN] A customer contract without deferrals and an unposted contract invoice
        CreateSalesDocumentsFromCustomerContractWODeferrals();

        // [WHEN] The contract invoice is posted
        ResetPostingNoSeriesDateUsage();
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Every G/L entry on the contract account carries the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetCustomerContractAccount(false));
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, CustomerContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsSellToCustomerPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenOneSalesInvoiceBillsTwoContracts()
    var
        GLEntry: Record "G/L Entry";
        SecondCustomerContract: Record "Customer Subscription Contract";
        DeferralAccountNo: Code[20];
    begin
        // [SCENARIO] When one invoice bills two contracts that post to the same account, each contract gets its own G/L entry with its own Subscription Contract No.
        Initialize();

        // [GIVEN] Two customer contracts with deferrals for the same customer
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateSecondCustomerContractForSameCustomer(SecondCustomerContract);

        // [GIVEN] Both contracts billed onto a single invoice by grouping on Sell-to Customer No.
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');

        // [WHEN] The contract invoice is posted
        PostSalesDocumentAndFetchDeferrals();

        // [THEN] The deferral account holds one G/L entry per contract, each with its own contract number
        DeferralAccountNo := GetCustomerContractAccount(true);
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, DeferralAccountNo);
        Assert.RecordCount(GLEntry, 2);

        GLEntry.SetRange("Subscription Contract No.", CustomerContract."No.");
        Assert.RecordCount(GLEntry, 1);

        GLEntry.SetRange("Subscription Contract No.", SecondCustomerContract."No.");
        Assert.RecordCount(GLEntry, 1);
    end;

    [Test]
    procedure TestContractNoIsNotFilledOnGLEntriesOfNonSubscriptionSalesInvoice()
    var
        GLEntry: Record "G/L Entry";
        PlainCustomer: Record Customer;
        PlainSalesHeader: Record "Sales Header";
        PlainSalesLine: Record "Sales Line";
        PlainDocumentNo: Code[20];
    begin
        // [SCENARIO] A sales invoice that has nothing to do with Subscription Billing leaves Subscription Contract No. blank on its G/L entries.
        Initialize();

        // [GIVEN] A plain sales invoice with no connection to any Subscription Contract
        LibrarySales.CreateCustomer(PlainCustomer);
        LibrarySales.CreateSalesHeader(PlainSalesHeader, PlainSalesHeader."Document Type"::Invoice, PlainCustomer."No.");
        LibrarySales.CreateSalesLine(
            PlainSalesLine, PlainSalesHeader, PlainSalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        PlainSalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        PlainSalesLine.Modify(true);

        // [WHEN] The invoice is posted
        ResetPostingNoSeriesDateUsage();
        PlainDocumentNo := LibrarySales.PostSalesDocument(PlainSalesHeader, true, true);

        // [THEN] Not one of its G/L entries carries a contract number
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", PlainDocumentNo);
        GLEntry.SetFilter("Subscription Contract No.", '<>%1', '');
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPostingSalesCreditMemo()
    var
        GLEntry: Record "G/L Entry";
        DeferralAccountNo: Code[20];
    begin
        // [SCENARIO] Posting a contract credit memo fills Subscription Contract No. on its G/L entries, not only on invoices.
        Initialize();

        // [GIVEN] A posted contract invoice with deferrals
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');
        PostSalesDocumentAndGetSalesInvoice();
        DeferralAccountNo := GetCustomerContractAccount(true);

        // [WHEN] The invoice is corrected by a credit memo
        PostSalesCreditMemo();

        // [THEN] The credit memo entries on the deferral account carry the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, CorrectedDocumentNo, DeferralAccountNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, CustomerContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenSalesLineHasNoContractNoStored()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] A document created before the contract number was stored on the sales line still gets the contract number
        // on its G/L entries, because posting falls back to the Billing Line.
        Initialize();

        // [GIVEN] A contract invoice whose sales lines carry no contract number, the way documents created before the change look
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll("Subscription Contract No.", '', false);
        SalesLine.ModifyAll("Subscription Contract Line No.", 0, false);

        // [WHEN] The contract invoice is posted
        PostSalesDocumentAndFetchDeferrals();

        // [THEN] The contract number still reaches the G/L entries of the deferral account
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetCustomerContractAccount(true));
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, CustomerContract."No.");

        // [THEN] And the posted invoice line was resolved through the Billing Line as well
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", PostedDocumentNo);
        SalesInvoiceLine.SetFilter("No.", '<>%1', '');
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Subscription Contract No.", CustomerContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestPostingFailsWhenContractOfDeferredSalesLineCannotBeResolved()
    begin
        // [SCENARIO] Posting a contract invoice line that must create contract deferrals fails when its contract cannot be resolved,
        // instead of posting it without deferrals.
        Initialize();

        // [GIVEN] A contract invoice with deferrals whose sales lines carry neither the contract nor the billing period
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.ModifyAll("Subscription Contract No.", '', false);
        SalesLine.ModifyAll("Subscription Contract Line No.", 0, false);
        SalesLine.ModifyAll("Recurring Billing from", 0D, false);

        // [WHEN] The contract invoice is posted
        ResetPostingNoSeriesDateUsage();
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posting fails because the contract to create the deferrals for is not found
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractDocumentCannotBeCopiedToAnotherSalesDocument()
    var
        CopiedSalesHeader: Record "Sales Header";
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        // [SCENARIO] A document linked to a Subscription Contract cannot be copied into another document. That is what keeps
        // the contract number on the sales line from ever reaching a document that bills no contract.
        Initialize();

        // [GIVEN] An unposted contract invoice whose lines carry the contract number
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');
        SalesLine.Reset();
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Subscription Contract No.", '<>%1', '');
        Assert.RecordIsNotEmpty(SalesLine);

        // [WHEN] Copying that invoice into another sales invoice is attempted
        LibrarySales.CreateSalesHeader(CopiedSalesHeader, CopiedSalesHeader."Document Type"::Invoice, Customer."No.");
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        asserterror CopyDocumentMgt.CopySalesDoc("Sales Document Type From"::Invoice, SalesHeader."No.", CopiedSalesHeader);

        // [THEN] The copy is rejected
        Assert.ExpectedError(CopyContractDocumentNotAllowedErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoIsStoredOnSalesLineWhenBillingDocumentIsCreated()
    begin
        // [SCENARIO] Creating a contract invoice stores the Subscription Contract on the sales line itself, so posting does
        // not have to read the Billing Line for it.
        Initialize();

        // [GIVEN] A customer contract
        CreateCustomerContractWithDeferrals('<2M-CM>');

        // [WHEN] The contract invoice is created from the billing proposal
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');

        // [THEN] Every sales line that bills the contract carries the contract and its line
        BillingLine.Reset();
        BillingLine.SetRange("Document No.", SalesHeader."No.");
        BillingLine.FindSet();
        repeat
            SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", BillingLine."Document Line No.");
            SalesLine.TestField("Subscription Contract No.", BillingLine."Subscription Contract No.");
            SalesLine.TestField("Subscription Contract Line No.", BillingLine."Subscription Contract Line No.");
        until BillingLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnCorrectiveCreditMemoCreatedFromPostedInvoice()
    var
        CreditMemoSalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Creating the corrective credit memo for a contract invoice carries the contract onto the credit memo lines.
        Initialize();

        // [GIVEN] A posted contract invoice
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');
        PostSalesDocumentAndGetSalesInvoice();

        // [WHEN] A corrective credit memo is created from it
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesCrMemoHeader);

        // [THEN] The credit memo sales lines carry the contract
        CreditMemoSalesLine.SetRange("Document Type", SalesCrMemoHeader."Document Type");
        CreditMemoSalesLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        CreditMemoSalesLine.SetFilter("No.", '<>%1', '');
        CreditMemoSalesLine.FindSet();
        repeat
            CreditMemoSalesLine.TestField("Subscription Contract No.", CustomerContract."No.");
            Assert.AreNotEqual(0, CreditMemoSalesLine."Subscription Contract Line No.", ContractLineNoMissingErr);
        until CreditMemoSalesLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnPostedCorrectiveCreditMemoCreatedFromPostedInvoice()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // [SCENARIO] Posting the corrective credit memo for a contract invoice carries the contract onto the posted credit memo lines.
        Initialize();

        // [GIVEN] A posted contract invoice and the corrective credit memo created from it
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');
        PostSalesDocumentAndGetSalesInvoice();
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesCrMemoHeader);

        // [WHEN] The credit memo is posted
        ResetPostingNoSeriesDateUsage();
        CorrectedDocumentNo := LibrarySales.PostSalesDocument(SalesCrMemoHeader, true, true);

        // [THEN] The posted credit memo lines carry the contract as well
        SalesCrMemoLine.SetRange("Document No.", CorrectedDocumentNo);
        SalesCrMemoLine.SetFilter("No.", '<>%1', '');
        SalesCrMemoLine.FindSet();
        repeat
            SalesCrMemoLine.TestField("Subscription Contract No.", CustomerContract."No.");
        until SalesCrMemoLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPostedContractInvoiceIsCancelled()
    var
        CancelledDocument: Record "Cancelled Document";
        GLEntry: Record "G/L Entry";
        DeferralAccountNo: Code[20];
    begin
        // [SCENARIO] Cancelling a posted contract invoice posts a credit memo whose G/L entries carry the contract number.
        Initialize();

        // [GIVEN] A posted contract invoice
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');
        PostSalesDocumentAndGetSalesInvoice();
        DeferralAccountNo := GetCustomerContractAccount(true);

        // [WHEN] The posted invoice is cancelled
        Assert.IsTrue(CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader), InvoiceNotCancelledErr);

        // [THEN] The credit memo that cancelled it carries the contract number on its G/L entries
        CancelledDocument.FindSalesCancelledInvoice(PostedDocumentNo);
        FilterGLEntryOnDocumentAndAccount(GLEntry, CancelledDocument."Cancelled By Doc. No.", DeferralAccountNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, CustomerContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsSellToCustomerPageHandler,MessageHandler')]
    procedure TestContractNoOnSalesLineWinsOverBillingLine()
    var
        GLEntry: Record "G/L Entry";
        SecondCustomerContract: Record "Customer Subscription Contract";
        SecondCustomerContractLine: Record "Cust. Sub. Contract Line";
        DeferralAccountNo: Code[20];
    begin
        // [SCENARIO] Posting reads the Subscription Contract from the sales line, and only falls back to the Billing Line
        // when the line has none. Where the two differ, the line is what reaches the G/L entry.
        Initialize();

        // [GIVEN] A contract invoice, and a second contract to point its lines at
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateSecondCustomerContractForSameCustomer(SecondCustomerContract);
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');

        // [GIVEN] Every sales line of the document is moved to a line of the second contract, while the Billing Lines still point at the first
        SecondCustomerContractLine.SetRange("Subscription Contract No.", SecondCustomerContract."No.");
        SecondCustomerContractLine.FindFirst();
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter("Subscription Contract No.", '<>%1', '');
        SalesLine.ModifyAll("Subscription Contract Line No.", SecondCustomerContractLine."Line No.", false);
        SalesLine.ModifyAll("Subscription Contract No.", SecondCustomerContract."No.", false);

        // [WHEN] The invoice is posted
        PostSalesDocumentAndFetchDeferrals();
        DeferralAccountNo := GetCustomerContractAccount(true);

        // [THEN] The G/L entries carry the contract from the sales line, not the one from the Billing Line
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, DeferralAccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, SecondCustomerContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnVATGLEntriesButNotOnReceivableWhenPostingSalesInvoice()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Posting a contract invoice fills Subscription Contract No. on the VAT account G/L entries of the contract line and leaves the receivable entry blank.
        Initialize();

        // [GIVEN] A customer contract with deferrals and an unposted contract invoice
        CreateCustomerContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');

        // [WHEN] The contract invoice is posted
        PostSalesDocumentAndFetchDeferrals();

        // [THEN] The G/L entries on the VAT account carry the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetSalesVATAccount());
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, CustomerContract."No.");

        // [THEN] The receivable entry carries no contract number
        AssertNoContractNoOnGLEntries(PostedDocumentNo, GetReceivablesAccount());
    end;

    [Test]
    [HandlerFunctions('CreateCustomerBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnLineDiscountGLEntryWhenPostingSalesInvoice()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Posting a contract invoice with a line discount fills Subscription Contract No. on the line discount G/L entry.
        Initialize();

        // [GIVEN] A customer contract without deferrals and an unposted contract invoice with a line discount that is posted to its own account
        CreateSalesDocumentsWithLineDiscountFromCustomerContractWODeferrals();

        // [WHEN] The contract invoice is posted
        ResetPostingNoSeriesDateUsage();
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The G/L entry on the line discount account carries the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetSalesLineDiscountAccount());
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, CustomerContract."No.");

        // [THEN] The receivable entry carries no contract number
        AssertNoContractNoOnGLEntries(PostedDocumentNo, GetReceivablesAccount());
    end;

    #endregion Customer Tests

    #region Vendor Tests

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPostingPurchaseInvoiceWithDeferrals()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Posting a contract invoice for a line that creates deferrals fills Subscription Contract No. on the G/L entry of the contract deferral account.
        Initialize();

        // [GIVEN] A vendor contract with deferrals and an unposted contract invoice
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');

        // [WHEN] The contract invoice is posted
        PostPurchDocumentAndFetchDeferrals();

        // [THEN] Every G/L entry on the contract deferral account carries the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetVendorContractAccount(true));
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, VendorContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPostingPurchaseInvoiceWithoutDeferrals()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Posting a contract invoice for a line that does not create deferrals fills Subscription Contract No. on the G/L entry of the contract account.
        Initialize();

        // [GIVEN] A vendor contract without deferrals and an unposted contract invoice
        CreatePurchaseDocumentsFromVendorContractWODeferrals();

        // [WHEN] The contract invoice is posted
        ResetPostingNoSeriesDateUsage();
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Every G/L entry on the contract account carries the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetVendorContractAccount(false));
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, VendorContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPostingPurchaseCreditMemo()
    var
        GLEntry: Record "G/L Entry";
        DeferralAccountNo: Code[20];
    begin
        // [SCENARIO] Posting a contract credit memo fills Subscription Contract No. on its G/L entries, not only on invoices.
        Initialize();

        // [GIVEN] A posted contract invoice with deferrals
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');
        PostPurchDocumentAndGetPurchInvoice();
        DeferralAccountNo := GetVendorContractAccount(true);

        // [WHEN] The invoice is corrected by a credit memo
        PostPurchCreditMemo();

        // [THEN] The credit memo entries on the deferral account carry the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, CorrectedDocumentNo, DeferralAccountNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, VendorContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsBuyFromVendorPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenOnePurchaseInvoiceBillsTwoContracts()
    var
        GLEntry: Record "G/L Entry";
        SecondVendorContract: Record "Vendor Subscription Contract";
        DeferralAccountNo: Code[20];
    begin
        // [SCENARIO] When one invoice bills two contracts that post to the same account, each contract gets its own G/L entry with its own Subscription Contract No.
        Initialize();

        // [GIVEN] Two vendor contracts with deferrals for the same vendor
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateSecondVendorContractForSameVendor(SecondVendorContract);

        // [GIVEN] Both contracts billed onto a single invoice by grouping on Buy-from Vendor No.
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');

        // [WHEN] The contract invoice is posted
        PostPurchDocumentAndFetchDeferrals();

        // [THEN] The deferral account holds one G/L entry per contract, each with its own contract number
        DeferralAccountNo := GetVendorContractAccount(true);
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, DeferralAccountNo);
        Assert.RecordCount(GLEntry, 2);

        GLEntry.SetRange("Subscription Contract No.", VendorContract."No.");
        Assert.RecordCount(GLEntry, 1);

        GLEntry.SetRange("Subscription Contract No.", SecondVendorContract."No.");
        Assert.RecordCount(GLEntry, 1);
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPurchaseLineHasNoContractNoStored()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] A document created before the contract number was stored on the purchase line still gets the contract number
        // on its G/L entries, because posting falls back to the Billing Line.
        Initialize();

        // [GIVEN] A contract invoice whose purchase lines carry no contract number, the way documents created before the change look
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.ModifyAll("Subscription Contract No.", '', false);
        PurchaseLine.ModifyAll("Subscription Contract Line No.", 0, false);

        // [WHEN] The contract invoice is posted
        PostPurchDocumentAndFetchDeferrals();

        // [THEN] The contract number still reaches the G/L entries of the deferral account
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetVendorContractAccount(true));
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, VendorContract."No.");

        // [THEN] And the posted invoice line was resolved through the Billing Line as well
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PostedDocumentNo);
        PurchInvLine.SetFilter("No.", '<>%1', '');
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("Subscription Contract No.", VendorContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestPostingFailsWhenContractOfDeferredPurchaseLineCannotBeResolved()
    begin
        // [SCENARIO] Posting a contract invoice line that must create contract deferrals fails when its contract cannot be resolved,
        // instead of posting it without deferrals.
        Initialize();

        // [GIVEN] A contract invoice with deferrals whose purchase lines carry neither the contract nor the billing period
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.ModifyAll("Subscription Contract No.", '', false);
        PurchaseLine.ModifyAll("Subscription Contract Line No.", 0, false);
        PurchaseLine.ModifyAll("Recurring Billing from", 0D, false);

        // [WHEN] The contract invoice is posted
        ResetPostingNoSeriesDateUsage();
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posting fails because the contract to create the deferrals for is not found
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoIsStoredOnPurchaseLineWhenBillingDocumentIsCreated()
    begin
        // [SCENARIO] Creating a contract invoice stores the Subscription Contract on the purchase line itself, so posting does
        // not have to read the Billing Line for it.
        Initialize();

        // [GIVEN] A vendor contract
        CreateVendorContractWithDeferrals('<2M-CM>');

        // [WHEN] The contract invoice is created from the billing proposal
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');

        // [THEN] Every purchase line that bills the contract carries the contract and its line
        BillingLine.Reset();
        BillingLine.SetRange(Partner, BillingLine.Partner::Vendor);
        BillingLine.SetRange("Document No.", PurchaseHeader."No.");
        BillingLine.FindSet();
        repeat
            PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", BillingLine."Document Line No.");
            PurchaseLine.TestField("Subscription Contract No.", BillingLine."Subscription Contract No.");
            PurchaseLine.TestField("Subscription Contract Line No.", BillingLine."Subscription Contract Line No.");
        until BillingLine.Next() = 0;
    end;

    [Test]
    procedure TestContractNoIsNotFilledOnGLEntriesOfNonSubscriptionPurchaseInvoice()
    var
        GLEntry: Record "G/L Entry";
        PlainVendor: Record Vendor;
        PlainPurchaseHeader: Record "Purchase Header";
        PlainPurchaseLine: Record "Purchase Line";
        PlainDocumentNo: Code[20];
    begin
        // [SCENARIO] A purchase invoice that has nothing to do with Subscription Billing leaves Subscription Contract No. blank on its G/L entries.
        Initialize();

        // [GIVEN] A plain purchase invoice with no connection to any Subscription Contract
        LibraryPurchase.CreateVendor(PlainVendor);
        LibraryPurchase.CreatePurchHeader(PlainPurchaseHeader, PlainPurchaseHeader."Document Type"::Invoice, PlainVendor."No.");
        LibraryPurchase.CreatePurchaseLine(
            PlainPurchaseLine, PlainPurchaseHeader, PlainPurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PlainPurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PlainPurchaseLine.Modify(true);

        // [WHEN] The invoice is posted
        ResetPostingNoSeriesDateUsage();
        PlainDocumentNo := LibraryPurchase.PostPurchaseDocument(PlainPurchaseHeader, true, true);

        // [THEN] Not one of its G/L entries carries a contract number
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", PlainDocumentNo);
        GLEntry.SetFilter("Subscription Contract No.", '<>%1', '');
        Assert.RecordIsEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsBuyFromVendorPageHandler,MessageHandler')]
    procedure TestContractNoOnPurchaseLineWinsOverBillingLine()
    var
        GLEntry: Record "G/L Entry";
        SecondVendorContract: Record "Vendor Subscription Contract";
        SecondVendorContractLine: Record "Vend. Sub. Contract Line";
        DeferralAccountNo: Code[20];
    begin
        // [SCENARIO] Posting reads the Subscription Contract from the purchase line, and only falls back to the Billing Line
        // when the line has none. Where the two differ, the line is what reaches the G/L entry.
        Initialize();

        // [GIVEN] A contract invoice, and a second contract to point its lines at
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateSecondVendorContractForSameVendor(SecondVendorContract);
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');

        // [GIVEN] Every purchase line of the document is moved to a line of the second contract, while the Billing Lines still point at the first
        SecondVendorContractLine.SetRange("Subscription Contract No.", SecondVendorContract."No.");
        SecondVendorContractLine.FindFirst();
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetFilter("Subscription Contract No.", '<>%1', '');
        PurchaseLine.ModifyAll("Subscription Contract Line No.", SecondVendorContractLine."Line No.", false);
        PurchaseLine.ModifyAll("Subscription Contract No.", SecondVendorContract."No.", false);

        // [WHEN] The invoice is posted
        PostPurchDocumentAndFetchDeferrals();
        DeferralAccountNo := GetVendorContractAccount(true);

        // [THEN] The G/L entries carry the contract from the purchase line, not the one from the Billing Line
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, DeferralAccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, SecondVendorContract."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,GetVendorContractLinesPageHandler,ExchangeRateSelectionModalPageHandler')]
    procedure TestContractNoOnPurchaseLineWhenAssignedToVendorContractLine()
    var
        VendorContractLine: Record "Vend. Sub. Contract Line";
    begin
        // [SCENARIO] Assigning an existing purchase invoice line to a Vendor Subscription Contract line stores the contract
        // on the purchase line.
        Initialize();

        // [GIVEN] A vendor contract and a purchase invoice line for the same vendor
        CreateVendorContractAndPurchaseInvoiceLine(VendorContractLine);

        // [WHEN] The purchase line is assigned to the vendor contract line
        PurchaseLine.AssignVendorContractLine(); // GetVendorContractLinesPageHandler

        // [THEN] The purchase line carries the contract and the contract line
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("Subscription Contract No.", VendorContract."No.");
        PurchaseLine.TestField("Subscription Contract Line No.", VendorContractLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,GetVendorContractLinesPageHandler,ExchangeRateSelectionModalPageHandler')]
    procedure TestContractNoOnGLEntriesWhenPurchaseLineAssignedToVendorContractLineIsPosted()
    var
        GLEntry: Record "G/L Entry";
        VendorContractLine: Record "Vend. Sub. Contract Line";
    begin
        // [SCENARIO] Posting a purchase invoice whose line was assigned to a Vendor Subscription Contract line carries the
        // contract number to the G/L entries.
        Initialize();

        // [GIVEN] A purchase invoice line assigned to a vendor contract line
        CreateVendorContractAndPurchaseInvoiceLine(VendorContractLine);
        PurchaseLine.AssignVendorContractLine(); // GetVendorContractLinesPageHandler

        // [WHEN] The invoice is posted
        ResetPostingNoSeriesDateUsage();
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The G/L entries of the invoice carry the contract number
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", PostedDocumentNo);
        GLEntry.SetRange("Subscription Contract No.", VendorContract."No.");
        Assert.RecordIsNotEmpty(GLEntry);
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnCorrectivePurchCreditMemoCreatedFromPostedInvoice()
    var
        CreditMemoPurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Creating the corrective credit memo for a contract invoice carries the contract onto the credit memo lines.
        Initialize();

        // [GIVEN] A posted contract invoice
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');
        PostPurchDocumentAndGetPurchInvoice();

        // [WHEN] A corrective credit memo is created from it
        CorrectPostedPurchaseInvoice.CreateCreditMemoCopyDocument(PurchaseInvoiceHeader, PurchaseCrMemoHeader);

        // [THEN] The credit memo purchase lines carry the contract
        CreditMemoPurchaseLine.SetRange("Document Type", PurchaseCrMemoHeader."Document Type");
        CreditMemoPurchaseLine.SetRange("Document No.", PurchaseCrMemoHeader."No.");
        CreditMemoPurchaseLine.SetFilter("No.", '<>%1', '');
        CreditMemoPurchaseLine.FindSet();
        repeat
            CreditMemoPurchaseLine.TestField("Subscription Contract No.", VendorContract."No.");
            Assert.AreNotEqual(0, CreditMemoPurchaseLine."Subscription Contract Line No.", ContractLineNoMissingErr);
        until CreditMemoPurchaseLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnPostedCorrectivePurchCreditMemoCreatedFromPostedInvoice()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        // [SCENARIO] Posting the corrective credit memo for a contract invoice carries the contract onto the posted credit memo lines.
        Initialize();

        // [GIVEN] A posted contract invoice and the corrective credit memo created from it
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');
        PostPurchDocumentAndGetPurchInvoice();
        CorrectPostedPurchaseInvoice.CreateCreditMemoCopyDocument(PurchaseInvoiceHeader, PurchaseCrMemoHeader);
        PurchaseCrMemoHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseCrMemoHeader.Modify(false);

        // [WHEN] The credit memo is posted
        ResetPostingNoSeriesDateUsage();
        CorrectedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseCrMemoHeader, true, true);

        // [THEN] The posted credit memo lines carry the contract as well
        PurchCrMemoLine.SetRange("Document No.", CorrectedDocumentNo);
        PurchCrMemoLine.SetFilter("No.", '<>%1', '');
        PurchCrMemoLine.FindSet();
        repeat
            PurchCrMemoLine.TestField("Subscription Contract No.", VendorContract."No.");
        until PurchCrMemoLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnGLEntriesWhenPostedContractPurchaseInvoiceIsCancelled()
    var
        CancelledDocument: Record "Cancelled Document";
        GLEntry: Record "G/L Entry";
        DeferralAccountNo: Code[20];
    begin
        // [SCENARIO] Cancelling a posted contract invoice posts a credit memo whose G/L entries carry the contract number.
        Initialize();

        // [GIVEN] A posted contract invoice
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');
        PostPurchDocumentAndGetPurchInvoice();
        DeferralAccountNo := GetVendorContractAccount(true);

        // [WHEN] The posted invoice is cancelled
        Assert.IsTrue(CorrectPostedPurchaseInvoice.CancelPostedInvoice(PurchaseInvoiceHeader), InvoiceNotCancelledErr);

        // [THEN] The credit memo that cancelled it carries the contract number on its G/L entries
        CancelledDocument.FindPurchCancelledInvoice(PostedDocumentNo);
        FilterGLEntryOnDocumentAndAccount(GLEntry, CancelledDocument."Cancelled By Doc. No.", DeferralAccountNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Credit Memo");
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, VendorContract."No.");
    end;

    [Test]
    [HandlerFunctions('CreateVendorBillingDocsContractPageHandler,MessageHandler')]
    procedure TestContractNoOnVATGLEntriesButNotOnPayableWhenPostingPurchaseInvoice()
    var
        GLEntry: Record "G/L Entry";
    begin
        // [SCENARIO] Posting a vendor contract invoice fills Subscription Contract No. on the VAT account G/L entries of the contract line and leaves the payable entry blank.
        Initialize();

        // [GIVEN] A vendor contract with deferrals and an unposted contract invoice
        CreateVendorContractWithDeferrals('<2M-CM>');
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');

        // [WHEN] The contract invoice is posted
        PostPurchDocumentAndFetchDeferrals();

        // [THEN] The G/L entries on the VAT account carry the contract number
        FilterGLEntryOnDocumentAndAccount(GLEntry, PostedDocumentNo, GetPurchaseVATAccount());
        Assert.RecordIsNotEmpty(GLEntry);
        TestContractNoOnAllGLEntries(GLEntry, VendorContract."No.");

        // [THEN] The payable entry carries no contract number
        AssertNoContractNoOnGLEntries(PostedDocumentNo, GetPayablesAccount());
    end;

    #endregion Vendor Tests

    #region Procedures

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Sub. Contr. No. GL Entry Test");
        LibrarySetupStorage.Restore();
        Clear(LibrarySetupStorage);
        ClearAll();
        ContractTestLibrary.InitContractsApp();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Sub. Contr. No. GL Entry Test");
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        IsInitialized := true;
        LibrarySetupStorage.Save(Database::"General Ledger Setup");
        LibrarySetupStorage.Save(Database::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(Database::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Sub. Contr. No. GL Entry Test");
    end;

    local procedure CreateBillingProposalAndCreateBillingDocuments(ServicePartner: Enum "Service Partner"; BillingDateFormula: Text; BillingToDateFormula: Text)
    begin
        ContractTestLibrary.CreateRecurringBillingTemplate(BillingTemplate, BillingDateFormula, BillingToDateFormula, '', ServicePartner);
        ContractTestLibrary.CreateBillingProposal(BillingTemplate, ServicePartner);
        BillingLine.SetRange("Billing Template Code", BillingTemplate.Code);
        BillingLine.SetRange(Partner, ServicePartner);
        Codeunit.Run(Codeunit::"Create Billing Documents", BillingLine); // CreateCustomerBillingDocs / CreateVendorBillingDocs page handler, MessageHandler
        BillingLine.FindLast();
        case ServicePartner of
            ServicePartner::Customer:
                SalesHeader.Get(BillingLine.GetSalesDocumentTypeFromBillingDocumentType(), BillingLine."Document No.");
            ServicePartner::Vendor:
                begin
                    PurchaseHeader.Get(BillingLine.GetPurchaseDocumentTypeFromBillingDocumentType(), BillingLine."Document No.");
                    if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Invoice then
                        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID())
                    else
                        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
                    PurchaseHeader.Modify(false);
                end;
        end;
    end;

    local procedure CreateCustomerContractWithDeferrals(BillingDateFormula: Text)
    begin
        ContractTestLibrary.CreateCustomerInLCY(Customer);
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        Item.Validate("Unit Price", 1200);
        Item.Modify(false);

        ContractTestLibrary.CreateServiceObjectForItem(ServiceObject, Item."No.");
        ServiceObject.Validate(Quantity, 1);
        ServiceObject.SetHideValidationDialog(true);
        ServiceObject.Validate("End-User Customer No.", Customer."No.");
        ServiceObject.Modify(false);

        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate, '<1M>', 10, Enum::"Invoicing Via"::Contract, Enum::"Calculation Base Type"::"Item Price", false);
        ContractTestLibrary.CreateServiceCommitmentPackage(ServiceCommitmentPackage);
        ContractTestLibrary.CreateServiceCommitmentPackageLine(ServiceCommitmentPackage.Code, ServiceCommitmentTemplate.Code, ServiceCommPackageLine);
        ContractTestLibrary.UpdateServiceCommitmentPackageLine(ServiceCommPackageLine, '<12M>', 10, '12M', '<1M>', Enum::"Service Partner"::Customer, Item."No.");

        ContractTestLibrary.AssignItemToServiceCommitmentPackage(Item, ServiceCommitmentPackage.Code);
        ServiceCommitmentPackage.SetFilter(Code, ItemServCommitmentPackage.GetPackageFilterForItem(ServiceObject."Source No."));
        ServiceObject.InsertServiceCommitmentsFromServCommPackage(CalcDate(BillingDateFormula, WorkDate()), ServiceCommitmentPackage);

        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(CustomerContract, ServiceObject, Customer."No.");
    end;

    local procedure CreateSalesDocumentsFromCustomerContractWODeferrals()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        CreateCustomerContractWithDeferrals('<2M-CM>');
        ContractTestLibrary.DisableDeferralsForCustomerContract(CustomerContract, false);
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');

        SubscriptionLine.SetRange(Partner, SubscriptionLine.Partner::Customer);
        SubscriptionLine.SetRange("Subscription Contract No.", CustomerContract."No.");
        SubscriptionLine.ModifyAll("Create Contract Deferrals", Enum::"Create Contract Deferrals"::No);
    end;

    local procedure CreateSecondCustomerContractForSameCustomer(var SecondCustomerContract: Record "Customer Subscription Contract")
    var
        SecondServiceObject: Record "Subscription Header";
    begin
        ContractTestLibrary.CreateServiceObjectForItem(SecondServiceObject, Item."No.");
        SecondServiceObject.Validate(Quantity, 1);
        SecondServiceObject.SetHideValidationDialog(true);
        SecondServiceObject.Validate("End-User Customer No.", Customer."No.");
        SecondServiceObject.Modify(false);

        ServiceCommitmentPackage.Reset();
        ServiceCommitmentPackage.SetFilter(Code, ItemServCommitmentPackage.GetPackageFilterForItem(SecondServiceObject."Source No."));
        SecondServiceObject.InsertServiceCommitmentsFromServCommPackage(CalcDate('<2M-CM>', WorkDate()), ServiceCommitmentPackage);

        ContractTestLibrary.CreateCustomerContractAndCreateContractLinesForItems(SecondCustomerContract, SecondServiceObject, Customer."No.");
    end;

    local procedure CreateVendorContractWithDeferrals(BillingDateFormula: Text)
    begin
        ContractTestLibrary.CreateVendorInLCY(Vendor);
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        Item.Validate("Unit Cost", 1200);
        Item.Modify(false);

        ContractTestLibrary.CreateServiceObjectForItem(ServiceObject, Item."No.");
        ServiceObject.Validate(Quantity, 1);
        ServiceObject.Modify(false);

        ContractTestLibrary.CreateServiceCommitmentTemplate(ServiceCommitmentTemplate, '<1M>', 10, Enum::"Invoicing Via"::Contract, Enum::"Calculation Base Type"::"Item Price", false);
        ContractTestLibrary.CreateServiceCommitmentPackage(ServiceCommitmentPackage);
        ContractTestLibrary.CreateServiceCommitmentPackageLine(ServiceCommitmentPackage.Code, ServiceCommitmentTemplate.Code, ServiceCommPackageLine);
        ContractTestLibrary.UpdateServiceCommitmentPackageLine(ServiceCommPackageLine, '<12M>', 10, '12M', '<1M>', Enum::"Service Partner"::Vendor, Item."No.");

        ContractTestLibrary.AssignItemToServiceCommitmentPackage(Item, ServiceCommitmentPackage.Code);
        ServiceCommitmentPackage.SetFilter(Code, ItemServCommitmentPackage.GetPackageFilterForItem(ServiceObject."Source No."));
        ServiceObject.InsertServiceCommitmentsFromServCommPackage(CalcDate(BillingDateFormula, WorkDate()), ServiceCommitmentPackage);

        ContractTestLibrary.CreateVendorContractAndCreateContractLinesForItems(VendorContract, ServiceObject, Vendor."No.");
    end;

    local procedure CreatePurchaseDocumentsFromVendorContractWODeferrals()
    var
        SubscriptionLine: Record "Subscription Line";
    begin
        CreateVendorContractWithDeferrals('<2M-CM>');
        ContractTestLibrary.DisableDeferralsForVendorContract(VendorContract, false);
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Vendor, '<2M-CM>', '<8M+CM>');

        SubscriptionLine.SetRange(Partner, SubscriptionLine.Partner::Vendor);
        SubscriptionLine.SetRange("Subscription Contract No.", VendorContract."No.");
        SubscriptionLine.ModifyAll("Create Contract Deferrals", Enum::"Create Contract Deferrals"::No);
    end;

    local procedure CreateSecondVendorContractForSameVendor(var SecondVendorContract: Record "Vendor Subscription Contract")
    var
        SecondServiceObject: Record "Subscription Header";
    begin
        ContractTestLibrary.CreateServiceObjectForItem(SecondServiceObject, Item."No.");
        SecondServiceObject.Validate(Quantity, 1);
        SecondServiceObject.Modify(false);

        ServiceCommitmentPackage.Reset();
        ServiceCommitmentPackage.SetFilter(Code, ItemServCommitmentPackage.GetPackageFilterForItem(SecondServiceObject."Source No."));
        SecondServiceObject.InsertServiceCommitmentsFromServCommPackage(CalcDate('<2M-CM>', WorkDate()), ServiceCommitmentPackage);

        ContractTestLibrary.CreateVendorContractAndCreateContractLinesForItems(SecondVendorContract, SecondServiceObject, Vendor."No.");
    end;

    local procedure FilterGLEntryOnDocumentAndAccount(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
    end;

    local procedure GetCustomerContractAccount(WithDeferrals: Boolean): Code[20]
    begin
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", PostedDocumentNo);
        SalesInvoiceLine.SetFilter("No.", '<>%1', '');
        SalesInvoiceLine.FindFirst();
        GeneralPostingSetup.Get(SalesInvoiceLine."Gen. Bus. Posting Group", SalesInvoiceLine."Gen. Prod. Posting Group");
        if WithDeferrals then
            exit(GeneralPostingSetup."Cust. Sub. Contr. Def Account");
        exit(GeneralPostingSetup."Cust. Sub. Contract Account");
    end;

    local procedure GetVendorContractAccount(WithDeferrals: Boolean): Code[20]
    begin
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PostedDocumentNo);
        PurchInvLine.SetFilter("No.", '<>%1', '');
        PurchInvLine.FindFirst();
        GeneralPostingSetup.Get(PurchInvLine."Gen. Bus. Posting Group", PurchInvLine."Gen. Prod. Posting Group");
        if WithDeferrals then
            exit(GeneralPostingSetup."Vend. Sub. Contr. Def. Account");
        exit(GeneralPostingSetup."Vend. Sub. Contract Account");
    end;

    local procedure TestContractNoOnAllGLEntries(var GLEntry: Record "G/L Entry"; ExpectedContractNo: Code[20])
    begin
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Subscription Contract No.", ExpectedContractNo);
        until GLEntry.Next() = 0;
    end;

    local procedure FetchCustomerContractDeferrals(DocumentNo: Code[20])
    begin
        CustomerContractDeferral.Reset();
        CustomerContractDeferral.SetRange("Document No.", DocumentNo);
        CustomerContractDeferral.FindFirst();
    end;

    local procedure FetchVendorContractDeferrals(DocumentNo: Code[20])
    begin
        VendorContractDeferral.Reset();
        VendorContractDeferral.SetRange("Document No.", DocumentNo);
        VendorContractDeferral.FindFirst();
    end;

    local procedure PostSalesCreditMemo()
    begin
        CorrectPostedSalesInvoice.CreateCreditMemoCopyDocument(SalesInvoiceHeader, SalesCrMemoHeader);
        ResetPostingNoSeriesDateUsage();
        CorrectedDocumentNo := LibrarySales.PostSalesDocument(SalesCrMemoHeader, true, true);
    end;

    local procedure PostSalesDocumentAndFetchDeferrals()
    begin
        ResetPostingNoSeriesDateUsage();
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FetchCustomerContractDeferrals(PostedDocumentNo);
    end;

    local procedure PostSalesDocumentAndGetSalesInvoice()
    begin
        ResetPostingNoSeriesDateUsage();
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.Get(PostedDocumentNo);
    end;

    local procedure PostPurchCreditMemo()
    begin
        CorrectPostedPurchaseInvoice.CreateCreditMemoCopyDocument(PurchaseInvoiceHeader, PurchaseCrMemoHeader);
        PurchaseCrMemoHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseCrMemoHeader.Modify(false);
        ResetPostingNoSeriesDateUsage();
        CorrectedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseCrMemoHeader, true, true);
    end;

    local procedure PostPurchDocumentAndFetchDeferrals()
    begin
        ResetPostingNoSeriesDateUsage();
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FetchVendorContractDeferrals(PostedDocumentNo);
    end;

    local procedure PostPurchDocumentAndGetPurchInvoice()
    begin
        ResetPostingNoSeriesDateUsage();
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseInvoiceHeader.Get(PostedDocumentNo);
    end;

    local procedure AssertNoContractNoOnGLEntries(DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        FilterGLEntryOnDocumentAndAccount(GLEntry, DocumentNo, GLAccountNo);
        Assert.RecordIsNotEmpty(GLEntry);
        GLEntry.SetFilter("Subscription Contract No.", '<>%1', '');
        Assert.RecordIsEmpty(GLEntry);
    end;

    local procedure CreateSalesDocumentsWithLineDiscountFromCustomerContractWODeferrals()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SubscriptionLine: Record "Subscription Line";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Discount Posting" := SalesReceivablesSetup."Discount Posting"::"All Discounts";
        SalesReceivablesSetup.Modify(false);
        CreateCustomerContractWithDeferrals('<2M-CM>');
        ContractTestLibrary.DisableDeferralsForCustomerContract(CustomerContract, false);
        SubscriptionLine.SetRange(Partner, SubscriptionLine.Partner::Customer);
        SubscriptionLine.SetRange("Subscription Contract No.", CustomerContract."No.");
        SubscriptionLine.FindSet();
        repeat
            SubscriptionLine.Validate("Discount %", 10);
            SubscriptionLine.Modify(true);
        until SubscriptionLine.Next() = 0;
        CreateBillingProposalAndCreateBillingDocuments(Enum::"Service Partner"::Customer, '<2M-CM>', '<8M+CM>');
    end;

    local procedure GetPayablesAccount(): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        PurchaseInvoiceHeader.Get(PostedDocumentNo);
        VendorPostingGroup.Get(PurchaseInvoiceHeader."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure GetPurchaseVATAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        PurchInvLine.Reset();
        PurchInvLine.SetRange("Document No.", PostedDocumentNo);
        PurchInvLine.SetFilter("Subscription Contract No.", '<>%1', '');
        PurchInvLine.FindFirst();
        VATPostingSetup.Get(PurchInvLine."VAT Bus. Posting Group", PurchInvLine."VAT Prod. Posting Group");
        exit(VATPostingSetup."Purchase VAT Account");
    end;

    local procedure GetReceivablesAccount(): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        SalesInvoiceHeader.Get(PostedDocumentNo);
        CustomerPostingGroup.Get(SalesInvoiceHeader."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetSalesLineDiscountAccount(): Code[20]
    begin
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", PostedDocumentNo);
        SalesInvoiceLine.SetFilter("Subscription Contract No.", '<>%1', '');
        SalesInvoiceLine.FindFirst();
        GeneralPostingSetup.Get(SalesInvoiceLine."Gen. Bus. Posting Group", SalesInvoiceLine."Gen. Prod. Posting Group");
        exit(GeneralPostingSetup."Sales Line Disc. Account");
    end;

    local procedure GetSalesVATAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        SalesInvoiceLine.Reset();
        SalesInvoiceLine.SetRange("Document No.", PostedDocumentNo);
        SalesInvoiceLine.SetFilter("Subscription Contract No.", '<>%1', '');
        SalesInvoiceLine.FindFirst();
        VATPostingSetup.Get(SalesInvoiceLine."VAT Bus. Posting Group", SalesInvoiceLine."VAT Prod. Posting Group");
        exit(VATPostingSetup."Sales VAT Account");
    end;

    local procedure CreateVendorContractAndPurchaseInvoiceLine(var VendorContractLine: Record "Vend. Sub. Contract Line")
    var
        ServiceCommitment: Record "Subscription Line";
    begin
        ContractTestLibrary.DeleteAllContractRecords();
        ContractTestLibrary.CreateVendor(Vendor);
        ContractTestLibrary.CreateVendorContractAndCreateContractLinesForItems(VendorContract, ServiceObject, Vendor."No.");
        VendorContractLine.SetRange("Subscription Contract No.", VendorContract."No.");
        VendorContractLine.FindFirst();
        ServiceCommitment.Get(VendorContractLine."Subscription Line Entry No.");
        ServiceCommitment."Billing Rhythm" := ServiceCommitment."Billing Base Period";
        ServiceCommitment.Modify(false);
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.");
        ContractTestLibrary.CreateItemWithServiceCommitmentOption(Item, Enum::"Item Service Commitment Type"::"Service Commitment Item");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, "Purchase Line Type"::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(false);
    end;

    local procedure ResetPostingNoSeriesDateUsage()
    var
        NoSeriesLine: Record "No. Series Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        NoSeriesLine.SetFilter(
            "Series Code", '%1|%2|%3|%4',
            SalesReceivablesSetup."Posted Shipment Nos.", SalesReceivablesSetup."Posted Invoice Nos.",
            SalesReceivablesSetup."Posted Credit Memo Nos.", SalesReceivablesSetup."Posted Return Receipt Nos.");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);

        PurchasesPayablesSetup.Get();
        NoSeriesLine.SetFilter(
            "Series Code", '%1|%2|%3|%4',
            PurchasesPayablesSetup."Posted Receipt Nos.", PurchasesPayablesSetup."Posted Invoice Nos.",
            PurchasesPayablesSetup."Posted Credit Memo Nos.", PurchasesPayablesSetup."Posted Return Shpt. Nos.");
        NoSeriesLine.ModifyAll("Last Date Used", 0D);
    end;

    #endregion Procedures

    #region Handlers

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure CreateCustomerBillingDocsContractPageHandler(var CreateCustomerBillingDocs: TestPage "Create Customer Billing Docs")
    begin
        CreateCustomerBillingDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CreateCustomerBillingDocsSellToCustomerPageHandler(var CreateCustomerBillingDocs: TestPage "Create Customer Billing Docs")
    begin
        CreateCustomerBillingDocs.GroupingType.SetValue(Enum::"Customer Rec. Billing Grouping"::"Sell-to Customer No.");
        CreateCustomerBillingDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CreateVendorBillingDocsContractPageHandler(var CreateVendorBillingDocs: TestPage "Create Vendor Billing Docs")
    begin
        CreateVendorBillingDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CreateVendorBillingDocsBuyFromVendorPageHandler(var CreateVendorBillingDocs: TestPage "Create Vendor Billing Docs")
    begin
        CreateVendorBillingDocs.GroupingType.SetValue(Enum::"Vendor Rec. Billing Grouping"::"Buy-from Vendor No.");
        CreateVendorBillingDocs.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ExchangeRateSelectionModalPageHandler(var ExchangeRateSelectionPage: TestPage "Exchange Rate Selection")
    begin
        ExchangeRateSelectionPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure GetVendorContractLinesPageHandler(var GetVendorContractLines: TestPage "Get Vendor Contract Lines")
    begin
        GetVendorContractLines.Expand(true);
        GetVendorContractLines.Next(); // Skip Grouping line
        GetVendorContractLines.Selected.SetValue(true);
        GetVendorContractLines.OK().Invoke()
    end;

    #endregion Handlers
}
#pragma warning restore AA0210
