codeunit 134102 "ERM Prepayment III"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Purchase Header" = rimd,
                  TableData "Purchase Line" = rimd;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;
        VATAmount: Decimal;
        PrepmtAmountPct: Decimal;
        PrepaymentInvoicesNotPaidErr: Label 'You cannot post the document of type %1 with the number %2 before all related prepayment invoices are posted.', Comment = 'You cannot post the document of type Order with the number 1001 before all related prepayment invoices are posted.';
        AmountError: Label '%1 must be %2 in %3.';
        PrepaymentError: Label 'Validation error for Field: Control95,  Message = ''The new prepayment amount must be between %1 and %2.''';
        PrepaymentError2: Label 'Validation error for Field: Control95,  Message = ''At least one line must have %1 > 0 to distribute prepayment amount.''';
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        PrepaymentTotalAmount: Decimal;
        NoAmtFoundToBePostedErr: Label 'No amount found to be posted.';
        CheckPrepaymentErr: Label 'You cannot correct or cancel a posted sales prepayment invoice.\\Open the related sales order and choose the Post Prepayment Credit Memo.';
        PrepaymentAmountHigherThanTheOrderErr: Label 'The Prepayment account is assigned to a VAT product posting group where the VAT percentage is not equal to zero. This can cause posting errors when invoices have mixed VAT lines. To avoid errors, set the VAT percentage to zero for the account.\\Prepayment amount to be posted is %1. It differs from document amount %2 by %3 in related lines. If the difference is related to rounding, please adjust amounts in lines related to prepayments.', Comment = '%1 - prepayment amount; %2 = document amount; %3 = difference amount';

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAfterUnapplyPrepmtCreditMemo()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        PostedInvoiceNo: Code[20];
        PostedCreditMemoNo: Code[20];
        OldSalesPrepaymentsAccount: Code[20];
        UnrealizedAmount: Decimal;
        UnrealizedBase: Decimal;
    begin
        // Check VAT Entry after unapply and reapply the Prepayment Invoice and Credit Memo.

        // Setup: Update VAT Posting Setup for Unrealized VAT, Create Sales Order with Prepayment %, Post Prepayment Invoice and Credit Memo and Unapply Prepayment Credit Memo.
        Initialize();
        UpdateGeneralLedgerSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldSalesPrepaymentsAccount := SetupForUnrealVAT(SalesLine, VATPostingSetup);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        PostedInvoiceNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");
        PostedCreditMemoNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");
        UnrealizedBase := Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100);
        UnrealizedAmount := Round((SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100) * (VATPostingSetup."VAT %" / 100));
        SalesPostPrepayments.Invoice(SalesHeader);
        SalesPostPrepayments.CreditMemo(SalesHeader);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::"Credit Memo", PostedCreditMemoNo);
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        // Exercise: Again apply Prepayment Credit Memo to Prepayment Invoice.
        LibraryLowerPermissions.SetSalesDocsPost();
        ApplyCustomerLedgerEntries(
          CustLedgerEntry."Document Type"::"Credit Memo", CustLedgerEntry."Document Type"::Invoice, PostedCreditMemoNo, PostedInvoiceNo);

        // Verify: Verify VAT Entry.
        VerifyVATEntry(PostedCreditMemoNo, UnrealizedBase, UnrealizedAmount);

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type", VATPostingSetup."Sales VAT Unreal. Account");
        UpdateSalesPrepmtAccount(OldSalesPrepaymentsAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler,ApplyVendorEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentAndPostPurchaseOrderWithCurrency()
    var
        Currency: Record Currency;
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        PurchPrepmtAccount: Code[20];
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check GL Entry for Gain or Loss A/c on G/L Entry when posted Purchase Invoice and Prepayment Invoice are on different exchange rates.

        // Setup: Create Purchase Order and Update Purchase Prepayment Account in general Posting setup, Post Prepayment Invoice.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, CreateCurrencyWithExchangeRate());
        PurchPrepmtAccount := UpdatePurchasePrepmtAccount(
            CreateGLAccount(PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group"),
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Amount :=
          LibraryERM.ConvertCurrency(
            PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100, PurchaseHeader."Currency Code", '',
            PurchaseHeader."Posting Date");
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        // Post Prepayment Invoice and Create Journal Line for Payment and Post it and Create new Exchange Rate for Currency.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        CreateAndPostPaymentEntry("Gen. Journal Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.");
        CreateAndModifyExchangeRate(PurchaseHeader."Currency Code");

        // Reopen Purchase Order and Modify Purchase Header.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        ModifyPurchaseHeader(PurchaseHeader);
        Amount :=
          Round(
            Amount -
            LibraryERM.ConvertCurrency(
              PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100, PurchaseHeader."Currency Code", '',
              PurchaseHeader."Posting Date"));

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Amount := Amount + CalculateGainOrLossAmount(DocumentNo, GeneralPostingSetup."Purch. Prepayments Account");

        // Verify: Verify VAT Amount in G/L Entry.
        Currency.Get(PurchaseHeader."Currency Code");
        VerifyGLEntry(PurchaseHeader."Currency Code", -Amount, DocumentNo, Currency."Realized Losses Acc.");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(PurchPrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler,ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure ApplyPaymentAndPostSalesOrderWithCurrency()
    var
        Currency: Record Currency;
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        SalesPrepmtAccount: Code[20];
        Amount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check GL Entry for Gain or Loss A/c on G/L entry when posted Sales Invoice and Prepayment Invoice are on different exchange rates.

        // Setup: Create Sales Order and Update Sales Prepayment Account in General Posting Setup, Post Prepayment Invoice.
        Initialize();
        CreateSalesDocument(SalesLine, CreateCurrencyWithExchangeRate());
        SalesPrepmtAccount := UpdateSalesPrepmtAccount(
            CreateGLAccount(SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group"),
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        Amount :=
          LibraryERM.ConvertCurrency(
            SalesLine."Line Amount" * SalesLine."Prepayment %" / 100, SalesHeader."Currency Code", '', SalesHeader."Posting Date");
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        // Post Prepayment Invoice and Create Journal Line for Payment and Post it and Create new Exchange Rate for Currency.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SalesPostPrepayments.Invoice(SalesHeader);
        CreateAndPostPaymentEntry("Gen. Journal Account Type"::Customer, SalesHeader."Sell-to Customer No.");
        CreateAndModifyExchangeRate(SalesHeader."Currency Code");

        // Reopen Sales Order and Modify Sales Header.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        ModifyPostingDateSalesHeader(SalesHeader);
        Amount :=
          Round(
            Amount -
            LibraryERM.ConvertCurrency(
              SalesLine."Line Amount" * SalesLine."Prepayment %" / 100, SalesHeader."Currency Code", '', SalesHeader."Posting Date"));

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Amount := Amount - CalculateGainOrLossAmount(DocumentNo, GeneralPostingSetup."Sales Prepayments Account");

        // Verify: Verify VAT Amount in G/L Entry.
        Currency.Get(SalesHeader."Currency Code");
        VerifyGLEntry(SalesHeader."Currency Code", Amount, DocumentNo, Currency."Realized Gains Acc.");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsPrepmtTotalAmountHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure EqualPrepmtValuesOnSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount has been divided equally in All Sales Line after modifying on Statistics page.

        // Setup: Create Sales Header with Random Prepayment %.
        Initialize();
        SalesPrepmtAccount := CreateSalesDocumentWithPremtSetup(SalesHeader, SalesLine);
        PrepaymentAmount := LibraryRandom.RandDec(10, 2);

        // Verify: Assign Random Values in Global Variables for Verification through SalesStatisticsPrepmtTotalAmountHandler.
        // Verify Sales Line for Equally assigned Prepayment Amount.
        OpenSalesOrderStatistics(SalesLine."Document No.");
        VerifySalesLine(SalesHeader."Document Type", SalesLine."Document No.", PrepaymentAmount);

        // Tear Down.
        LibraryLowerPermissions.SetO365Setup();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsPrepmtTotalAmountHandlerNM')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure EqualPrepmtValuesOnSalesLineNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount has been divided equally in All Sales Line after modifying on Statistics page.

        // Setup: Create Sales Header with Random Prepayment %.
        Initialize();
        SalesPrepmtAccount := CreateSalesDocumentWithPremtSetup(SalesHeader, SalesLine);
        PrepaymentAmount := LibraryRandom.RandDec(10, 2);

        // Verify: Assign Random Values in Global Variables for Verification through SalesStatisticsPrepmtTotalAmountHandlerNM.
        // Verify Sales Line for Equally assigned Prepayment Amount.
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");
        VerifySalesLine(SalesHeader."Document Type", SalesLine."Document No.", PrepaymentAmount);

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryAfterSalesPrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocumentNo: Code[20];
        SalesPrepmtAccount: Code[20];
    begin
        // Check Gen. Bus. Posting Group and Gen. Prod. Posting Group in G/L Entry after posting Prepayment Invoice from Sales Order.

        // Setup: Create Sales Order and update Sales Prepayment Account with Random Values for Prepayment %, Quantity and Unit Price.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), LibraryRandom.RandDec(10, 2));
        CreateAndModifySalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");

        // Exercise.
        SalesPostPrepayments.Invoice(SalesHeader);

        // Verify: Verify values in G/L Entry.
        FindGLEntry(GLEntry, DocumentNo, GLAccount."No.");
        GLEntry.FindFirst();
        GLEntry.TestField("Gen. Bus. Posting Group", SalesLine."Gen. Bus. Posting Group");
        GLEntry.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntyAfterPurchasePrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Gen. Bus. Posting Group and Gen. Prod. Posting Group in G/L Entry after posting Prepayment Invoice from Purchase Order.

        // Setup: Create Purchase Order and update Purchase Prepayment Account.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        CreatePurchaseDocument(PurchaseLine, '');
        PurchasePrepmtAccount :=
          UpdatePurchasePrepmtAccount(GLAccount."No.", PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");

        // Exercise.
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // Verify: Verify values in G/L Entry.
        FindGLEntry(GLEntry, DocumentNo, GLAccount."No.");
        GLEntry.FindFirst();
        GLEntry.TestField("Gen. Bus. Posting Group", PurchaseLine."Gen. Bus. Posting Group");
        GLEntry.TestField("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPrePmtInvoice()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocumentNo: Code[20];
        SalesPrepmtAccount: Code[20];
        LineAmount: Decimal;
    begin
        // Check Prepayment % on Posted Sales Invoice Line after Posting Prepayment Invoice through Sales Order.

        // Create Sales Document.
        Initialize();
        SalesPrepmtAccount := CreateSalesDocumentWithPremtSetup(SalesHeader, SalesLine);
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        // Exercise.
        LibraryLowerPermissions.SetSalesDocsPost();
        SalesPostPrepayments.Invoice(SalesHeader);
        LineAmount := FindSalesLinePrepaymentPct(SalesHeader."Document Type", SalesHeader."No.");

        // Verify.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        Assert.AreNearlyEqual(
          LineAmount, SalesInvoiceLine."Line Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, SalesInvoiceLine.FieldCaption("Line Amount"), LineAmount, SalesInvoiceLine.TableCaption()));

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchasePrepaymentInvoiceNoSeries()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        OldPostedPrepmtInvNos: Code[20];
        PurchasePrepmtAccount: Code[20];
        PostedPrepmtInvNos: Code[20];
    begin
        // Check Posted Prepayment Invoice Nos after creating new No. Series for Posted Prepayment Purchase Invoice in Purchase and Payables Setup.

        // Setup: Create new No. Series for Posted Prepayment Purchase Invoice and update in Purchase and Payables Setup, create Purchase Order and update Purchase Prepayment account in General Posting Setup.
        Initialize();
        PostedPrepmtInvNos := LibraryUtility.GetGlobalNoSeriesCode();
        OldPostedPrepmtInvNos := PostedPrepmtInvNosInPurchaseSetup(PostedPrepmtInvNos);
        CreatePurchaseDocument(PurchaseLine, '');
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        PurchasePrepmtAccount :=
          UpdatePurchasePrepmtAccount(GLAccount."No.", PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();

        // Exercise: Post Prepayment Purchase Invoice.
        LibraryLowerPermissions.SetPurchDocsPost();
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // Verify: Verify the Posted Prepayment Invoice Nos.
        VerifyPrepaymentInvoice(PurchaseHeader."No.", PostedPrepmtInvNos);

        // Tear Down: Reset the Posted Prepayment Invoice Nos from the Purchase and Payables Setup and Purchse Prepayment Account in General Posting Setup.
        LibraryLowerPermissions.SetOutsideO365Scope();
        PostedPrepmtInvNosInPurchaseSetup(OldPostedPrepmtInvNos);
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOnPurchasePrepaymentCreditMemo()
    var
        GLAccount: Record "G/L Account";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Posting Date should not be blank on Posted Prepayment Credit Memo from Purchase Order.

        // Setup: Create Purchase Order, Update Purchase Prepayment Account and Post Prepayment Invoice.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        CreatePurchaseDocument(PurchaseLine, '');
        PurchasePrepmtAccount :=
          UpdatePurchasePrepmtAccount(GLAccount."No.", PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        ModifyCrMemoNoOnPurchaseHeader(PurchaseHeader);
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepmt. Cr. Memo No. Series");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsPost();
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);

        // Verify: Verify Posted Prepayment Credit Memo with Posting Date.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.TestField("Posting Date", PurchaseHeader."Posting Date");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOnPurchasePrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocumentNo: Code[20];
        PurchasePrepmtAccount: Code[20];
    begin
        // Check Posting Date should not be blank on Posted Prepayment Invoice from Purchase Order.

        // Setup: Create Purchase Order and Update Purchase Prepayment Account.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        CreatePurchaseDocument(PurchaseLine, '');
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        PurchasePrepmtAccount :=
          UpdatePurchasePrepmtAccount(GLAccount."No.", PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsPost();
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // Verify: Verify Posted Prepayment Invoice with Posting Date.
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Posting Date", PurchaseHeader."Posting Date");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdatePurchasePrepmtAccount(
          PurchasePrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOnSalesPrepaymentCreditMemo()
    var
        GLAccount: Record "G/L Account";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocumentNo: Code[20];
        SalesPrepmtAccount: Code[20];
    begin
        // Check Posting Date should not be blank on Posted Prepayment Credit Memo from Sales Order.

        // Setup: Create Sales Order, Update Sales Prepayment Account and Post Prepayment Invoice with Random Values.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), LibraryRandom.RandDec(10, 2));
        CreateAndModifySalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesPostPrepayments.Invoice(SalesHeader);
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");

        // Exercise.
        LibraryLowerPermissions.SetSalesDocsPost();
        SalesPostPrepayments.CreditMemo(SalesHeader);

        // Verify: Verify Posting Date on Posted Prepayment Credit Memo.
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.TestField("Posting Date", SalesHeader."Posting Date");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingDateOnSalesPrepaymentInvoice()
    var
        GLAccount: Record "G/L Account";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocumentNo: Code[20];
        SalesPrepmtAccount: Code[20];
    begin
        // Check Posting Date should not be blank on Posted Prepayment Invoice from Sales Order.

        // Setup: Create Sales Order and Update Sales Prepayment Account with Random Values.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), LibraryRandom.RandDec(10, 2));
        CreateAndModifySalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");

        // Exercise.
        LibraryLowerPermissions.SetSalesDocsPost();
        SalesPostPrepayments.Invoice(SalesHeader);

        // Verify: Verify Posting Date on Posted Prepayment Invoice.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.TestField("Posting Date", SalesHeader."Posting Date");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [HandlerFunctions('SalesStatisticsPrepmtTotalAmountHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PrepmtAmountErrorOnStatistics()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount Error on Statistics page when Prepayment % not assigned on Sales Order.

        // Setup: Create Sales Header with Zero Prepayment % and Create Sales Line with G/L Account and Random values.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        // TODO: Uncomment LibraryLowerPermissions.SetO365Setup();
        // TODO: Uncomment LibraryLowerPermissions.AddSalesDocsPost();
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), 0);
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(10, 2));
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Assign Random values in Global Variables for Verification through SalesStatisticsPrepmtTotalAmountHandler.
        PrepaymentAmount := LibraryRandom.RandDec(10, 2);
        // TODO: Uncomment LibraryLowerPermissions.SetOutsideO365Scope();
        asserterror OpenSalesOrderStatistics(SalesLine."Document No.");

        // Verify: Verify Error on Prepayment Amount field with Statistics page.
        Assert.ExpectedError(StrSubstNo(PrepaymentError2, SalesLine.FieldCaption("Prepayment %")));

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [HandlerFunctions('SalesStatisticsPrepmtTotalAmountHandler')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PrepmtAmountErrorWithMoreInvoiceAmount()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Check Prepayment Amount Error on Statistics Page when Prepayment Amount is more than the Sales Line Amount.

        // Setup: Create Sales Header with Zero Prepayment %.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        // TODO: Uncomment LibraryLowerPermissions.SetSalesDocsPost();
        // TODO: Uncomment LibraryLowerPermissions.AddO365Setup();
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), 0);
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(10, 2));
        ModifySalesLinePrepaymentPct(SalesLine, LibraryRandom.RandDec(10, 2));
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Assign Calculation in Global Variables for Verification through SalesStatisticsPrepmtTotalAmountHandler morethan Sales Line Amount.
        // TODO: Uncomment LibraryLowerPermissions.SetOutsideO365Scope();
        PrepaymentAmount := SalesLine."Line Amount" + LibraryRandom.RandDec(10, 2);
        asserterror OpenSalesOrderStatistics(SalesLine."Document No.");

        // Verify: Verify Error on Prepayment Amount field with Statistics page.
        Amount1 := SalesLine."Prepmt. Amt. Inv.";
        Amount2 := SalesLine."Line Amount";
        Assert.ExpectedError(StrSubstNo(PrepaymentError, Amount1, Amount2));

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;
#endif
    [HandlerFunctions('SalesStatisticsPrepmtTotalAmountHandlerNM')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PrepmtAmountErrorOnStatisticsNM()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment Amount Error on Statistics page when Prepayment % not assigned on Sales Order.

        // Setup: Create Sales Header with Zero Prepayment % and Create Sales Line with G/L Account and Random values.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), 0);
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(10, 2));
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Assign Random values in Global Variables for Verification through SalesStatisticsPrepmtTotalAmountHandler.
        PrepaymentAmount := LibraryRandom.RandDec(10, 2);
        asserterror OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // Verify: Verify Error on Prepayment Amount field with Statistics page.
        Assert.ExpectedError(StrSubstNo(PrepaymentError2, SalesLine.FieldCaption("Prepayment %")));

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [HandlerFunctions('SalesStatisticsPrepmtTotalAmountHandlerNM')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PrepmtAmountErrorWithMoreInvoiceAmountNM()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
        Amount1: Decimal;
        Amount2: Decimal;
    begin
        // Check Prepayment Amount Error on Statistics Page when Prepayment Amount is more than the Sales Line Amount.

        // Setup: Create Sales Header with Zero Prepayment %.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), 0);
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(10, 2));
        ModifySalesLinePrepaymentPct(SalesLine, LibraryRandom.RandDec(10, 2));
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Assign Calculation in Global Variables for Verification through SalesStatisticsPrepmtTotalAmountHandler morethan Sales Line Amount.
        PrepaymentAmount := SalesLine."Line Amount" + LibraryRandom.RandDec(10, 2);
        asserterror OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // Verify: Verify Error on Prepayment Amount field with Statistics page.
        Amount1 := SalesLine."Prepmt. Amt. Inv.";
        Amount2 := SalesLine."Line Amount";
        Assert.ExpectedError(StrSubstNo(PrepaymentError, Amount1, Amount2));

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountInvLCYAfterPostingPurchasePrepmt()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        PurchPrepaymentsAccount: Code[20];
        PrepmtAmountInvLCY: Decimal;
    begin
        // Check Prepayment Amount Invoice(LCY) field value after posting Purchase Prepayment Invoice.

        // Setup: Create Purchase Order with Prepayment % and blank currency.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, '');
        GLAccount.Get(LibraryERM.CreateGLAccountWithPurchSetup());
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        PurchPrepaymentsAccount :=
          UpdatePurchasePrepmtAccount(GLAccount."No.", PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        PrepmtAmountInvLCY := Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."Prepayment %" / 100);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        LibraryLowerPermissions.SetPurchDocsPost();
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // Verify.
        FindPurchaseLine(PurchaseLine, PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseLine.TestField("Prepmt. Amount Inv. (LCY)", PrepmtAmountInvLCY);

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdatePurchasePrepmtAccount(
          PurchPrepaymentsAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountInvLCYAfterPostingSalesPrepmt()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        SalesPrepmtAccount: Code[20];
        PrepmtAmountInvLCY: Decimal;
    begin
        // Check Prepayment Amount Invoice(LCY) field value after posting Sales Prepayment Invoice.

        // Setup: Create Sales Order with Prepayment % and blank currency.
        Initialize();
        CreateSalesDocument(SalesLine, '');
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        PrepmtAmountInvLCY := Round(SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Prepayment %" / 100);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        LibraryLowerPermissions.SetSalesDocsPost();
        SalesPostPrepayments.Invoice(SalesHeader);

        // Verify.
        FindSalesLine(SalesLine, SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.TestField("Prepmt. Amount Inv. (LCY)", PrepmtAmountInvLCY);

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountInvLCYBeforePostingPurchasePrepmt()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Prepayment Amount Invoice(LCY) field value before posting Purchase Prepayment Invoice.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Order with Prepayment % and blank currency.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsCreate();
        CreatePurchaseDocument(PurchaseLine, '');

        // Verify.
        PurchaseLine.TestField("Prepmt. Amount Inv. (LCY)", 0);  // 'Prepmt. Amount Inv. (LCY)' must be zero before Prepayment Invoice posting.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtAmountInvLCYBeforePostingSalesPrepmt()
    var
        SalesLine: Record "Sales Line";
    begin
        // Check Prepayment Amount Invoice(LCY) field value before posting Sales Prepayment Invoice.

        // Setup.
        Initialize();

        // Exercise: Create Sales Order with Prepayment % and blank currency.
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        CreateSalesDocument(SalesLine, '');

        // Verify.
        SalesLine.TestField("Prepmt. Amount Inv. (LCY)", 0);  // 'Prepmt. Amount Inv. (LCY)' must be zero before Prepayment Invoice posting.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtLineAmountOnSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment % and Prepayment Line Amount on Sales Line.

        // Create Sales Document.
        Initialize();
        SalesPrepmtAccount := CreateSalesDocumentWithPremtSetup(SalesHeader, SalesLine);

        // Verify: Verify Prepayment % and Prepayment Line Amount field on Sales Line.
        LibraryLowerPermissions.SetSalesDocsCreate();
        VerifySalesLineForPrepaymentValues(SalesHeader);

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PrepmtValuesOnSalesLine()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check modified Prepayment %, Prepayment VAT Amount and Prepayment Total Amount on Statistics Page and Sales Line.

        // Setup: Create Sales Header with Random Prepayment %.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), LibraryRandom.RandDec(10, 2));

        // Exercise: Create Sales Line with G/L Account and Random Values.
        LibraryLowerPermissions.SetSalesDocsCreate();
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(10, 2));

        LibraryLowerPermissions.SetO365Setup();
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Verify: Open Sales Order Statistics Page and Assign Calculation in Global Variables for Verification through SalesPrepmtFieldsStatisticsHandler.
        PrepaymentAmount := Round(SalesLine."Prepmt. Line Amount" + LibraryRandom.RandDec(10, 2));
        PrepaymentVATAmount := Round(PrepaymentAmount * SalesLine."VAT %" / 100);
        PrepaymentTotalAmount := PrepaymentVATAmount + PrepaymentAmount;
        LibraryLowerPermissions.SetOutsideO365Scope();
        OpenSalesOrderStatistics(SalesLine."Document No.");

        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Prepmt. Line Amount", PrepaymentAmount);

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure PrepmtValuesOnSalesLineNM()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check modified Prepayment %, Prepayment VAT Amount and Prepayment Total Amount on Statistics Page and Sales Line.

        // Setup: Create Sales Header with Random Prepayment %.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), LibraryRandom.RandDec(10, 2));

        // Exercise: Create Sales Line with G/L Account and Random Values.
        LibraryLowerPermissions.SetSalesDocsCreate();
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(10, 2));

        LibraryLowerPermissions.SetO365Setup();
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Verify: Open Sales Order Statistics Page and Assign Calculation in Global Variables for Verification through SalesPrepmtFieldsStatisticsHandlerNM.
        PrepaymentAmount := Round(SalesLine."Prepmt. Line Amount" + LibraryRandom.RandDec(10, 2));
        PrepaymentVATAmount := Round(PrepaymentAmount * SalesLine."VAT %" / 100);
        PrepaymentTotalAmount := PrepaymentVATAmount + PrepaymentAmount;
        LibraryLowerPermissions.SetOutsideO365Scope();
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Prepmt. Line Amount", PrepaymentAmount);

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure PurchasePrepmtInvoiceWithCurrencyAndVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        DocumentNo: Code[20];
        PurchPrepmtAccount: Code[20];
        PrepaymentAmount: Decimal;
        Amount: Decimal;
    begin
        // Check GL Entry for VAT Amount after Posting Prepayment Purchase Invoice with Currency.

        // Setup: Create Purchase Order and Update Purchase Prepayment Account in general Posting setup.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddPurchDocsPost();
        CreatePurchaseDocument(PurchaseLine, CreateCurrencyWithExchangeRate());
        PurchPrepmtAccount :=
          UpdatePurchasePrepmtAccount(
            CreateGLAccount(PurchaseLine."Gen. Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group"),
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PrepaymentAmount := Round((PurchaseLine."Amount Including VAT" - PurchaseLine.Amount) * PurchaseLine."Prepayment %" / 100);
        Amount :=
          Round(
            LibraryERM.ConvertCurrency(PrepaymentAmount, PurchaseHeader."Currency Code", '', PurchaseHeader."Posting Date"));
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Prepayment No. Series");

        // Exercise: Post Purchase Prepayment Invoice.
        PurchasePostPrepayments.Invoice(PurchaseHeader);

        // Verify: Verify VAT Amount in G/L Entry.
        VerifyGLEntryWithAmount(DocumentNo, VATPostingSetup."Purchase VAT Account", Amount);

        // Tear Down.
        UpdatePurchasePrepmtAccount(PurchPrepmtAccount, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinePrepmtPct()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Prepayment % is same after Creating New Sales Line on Sales Order.

        // Setup: Create Sales Header with Random Prepayment %.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), LibraryRandom.RandDec(10, 2));

        // Exercise: Create Sales Line with G/L Account Type and Zero Quantity.
        LibraryLowerPermissions.SetSalesDocsCreate();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 0);

        // Verify: Verify Prepayment % and Prepayment Line Amount field on Sales Line after Creating New Line.
        SalesLine.TestField("Prepayment %", SalesHeader."Prepayment %");
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderExplodeBOM()
    var
        BOMComponent: Record "BOM Component";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ItemNo: Code[20];
    begin
        // Check Prepayment % on Sales Line after Creating Item with Sales Prepayment % and BOM component.

        // Setup: Create Item with Sales Prepayment %.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateSalesPrepaymentPct(SalesPrepaymentPct, CreateCustomer());
        ItemNo := SalesPrepaymentPct."Item No.";
        CreateSalesPrepaymentPct(SalesPrepaymentPct, SalesPrepaymentPct."Sales Code");

        // Create BOM Component and Sales Order with Zero Quantity.
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ItemNo, BOMComponent.Type::Item, SalesPrepaymentPct."Item No.", 1, '');
        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateSalesOrder(SalesLine, SalesPrepaymentPct."Sales Code", ItemNo, 0);

        // Explode BOM on Sales Line through Sales Order Page.
        LibraryLowerPermissions.SetOutsideO365Scope();
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesOrder.SalesLines.ExplodeBOM_Functions.Invoke();

        // Verify: Verify Sales Line Prepayment % for BOM Component after Explode BOM.
        SalesLine.SetRange("No.", SalesPrepaymentPct."Item No.");
        SalesLine.FindFirst();
        SalesLine.TestField("Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPrepmtPct()
    var
        SalesPrepaymentPct: Record "Sales Prepayment %";
        SalesLine: Record "Sales Line";
    begin
        // Check Prepayment % on Sales Line after Creating Item with Sales Prepayment %.

        // Setup: Create Item with Sales Prepayment %.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsCreate();
        CreateSalesPrepaymentPct(SalesPrepaymentPct, CreateCustomer());

        // Exercise: Create Sales Order with Zero Quantity.
        LibraryLowerPermissions.AddSalesDocsCreate();
        CreateSalesOrder(SalesLine, SalesPrepaymentPct."Sales Code", SalesPrepaymentPct."Item No.", 0);

        // Verify: Verify Prepayment % on Sales Line according to Item Prepayment %.
        SalesLine.TestField("Prepayment %", SalesPrepaymentPct."Prepayment %");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsPrepmtInvPctHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPrepmtPctStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment % BAR on Sales Order Statistics Page after Posting Prepayment Invoice on Sales Order.

        // Setup: Create Setup for Sales Prepayment %.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SalesPrepmtAccount := SetupForSalesPrepayment(SalesLine);

        // Post Prepayment Invoice and Change Status with Open.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesPostPrepayments.Invoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise: Modify and Calculate Prepayment % BAR Value with Random Values. Custom Formula taken by Sales Order Statistics Page.
        // Assign Calculation in Global Variable for Page Handler.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Prepmt. Line Amount", SalesLine."Prepmt. Line Amount" + LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        PrepmtAmountPct := Round(SalesLine."Prepmt. Amt. Inv." / SalesLine."Prepmt. Line Amount" * 100, 1);

        // Verify: Verify Statistics Page on Sales Order with Prepayment % BAR field(SalesOrderStatisticsHandler).
        LibraryLowerPermissions.SetOutsideO365Scope();
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsPrepmtInvPctHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesOrderPrepmtPctStatisticsNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        SalesPrepmtAccount: Code[20];
    begin
        // Check Prepayment % BAR on Sales Order Statistics Page after Posting Prepayment Invoice on Sales Order.

        // Setup: Create Setup for Sales Prepayment %.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SalesPrepmtAccount := SetupForSalesPrepayment(SalesLine);

        // Post Prepayment Invoice and Change Status with Open.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesPostPrepayments.Invoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise: Modify and Calculate Prepayment % BAR Value with Random Values. Custom Formula taken by Sales Order Statistics Page.
        // Assign Calculation in Global Variable for Page Handler.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Prepmt. Line Amount", SalesLine."Prepmt. Line Amount" + LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        PrepmtAmountPct := Round(SalesLine."Prepmt. Amt. Inv." / SalesLine."Prepmt. Line Amount" * 100, 1);

        // Verify: Verify Statistics Page on Sales Order with Prepayment % BAR field(SalesOrderStatisticsHandler).
        LibraryLowerPermissions.SetOutsideO365Scope();
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPrepmtPostError()
    var
        SalesPrepaymentPct: Record "Sales Prepayment %";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 224328] System throws error "You cannot post the document of type Oder with the number 1001 before all related prepayment invoices are fully posted and paid."
        // [SCENARIO 224328] when unposted prepayment blocks posting of sales order with No. = 1001

        // Setup: Create Item with Sales Prepayment % and Sales Order With Random Values..
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateSalesPrepaymentPct(SalesPrepaymentPct, CreateCustomer());
        CreateSalesOrder(SalesLine, SalesPrepaymentPct."Sales Code", SalesPrepaymentPct."Item No.", LibraryRandom.RandDec(10, 2));
        ModifyUnitPriceOnSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));

        // Exercise: Try to Post Sales Order with Page.
        LibraryLowerPermissions.SetOutsideO365Scope();
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesLine."Document No.");
        asserterror SalesOrder.Post.Invoke();

        // Verify: Verify Error raised during Sales Order Posting.
        Assert.ExpectedError(StrSubstNo(PrepaymentInvoicesNotPaidErr, SalesLine."Document Type", SalesLine."Document No."));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPrepmtStatistics()
    var
        SalesPrepaymentPct: Record "Sales Prepayment %";
        SalesLine: Record "Sales Line";
    begin
        // Check Prepayment Amount field on Sales Order Statistics page.

        // Setup: Create Item with Sales Prepayment %.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateSalesPrepaymentPct(SalesPrepaymentPct, CreateCustomer());

        // Exercise: Take Random Value for Quantity on Sales Order.
        CreateSalesOrder(SalesLine, SalesPrepaymentPct."Sales Code", SalesPrepaymentPct."Item No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Prepayment VAT Amount field's editable property on Statistics Page through page Handler(SalesOrderStatisticsHandler).
        LibraryLowerPermissions.SetOutsideO365Scope();
        OpenSalesOrderStatistics(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('VATSalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderVATAmtStatistics()
    var
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check VAT Amount on Prepayment Tab with Sales Order Statistics Page after Create Sales Order.

        // Setup: Create Setup for Sales Prepayment %.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SalesPrepmtAccount := SetupForSalesPrepayment(SalesLine);

        // Exercise: Calculate VAT Amount and Assign in Global Variable.
        VATAmount := SalesLine."Line Amount" * SalesLine."VAT %" / 100;

        // Verify: Open Sales Order Statistics Page and Verify VAT Amount field through Page Handler(VATSalesOrderStatisticsHandler).
        LibraryLowerPermissions.SetOutsideO365Scope();
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesOrderPrepmtStatisticsNM()
    var
        SalesPrepaymentPct: Record "Sales Prepayment %";
        SalesLine: Record "Sales Line";
    begin
        // Check Prepayment Amount field on Sales Order Statistics page.

        // Setup: Create Item with Sales Prepayment %.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateSalesPrepaymentPct(SalesPrepaymentPct, CreateCustomer());

        // Exercise: Take Random Value for Quantity on Sales Order.
        CreateSalesOrder(SalesLine, SalesPrepaymentPct."Sales Code", SalesPrepaymentPct."Item No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Prepayment VAT Amount field's editable property on Statistics Page through page Handler(SalesOrderStatisticsHandlerNM).
        LibraryLowerPermissions.SetOutsideO365Scope();
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('VATSalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesOrderVATAmtStatisticsNM()
    var
        SalesLine: Record "Sales Line";
        SalesPrepmtAccount: Code[20];
    begin
        // Check VAT Amount on Prepayment Tab with Sales Order Statistics Page after Create Sales Order.

        // Setup: Create Setup for Sales Prepayment %.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        SalesPrepmtAccount := SetupForSalesPrepayment(SalesLine);

        // Exercise: Calculate VAT Amount and Assign in Global Variable.
        VATAmount := SalesLine."Line Amount" * SalesLine."VAT %" / 100;

        // Verify: Open Sales Order Statistics Page and Verify VAT Amount field through Page Handler(VATSalesOrderStatisticsHandlerNM).
        LibraryLowerPermissions.SetOutsideO365Scope();
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // Tear Down.
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtInvoiceWithCurrencyAndVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocumentNo: Code[20];
        SalesPrepmtAccount: Code[20];
        PrepaymentAmount: Decimal;
        Amount: Decimal;
    begin
        // Check GL Entry for VAT Amount after Posting Prepayment Sales Invoice with Currency.

        // Setup: Create Purchase Order and Update Purchase Prepayment Account in general Posting setup.
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        CreateSalesDocument(SalesLine, CreateCurrencyWithExchangeRate());
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(
            CreateGLAccount(SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group"),
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        PrepaymentAmount := Round((SalesLine."Amount Including VAT" - SalesLine.Amount) * SalesLine."Prepayment %" / 100);
        Amount :=
          Round(
            LibraryERM.ConvertCurrency(PrepaymentAmount, SalesHeader."Currency Code", '', SalesHeader."Posting Date"));
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");

        // Exercise: Post Sales Prepayment Invoice.
        LibraryLowerPermissions.SetSalesDocsPost();
        SalesPostPrepayments.Invoice(SalesHeader);

        // Verify: Verify VAT Amount in G/L Entry.
        VerifyGLEntryWithAmount(DocumentNo, VATPostingSetup."Sales VAT Account", -Amount);

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateSalesPrepmtAccount(SalesPrepmtAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryAfterPostPrepmtCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        PostedCreditMemoNo: Code[20];
        UnrealizedAmount: Decimal;
        UnrealizedBase: Decimal;
        OldSalesPrepaymentsAccount: Code[20];
    begin
        // Check VAT Entry after posting Prepayment Credit Memo.

        // Setup: Update VAT Posting Setup for Unrealized VAT and Create Sales Order with Prepayment %.
        Initialize();
        UpdateGeneralLedgerSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        OldSalesPrepaymentsAccount := SetupForUnrealVAT(SalesLine, VATPostingSetup);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        PostedCreditMemoNo := GetPostedDocumentNo(SalesHeader."Prepmt. Cr. Memo No. Series");
        UnrealizedBase := Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100);
        UnrealizedAmount := Round((SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100) * (VATPostingSetup."VAT %" / 100));
        LibraryLowerPermissions.SetSalesDocsPost();
        SalesPostPrepayments.Invoice(SalesHeader);

        // Exercise: Post Sales Prepayment Credit Memo.
        SalesPostPrepayments.CreditMemo(SalesHeader);

        // Verify: Verify VAT Entry.
        VerifyVATEntry(PostedCreditMemoNo, UnrealizedBase, UnrealizedAmount);

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type", VATPostingSetup."Sales VAT Unreal. Account");
        UpdateSalesPrepmtAccount(OldSalesPrepaymentsAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryAfterPostPrepmtInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        PostedInvoiceNo: Code[20];
        UnrealizedAmount: Decimal;
        UnrealizedBase: Decimal;
        OldSalesPrepaymentsAccount: Code[20];
    begin
        // Check VAT Entry after posting Prepayment Invoice.

        // Setup: Update VAT Posting Setup for Unrealized VAT and Create Sales Order with Prepayment %.
        Initialize();
        UpdateGeneralLedgerSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldSalesPrepaymentsAccount := SetupForUnrealVAT(SalesLine, VATPostingSetup);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        PostedInvoiceNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");
        UnrealizedBase := Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100);
        UnrealizedAmount := Round((SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100) * (VATPostingSetup."VAT %" / 100));
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        // Exercise.
        LibraryLowerPermissions.SetSalesDocsPost();
        SalesPostPrepayments.Invoice(SalesHeader);

        // Verify: Verify VAT Entry.
        VerifyVATEntry(PostedInvoiceNo, -UnrealizedBase, -UnrealizedAmount);

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type", VATPostingSetup."Sales VAT Unreal. Account");
        UpdateSalesPrepmtAccount(OldSalesPrepaymentsAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSecondPrepaymentInvoiceForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        DocumentType: Option Invoice,"Credit Memo",Statistic;
        TempDecToHaveItEqual: Decimal;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 379850] Prepayment Invoice should be posted if one line of Purchase Invoice has amount to be posted and the last line has not

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        VATPostingSetup.SetRange("VAT Bus. Posting Group", SalesHeader."VAT Bus. Posting Group");
        VATPostingSetup.SetRange("VAT Prod. Posting Group", '');
        if not VATPostingSetup.FindFirst() then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", '');
        TempDecToHaveItEqual := LibraryRandom.RandDec(100, 2);
        CreateSalesLineWithPrepmtAmts(SalesHeader, TempDecToHaveItEqual, TempDecToHaveItEqual);
        CreateSalesLineWithPrepmtAmts(SalesHeader, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDecInRange(101, 200, 2));
        TempDecToHaveItEqual := LibraryRandom.RandDec(100, 2);
        CreateSalesLineWithPrepmtAmts(SalesHeader, TempDecToHaveItEqual, TempDecToHaveItEqual);

        Assert.IsTrue(SalesPostPrepayments.CheckOpenPrepaymentLines(SalesHeader, DocumentType::Invoice), NoAmtFoundToBePostedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectPostedPrePmtInvoiceThrowsError()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // Create Sales Document with prepayments and post
        Initialize();
        DocumentNo := CreateAndPostSalesDocument();

        // Exercise
        LibraryLowerPermissions.SetSalesDocsPost();
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoKey(DocumentNo);
        asserterror PostedSalesInvoice.CorrectInvoice.Invoke();

        // Verify
        Assert.ExpectedError(CheckPrepaymentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPostedPrePmtInvoiceThrowsError()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // Create Sales Document with prepayments and post
        Initialize();
        DocumentNo := CreateAndPostSalesDocument();

        // Exercise
        LibraryLowerPermissions.SetSalesDocsPost();
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoKey(DocumentNo);
        asserterror PostedSalesInvoice.CancelInvoice.Invoke();

        // Verify
        Assert.ExpectedError(CheckPrepaymentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCorrectiveCreditMemoOnPostedPrePmtInvoiceThrowsError()
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Corrective Credit Memo] [Sales]
        // Create Sales Document with prepayments and post
        Initialize();
        DocumentNo := CreateAndPostSalesDocument();

        // Exercise
        LibraryLowerPermissions.SetSalesDocsPost();
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.GotoKey(DocumentNo);
        asserterror PostedSalesInvoice.CreateCreditMemo.Invoke();

        // Verify
        Assert.ExpectedError(CheckPrepaymentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPrepmtPostError()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasePrepaymentPct: Record "Purchase Prepayment %";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 251876] System throws error "You cannot post the document of type Oder with the number 1001 before all related prepayment invoices are fully posted and paid."
        // [SCENARIO 251876] when unposted prepayment blocks posting of purchase order with No. = 1001

        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchasePrepaymentPct(PurchasePrepaymentPct, CreateVendor('', VATPostingSetup."VAT Bus. Posting Group"));

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, PurchasePrepaymentPct."Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, PurchasePrepaymentPct."Item No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Modify(true);

        LibraryLowerPermissions.SetOutsideO365Scope();
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        asserterror PurchaseOrder.Post.Invoke();

        Assert.ExpectedError(StrSubstNo(PrepaymentInvoicesNotPaidErr, PurchaseHeader."Document Type", PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure VATEntryAfterUnapplyPayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        OldSalesPrepaymentsAccount: Code[20];
    begin
        // [FEATURE] [Sales] [Unapply] [Unrealized VAT] [VAT Entry] [G/L Entry - VAT Entry Link]
        // [SCENARIO 303619] VAT Entry created on Unapply Payment for Prepayment Invoice has "G/L Entry - VAT Entry Link" record
        Initialize();
        LibraryLowerPermissions.SetO365Setup();
        LibraryLowerPermissions.AddSalesDocsPost();
        UpdateGeneralLedgerSetup(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Sales Order with posted Prepayment Invoice "PPI01"
        OldSalesPrepaymentsAccount := SetupForUnrealVAT(SalesLine, VATPostingSetup);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        FindVATEntriesForDocument(VATEntry, VATEntry."Document Type"::Invoice, DocumentNo);
        VerifyGLEntryVATEntryLink(VATEntry."Entry No.");

        // [GIVEN] Payment Journal Line "PAY01" applied to "PPI01" created and posted
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Payment,
          CreateAndPostPaymentEntry("Gen. Journal Account Type"::Customer, SalesHeader."Sell-to Customer No."));
        FindVATEntriesForDocument(VATEntry, VATEntry."Document Type"::Payment, CustLedgerEntry."Document No.");
        VerifyGLEntryVATEntryLink(VATEntry."Entry No.");

        // [WHEN] Unapply Customer Ledger Entry for "PAY01"
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);

        // [THEN] "G/L Account No." on the second VAT Entry for "PAY01" is not empty
        VATEntry.Next();
        VerifyGLEntryVATEntryLink(VATEntry."Entry No.");

        // Tear Down.
        LibraryLowerPermissions.SetOutsideO365Scope();
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type", VATPostingSetup."Sales VAT Unreal. Account");
        UpdateSalesPrepmtAccount(OldSalesPrepaymentsAccount, SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    [Test]
    procedure PurchasePrepmtVATMoreThanDocVAT_TotalEquals_OneLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 382286] Post prepayment invoice with prepayment VAT% more than document VAT%, but equal total amounts
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Purchase order with one line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 88% (prepayment VAT % = 25)
        // [GIVEN] Document total = 1000 + 100 = 1100, prepayment total = 1000 * 88% * 125% = 1100
        CreatePurchasePrepmtSetup(LineGLAccount, 10);
        CreatePurchaseHeader(PurchaseHeader, LineGLAccount);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineGLAccount."No.", 1, 1000, 88);
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", DuplicateVATSetup(LineGLAccount, 25));

        // [WHEN] Post prepayment invoice
        DocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Prepayment has been posted
        VerifyPurchasePostedInvoiceAmounts(DocumentNo, 880, 1100);
    end;

    [Test]
    procedure PurchasePrepmtVATMoreThanDocVAT_TotalEquals_TwoLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 382286] Post prepayment invoice with prepayment VAT% more than document VAT%, but equal total amounts (two lines)
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Purchase order with first line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 88% (prepayment VAT % = 25)
        // [GIVEN] And second line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 0%
        // [GIVEN] Document total = 2000 + 200 = 2200 (first line 1100), prepayment total = 1000 * 88% * 125% = 1100
        CreatePurchasePrepmtSetup(LineGLAccount, 10);
        CreatePurchaseHeader(PurchaseHeader, LineGLAccount);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineGLAccount."No.", 1, 1000, 88);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineGLAccount."No.", 1, 1000, 0);
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", DuplicateVATSetup(LineGLAccount, 25));

        // [WHEN] Post prepayment invoice
        DocumentNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Prepayment has been posted
        VerifyPurchasePostedInvoiceAmounts(DocumentNo, 880, 1100);
    end;

    [Test]
    procedure PurchasePrepmtVATMoreThanDocVAT_Error_OneLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        PrepmtTotalInclVAT: Decimal;
        DocumentTotalInclVAT: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 382286] Try post prepayment invoice with prepayment VAT% more than document VAT%,
        // [SCENARIO 382286] in case of total prepayment more than total document amount by one cent
        Initialize();
        PrepmtTotalInclVAT := 1100.01;
        DocumentTotalInclVAT := 1100.00;
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Purchase order with one line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 88.0004% (prepayment VAT % = 25)
        // [GIVEN] Document total = 1000 + 100 = 1100, prepayment total = 1000 * 88.0005% * 125% = 1100.01
        CreatePurchasePrepmtSetup(LineGLAccount, 10);
        CreatePurchaseHeader(PurchaseHeader, LineGLAccount);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineGLAccount."No.", 1, 1000, 88.0005);
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", DuplicateVATSetup(LineGLAccount, 25));

        // [WHEN] Post prepayment invoice
        asserterror LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Prepayment has been posted
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PrepaymentAmountHigherThanTheOrderErr,
            Abs(PrepmtTotalInclVAT), Abs(DocumentTotalInclVAT), Abs(PrepmtTotalInclVAT) - Abs(DocumentTotalInclVAT)));
    end;

    [Test]
    procedure PurchasePrepmtVATMoreThanDocVAT_Error_TwoLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineGLAccount: Record "G/L Account";
        PrepmtTotalInclVAT: Decimal;
        DocumentTotalInclVAT: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 382286] Try post prepayment invoice with prepayment VAT% more than document VAT%,
        // [SCENARIO 382286] in case of total prepayment more than total document amount by one cent (two lines)
        Initialize();
        PrepmtTotalInclVAT := 1100.01;
        DocumentTotalInclVAT := 1100.00;
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Purchase order with first line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 88.0004% (prepayment VAT % = 25)
        // [GIVEN] And second line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 0%
        // [GIVEN] Document total = 2000 + 200 = 2200 (first line 1100), prepayment total = 1000 * 88.0005% * 125% = 1100.01
        CreatePurchasePrepmtSetup(LineGLAccount, 10);
        CreatePurchaseHeader(PurchaseHeader, LineGLAccount);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineGLAccount."No.", 1, 1000, 88.0005);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, LineGLAccount."No.", 1, 1000, 0);
        LibraryERM.UpdatePurchPrepmtAccountVATGroup(
            PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group", DuplicateVATSetup(LineGLAccount, 25));

        // [WHEN] Post prepayment invoice
        asserterror LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] Prepayment has been posted
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PrepaymentAmountHigherThanTheOrderErr,
            Abs(PrepmtTotalInclVAT), Abs(DocumentTotalInclVAT), Abs(PrepmtTotalInclVAT) - Abs(DocumentTotalInclVAT)));
    end;

    [Test]
    procedure SalesPrepmtVATMoreThanDocVAT_TotalEquals_OneLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 382286] Post sales prepayment invoice with prepayment VAT% more than document VAT%, but equal total amounts
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Sales order with one line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 88% (prepayment VAT % = 25)
        // [GIVEN] Document total = 1000 + 100 = 1100, prepayment total = 1000 * 88% * 125% = 1100
        CreateSalesPrepmtSetup(LineGLAccount, 10);
        CreateSalesHeader(SalesHeader, LineGLAccount);
        CreateSalesLine(SalesHeader, SalesLine, LineGLAccount."No.", 1, 1000, 88);
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", DuplicateVATSetup(LineGLAccount, 25));

        // [WHEN] Post prepayment invoice
        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Prepayment has been posted
        VerifySalesPostedInvoiceAmounts(DocumentNo, 880, 1100);
    end;

    [Test]
    procedure SalesPrepmtVATMoreThanDocVAT_TotalEquals_TwoLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 382286] Post sales prepayment invoice with prepayment VAT% more than document VAT%, but equal total amounts (two lines)
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Sales order with first line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 88% (prepayment VAT % = 25)
        // [GIVEN] And second line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 0%
        // [GIVEN] Document total = 2000 + 200 = 2200 (first line 1100), prepayment total = 1000 * 88% * 125% = 1100
        CreateSalesPrepmtSetup(LineGLAccount, 10);
        CreateSalesHeader(SalesHeader, LineGLAccount);
        CreateSalesLine(SalesHeader, SalesLine, LineGLAccount."No.", 1, 1000, 88);
        CreateSalesLine(SalesHeader, SalesLine, LineGLAccount."No.", 1, 1000, 0);
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", DuplicateVATSetup(LineGLAccount, 25));

        // [WHEN] Post prepayment invoice
        DocumentNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Prepayment has been posted
        VerifySalesPostedInvoiceAmounts(DocumentNo, 880, 1100);
    end;

    [Test]
    procedure SalesPrepmtVATMoreThanDocVAT_Error_OneLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        PrepmtTotalInclVAT: Decimal;
        DocumentTotalInclVAT: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 382286] Try post sales prepayment invoice with prepayment VAT% more than document VAT%,
        // [SCENARIO 382286] in case of total prepayment more than total document amount by one cent
        Initialize();
        PrepmtTotalInclVAT := 1100.01;
        DocumentTotalInclVAT := 1100.00;
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Sales order with one line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 88.0005% (prepayment VAT % = 25)
        // [GIVEN] Document total = 1000 + 100 = 1100, prepayment total = 1000 * 88.0005% * 125% = 1100.01
        CreateSalesPrepmtSetup(LineGLAccount, 10);
        CreateSalesHeader(SalesHeader, LineGLAccount);
        CreateSalesLine(SalesHeader, SalesLine, LineGLAccount."No.", 1, 1000, 88.0005);
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", DuplicateVATSetup(LineGLAccount, 25));

        // [WHEN] Post prepayment invoice
        asserterror LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Prepayment has been posted
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PrepaymentAmountHigherThanTheOrderErr,
            Abs(PrepmtTotalInclVAT), Abs(DocumentTotalInclVAT), Abs(PrepmtTotalInclVAT) - Abs(DocumentTotalInclVAT)));
    end;

    [Test]
    procedure SalesPrepmtVATMoreThanDocVAT_Error_TwoLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
        PrepmtTotalInclVAT: Decimal;
        DocumentTotalInclVAT: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 382286] Try post sales prepayment invoice with prepayment VAT% more than document VAT%,
        // [SCENARIO 382286] in case of total prepayment more than total document amount by one cent (two lines)
        Initialize();
        PrepmtTotalInclVAT := 1100.01;
        DocumentTotalInclVAT := 1100.00;
        LibraryLowerPermissions.SetO365BusFull();

        // [GIVEN] Sales order with first line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 88.0005% (prepayment VAT % = 25)
        // [GIVEN] And second line having Qty = 1, Unit Price = 1000, VAT setup = "X" (10 %), prepayment 0%
        // [GIVEN] Document total = 2000 + 200 = 2200 (first line 1100), prepayment total = 1000 * 88.0005% * 125% = 1100.01
        CreateSalesPrepmtSetup(LineGLAccount, 10);
        CreateSalesHeader(SalesHeader, LineGLAccount);
        CreateSalesLine(SalesHeader, SalesLine, LineGLAccount."No.", 1, 1000, 88.0005);
        CreateSalesLine(SalesHeader, SalesLine, LineGLAccount."No.", 1, 1000, 0);
        LibraryERM.UpdateSalesPrepmtAccountVATGroup(
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group", DuplicateVATSetup(LineGLAccount, 25));

        // [WHEN] Post prepayment invoice
        asserterror LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Prepayment has been posted
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PrepaymentAmountHigherThanTheOrderErr,
            Abs(PrepmtTotalInclVAT), Abs(DocumentTotalInclVAT), Abs(PrepmtTotalInclVAT) - Abs(DocumentTotalInclVAT)));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prepayment III");
        Clear(VATAmount);
        Clear(PrepmtAmountPct);
        Clear(PrepaymentVATAmount);
        Clear(PrepaymentTotalAmount);
        Clear(PrepaymentAmount);
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prepayment III");

        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        DisableGST(false);
        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prepayment III");
    end;

    local procedure ApplyCustomerLedgerEntries(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, DocumentType2, DocumentNo2);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CalculateGainOrLossAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]) Amount: Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        GLEntry.FindSet();
        repeat
            Amount += GLEntry.Amount;
        until GLEntry.Next() = 0;
    end;

    local procedure CreateAndModifyExchangeRate(CurrencyCode: Code[10])
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
    begin
        // Take random value to calculate Starting Date and 1D Required for modifing Starting Date by 1 Day.
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
        LibraryERM.CreateExchRate(
          CurrencyExchangeRate2, CurrencyExchangeRate."Currency Code", CalcDate('<1D>', CurrencyExchangeRate."Starting Date"));

        // Multiplying by 2 to make sure that new Exchange Rate is greater than existing Exchange Rate.
        ModifyCurrencyExchangeRate(
          CurrencyExchangeRate2, 2 * CurrencyExchangeRate."Exchange Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure CreateAndModifySalesHeader(var SalesHeader: Record "Sales Header"; SelltoCustomerNo: Code[20]; PrepaymentPct: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SelltoCustomerNo);
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Modify(true);
    end;

    local procedure CreateAndModifySalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        ModifyUnitPriceOnSalesLine(SalesLine, UnitPrice);
    end;

    local procedure CreateAndPostPaymentEntry(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // Create General Line and Apply Posted Prepayment Invoice.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, 0);
        GeneralJournal.OpenEdit();
        GeneralJournal.FILTER.SetFilter("Document No.", GenJournalLine."Document No.");
        GeneralJournal."Apply Entries".Invoke();

        // Post General line.
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Take Random value for Exchange Rate Amount.
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        ModifyCurrencyExchangeRate(CurrencyExchangeRate, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCurrency(CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateGLAccWithBusPostingGroup(var GLAccount: Record "G/L Account"; GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GLAccount.Get(CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"));
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify();
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Using Random for Quantity, Direct Unit Cost and Prepayment %.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(CurrencyCode, VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Prepayment VAT %", PurchaseLine."VAT %");
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; LineGLAccount: Record "G/L Account")
    var
        VendorNo: Code[20];
    begin
        VendorNo :=
            LibraryPurchase.CreateVendorWithBusPostingGroups(
                LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
    end;

    local procedure CreatePurchaseLine(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LineGLAccountNo: Code[20]; Qty: Decimal; UnitCost: Decimal; PrepmtPct: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LineGLAccountNo, Qty);
        PurchaseLine.Validate("Direct Unit Cost", UnitCost);
        PurchaseLine.Validate("Prepayment %", PrepmtPct);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Using Random for Quantity and Direct Unit Cost.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateAndModifySalesHeader(SalesHeader,
          CreateCustomerWithCurrency(CurrencyCode, VATPostingSetup."VAT Bus. Posting Group"), LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Prepayment VAT %", SalesLine."VAT %");
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithPremtSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line") SalesPrepmtAccount: Code[20]
    var
        GLAccount: Record "G/L Account";
        Resource: Record Resource;
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        LibraryResource: Codeunit "Library - Resource";
    begin
        // Setup: Create Sales Header with Random Prepayment %.
        // To set Gen. Product Posting Group with Non-blank Def. VAT Prod. Posting Group on G/L Account.
        FindPostingSetupWithNonBlankVATPostingGroup(GeneralPostingSetup, VATPostingSetup);
        CreateGLAccWithBusPostingGroup(GLAccount, GeneralPostingSetup, VATPostingSetup);

        LibraryResource.CreateResource(Resource, GLAccount."VAT Bus. Posting Group");
        Resource.Validate("Gen. Prod. Posting Group", GLAccount."Gen. Prod. Posting Group");
        Resource.Modify(true);
        CreateAndModifySalesHeader(SalesHeader, CreateCustomer(), LibraryRandom.RandDec(10, 2));

        // Exercise: Create Sales Line with G/L Account,Resource with Random Values.
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", LibraryRandom.RandDec(100, 2),
          LibraryRandom.RandDec(10, 2));
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", SalesLine."Unit Price", SalesLine.Quantity);
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(SalesLine."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; LineGLAccount: Record "G/L Account")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo :=
            LibrarySales.CreateCustomerWithBusPostingGroups(
                LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineGLAccountNo: Code[20]; Qty: Decimal; UnitPrice: Decimal; PrepmtPct: Decimal)
    begin
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccountNo, Qty);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Prepayment %", PrepmtPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithPrepmtAmts(var SalesHeader: Record "Sales Header"; PrepmtLineAmount: Decimal; PrepmtAmtInv: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
        SalesLine."Prepmt. Line Amount" := PrepmtLineAmount;
        SalesLine."Prepmt. Amt. Inv." := PrepmtAmtInv;
        SalesLine.Modify();
    end;

    local procedure CreateSalesPrepaymentPct(var SalesPrepaymentPct: Record "Sales Prepayment %"; CustomerNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Take Random Prepayment %.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesPrepaymentPct(
          SalesPrepaymentPct, SalesPrepaymentPct."Sales Type"::Customer, CustomerNo, LibraryInventory.CreateItemNo(), WorkDate());
        SalesPrepaymentPct.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesPrepaymentPct.Modify(true);
    end;

    local procedure CreatePurchasePrepaymentPct(var PurchasePrepaymentPct: Record "Purchase Prepayment %"; VendorNo: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Take Random Prepayment %.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchasePrepaymentPct(
          PurchasePrepaymentPct, LibraryInventory.CreateItemNo(), VendorNo, WorkDate());
        PurchasePrepaymentPct.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        PurchasePrepaymentPct.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument() DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        CreateSalesDocumentWithPremtSetup(SalesHeader, SalesLine);
        DocumentNo := GetPostedDocumentNo(SalesHeader."Prepayment No. Series");
        SalesPostPrepayments.Invoice(SalesHeader);
        Commit();
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        // Create Vendor with Currency.
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchasePrepmtSetup(var LineGLAccount: Record "G/L Account"; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryPurchase.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateSalesPrepmtSetup(var LineGLAccount: Record "G/L Account"; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Modify(true);
    end;

    local procedure DuplicateVATSetup(LineGLAccount: Record "G/L Account"; VATPct: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        VATPostingSetup.Get(LineGLAccount."VAT Bus. Posting Group", LineGLAccount."VAT Prod. Posting Group");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup.Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Insert();
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure DisableGST(DisableGST: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Enable GST (Australia)", DisableGST);
        GLSetup.Validate("Full GST on Prepayment", DisableGST);
        GLSetup.Validate("GST Report", DisableGST);
        GLSetup.Validate("Adjustment Mandatory", DisableGST);
        GLSetup.Modify(true);
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
    end;

    local procedure FindPostingSetupWithNonBlankVATPostingGroup(var GeneralPostingSetup: Record "General Posting Setup"; var VATPostingSetup: Record "VAT Posting Setup")
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        // To set Gen. Product Posting Group with Non-blank Def. VAT Prod. Posting Group on G/L Account.
        GenProductPostingGroup.SetFilter("Def. VAT Prod. Posting Group", '<>%1', '');
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);

        VATProductPostingGroup.SetRange(Code, GenProductPostingGroup."Def. VAT Prod. Posting Group");
        LibraryERM.FindVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup.SetRange("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
    end;

    local procedure FindSalesLinePrepaymentPct(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]) TotalPrepaymentPct: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo);
        repeat
            TotalPrepaymentPct += Round(SalesLine."Line Amount" * SalesLine."Prepayment %" / 100);
        until SalesLine.Next() = 0;
    end;

    local procedure FindVATEntriesForDocument(var VATEntry: Record "VAT Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
    end;

    local procedure GetPostedDocumentNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    local procedure ModifyCrMemoNoOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyCurrencyExchangeRate(CurrencyExchangeRate: Record "Currency Exchange Rate"; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure ModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Posting Date", CalcDate('<1D>', PurchaseHeader."Posting Date"));  // 1D Required for modifing Posting Date by 1 Day.
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No." + Format(LibraryRandom.RandInt(10)));
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyPostingDateSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Posting Date", CalcDate('<1D>', SalesHeader."Posting Date"));  // 1D Required for modifing Posting Date by 1 Day.
        SalesHeader.Modify(true);
    end;

    local procedure ModifySalesLinePrepaymentPct(var SalesLine: Record "Sales Line"; PrepaymentPct: Decimal)
    begin
        SalesLine.Validate("Prepayment %", PrepaymentPct);
        SalesLine.Modify(true);
    end;

    local procedure ModifyUnitPriceOnSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        // Taken Random value for Unit Price in Sales Line.
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenSalesOrderStatistics(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Statistics.Invoke();
    end;
#endif
    local procedure OpenSalesOrderStatisticsNM(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesOrderStatistics.Invoke();
    end;

    local procedure PostedPrepmtInvNosInPurchaseSetup(PostedPrepmtInvNos: Code[20]) PostedPrepmtInvNosOld: Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PostedPrepmtInvNosOld := PurchasesPayablesSetup."Posted Prepmt. Inv. Nos.";
        PurchasesPayablesSetup.Validate("Posted Prepmt. Inv. Nos.", PostedPrepmtInvNos);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure SetupForSalesPrepayment(var SalesLine: Record "Sales Line") SalesPrepmtAccount: Code[20]
    var
        GLAccount: Record "G/L Account";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // Create Sales Order with Random Quantity.
        CreateSalesPrepaymentPct(SalesPrepaymentPct, CreateCustomer());
        CreateSalesOrder(SalesLine, SalesPrepaymentPct."Sales Code", SalesPrepaymentPct."Item No.", LibraryRandom.RandDec(10, 2));
        ModifyUnitPriceOnSalesLine(SalesLine, LibraryRandom.RandDec(100, 2));
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        SalesPrepmtAccount :=
          UpdateSalesPrepmtAccount(GLAccount."No.", SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        SalesLine.Validate("Prepayment %");
        SalesLine.Modify(true);
    end;

    local procedure SetupForUnrealVAT(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup") OldSalesPrepaymentsAccount: Code[20]
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
    begin
        // Set Prepayment Unrealized VAT in General Ledger Setup. Update Sales VAT Unreal. Account in VAT Posting Setup. Create Customer with 'Apply to Oldest' and create Item. Update Sales Prepayment Account in General Posting Setup.
        // Create Sales Order with Random values.
        LibraryERM.CreateGLAccount(GLAccount);
        UpdateVATPostingSetup(VATPostingSetup, VATPostingSetup."Unrealized VAT Type"::Percentage, GLAccount."No.");
        Customer.Get(CreateCustomerWithCurrency('', VATPostingSetup."VAT Bus. Posting Group"));
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Modify(true);
        CreateAndModifySalesHeader(SalesHeader, Customer."No.", LibraryRandom.RandDec(10, 2));
        CreateAndModifySalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(100, 2), 100 + LibraryRandom.RandDec(100, 2));  // Using large value.
        SalesLine.Validate("Prepayment VAT %", VATPostingSetup."VAT %");
        SalesLine.Modify(true);
        OldSalesPrepaymentsAccount :=
          UpdateSalesPrepmtAccount(
            CreateGLAccount(SalesLine."Gen. Prod. Posting Group", SalesLine."VAT Prod. Posting Group"),
            SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
    end;

    local procedure UpdateGeneralLedgerSetup(PrepaymentUnrealizedVAT: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Prepayment Unrealized VAT", PrepaymentUnrealizedVAT);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdatePurchasePrepmtAccount(PurchPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldPurchPrepaymentsAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldPurchPrepaymentsAccount := GeneralPostingSetup."Purch. Prepayments Account";
        GeneralPostingSetup."Purch. Prepayments Account" := PurchPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesPrepmtAccount(SalesPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldSalesPrepaymentsAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldSalesPrepaymentsAccount := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup."Sales Prepayments Account" := SalesPrepaymentsAccount;
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"; UnrealizedVATType: Option; SalesVATUnrealAccount: Code[20])
    begin
        VATPostingSetup.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", UnrealizedVATType);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", SalesVATUnrealAccount);
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyGLEntry(CurrencyCode: Code[10]; Amount: Decimal; DocumentNo: Code[20]; GLAccountNo: Code[20])
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
    begin
        Currency.Get(CurrencyCode);
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryWithAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        GLEntry.SetRange(Amount, Amount);
        GLEntry.FindFirst();
    end;

    local procedure VerifyPrepaymentInvoice(PrepaymentOrderNo: Code[20]; PostedPrepmtInvNos: Code[20])
    var
        NoSeriesLine: Record "No. Series Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        NoSeriesLine.SetRange("Series Code", PostedPrepmtInvNos);
        NoSeriesLine.FindFirst();
        PurchInvHeader.SetRange("Prepayment Order No.", PrepaymentOrderNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.TestField("No.", NoSeriesLine."Last No. Used");
    end;

    local procedure VerifySalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; PrepaymentAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo);
        repeat
            Assert.AreNearlyEqual(
              Round(PrepaymentAmount / 2), SalesLine."Prepmt. Line Amount", LibraryERM.GetAmountRoundingPrecision(),
              StrSubstNo(AmountError, SalesLine.FieldCaption("Prepmt. Line Amount"), Round(PrepaymentAmount / 2), SalesLine.TableCaption()));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesLineForPrepaymentValues(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        repeat
            SalesLine.TestField("Prepmt. Line Amount", Round(SalesLine."Line Amount" * SalesHeader."Prepayment %" / 100));
            SalesLine.TestField("Prepayment %", SalesHeader."Prepayment %");
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; UnrealizedBase: Decimal; UnrealizedAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          UnrealizedAmount, VATEntry."Unrealized Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption("Unrealized Amount"), UnrealizedAmount, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(
          UnrealizedBase, VATEntry."Unrealized Base", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption("Unrealized Base"), UnrealizedBase, VATEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryVATEntryLink(VATEntryNo: Integer)
    var
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
    begin
        GLEntryVATEntryLink.SetRange("VAT Entry No.", VATEntryNo);
        Assert.RecordIsNotEmpty(GLEntryVATEntryLink);
    end;

    local procedure VerifyPurchasePostedInvoiceAmounts(DocumentNo: Code[20]; Amount: Decimal; AmountInclVAT: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        PurchInvHeader.TestField(Amount, Amount);
        PurchInvHeader.TestField("Amount Including VAT", AmountInclVAT);
    end;

    local procedure VerifySalesPostedInvoiceAmounts(DocumentNo: Code[20]; Amount: Decimal; AmountInclVAT: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvoiceHeader.TestField(Amount, Amount);
        SalesInvoiceHeader.TestField("Amount Including VAT", AmountInclVAT);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ExplodeBomHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Take 1 for "Retrieve dimensions from components".
        Choice := 1;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        Assert.IsTrue(SalesOrderStatistics.PrepmtTotalAmount.Editable(), 'Prepayment Total Amount field must be editable.');
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPrepmtFieldsStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        SalesOrderStatistics.PrepmtTotalAmount.SetValue(PrepaymentAmount);
        SalesOrderStatistics.PrepmtVATAmount.AssertEquals(PrepaymentVATAmount);
        SalesOrderStatistics.PrepmtTotalAmount2.AssertEquals(Format(PrepaymentTotalAmount, 0, '<Precision,2><Standard Format,0>'));
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPrepmtInvPctHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        SalesOrderStatistics.PrepmtInvPct.AssertEquals(Format(PrepmtAmountPct, 0, 1) + '%');
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPrepmtTotalAmountHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        SalesOrderStatistics.PrepmtTotalAmount.SetValue(PrepaymentAmount);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        Assert.IsTrue(SalesOrderStatistics.PrepmtTotalAmount.Editable(), 'Prepayment Total Amount field must be editable.');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesPrepmtFieldsStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        SalesOrderStatistics.PrepmtTotalAmount.SetValue(PrepaymentAmount);
        SalesOrderStatistics.PrepmtVATAmount.AssertEquals(PrepaymentVATAmount);
        SalesOrderStatistics.PrepmtTotalAmount2.AssertEquals(Format(PrepaymentTotalAmount, 0, '<Precision,2><Standard Format,0>'));
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPrepmtInvPctHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        SalesOrderStatistics.PrepmtInvPct.AssertEquals(Format(PrepmtAmountPct, 0, 1) + '%');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPrepmtTotalAmountHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        SalesOrderStatistics.PrepmtTotalAmount.SetValue(PrepaymentAmount);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UpdateExchRateConfirmHandler(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATSalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.VATAmount.AssertEquals(VATAmount);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure VATSalesOrderStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatistics.VATAmount.AssertEquals(VATAmount);
    end;
}