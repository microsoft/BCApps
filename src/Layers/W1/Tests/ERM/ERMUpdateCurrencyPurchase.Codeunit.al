codeunit 134086 "ERM Update Currency - Purchase"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FCY] [Purchase]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ERMUpdateCurrencyPurchase: Codeunit "ERM Update Currency - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        isInitialized: Boolean;
        PostingDateMessageText: Text[1024];
        UnknownError: Label 'Unknown error.';
        PostingDateMessage: Label 'Do you want to update the exchange rate?';
        PurchaseHeaderError: Label '%1 %2 must be deleted.';
        SuggestVendorPaymentText: Text[1024];
        AmountError: Label '%1 must be %2 in %3.';
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        IncorrectValueErr: Label 'Incorrect value %1 for field %2.';
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        ChangeCurrencyMsg: Label 'The %1 in the %2 will be changed from %3 to %4.\\Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure UpdateCurrencyOnCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check that Direct Unit Cost and Line Amount of Purchase Line get updated as per Currency Exchange Rates.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Purchase Credit Memo and new Currency with Exchange rate.
        CreatePurchaseDocument(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::"Credit Memo");

        // 3. Verify: Verify Purchase Line Direct Unit Cost and Line Amount updated as per Currency.
        VerifyPurchaseDocumentValues(
          PurchaseHeader, CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeCurrencyOnCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check that Direct Unit Cost and Line Amount of Purchase Line get updated after changing Currency as per new
        // Currency Exchange Rates.

        // 1. Setup: Create Purchase Credit Memo and new Currency with Exchange rate.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::"Credit Memo");

        // 2. Exercise: Create New Currency with Exchange Rate and Validate Purchase Header.
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        UpdateCurrencyOnPurchaseHeader(PurchaseHeader, CurrencyExchangeRate."Currency Code");

        // 3. Verify: Verify Purchase Line Direct Unit Cost and Line Amount updated as per Currency.
        VerifyPurchaseDocumentValues(
          PurchaseHeader, CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ChangePostingDateOnCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check While changing Posting Date, Application generates a message to update Exchange Rate.

        Initialize();
        CreateDocumentExchangeRate(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::"Credit Memo");

        // 3. Verify: Message occurs while changing Posting Date.
        Assert.AreEqual(StrSubstNo(PostingDateMessage), PostingDateMessageText, UnknownError);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ModifyAmountOnCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check after changing Posting Date, Direct Unit Cost and Line Amount of Purchase Line get updated as per new Exchange Rate.

        Initialize();
        CreateDocumentExchangeRate(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::"Credit Memo");
        UpdatePurchaseLines(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // 3. Verify: Verify Purchase Line Direct Unit Cost and Line Amount updated as per new Exchange Rate.
        VerifyPurchaseDocumentValues(
          PurchaseHeader, CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeCurrencyOnQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check after changing Currency in Purchase Quote, Currency Factor get updated.

        // 1. Setup: Create Purchase Quote and new Currency with Exchange rate.
        Initialize();
        CreatePurchaseHeader(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::Quote);

        // 2. Exercise: Create new Currency with Exchange rate and update Purchase Header.
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        UpdateCurrencyOnPurchaseHeader(PurchaseHeader, CurrencyExchangeRate."Currency Code");

        // 3. Verify: Verify Purchase Header Currency Factor get updated as per new Currency.
        PurchaseHeader.TestField("Currency Factor", CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyAmountOnQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check after changing Currency in Purchase Quote, Direct Unit Cost and Line Amount of Purchase Line get updated as
        // per new Currency.

        // 1. Setup: Create Purchase Quote and new Currency with Exchange rate.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::Quote);

        // 2. Exercise: Create new Currency with Exchange rate and update Purchase Header.
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        UpdateCurrencyOnPurchaseHeader(PurchaseHeader, CurrencyExchangeRate."Currency Code");
        UpdatePurchaseLines(PurchaseHeader."Document Type", PurchaseHeader."No.");

        // 3. Verify: Verify Purchase Line Direct Unit Cost and Line Amount updated as per Currency.
        VerifyPurchaseDocumentValues(
          PurchaseHeader, CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyVendWithCurrencyOnOrder()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PurchHeader: Record "Purchase Header";
    begin
        Initialize();

        CreateOrderWithLCY(PurchHeader);
        ValidateVendWithFCYOnOrder(CurrencyExchangeRate, PurchHeader);

        PurchHeader.TestField("Currency Factor", CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FlowCurrencyOnCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Credit Memo get updated with Vendor Currency Code.
        CheckCurrencyOnHeader(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FlowCurrencyOnInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Invoice get updated with Vendor Currency Code.
        CheckCurrencyOnHeader(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FlowCurrencyOnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Order get updated with Vendor Currency Code.
        CheckCurrencyOnHeader(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FlowCurrencyOnQuote()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Quote get updated with Vendor Currency Code.
        CheckCurrencyOnHeader(PurchaseHeader."Document Type"::Quote);
    end;

    local procedure CheckCurrencyOnHeader(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // 1. Setup:
        Initialize();

        // 2. Exercise: Create new Currency, Vendor, Purchase Document and update with Currency.
        Vendor.Get(CreateVendorUpdateCurrency(CurrencyExchangeRate));
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");

        // 3. Verify: Verify Purchase Document Currency Code match with Vendor Currency Code.
        PurchaseHeader.TestField("Currency Code", Vendor."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCurrencyOnVendor()
    var
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VendorNo: Code[20];
    begin
        // Check Vendor get updated with Currency Code.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create new Currency and update Customer.
        VendorNo := CreateVendorUpdateCurrency(CurrencyExchangeRate);

        // 3. Verify: Verify Customer updated with new Currency Code.
        Vendor.Get(VendorNo);
        Vendor.TestField("Currency Code", CurrencyExchangeRate."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Header Deleted.

        // 1. Setup: Create Purchase Header.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // 2. Exercise: Delete Purchase Header.
        PurchaseHeader.Delete(true);

        // 3. Verify: Verify Purchase Header deleted.
        Assert.IsFalse(
          PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No."),
          StrSubstNo(PurchaseHeaderError, PurchaseHeader.TableCaption(), PurchaseHeader."No."));
    end;

    [Test]
    [HandlerFunctions('CreditMemoConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostCreditMemoWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check after Posting Purchase Credit Memo, Currency flow in Vendor Ledger Entry.

        // 1. Setup: Create Purchase Credit Memo and new Currency with Exchange rate.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::"Credit Memo");
        UpdateVendorCreditMemoNo(PurchaseHeader);

        // 2. Exercise: Post Purchase Credit Memo.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        ExecuteUIHandler();

        // 3. Verify: Verify Currency flow in Vendor Ledger Entry.
        VerifyLedgerPurchaseCreditMemo(PurchaseHeader."No.", CurrencyExchangeRate."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostInvoiceWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check after Posting Purchase Invoice, Currency flow in Vendor Ledger Entry.
        Initialize();
        PostDocumentWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, false, true);

        // 3. Verify: Verify Currency flow in Vendor Ledger Entry.
        VerifyLedgerPurchaseInvoice(PurchaseHeader."No.", PurchaseHeader."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOderWithCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check after Posting Purchase Order, Currency flow in Vendor Ledger Entry.
        Initialize();
        PostDocumentWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Order, true, true);

        // 3. Verify: Verify Currency flow in Vendor Ledger Entry.
        VerifyLedgerPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Currency Code");
    end;

    local procedure PostDocumentWithCurrency(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; Ship: Boolean; Invoice: Boolean)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // 1. Setup: Create Purchase Document and new Currency with Exchange rate.
        CreatePurchaseDocument(PurchaseHeader, CurrencyExchangeRate, DocumentType);
        UpdateVendorInvoiceNo(PurchaseHeader);

        // 2. Exercise: Post Purchase Credit Memo.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Ship, Invoice);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure ExchRateAdjustmentWithVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VendorNo: Code[20];
    begin
        // Check that after Modify Relational Exch. Rate Amount and run Adjust Exchange rate batch job, GL entry and
        // Detailed Vendor Ledger Entry created with Correct Amount.

        // 1. Setup: Create and Post General Journal Line for Vendor, make Currency with Exchange Rate and modify.
        Initialize();
        BindSubscription(ERMUpdateCurrencyPurchase);
        VendorNo := CreateVendorUpdateCurrency(CurrencyExchangeRate);
        CreateAndPostGenJournalLine(GenJournalLine, VendorNo, CurrencyExchangeRate);
        UpdateExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run Exch. Rate Adjustment batch job.
        RunExchRateAdjustment(CurrencyExchangeRate);
        UnbindSubscription(ERMUpdateCurrencyPurchase);

        // 3. Verify: Verify G/L Entry and Detailed Vendor Ledger Entry made for correct Amount after running
        // Adjust Exchange Rate Batch Job
        VerifyGLEntryAdjustExchange(GenJournalLine, CurrencyExchangeRate);
        VerifyDetailedVendorLedgEntry(GenJournalLine, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaymentWithManualCheck()
    begin
        // Create and Post General Journal Lines and Suggest Vendor Payments with Manual Check.
        SetupVendorPayment("Bank Payment Type"::"Manual Check");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure VendorPaymentWithComputerCheck()
    begin
        // Create and Post General Journal Lines and Suggest Vendor Payments with Computer Check.
        SetupVendorPayment("Bank Payment Type"::"Computer Check");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnPurchQuotePage()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        PurchaseQuotePage: TestPage "Purchase Quote";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.FindCurrency(Currency);
        PurchaseQuotePage.OpenEdit();
        PurchaseQuotePage.New();
        PurchaseQuotePage."Buy-from Vendor Name".Value(Vendor."No.");
        PurchaseQuotePage.PurchLines.Type.Value(Format(PurchaseLine.Type::"G/L Account"));
        PurchaseQuotePage.PurchLines."No.".Value(GLAccount."No.");
        PurchaseQuotePage.PurchLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        PurchaseQuotePage."Currency Code".Value(Currency.Code);
        DocumentNo := PurchaseQuotePage."No.".Value();
        PurchaseQuotePage.Close();

        VerifyCurrencyInPurchaseLine(PurchaseLine."Document Type"::Quote, DocumentNo, GLAccount."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnPurchOrderPage()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        PurchaseOrderPage: TestPage "Purchase Order";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.FindCurrency(Currency);
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.New();
        PurchaseOrderPage."Buy-from Vendor Name".Value(Vendor."No.");
        PurchaseOrderPage.PurchLines.Type.Value(Format(PurchaseLine.Type::"G/L Account"));
        PurchaseOrderPage.PurchLines."No.".Value(GLAccount."No.");
        PurchaseOrderPage.PurchLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        PurchaseOrderPage."Currency Code".Value(Currency.Code);
        DocumentNo := PurchaseOrderPage."No.".Value();
        PurchaseOrderPage.Close();

        VerifyCurrencyInPurchaseLine(PurchaseLine."Document Type"::Order, DocumentNo, GLAccount."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnPurchInvoicePage()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.FindCurrency(Currency);
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.New();
        PurchaseInvoicePage."Buy-from Vendor Name".Value(Vendor.Name);
        PurchaseInvoicePage.PurchLines.Type.Value(Format(PurchaseLine.Type::"G/L Account"));
        PurchaseInvoicePage.PurchLines."No.".Value(GLAccount."No.");
        PurchaseInvoicePage.PurchLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        PurchaseInvoicePage."Currency Code".Value(Currency.Code);
        DocumentNo := PurchaseInvoicePage."No.".Value();
        PurchaseInvoicePage.Close();

        VerifyCurrencyInPurchaseLine(PurchaseLine."Document Type"::Invoice, DocumentNo, GLAccount."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnPurchCrMemoPage()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        PurchaseCrMemoPage: TestPage "Purchase Credit Memo";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.FindCurrency(Currency);
        PurchaseCrMemoPage.OpenEdit();
        PurchaseCrMemoPage.New();
        PurchaseCrMemoPage."Buy-from Vendor Name".SetValue(Vendor.Name);
        PurchaseCrMemoPage.PurchLines.Type.Value(Format(PurchaseLine.Type::"G/L Account"));
        PurchaseCrMemoPage.PurchLines."No.".Value(GLAccount."No.");
        PurchaseCrMemoPage.PurchLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        PurchaseCrMemoPage."Currency Code".Value(Currency.Code);
        DocumentNo := PurchaseCrMemoPage."No.".Value();
        PurchaseCrMemoPage.Close();

        VerifyCurrencyInPurchaseLine(PurchaseLine."Document Type"::"Credit Memo", DocumentNo, GLAccount."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnBlanketPurchOrderPage()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        BlanketPurchOrderPage: TestPage "Blanket Purchase Order";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.FindCurrency(Currency);
        BlanketPurchOrderPage.OpenEdit();
        BlanketPurchOrderPage.New();
        BlanketPurchOrderPage."Buy-from Vendor Name".Value(Vendor."No.");
        BlanketPurchOrderPage.PurchLines.Type.Value(Format(PurchaseLine.Type::"G/L Account"));
        BlanketPurchOrderPage.PurchLines."No.".Value(GLAccount."No.");
        BlanketPurchOrderPage.PurchLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        BlanketPurchOrderPage."Currency Code".Value(Currency.Code);
        DocumentNo := BlanketPurchOrderPage."No.".Value();
        BlanketPurchOrderPage.Close();

        VerifyCurrencyInPurchaseLine(PurchaseLine."Document Type"::"Blanket Order", DocumentNo, GLAccount."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnPurchReturnOrderPage()
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        Currency: Record Currency;
        PurchReturnOrderPage: TestPage "Purchase Return Order";
        DocumentNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.FindGLAccount(GLAccount);
        LibraryERM.FindCurrency(Currency);
        PurchReturnOrderPage.OpenEdit();
        PurchReturnOrderPage.New();
        PurchReturnOrderPage."Buy-from Vendor Name".Value(Vendor."No.");
        PurchReturnOrderPage.PurchLines.Type.Value(Format(PurchaseLine.Type::"G/L Account"));
        PurchReturnOrderPage.PurchLines."No.".Value(GLAccount."No.");
        PurchReturnOrderPage.PurchLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        PurchReturnOrderPage."Currency Code".Value(Currency.Code);
        DocumentNo := PurchReturnOrderPage."No.".Value();
        PurchReturnOrderPage.Close();

        VerifyCurrencyInPurchaseLine(PurchaseLine."Document Type"::"Return Order", DocumentNo, GLAccount."No.", Currency.Code);
    end;

    local procedure SetupVendorPayment(CheckType: Enum "Bank Payment Type")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        BankAccountNo: Code[20];
    begin
        // 1. Setup: Create Currency, Bank Account, Vendor and General Journal Lines and Post.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        BankAccountNo := CreateBankAccount(CurrencyExchangeRate."Currency Code");
        CreateGeneralLines(GenJournalLine, CreateVendor(CurrencyExchangeRate."Currency Code"));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Report Suggest Vendor Payment.
        SuggestVendorPayment(GenJournalLine."Account No.", BankAccountNo, CheckType);

        // 3. Verify: Message Appears for Suggest Vendor Payment.
        BankAccount.Get(BankAccountNo);
        Assert.AreNotEqual(0, StrPos(SuggestVendorPaymentText, BankAccount."Currency Code"), UnknownError);
    end;

    [Test]
    [HandlerFunctions('MsgConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnGenJournalLine()
    var
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PostedDocumentNo: Code[20];
        ExpectedMsg: Text;
    begin
        // [FEATURE] [UI] [Journal] [Application]
        // [SCENARIO 230918] Stan fill "Applies-to Doc. No." of Gen. Journal Line with a Posted Document Number. When a confirm message about a Currency Code update appears, it contains correct Currency Codes.
        Initialize();

        // [GIVEN] Posted Purchase Invoice with "Currency Code" = "C1"
        CreatePurchaseDocument(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::Invoice);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Vendor is updated with "Currency Code" = "C2".
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Vendor.Modify(true);

        // [GIVEN] Create Gen. Journal Line for the Vendor with zero Amount and empty "Account No.".
        CreateGeneralJournalLine(GenJournalLine, '');
        GenJournalLine.Validate(Amount, 0);

        // [WHEN] Fill "Applies-to Doc. No." with the Posted Purchase Invoice No.
        ExpectedMsg :=
          StrSubstNo(
            ChangeCurrencyMsg,
            GenJournalLine.FieldCaption("Currency Code"),
            GenJournalLine.TableCaption(),
            GenJournalLine.GetShowCurrencyCode(Vendor."Currency Code"),
            GenJournalLine.GetShowCurrencyCode(PurchaseHeader."Currency Code"));
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocumentNo);

        // [THEN] Confirm message appeared: "The Currency Code will be changed from C2 to C1".
        Assert.ExpectedMessage(ExpectedMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExchRateAdjustmentWithPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        VendorInvNo: Code[35];
    begin
        // [SCENARIO: 494354] When Exch. Rate Adjustment (596, Report Request) is run with Dimension Posting option "Source Entry Dimensions" and 
        // entries are posted to G/L, the Global dimensions are not updated in G/L table, although the Dimension Set ID is added correctly

        // [GIVEN] Setup: Create and Post General Journal Line for Vendor, make Currency with Exchange Rate and modify.
        Initialize();
        VendorInvNo := LibraryRandom.RandText(35);

        BindSubscription(ERMUpdateCurrencyPurchase);

        // [GIVEN] Create and Post Purchase Invoice with "Currency Code" = "C1"
        CreatePurchaseDocument(PurchaseHeader, CurrencyExchangeRate, PurchaseHeader."Document Type"::Invoice);
        UpdatePurchaseInvoice(PurchaseHeader, VendorInvNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [GIVEN] Update Currency Exchange Rate
        UpdateExchangeAndAdjustmentRateAmounts(CurrencyExchangeRate);

        // [THEN] Run Exch. Rate Adjustment batch job.
        RunExchRateAdjustmentReport(CurrencyExchangeRate);
        UnbindSubscription(ERMUpdateCurrencyPurchase);

        // [VERIFY] Verify: Global Dimension on G/L Entry or available after running Exch. Rate Adjustment Report
        VerifyGlobalDimensionOnGLEntryAdjustExchange(VendorInvNo, CurrencyExchangeRate."Currency Code");
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        // Lazy Setup.
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();
    end;

    local procedure RunExchRateAdjustment(CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyExchangeRate."Currency Code");
        Clear(ExchRateAdjustment);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.InitializeRequest2(
          CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Starting Date", 'Test', CurrencyExchangeRate."Starting Date",
          CurrencyExchangeRate."Currency Code", true, false);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.Run();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentType: Enum "Purchase Document Type")
    begin
        CreatePurchaseHeader(PurchaseHeader, CurrencyExchangeRate, DocumentType);
        CreatePurchaseLines(PurchaseHeader);
    end;

    local procedure CreateOrderWithLCY(var PurchHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, CreateVendor(''));
        CreatePurchaseLines(PurchHeader);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentType: Enum "Purchase Document Type")
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        UpdateCurrencyOnPurchaseHeader(PurchaseHeader, CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreatePurchaseLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Counter: Integer;
    begin
        // Create Multiple lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(9) do
            // Required Random Value for Quantity field.
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        CreateExchangeRate(CurrencyExchangeRate, Currency.Code, NormalDate(LibraryFiscalYear.GetInitialPostingDate()));
    end;

    local procedure CreateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; StartingDate: Date)
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);

        // Using Random Exchange Rate Amount and Adjustment Exchange Rate.
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exch. Rate Amount and Relational Adjmt Exch Rate Amt always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", LibraryRandom.RandDec(100, 2) + CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2)); // Use Random Value for Last Direct Cost field.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    [Normal]
    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    [Normal]
    local procedure CreateGeneralLines(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        Counter: Integer;
    begin
        // Create 2 to 10 Gen. Journal Lines Boundary 2 is important to test Suggest Vendor Payment for multiple lines.
        for Counter := 1 to 2 * LibraryRandom.RandInt(5) do
            CreateGeneralJournalLine(GenJournalLine, VendorNo);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CreateGeneralJournalLine(GenJournalLine, VendorNo);
        GenJournalLine.Validate("Posting Date", CurrencyExchangeRate."Starting Date");
        GenJournalLine.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        // Required Random Value for Amount field value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, VendorNo, -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate(
          "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", FindGLAccount());
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateVendorUpdateCurrency(var CurrencyExchangeRate: Record "Currency Exchange Rate"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateDocumentExchangeRate(var PurchaseHeader: Record "Purchase Header"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentType: Enum "Purchase Document Type")
    begin
        // 1. Setup: Create Purchase Document and new Currency with Exchange Rate.
        CreatePurchaseHeader(PurchaseHeader, CurrencyExchangeRate, DocumentType);
        CreatePurchaseLines(PurchaseHeader);

        // 2. Exercise: Create new Exchange Rate for Currency with different Starting Date.
        CreateExchangeRate(
          CurrencyExchangeRate,
          CurrencyExchangeRate."Currency Code",
          CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', CurrencyExchangeRate."Starting Date"));
        UpdatePostingDate(PurchaseHeader, CurrencyExchangeRate."Starting Date");
    end;

    local procedure FindGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        exit(LibraryERM.FindDirectPostingGLAccount(GLAccount));
    end;

    local procedure FindPurchaseLines(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
    end;

    [Normal]
    local procedure SuggestVendorPayment(VendorNo: Code[20]; BankAccountNo: Code[20]; BankPmtType: Enum "Bank Payment Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        Clear(SuggestVendorPayments);
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        Vendor.SetRange("No.", VendorNo);
        SuggestVendorPayments.SetTableView(Vendor);
        // Required Random Value for "Document No." field value is not important.
        SuggestVendorPayments.InitializeRequest(
          WorkDate(), false, 0, false, WorkDate(), VendorNo, true, "Gen. Journal Account Type"::"Bank Account", BankAccountNo, BankPmtType);
        SuggestVendorPayments.UseRequestPage(false);
        Commit();
        SuggestVendorPayments.Run();
    end;

    local procedure UpdateCurrencyOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    begin
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Quote then
            PurchaseHeader."Posting Date" := PurchaseHeader."Document Date";
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePostingDate(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    begin
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseLines(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        ItemNo: code[20];
    begin
        FindPurchaseLines(PurchaseLine, DocumentType, DocumentNo);
        repeat
            ItemNo := PurchaseLine."No.";
            PurchaseLine."No." := '';
            PurchaseLine.Validate("No.", ItemNo);
            PurchaseLine.Validate("Line Discount %", 0);
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + LibraryRandom.RandInt(4));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVendorCreditMemoNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CalcCurrencyFactor(CurrencyExchangeRate: Record "Currency Exchange Rate"): Decimal
    begin
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure ValidateVendWithFCYOnOrder(var CurrencyExchangeRate: Record "Currency Exchange Rate"; var PurchHeader: Record "Purchase Header")
    var
        PurchOrder: TestPage "Purchase Order";
    begin
        PurchOrder.OpenEdit();
        PurchOrder.GotoRecord(PurchHeader);
        PurchOrder."Buy-from Vendor Name".SetValue(CreateVendorUpdateCurrency(CurrencyExchangeRate));
        PurchOrder.Close();
        PurchHeader.Find();
    end;

    local procedure VerifyPurchaseDocumentValues(PurchaseHeader: Record "Purchase Header"; CurrencyFactor: Decimal)
    begin
        PurchaseHeader.TestField("Currency Factor", CurrencyFactor);
        VerifyPurchaseLineValues(PurchaseHeader);
    end;

    local procedure VerifyPurchaseLineValues(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Currency: Record Currency;
    begin
        // Replace TESTFIELD with AssertNealyEqual to fix GDL Failures.
        Currency.Get(PurchaseHeader."Currency Code");
        Currency.InitRoundingPrecision();
        FindPurchaseLines(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        repeat
            Item.Get(PurchaseLine."No.");
            Assert.AreNearlyEqual(
              PurchaseLine."Direct Unit Cost", Item."Last Direct Cost" * PurchaseHeader."Currency Factor",
              Currency."Unit-Amount Rounding Precision",
              StrSubstNo(
                AmountError, PurchaseLine.FieldCaption("Direct Unit Cost"),
                Item."Last Direct Cost" * PurchaseHeader."Currency Factor", PurchaseLine.TableCaption()));
            PurchaseLine.TestField(
              "Line Amount", Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost", Currency."Amount Rounding Precision"));
        until PurchaseLine.Next() = 0;
    end;

    local procedure VerifyLedgerPurchaseCreditMemo(PreAssignedNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchCrMemoHdr.FindFirst();
        VerifyVendorLedgerEntry(PurchCrMemoHdr."No.", CurrencyCode);
    end;

    local procedure VerifyLedgerPurchaseInvoice(PreAssignedNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        PurchInvHeader.FindFirst();
        VerifyVendorLedgerEntry(PurchInvHeader."No.", CurrencyCode);
    end;

    local procedure VerifyLedgerPurchaseOrder(OrderNo: Code[20]; CurrencyCode: Code[10])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
        VerifyVendorLedgerEntry(PurchInvHeader."No.", CurrencyCode);
    end;

    [Normal]
    local procedure VerifyGLEntryAdjustExchange(GenJournalLine: Record "Gen. Journal Line"; CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyExchangeRate."Currency Code");
        Currency.InitRoundingPrecision();
        GLEntry.SetRange("Document No.", CurrencyExchangeRate."Currency Code");
        GLEntry.SetFilter(Amount, '<0');
        GLEntry.FindFirst();
        GLEntry.TestField(
          Amount, Round(
            GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" /
            CurrencyExchangeRate."Exchange Rate Amount" - GenJournalLine."Amount (LCY)", Currency."Amount Rounding Precision"));
    end;

    local procedure VerifyVendorLedgerEntry(DocumentNo: Code[20]; CurrencyCode: Code[10])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyDetailedVendorLedgEntry(GenJournalLine: Record "Gen. Journal Line"; CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        Currency.Get(CurrencyExchangeRate."Currency Code");
        Currency.InitRoundingPrecision();
        DetailedVendorLedgEntry.SetRange("Document No.", CurrencyExchangeRate."Currency Code");
        DetailedVendorLedgEntry.FindFirst();
        DetailedVendorLedgEntry.TestField(
          "Amount (LCY)", Round(
            GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" /
            CurrencyExchangeRate."Exchange Rate Amount" - GenJournalLine."Amount (LCY)", Currency."Amount Rounding Precision"));
    end;

    local procedure VerifyCurrencyInPurchaseLine(DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; No: Code[20]; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        Assert.AreEqual(No, PurchaseLine."No.",
          StrSubstNo(IncorrectValueErr, PurchaseLine."No.", PurchaseLine.FieldCaption("No.")));
        Assert.AreEqual(CurrencyCode, PurchaseLine."Currency Code",
          StrSubstNo(IncorrectValueErr, PurchaseLine."Currency Code", PurchaseLine.FieldCaption("Currency Code")));
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    local procedure RunExchRateAdjustmentReport(CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        Currency.SetRange(Code, CurrencyExchangeRate."Currency Code");
        Clear(ExchRateAdjustment);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.InitializeRequest2(
            0D, WorkDate(), LibraryRandom.RandText(10), WorkDate(),
            CurrencyExchangeRate."Currency Code", true, false);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.Run();
    end;

    local procedure UpdatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; VendorInvNo: Code[35])
    var
        DimensionValue: Record "Dimension Value";
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvNo);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue);
        PurchaseHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue);
        PurchaseHeader.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateExchangeAndAdjustmentRateAmounts(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRate.Validate("Exchange Rate Amount", CurrencyExchangeRate."Exchange Rate Amount" + LibraryRandom.RandInt(2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure VerifyGlobalDimensionOnGLEntryAdjustExchange(VendorInvNo: Code[35]; CurrencyCode: Code[10])
    var
        GLEntry: Record "G/L Entry";
        GLEntry2: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", CurrencyCode);
        GLEntry.FindFirst();
        GLEntry2.SetRange("External Document No.", VendorInvNo);
        GLEntry2.FindFirst();

        Assert.AreEqual(GLEntry."Global Dimension 1 Code", GLEntry2."Global Dimension 1 Code", '');
        Assert.AreEqual(GLEntry."Global Dimension 2 Code", GLEntry2."Global Dimension 2 Code", '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        Result := true;
        PostingDateMessageText := ConfirmMessage; // Set global variable.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreditMemoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just for Handle the Message.
        SuggestVendorPaymentText := Message; // Set global variable.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ExchRateWasAdjustedTxt, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure MsgConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
        LibraryVariableStorage.Enqueue(Question);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Run Handler", 'OnBeforeRunVendExchRateAdjustment', '', false, false)]
    local procedure RunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempVendorLedgerEntry: Record "Vendor Ledger Entry" temporary; var IsHandled: Boolean)
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
    begin
        ExchRateAdjmtProcess.AdjustExchRateVend(GenJnlLine, TempVendorLedgerEntry);
        IsHandled := true;
    end;
}

