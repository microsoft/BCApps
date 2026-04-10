codeunit 134087 "ERM Update Currency - Sales"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [FCY] [Sales]
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryResource: Codeunit "Library - Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJob: Codeunit "Library - Job";
        ERMUpdateCurrencySales: Codeunit "ERM Update Currency - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        isInitialized: Boolean;
        AmountError: Label '%1 must be %2 in \\%3 %4=%5.';
        UnitPriceError: Label '%1 must be %2 in %3.';
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';
        IncorrectValueErr: Label 'Incorrect value %1 for field %2.';
        ExchRateWasAdjustedTxt: Label 'One or more currency exchange rates have been adjusted.';
        ChangeCurrencyMsg: Label 'The %1 in the %2 will be changed from %3 to %4.\\Do you want to continue?';
        CannotUpdateLCYCodeErr: Label 'You cannot update the local currency code because there are posted general ledger entries.';

    [Test]
    [HandlerFunctions('CurrencyExchangeRateSendNotificationHandler')]
    [Scope('OnPrem')]
    procedure ModifyPostingDateOnInvoice()
    var
        SalesHeader: Record "Sales Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyDate: Date;
    begin
        // Check after changing Posting Date, Application generates a confirm dialog if Exchange Rate does not exist and opens page 483.

        // 1. Setup: Create Sales Invoice and new Currency with Exchange Rate.
        Initialize();
        CreateSalesDocument(SalesHeader, CurrencyExchangeRate, SalesHeader."Document Type"::Invoice);

        // 2. Exercise: Modify Posting Date with a date lesser that Existing Starting Date of Exchange Rate.
        SalesHeader.SetHideValidationDialog(true);
        CurrencyDate := CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', CurrencyExchangeRate."Starting Date");

        SalesHeader.Validate("Posting Date", CurrencyDate);

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyAmountOnInvoice()
    var
        SalesHeader: Record "Sales Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        NewStartingDate: Date;
    begin
        // Check after changing Posting Date, Unit Price and Line Amount of Sales Line get updated as per new Exchange Rate.

        // 1. Setup: Create Sales Invoice and new Currency with Exchange Rate.
        Initialize();
        CreateSalesDocument(SalesHeader, CurrencyExchangeRate, SalesHeader."Document Type"::Invoice);

        // 2. Exercise: Create new Exchange Rate for Currency with different Starting Date.
        NewStartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', CurrencyExchangeRate."Starting Date");
        CreateExchangeRate(CurrencyExchangeRate, CurrencyExchangeRate."Currency Code", NewStartingDate);
        UpdatePostingDateSalesHeader(SalesHeader, NewStartingDate);
        UpdateSalesLines(SalesHeader."Document Type", SalesHeader."No.");

        // 3. Verify: Verify Sales Line Unit Price and Line Amount updated as per new Exchange Rate.
        VerifySalesDocumentValues(
          SalesHeader, CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyCurrencyCreditMemoHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check after changing Currency in Sales Credit Memo, Currency Factor get updated.
        ChangeCurrencyOnHeader(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyCurrencyInvoiceHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check after changing Currency in Sales Invoice, Currency Factor get updated.
        ChangeCurrencyOnHeader(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyCurrencyOrderHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check after changing Currency in Sales Order, Currency Factor get updated.
        ChangeCurrencyOnHeader(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyCurrencyQuoteHeader()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check after changing Currency in Sales Quote, Currency Factor get updated.
        ChangeCurrencyOnHeader(SalesHeader."Document Type"::Quote);
    end;

    local procedure ChangeCurrencyOnHeader(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // 1. Setup: Create Sales Document and new Currency with Exchange rate.
        Initialize();
        CreateSalesHeaderWithCurrency(SalesHeader, CurrencyExchangeRate, DocumentType);

        // 2. Exercise: Create new Currency with Exchange rate and update Sales Header.
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        UpdateCurrencyOnSalesHeader(SalesHeader, CurrencyExchangeRate."Currency Code");

        // 3. Verify: Verify Sales Header Currency Factor get updated as per new Currency.
        SalesHeader.TestField("Currency Factor", CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyCurrencyCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check after changing Currency in Sales Credit Memo, Unit Price and Line Amount of Sales Line get updated as per
        // new Currency.
        ChangeCurrencyOnDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyCurrencyInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check after changing Currency in Sales Invoice, Unit Price and Line Amount of Sales Line get updated as
        // per new Currency.
        ChangeCurrencyOnDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyCurrencyOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check after changing Currency in Sales Order, Unit Price and Line Amount of Sales Line get updated as
        // per new Currency.
        ChangeCurrencyOnDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyCurrencyQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check after changing Currency in Sales Quote, Unit Price and Line Amount of Sales Line get updated as
        // per new Currency.
        ChangeCurrencyOnDocument(SalesHeader."Document Type"::Quote);
    end;

    local procedure ChangeCurrencyOnDocument(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // 1. Setup: Create Sales Document and new Currency with Exchange rate.
        Initialize();
        CreateSalesDocument(SalesHeader, CurrencyExchangeRate, DocumentType);

        // 2. Exercise: Create new Currency with Exchange rate and update Sales Header and Line.
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        UpdateCurrencyOnSalesHeader(SalesHeader, CurrencyExchangeRate."Currency Code");
        UpdateSalesLines(SalesHeader."Document Type", SalesHeader."No.");

        // 3. Verify: Verify Sales Line Unit Price and Line Amount updated as per Currency.
        VerifySalesDocumentValues(
          SalesHeader, CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ModifyCustWithCurrencyOnOrder()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
    begin
        Initialize();

        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        CreateOrderWithLCY(SalesHeader);
        ValidateCustWithFCYOnOrder(CurrencyExchangeRate, SalesHeader);

        SalesHeader.TestField("Currency Factor", CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FlowCurrencyOnCreditMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check Sales Credit Memo get updated with Customer Currency Code.
        CheckCurrencyOnHeader(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FlowCurrencyOnInvoice()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check Sales Invoice get updated with Customer Currency Code.
        CheckCurrencyOnHeader(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FlowCurrencyOnOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check Sales Order get updated with Customer Currency Code.
        CheckCurrencyOnHeader(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FlowCurrencyOnQuote()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check Sales Quote get updated with Customer Currency Code.
        CheckCurrencyOnHeader(SalesHeader."Document Type"::Quote);
    end;

    local procedure CheckCurrencyOnHeader(DocumentType: Enum "Sales Document Type")
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
    begin
        // 1. Setup:
        Initialize();

        // 2. Exercise: Create new Currency, Customer, Sales Document and update with Currency.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomerWithCurrencyExchangeRate(CurrencyExchangeRate));

        // 3. Verify: Verify Sales Document Currency Code match with Customer Currency Code.
        SalesHeader.TestField("Currency Code", CurrencyExchangeRate."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckCurrencyOnCustomer()
    var
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustomerNo: Code[20];
    begin
        // Check Customer get updated with Currency Code.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create new Currency and update Customer.
        CustomerNo := CreateCustomerWithCurrencyExchangeRate(CurrencyExchangeRate);

        // 3. Verify: Verify Customer updated with new Currency Code.
        Customer.Get(CustomerNo);
        Customer.TestField("Currency Code", CurrencyExchangeRate."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountWithRelationalCurrency()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Check General Journal Line Amount(LCY) get updated with Base Currency Exchange Rate and Relational Currency Exchange Rate.

        // 1. Setup: Create Currency with Exchange rate, Create another Currency with two Exchange rates and assign first Currency as
        // Relational Currency.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate2);
        ModifyCurrency(CurrencyExchangeRate, CurrencyExchangeRate2);

        // 2. Exercise: Create General Journal Line with Customer and second Currency.
        // Required Random Value for Amount.
        CustomerNo := CreateCustomerWithCurrency('');
        CreateGeneralJournalLine(
          GenJournalLine, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate2."Currency Code", CustomerNo,
          LibraryRandom.RandDec(100, 2), GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer);

        // 3. Verify: Verify Amount(LCY) updated as per Currency Exchange Rate.
        VerifyGenJournalAmount(
          GenJournalLine, CurrencyExchangeRate2,
          LibraryERM.ConvertCurrency(GenJournalLine.Amount, CurrencyExchangeRate."Currency Code", '', CurrencyExchangeRate."Starting Date"),
          CurrencyExchangeRate."Starting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountExceptRelationalCurrency()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyExchangeRate2: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerNo: Code[20];
    begin
        // Check General Journal Line Amount(LCY) get updated with Base Currency Exchange Rate.

        // 1. Setup: Create Currency with Exchange rate, Create another Currency with two Exchange rates and assign first Currency as
        // Relational Currency.
        Initialize();
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate2);
        ModifyCurrency(CurrencyExchangeRate, CurrencyExchangeRate2);

        // 2. Exercise: Create General Journal Line with Customer and second Currency.
        // Required Random Value for Amount.
        CustomerNo := CreateCustomerWithCurrency('');
        CreateGeneralJournalLine(
          GenJournalLine, CurrencyExchangeRate2."Starting Date", CurrencyExchangeRate2."Currency Code", CustomerNo,
          LibraryRandom.RandDec(100, 2), GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer);

        // 3. Verify: Verify Amount(LCY) updated as per Currency Exchange Rate.
        VerifyGenJournalAmount(GenJournalLine, CurrencyExchangeRate2, GenJournalLine.Amount, CurrencyExchangeRate2."Starting Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndPostInvoice()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        PostedSaleInvoiceNo: Code[20];
    begin
        // Check Currency Code and Currency Factor posted properly in Posted Sales Invoice.

        // 1. Setup: Create Customer and Currency with Exchange rate.
        Initialize();
        CustomerNo := CreateCustomerWithCurrencyExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Create Sales Invoice and Post.
        PostedSaleInvoiceNo := CreateAndPostSalesInvoice(SalesHeader, CustomerNo);

        // 3. Verify: Verify Currency flow on Posted Sales Invoice.
        VerifySalesInvoiceCurrency(PostedSaleInvoiceNo, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('ApplyEntryPageHandler')]
    [Scope('OnPrem')]
    procedure PostJournalLineWithInvoice()
    var
        SalesHeader: Record "Sales Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalLine: Record "Gen. Journal Line";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Check Amount posted correctly as per Currency Exchange Rate from Invoice to GL Entry.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Customer, Currency, Sales Invoice, Post and Apply.
        PostedSaleInvoiceNo := CreateAndPostSalesInvoice(SalesHeader, CreateCustomerWithCurrencyExchangeRate(CurrencyExchangeRate));
        // Passing Amount Zero as it will update after Apply Entry.
        CreateGeneralJournalLine(
          GenJournalLine, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code", SalesHeader."Sell-to Customer No.", 0,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer);
        ApplyInvoice(GenJournalLine, PostedSaleInvoiceNo, SalesHeader."Document Type"::Invoice);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Amount Posted correctly on GL Entry.
        VerifyGLEntry(
          CurrencyExchangeRate, GenJournalLine."Document No.", LibraryERM.ConvertCurrency(
            GenJournalLine.Amount, CurrencyExchangeRate."Currency Code", '', CurrencyExchangeRate."Starting Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndCheckCurrency()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Create New Currency with Exchange rate.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create new Currency with Exchange rate.
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        // 3. Verify: Verify that correct Currency created.
        Currency.Get(CurrencyExchangeRate."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndCheckCustomerCurrency()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustomerNo: Code[20];
    begin
        // Create New Currency with Exchange rate and Customer.

        // 1. Setup:
        Initialize();

        // 2. Exercise:  Create Customer and Currency with Exchange rate.
        CustomerNo := CreateCustomerWithCurrencyExchangeRate(CurrencyExchangeRate);

        // 3. Verify: Verify that correct Currency and Customer created.
        Currency.Get(CurrencyExchangeRate."Currency Code");
        Customer.Get(CustomerNo);
        Customer.TestField("Currency Code", CurrencyExchangeRate."Currency Code");
    end;

    [Test]
    [HandlerFunctions('CreditMemoConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostCreditMemoWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Check after Posting Sales Credit Memo, Currency flow in Customer Ledger Entry.
        Initialize();
        DocumentNo := PostDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::"Credit Memo", false, true);

        // 3. Verify: Verify Currency flow in Customer Ledger Entry.
        VerifyCustomerLedgerEntry(DocumentNo, SalesHeader."Currency Code");
    end;

    [Test]
    [HandlerFunctions('CreditMemoConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostInvoiceWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Check after Posting Sales Invoice, Currency flow in Customer Ledger Entry.
        Initialize();
        DocumentNo := PostDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Invoice, false, true);

        // 3. Verify: Verify Currency flow in Customer Ledger Entry.
        VerifyCustomerLedgerEntry(DocumentNo, SalesHeader."Currency Code");
    end;

    [Test]
    [HandlerFunctions('CreditMemoConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostOrderWithCurrency()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Check after Posting Sales Order, Currency flow in Customer Ledger Entry.
        Initialize();
        DocumentNo := PostDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Order, true, true);

        // 3. Verify: Verify Currency flow in Customer Ledger Entry.
        VerifyCustomerLedgerEntry(DocumentNo, SalesHeader."Currency Code");
    end;

    local procedure PostDocumentWithCurrency(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Ship: Boolean; Invoice: Boolean) DocumentNo: Code[20]
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // 1. Setup: Create Sales Document and new Currency with Exchange rate.
        CreateSalesDocument(SalesHeader, CurrencyExchangeRate, DocumentType);

        // 2. Exercise: Post Sales Credit Memo.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, Ship, Invoice);
        ExecuteUIHandler();
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure ExchRateAdjustmentOrder()
    var
        SalesHeader: Record "Sales Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        OldRelationalExchangeRate: Decimal;
    begin
        // Check that after Modify Relational Exch. Rate Amount and run Adjust Exchange rate batch job, GL entry created
        // with Correct Amount in Sales Order.
        Initialize();
        BindSubscription(ERMUpdateCurrencySales);
        OldRelationalExchangeRate := ExchRateAdjustmentDocument(SalesHeader, CurrencyExchangeRate, SalesHeader."Document Type"::Order);
        UnbindSubscription(ERMUpdateCurrencySales);

        // 3. Verify: Verify G/L Entry made for correct Amount after running Adjust Exchange Rate Batch Job.
        VerifyGLEntryForOrder(CurrencyExchangeRate, SalesHeader."No.", OldRelationalExchangeRate);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure ExchRateAdjustmentInvoice()
    var
        SalesHeader: Record "Sales Header";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        OldRelationalExchangeRate: Decimal;
    begin
        // Check that after Modify Relational Exch. Rate Amount and run Adjust Exchange rate batch job, GL entry created
        // with Correct Amount in Sales Invoice.
        Initialize();
        OldRelationalExchangeRate := ExchRateAdjustmentDocument(SalesHeader, CurrencyExchangeRate, SalesHeader."Document Type"::Invoice);

        // 3. Verify: Verify G/L Entry made for correct Amount after running Adjust Exchange Rate Batch Job.
        VerifyGLEntryForInvoice(CurrencyExchangeRate, SalesHeader."No.", OldRelationalExchangeRate);
    end;

    local procedure ExchRateAdjustmentDocument(var SalesHeader: Record "Sales Header"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentType: Enum "Sales Document Type") OldRelationalExchangeRate: Decimal
    begin
        // 1. Setup: Create and Post Sales Document with new Currency and Exchange rate.
        CreateSalesDocument(SalesHeader, CurrencyExchangeRate, DocumentType);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        OldRelationalExchangeRate := CurrencyExchangeRate."Relational Exch. Rate Amount";
        UpdateExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run Adjust Exchange Rate batch job.
        RunExchRateAdjustment(CurrencyExchangeRate, SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure EntriesAfterExchRateAdjustment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustomerNo: Code[20];
    begin
        // Check that after Modify Relational Exch. Rate Amount and run Adjust Exchange rate batch job, GL entry and
        // Detailed Customer Ledger Entry created with Correct Amount.

        // 1. Setup: Create and Post General Journal Line for Customer.
        Initialize();
        BindSubscription(ERMUpdateCurrencySales);
        CustomerNo := CreateCustomerWithCurrencyExchangeRate(CurrencyExchangeRate);
        // Required Random Value for Amount.
        CreateGeneralJournalLine(
          GenJournalLine, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code", CustomerNo,
          LibraryRandom.RandDec(100, 2), GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run Adjust Exchange Rate batch job.
        RunExchRateAdjustment(CurrencyExchangeRate, GenJournalLine."Document No.");
        UnbindSubscription(ERMUpdateCurrencySales);

        // 3. Verify: Verify G/L Entry and Detailed Customer Ledger Entry made for correct Amount after running
        // Adjust Exchange Rate Batch Job.
        VerifyGLEntryAdjustExchange(GenJournalLine, CurrencyExchangeRate, GenJournalLine."Document No.");
        VerifyDetailedCustomerLedger(GenJournalLine, CurrencyExchangeRate, GenJournalLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure LossEntryExchRateAdjustment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustomerNo: Code[20];
    begin
        // Check that after Modify lower Relational Exch. Rate Amount and run Adjust Exchange rate batch job,
        // GL Entry updated with Correct Amount for Customer.

        // 1. Setup: Create and Post General Journal Line for Customer and Update Exchange rate.
        Initialize();
        BindSubscription(ERMUpdateCurrencySales);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        // Required Random Value for Amount.
        CustomerNo := CreateCustomerWithCurrency('');
        CreateGeneralJournalLine(
          GenJournalLine, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code", CustomerNo,
          LibraryRandom.RandDec(100, 2), GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateLowerExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run Adjust Exchange Rate batch job.
        RunExchRateAdjustment(CurrencyExchangeRate, GenJournalLine."Document No.");
        UnbindSubscription(ERMUpdateCurrencySales);

        // 3. Verify: Verify G/L Entry made for correct Amount after running Adjust Exchange Rate Batch Job.
        VerifyGLEntryLowerExchangeRate(GenJournalLine, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('ApplyEntryPageHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentAfterExchRateAdjustment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CustomerNo: Code[20];
    begin
        // Check that after Modify lower Relational Exch. Rate Amount and run Adjust Exchange rate batch job,
        // GL Entry updated with Correct Amount for Customer with payment.

        // 1. Setup: Create and Post General Journal Line for Customer, Update Exchange Rate and run adjust exchange batch job.
        Initialize();
        BindSubscription(ERMUpdateCurrencySales);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        // Required Random Value for Amount.
        CustomerNo := CreateCustomerWithCurrency('');
        CreateGeneralJournalLine(
          GenJournalLine, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code", CustomerNo,
          LibraryRandom.RandDec(100, 2), GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateLowerExchangeRate(CurrencyExchangeRate);

        RunExchRateAdjustment(CurrencyExchangeRate, GenJournalLine."Document No.");

        // 2. Exercise: Make payment and apply invoice.
        // Passing Amount as 0 because it will update after apply.
        CreateGeneralJournalLine(
          GenJournalLine2, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code", GenJournalLine."Account No.", 0,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer);
        ApplyInvoice(GenJournalLine2, GenJournalLine."Document No.", GenJournalLine2."Document Type"::Invoice);
        LibraryERM.PostGeneralJnlLine(GenJournalLine2);
        UnbindSubscription(ERMUpdateCurrencySales);

        // 3. Verify: Verify Payment applies properly to the invoice.
        VerifyRemaningAmount(GenJournalLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure LossExchRateAdjustmentForBank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check that after Modify Lower Relational Exch. Rate Amount and run Adjust Exchange rate batch job,
        // GL Entry updated with Correct Amount for Bank.

        // 1. Setup: Create and Post General Journal Line for Bank Account and Update Lower Exchange rate.
        Initialize();
        BindSubscription(ERMUpdateCurrencySales);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        // Required Random Value for Amount.
        CreateGeneralJournalLine(
          GenJournalLine, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code",
          CreateBankWithCurrency(CurrencyExchangeRate."Currency Code"), LibraryRandom.RandDec(100, 2),
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"Bank Account");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateLowerExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run Adjust Exchange Rate batch job.
        RunExchRateAdjustment(CurrencyExchangeRate, GenJournalLine."Document No.");
        UnbindSubscription(ERMUpdateCurrencySales);

        // 3. Verify: Verify G/L Entry made for correct Amount after running Adjust Exchange Rate Batch Job.
        VerifyGLEntryLowerExchangeRate(GenJournalLine, CurrencyExchangeRate);
    end;

    [Test]
    [HandlerFunctions('StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure ExchRateAdjustmentForBank()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Check that after Modify Upper Relational Exch. Rate Amount and run Adjust Exchange rate batch job,
        // GL Entry updated with Correct Amount for Bank.

        // 1. Setup: Create and Post General Journal Line for Bank Account and Update Upper Exchange rate.
        Initialize();
        BindSubscription(ERMUpdateCurrencySales);
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);

        // Required Random Value for Amount.
        CreateGeneralJournalLine(
          GenJournalLine, CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Currency Code",
          CreateBankWithCurrency(CurrencyExchangeRate."Currency Code"), LibraryRandom.RandDec(100, 2),
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::"Bank Account");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        UpdateExchangeRate(CurrencyExchangeRate);

        // 2. Exercise: Run Adjust Exchange Rate batch job.
        RunExchRateAdjustment(CurrencyExchangeRate, GenJournalLine."Document No.");
        UnbindSubscription(ERMUpdateCurrencySales);

        // 3. Verify: Verify G/L Entry made for correct Amount after running Adjust Exchange Rate Batch Job.
        VerifyGLEntryAdjustExchange(GenJournalLine, CurrencyExchangeRate, GenJournalLine."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CurrencyOnCustomerJobCard()
    var
        TempJob: Record Job temporary;
        Customer: Record Customer;
    begin
        // Check that correct fields updated for Currency on Customer Job Card.

        // Setup: Find a Customer with Currency attached.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Customer.Modify(true);

        // Exercise: Create Job For Customer.
        LibraryJob.CreateJob(TempJob, Customer."No.");

        // Verify: Verify different Currency Field On Job Card.
        TempJob.TestField("Currency Code", '');
        TempJob.TestField("Invoice Currency Code", Customer."Currency Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnSalesQuotePage()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Resource: Record Resource;
        Currency: Record Currency;
        SalesQuotePage: TestPage "Sales Quote";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryResource.FindResource(Resource);
        LibraryERM.FindCurrency(Currency);
        SalesQuotePage.OpenEdit();
        SalesQuotePage.New();
        SalesQuotePage."Sell-to Customer Name".Value(Customer.Name);
        SalesQuotePage.SalesLines.Type.Value(Format(SalesLine.Type::Resource));
        SalesQuotePage.SalesLines."No.".Value(Resource."No.");
        SalesQuotePage.SalesLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        SalesQuotePage."Currency Code".Value(Currency.Code);
        DocumentNo := SalesQuotePage."No.".Value();
        SalesQuotePage.Close();

        VerifyCurrencyInSalesLine(SalesLine."Document Type"::Quote, DocumentNo, Resource."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnSalesOrderPage()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Resource: Record Resource;
        Currency: Record Currency;
        SalesOrderPage: TestPage "Sales Order";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryResource.FindResource(Resource);
        LibraryERM.FindCurrency(Currency);
        SalesOrderPage.OpenEdit();
        SalesOrderPage.New();
        SalesOrderPage."Sell-to Customer Name".Value(Customer.Name);
        SalesOrderPage.SalesLines.Type.Value(Format(SalesLine.Type::Resource));
        SalesOrderPage.SalesLines."No.".Value(Resource."No.");
        SalesOrderPage.SalesLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        SalesOrderPage."Currency Code".Value(Currency.Code);
        DocumentNo := SalesOrderPage."No.".Value();
        SalesOrderPage.Close();

        VerifyCurrencyInSalesLine(SalesLine."Document Type"::Order, DocumentNo, Resource."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnSalesInvoicePage()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Resource: Record Resource;
        Currency: Record Currency;
        SalesInvoicePage: TestPage "Sales Invoice";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryResource.FindResource(Resource);
        LibraryERM.FindCurrency(Currency);
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.New();
        SalesInvoicePage."Sell-to Customer Name".Value(Customer."No.");
        SalesInvoicePage.SalesLines.Type.Value(Format(SalesLine.Type::Resource));
        SalesInvoicePage.SalesLines."No.".Value(Resource."No.");
        SalesInvoicePage.SalesLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        SalesInvoicePage."Currency Code".Value(Currency.Code);
        DocumentNo := SalesInvoicePage."No.".Value();
        SalesInvoicePage.Close();

        VerifyCurrencyInSalesLine(SalesLine."Document Type"::Invoice, DocumentNo, Resource."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnSalesCrMemoPage()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Resource: Record Resource;
        Currency: Record Currency;
        SalesCrMemoPage: TestPage "Sales Credit Memo";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryResource.FindResource(Resource);
        LibraryERM.FindCurrency(Currency);
        SalesCrMemoPage.OpenEdit();
        SalesCrMemoPage.New();
        SalesCrMemoPage."Sell-to Customer Name".Value(Customer."No.");
        SalesCrMemoPage.SalesLines.Type.Value(Format(SalesLine.Type::Resource));
        SalesCrMemoPage.SalesLines."No.".Value(Resource."No.");
        SalesCrMemoPage.SalesLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        SalesCrMemoPage."Currency Code".Value(Currency.Code);
        DocumentNo := SalesCrMemoPage."No.".Value();
        SalesCrMemoPage.Close();

        VerifyCurrencyInSalesLine(SalesLine."Document Type"::"Credit Memo", DocumentNo, Resource."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnBlanketSalesOrderPage()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Resource: Record Resource;
        Currency: Record Currency;
        BlanketSalesOrderPage: TestPage "Blanket Sales Order";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryResource.FindResource(Resource);
        LibraryERM.FindCurrency(Currency);
        BlanketSalesOrderPage.OpenEdit();
        BlanketSalesOrderPage.New();
        BlanketSalesOrderPage."Sell-to Customer Name".Value(Customer."No.");
        BlanketSalesOrderPage.SalesLines.Type.Value(Format(SalesLine.Type::Resource));
        BlanketSalesOrderPage.SalesLines."No.".Value(Resource."No.");
        BlanketSalesOrderPage.SalesLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        BlanketSalesOrderPage."Currency Code".Value(Currency.Code);
        DocumentNo := BlanketSalesOrderPage."No.".Value();
        BlanketSalesOrderPage.Close();

        VerifyCurrencyInSalesLine(SalesLine."Document Type"::"Blanket Order", DocumentNo, Resource."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnSalesReturnOrderPage()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Resource: Record Resource;
        Currency: Record Currency;
        SalesReturnOrderPage: TestPage "Sales Return Order";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryResource.FindResource(Resource);
        LibraryERM.FindCurrency(Currency);
        SalesReturnOrderPage.OpenEdit();
        SalesReturnOrderPage.New();
        SalesReturnOrderPage."Sell-to Customer Name".Value(Customer."No.");
        SalesReturnOrderPage.SalesLines.Type.Value(Format(SalesLine.Type::Resource));
        SalesReturnOrderPage.SalesLines."No.".Value(Resource."No.");
        SalesReturnOrderPage.SalesLines.Quantity.Value(Format(LibraryRandom.RandInt(5)));
        SalesReturnOrderPage."Currency Code".Value(Currency.Code);
        DocumentNo := SalesReturnOrderPage."No.".Value();
        SalesReturnOrderPage.Close();

        VerifyCurrencyInSalesLine(SalesLine."Document Type"::"Return Order", DocumentNo, Resource."No.", Currency.Code);
    end;

    [Test]
    [HandlerFunctions('MsgConfirmHandler')]
    [Scope('OnPrem')]
    procedure UpdateCurrencyCodeOnGenJournalLine()
    var
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        PostedDocumentNo: Code[20];
        ExpectedMsg: Text;
    begin
        // [FEATURE] [UI] [Journal] [Application]
        // [SCENARIO 230918] Stan fill "Applies-to Doc. No." of Gen. Journal Line with a Posted Document Number. When a confirm message about a Currency Code update appears, it contains correct Currency Codes.
        Initialize();

        // [GIVEN] Posted Sales Invoice with "Currency code" = "C1".
        CreateSalesDocument(SalesHeader, CurrencyExchangeRate, SalesHeader."Document Type"::Invoice);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Customer is updated with "Currency Code" = "C2".
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        Customer.Modify(true);

        // [GIVEN] Create Gen. Journal Line for the Customer with zero Amount and empty "Account No.".
        CreateGeneralJournalLine(
          GenJournalLine, WorkDate(), '', '', 0, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer);

        // [WHEN] Fill "Applies-to Doc. No." with the Posted Sales Invoice No.
        ExpectedMsg :=
          StrSubstNo(
            ChangeCurrencyMsg,
            GenJournalLine.FieldCaption("Currency Code"),
            GenJournalLine.TableCaption(),
            GenJournalLine.GetShowCurrencyCode(Customer."Currency Code"),
            GenJournalLine.GetShowCurrencyCode(SalesHeader."Currency Code"));
        GenJournalLine."Applies-to Doc. Type" := GenJournalLine."Applies-to Doc. Type"::Invoice;
        GenJournalLine.Validate("Applies-to Doc. No.", PostedDocumentNo);

        // [THEN] Confirm message appeared: "The Currency Code will be changed from C2 to C1".
        Assert.ExpectedMessage(ExpectedMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure UpdateNonEmptyLCYCodeOnGenLedgerSetupWhenNoGLEntries()
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [General Ledger Setup]
        // [SCENARIO 568346] Update "LCY Code" from non-empty value in General Ledger Setup when there are no G/L Entries.
        Initialize();

        // [GIVEN] There are no G/L Entries.
        GLEntry.DeleteAll();

        // [GIVEN] "LCY Code" is AAA in General Ledger Setup.
        LibraryERM.CreateCurrency(Currency);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("LCY Code", Currency.Code);
        GeneralLedgerSetup.Modify();

        // [WHEN] Update "LCY Code" to BBB in General Ledger Setup.
        LibraryERM.CreateCurrency(Currency);
        GeneralLedgerSetup.Validate("LCY Code", Currency.Code);
        GeneralLedgerSetup.Modify();

        // [THEN] "LCY Code" in General Ledger Setup is updated.
        GeneralLedgerSetup.Get();
        Assert.AreEqual(Currency.Code, GeneralLedgerSetup."LCY Code", '');
    end;

    [Test]
    procedure UpdateEmptyLCYCodeOnGenLedgerSetupWhenGLEntries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [General Ledger Setup]
        // [SCENARIO 568346] Update "LCY Code" from empty value in General Ledger Setup when there are G/L Entries.
        Initialize();

        // [GIVEN] "LCY Code" is empty in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := '';
        GeneralLedgerSetup.Modify();

        // [GIVEN] There are G/L Entries.
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Enum::"Gen. Journal Document Type"::" ",
            Enum::"Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            Enum::"Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 100);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Update "LCY Code" in General Ledger Setup.
        LibraryERM.CreateCurrency(Currency);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("LCY Code", Currency.Code);
        GeneralLedgerSetup.Modify();

        // [THEN] "LCY Code" in General Ledger Setup is updated.
        GeneralLedgerSetup.Get();
        Assert.AreEqual(Currency.Code, GeneralLedgerSetup."LCY Code", '');
    end;

    [Test]
    procedure UpdateNonEmptyLCYCodeOnGenLedgerSetupWhenGLEntries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // [FEATURE] [General Ledger Setup]
        // [SCENARIO 568346] Update "LCY Code" from non-empty value in General Ledger Setup when there are G/L Entries.
        Initialize();

        // [GIVEN] "LCY Code" has non-empty value in General Ledger Setup.
        LibraryERM.CreateCurrency(Currency);
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."LCY Code" := Currency.Code;
        GeneralLedgerSetup.Modify();

        // [GIVEN] There are G/L Entries.
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryJournals.CreateGenJournalLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, Enum::"Gen. Journal Document Type"::" ",
            Enum::"Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
            Enum::"Gen. Journal Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), 100);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Update "LCY Code" in General Ledger Setup.
        LibraryERM.CreateCurrency(Currency);
        GeneralLedgerSetup.Get();
        asserterror GeneralLedgerSetup.Validate("LCY Code", Currency.Code);

        // [THEN] "LCY Code" in General Ledger Setup is not updated and error is thrown.
        Assert.ExpectedError(CannotUpdateLCYCodeErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateLocalPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();

        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
    end;

    local procedure ApplyInvoice(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJnlApply: Codeunit "Gen. Jnl.-Apply";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        ApplyCustomerEntries: Page "Apply Customer Entries";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindSet();
        repeat
            CustEntrySetApplID.SetApplId(CustLedgerEntry, CustLedgerEntry, GenJournalLine."Document No.");
            ApplyCustomerEntries.CalcApplnAmount();
        until CustLedgerEntry.Next() = 0;
        Commit();
        GenJnlApply.Run(GenJournalLine);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2)); // Use Random Value for Unit Price field
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomerWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentType: Enum "Sales Document Type")
    begin
        CreateSalesHeaderWithCurrency(SalesHeader, CurrencyExchangeRate, DocumentType);
        CreateSalesLines(SalesHeader);
    end;

    local procedure CreateOrderWithLCY(var SalesHeader: Record "Sales Header")
    var
        CustomerNo: Code[20];
    begin
        CustomerNo := CreateCustomerWithCurrency('');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLines(SalesHeader);
    end;

    local procedure CreateSalesHeaderWithCurrency(var SalesHeader: Record "Sales Header"; var CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentType: Enum "Sales Document Type")
    var
        CustomerNo: Code[20];
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        CustomerNo := CreateCustomerWithCurrency('');
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        UpdateCurrencyOnSalesHeader(SalesHeader, CurrencyExchangeRate."Currency Code");
    end;

    local procedure CreateSalesLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        // Create Multiple Lines - Boundary 2 is important.
        for Counter := 2 to 2 + LibraryRandom.RandInt(9) do
            // Required Random Value for Quantity field.
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
    end;

    local procedure CreateCurrencyWithExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        CreateExchangeRate(CurrencyExchangeRate, Currency.Code, WorkDate());
    end;

    local procedure CreateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; StartingDate: Date)
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);

        // Using Random Exchange Rate Amount and Adjustment Exchange Rate.
        CurrencyExchangeRate.Validate("Exchange Rate Amount", LibraryRandom.RandDec(100, 2));
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");

        // Relational Exchange Rate Amount and Relational Adjmt Exchange Rate Amount always greater than Exchange Rate Amount.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", LibraryRandom.RandDec(100, 2) + CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateCustomerWithCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"): Code[20]
    begin
        CreateCurrencyWithExchangeRate(CurrencyExchangeRate);
        exit(CreateCustomerWithCurrency(CurrencyExchangeRate."Currency Code"));
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; CurrencyCode: Code[10]; CustomerNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, DocumentType, AccountType, CustomerNo, Amount);
        GenJournalLine.Validate(
          "Document No.", LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]) DocumentNo: Code[20]
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLines(SalesHeader);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateBankWithCurrency(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.FindBankAccountPostingGroup(BankAccountPostingGroup);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure FindSalesInvoiceAmount(DocumentNo: Code[20]) SalesInvoiceAmount: Decimal
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindSet();
        repeat
            SalesInvoiceAmount += SalesInvoiceLine."Amount Including VAT";
        until SalesInvoiceLine.Next() = 0;
    end;

    local procedure FindSalesLines(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
    end;

    local procedure ModifyCurrency(var CurrencyExchangeRate: Record "Currency Exchange Rate"; var CurrencyExchangeRate2: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRate2.Validate("Relational Currency Code", CurrencyExchangeRate."Currency Code");
        CurrencyExchangeRate2.Modify(true);
        CreateExchangeRate(
          CurrencyExchangeRate2, CurrencyExchangeRate2."Currency Code",
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', CurrencyExchangeRate2."Starting Date"));
    end;

    local procedure RunExchRateAdjustment(CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentNo: Code[20])
    var
        Currency: Record Currency;
        ExchRateAdjustment: Report "Exch. Rate Adjustment";
    begin
        // Using Random Number Generator for Document No.
        Currency.SetRange(Code, CurrencyExchangeRate."Currency Code");
        Clear(ExchRateAdjustment);
        ExchRateAdjustment.SetTableView(Currency);
        ExchRateAdjustment.InitializeRequest2(
          CurrencyExchangeRate."Starting Date", CurrencyExchangeRate."Starting Date", 'Test', CurrencyExchangeRate."Starting Date",
          DocumentNo, true, false);
        ExchRateAdjustment.UseRequestPage(false);
        ExchRateAdjustment.Run();
    end;

    local procedure UpdateCurrencyOnSalesHeader(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10])
    begin
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePostingDateSalesHeader(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    begin
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesLines(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        ItemNo: code[20];
    begin
        FindSalesLines(SalesLine, DocumentType, DocumentNo);
        repeat
            ItemNo := SalesLine."No.";
            SalesLine."No." := '';
            SalesLine.Validate("No.", ItemNo);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    [Normal]
    local procedure UpdateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" + LibraryRandom.RandInt(4));
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    [Normal]
    local procedure UpdateLowerExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    begin
        // Use 2 to Update Lower Exchange Rate.
        CurrencyExchangeRate.Validate(
          "Relational Exch. Rate Amount", CurrencyExchangeRate."Relational Exch. Rate Amount" / 2);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure GetGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.FindLast();
    end;

    local procedure GetCurrency(var Currency: Record Currency; CurrencyCode: Code[10])
    begin
        Currency.Get(CurrencyCode);
        Currency.InitRoundingPrecision();
    end;

    local procedure GetGLEntryForExchangeRate(DocumentNo: Code[20]) GLAmount: Decimal
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.FindSet();
        repeat
            GLAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
    end;

    local procedure CalcCurrencyFactor(CurrencyExchangeRate: Record "Currency Exchange Rate"): Decimal
    begin
        exit(CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount");
    end;

    local procedure ValidateCustWithFCYOnOrder(var CurrencyExchangeRate: Record "Currency Exchange Rate"; var SalesHeader: Record "Sales Header")
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Sell-to Customer Name".SetValue(CreateCustomerWithCurrencyExchangeRate(CurrencyExchangeRate));
        SalesOrder.Close();
        SalesHeader.Find();
    end;

    local procedure VerifySalesDocumentValues(SalesHeader: Record "Sales Header"; CurrencyFactor: Decimal)
    begin
        SalesHeader.TestField("Currency Factor", CurrencyFactor);
        VerifySalesLineValues(SalesHeader);
    end;

    local procedure VerifySalesLineValues(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Currency: Record Currency;
    begin
        // Replace TESTFIELD with AssertNealyEqual to fix GDL Failures.
        GetCurrency(Currency, SalesHeader."Currency Code");
        FindSalesLines(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        repeat
            Item.Get(SalesLine."No.");
            Assert.AreNearlyEqual(
              SalesLine."Unit Price", Item."Unit Price" * SalesHeader."Currency Factor", Currency."Unit-Amount Rounding Precision",
              StrSubstNo(
                UnitPriceError, SalesLine.FieldCaption("Unit Price"),
                Item."Unit Price" * SalesHeader."Currency Factor", SalesLine.TableCaption()));
            SalesLine.TestField("Line Amount", Round(SalesLine.Quantity * SalesLine."Unit Price", Currency."Amount Rounding Precision"));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyGenJournalAmount(GenJournalLine: Record "Gen. Journal Line"; CurrencyExchangeRate: Record "Currency Exchange Rate"; Amount: Decimal; StartingDate: Date)
    var
        Currency: Record Currency;
    begin
        GetCurrency(Currency, CurrencyExchangeRate."Currency Code");
        GenJournalLine.TestField(
          "Amount (LCY)", Round(LibraryERM.ConvertCurrency(Amount, CurrencyExchangeRate."Currency Code", '', StartingDate),
            Currency."Amount Rounding Precision"));
    end;

    local procedure VerifySalesInvoiceCurrency(SalesInvoiceNo: Code[20]; CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("No.", SalesInvoiceNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Currency Code", CurrencyExchangeRate."Currency Code");
        SalesInvoiceHeader.TestField("Currency Factor", CalcCurrencyFactor(CurrencyExchangeRate));
    end;

    [Normal]
    local procedure VerifyGLEntry(CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentNo: Code[20]; Amount: Decimal)
    var
        Currency: Record Currency;
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter(Amount, '<0');
        GLEntry.FindLast();
        Currency.Get(CurrencyExchangeRate."Currency Code");
        GLEntry.TestField("Posting Date", CurrencyExchangeRate."Starting Date");
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountError, GLEntry.FieldCaption(Amount), Amount,
            GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyGLEntryAmount(CurrencyExchangeRate: Record "Currency Exchange Rate"; SalesInvoiceHeaderNo: Code[20]; DocumentNo: Code[20]; OldRelationalExchangeRate: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        ExpectedAmount: Decimal;
    begin
        GetCurrency(Currency, CurrencyExchangeRate."Currency Code");
        GetGLEntry(GLEntry, DocumentNo);

        ExpectedAmount :=
          FindSalesInvoiceAmount(SalesInvoiceHeaderNo) *
          (CurrencyExchangeRate."Relational Exch. Rate Amount" - OldRelationalExchangeRate) /
          CurrencyExchangeRate."Exchange Rate Amount";
        Assert.AreNearlyEqual(
          ExpectedAmount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountError, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."),
            GLEntry."Entry No."));
    end;

    [Normal]
    local procedure VerifyGLEntryForOrder(CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentNo: Code[20]; OldRelationalExchangeRate: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", DocumentNo);
        SalesInvoiceHeader.FindFirst();
        VerifyGLEntryAmount(CurrencyExchangeRate, SalesInvoiceHeader."No.", DocumentNo, OldRelationalExchangeRate);
    end;

    [Normal]
    local procedure VerifyGLEntryForInvoice(CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentNo: Code[20]; OldRelationalExchangeRate: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", DocumentNo);
        SalesInvoiceHeader.FindFirst();
        VerifyGLEntryAmount(CurrencyExchangeRate, SalesInvoiceHeader."No.", DocumentNo, OldRelationalExchangeRate);
    end;

    [Normal]
    local procedure VerifyGLEntryAdjustExchange(GenJournalLine: Record "Gen. Journal Line"; CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        ExpectedGLAmount: Decimal;
    begin
        GetCurrency(Currency, CurrencyExchangeRate."Currency Code");
        GetGLEntry(GLEntry, DocumentNo);

        ExpectedGLAmount :=
          GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" /
          CurrencyExchangeRate."Exchange Rate Amount" - GenJournalLine."Amount (LCY)";
        Assert.AreNearlyEqual(
          ExpectedGLAmount, GLEntry.Amount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountError, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."),
            GLEntry."Entry No."));
    end;

    [Normal]
    local procedure VerifyDetailedCustomerLedger(GenJournalLine: Record "Gen. Journal Line"; CurrencyExchangeRate: Record "Currency Exchange Rate"; DocumentNo: Code[20])
    var
        Currency: Record Currency;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ExpectedDetailCustEntryAmount: Decimal;
    begin
        GetCurrency(Currency, CurrencyExchangeRate."Currency Code");
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.FindLast();
        ExpectedDetailCustEntryAmount :=
          GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" / CurrencyExchangeRate."Exchange Rate Amount" -
          GenJournalLine."Amount (LCY)";
        Assert.AreNearlyEqual(
          ExpectedDetailCustEntryAmount, DetailedCustLedgEntry."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountError, DetailedCustLedgEntry.FieldCaption("Amount (LCY)"), DetailedCustLedgEntry."Amount (LCY)",
            DetailedCustLedgEntry.TableCaption(), DetailedCustLedgEntry.FieldCaption("Entry No."), DetailedCustLedgEntry."Entry No."));
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; CurrencyCode: Code[10])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Currency Code", CurrencyCode);
    end;

    [Normal]
    local procedure VerifyGLEntryLowerExchangeRate(GenJournalLine: Record "Gen. Journal Line"; CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
        ExpectedGLAmount: Decimal;
        GLAmount: Decimal;
    begin
        GetCurrency(Currency, CurrencyExchangeRate."Currency Code");
        ExpectedGLAmount :=
          GenJournalLine."Amount (LCY)" -
          GenJournalLine.Amount * CurrencyExchangeRate."Relational Exch. Rate Amount" /
          CurrencyExchangeRate."Exchange Rate Amount";
        GLAmount := GetGLEntryForExchangeRate(GenJournalLine."Document No.");

        Assert.AreNearlyEqual(
          ExpectedGLAmount, GLAmount, Currency."Amount Rounding Precision",
          StrSubstNo(
            AmountError, GLEntry.FieldCaption(Amount), GLAmount, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."),
            GLEntry."Entry No."));
    end;

    local procedure VerifyRemaningAmount(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.CalcFields("Remaining Amount");
            CustLedgerEntry.TestField("Remaining Amount", 0);
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyCurrencyInSalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; No: Code[20]; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        Assert.AreEqual(No, SalesLine."No.",
          StrSubstNo(IncorrectValueErr, SalesLine."No.", SalesLine.FieldCaption("No.")));
        Assert.AreEqual(CurrencyCode, SalesLine."Currency Code",
          StrSubstNo(IncorrectValueErr, SalesLine."Currency Code", SalesLine.FieldCaption("Currency Code")));
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreditMemoConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Result: Boolean)
    begin
        Result := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just for Handle the Message.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEntryPageHandler(var ApplyCustomerEntries: Page "Apply Customer Entries"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
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

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure CurrencyExchangeRateSendNotificationHandler(var NotificationInstance: Notification): Boolean
    var
        UpdateCurrencyExchangeRates: Codeunit "Update Currency Exchange Rates";
    begin
        Assert.AreEqual(
          Format(NotificationInstance.Id),
          Format(UpdateCurrencyExchangeRates.GetMissingExchangeRatesNotificationID()),
          '');

        exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Run Handler", 'OnBeforeRunCustExchRateAdjustment', '', false, false)]
    local procedure RunCustExchRateAdjustment(GenJnlLine: Record "Gen. Journal Line"; var TempCustLedgerEntry: Record "Cust. Ledger Entry" temporary; var IsHandled: Boolean)
    var
        ExchRateAdjmtProcess: Codeunit "Exch. Rate Adjmt. Process";
    begin
        ExchRateAdjmtProcess.AdjustExchRateCust(GenJnlLine, TempCustLedgerEntry);
        IsHandled := true;
    end;
}

