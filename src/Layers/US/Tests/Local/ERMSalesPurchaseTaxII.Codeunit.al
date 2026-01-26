codeunit 142051 "ERM Sales/Purchase Tax II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Sales Tax]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJob: Codeunit "Library - Job";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountError: Label '%1 must be %2 in %3.';
        PostingDateError: Label 'Posting Date must have a value in Gen. Journal Line';
        AccountNoError: Label '%1 must have a value in Gen. Journal Line';
        SalesTaxAmountError: Label 'Amount must not be 0 in Gen. Journal Line';
        WrongValueEntryAmountErr: Label 'Value Entry Amount is wrong.';
        WrongUnitCostErr: Label 'Wrong Unit Cost (LCY) in Job Ledger Entry %1.';
        TaxAmountMustMatchErr: Label 'Tax Amount must be same';
        SalesHeaderNo: Label 'Sales_Header_No_';
        PurchaseHeaderNo: Label 'Purchase_Header_No_';
        FORMATServiceHeaderDocumentTypeServiceHeaderNo: Label 'FORMAT__Service_Header___Document_Type____________Service_Header___No__';
        ServiceOrderNo: Label 'No_ServHeader';
        ServiceQuoteNo: Label 'Service_Header_No_';
        WrongRndSummarizedTaxAmountErr: Label 'Wrong rounded summarized Tax Amount.';
        GLEntryAmountErr: Label 'G/L Entry Amount is wrong.';
        TaxAmountErr: Label 'Wrong Tax Amount.';
        ItemChargeVENotPostedErr: Label 'Value Entry with item charge for item %1 was not posted.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMTax: Codeunit "Library - ERM Tax";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        IsInitialized: Boolean;
        DummyTaxCountry: Option US,CA;
        UseTaxCannotBeSetErr: Label '%1 cannot be set because %2 record %3, %4 is set for Expense/Capitalize.';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesOrderTaxAmount_RoundingByJurisdiction()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Sales] [Order]
        // [SCENARIO] Tax Amount rounding on Sales Order Statistics with two jurisdiction codes and TaxArea."Country/Region" = CA
        Initialize();

        // [GIVEN] Sales Order with Item, Currency, two jurisdiction codes and TaxArea."Country/Region" = CA
        TaxAmount := CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Order, DummyTaxCountry::CA);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // [WHEN] Open Sales Order Statistics
        SalesOrder.Statistics.Invoke();

        // [THEN] Tax Amount on Sales Order Statistics is correct
        // SalesOrderStatsTestPageHandler
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesOrderTaxAmount_Rounding()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Sales] [Order]
        // [SCENARIO] Tax Amount rounding on Sales Order Statistics with two jurisdiction codes and TaxArea."Country/Region" = US
        Initialize();

        // [GIVEN] Sales Order with Item, Currency, two jurisdiction codes and TaxArea."Country/Region" = US
        TaxAmount := CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Order, DummyTaxCountry::US);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // [WHEN] Open Sales Order Statistics
        SalesOrder.Statistics.Invoke();

        // [THEN] Tax Amount on Sales Order Statistics is correct
        // SalesOrderStatsTestPageHandler
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsTestPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsSalesOrderTaxAmount_RoundingByJurisdictionNM()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Sales] [Order]
        // [SCENARIO] Tax Amount rounding on Sales Order Statistics with two jurisdiction codes and TaxArea."Country/Region" = CA
        Initialize();

        // [GIVEN] Sales Order with Item, Currency, two jurisdiction codes and TaxArea."Country/Region" = CA
        TaxAmount := CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Order, DummyTaxCountry::CA);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // [WHEN] Open Sales Order Statistics
        SalesOrder.SalesOrderStats.Invoke();

        // [THEN] Tax Amount on Sales Order Statistics is correct
        // SalesOrderStatsTestPageHandlerNM
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsTestPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsSalesOrderTaxAmount_RoundingNM()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Sales] [Order]
        // [SCENARIO] Tax Amount rounding on Sales Order Statistics with two jurisdiction codes and TaxArea."Country/Region" = US
        Initialize();

        // [GIVEN] Sales Order with Item, Currency, two jurisdiction codes and TaxArea."Country/Region" = US
        TaxAmount := CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Order, DummyTaxCountry::US);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenSalesOrderPage(SalesOrder, SalesHeader);

        // [WHEN] Open Sales Order Statistics
        SalesOrder.SalesOrderStats.Invoke();

        // [THEN] Tax Amount on Sales Order Statistics is correct
        // SalesOrderStatsTestPageHandlerNM
    end;

    [Test]
    [HandlerFunctions('SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SaleDocumentTestReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Sales Order values on Sales Document Test Report - 202.

        // Setup: Create Sales Order and open Sales Order page.
        Initialize();
        CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Order, DummyTaxCountry::CA);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        Commit();

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");

        // Verify: Verify Sales Order values on Sales Document Test Report - 202.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(SalesHeaderNo, SalesHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'VATAmountLine__VAT_Amount_', Round(SalesLine."Line Amount" * SalesLine."VAT %" / 100));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesQuotesTaxAmount_RoundingByJurisdiction()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Sales] [Quote]
        // [SCENARIO] Tax Amount rounding on Sales Quote Statistics with two jurisdiction codes and TaxArea."Country/Region" = CA
        Initialize();

        // [GIVEN] Sales Quote with Item, Currency, two jurisdiction codes and TaxArea."Country/Region" = CA
        TaxAmount := CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Quote, DummyTaxCountry::CA);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenSalesQuotePage(SalesQuote, SalesHeader);

        // [WHEN] Open Sales Quote Statistics
        SalesQuote.Statistics.Invoke();

        // [THEN] Tax Amount on Sales Quote Statistics is correct
        // SalesStatsTestPageHandler.
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesQuotesTaxAmount_Rounding()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Sales] [Quote]
        // [SCENARIO] Tax Amount rounding on Sales Quote Statistics with two jurisdiction codes and TaxArea."Country/Region" = US
        Initialize();

        // [GIVEN] Sales Quote with Item, Currency, two jurisdiction codes and TaxArea."Country/Region" = US
        TaxAmount := CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Quote, DummyTaxCountry::US);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenSalesQuotePage(SalesQuote, SalesHeader);

        // [WHEN] Open Sales Quote Statistics
        SalesQuote.Statistics.Invoke();

        // [THEN] Tax Amount on Sales Quote Statistics is correct
        // SalesStatsTestPageHandler.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatsTestNonModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesQuotesTaxAmount_RoundingByJurisdictionNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Sales] [Quote]
        // [SCENARIO] Tax Amount rounding on Sales Quote Statistics with two jurisdiction codes and TaxArea."Country/Region" = CA
        Initialize();

        // [GIVEN] Sales Quote with Item, Currency, two jurisdiction codes and TaxArea."Country/Region" = CA
        TaxAmount := CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Quote, DummyTaxCountry::CA);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenSalesQuotePage(SalesQuote, SalesHeader);

        // [WHEN] Open Sales Quote Statistics
        SalesQuote.SalesStats.Invoke();

        // [THEN] Tax Amount on Sales Quote Statistics is correct
        // SalesStatsTestPageHandler.
    end;

    [Test]
    [HandlerFunctions('SalesStatsTestNonModalPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsSalesQuotesTaxAmount_RoundingNonModal()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Rounding] [Sales] [Quote]
        // [SCENARIO] Tax Amount rounding on Sales Quote Statistics with two jurisdiction codes and TaxArea."Country/Region" = US
        Initialize();

        // [GIVEN] Sales Quote with Item, Currency, two jurisdiction codes and TaxArea."Country/Region" = US
        TaxAmount := CreateSalesDocumentWithCurrency(SalesHeader, SalesHeader."Document Type"::Quote, DummyTaxCountry::US);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenSalesQuotePage(SalesQuote, SalesHeader);

        // [WHEN] Open Sales Quote Statistics
        SalesQuote.SalesStats.Invoke();

        // [THEN] Tax Amount on Sales Quote Statistics is correct
        // SalesStatsTestPageHandler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsPurchaseOrderTaxAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Purchase Order Statistics.

        // Setup: Create Purchase Order and open Purchase Order page.
        Initialize();
        TaxAmount := CreatePurchaseDocumentWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);

        // Exercise.
        PurchaseOrder.Statistics.Invoke();

        // Verify: Verify Tax Amount on Purchase Order Statistics. Verification done in PurchaseOrderStatsTestPageHandler.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsPurchOrderTaxAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Purchase Order Statistics.

        // Setup: Create Purchase Order and open Purchase Order page.
        Initialize();
        TaxAmount := CreatePurchaseDocumentWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);

        // Exercise.
        PurchaseOrder.PurchaseOrderStats.Invoke();

        // Verify: Verify Tax Amount on Purchase Order Statistics. Verification done in PurchOrderStatsTestPageHandler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsPurchaseQuoteTaxAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Purchase Quote Statistics.

        // Setup: Create Purchase Quote and open Purchase Quote page.
        Initialize();
        TaxAmount := CreatePurchaseDocumentWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenPurchaseQuotePage(PurchaseQuote, PurchaseHeader);

        // Exercise.
        PurchaseQuote.Statistics.Invoke();

        // Verify: Verify Tax Amount on Purchase Quote Statistics. Verification done in PurchaseStatsTestPageHandler.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseStatsTestHandler')]
    [Scope('OnPrem')]
    procedure StatisticsPurchaseQuoteTaxAmt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuote: TestPage "Purchase Quote";
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Purchase Quote Statistics.

        // Setup: Create Purchase Quote and open Purchase Quote page.
        Initialize();
        TaxAmount := CreatePurchaseDocumentWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Quote);
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenPurchaseQuotePage(PurchaseQuote, PurchaseHeader);

        // Exercise.
        PurchaseQuote.PurchaseStats.Invoke();

        // Verify: Verify Tax Amount on Purchase Quote Statistics. Verification done in PurchaseStatsTestHandler.
    end;

    [Test]
    [HandlerFunctions('PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order values on Purchase Document Test Report - 402.

        // Setup: Create Purchase Order.
        Initialize();
        CreatePurchaseDocumentWithCurrency(PurchaseHeader, PurchaseHeader."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        Commit();

        // Exercise.
        REPORT.Run(REPORT::"Purchase Document - Test");

        // Verify: Verify Purchase Order values on Purchase Document Test Report - 402.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchaseHeaderNo, PurchaseHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists(
          'VATAmountLine__VAT_Amount_', Round(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100));
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsServiceOrderTaxAmount()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Service Order Statistics.

        // Setup: Create Service Order and open Service Order page.
        Initialize();
        TaxAmount := CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::Order);
        LibraryVariableStorage.Enqueue(ServiceHeader."Currency Code");
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenServiceOrderPage(ServiceHeader, ServiceOrder);

        // Exercise.
        ServiceOrder.Statistics.Invoke();

        // Verify: Verify Tax Amount on Service Order Statistics. Verification done in ServiceOrderStatsTestPageHandler.
    end;

    [Test]
    [HandlerFunctions('ServiceStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticsServiceInvoiceTaxAmount()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Service Invoice Statistics.

        // Setup: Create Service Invoice and open Service Invoice page.
        Initialize();
        TaxAmount := CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(ServiceHeader."Currency Code");
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenServiceInvoicePage(ServiceHeader, ServiceInvoice);

        // Exercise.
        ServiceInvoice.Statistics.Invoke();

        // Verify: Verify Tax Amount on Service Invoice Statistics. Verification done in ServiceStatsTestPageHandler.
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceOrderStatsTestPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsServiceOrderTaxAmountNM()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrder: TestPage "Service Order";
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Service Order Statistics.

        // Setup: Create Service Order and open Service Order page.
        Initialize();
        TaxAmount := CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::Order);
        LibraryVariableStorage.Enqueue(ServiceHeader."Currency Code");
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenServiceOrderPage(ServiceHeader, ServiceOrder);

        // Exercise.
        ServiceOrder.ServiceOrderStats.Invoke();

        // Verify: Verify Tax Amount on Service Order Statistics. Verification done in ServiceOrderStatsTestPageHandler.
    end;

    [Test]
    [HandlerFunctions('ServiceStatsTestPageHandlerNM')]
    [Scope('OnPrem')]
    procedure StatisticsServiceInvoiceTaxAmountNM()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoice: TestPage "Service Invoice";
        TaxAmount: Decimal;
    begin
        // Verify Tax Amount on Service Invoice Statistics.

        // Setup: Create Service Invoice and open Service Invoice page.
        Initialize();
        TaxAmount := CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(ServiceHeader."Currency Code");
        LibraryVariableStorage.Enqueue(TaxAmount);
        OpenServiceInvoicePage(ServiceHeader, ServiceInvoice);

        // Exercise.
        ServiceInvoice.ServiceStats.Invoke();

        // Verify: Verify Tax Amount on Service Invoice Statistics. Verification done in ServiceStatsTestPageHandler.
    end;

    [Test]
    [HandlerFunctions('ServiceDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Service Order values on Service Document Test Report - 5915.

        // Setup: Create Service Order.
        Initialize();
        CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::Order);
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        Commit();

        // Exercise.
        REPORT.Run(REPORT::"Service Document - Test");

        // Verify: Verify Service Order values on Service Document Test Report - 5915.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(
          FORMATServiceHeaderDocumentTypeServiceHeaderNo, Format(ServiceHeader."Document Type") + ' ' + ServiceHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists('Service_Line___Line_Amount_', ServiceLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ServiceOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderAmountOnServiceOrderReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Service Order Number and Amount on Service Order Report - 5900.

        // Setup: Create Service Order.
        Initialize();
        CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::Order);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        FindServiceLine(ServiceLine, ServiceHeader."No.");
        Commit();

        // Exercise.
        REPORT.Run(REPORT::"Service Order");

        // Verify: Verify Service Order Number and Amount on Service Order Report - 5900.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ServiceOrderNo, ServiceHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists('TotalAmt', ServiceLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('ServiceQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceQuoteAmountOnServiceQuoteReport()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // Verify Service Order Number and Amount on Service Quote Report - 5902.

        // Setup: Create Service Order.
        Initialize();
        CreateServiceDocumentWithCurrency(ServiceHeader, ServiceHeader."Document Type"::Quote);
        LibraryVariableStorage.Enqueue(ServiceHeader."No.");
        FindServiceLine(ServiceLine, ServiceHeader."No.");
        Commit();

        // Exercise.
        REPORT.Run(REPORT::"Service Quote");

        // Verify: Verify Service Order Number and Tax Amount on Service Quote Report - 5902.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(ServiceQuoteNo, ServiceHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists('Amt', ServiceLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryUsingGSTHSTGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Amount after posting General Journal Line with GST/HST Journal in G/L Entry.

        // Setup.
        Initialize();

        // Exercise: Create Tax Area Line and General Journal Line using Tax Setup
        CreateAndPostGenJournalWithTaxDetail(GenJournalLine, WorkDate());

        // Verify: Verify Amount after posting General Journal Line with GST/HST in G/L Entry.
        VerifyGLEntryAmount(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlankPostingDateGenJournalLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Posting Date error while posting General Journal Line with GST/HST and blank posting date.

        // Setup.
        Initialize();

        // Exercise: Create Tax Area Line and General Journal Line using Tax Setup
        asserterror CreateAndPostGenJournalWithTaxDetail(GenJournalLine, 0D);

        // Verify: Verify Posting Date error while posting General Journal Line with GST/HST and blank posting date.
        Assert.ExpectedError(PostingDateError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanklAccountNoGenJournalLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify Account No. error while posting General Journal Line with GST/HST and blank Account No.

        // Setup: Create General Journal Line and modify GST/HST.
        Initialize();
        CreateGenJournal(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", '',
          LibraryRandom.RandDec(10, 2));
        GenJournalLine.Validate("GST/HST", GenJournalLine."GST/HST"::"Self Assessment");
        GenJournalLine.Modify(true);

        // Exercise.
        asserterror LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verify Account No. error while posting General Journal Line with GST/HST and blank Account No.
        Assert.ExpectedError(StrSubstNo(AccountNoError, GenJournalLine."Account No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlankBalAccountNoGenJournalLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesTaxJournal: TestPage "Sales Tax Journal";
    begin
        // Verify Bal. Account No. error while posting General Journal Line with GST/HST and blank Bal. Account No.

        // Setup: Create Sales Tax Journal Line using page.
        Initialize();
        CreateTaxAreaLine(TaxDetail);
        FindVATPostingSetup(VATPostingSetup);
        SalesTaxJournal.OpenEdit();
        SalesTaxJournal."Document No.".SetValue(LibraryUtility.GenerateGUID());
        SalesTaxJournal."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        SalesTaxJournal."Account No.".SetValue(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"));
        SalesTaxJournal.Amount.SetValue(LibraryRandom.RandDec(10, 2));
        SalesTaxJournal."Bal. Account No.".SetValue('');

        // Exercise.
        asserterror SalesTaxJournal.Post.Invoke();

        // Verify: Verify Bal. Account No. error while posting General Journal Line with GST/HST and blank Bal. Account No.
        Assert.ExpectedError(StrSubstNo(AccountNoError, GenJournalLine."Account No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure BlankAmountGenJournalLineError()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesTaxJournal: TestPage "Sales Tax Journal";
    begin
        // Verify Amount error while posting Sales Tax Journal Line with zero Amount.

        // Setup: Create Sales Tax Journal Line using page.
        Initialize();
        CreateTaxAreaLine(TaxDetail);
        FindVATPostingSetup(VATPostingSetup);
        SalesTaxJournal.OpenEdit();
        SalesTaxJournal."Account Type".SetValue(GenJournalLine."Account Type"::"G/L Account");
        SalesTaxJournal."Account No.".SetValue(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"));
        SalesTaxJournal.Amount.SetValue(0);

        // Exercise.
        asserterror SalesTaxJournal.Post.Invoke();

        // Verify: Verify Amount error while posting Sales Tax Journal Line with zero Amount.
        Assert.ExpectedError(SalesTaxAmountError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryUsingGSTHSTGenJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Verify VAT Entry values after posting General Journal Line with GST/HST in G/L Entry.

        // Setup.
        Initialize();

        // Exercise: Create Tax Area Line and General Journal Line using Tax Setup.
        CreateAndPostGenJournalWithTaxDetail(GenJournalLine, WorkDate());

        // Verify: Verify VAT Entry values after posting General Journal Line with GST/HST in G/L Entry.
        VerifyVATEntry(
          GenJournalLine."Document Type", GenJournalLine."Document No.", GenJournalLine."Bal. VAT Base Amount", GenJournalLine."GST/HST");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompInfoSoftwareIdentificationCode()
    var
        CompanyInformation: Record "Company Information";
        SoftwareIdentificationCode: Code[10];
    begin
        // Verify Software Identification Code in the Company Information.

        // Setup.
        Initialize();

        // Exercise: Modify Software Identification Code in the Company Information.
        SoftwareIdentificationCode := DelStr(LibraryUtility.GenerateGUID(), 1, 8);  // Using 8 for length of Software Identification Code.
        CompanyInformation.Validate("Software Identification Code", SoftwareIdentificationCode);
        CompanyInformation.Modify(true);

        // Verify: Verify Software Identification Code in the Company Information.
        CompanyInformation.TestField("Software Identification Code", SoftwareIdentificationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderUsingGSTHSTBlank()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order Line GST/HST should be updated to blank while using Item in Purchase Line.
        PurchDocumentUsingGSTHSTValues(PurchaseLine."Document Type"::Invoice, PurchaseLine."GST/HST"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceUsingGSTHSTSelfAssessment()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Invoice Line GST/HST should be updated to Self Assessment while using Item in Purchase Line.
        PurchDocumentUsingGSTHSTValues(PurchaseLine."Document Type"::Invoice, PurchaseLine."GST/HST"::"Self Assessment");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderUsingGSTHSTRebate()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Return Order Line GST/HST should be updated to Rebate while using Item in Purchase Line.
        PurchDocumentUsingGSTHSTValues(PurchaseLine."Document Type"::"Return Order", PurchaseLine."GST/HST"::Rebate);
    end;

    local procedure PurchDocumentUsingGSTHSTValues(DocumentType: Enum "Purchase Document Type"; GSTHST: Enum "GST HST Tax Type")
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        // Setup.
        Initialize();
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        FindVATPostingSetup(VATPostingSetup);

        // Exercise.
        CreatePurchaseDocument(
          PurchaseLine, DocumentType, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"),
          CreateVendor(TaxAreaCode));
        PurchaseLine.Validate("GST/HST", GSTHST);
        PurchaseLine.Modify(true);

        // Verify: Verify Purchase Document Line GST/HST should be updated.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("GST/HST", GSTHST);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoUsingGSTHSTAcquisition()
    var
        FixedAsset: Record "Fixed Asset";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Credit Memo Line GST/HST should be updated to Acquisition while using Fixed Asset in Purchase Line.

        // Setup.
        Initialize();
        CreateFixedAsset(FixedAsset, '');  // Using blank value for FA Posting Group.

        // Exercise.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", CreateVendor(''));

        // Verify: Verify Purchase Credit Memo Line GST/HST should be updated to Acquisition while using Fixed Asset in Purchase Line.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.TestField("GST/HST", PurchaseLine."GST/HST"::Acquisition);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxEntryUsingPurchCrMemoGSTHST()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Entry GST/HST value after posting Purchase Credit Memo.
        GSTHSTTaxEntryUsingPurchDoc(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxEntryUsingPurchInvoiceGSTHST()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Entry GST/HST value after posting Purchase Invoice.
        GSTHSTTaxEntryUsingPurchDoc(PurchaseHeader."Document Type"::Invoice);
    end;

    local procedure GSTHSTTaxEntryUsingPurchDoc(DocumentType: Enum "Purchase Document Type")
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Setup: Create and setup Fixed Asset, Depreciation Book.
        Initialize();
        CreateAndModifyDepreciationBook(DepreciationBook);
        CreateFixedAsset(FixedAsset, CreateFAPostingGroup());
        CreateFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, FixedAsset."FA Posting Group");

        // Exercise: Create Vendor, create Purchase Document.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        ModifyPurchaseHeader(PurchaseHeader, PurchaseHeader."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAsset."No.", LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Quantity.
        ModifyPurchaseLineDepreciationBook(PurchaseLine, DepreciationBook.Code);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Entry GST/HST value after posting Purchase Document.
        VerifyVATEntry(PurchaseLine."Document Type", DocumentNo, PurchaseLine.Amount, PurchaseLine."GST/HST");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAfterPostElectronicPmtUsingSalesCrMemo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry after applying Sales Credit Memo using Electronic Payment.

        // Setup: Create and post Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", '', '');
        DocumentNo := PostSalesDocument(SalesLine);

        // Exercise.
        CreateAndPostElectronicPmtLine(
          GenJournalLine, DocumentNo, SalesLine."Sell-to Customer No.", SalesLine.Amount,
          GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer,
          GenJournalLine."Applies-to Doc. Type"::"Credit Memo");

        // Verify: Verify G/L Entry after applying Sales Credit Memo using Electronic Payment.
        VerifyGLEntryAmount(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLAfterPostElectronicPmtUsingPurchOrder()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Verify G/L Entry after applying Purchase Invoice using Electronic Payment.

        // Setup: Create and post Purchase Order.
        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", ''), CreateVendor(''));
        ModifyPurchaseLine(PurchaseLine, 0);  // Using 0 for Line Discount.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise.
        CreateAndPostElectronicPmtLine(
          GenJournalLine, DocumentNo, PurchaseLine."Buy-from Vendor No.", PurchaseLine.Amount,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, GenJournalLine."Applies-to Doc. Type"::Invoice);

        // Verify: Verify G/L Entry after applying Purchase Invoice using Electronic Payment.
        VerifyGLEntryAmount(GenJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedInvoiceLineDiscAfterPostPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        // Verify Posted Purchase Invoice Line Discount and Amount after posting Purchase Order with Line Discount %.

        // Setup: Create and modify Purchase Order.
        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", ''), CreateVendor(''));
        ModifyPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));  // Using Random value for Line Discount %.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Posted Purchase Invoice Line Discount and Amount after posting Purchase Order with Line Discount %.
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindFirst();
        PurchInvLine.TestField(Amount, PurchaseLine."Line Amount");
        PurchInvLine.TestField("Line Discount %", PurchaseLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedInvoiceLineDiscAfterPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Posted Sales Invoice Line Discount and Amount after posting Sales Order with Line Discount %.

        // Setup: Create and modify Sales Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, '', '');
        ModifySalesLine(SalesLine);

        // Exercise.
        DocumentNo := PostSalesDocument(SalesLine);

        // Verify: Verify Posted Sales Invoice Line Discount and Amount after posting Sales Order with Line Discount %.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Amount, SalesInvoiceLine."Line Amount");
        SalesInvoiceLine.TestField("Line Discount %", SalesInvoiceLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTaxAreaOnPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // Verify Purchase Order Tax Area Code which should be validated from Vendor. Bug Id:203903

        // Setup: Modify Purchases and Payables setup and create Tax Area Line.
        Initialize();
        ModifyPurchasesPayablesSetup();
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);

        // Exercise.
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);

        // Verify: Verify Purchase Order Tax Area Code which should be validated from Vendor.
        PurchaseHeader.TestField("Tax Area Code", TaxAreaCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedInvoiceLineDiscAmountAfterPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        DocumentNo: Code[20];
        TaxAreaCode: Code[20];
    begin
        // Verify Posted Sales Invoice Line Discount Amount after posting Sales Order with Line Discount Amount. BUG ID:151937

        // Setup: Create Tax Area Line and Create and modify Sales Order.
        Initialize();
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, TaxAreaCode, TaxDetail."Tax Group Code");
        ModifySalesLine(SalesLine);

        // Exercise.
        DocumentNo := PostSalesDocument(SalesLine);

        // Verify: Verify Posted Sales Invoice Line Discount Amount after posting Sales Order with Line Discount Amount.
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Line Discount Amount", SalesInvoiceLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderVATAmountChange()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order Line VAT Entry and GL Entry after posting Purchase Order. BUG ID:151922
        ChangePositiveVATAmount(PurchaseLine."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceVATAmountChange()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Order Line VAT Entry and GL Entry after posting Purchase Invoice. BUG ID:151922
        ChangePositiveVATAmount(PurchaseLine."Document Type"::Invoice);
    end;

    local procedure ChangePositiveVATAmount(DocumentType: Enum "Purchase Document Type")
    var
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Setup: Create Purchase Order/Invoice.
        Initialize();
        UpdateExtDocNoPurchasesPayablesSetup(false);
        Amount := CreateAndModifyPurchaseDocument(PurchaseLine, DocumentType);

        // Exercise.
        DocumentNo := PostPurchaseDocument(PurchaseLine);

        // Verify: Verify GL entry and VAT Entry values after posting Purchase Invoice.
        VerifyGLEntry(DocumentNo, Amount);
        VerifyVATEntry(GLEntry."Document Type"::Invoice, DocumentNo, Amount, VATEntry."GST/HST"::" ");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoVATAmountChange()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase Credit Memo Line VAT Entry and GL Entry after posting Purchase Credit Memo. BUG ID:151922
        ChangeNegativeVATAmount(PurchaseLine."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchRetrunOrderVATAmountChange()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Purchase  Retrun Order Line VAT Entry and GL Entry after posting Purchase Return Order. BUG ID:151922
        ChangeNegativeVATAmount(PurchaseLine."Document Type"::"Return Order");
    end;

    local procedure ChangeNegativeVATAmount(DocumentType: Enum "Purchase Document Type")
    var
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Verify Purchase  Retrun Order Line VAT Entry and GL Entry after posting Purchase Return Order. BUG ID:151922

        // Setup: Create Purchase Return Order.
        Initialize();
        UpdateExtDocNoPurchasesPayablesSetup(false);
        Amount := CreateAndModifyPurchaseDocument(PurchaseLine, DocumentType);

        // Exercise.
        DocumentNo := PostPurchaseDocument(PurchaseLine);

        // Verify: Verify GL entry and VAT Entry values after posting Purchase Return order.
        VerifyGLEntry(DocumentNo, -Amount);
        VerifyVATEntry(GLEntry."Document Type"::"Credit Memo", DocumentNo, -Amount, VATEntry."GST/HST"::" ");
    end;

    local procedure CreateAndModifyPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"): Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Setup.
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchaseDocument(
          PurchaseLine, DocumentType, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", ''), CreateVendor(''));  // Using Blank for Tax Area Code And Tax Group Code.
        ModifyPurchaseLine(PurchaseLine, 0);  // Using 0 for Line Discount.
        PurchaseLine.Validate("VAT %", LibraryRandom.RandDec(10, 2));  // Using RANDOM value for VAT %.
        PurchaseLine.Modify(true);
        exit(PurchaseLine.Amount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsHandler,SalesTaxLinesSubformDynHandler')]
    [Scope('OnPrem')]
    procedure VATDifferenceOnPurchaseLine()
    var
        CompanyInfomation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxGroup: Record "Tax Group";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        TaxAreaCode: Code[20];
    begin
        // Verify GL entry values after posting Purchase Order,Tax Amount Change throgh Statistics page. BUG ID:151938
        Initialize();

        // Setup. Create Tax Detail and Purchase Order.
        CompanyInfomation.Get();
        PurchasesPayablesSetup.Get();
        LibraryPurchase.SetAllowVATDifference(true);
        GeneralLedgerSetup.Get();
        VATPostingSetup.Get('', '');
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        TaxDetail.Validate("Expense/Capitalize", true);
        TaxDetail.Modify(true);
        UpdateTaxAreaCodeCompanyInformation(TaxAreaCode);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxGroup.Code),
          CreateVendor(TaxAreaCode));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Tax Group Code", TaxDetail."Tax Group Code");
        PurchaseLine.Modify(true);
        UpdateMaxVATDifferenceAllowedGeneralLedgerSetup(
          Round(PurchaseLine.Amount * TaxDetail."Tax Below Maximum" / 100) + 1);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseOrderStatistics(PurchaseHeader."No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry values after posting Purchase Order.
        VerifyGLEntry(DocumentNo, PurchaseLine.Amount);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler,SalesTaxLinesSubformDynHandler')]
    [Scope('OnPrem')]
    procedure VATDifferenceOnPurchLine()
    var
        CompanyInfomation: Record "Company Information";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxGroup: Record "Tax Group";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        TaxAreaCode: Code[20];
    begin
        // Verify GL entry values after posting Purchase Order,Tax Amount Change throgh Statistics page. BUG ID:151938
        Initialize();

        // Setup. Create Tax Detail and Purchase Order.
        CompanyInfomation.Get();
        PurchasesPayablesSetup.Get();
        LibraryPurchase.SetAllowVATDifference(true);
        GeneralLedgerSetup.Get();
        VATPostingSetup.Get('', '');
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        TaxDetail.Validate("Expense/Capitalize", true);
        TaxDetail.Modify(true);
        UpdateTaxAreaCodeCompanyInformation(TaxAreaCode);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Order, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxGroup.Code),
          CreateVendor(TaxAreaCode));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Tax Group Code", TaxDetail."Tax Group Code");
        PurchaseLine.Modify(true);
        UpdateMaxVATDifferenceAllowedGeneralLedgerSetup(
          Round(PurchaseLine.Amount * TaxDetail."Tax Below Maximum" / 100) + 1);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchOrderStatistics(PurchaseHeader."No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry values after posting Purchase Order.
        VerifyGLEntry(DocumentNo, PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure VerifyValueAfterPostPurchaseOrderWithChargeItemAssgnmt()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        DocumentNo: Code[20];
        TaxAreaCode: Code[20];
        ChargeAmount: Decimal;
    begin
        // Verify Value Entries values after posting Purchase Order with Item Charge assignment.

        // Setup.
        Initialize();
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        VATPostingSetup.Get('', '');
        CreatePurchaseDocumentWithTaxArea(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"),
          CreateVendor(TaxAreaCode), TaxAreaCode);
        ChargeAmount := AddChargeAssignmentToPurchaseOrder(VATPostingSetup, TaxDetail."Tax Group Code", PurchaseLine);

        // Exercise.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Check additional charge values for Item in Value Entry.
        VerifyValueEntriesCostAmount(DocumentNo, ChargeAmount * (1 + (TaxDetail."Tax Below Maximum" / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetSummarizeSalesTaxTableWithRounding()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
        SalesTaxCalc: Codeunit "Sales Tax Calculate";
    begin
        // Verify that rounding works correctly when summarize Sales Tax Lines.

        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Order, '', '');
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group", ''),
          LibraryRandom.RandInt(10));
        SalesTaxCalc.AddSalesLine(SalesLine);
        SetupTFS358890SalesTaxLine(TempSalesTaxAmountLine);
        SalesTaxCalc.PutSalesTaxAmountLineTable(TempSalesTaxAmountLine, 0, 0, '');
        SalesTaxCalc.GetSummarizedSalesTaxTable(TempSalesTaxAmountLine);
        TempSalesTaxAmountLine.CalcSums("Tax Amount");
        Assert.AreEqual(GetTFS358890RoundingResult(), TempSalesTaxAmountLine."Tax Amount", WrongRndSummarizedTaxAmountErr);
        UpdateCustomer(SalesHeader."Bill-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorTaxAreaOnPurchInvWithJobTask()
    var
        TaxDetail: Record "Tax Detail";
        Job: Record Job;
        JobTask: Record "Job Task";
        TaxAreaCode: Code[20];
        DocumentNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Verify Purchase Invoice with Job Task posted with corrected amount in Job Ledger Entry
        Initialize();
        ModifyPurchasesPayablesSetup();
        TaxAreaCode := InitJobAndTaxDetailWithExpense(Job, JobTask, TaxDetail);
        DocumentNo := CreatePostPurchInvWithJobTask(ExpectedAmount, TaxDetail, JobTask, TaxAreaCode);
        VerifyJobLedgerEntryTotalCost(JobTask."Job No.", DocumentNo, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPartialPurchInvWithJobTaskAndTaxToBeExpensed()
    var
        TaxDetail: Record "Tax Detail";
        Job: Record Job;
        JobTask: Record "Job Task";
        PurchaseLine: Record "Purchase Line";
        TaxAreaCode: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify that "Tax To Be Expensed" correctly transfered from partially posted Purchase Invoice to "Unit Cost (LCY)" in Job Jnl. Line.

        Initialize();
        ModifyPurchasesPayablesSetup();
        TaxAreaCode := InitJobAndTaxDetailWithExpense(Job, JobTask, TaxDetail);
        DocumentNo := CreatePostPartialPurchInvWithJobTask(PurchaseLine, TaxDetail, JobTask, TaxAreaCode);
        VerifyUnitCostWithTaxInJobLedgEntry(PurchaseLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithCurrencyAndTwoLinesEvenUseTaxLines()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        GLAccountArray: array[4] of Code[20];
        ExpectedAmountArray: array[4] of Decimal;
        PurchaseLineCount: Integer;
        UseTaxLineNo: Integer;
    begin
        // [SCENARIO] Post Purchase Invoice in FCY with two lines. Second line has "Use Tax" flag.
        Initialize();
        PurchaseLineCount := 2; // number of Purchase Invoice lines
        UseTaxLineNo := 2; // use 1 (odd) or 2 (even) to define which lines will have "Use Tax" flag
        // [GIVEN] Purchase Invoice in FCY, odd or even lines has "Use Tax" flag
        CreatePurchInvWithCurrencyAndUseTaxLine(
          PurchaseHeader, GLAccountArray, ExpectedAmountArray, PurchaseLineCount, UseTaxLineNo);
        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Sales Tax distributed to Document or Vendor according to "Use Tax" value
        VerifyGLEntryUseTax(DocumentNo, GLAccountArray, ExpectedAmountArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithCurrencyAndTwoLinesOddUseTaxLines()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        GLAccountArray: array[4] of Code[20];
        ExpectedAmountArray: array[4] of Decimal;
        PurchaseLineCount: Integer;
        UseTaxLineNo: Option "None",All,Even,Odd;
    begin
        // [SCENARIO] Post Purchase Invoice in FCY with two lines. First line has "Use Tax" flag.
        Initialize();
        PurchaseLineCount := 2; // number of Purchase Invoice lines
        UseTaxLineNo := 1; // use 1 (odd) or 2 (even) to define which lines will have "Use Tax" flag
        // [GIVEN] Purchase Invoice in FCY, odd or even lines has "Use Tax" flag
        CreatePurchInvWithCurrencyAndUseTaxLine(
          PurchaseHeader, GLAccountArray, ExpectedAmountArray, PurchaseLineCount, UseTaxLineNo);
        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Sales Tax distributed to Document or Vendor according to "Use Tax" value
        VerifyGLEntryUseTax(DocumentNo, GLAccountArray, ExpectedAmountArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithCurrencyAndThreeLinesEvenUseTaxLines()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        GLAccountArray: array[4] of Code[20];
        ExpectedAmountArray: array[4] of Decimal;
        PurchaseLineCount: Integer;
        UseTaxLineNo: Integer;
    begin
        // [SCENARIO] Post Purchase Invoice in FCY with three lines. Even lines has "Use Tax" flag.
        Initialize();
        PurchaseLineCount := 3; // number of Purchase Invoice lines
        UseTaxLineNo := 2; // use 1 (odd) or 2 (even) to define which lines will have "Use Tax" flag
        // [GIVEN] Purchase Invoice in FCY, odd or even lines has "Use Tax" flag
        CreatePurchInvWithCurrencyAndUseTaxLine(
          PurchaseHeader, GLAccountArray, ExpectedAmountArray, PurchaseLineCount, UseTaxLineNo);
        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Sales Tax distributed to Document or Vendor according to "Use Tax" value
        VerifyGLEntryUseTax(DocumentNo, GLAccountArray, ExpectedAmountArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithCurrencyAndThreeLinesOddUseTaxLines()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        GLAccountArray: array[4] of Code[20];
        ExpectedAmountArray: array[4] of Decimal;
        PurchaseLineCount: Integer;
        UseTaxLineNo: Integer;
    begin
        // [SCENARIO] Post Purchase Invoice in FCY with three lines. Odd lines has "Use Tax" flag.
        Initialize();
        PurchaseLineCount := 3; // number of Purchase Invoice lines
        UseTaxLineNo := 1; // use 1 (odd) or 2 (even) to define which lines will have "Use Tax" flag
        // [GIVEN] Purchase Invoice in FCY, odd or even lines has "Use Tax" flag
        CreatePurchInvWithCurrencyAndUseTaxLine(
          PurchaseHeader, GLAccountArray, ExpectedAmountArray, PurchaseLineCount, UseTaxLineNo);
        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Sales Tax distributed to Document or Vendor according to "Use Tax" value
        VerifyGLEntryUseTax(DocumentNo, GLAccountArray, ExpectedAmountArray);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsModalPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeSalesOrderStatTaxAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        DocumentNo: Code[20];
        TaxAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        NewTaxAmount: Decimal;
        UnitPrice: Decimal;
        SalesTaxPct: Integer;
    begin
        // [SCENARIO] Create Sales Order, open Statistics, change Tax Amount and post document

        Initialize();
        UnitPrice := 854224.16; // hardcoded "Unit Price" to get required difference
        NewTaxAmount := 42711.44;
        SalesTaxPct := 5; // hardcoded sales tax percent to get required difference
        SetVATDiffSetup(1, true);
        // [GIVEN] Sales Order with specific Amount and Sales Tax % to get required difference
        CreateSalesTaxSetupWithSpecificTaxPct(TaxAreaCode, TaxGroupCode, TaxAccountNo, SalesTaxPct, 0);
        CreateSalesDocumentWithSpecificAmountAndTaxArea(SalesHeader, TaxAreaCode, TaxGroupCode, UnitPrice);
        LibraryVariableStorage.Enqueue(NewTaxAmount);

        // [WHEN] Open Statistics, drilldown to Tax entries and "manually" change Tax Amount. Post document.
        OpenSalesOrderPage(SalesOrder, SalesHeader); // calls SalesOrderStatsModalPageHandler
        SalesOrder.Statistics.Invoke();
        // [WHEN] Post document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entry with changed Tax Amount exist
        VerifyGLEntryTaxAmount(DocumentNo, TaxAccountNo, -NewTaxAmount);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeSalesOrderStatTaxAmountNM()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        DocumentNo: Code[20];
        TaxAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        NewTaxAmount: Decimal;
        UnitPrice: Decimal;
        SalesTaxPct: Integer;
    begin
        // [SCENARIO] Create Sales Order, open Statistics, change Tax Amount and post document

        Initialize();
        UnitPrice := 854224.16; // hardcoded "Unit Price" to get required difference
        NewTaxAmount := 42711.44;
        SalesTaxPct := 5; // hardcoded sales tax percent to get required difference
        SetVATDiffSetup(1, true);
        // [GIVEN] Sales Order with specific Amount and Sales Tax % to get required difference
        CreateSalesTaxSetupWithSpecificTaxPct(TaxAreaCode, TaxGroupCode, TaxAccountNo, SalesTaxPct, 0);
        CreateSalesDocumentWithSpecificAmountAndTaxArea(SalesHeader, TaxAreaCode, TaxGroupCode, UnitPrice);
        LibraryVariableStorage.Enqueue(NewTaxAmount);

        // [WHEN] Open Statistics, drilldown to Tax entries and "manually" change Tax Amount. Post document.
        OpenSalesOrderPage(SalesOrder, SalesHeader); // calls SalesOrderStatsModalPageHandler
        SalesOrder.SalesOrderStats.Invoke();
        // [WHEN] Post document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entry with changed Tax Amount exist
        VerifyGLEntryTaxAmount(DocumentNo, TaxAccountNo, -NewTaxAmount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure ChangePurchaseOrderStatTaxAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        DocumentNo: Code[20];
        TaxAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        NewTaxAmount: Decimal;
        DirectUnitCost: Decimal;
        SalesTaxPct: Integer;
    begin
        // [SCENARIO] Create Purchase Order, open Statistics, change Tax Amount and post document

        Initialize();
        DirectUnitCost := 854224.16; // hardcoded "Direct Unit Cost" to get required difference
        NewTaxAmount := 42711.44;
        SalesTaxPct := 5; // hardcoded sales tax percent to get required difference
        SetVATDiffSetup(1, true);

        // [GIVEN] Purchase Order with specific Amount and Sales Tax % to get required difference
        CreateSalesTaxSetupWithSpecificTaxPct(TaxAreaCode, TaxGroupCode, TaxAccountNo, SalesTaxPct, 1);
        CreatePurchaseDocumentWithSpecificAmountAndTaxArea(PurchaseHeader, TaxAreaCode, TaxGroupCode, DirectUnitCost);
        LibraryVariableStorage.Enqueue(NewTaxAmount);

        // [WHEN] Open Statistics, drilldown to Tax entries and "manually" change Tax Amount.
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader); // calls PurchOrderStatisticsPageHandler
        PurchaseOrder.Statistics.Invoke();
        // [WHEN] Post document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry with changed Tax Amount exist
        VerifyGLEntryTaxAmount(DocumentNo, TaxAccountNo, NewTaxAmount);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler,SalesTaxLinesSubformDynPageHandler')]
    [Scope('OnPrem')]
    procedure ChangePurchOrderStatTaxAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        DocumentNo: Code[20];
        TaxAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        NewTaxAmount: Decimal;
        DirectUnitCost: Decimal;
        SalesTaxPct: Integer;
    begin
        // [SCENARIO] Create Purchase Order, open Statistics, change Tax Amount and post document

        Initialize();
        DirectUnitCost := 854224.16; // hardcoded "Direct Unit Cost" to get required difference
        NewTaxAmount := 42711.44;
        SalesTaxPct := 5; // hardcoded sales tax percent to get required difference
        SetVATDiffSetup(1, true);

        // [GIVEN] Purchase Order with specific Amount and Sales Tax % to get required difference
        CreateSalesTaxSetupWithSpecificTaxPct(TaxAreaCode, TaxGroupCode, TaxAccountNo, SalesTaxPct, 1);
        CreatePurchaseDocumentWithSpecificAmountAndTaxArea(PurchaseHeader, TaxAreaCode, TaxGroupCode, DirectUnitCost);
        LibraryVariableStorage.Enqueue(NewTaxAmount);

        // [WHEN] Open Statistics, drilldown to Tax entries and "manually" change Tax Amount.
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader); // calls PurchaseOrderStatisticsPageHandler
        PurchaseOrder.PurchaseOrderStats.Invoke();
        // [WHEN] Post document.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry with changed Tax Amount exist
        VerifyGLEntryTaxAmount(DocumentNo, TaxAccountNo, NewTaxAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiveItemInTwoTransactionsAndInvoiceItemCharge()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyToPost: Decimal;
    begin
        // [SCENARIO 359660] Value entry for item charge is created when item is received in two separate receipts before applying item charge
        Initialize();

        // [GIVEN] Purchase order with 2 lines: item and item charge
        CreatePurchaseOrderWithItemCharge(PurchaseHeader, PurchaseLine);

        // [GIVEN] Both item and item charge are partially received and invoiced
        QtyToPost := LibraryRandom.RandDec(PurchaseLine.Quantity, 2) / 2;
        PostPurchaseItemLine(PurchaseHeader, QtyToPost, QtyToPost);
        PostPurchaseChargeLine(PurchaseHeader, QtyToPost, QtyToPost);

        // [GIVEN] Item line is completely received, but remains to be invoiced
        QtyToPost := PurchaseLine.Quantity - QtyToPost;
        PostPurchaseItemLine(PurchaseHeader, QtyToPost, 0);
        // [GIVEN] Item charge is completely received and invoiced
        PostPurchaseChargeLine(PurchaseHeader, QtyToPost, QtyToPost);

        // [WHEN] Posting final invoice for the remaining quantity on item line
        PostPurchaseItemLine(PurchaseHeader, 0, QtyToPost);

        // [THEN] Value entry with item charge is created
        VerifyItemChargeIsPosted(PurchaseLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithCurrencyAndProvincialTax()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        GLAccountArray: array[4] of Code[20];
        ExpectedAmountArray: array[4] of Decimal;
    begin
        // [FEATURE] [Purchase] [Provincial Tax] [Currency]
        // [SCENARIO] Post Purchase Invoice in FCY with Provincial Tax.
        Initialize();
        // [GIVEN] Purchase Invoice in FCY, "Provincial Tax Area Code" filled in.
        CreatePurchInvWithCurrencyAndProvTax(PurchaseHeader, GLAccountArray, ExpectedAmountArray);
        // [WHEN] Post Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        // [THEN] Sales Tax distributed to Document or Vendor according to "Use Tax" value
        VerifyGLEntryUseTax(DocumentNo, GLAccountArray, ExpectedAmountArray);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithProvTaxAndExpense_FCY()
    var
        PurchaseHeader: Record "Purchase Header";
        NoTaxAreaCode: Code[20];
        ProvTaxAreaCode: Code[20];
        TaxableTaxGroupCode: Code[10];
        TaxJurisdictionCode: array[4] of Code[10];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Provincial Tax] [Currency] [Expense/Capitalize]
        // [SCENARIO 216424] Posting of a purchase invoice with Currency, "Tax Area Code" = "NOTAX", "Provincial Tax Area Code" = "PROVTAX",
        // [SCENARIO 216424] where "PROVTAX" - tax area with several tax jurisdictions having tax detail lines setup with "Expense/Capitalize" = TRUE
        Initialize();

        // [GIVEN] Sales Tax Groups: "TAXABLE", "NONTAXABLE"
        // [GIVEN] Sales Tax Area "NOTAX" with "NOTAX" jutrisdiction line
        // [GIVEN] Sales Tax Area "PROVTAX" with several custom jurisdiction lines including "Expense/Capitalize" = TRUE setup
        CreateCustomTaxSetup_TFS216424(NoTaxAreaCode, ProvTaxAreaCode, TaxableTaxGroupCode, TaxJurisdictionCode, DummyTaxCountry::CA);

        // [GIVEN] Purchase invoice with Currency, "Tax Liable" = TRUE, "Tax Area Code" = "NOTAX", "Provincial Tax Area Code" = "PROVTAX" and G/L Account line
        GLAccountNo := CreateGLAccount('', TaxableTaxGroupCode);
        CreatePurchaseInvoiceWithProvTaxSetup(
          PurchaseHeader, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 0.74783, 0.74783),
          NoTaxAreaCode, ProvTaxAreaCode, GLAccountNo, 100);

        // [WHEN] Post the purchase invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        VerifyGLEntries_TFS216424(PurchaseHeader."Buy-from Vendor No.", DocumentNo, GLAccountNo, TaxJurisdictionCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithProvTaxAndExpense_LCY()
    var
        PurchaseHeader: Record "Purchase Header";
        NoTaxAreaCode: Code[20];
        ProvTaxAreaCode: Code[20];
        TaxableTaxGroupCode: Code[10];
        TaxJurisdictionCode: array[4] of Code[10];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Provincial Tax] [Expense/Capitalize]
        // [SCENARIO 216424] Posting of a purchase invoice with "Tax Area Code" = "NOTAX", "Provincial Tax Area Code" = "PROVTAX",
        // [SCENARIO 216424] where "PROVTAX" - tax area with several tax jurisdictions having tax detail lines setup with "Expense/Capitalize" = TRUE
        Initialize();

        // [GIVEN] Sales Tax Groups: "TAXABLE", "NONTAXABLE"
        // [GIVEN] Sales Tax Area "NOTAX" with "NOTAX" jutrisdiction line
        // [GIVEN] Sales Tax Area "PROVTAX" with several custom jurisdiction lines including "Expense/Capitalize" = TRUE setup
        CreateCustomTaxSetup_TFS216424(NoTaxAreaCode, ProvTaxAreaCode, TaxableTaxGroupCode, TaxJurisdictionCode, DummyTaxCountry::CA);

        // [GIVEN] Purchase invoice with "Tax Liable" = TRUE, "Tax Area Code" = "NOTAX", "Provincial Tax Area Code" = "PROVTAX" and G/L Account line
        GLAccountNo := CreateGLAccount('', TaxableTaxGroupCode);
        CreatePurchaseInvoiceWithProvTaxSetup(PurchaseHeader, '', NoTaxAreaCode, ProvTaxAreaCode, GLAccountNo, 133.72);

        // [WHEN] Post the purchase invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        VerifyGLEntries_TFS216424(PurchaseHeader."Buy-from Vendor No.", DocumentNo, GLAccountNo, TaxJurisdictionCode);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatExciseTaxAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Sales Tax] [Excise Tax] [Statistics]
        // [SCENARIO 361729] Excise Tax Amount on the Purchase Order Statistics page
        Initialize();
        // [GIVEN] Purchase Order with Excise Tax, tax amount = "Y"
        CreatePurchOrderWithExciseTax(PurchaseHeader, TaxAmount);
        LibraryVariableStorage.Enqueue(TaxAmount);
        // [WHEN] Open Purchase Order Statistics
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);
        PurchaseOrder.Statistics.Invoke();
        // [THEN] "Tax Amount" field on statistics page = "Y"
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderStatExciseTaxAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrder: TestPage "Purchase Order";
        TaxAmount: Decimal;
    begin
        // [FEATURE] [Sales Tax] [Excise Tax] [Statistics]
        // [SCENARIO 361729] Excise Tax Amount on the Purchase Order Statistics page
        Initialize();
        // [GIVEN] Purchase Order with Excise Tax, tax amount = "Y"
        CreatePurchOrderWithExciseTax(PurchaseHeader, TaxAmount);
        LibraryVariableStorage.Enqueue(TaxAmount);
        // [WHEN] Open Purchase Order Statistics
        OpenPurchaseOrderPage(PurchaseOrder, PurchaseHeader);
        PurchaseOrder.PurchaseOrderStats.Invoke();
        // [THEN] "Tax Amount" field on statistics page = "Y"
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvoiceExciseTaxAmountLine()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales Tax] [Excise Tax]
        // [SCENARIO 362131] Excise Tax Amount dependency on "Quantity (Base)" in posted Purchase Invoice
        Initialize();
        // [GIVEN] Posted Purchase Invoice with Excise Tax, "Quantity (Base)" = "X", Excise tax % = "Y"
        CreateAndPostPurchDocWithExciseTax(
          DocumentNo, TaxAmount, PostingDate, PurchaseHeader."Document Type"::Invoice);
        // [WHEN] Simulate Sales Tax calculation
        MockSalesTaxCalc(SalesTaxAmountLine, DocumentNo, PostingDate, DATABASE::"Purch. Inv. Header");
        // [THEN] "Tax Amount" in Sales Tax Amount Line = "X" * "Y"
        Assert.AreEqual(TaxAmount, SalesTaxAmountLine."Tax Amount", TaxAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoExciseTaxAmountLine()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales Tax] [Excise Tax]
        // [SCENARIO 362131] Excise Tax Amount dependency on "Quantity (Base)" in posted Purchase Credit Memo
        Initialize();
        // [GIVEN] Posted Purchase Credit Memo with Excise Tax, "Quantity (Base)" = "X", Excise tax % = "Y"
        CreateAndPostPurchDocWithExciseTax(
          DocumentNo, TaxAmount, PostingDate, PurchaseHeader."Document Type"::"Credit Memo");
        // [WHEN] Simulate Sales Tax calculation
        MockSalesTaxCalc(SalesTaxAmountLine, DocumentNo, PostingDate, DATABASE::"Purch. Cr. Memo Hdr.");
        // [THEN] "Tax Amount" in Sales Tax Amount Line = "X" * "Y"
        Assert.AreEqual(TaxAmount, SalesTaxAmountLine."Tax Amount", TaxAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceExciseTaxAmountLine()
    var
        SalesHeader: Record "Sales Header";
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales Tax] [Excise Tax]
        // [SCENARIO 362131] Excise Tax Amount dependency on "Quantity (Base)" in posted Sales Invoice
        Initialize();
        // [GIVEN] Posted Sales Invoice with Excise Tax, "Quantity (Base)" = "X", Excise tax % = "Y"
        CreateAndPostSalesDocWithExciseTax(
          DocumentNo, TaxAmount, PostingDate, SalesHeader."Document Type"::Invoice);
        // [WHEN] Simulate Sales Tax calculation
        MockSalesTaxCalc(SalesTaxAmountLine, DocumentNo, PostingDate, DATABASE::"Sales Invoice Header");
        // [THEN] "Tax Amount" in Sales Tax Amount Line = "X" * "Y"
        Assert.AreEqual(TaxAmount, SalesTaxAmountLine."Tax Amount", TaxAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoExciseTaxAmountLine()
    var
        SalesHeader: Record "Sales Header";
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        DocumentNo: Code[20];
        TaxAmount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [Sales Tax] [Excise Tax]
        // [SCENARIO 362131] Excise Tax Amount dependency on "Quantity (Base)" in posted Sales Credit Memo
        Initialize();
        // [GIVEN] Posted Sales Credit Memo with Excise Tax, "Quantity (Base)" = "X", Excise tax % = "Y"
        CreateAndPostSalesDocWithExciseTax(
          DocumentNo, TaxAmount, PostingDate, SalesHeader."Document Type"::"Credit Memo");
        // [WHEN] Simulate Sales Tax calculation
        MockSalesTaxCalc(SalesTaxAmountLine, DocumentNo, PostingDate, DATABASE::"Sales Cr.Memo Header");
        // [THEN] "Tax Amount" in Sales Tax Amount Line = "X" * "Y"
        Assert.AreEqual(TaxAmount, SalesTaxAmountLine."Tax Amount", TaxAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderRoundingWithExciseTaxAndTaxOnTax()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        DocumentNo: Code[20];
        SalesTaxAccountNo: Code[20];
        PurchaseTaxAccountNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Sales Tax] [Excise Tax] [Tax On Tax]
        // [SCENARIO 363004] Sales Order rounding posting with specific Tax Area Setup (Excise Tax, Calculate Tax On Tax)
        Initialize();

        // [GIVEN] Tax Area Setup with two lines:
        // [GIVEN] Tax Detail Line 1:  "Tax Type" = "Sales and Use Tax", "Tax Below Maximum" = 5, "Calculate Tax On Tax" = TRUE
        // [GIVEN] Tax Detail Line 2:  "Tax Type" = "Excise Tax", "Tax Below Maximum" = 10.25, "Calculate Tax On Tax" = FALSE
        CreateTaxAreaSetupWithTwoLinesExciseTaxAndSpecificAmounts(
          TaxAreaCode, TaxGroupCode, SalesTaxAccountNo, PurchaseTaxAccountNo, 5, 10.25);

        // [GIVEN] Sales Order with Tax Area Setup and Unit Price = 723.65
        CreateSalesDocumentWithSpecificAmountAndTaxArea(SalesHeader, TaxAreaCode, TaxGroupCode, 723.65);

        // [WHEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Order posted with Tax Amount = 36.70 on Sales Tax Account
        VerifyGLEntryTaxAmount(DocumentNo, SalesTaxAccountNo, -36.7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderRoundingWithExciseTaxAndTaxOnTax()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        DocumentNo: Code[20];
        SalesTaxAccountNo: Code[20];
        PurchaseTaxAccountNo: Code[20];
    begin
        // [FEATURE] [Purchase Order] [Sales Tax] [Excise Tax] [Tax On Tax]
        // [SCENARIO 363004] Purchase Order rounding posting with specific Tax Area Setup (Excise Tax, Calculate Tax On Tax)
        Initialize();

        // [GIVEN] Tax Area Setup with two lines:
        // [GIVEN] Tax Detail Line 1:  "Tax Type" = "Sales and Use Tax", "Tax Below Maximum" = 5, "Calculate Tax On Tax" = TRUE
        // [GIVEN] Tax Detail Line 2:  "Tax Type" = "Excise Tax", "Tax Below Maximum" = 10.25, "Calculate Tax On Tax" = FALSE
        CreateTaxAreaSetupWithTwoLinesExciseTaxAndSpecificAmounts(
          TaxAreaCode, TaxGroupCode, SalesTaxAccountNo, PurchaseTaxAccountNo, 5, 10.25);

        // [GIVEN] Purchase Order with Tax Area Setup and Unit Price = 723.65
        CreatePurchaseDocumentWithSpecificAmountAndTaxArea(PurchaseHeader, TaxAreaCode, TaxGroupCode, 723.65);

        // [WHEN] Post Purchase Order
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Order posted with Tax Amount = 36.70 on Purchase Tax Account
        VerifyGLEntryTaxAmount(DocumentNo, PurchaseTaxAccountNo, 36.7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotZeroAmountInPurchInvoiceWithTaxOnReopen()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [SCENARIO 363302] Not a zero amount after reopening released Purchase Order with Sales Tax

        Initialize();
        ModifyPurchasesPayablesSetup();
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);

        // [GIVEN] Released Purchase Order with Sales Tax
        CreateReleasePurchOrder(PurchaseHeader, PurchaseLine, '', TaxDetail."Tax Group Code", TaxAreaCode);

        // [WHEN] Reopen Purchase Order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [THEN] Amount Including VAT <> 0
        PurchaseLine.Find();
        Assert.AreNotEqual(0, PurchaseLine."Amount Including VAT", PurchaseLine.FieldCaption("Amount Including VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameAmountInPurchInvoiceWithVATOnReopen()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AmountInclVAT: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 363302] Amount is not changed after reopening released Purchase Order with VAT

        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        // [GIVEN] Released Purchase Order with VAT and Amount Including VAT = 125
        CreateReleasePurchOrder(
          PurchaseHeader, PurchaseLine, VATPostingSetup."VAT Prod. Posting Group", '', '');
        AmountInclVAT := PurchaseLine."Amount Including VAT";

        // [WHEN] Reopen Purchase Order
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);

        // [THEN] Amount Including VAT = 125
        PurchaseLine.Find();
        Assert.AreEqual(AmountInclVAT, PurchaseLine."Amount Including VAT", PurchaseLine.FieldCaption("Amount Including VAT"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NotZeroAmountInSalesInvoiceWithTaxOnReopen()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [SCENARIO 363302] Not a zero amount after reopening released Sales Order with Sales Tax

        Initialize();
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);

        // [GIVEN] Released Sales Order with Sales Tax
        CreateReleaseSalesOrder(SalesHeader, SalesLine, '', TaxDetail."Tax Group Code", TaxAreaCode);

        // [WHEN] Reopen Sales Order
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [THEN] Amount Including VAT <> 0
        SalesLine.Find();
        Assert.AreNotEqual(0, SalesLine."Amount Including VAT", SalesLine.FieldCaption("Amount Including VAT"));
        UpdateCustomer(SalesHeader."Bill-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameAmountInSalesInvoiceWithVATOnReopen()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AmountInclVAT: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363302] Amount is not changed after reopening released Sales Order with VAT

        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        // [GIVEN] Released Sales Order with VAT and Amount Including VAT = 125
        CreateReleaseSalesOrder(SalesHeader, SalesLine, VATPostingSetup."VAT Prod. Posting Group", '', '');
        AmountInclVAT := SalesLine."Amount Including VAT";

        // [WHEN] Reopen Sales Order
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [THEN] Amount Including VAT = 125
        SalesLine.Find();
        Assert.AreEqual(AmountInclVAT, SalesLine."Amount Including VAT", SalesLine.FieldCaption("Amount Including VAT"));
        UpdateCustomer(SalesHeader."Bill-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FCYSalesOrderWithPrepmtInvoice()
    var
        SalesHeader: Record "Sales Header";
        DocNo: Code[20];
    begin
        // [SCENARIO 372265] Post FCY Sales Order after Prepayment Invoice is posted with custom Amount and Exchange Rate
        Initialize();
        // [GIVEN] FCY Sales Order with custom Amount = 999 and Exchange Rate (1:1.25)
        CreateFCYSalesOrderWithCustomAmountAndExchageRate(SalesHeader);
        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        // [WHEN] Post Sales Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [THEN] GLEntry.Amount = 999 * 1.25 = -1248.75
        VerifyGLEntryCustomAmount(DocNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithNegativeLineAndCustomAmounts()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        TaxAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        DirectUnitCost: array[2] of Decimal;
        SalesTaxPct: Integer;
    begin
        // [FEATURE] [Rounding] [Purchase] [Negative Line]
        // [SCENARIO 375539] Purchase Order with two lines, the last line is negative
        Initialize();
        DirectUnitCost[1] := 1229; // hardcoded "Direct Unit Cost" to get required rounding issue
        DirectUnitCost[2] := -93.3; // hardcoded "Direct Unit Cost" to get required rounding issue
        SalesTaxPct := 5; // hardcoded sales tax percent to get required rounding issue

        // [GIVEN] Purchase Order with two lines (the last line is negative) with specific Amount and Sales Tax % to get required difference
        CreateSalesTaxSetupWithSpecificTaxPct(TaxAreaCode, TaxGroupCode, TaxAccountNo, SalesTaxPct, 1);
        CreatePurchDocWithNegativeLineAndCustomAmounts(PurchaseHeader, TaxAreaCode, TaxGroupCode, DirectUnitCost);

        // [WHEN] Post document
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry with specified Tax Amount exist
        VerifyGLEntryTaxAmount(DocumentNo, TaxAccountNo, 56.79);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsForTaxAreaWithMoreThan4Jurisdictions()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        Counter: Integer;
        TaxAreaCode: Code[20];
    begin
        // [FEAUTURE] [Purchase Order]
        // [SCENARIO 379686] When more than 4 tax jurisdictions are contained in the tax area selected on the purchase order
        // [SCENARIO] an "Index out of bounds." error message should appear on opening the Purchase Order Statistics page

        Initialize();

        // [GIVEN] Tax Area TA with 5 tax jurisdictions and Country = 'CA'
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();

        TaxGroup.FindFirst();

        for Counter := 1 to 5 do
            CreateTaxJurisdictionAndTaxDetail(TaxAreaCode, TaxGroup.Code);

        // [GIVEN] Vendor V with "Tax Area Code" = TA and "Tax Liable" = TRUE
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Liable", true);
        Vendor.Modify(true);

        if not VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);

        // [GIVEN] Purchase order for Vendor V with "Tax Area Code" = TA in Header and Line and "Tax Liable" = TRUE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroup.Code, true), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Tax Group Code", TaxGroup.Code);
        PurchaseLine.Modify(true);

        // [WHEN] Open Purchase Order Statistics
        LibraryVariableStorage.Enqueue(Round(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100));
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.Statistics.Invoke();  // Opens Page Handler - PurchaseOrderStatsPageHandler
        PurchaseOrder.Close();

        // [THEN] No error message appear
        // "Tax Amount" Assertion is done in PurchaseOrderStatsPageHandler
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsTestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsForTaxAreaWithMoreThan4Jurisdictions()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxGroup: Record "Tax Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        PurchaseOrder: TestPage "Purchase Order";
        Counter: Integer;
        TaxAreaCode: Code[20];
    begin
        // [FEAUTURE] [Purchase Order]
        // [SCENARIO 379686] When more than 4 tax jurisdictions are contained in the tax area selected on the purchase order
        // [SCENARIO] an "Index out of bounds." error message should appear on opening the Purchase Order Statistics page

        Initialize();

        // [GIVEN] Tax Area TA with 5 tax jurisdictions and Country = 'CA'
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();

        TaxGroup.FindFirst();

        for Counter := 1 to 5 do
            CreateTaxJurisdictionAndTaxDetail(TaxAreaCode, TaxGroup.Code);

        // [GIVEN] Vendor V with "Tax Area Code" = TA and "Tax Liable" = TRUE
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Liable", true);
        Vendor.Modify(true);

        if not VATPostingSetup.Get(Vendor."VAT Bus. Posting Group", '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);

        // [GIVEN] Purchase order for Vendor V with "Tax Area Code" = TA in Header and Line and "Tax Liable" = TRUE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroup.Code, true), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Tax Group Code", TaxGroup.Code);
        PurchaseLine.Modify(true);

        // [WHEN] Open Purchase Order Statistics
        LibraryVariableStorage.Enqueue(Round(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100));
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder.PurchaseOrderStats.Invoke();  // Opens Page Handler - PurchaseOrderStatsPageHandler
        PurchaseOrder.Close();

        // [THEN] No error message appear
        // "Tax Amount" Assertion is done in PurchOrderStatsPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithTwoTaxDetailsWhenMaximumAmountQtyIsSpecified()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail1: Record "Tax Detail";
        TaxDetail2: Record "Tax Detail";
        GLEntry: Record "G/L Entry";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 200992] Sales Order posting with rounding for 2 Tax Details when "Maximum Amount/Qty" is specified
        Initialize();
        UpdateVATInUseOnGLSetup();

        // [GIVEN] Sales Tax Setup has 1st line of Tax Detail with "Tax Below Maximum" = 6
        // [GIVEN] Sales Tax Setup has 2nd line of Tax Detail with "Tax Below Maximum" = 1.5 and "Maximum Amount/Qty" = 5000
        // [GIVEN] Tax Account (Sales) = "X"
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxAreaSetupWithValues(TaxDetail1, TaxAreaCode, TaxGroupCode, 6, 0, GLAccountNo);
        CreateTaxAreaSetupWithValues(TaxDetail2, TaxAreaCode, TaxGroupCode, 1.5, 5000, GLAccountNo);

        // [GIVEN] Tax Liable Sales Order with Amount = 5074.25
        // [GIVEN] Generated Tax Amount consisits of 1.5% * 5000 = 75 (due to amount limit) and 6% * 5074.25 = 304.455, in total of 379.455
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Order, '', TaxAreaCode);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail1."Tax Group Code", 5074.25);

        // [WHEN] Post Sales Order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Tax Amount is posted as 379.46 for G/L Account "X"
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, -379.46);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithSeveralCustomLinesAndExpense_CA()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize]
        // [SCENARIO 210430] Purchase invoice posting in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Purchase invoice with several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, TaxAreaCode, TaxGroupCode, '');

        // [WHEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] VLE Amount = 6291.63
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountPurchases(TaxAreaCode), 280.88);
        VerifyVLEAmount(DocumentNo, PurchaseHeader."Buy-from Vendor No.", -6291.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithSeveralCustomLinesAndExpense_CA()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize]
        // [SCENARIO 210430] Sales invoice posting in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Sales invoice with several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode, TaxGroupCode, '');

        // [WHEN] Post the invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] CLE Amount = 6291.63
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountSales(TaxAreaCode), -280.88);
        VerifyCLEAmount(DocumentNo, SalesHeader."Sell-to Customer No.", 6291.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithSeveralCustomLinesAndExpense_US()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize]
        // [SCENARIO 210430] Purchase invoice posting in case of Tax Country = US, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Purchase invoice with several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, TaxAreaCode, TaxGroupCode, '');

        // [WHEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] VLE Amount = 6291.63
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountPurchases(TaxAreaCode), 280.88);
        VerifyVLEAmount(DocumentNo, PurchaseHeader."Buy-from Vendor No.", -6291.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithSeveralCustomLinesAndExpense_US()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize]
        // [SCENARIO 210430] Sales invoice posting in case of Tax Country = US, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Sales invoice with several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode, TaxGroupCode, '');

        // [WHEN] Post the invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] CLE Amount = 6291.62
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountSales(TaxAreaCode), -280.88);
        VerifyCLEAmount(DocumentNo, SalesHeader."Sell-to Customer No.", 6291.62);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithSeveralCustomLinesAndExpense_Currency_CA()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Currency] [Expense/Capitalize]
        // [SCENARIO 210430] Purchase invoice posting in case of Tax Country = CA, Expense, FCY, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Purchase invoice with FCY, several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] VLE Amount = 6291.63
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountPurchases(TaxAreaCode), 280.88);
        VerifyVLEAmount(DocumentNo, PurchaseHeader."Buy-from Vendor No.", -6291.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithSeveralCustomLinesAndExpense_Currency_CA()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Currency] [Expense/Capitalize]
        // [SCENARIO 210430] Sales invoice posting in case of Tax Country = CA, Expense, FCY, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Sales invoice with FCY, several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Post the invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] CLE Amount = 6291.63
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountSales(TaxAreaCode), -280.88);
        VerifyCLEAmount(DocumentNo, SalesHeader."Sell-to Customer No.", 6291.63);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithSeveralCustomLinesAndExpense_Currency_US()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Currency] [Expense/Capitalize]
        // [SCENARIO 210430] Purchase invoice posting in case of Tax Country = US, Expense, FCY, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Purchase invoice with FCY, several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] VLE Amount = 6291.62
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountPurchases(TaxAreaCode), 280.88);
        VerifyVLEAmount(DocumentNo, PurchaseHeader."Buy-from Vendor No.", -6291.62);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithSeveralCustomLinesAndExpense_Currency_US()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Currency] [Expense/Capitalize]
        // [SCENARIO 210430] Sales invoice posting in case of Tax Country = US, Expense, FCY, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Sales invoice with FCY, several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Post the invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] CLE Amount = 6291.62
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountSales(TaxAreaCode), -280.88);
        VerifyCLEAmount(DocumentNo, SalesHeader."Sell-to Customer No.", 6291.62);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceTwoJurisdiction3LastNegativeLines_CA()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize]
        // [SCENARIO 212811] Purchase invoice posting in case of Tax Country = CA, Expense, several custom lines including negative
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Purchase invoice with several lines with custom amounts, including negative
        CreateCustomPurchaseInvoice_TFS212811(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, TaxAreaCode, TaxGroupCode, '');

        // [WHEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] VLE Amount = 6291.61
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountPurchases(TaxAreaCode), 280.88);
        VerifyVLEAmount(DocumentNo, PurchaseHeader."Buy-from Vendor No.", -6291.61);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTwoJurisdiction3LastNegativeLines_CA()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize]
        // [SCENARIO 212811] Sales invoice posting in case of Tax Country = CA, Expense, several custom lines including negative
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Sales invoice with several lines with custom amounts, including negative
        CreateCustomSalesInvoice_TFS212811(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode, TaxGroupCode, '');

        // [WHEN] Post the invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] CLE Amount = 6291.61
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountSales(TaxAreaCode), -280.88);
        VerifyCLEAmount(DocumentNo, SalesHeader."Sell-to Customer No.", 6291.61);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceTwoJurisdiction3LastNegativeLines_US()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize]
        // [SCENARIO 212811] Purchase invoice posting in case of Tax Country = US, Expense, several custom lines including negative
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Purchase invoice with several lines with custom amounts, including negative
        CreateCustomPurchaseInvoice_TFS212811(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, TaxAreaCode, TaxGroupCode, '');

        // [WHEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] VLE Amount = 6291.61
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountPurchases(TaxAreaCode), 280.88);
        VerifyVLEAmount(DocumentNo, PurchaseHeader."Buy-from Vendor No.", -6291.61);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTwoJurisdiction3LastNegativeLines_US()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize]
        // [SCENARIO 212811] Sales invoice posting in case of Tax Country = US, Expense, several custom lines including negative
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Sales invoice with several lines with custom amounts, including negative
        CreateCustomSalesInvoice_TFS212811(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode, TaxGroupCode, '');

        // [WHEN] Post the invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] CLE Amount = 6291.6
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountSales(TaxAreaCode), -280.88);
        VerifyCLEAmount(DocumentNo, SalesHeader."Sell-to Customer No.", 6291.6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceTwoJurisdiction3LastNegativeLinesFCY_CA()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Currency] [Expense/Capitalize]
        // [SCENARIO 212811] Purchase invoice posting in case of Tax Country = CA, Expense, FCY, several custom lines including negative
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Purchase invoice with FCY, several lines with custom amounts, including negative
        CreateCustomPurchaseInvoice_TFS212811(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] VLE Amount = 6291.61
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountPurchases(TaxAreaCode), 280.88);
        VerifyVLEAmount(DocumentNo, PurchaseHeader."Buy-from Vendor No.", -6291.61);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTwoJurisdiction3LastNegativeLinesFCY_CA()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Currency] [Expense/Capitalize]
        // [SCENARIO 212811] Sales invoice posting in case of Tax Country = CA, Expense, FCY, several custom lines including negative
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Sales invoice with FCY, several lines with custom amounts, including negative
        CreateCustomSalesInvoice_TFS212811(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Post the invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] CLE Amount = 6291.61
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountSales(TaxAreaCode), -280.88);
        VerifyCLEAmount(DocumentNo, SalesHeader."Sell-to Customer No.", 6291.61);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceTwoJurisdiction3LastNegativeLinesFCY_US()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Currency] [Expense/Capitalize]
        // [SCENARIO 212811] Purchase invoice posting in case of Tax Country = US, Expense, FCY, several custom lines including negative
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Purchase invoice with FCY, several lines with custom amounts, including negative
        CreateCustomPurchaseInvoice_TFS212811(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Post the invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] VLE Amount = 6291.6
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountPurchases(TaxAreaCode), 280.88);
        VerifyVLEAmount(DocumentNo, PurchaseHeader."Buy-from Vendor No.", -6291.6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTwoJurisdiction3LastNegativeLinesFCY_US()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Currency] [Expense/Capitalize]
        // [SCENARIO 212811] Sales invoice posting in case of Tax Country = US, Expense, FCY, several custom lines including negative
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Sales invoice with FCY, several lines with custom amounts, including negative
        CreateCustomSalesInvoice_TFS212811(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Post the invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The invoice has been posted
        // [THEN] CLE Amount = 6291.6
        // [THEN] G/L Entry Amount for Tax = 280.88
        VerifyGLEntryTaxAmount(DocumentNo, GetTaxAccountSales(TaxAreaCode), -280.88);
        VerifyCLEAmount(DocumentNo, SalesHeader."Sell-to Customer No.", 6291.6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedPurchInvoiceWithTaxDifferenceToPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        DummySalesTaxAmountDifference: Record "Sales Tax Amount Difference";
        CrMemoPurchaseHeader: Record "Purchase Header";
        PostedPurchInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Copy Document] [Tax Difference]
        // [SCENARIO 214207] Sales Tax Amount Difference should be copied from Posted Purchase Invoice to Purchase Cr. Memo by Copy Document
        Initialize();

        // [GIVEN] Posted Purchase Invoice with Sales Tax Amount Difference
        UpdateMaxVATDifferenceAllowedGeneralLedgerSetup(LibraryRandom.RandIntInRange(10, 100));
        LibraryPurchase.SetAllowVATDifference(true);
        CreatePurchInvoiceWithTaxDifference(PurchaseHeader, DummySalesTaxAmountDifference."Document Product Area"::Purchase);
        PostedPurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Created blank purchase credit memo
        LibraryPurchase.CreatePurchHeader(
          CrMemoPurchaseHeader, CrMemoPurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Copy the posted purchase invoice to credit memo by Copy Document
        LibraryPurchase.CopyPurchaseDocument(CrMemoPurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PostedPurchInvoiceNo, true, false);

        // [THEN] Sales Tax Amount Difference has been copied
        DummySalesTaxAmountDifference.SetRange("Document No.", CrMemoPurchaseHeader."No.");
        DummySalesTaxAmountDifference.SetRange("Document Type", CrMemoPurchaseHeader."Document Type");
        Assert.RecordIsNotEmpty(DummySalesTaxAmountDifference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPostedSalesInvoiceWithTaxDifferenceToSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        DummySalesTaxAmountDifference: Record "Sales Tax Amount Difference";
        CrMemoSalesHeader: Record "Sales Header";
        PostedSalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Copy Document] [Tax Difference]
        // [SCENARIO 214207] Sales Tax Amount Difference should be copied from Posted Sales Invoice to Sales Cr. Memo by Copy Document
        Initialize();

        // [GIVEN] Posted Sales Invoice with Sales Tax Amount Difference
        UpdateMaxVATDifferenceAllowedGeneralLedgerSetup(LibraryRandom.RandIntInRange(10, 100));
        LibrarySales.SetAllowVATDifference(true);

        CreateSalesInvoiceWithTaxDifference(SalesHeader, DummySalesTaxAmountDifference."Document Product Area"::Sales);
        PostedSalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Created blank sales credit memo
        LibrarySales.CreateSalesHeader(
          CrMemoSalesHeader, CrMemoSalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy the posted sales invoice to credit memo by Copy Document
        LibrarySales.CopySalesDocument(CrMemoSalesHeader, "Sales Document Type From"::"Posted Invoice", PostedSalesInvoiceNo, true, false);

        // [THEN] Sales Tax Amount Difference has been copied
        DummySalesTaxAmountDifference.SetRange("Document No.", CrMemoSalesHeader."No.");
        DummySalesTaxAmountDifference.SetRange("Document Type", CrMemoSalesHeader."Document Type");
        Assert.RecordIsNotEmpty(DummySalesTaxAmountDifference);
    end;

    [Test]
    [HandlerFunctions('SalesOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithBlankTaxGroupCodeIsShownOnOrderListWhenSkipNoVATIsFalse()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 382294] Sales Order with "Tax Area Code" and blank "Tax Group Code" field value is shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = FALSE
        Initialize();

        // [GIVEN] Sales Order "A" with "Tax Area Code" and blank "Tax Group Code" field value
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreateSalesOrder(SalesHeader, TaxAreaCode, '', 0);

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = FALSE
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        OpenSalesOrderList(SalesHeader, false);

        // [THEN] Sales Order "A" is on the order list
        // Verify sales order in SalesOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('SalesOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithTaxIsShownOnOrderListWhenSkipNoVATIsFalse()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 382294] Sales Order with Tax is shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = FALSE
        Initialize();

        // [GIVEN] Sales Order "A" with Tax
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreateSalesOrder(SalesHeader, TaxAreaCode, TaxDetail."Tax Group Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = FALSE
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        OpenSalesOrderList(SalesHeader, false);

        // [THEN] Sales Order "A" is on the order list
        // Verify sales order in SalesOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('SalesOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithTaxIsShownOnOrderListWhenSkipNoVATIsTrue()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 382294] Sales Order with Tax is shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Sales Order "A" with Tax
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreateSalesOrder(SalesHeader, TaxAreaCode, TaxDetail."Tax Group Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = TRUE
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        OpenSalesOrderList(SalesHeader, false);

        // [THEN] Sales Order "A" is on the order list
        // Verify sales order in SalesOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('SalesOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithoutTaxIsNotShownOnOrderListWhenSkipNoVATIsTrue()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 382294] Sales Order without Tax is not shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Sales Order "A" without Tax
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreateSalesOrder(SalesHeader, TaxAreaCode, TaxDetail."Tax Group Code", 0);

        // [WHEN] Open "Sales Order List" page with SkipShowingLinesWithoutVAT = TRUE
        LibraryVariableStorage.Enqueue('');
        OpenSalesOrderList(SalesHeader, true);

        // [THEN] Sales Order "A" is not shown on the order list
        // Verify sales order in SalesOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithBlankTaxGroupCodeIsShownOnOrderListWhenSkipNoVATIsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 382294] Purchase Order with "Tax Area Code" and blank "Tax Group Code" field value is shown on the "Purchase Order List" page when called with SkipShowingLinesWithoutVAT = FALSE
        Initialize();

        // [GIVEN] Purchase Order "A" with "Tax Area Code" and blank "Tax Group Code" field value
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreatePurchaseOrder(PurchaseHeader, TaxAreaCode, '', 0);

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = FALSE
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        OpenPurchaseOrderList(PurchaseHeader, false);

        // [THEN] Purchase Order "A" is on the order list
        // Verify purchase order in PurchaseOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithTaxIsShownOnOrderListWhenSkipNoVATIsFalse()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 382294] Purchase Order with Tax is shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = FALSE
        Initialize();

        // [GIVEN] Purchase Order "A" with Tax
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreatePurchaseOrder(PurchaseHeader, TaxAreaCode, TaxDetail."Tax Group Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = FALSE
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        OpenPurchaseOrderList(PurchaseHeader, false);

        // [THEN] Purchase Order "A" is on the order list
        // Verify purchase order in PurchaseOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithTaxIsShownOnOrderListWhenSkipNoVATIsTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 382294] Purchase Order with Tax is shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Purchase Order "A" with Tax
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreatePurchaseOrder(PurchaseHeader, TaxAreaCode, TaxDetail."Tax Group Code", LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = TRUE
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        OpenPurchaseOrderList(PurchaseHeader, false);

        // [THEN] Purchase Order "A" is on the order list
        // Verify purchase order in PurchaseOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderListPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithoutTaxIsNotShownOnOrderListWhenSkipNoVATIsTrue()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 382294] Purchase Order without Tax is not shown on the "Sales Order List" page when called with SkipShowingLinesWithoutVAT = TRUE
        Initialize();

        // [GIVEN] Purchase Order "A" without Tax
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreatePurchaseOrder(PurchaseHeader, TaxAreaCode, TaxDetail."Tax Group Code", 0);

        // [WHEN] Open "Purchase Order List" page with SkipShowingLinesWithoutVAT = TRUE
        LibraryVariableStorage.Enqueue('');
        OpenPurchaseOrderList(PurchaseHeader, true);

        // [THEN] Purchase Order "A" is not shown on the order list
        // Verify purchase order in PurchaseOrderListPageHandler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_Invoice_CA()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize] [Invoice]
        // [SCENARIO 228521] Purchase invoice subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Purchase invoice with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a purchase invoice page
        ValidatePurchaseInvoiceTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.11);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_Invoice_US()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize] [Invoice]
        // [SCENARIO 228521] Purchase invoice subtotals in case of Tax Country = US, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        // [GIVEN] Purchase invoice with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a purchase invoice page
        ValidatePurchaseInvoiceTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.10
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_Invoice_FCY_CA()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Currency] [Expense/Capitalize]
        // [SCENARIO 228521] Purchase invoice subtotals in case of Tax Country = CA, Expense, FCY, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Purchase invoice with FCY, several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Validate "Tax Area" header value on a purchase invoice page
        ValidatePurchaseInvoiceTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.11);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_Invoice_FCY_US()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Currency] [Expense/Capitalize]
        // [SCENARIO 228521] Purchase invoice subtotals in case of Tax Country = US, Expense, FCY, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Purchase invoice with FCY, several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Validate "Tax Area" header value on a purchase invoice page
        ValidatePurchaseInvoiceTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.10
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_CreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize] [Credit Memo]
        // [SCENARIO 228521] Purchase credit memo subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Purchase credit memo with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a purchase credit memo page
        ValidatePurchaseCreditMemoTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.11);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_Order()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize] [Order]
        // [SCENARIO 228521] Purchase order subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Purchase order with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a purchase order page
        ValidatePurchaseOrderTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.11);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_ReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize] [Return Order]
        // [SCENARIO 228521] Purchase return order subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Purchase return order with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a purchase return order page
        ValidatePurchaseReturnOrderTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.11);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_BlanketOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize] [Blanket Order]
        // [SCENARIO 228521] Purchase blanket order subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Purchase blanket order with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a purchase blanket order page
        ValidatePurchaseBlanketOrderTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.11);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure Subtotals_Purchase_Quote()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Expense/Capitalize] [Quote]
        // [SCENARIO 228521] Purchase quote subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Purchase quote with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomPurchaseInvoice_TFS210430(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a purchase quote page
        ValidatePurchaseQuoteTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader, 674.11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_Invoice_CA()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Invoice]
        // [SCENARIO 228521] Sales invoice subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Sales invoice with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::Invoice, '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a sales invoice page
        ValidateSalesInvoiceTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_Invoice_US()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Invoice]
        // [SCENARIO 228521] Sales invoice subtotals in case of Tax Country = US, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        // [GIVEN] Sales invoice with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::Invoice, '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a sales invoice page
        ValidateSalesInvoiceTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.10
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_Invoice_FCY_CA()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Currency] [Expense/Capitalize]
        // [SCENARIO 228521] Sales invoice subtotals in case of Tax Country = CA, Expense, FCY, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Sales invoice with FCY, several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Validate "Tax Area" header value on a purchase invoice page
        ValidateSalesInvoiceTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_Invoice_FCY_US()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Currency] [Expense/Capitalize]
        // [SCENARIO 228521] Sales invoice subtotals in case of Tax Country = US, Expense, FCY, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = US having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);

        // [GIVEN] Sales invoice with FCY, several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          TaxAreaCode, TaxGroupCode, LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 1, 1));

        // [WHEN] Validate "Tax Area" header value on a purchase invoice page
        ValidateSalesInvoiceTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.10
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_CreditMemo()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Credit Memo]
        // [SCENARIO 228521] Sales credit memo subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Sales credit memo with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a sales credit memo page
        ValidateSalesCreditMemoTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_Order()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Order]
        // [SCENARIO 228521] Sales order subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Sales order with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::Order, '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a sales order page
        ValidateSalesOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_ReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Return Order]
        // [SCENARIO 228521] Sales return order subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Sales return order with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::"Return Order", '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a sales return order page
        ValidateSalesReturnOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_BlanketOrder()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Blanket Order]
        // [SCENARIO 228521] Sales blanket order subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Sales blanket order with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a sales blanket order page
        ValidateSalesBlanketOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Subtotals_Sales_Quote()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Quote]
        // [SCENARIO 228521] Sales quote subtotals in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Sales quote with blanked "Tax Area", several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::Quote, '', TaxGroupCode, '');

        // [WHEN] Validate "Tax Area" header value on a sales quote page
        ValidateSalesQuoteTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [THEN] Document subtotal Tax Amount = 674.11
        VerifySalesTotalTaxBeforeAfterRelease(SalesHeader, 674.11);
    end;

    [Test]
    [HandlerFunctions('StandardSalesOrderConf_RPH')]
    [Scope('OnPrem')]
    procedure PrintOrderConfirmationW1Report()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Order] [Report] [Order Confirmation]
        // [SCENARIO 228827] Print REP1305 "Standard Sales - Order Conf." in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        UpdateReportLayoutSelection(REPORT::"Standard Sales - Order Conf.", 'StandardSalesOrderConf.rdlc');

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Sales order with several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::Order, '', TaxGroupCode, '');
        ValidateSalesOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [WHEN] Print REP1305 "Standard Sales - Order Conf."
        PrintStandardSalesOrderConfReport(SalesHeader);

        // [THEN] Report prints correct total amounts
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.VerifyCellValueByRef('T', 45, 1, LibraryReportValidation.FormatDecimalValue(5617.52)); // Amount
        LibraryReportValidation.VerifyCellValueByRef('T', 48, 1, LibraryReportValidation.FormatDecimalValue(280.88)); // PST
        LibraryReportValidation.VerifyCellValueByRef('T', 50, 1, LibraryReportValidation.FormatDecimalValue(393.23)); // GST
        LibraryReportValidation.VerifyCellValueByRef('T', 51, 1, Format(6291.63)); // Total Including VAT
        LibraryReportValidation.VerifyCellValueByRef('T', 53, 1, LibraryReportValidation.FormatDecimalValue(674.11)); // Total Tax

        // Tear Down
        UpdateReportLayoutSelection(REPORT::"Standard Sales - Order Conf.", 'StandardSalesOrderConf.docx');
    end;

    [Test]
    [HandlerFunctions('SalesOrder_RPH')]
    [Scope('OnPrem')]
    procedure PrintOrderConfirmationNAReport()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        RowNo: Integer;
    begin
        // [FEATURE] [Rounding] [Sales] [Expense/Capitalize] [Order] [Report] [Order Confirmation]
        // [SCENARIO 228827] Print REP10075 "Sales Order" in case of Tax Country = CA, Expense, several custom lines including negative and last nontaxable
        Initialize();

        // [GIVEN] Tax area with "Country/Region" = CA having several lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        // [GIVEN] Sales order with several lines with custom amounts, including negative
        // [GIVEN] Last line is nontaxable
        CreateCustomSalesInvoice_TFS210430(SalesHeader, SalesHeader."Document Type"::Order, '', TaxGroupCode, '');
        ValidateSalesOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);

        // [WHEN] Print REP10075 "Sales Order"
        PrintSalesOrderReport(SalesHeader);

        // [THEN] Report prints all document lines
        LibraryReportValidation.OpenFile();
        RowNo := 56;

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            LibraryReportValidation.VerifyCellValueByRef('P', RowNo, 1, LibraryReportValidation.FormatDecimalValue(SalesLine."Unit Price"));
            RowNo += 1;
        until SalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUseTaxBothUseSalesTaxOnlyExpenseCapitalize()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxJurisdictionCode: Code[10];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Expense/Capitalize]
        // [SCENARIO 283517] "Use Tax" can be set on Purchase Line if both "Sales Tax Only" with "Expense/Capitalize" = TRUE Tax Detail and Tax Detail of another type exist for applicable Tax Jurisdiction

        Initialize();
        ModifyPurchasesPayablesSetup();
        // [GIVEN] Tax Area "TA01" with "Country/Region" = CA and Tax Area Line for Tax Jurisdiction "TJ01"
        // [GIVEN] Tax Group "TG01"
        // [GIVEN] Tax Detail with "Tax Jurisdiction" = "TJ01", "Tax Group" = "TG01", "Tax Type" = "Sales Tax Only", "Expense/Capitalize" = TRUE
        // [GIVEN] Tax Detail with "Tax Jurisdiction" = "TJ01", "Tax Group" = "TG01", "Tax Type" = "Use Tax Only"
        CreateCustomTaxSetup_TFS283517(
          TaxAreaCode, TaxGroupCode, TaxJurisdictionCode, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));

        // [GIVEN] Vendor with "Tax Area" = "TA01", "Tax Liable" = TRUE
        VendorNo := CreateVendor(TaxAreaCode);

        // [GIVEN] Purchase Order created for Vendor
        // [GIVEN] Purchase Line for Item of Tax Group "TG01" created on Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine,
          PurchaseHeader,
          PurchaseLine.Type::Item,
          CreateItem('', TaxGroupCode),
          1);

        // [WHEN] Check "Use Tax" on Purchase Line
        // [THEN] "Use Tax" applied
        PurchaseLine.Validate("Use Tax", true);
        PurchaseLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUseTaxStandardSalesAndUseTaxWithExpenseCapitalize()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        VendorNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Expense/Capitalize]
        // [SCENARIO 285454] "Use Tax" cannot be set on Purchase Line when "Sales And Use Tax" has "Expense/Capitalize" = TRUE in Tax Detail
        Initialize();
        ModifyPurchasesPayablesSetup();

        // [GIVEN] Tax Area "TA01" with "Country/Region" = CA and Tax Area Line for Tax Jurisdiction "TJ01"
        // [GIVEN] Tax Group "TG01"
        // [GIVEN] Tax Detail with "Tax Jurisdiction" = "TJ01", "Tax Group" = "TG01", "Tax Type" = "Sales And Use Tax", "Expense/Capitalize" = TRUE
        // [GIVEN] Vendor with "Tax Area" = "TA01", "Tax Liable" = TRUE
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        VendorNo := CreateVendor(TaxAreaCode);

        // [GIVEN] Purchase Order created for Vendor
        // [GIVEN] Purchase Line for Item of Tax Group "TG01" created on Purchase Order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine,
          PurchaseHeader,
          PurchaseLine.Type::Item,
          CreateItem('', TaxDetail."Tax Group Code"),
          1);

        // [WHEN] Check "Use Tax" on Purchase Line
        asserterror PurchaseLine.Validate("Use Tax", true);

        // [THEN] Error raised that use tax cannot be set because of Expense/Capitalize
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(
          StrSubstNo(
            UseTaxCannotBeSetErr,
            PurchaseLine.FieldCaption("Use Tax"), TaxDetail.TableCaption(),
            TaxDetail."Tax Jurisdiction Code", TaxDetail."Tax Group Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithTwoTaxDetailsOfUseTaxAndExpenseCapitalize()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        TaxJurisdictionCode: Code[10];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        DocumentNo: Code[20];
        TaxPctExpense: Decimal;
        TaxPctUseTax: Decimal;
    begin
        // [FEATURE] [Purchase] [Expense/Capitalize]
        // [SCENARIO 285454] "Use Tax" can be set on Purchase Line if both "Sales Tax Only" with "Expense/Capitalize" = TRUE Tax Detail and Tax Detail of another type exist for applicable Tax Jurisdiction

        Initialize();
        ModifyPurchasesPayablesSetup();
        // [GIVEN] Tax Area "TA01" with "Country/Region" = CA and Tax Area Line for Tax Jurisdiction "TJ01"
        // [GIVEN] Tax Group "TG01"
        // [GIVEN] Tax Detail 5%  with "Tax Jurisdiction" = "TJ01", "Tax Group" = "TG01", "Tax Type" = "Sales Tax Only", "Expense/Capitalize" = TRUE
        // [GIVEN] Tax Detail 5% with "Tax Jurisdiction" = "TJ01", "Tax Group" = "TG01", "Tax Type" = "Use Tax Only"
        TaxPctExpense := LibraryRandom.RandInt(10);
        TaxPctUseTax := LibraryRandom.RandInt(10);
        CreateCustomTaxSetup_TFS283517(TaxAreaCode, TaxGroupCode, TaxJurisdictionCode, TaxPctExpense, TaxPctUseTax);

        // [GIVEN] Purchase Order created for Vendor with "Tax Area" = "TA01", "Tax Liable" = TRUE
        // [GIVEN] Purchase Line 1 for Item of Tax Group "TG01" with Use Tax = Yes has Amount = 300
        // [GIVEN] Purchase Line 2 for Item of Tax Group "TG01" with Use Tax = No has Amount = 50
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(TaxAreaCode));
        CreatePurchLineWithUseTax(PurchaseLine1, PurchaseHeader, '', TaxGroupCode, true);
        CreatePurchLineWithUseTax(PurchaseLine2, PurchaseHeader, '', TaxGroupCode, false);
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Post purchase order
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase is posted with Amount = 367.50
        // [THEN] Tax is posted with Amount = -15
        // [THEN] Vendor's account has Amount = -352.50
        VerifyGLEntriesWithUseTax(
          DocumentNo, PurchaseHeader."Buy-from Vendor No.", TaxJurisdictionCode, PurchaseLine1.Amount * TaxPctUseTax / 100,
          PurchaseLine1.Amount + PurchaseLine2.Amount * (1 + TaxPctExpense / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetSalesQuoteTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 309621] Set "Tax Liable" for Sales Quote make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Quote with Tax Area Code with "Tax Liable" = FALSE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Quote, '', TaxAreaCode);
        SalesHeader.Validate("Tax Liable", false);
        SalesHeader.Modify(true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Sales Quote
        ValidateSalesQuoteTaxLiableThroughPage(SalesHeader, true);

        // [THEN] Sales Quote first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Sales Quote last line "Amount" = 20, "Amount Including VAT" = 21
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetSalesBlanketOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Blanket Order]
        // [SCENARIO 309621] Set "Tax Liable" for Sales Blanket Order make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Blanket Order with Tax Area Code with "Tax Liable" = FALSE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '', TaxAreaCode);
        SalesHeader.Validate("Tax Liable", false);
        SalesHeader.Modify(true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Sales Blanket Order
        ValidateSalesBlanketOrderTaxLiableThroughPage(SalesHeader, true);

        // [THEN] Sales Blanket Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Sales Blanket Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetSalesOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 309621] Set "Tax Liable" for Sales Order make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Order with Tax Area Code with "Tax Liable" = FALSE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Order, '', TaxAreaCode);
        SalesHeader.Validate("Tax Liable", false);
        SalesHeader.Modify(true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Sales Order
        ValidateSalesOrderTaxLiableThroughPage(SalesHeader, true);

        // [THEN] Sales Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Sales Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetSalesInvoiceTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 309621] Set "Tax Liable" for Sales Invoice make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Invoice with Tax Area Code with "Tax Liable" = FALSE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Invoice, '', TaxAreaCode);
        SalesHeader.Validate("Tax Liable", false);
        SalesHeader.Modify(true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Sales Invoice
        ValidateSalesInvoiceTaxLiableThroughPage(SalesHeader, true);

        // [THEN] Sales Invoice first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Sales Invoice last line "Amount" = 20, "Amount Including VAT" = 21
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetSalesCreditMemoTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 309621] Set "Tax Liable" for Sales Credit Memo make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Credit Memo with Tax Area Code with "Tax Liable" = FALSE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '', TaxAreaCode);
        SalesHeader.Validate("Tax Liable", false);
        SalesHeader.Modify(true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Sales Credit Memo
        ValidateSalesCreditMemoTaxLiableThroughPage(SalesHeader, true);

        // [THEN] Sales Credit Memo first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Sales Credit Memo last line "Amount" = 20, "Amount Including VAT" = 21
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetSalesReturnOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Return Order]
        // [SCENARIO 309621] Set "Tax Liable" for Sales Return Order make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Return Order with Tax Area Code with "Tax Liable" = FALSE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::"Return Order", '', TaxAreaCode);
        SalesHeader.Validate("Tax Liable", false);
        SalesHeader.Modify(true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Sales Return Order
        ValidateSalesReturnOrderTaxLiableThroughPage(SalesHeader, true);

        // [THEN] Sales Return Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Sales Return Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnsetSalesQuoteTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 309621] Unset "Tax Liable" for Sales Quote make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Quote with Tax Area Code with "Tax Liable" = TRUE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Quote, '', TaxAreaCode);
        SalesHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set OFF "Tax Liable" for Sales Quote
        ValidateSalesQuoteTaxLiableThroughPage(SalesHeader, false);

        // [THEN] Sales Quote first line "Amount" = 10, "Amount Including VAT" = 10
        // [THEN] Sales Quote last line "Amount" = 20, "Amount Including VAT" = 20
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnsetSalesBlanketOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Blanket Order]
        // [SCENARIO 309621] Unset "Tax Liable" for Sales Blanket Order make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Blanket Order with Tax Area Code with "Tax Liable" = TRUE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '', TaxAreaCode);
        SalesHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set OFF "Tax Liable" for Sales Blanket Order
        ValidateSalesBlanketOrderTaxLiableThroughPage(SalesHeader, false);

        // [THEN] Sales Blanket Order first line "Amount" = 10, "Amount Including VAT" = 10
        // [THEN] Sales Blanket Order last line "Amount" = 20, "Amount Including VAT" = 20
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnsetSalesOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Order]
        // [SCENARIO 309621] Unset "Tax Liable" for Sales Order make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Order with Tax Area Code with "Tax Liable" = TRUE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Order, '', TaxAreaCode);
        SalesHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set OFF "Tax Liable" for Sales Order
        ValidateSalesOrderTaxLiableThroughPage(SalesHeader, false);

        // [THEN] Sales Order first line "Amount" = 10, "Amount Including VAT" = 10
        // [THEN] Sales Order last line "Amount" = 20, "Amount Including VAT" = 20
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnsetSalesInvoiceTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 309621] Unset "Tax Liable" for Sales Invoice make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Invoice with Tax Area Code with "Tax Liable" = TRUE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Invoice, '', TaxAreaCode);
        SalesHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set OFF "Tax Liable" for Sales Invoice
        ValidateSalesInvoiceTaxLiableThroughPage(SalesHeader, false);

        // [THEN] Sales Invoice first line "Amount" = 10, "Amount Including VAT" = 10
        // [THEN] Sales Invoice last line "Amount" = 20, "Amount Including VAT" = 20
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnsetSalesCreditMemoTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 309621] Unset "Tax Liable" for Sales Credit Memo make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Credit Memo with Tax Area Code with "Tax Liable" = TRUE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '', TaxAreaCode);
        SalesHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set OFF "Tax Liable" for Sales Credit Memo
        ValidateSalesCreditMemoTaxLiableThroughPage(SalesHeader, false);

        // [THEN] Sales Credit Memo first line "Amount" = 10, "Amount Including VAT" = 10
        // [THEN] Sales Credit Memo last line "Amount" = 20, "Amount Including VAT" = 20
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnsetSalesReturnOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Return Order]
        // [SCENARIO 309621] Unset "Tax Liable" for Sales Return Order make Sales Lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Sales Return Order with Tax Area Code with "Tax Liable" = TRUE
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::"Return Order", '', TaxAreaCode);
        SalesHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Sales Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set OFF "Tax Liable" for Sales Return Order
        ValidateSalesReturnOrderTaxLiableThroughPage(SalesHeader, false);

        // [THEN] Sales Return Order first line "Amount" = 10, "Amount Including VAT" = 10
        // [THEN] Sales Return Order last line "Amount" = 20, "Amount Including VAT" = 20
        VerifySalesLinesAmounts(SalesHeader."No.", SalesHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetPurchaseQuoteTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Quote]
        // [SCENARIO 309621] Set "Tax Liable" for Purchase Quote make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Quote with Tax Area Code with "Tax Liable" = FALSE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '', TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", false);
        PurchaseHeader.Modify(true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Purchase Quote
        ValidatePurchaseQuoteTaxLiableThroughPage(PurchaseHeader, true);

        // [THEN] Purchase Quote first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Quote last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetPurchaseBlanketOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Blanket Order]
        // [SCENARIO 309621] Set "Tax Liable" for Purchase Blanket Order make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Blanket Order with Tax Area Code with "Tax Liable" = FALSE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", false);
        PurchaseHeader.Modify(true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Purchase Blanket Order
        ValidatePurchaseBlanketOrderTaxLiableThroughPage(PurchaseHeader, true);

        // [THEN] Purchase Blanket Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Blanket Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetPurchaseOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 309621] Set "Tax Liable" for Purchase Order make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Order with Tax Area Code with "Tax Liable" = FALSE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", false);
        PurchaseHeader.Modify(true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Purchase Order
        ValidatePurchaseOrderTaxLiableThroughPage(PurchaseHeader, true);

        // [THEN] Purchase Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetPurchaseInvoiceTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 309621] Set "Tax Liable" for Purchase Invoice make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Invoice with Tax Area Code with "Tax Liable" = FALSE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", false);
        PurchaseHeader.Modify(true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Purchase Invoice
        ValidatePurchaseInvoiceTaxLiableThroughPage(PurchaseHeader, true);

        // [THEN] Purchase Invoice first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Invoice last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetPurchaseCreditMemoTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 309621] Set "Tax Liable" for Purchase Credit Memo make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Credit Memo with Tax Area Code with "Tax Liable" = FALSE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '', TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", false);
        PurchaseHeader.Modify(true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Purchase Credit Memo
        ValidatePurchaseCreditMemoTaxLiableThroughPage(PurchaseHeader, true);

        // [THEN] Purchase Credit Memo first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Credit Memo last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SetPurchaseReturnOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
        LineAmountInclVAT: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order]
        // [SCENARIO 309621] Set "Tax Liable" for Purchase Return Order make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Credit Memo with Tax Area Code with "Tax Liable" = FALSE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '', TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", false);
        PurchaseHeader.Modify(true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPriceWithVAT(UnitPrice, LineAmountInclVAT, TaxDetail."Tax Below Maximum");
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set "Tax Liable" for Purchase Return Order
        ValidatePurchaseReturnOrderTaxLiableThroughPage(PurchaseHeader, true);

        // [THEN] Purchase Return Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Return Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, LineAmountInclVAT);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnsetPurchaseQuoteTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Quote]
        // [SCENARIO 309621] Unset "Tax Liable" for Purchase Quote make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Quote with Tax Area Code with "Tax Liable" = TRUE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '', TaxAreaCode);
        PurchaseHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set off "Tax Liable" for Purchase Quote
        ValidatePurchaseQuoteTaxLiableThroughPage(PurchaseHeader, false);

        // [THEN] Purchase Quote first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Quote last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnsetPurchaseBlanketOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Blanket Order]
        // [SCENARIO 309621] Unset "Tax Liable" for Purchase Blanket Order make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Blanket Order with Tax Area Code with "Tax Liable" = TRUE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', TaxAreaCode);
        PurchaseHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set off "Tax Liable" for Purchase Blanket Order
        ValidatePurchaseBlanketOrderTaxLiableThroughPage(PurchaseHeader, false);

        // [THEN] Purchase Blanket Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Blanket Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnsetPurchaseOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Order]
        // [SCENARIO 309621] Unset "Tax Liable" for Purchase Order make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Order with Tax Area Code with "Tax Liable" = TRUE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);
        PurchaseHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set off "Tax Liable" for Purchase Order
        ValidatePurchaseOrderTaxLiableThroughPage(PurchaseHeader, false);

        // [THEN] Purchase Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnsetPurchaseInvoiceTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 309621] Unset "Tax Liable" for Purchase Invoice make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Invoice with Tax Area Code with "Tax Liable" = TRUE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxAreaCode);
        PurchaseHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);

        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set off "Tax Liable" for Purchase Invoice
        ValidatePurchaseInvoiceTaxLiableThroughPage(PurchaseHeader, false);

        // [THEN] Purchase Invoice first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Invoice last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnsetPurchaseCreditMemoTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 309621] Unset "Tax Liable" for Purchase Credit Memo make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Credit Memo with Tax Area Code with "Tax Liable" = TRUE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '', TaxAreaCode);
        PurchaseHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set off "Tax Liable" for Purchase Credit Memo
        ValidatePurchaseCreditMemoTaxLiableThroughPage(PurchaseHeader, false);

        // [THEN] Purchase Credit Memo first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Credit Memo last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UnsetPurchaseReturnOrderTaxLiableUpdatesLineAmountsRespectively()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        UnitPrice: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order]
        // [SCENARIO 309621] Unset "Tax Liable" for Purchase Return Order make Purchase lines amounts recalculated accordingly
        Initialize();

        // [GIVEN] Tax Area Code with Tax Group Code "TG" with Tax Detail where "Tax Below Max" = 5
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        CreateTaxAreaSetupWithValues(
            TaxDetail, TaxAreaCode, LibraryERMTax.CreateTaxGroupCode(),
            LibraryRandom.RandInt(10), 0, LibraryERM.CreateGLAccountNo());

        // [GIVEN] Purchase Return Order with Tax Area Code with "Tax Liable" = TRUE
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '', TaxAreaCode);
        PurchaseHeader.TestField("Tax Liable", true);

        // [GIVEN] Two Purchase Lines added with G/L Accounts with "TG" with amounts 10 and 20
        CreateUnitPrice(UnitPrice);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[1]);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountNo(), TaxDetail."Tax Group Code", UnitPrice[2]);

        // [WHEN] Set off "Tax Liable" for Purchase Return Order
        ValidatePurchaseReturnOrderTaxLiableThroughPage(PurchaseHeader, false);

        // [THEN] Purchase Return Order first line "Amount" = 10, "Amount Including VAT" = 10,5
        // [THEN] Purchase Return Order last line "Amount" = 20, "Amount Including VAT" = 21
        VerifyPurchaseLinesAmounts(PurchaseHeader."No.", PurchaseHeader."Document Type", UnitPrice, UnitPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyFixedAssetJournalsAcceptingManualNumbers()
    var
        DepreciationBook: Record "Depreciation Book";
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FAJournalLine: Record "FA Journal Line";
        FAJournalTemplate: Record "FA Journal Template";
        FAJournalBatch: Record "FA Journal Batch";
    begin
        // [SCENARIO 452446] Fixed Asset Journal not accepting Manual numbers after enabling it
        Initialize();

        // [GIVEN] Create FA Journal Batch, No. Series
        LibraryFixedAsset.FindFAJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        FAJournalBatch.Modify(true);

        // [GIVEN] Create Fixed Asset, Depreciation Book
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        DepreciationBook."G/L Integration - Acq. Cost" := false;
        DepreciationBook.Modify();

        // [GIVEN] Create FA Journal Line
        CreateFAJournalLine(
          FAJournalLine, FAJournalBatch, FAJournalLine."FA Posting Type"::"Acquisition Cost", FixedAsset."No.",
          DepreciationBook.Code, LibraryRandom.RandDec(1000, 2));

        // [WHEN] Assign any document number
        FAJournalLine."Document No." := LibraryUtility.GenerateGUID();
        FAJournalLine.Modify();

        // [THEN] Post FA Journal Line without any error
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        TaxSetup: Record "Tax Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        CreateEmptyVATPostingSetupSalesTax();
        LibraryERMCountryData.CreateVATData();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryApplicationArea.EnableFoundationSetup();

        TaxSetup.DeleteAll();
        TaxSetup.Init();
        TaxSetup.Insert();

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        IsInitialized := true;
    end;

    local procedure CreateCustomTaxSetup_TFS210430(var TaxAreaCode: Code[20]; var TaxGroupCode: array[2] of Code[20]; TaxCountry: Option)
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: array[2] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(TaxCountry);
        for i := 1 to ArrayLen(TaxGroupCode) do begin
            TaxGroupCode[i] := LibraryERMTax.CreateTaxGroupCode();
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(TaxCountry);
            CreateSimpleTaxAreaLine(TaxAreaCode, TaxJurisdictionCode[i], i);
        end;

        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode[1], 5);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode[2], 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], '', 7);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode[1], 7);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode[2], 7);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode[2], '', TaxDetail."Tax Type"::"Sales and Use Tax", true);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode[2], TaxGroupCode[1], TaxDetail."Tax Type"::"Sales and Use Tax", true);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode[2], TaxGroupCode[2], TaxDetail."Tax Type"::"Sales and Use Tax", true);
    end;

    local procedure CreateCustomTaxSetup_TFS216424(var NoTaxAreaCode: Code[20]; var ProvTaxAreaCode: Code[20]; var TaxableTaxGroupCode: Code[20]; var TaxJurisdictionCode: array[4] of Code[10]; CountryRegion: Option)
    var
        TaxDetail: Record "Tax Detail";
        NonTaxableTaxGroupCode: Code[20];
        NoTaxJurisdictionCode: Code[10];
        i: Integer;
    begin
        // Sales Tax Groups: "TAXABLE", "NONTAXABLE"
        TaxableTaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        NonTaxableTaxGroupCode := LibraryERMTax.CreateTaxGroupCode();

        // Sales Tax Jurisdictions:
        // 1: "Code" = "Jur1", "Report-to Jurisdiction" = "Jur1"
        // 2: "Code" = "Jur2", "Report-to Jurisdiction" = "Jur1"
        // 3: "Code" = "Jur3", "Report-to Jurisdiction" = "Jur3"
        // 4: "Code" = "Jur4", "Report-to Jurisdiction" = "Jur3"
        // 5: "Code" = "NOTAX", "Report-to Jurisdiction" = ""
        NoTaxJurisdictionCode := CreateSalesTaxJurisdictionWithReportTo(CountryRegion, '');
        TaxJurisdictionCode[1] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(CountryRegion);
        TaxJurisdictionCode[2] := CreateSalesTaxJurisdictionWithReportTo(CountryRegion, TaxJurisdictionCode[1]);
        TaxJurisdictionCode[3] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(CountryRegion);
        TaxJurisdictionCode[4] := CreateSalesTaxJurisdictionWithReportTo(CountryRegion, TaxJurisdictionCode[3]);

        // Sales Tax Area "NOTAX" with "NOTAX" jutrisdiction line
        NoTaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(CountryRegion);
        CreateSimpleTaxAreaLine(NoTaxAreaCode, NoTaxJurisdictionCode, 0);

        // Sales Tax Area "PROVTAX" with 4 jurisdiction lines: "Jur1", "Jur2", "Jur3", "Jur4"
        ProvTaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(CountryRegion);
        for i := 1 to ArrayLen(TaxJurisdictionCode) do
            CreateSimpleTaxAreaLine(ProvTaxAreaCode, TaxJurisdictionCode[i], 0);

        // Tax Details (all with "Tax Type" = "Sales and Use Tax"):
        // "Tax Jurisdiction Code" = "NOTAX", "Tax Group Code" = "", "Tax Below Maximum" = 0, "Expense/Capitalize" = FALSE
        LibraryERMTax.CreateTaxDetail(TaxDetail, NoTaxJurisdictionCode, '', 0);

        // "Tax Jurisdiction Code" = "Jur1", "Tax Group Code" = "NONTAXABLE", "Tax Below Maximum" = 0, "Expense/Capitalize" = FALSE
        // "Tax Jurisdiction Code" = "Jur1", "Tax Group Code" = "TAXABLE", "Tax Below Maximum" = 2.5, "Expense/Capitalize" = FALSE
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], NonTaxableTaxGroupCode, 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxableTaxGroupCode, 2.5);

        // "Tax Jurisdiction Code" = "Jur2", "Tax Group Code" = "NONTAXABLE", "Tax Below Maximum" = 0, "Expense/Capitalize" = FALSE
        // "Tax Jurisdiction Code" = "Jur2", "Tax Group Code" = "TAXABLE", "Tax Below Maximum" = 2.5, "Expense/Capitalize" = TRUE
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], NonTaxableTaxGroupCode, 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxableTaxGroupCode, 2.5);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode[2], TaxableTaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", true);

        // "Tax Jurisdiction Code" = "Jur3", "Tax Group Code" = "NONTAXABLE", ""Tax Below Maximum" = 0, "Expense/Capitalize" = FALSE
        // "Tax Jurisdiction Code" = "Jur3", "Tax Group Code" = "TAXABLE", "Tax Below Maximum" = 6.56, "Expense/Capitalize" = FALSE
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[3], NonTaxableTaxGroupCode, 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[3], TaxableTaxGroupCode, 6.56);

        // "Tax Jurisdiction Code" = "Jur4", "Tax Group Code" = "NONTAXABLE", "Tax Below Maximum" = 0, "Expense/Capitalize" = FALSE
        // "Tax Jurisdiction Code" = "Jur4", "Tax Group Code" = "TAXABLE", "Tax Below Maximum" = 1.44, "Expense/Capitalize" = TRUE
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[4], NonTaxableTaxGroupCode, 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[4], TaxableTaxGroupCode, 1.44);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode[4], TaxableTaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", true);
    end;

    local procedure CreateCustomTaxSetup_TFS283517(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; var TaxJurisdictionCode: Code[10]; TaxPct1: Decimal; TaxPct2: Decimal)
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_CA();
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetailWithTaxType(
          TaxDetail,
          TaxJurisdictionCode,
          TaxGroupCode,
          TaxDetail."Tax Type"::"Sales Tax Only",
          TaxPct1,
          0);
        TaxDetail.Validate("Expense/Capitalize", true);
        TaxDetail.Modify(true);
        LibraryERMTax.CreateTaxDetailWithTaxType(
          TaxDetail,
          TaxJurisdictionCode,
          TaxGroupCode,
          TaxDetail."Tax Type"::"Use Tax Only",
          TaxPct2,
          0);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
    end;

    local procedure CreateCustomPurchaseInvoice_TFS210430(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: array[2] of Code[20]; CurrencyCode: Code[10])
    var
        GLAccountNo: Code[20];
    begin
        LibraryPurchase.SetInvoiceRounding(false);

        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, DocumentType, CurrencyCode, TaxAreaCode);

        GLAccountNo := CreateGLAccNoWithTaxSetup('', TaxGroupCode[2], false);
        CreateCustomPurchaseInvoiceLines(PurchaseHeader, TaxGroupCode[1], GLAccountNo);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, TaxGroupCode[2], 0.02);
    end;

    local procedure CreateCustomSalesInvoice_TFS210430(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: array[2] of Code[20]; CurrencyCode: Code[10])
    var
        GLAccountNo: Code[20];
    begin
        LibrarySales.SetInvoiceRounding(false);

        CreateSalesHeaderWithTaxArea(SalesHeader, DocumentType, CurrencyCode, TaxAreaCode);

        GLAccountNo := CreateGLAccNoWithTaxSetup('', TaxGroupCode[2], false);
        CreateCustomSalesInvoiceLines(SalesHeader, TaxGroupCode[1], GLAccountNo);
        CreateSalesLineGL(SalesHeader, GLAccountNo, TaxGroupCode[2], 0.02);
    end;

    local procedure CreateCustomPurchaseInvoice_TFS212811(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: array[2] of Code[20]; CurrencyCode: Code[10])
    var
        GLAccountNo: Code[20];
    begin
        LibraryPurchase.SetInvoiceRounding(false);

        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, DocumentType, CurrencyCode, TaxAreaCode);

        GLAccountNo := CreateGLAccNoWithTaxSetup('', TaxGroupCode[2], false);
        CreateCustomPurchaseInvoiceLines(PurchaseHeader, TaxGroupCode[1], GLAccountNo);
    end;

    local procedure CreateCustomSalesInvoice_TFS212811(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: array[2] of Code[20]; CurrencyCode: Code[10])
    var
        GLAccountNo: Code[20];
    begin
        LibrarySales.SetInvoiceRounding(false);

        CreateSalesHeaderWithTaxArea(SalesHeader, DocumentType, CurrencyCode, TaxAreaCode);

        GLAccountNo := CreateGLAccNoWithTaxSetup('', TaxGroupCode[2], false);
        CreateCustomSalesInvoiceLines(SalesHeader, TaxGroupCode[1], GLAccountNo);
    end;

    local procedure CreateCustomPurchaseInvoiceLines(var PurchaseHeader: Record "Purchase Header"; TaxGroupCode: Code[20]; GLAccountNo: Code[20])
    var
        UnitPrice: array[13] of Decimal;
        i: Integer;
    begin
        PrepareLineValues_TFS212811(UnitPrice);
        for i := 1 to ArrayLen(UnitPrice) do
            CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, TaxGroupCode, UnitPrice[i]);
    end;

    local procedure CreateCustomSalesInvoiceLines(var SalesHeader: Record "Sales Header"; TaxGroupCode: Code[20]; GLAccountNo: Code[20])
    var
        UnitPrice: array[13] of Decimal;
        i: Integer;
    begin
        PrepareLineValues_TFS212811(UnitPrice);
        for i := 1 to ArrayLen(UnitPrice) do
            CreateSalesLineGL(SalesHeader, GLAccountNo, TaxGroupCode, UnitPrice[i]);
    end;

    local procedure CalculateTaxAmount(TaxAreaCode: Code[20]; TaxDetail: Record "Tax Detail"; TaxDetail2: Record "Tax Detail"; LineAmount: Decimal): Decimal
    var
        TaxArea: Record "Tax Area";
        TaxAmount: Decimal;
        TaxAmount2: Decimal;
    begin
        TaxAmount := LineAmount * TaxDetail."Tax Below Maximum" / 100;
        TaxAmount2 := LineAmount * TaxDetail2."Tax Below Maximum" / 100;
        TaxArea.Get(TaxAreaCode);
        if TaxArea."Country/Region" = TaxArea."Country/Region"::US then
            exit(Round(TaxAmount + TaxAmount2));
        exit(Round(TaxAmount) + Round(TaxAmount2));
    end;

    local procedure CreateCustomer(TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Identification Type", Customer."Tax Identification Type"::"Legal Entity");
        Customer."RFC No." := LibraryUtility.GenerateGUID();
        Customer."CURP No." := LibraryUtility.GenerateGUID();
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyWithCustomExchRate(StartingDate: Date; ExchRate: Decimal): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Amount Rounding Precision", 0.01);
        Currency.Validate("Invoice Rounding Precision", 0.01);
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(Currency.Code, StartingDate, ExchRate, ExchRate);
        exit(Currency.Code);
    end;

    local procedure CreateItemCharge(var ItemCharge: Record "Item Charge"; VATProdPostingGroupCode: Code[20]; TaxGroupCode: Code[20])
    begin
        LibraryInventory.CreateItemCharge(ItemCharge);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroupCode);
        ItemCharge.Validate("Tax Group Code", TaxGroupCode);
        ItemCharge.Modify(true);
    end;

    local procedure CreateItemChargePurchaseLine(var PurchaseHeader: Record "Purchase Header"; AppliesToPurchLine: Record "Purchase Line")
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemCharge: Record "Item Charge";
        PurchLineCharge: Record "Purchase Line";
    begin
        CreateItemCharge(ItemCharge, AppliesToPurchLine."VAT Prod. Posting Group", AppliesToPurchLine."Tax Group Code");

        LibraryPurchase.CreatePurchaseLine(
          PurchLineCharge, PurchaseHeader, PurchLineCharge.Type::"Charge (Item)", ItemCharge."No.", AppliesToPurchLine.Quantity);

        PurchLineCharge.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 500, 2));
        PurchLineCharge.Modify(true);

        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchLineCharge, PurchaseHeader."Document Type",
          PurchaseHeader."No.", AppliesToPurchLine."Line No.", AppliesToPurchLine."No.");
    end;

    local procedure CreatePurchaseHeaderWithTaxArea(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; TaxAreaCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(''));
        PurchaseHeader.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithCurrency(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxDetail2: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLineWithTaxDetail(TaxDetail, TaxDetail2, false, DummyTaxCountry::CA);
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, DocumentType, CreateCurrencyWithCustomExchRate(WorkDate(), 1.0339), TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        exit(CalculateTaxAmount(TaxAreaCode, TaxDetail, TaxDetail2, PurchaseLine."Line Amount"));
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    begin
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);
        CreatePurchaseLineGL(PurchaseHeader, LibraryERM.CreateGLAccountWithPurchSetup(), TaxGroupCode, DirectUnitCost);
    end;

    local procedure CreatePurchaseLineGL(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesHeaderWithTaxArea(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; TaxAreaCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(''));
        SalesHeader.Validate("Bill-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithCurrency(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; TaxCountry: Option): Decimal
    var
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxDetail2: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLineWithTaxDetail(TaxDetail, TaxDetail2, false, TaxCountry);
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesHeaderWithTaxArea(SalesHeader, DocumentType, CreateCurrencyWithCustomExchRate(WorkDate(), 1.0339), TaxAreaCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"),
          LibraryRandom.RandInt(10));
        exit(CalculateTaxAmount(TaxAreaCode, TaxDetail, TaxDetail2, SalesLine."Line Amount"));
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    begin
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Order, '', TaxAreaCode);
        CreateSalesLineGL(SalesHeader, LibraryERM.CreateGLAccountWithSalesSetup(), TaxGroupCode, UnitPrice);
    end;

    local procedure CreateSalesLineGL(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceDocumentWithCurrency(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"): Decimal
    var
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
        TaxDetail: Record "Tax Detail";
        TaxDetail2: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLineWithTaxDetail(TaxDetail, TaxDetail2, false, DummyTaxCountry::CA);
        FindVATPostingSetup(VATPostingSetup);
        LibraryService.CreateServiceHeader(
          ServiceHeader, DocumentType, CreateCustomer(TaxAreaCode));
        ServiceHeader.Validate("Currency Code", CreateCurrencyWithCustomExchRate(WorkDate(), 1.0339));
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"));
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Modify(true);
        ModifyServiceLine(ServiceLine);
        exit(CalculateTaxAmount(TaxAreaCode, TaxDetail, TaxDetail2, ServiceLine."Line Amount"));
    end;

    local procedure CreateFCYSalesOrderWithCustomAmountAndExchageRate(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        PrepmtGLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxGroupCode: Code[20];
        CurrencyCode: Code[10];
    begin
        CurrencyCode := CreateCurrencyWithCustomExchRate(WorkDate(), 0.8);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();

        LibraryERM.CreatePrepaymentVATSetup(
          GLAccount, PrepmtGLAccount, "General Posting Type"::Sale,
          VATPostingSetup."VAT Calculation Type"::"Sales Tax",
          VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);
        PrepmtGLAccount.Validate("Tax Group Code", TaxGroupCode);
        PrepmtGLAccount.Modify(true);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GLAccount."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        Customer.Validate("Prepayment %", 50);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", 999);
        SalesLine.Modify(true);
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxGroupCode: Code[20]; TaxType: Option; TaxCountry: Option; CalculateTaxOnTax: Boolean; TaxBelowMaximum: Decimal)
    var
        TaxJurisdictionCode: Code[10];
    begin
        TaxJurisdictionCode := CreateSalesTaxJurisdiction(TaxCountry, CalculateTaxOnTax);
        LibraryERMTax.CreateTaxDetailWithTaxType(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxType, TaxBelowMaximum, 0);
    end;

    local procedure CreateTaxAreaLineWithTaxDetail(var TaxDetail: Record "Tax Detail"; var TaxDetail2: Record "Tax Detail"; CalculateTaxOnTax: Boolean; TaxCountry: Option): Code[20]
    var
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxDetail(
          TaxDetail, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", TaxCountry, CalculateTaxOnTax, LibraryRandom.RandInt(5));
        CreateTaxDetail(
          TaxDetail2, TaxGroupCode, TaxDetail2."Tax Type"::"Sales and Use Tax", TaxCountry, CalculateTaxOnTax, LibraryRandom.RandDec(10, 3));
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(TaxCountry);
        CreateSimpleTaxAreaLine(TaxAreaCode, TaxDetail."Tax Jurisdiction Code", 1);
        CreateSimpleTaxAreaLine(TaxAreaCode, TaxDetail2."Tax Jurisdiction Code", 2);
        exit(TaxAreaCode);
    end;

    local procedure CreateTaxAreaSetupWithTwoLinesExciseTaxAndSpecificAmounts(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; var SalesTaxAccountNo: Code[20]; var PurchaseTaxAccountNo: Code[20]; TaxBelowMaximum1: Decimal; TaxBelowMaximum2: Decimal)
    var
        TaxDetail: array[2] of Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxDetail(
          TaxDetail[1], TaxGroupCode, TaxDetail[1]."Tax Type"::"Sales and Use Tax", DummyTaxCountry::CA, true, TaxBelowMaximum1);
        CreateTaxDetail(
          TaxDetail[2], TaxGroupCode, TaxDetail[2]."Tax Type"::"Excise Tax", DummyTaxCountry::CA, false, TaxBelowMaximum2);

        TaxJurisdiction.Get(TaxDetail[1]."Tax Jurisdiction Code");
        SalesTaxAccountNo := TaxJurisdiction."Tax Account (Sales)";
        PurchaseTaxAccountNo := TaxJurisdiction."Tax Account (Purchases)";

        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        CreateSimpleTaxAreaLine(TaxAreaCode, TaxDetail[2]."Tax Jurisdiction Code", 1);
        CreateSimpleTaxAreaLine(TaxAreaCode, TaxDetail[1]."Tax Jurisdiction Code", 2);
    end;

    local procedure CreateTaxAreaSetupWithValues(var TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxBelowMax: Decimal; MaxAmt: Decimal; GLAccountNo: Code[20])
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccountNo);
        TaxJurisdiction.Modify(true);
        LibraryERMTax.CreateTaxDetailWithTaxType(
          TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", TaxBelowMax, MaxAmt);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdiction.Code);
    end;

    local procedure CreateSimpleTaxAreaLine(TaxAreaCode: Code[20]; TaxJurisdictionCode: Code[10]; CalculationOrder: Integer)
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
        TaxAreaLine.Validate("Calculation Order", CalculationOrder);
        TaxAreaLine.Modify(true);
    end;

    local procedure CreateGLAccNoWithTaxSetup(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Tax Area Code", TaxAreaCode);
        GLAccount.Validate("Tax Liable", TaxLiable);
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure PrepareLineValues_TFS212811(var UnitPrice: array[13] of Decimal)
    begin
        UnitPrice[1] := 400;
        UnitPrice[2] := 675;
        UnitPrice[3] := 53.75;
        UnitPrice[4] := 120;
        UnitPrice[5] := 600;
        UnitPrice[6] := 1800;
        UnitPrice[7] := 105;
        UnitPrice[8] := 175;
        UnitPrice[9] := 275;
        UnitPrice[10] := 1650;
        UnitPrice[11] := -101.5;
        UnitPrice[12] := -89.75;
        UnitPrice[13] := -45;
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineType: Enum "Purchase Line Type")
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, LineType);
        PurchaseLine.FindFirst();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; DocumentNo: Code[20])
    begin
        ServiceLine.SetRange("Document No.", DocumentNo);
        ServiceLine.FindFirst();
    end;

    local procedure ModifyServiceLine(var ServiceLine: Record "Service Line")
    begin
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure OpenSalesOrderPage(var SalesOrder: TestPage "Sales Order"; SalesHeader: Record "Sales Header")
    begin
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesQuotePage(var SalesQuote: TestPage "Sales Quote"; SalesHeader: Record "Sales Header")
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
    end;

    local procedure OpenServiceOrderPage(ServiceHeader: Record "Service Header"; var ServiceOrder: TestPage "Service Order")
    begin
        ServiceOrder.OpenView();
        ServiceOrder.GotoRecord(ServiceHeader);
    end;

    local procedure OpenServiceInvoicePage(ServiceHeader: Record "Service Header"; var ServiceInvoice: TestPage "Service Invoice")
    begin
        ServiceInvoice.OpenView();
        ServiceInvoice.GotoRecord(ServiceHeader);
    end;

    local procedure OpenPurchaseOrderPage(var PurchaseOrder: TestPage "Purchase Order"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenPurchaseQuotePage(var PurchaseQuote: TestPage "Purchase Quote"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseQuote.OpenView();
        PurchaseQuote.GotoRecord(PurchaseHeader);
    end;

    local procedure OpenSalesOrderList(SalesHeader: Record "Sales Header"; SkipShowingLinesWithoutVAT: Boolean)
    var
        SalesOrderList: Page "Sales Order List";
    begin
        SalesHeader.SetRecFilter();
        Clear(SalesOrderList);
        if SkipShowingLinesWithoutVAT then
            SalesOrderList.SkipShowingLinesWithoutVAT();
        SalesOrderList.SetTableView(SalesHeader);
        SalesOrderList.Run();
    end;

    local procedure OpenPurchaseOrderList(PurchaseHeader: Record "Purchase Header"; SkipShowingLinesWithoutVAT: Boolean)
    var
        PurchaseOrderList: Page "Purchase Order List";
    begin
        PurchaseHeader.SetRecFilter();
        Clear(PurchaseOrderList);
        if SkipShowingLinesWithoutVAT then
            PurchaseOrderList.SkipShowingLinesWithoutVAT();
        PurchaseOrderList.SetTableView(PurchaseHeader);
        PurchaseOrderList.Run();
    end;

    local procedure CreatePostPurchInvWithJobTask(var AmountInclTAX: Decimal; TaxDetail: Record "Tax Detail"; JobTask: Record "Job Task"; TaxAreaCode: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchInvWithJobTask(PurchaseHeader, PurchaseLine, TaxDetail, JobTask, TaxAreaCode);
        AmountInclTAX :=
          Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" *
            (1 + TaxDetail."Tax Below Maximum" / 100));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostPartialPurchInvWithJobTask(var PurchaseLine: Record "Purchase Line"; TaxDetail: Record "Tax Detail"; JobTask: Record "Job Task"; TaxAreaCode: Code[20]) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchInvWithJobTask(PurchaseHeader, PurchaseLine, TaxDetail, JobTask, TaxAreaCode);
        PurchaseLine.Validate(
          "Qty. to Invoice", Round(PurchaseLine."Qty. to Invoice" / LibraryRandom.RandIntInRange(3, 5)));
        PurchaseLine.Modify(true);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchaseLine.Find();
    end;

    local procedure CreatePurchInvWithJobTask(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TaxDetail: Record "Tax Detail"; JobTask: Record "Job Task"; TaxAreaCode: Code[20])
    begin
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount('', TaxDetail."Tax Group Code"),
          LibraryRandom.RandIntInRange(10, 50));
        ModifyPurchLineWithJobTask(PurchaseLine, JobTask);
    end;

    local procedure AddChargeAssignmentToPurchaseOrder(VATPostingSetup: Record "VAT Posting Setup"; TaxGroupCode: Code[20]; PurchaseLine: Record "Purchase Line"): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        ItemCharge: Record "Item Charge";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          CreateItem(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode),
          LibraryRandom.RandInt(10));
        CreateItemCharge(ItemCharge, VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader,
            PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Modify(true);
        PurchaseLine.ShowItemChargeAssgnt();
        // Assign value equally in Handler
        exit(PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeaderWithTaxArea(SalesHeader, DocumentType, '', TaxAreaCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount('', TaxGroupCode), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostElectronicPmtLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; AccountNo: Code[20]; Amount: Decimal; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AppliesToDocType: Enum "Gen. Journal Document Type")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        CreateGenJournal(GenJournalLine, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Validate("Check Exported", true);  // Validating Check Exported to avoid the mannual setup for Electronic payment.
        GenJournalLine.Validate("Check Transmitted", true);  // Validating Check Transmitted to avoid the mannual setup for Electronic payment.
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalWithTaxDetail(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date)
    var
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateTaxAreaLine(TaxDetail);
        FindVATPostingSetup(VATPostingSetup);

        GLAccount.Get(CreateGLAccount('', TaxDetail."Tax Group Code"));
        GLAccount."VAT Bus. Posting Group" := '';
        GLAccount.Modify();

        GenJournalLineUsingTaxSetup(
          GenJournalLine, PostingDate, GenJournalLine."Document Type"::" ", GLAccount."No.",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxDetail."Tax Group Code"), -LibraryRandom.RandDec(10, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateFADepreciationBook(FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingGroup: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FANo, DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Book Code", DepreciationBookCode);
        FADepreciationBook.Validate("Depreciation Starting Date", WorkDate());
        FADepreciationBook.Validate("Depreciation Ending Date", WorkDate());
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateAndModifyDepreciationBook(var DepreciationBook: Record "Depreciation Book")
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);
    end;

    local procedure CreateFAPostingGroup(): Code[20]
    var
        GLAccount: Record "G/L Account";
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup.Validate("Acquisition Cost Account", GLAccount."No.");
        FAPostingGroup.Modify(true);
        exit(FAPostingGroup.Code);
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset"; FAPostingGroup: Code[20])
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup);
        FixedAsset.Modify(true);
    end;

    local procedure GenJournalLineUsingTaxSetup(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; Amount: Decimal)
    begin
        CreateGenJournal(
          GenJournalLine, DocumentType, GenJournalLine."Account Type"::"G/L Account", AccountNo, Amount);
        GenJournalLine.Validate("GST/HST", GenJournalLine."GST/HST"::"Self Assessment");
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGenJournal(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("Unit Price", 100 + LibraryRandom.RandDec(100, 2));  // Using RANDOM value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; No: Code[20]; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
    end;

    local procedure CreatePurchaseDocumentWithTaxArea(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; No: Code[20]; VendorNo: Code[20]; TaxAreaCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseLine, DocumentType, Type, No, VendorNo);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithTaxArea(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxDetailWithExpense(TaxDetail);
        CreatePurchaseDocumentWithTaxArea(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item,
          CreateItem('', TaxDetail."Tax Group Code"),
          CreateVendor(TaxAreaCode), TaxAreaCode);

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure CreatePurchaseOrderWithItemCharge(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        CreatePurchaseOrderWithTaxArea(PurchaseHeader, PurchaseLine);
        CreateItemChargePurchaseLine(PurchaseHeader, PurchaseLine);
    end;

    local procedure CreatePurchInvoiceWithTaxDifference(var PurchaseHeader: Record "Purchase Header"; DocumentProductArea: Enum "Sales Tax Document Area")
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount('', TaxDetail."Tax Group Code"), LibraryRandom.RandIntInRange(10, 100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        CreateSalesTaxAmountDifference(
          TaxDetail, PurchaseHeader."No.", PurchaseHeader."Document Type", PurchaseHeader."Tax Area Code", DocumentProductArea);
    end;

    local procedure CreatePurchaseInvoiceWithProvTaxSetup(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10]; TaxAreaCode: Code[20]; ProvincialTaxAreaCode: Code[20]; GLAccountNo: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CurrencyCode, TaxAreaCode);
        PurchaseHeader.Validate("Provincial Tax Area Code", ProvincialTaxAreaCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchLineWithUseTax(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATProdPostingGroup: Code[20]; TaxGroupCode: Code[20]; UseTax: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATProdPostingGroup, TaxGroupCode), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Use Tax", UseTax);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithTaxDifference(var SalesHeader: Record "Sales Header"; DocumentProductArea: Enum "Sales Tax Document Area")
    var
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Invoice, '', TaxAreaCode);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount('', TaxDetail."Tax Group Code"), LibraryRandom.RandIntInRange(10, 100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        CreateSalesTaxAmountDifference(
          TaxDetail, SalesHeader."No.", SalesHeader."Document Type", SalesHeader."Tax Area Code", DocumentProductArea);
    end;

    local procedure CreateSalesTaxJurisdiction(CountryRegion: Option; CalculateTaxOnTax: Boolean): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(CountryRegion));
        TaxJurisdiction.Validate("Calculate Tax on Tax", CalculateTaxOnTax);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateSalesTaxJurisdictionWithReportTo(CountryRegion: Option; ReportToJurisdictionCode: Code[10]): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(CountryRegion));
        TaxJurisdiction.Validate("Report-to Jurisdiction", ReportToJurisdictionCode);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail")
    var
        TaxGroupCode: Code[20];
        TaxJurisdictionCode: Code[10];
    begin
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        TaxJurisdictionCode := CreateSalesTaxJurisdiction(DummyTaxCountry::US, false);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, LibraryRandom.RandInt(10));
    end;

    local procedure CreateVendor(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", '');
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateSalesTaxAmountDifference(TaxDetail: Record "Tax Detail"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; DocumentProductArea: Enum "Sales Tax Document Area")
    var
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        SalesTaxAmountDifference.Init();
        SalesTaxAmountDifference."Document No." := DocumentNo;
        SalesTaxAmountDifference."Document Type" := DocumentType.AsInteger();
        SalesTaxAmountDifference."Document Product Area" := DocumentProductArea;
        SalesTaxAmountDifference."Tax Area Code" := TaxAreaCode;
        SalesTaxAmountDifference."Tax Jurisdiction Code" := TaxDetail."Tax Jurisdiction Code";
        SalesTaxAmountDifference."Tax %" := LibraryRandom.RandIntInRange(10, 50);
        SalesTaxAmountDifference."Tax Group Code" := TaxDetail."Tax Group Code";
        SalesTaxAmountDifference."Expense/Capitalize" := TaxDetail."Expense/Capitalize";
        SalesTaxAmountDifference."Tax Type" := TaxDetail."Tax Type";
        SalesTaxAmountDifference."Use Tax" := true;
        SalesTaxAmountDifference."Tax Difference" := LibraryRandom.RandIntInRange(10, 90);
        SalesTaxAmountDifference.Insert();
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"): Code[20]
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, LibraryERMTax.CreateTaxArea_US(), TaxDetail."Tax Jurisdiction Code");
        exit(TaxAreaLine."Tax Area");
    end;

    local procedure CreateTaxDetailWithExpense(var TaxDetail: Record "Tax Detail") TaxAreaCode: Code[20]
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        UpdateTaxDetailExpenseCapitalize(TaxDetail."Tax Jurisdiction Code", TaxDetail."Tax Group Code", TaxDetail."Tax Type", true);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure CreateEmptyVATPostingSetupSalesTax()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Init();
        VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Sales Tax";
        if VATPostingSetup.Insert() then;
    end;

    local procedure CreatePurchInvWithCurrencyAndUseTaxLine(var PurchaseHeader: Record "Purchase Header"; var GLAccountArray: array[4] of Code[20]; var ExpectedAmountArray: array[4] of Decimal; PurchaseLineCount: Integer; UseTaxLineNo: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        GLAccount: Record "G/L Account";
        VendorPostingGroup: Record "Vendor Posting Group";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        DirectUnitCost: Decimal;
        SalesTaxAmount: Decimal;
        SalesTaxPct: Decimal;
        I: Integer;
    begin
        CreateSalesTaxSetup(TaxAreaCode, TaxGroupCode, GLAccountArray, SalesTaxPct);
        VATPostingSetup.Get('', '');

        GLAccount.Get(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode));
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);

        CreatePurchaseHeaderWithTaxArea(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateCurrencyWithRandomExchRate(), TaxAreaCode);
        DirectUnitCost := LibraryRandom.RandDecInRange(100, 1000, 2);
        SalesTaxAmount := DirectUnitCost / 100 * SalesTaxPct;

        for I := 1 to PurchaseLineCount do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
              GLAccount."No.", 1);
            PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
            PurchaseLine.Validate("Use Tax", DoesLineUseTax(UseTaxLineNo, I));
            PurchaseLine.Modify(true);
        end;

        GetExpectedAmounts(
          ExpectedAmountArray, DirectUnitCost, SalesTaxAmount,
          PurchaseHeader."Currency Factor", PurchaseLineCount, UseTaxLineNo);

        GLAccountArray[1] := GLAccount."No.";
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        GLAccountArray[2] := VendorPostingGroup."Payables Account";
    end;

    local procedure CreatePurchInvWithCurrencyAndProvTax(var PurchaseHeader: Record "Purchase Header"; var GLAccountArray: array[4] of Code[20]; var ExpectedAmountArray: array[4] of Decimal)
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        ProvTaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        DirectUnitCost: Decimal;
        SalesTaxAmount: Decimal;
        ProvTaxAmount: Decimal;
        SalesTaxPct: Decimal;
        ProvTaxPct: Decimal;
    begin
        CreateSalesTaxSetupProvTax(TaxAreaCode, ProvTaxAreaCode, TaxGroupCode, GLAccountArray, SalesTaxPct, ProvTaxPct);

        DirectUnitCost := LibraryRandom.RandDecInRange(1000, 2000, 2);
        SalesTaxAmount := DirectUnitCost / 100 * SalesTaxPct;
        ProvTaxAmount := DirectUnitCost / 100 * ProvTaxPct;

        GLAccountNo := CreateGLAccount('', TaxGroupCode);
        CreatePurchaseInvoiceWithProvTaxSetup(
          PurchaseHeader, CreateCurrencyWithRandomExchRate(), TaxAreaCode,
          ProvTaxAreaCode, GLAccountNo, DirectUnitCost);

        GetExpectedAmountsProvTax(
          ExpectedAmountArray, DirectUnitCost, SalesTaxAmount, ProvTaxAmount, PurchaseHeader."Currency Factor");

        GLAccountArray[1] := GLAccountNo;
        VendorPostingGroup.Get(PurchaseHeader."Vendor Posting Group");
        GLAccountArray[2] := VendorPostingGroup."Payables Account";
    end;

    local procedure CreatePurchOrderWithExciseTax(var PurchaseHeader: Record "Purchase Header"; var TaxAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        ExciseTaxPct: Decimal;
    begin
        CreateSalesTaxSetupExciseTax(TaxAreaCode, TaxGroupCode, ExciseTaxPct);
        VATPostingSetup.Get('', '');

        GLAccount.Get(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode));
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);

        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Modify(true);
        // Excise tax amount = "Tax Detail"."Tax Below Maximum"
        TaxAmount := ExciseTaxPct;
    end;

    local procedure CreateAndPostPurchDocWithExciseTax(var DocumentNo: Code[20]; var TaxAmount: Decimal; var PostingDate: Date; DocumentType: Enum "Purchase Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        ExciseTaxPct: Decimal;
    begin
        CreateSalesTaxSetupExciseTax(TaxAreaCode, TaxGroupCode, ExciseTaxPct);
        VATPostingSetup.Get('', '');

        GLAccount.Get(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode));
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);

        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, DocumentType, '', TaxAreaCode);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then
            PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Validate("Qty. per Unit of Measure", LibraryRandom.RandIntInRange(10, 20));
        PurchaseLine.Validate(Quantity);
        // update "Quantity (Base)"
        PurchaseLine.Modify(true);
        // Excise tax amount = "Tax Detail"."Tax Below Maximum" * "Quantity (Base)"
        TaxAmount := ExciseTaxPct * PurchaseLine."Qty. per Unit of Measure";
        PostingDate := PurchaseHeader."Posting Date";
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocWithExciseTax(var DocumentNo: Code[20]; var TaxAmount: Decimal; var PostingDate: Date; DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        ExciseTaxPct: Decimal;
    begin
        CreateSalesTaxSetupExciseTax(TaxAreaCode, TaxGroupCode, ExciseTaxPct);
        VATPostingSetup.Get('', '');

        GLAccount.Get(CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode));
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Modify(true);

        CreateSalesHeaderWithTaxArea(SalesHeader, DocumentType, '', TaxAreaCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));
        SalesLine.Validate("Qty. per Unit of Measure", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate(Quantity);
        // update "Quantity (Base)"
        SalesLine.Modify(true);
        // Excise tax amount = "Tax Detail"."Tax Below Maximum" * "Quantity (Base)"
        TaxAmount := ExciseTaxPct * SalesLine."Qty. per Unit of Measure";
        PostingDate := SalesHeader."Posting Date";
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateReleasePurchOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATProdPostGroupCode: Code[20]; TaxGroupCode: Code[20]; TaxAreaCode: Code[20])
    begin
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseLine.Type::Item,
          CreateItem(VATProdPostGroupCode, TaxGroupCode),
          CreateVendor(TaxAreaCode));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATProdPostGroupCode: Code[20]; TaxGroupCode: Code[20]; TaxAreaCode: Code[20])
    begin
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Order, '', TaxAreaCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(VATProdPostGroupCode, TaxGroupCode),
          LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesTaxSetup(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; var GLAccountArray: array[4] of Code[20]; var SalesTaxPct: Decimal)
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        TaxDetail.Validate(
          "Tax Below Maximum",
          TaxDetail."Tax Below Maximum" + TaxDetail."Tax Below Maximum" / 10); // getting decimal percent
        TaxDetail.Modify(true);
        SalesTaxPct := TaxDetail."Tax Below Maximum";
        TaxGroupCode := TaxDetail."Tax Group Code";
        TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        GLAccountArray[3] := TaxJurisdiction."Tax Account (Purchases)";
        GLAccountArray[4] := TaxJurisdiction."Reverse Charge (Purchases)";
    end;

    local procedure CreateSalesTaxSetupProvTax(var TaxAreaCode: Code[20]; var ProvTaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; var GLAccountArray: array[4] of Code[20]; var SalesTaxPct: Decimal; var ProvTaxPct: Decimal)
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxDetail(
          TaxDetail, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", DummyTaxCountry::CA, false, LibraryRandom.RandInt(10));
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxDetail."Tax Jurisdiction Code");
        TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        GLAccountArray[3] := TaxJurisdiction."Tax Account (Purchases)";
        SalesTaxPct := TaxDetail."Tax Below Maximum";

        CreateTaxDetail(
          TaxDetail, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", DummyTaxCountry::CA, false, LibraryRandom.RandInt(10));
        UpdateTaxDetailExpenseCapitalize(TaxDetail."Tax Jurisdiction Code", TaxDetail."Tax Group Code", TaxDetail."Tax Type", true);
        ProvTaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, ProvTaxAreaCode, TaxDetail."Tax Jurisdiction Code");
        TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        GLAccountArray[4] := TaxJurisdiction."Reverse Charge (Purchases)";
        ProvTaxPct := TaxDetail."Tax Below Maximum";
    end;

    local procedure CreateSalesTaxSetupExciseTax(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; var ExciseTaxPct: Decimal)
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
    begin
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        TaxJurisdictionCode := CreateSalesTaxJurisdiction(DummyTaxCountry::US, false);
        ExciseTaxPct := LibraryRandom.RandDec(10, 2);
        LibraryERMTax.CreateTaxDetailWithTaxType(
          TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Excise Tax", ExciseTaxPct, 0);
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
    end;

    local procedure CreateTaxJurisdictionAndTaxDetail(TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
    begin
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_CA();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, LibraryRandom.RandInt(10));
    end;

    local procedure CreateCurrencyWithRandomExchRate(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Amount Rounding Precision", 0.01);
        Currency.Validate("Invoice Rounding Precision", 0.01);
        Currency.Modify(true);
        LibraryERM.CreateExchangeRate(
          Currency.Code, WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
        exit(Currency.Code);
    end;

    local procedure CreateUnitPrice(var LineAmount: array[2] of Decimal)
    begin
        LineAmount[1] := LibraryRandom.RandDecInRange(50, 100, 2);
        LineAmount[2] := LibraryRandom.RandDecInRange(50, 100, 2);
    end;

    local procedure CreateUnitPriceWithVAT(var LineAmount: array[2] of Decimal; var LineAmountIncludingVAT: array[2] of Decimal; VATPercent: Decimal)
    begin
        CreateUnitPrice(LineAmount);
        LineAmountIncludingVAT[1] := Round(LineAmount[1] * (1 + VATPercent / 100));
        LineAmountIncludingVAT[2] := Round(LineAmount[2] * (1 + VATPercent / 100));
    end;

    local procedure DoesLineUseTax(UseTaxLineNo: Integer; LineCounter: Integer): Boolean
    begin
        exit(
          ((UseTaxLineNo = 1) and (LineCounter mod 2 <> 0)) or
          ((UseTaxLineNo = 2) and (LineCounter mod 2 = 0)));
    end;

    local procedure InsertSalesTaxLineWithFixedValues(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; TaxBaseAmountFCY: Decimal; TaxPct: Decimal)
    begin
        SalesTaxAmountLine."Tax Area Code for Key" := LibraryERMTax.CreateTaxArea_US();
        SalesTaxAmountLine."Tax Base Amount FCY" := TaxBaseAmountFCY;
        SalesTaxAmountLine."Tax %" := TaxPct;
        SalesTaxAmountLine.Insert();
    end;

    local procedure ModifyPurchaseLineDepreciationBook(PurchaseLine: Record "Purchase Line"; DepreciationBookCode: Code[10])
    begin
        PurchaseLine.Validate("Depreciation Book Code", DepreciationBookCode);
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorCrMemoNo: Code[35])
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", VendorCrMemoNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; LineDiscount: Decimal)
    begin
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Validate("Line Discount %", LineDiscount);
        PurchaseLine.Modify(true);
    end;

    local procedure ModifySalesLine(SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(100, 2));  // Using Random value for Line Discount %.
        SalesLine.Modify(true);
    end;

    local procedure ModifyPurchasesPayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Use Vendor's Tax Area Code", true);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ModifyPurchLineWithJobTask(var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task")
    begin
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Validate("Job Line Type", PurchaseLine."Job Line Type"::"Both Budget and Billable");
        PurchaseLine.Validate("Job Unit Price", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure MockSalesTaxCalc(var SalesTaxAmountLine: Record "Sales Tax Amount Line"; DocumentNo: Code[20]; PostingDate: Date; TableID: Integer)
    var
        SalesTaxCalc: Codeunit "Sales Tax Calculate";
    begin
        SalesTaxCalc.StartSalesTaxCalculation();
        case TableID of
            DATABASE::"Purch. Inv. Header":
                SalesTaxCalc.AddPurchInvoiceLines(DocumentNo);
            DATABASE::"Purch. Cr. Memo Hdr.":
                SalesTaxCalc.AddPurchCrMemoLines(DocumentNo);
            DATABASE::"Sales Invoice Header":
                SalesTaxCalc.AddSalesInvoiceLines(DocumentNo);
            DATABASE::"Sales Cr.Memo Header":
                SalesTaxCalc.AddSalesCrMemoLines(DocumentNo);
        end;
        SalesTaxCalc.EndSalesTaxCalculation(PostingDate);
        SalesTaxCalc.GetSummarizedSalesTaxTable(SalesTaxAmountLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenPurchaseOrderStatistics(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.Statistics.Invoke();
    end;
#endif

    local procedure OpenPurchOrderStatistics(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchaseOrderStats.Invoke();
    end;

    local procedure PostPurchaseDocument(PurchaseLine: Record "Purchase Line") DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PostPurchaseItemLine(var PurchaseHeader: Record "Purchase Header"; QtyToReceive: Decimal; QtyToInvoice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PostPurchaseDocumentLine(PurchaseHeader, PurchaseLine.Type::Item, QtyToReceive, QtyToInvoice);
    end;

    local procedure PostPurchaseChargeLine(var PurchaseHeader: Record "Purchase Header"; QtyToReceive: Decimal; QtyToInvoice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine.Type::"Charge (Item)");
        UpdateItemChargeQtyToAssign(PurchaseLine, PurchaseLine."Quantity Invoiced" + QtyToInvoice);

        PostPurchaseDocumentLine(PurchaseHeader, PurchaseLine.Type::"Charge (Item)", QtyToReceive, QtyToInvoice);
    end;

    local procedure PostPurchaseDocumentLine(var PurchaseHeader: Record "Purchase Header"; LineType: Enum "Purchase Line Type"; QtyToReceive: Decimal; QtyToInvoice: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        if QtyToInvoice <> 0 then
            UpdateVendorInvoiceNo(PurchaseHeader);

        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", LineType);
        UpdateQtyToReceiveAndInvoice(PurchaseLine, QtyToReceive, QtyToInvoice);

        PurchaseLine.SetFilter("Line No.", '<>%1', PurchaseLine."Line No.");
        PurchaseLine.SetRange(Type);
        if PurchaseLine.FindSet() then
            repeat
                UpdateQtyToReceiveAndInvoice(PurchaseLine, 0, 0);
            until PurchaseLine.Next() = 0;

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, QtyToReceive <> 0, QtyToInvoice <> 0);
    end;

    local procedure PostSalesDocument(SalesLine: Record "Sales Line") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PrintStandardSalesOrderConfReport(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, false, SalesHeader);
    end;

    local procedure PrintSalesOrderReport(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::"Sales Order", true, false, SalesHeader);
    end;

    local procedure UpdateCustomer(CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer."RFC No." := '';
        Customer."CURP No." := '';
        Customer.Modify(true);
    end;

    local procedure UpdateItemChargeQtyToAssign(PurchaseLine: Record "Purchase Line"; NewQtyToAssign: Decimal)
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        ItemChargeAssignmentPurch.SetRange("Document Type", PurchaseLine."Document Type");
        ItemChargeAssignmentPurch.SetRange("Document No.", PurchaseLine."Document No.");
        ItemChargeAssignmentPurch.SetRange("Document Line No.", PurchaseLine."Line No.");
        ItemChargeAssignmentPurch.FindFirst();

        ItemChargeAssignmentPurch.Validate("Qty. to Assign", NewQtyToAssign);
        ItemChargeAssignmentPurch.Modify(true);
    end;

    local procedure UpdateTaxAreaCodeCompanyInformation(TaxAreaCode: Code[20])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Validate("Tax Area Code", TaxAreaCode);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateMaxVATDifferenceAllowedGeneralLedgerSetup(MaxVATDifferenceAllowed: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Max. VAT Difference Allowed", MaxVATDifferenceAllowed);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateExtDocNoPurchasesPayablesSetup(NewExternalDocNo: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", NewExternalDocNo);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateQtyToReceiveAndInvoice(var PurchLine: Record "Purchase Line"; QtyToReceive: Decimal; QtyToInvoice: Decimal)
    begin
        PurchLine.Validate("Qty. to Receive", QtyToReceive);
        PurchLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchLine.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVATInUseOnGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."VAT in Use" := false;
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option; NewValue: Boolean)
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxDetail.Get(TaxJurisdictionCode, TaxGroupCode, TaxType, WorkDate());
        TaxDetail.Validate("Expense/Capitalize", NewValue);
        TaxDetail.Modify(true);
    end;

    local procedure UpdateReportLayoutSelection(ReportID: Integer; ReportName: Text[250])
    var
        ReportLayouts: TestPage "Report Layouts";
    begin
        ReportLayouts.OpenEdit();
        ReportLayouts.Filter.SetFilter("Report ID", Format(ReportID));
        ReportLayouts.Filter.SetFilter(Name, ReportName);
        ReportLayouts.IsDefaultLayout.SetValue(true);
        ReportLayouts.Close();
    end;

    local procedure ValidatePurchaseInvoiceTaxAreaThroughPage(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice."Tax Area Code".SetValue(TaxAreaCode);
        PurchaseInvoice.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseInvoiceTaxLiableThroughPage(var PurchaseHeader: Record "Purchase Header"; NewTaxLiable: Boolean)
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice."Tax Liable".SetValue(NewTaxLiable);
        PurchaseInvoice.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseCreditMemoTaxAreaThroughPage(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo."Tax Area Code".SetValue(TaxAreaCode);
        PurchaseCreditMemo.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseCreditMemoTaxLiableThroughPage(var PurchaseHeader: Record "Purchase Header"; NewTaxLiable: Boolean)
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo."Tax Liable".SetValue(NewTaxLiable);
        PurchaseCreditMemo.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseOrderTaxAreaThroughPage(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder."Tax Area Code".SetValue(TaxAreaCode);
        PurchaseOrder.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseOrderTaxLiableThroughPage(var PurchaseHeader: Record "Purchase Header"; NewTaxLiable: Boolean)
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.GotoRecord(PurchaseHeader);
        PurchaseOrder."Tax Liable".SetValue(NewTaxLiable);
        PurchaseOrder.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseReturnOrderTaxAreaThroughPage(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder."Tax Area Code".SetValue(TaxAreaCode);
        PurchaseReturnOrder.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseReturnOrderTaxLiableThroughPage(var PurchaseHeader: Record "Purchase Header"; NewTaxLiable: Boolean)
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.GotoRecord(PurchaseHeader);
        PurchaseReturnOrder."Tax Liable".SetValue(NewTaxLiable);
        PurchaseReturnOrder.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseBlanketOrderTaxAreaThroughPage(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
        BlanketPurchaseOrder."Tax Area Code".SetValue(TaxAreaCode);
        BlanketPurchaseOrder.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseBlanketOrderTaxLiableThroughPage(var PurchaseHeader: Record "Purchase Header"; NewTaxLiable: Boolean)
    var
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.GotoRecord(PurchaseHeader);
        BlanketPurchaseOrder."Tax Liable".SetValue(NewTaxLiable);
        BlanketPurchaseOrder.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseQuoteTaxAreaThroughPage(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20])
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote."Tax Area Code".SetValue(TaxAreaCode);
        PurchaseQuote.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidatePurchaseQuoteTaxLiableThroughPage(var PurchaseHeader: Record "Purchase Header"; NewTaxLiable: Boolean)
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);
        PurchaseQuote."Tax Liable".SetValue(NewTaxLiable);
        PurchaseQuote.Close();
        PurchaseHeader.Find();
    end;

    local procedure ValidateSalesInvoiceTaxAreaThroughPage(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice."Tax Area Code".SetValue(TaxAreaCode);
        SalesInvoice.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesInvoiceTaxLiableThroughPage(var SalesHeader: Record "Sales Header"; NewTaxLiable: Boolean)
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice."Tax Liable".SetValue(NewTaxLiable);
        SalesInvoice.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesCreditMemoTaxAreaThroughPage(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo."Tax Area Code".SetValue(TaxAreaCode);
        SalesCreditMemo.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesCreditMemoTaxLiableThroughPage(var SalesHeader: Record "Sales Header"; NewTaxLiable: Boolean)
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo."Tax Liable".SetValue(NewTaxLiable);
        SalesCreditMemo.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesOrderTaxAreaThroughPage(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Tax Area Code".SetValue(TaxAreaCode);
        SalesOrder.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesOrderTaxLiableThroughPage(var SalesHeader: Record "Sales Header"; NewTaxLiable: Boolean)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Tax Liable".SetValue(NewTaxLiable);
        SalesOrder.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesReturnOrderTaxAreaThroughPage(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder."Tax Area Code".SetValue(TaxAreaCode);
        SalesReturnOrder.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesReturnOrderTaxLiableThroughPage(var SalesHeader: Record "Sales Header"; NewTaxLiable: Boolean)
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
        SalesReturnOrder."Tax Liable".SetValue(NewTaxLiable);
        SalesReturnOrder.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesBlanketOrderTaxAreaThroughPage(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20])
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder."Tax Area Code".SetValue(TaxAreaCode);
        BlanketSalesOrder.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesBlanketOrderTaxLiableThroughPage(var SalesHeader: Record "Sales Header"; NewTaxLiable: Boolean)
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder."Tax Liable".SetValue(NewTaxLiable);
        SalesHeader.Find();
    end;

    local procedure ValidateSalesQuoteTaxAreaThroughPage(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20])
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote."Tax Area Code".SetValue(TaxAreaCode);
        SalesQuote.Close();
        SalesHeader.Find();
    end;

    local procedure ValidateSalesQuoteTaxLiableThroughPage(var SalesHeader: Record "Sales Header"; NewTaxLiable: Boolean)
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote."Tax Liable".SetValue(NewTaxLiable);
        SalesQuote.Close();
        SalesHeader.Find();
    end;

    local procedure SetupTFS358890SalesTaxLine(var SalesTaxAmountLine: Record "Sales Tax Amount Line")
    begin
        InsertSalesTaxLineWithFixedValues(SalesTaxAmountLine, 3250, 6.25);
        InsertSalesTaxLineWithFixedValues(SalesTaxAmountLine, 3250, 1);
        InsertSalesTaxLineWithFixedValues(SalesTaxAmountLine, 3250, 0);
    end;

    local procedure GetTFS358890RoundingResult(): Decimal
    begin
        exit(235.63);
    end;

    local procedure GetTaxAccountSales(TaxAreaCode: Code[20]): Code[20]
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        TaxAreaLine.FindFirst();

        TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code");
        exit(TaxJurisdiction."Tax Account (Sales)");
    end;

    local procedure GetTaxAccountPurchases(TaxAreaCode: Code[20]): Code[20]
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxAreaLine.SetRange("Tax Area", TaxAreaCode);
        TaxAreaLine.FindFirst();

        TaxJurisdiction.Get(TaxAreaLine."Tax Jurisdiction Code");
        exit(TaxJurisdiction."Tax Account (Purchases)");
    end;

    local procedure GetJurTaxAccPurchases(TaxJurisdictionCode: Code[10]): Code[20]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get(TaxJurisdictionCode);
        exit(TaxJurisdiction."Tax Account (Purchases)");
    end;

    local procedure GetJurTaxAccReverse(TaxJurisdictionCode: Code[10]): Code[20]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Get(TaxJurisdictionCode);
        exit(TaxJurisdiction."Reverse Charge (Purchases)");
    end;

    local procedure GetVendorPayablesAccount(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure InitJobAndTaxDetailWithExpense(var Job: Record Job; var JobTask: Record "Job Task"; var TaxDetail: Record "Tax Detail"): Code[20]
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        exit(CreateTaxDetailWithExpense(TaxDetail));
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryAmount(GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("Bal. Account No.", GenJournalLine."Bal. Account No.");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          GenJournalLine.Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; Amount: Decimal; GSTHST: Enum "GST HST Tax Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("GST/HST", GSTHST);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountError, VATEntry.FieldCaption(Base), VATEntry.Base, VATEntry.TableCaption()));
    end;

    local procedure VerifyJobLedgerEntryTotalCost(JobNo: Code[20]; DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobLedgerEntry.SetRange("Job No.", JobNo);
        JobLedgerEntry.SetRange("Document No.", DocumentNo);
        JobLedgerEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, JobLedgerEntry."Total Cost", '');
    end;

    local procedure VerifyValueEntriesCostAmount(DocumentNo: Code[20]; ExpectedAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document Type", ValueEntry."Document Type"::"Purchase Invoice");
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreEqual(ExpectedAmount, ValueEntry."Cost Amount (Actual)", WrongValueEntryAmountErr);
    end;

    local procedure VerifyUnitCostWithTaxInJobLedgEntry(PurchLine: Record "Purchase Line"; DocNo: Code[20])
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        GLSetup: Record "General Ledger Setup";
    begin
        JobLedgerEntry.SetRange("Job No.", PurchLine."Job No.");
        JobLedgerEntry.SetRange("Document No.", DocNo);
        JobLedgerEntry.FindFirst();
        GLSetup.Get();
        Assert.AreEqual(
          Round(
            PurchLine."Unit Cost (LCY)" + PurchLine."Tax To Be Expensed" / PurchLine.Quantity,
            GLSetup."Unit-Amount Rounding Precision"),
          JobLedgerEntry."Unit Cost (LCY)", StrSubstNo(WrongUnitCostErr, JobLedgerEntry."Entry No."));
    end;

    local procedure CreatePurchaseDocumentWithSpecificAmountAndTaxArea(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        VATPostingSetup.Get('', '');
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithSpecificAmountAndTaxArea(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        VATPostingSetup.Get('', '');
        CreateSalesHeaderWithTaxArea(SalesHeader, SalesHeader."Document Type"::Order, '', TaxAreaCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode), 1);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesTaxSetupWithSpecificTaxPct(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; var TaxAccountNo: Code[20]; SalesTaxPct: Decimal; Type: Option Sale,Purchase)
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        CreateSalesTaxJurisdiction(DummyTaxCountry::US, false);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail);
        TaxGroupCode := TaxDetail."Tax Group Code";
        TaxJurisdiction.Get(TaxDetail."Tax Jurisdiction Code");
        if Type = Type::Sale then
            TaxAccountNo := TaxJurisdiction."Tax Account (Sales)"
        else
            TaxAccountNo := TaxJurisdiction."Tax Account (Purchases)";
        TaxDetail.Validate("Tax Below Maximum", SalesTaxPct);
        TaxDetail.Modify();
    end;

    local procedure CreatePurchDocWithNegativeLineAndCustomAmounts(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: array[2] of Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        VATPostingSetup.Get('', '');
        CreatePurchaseHeaderWithTaxArea(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', TaxAreaCode);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost[1]);
        PurchaseLine.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group", TaxGroupCode), 1);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost[2]);
        PurchaseLine.Modify(true);
    end;

    local procedure SetVATDiffSetup(NewMaxVATDiffAllowed: Decimal; NewAllowVATDiff: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Max. VAT Difference Allowed", NewMaxVATDiffAllowed);
        GLSetup.Modify(true);

        SalesSetup.Get();
        SalesSetup.Validate("Allow VAT Difference", NewAllowVATDiff);
        SalesSetup.Modify(true);

        PurchSetup.Get();
        PurchSetup.Validate("Allow VAT Difference", NewAllowVATDiff);
        PurchSetup.Modify(true);
    end;

    local procedure VerifyGLEntryUseTax(DocumentNo: Code[20]; GLAccountArray: array[4] of Code[20]; ExpectedAmountArray: array[4] of Decimal)
    var
        GLEntry: Record "G/L Entry";
        ActualAmountArray: array[4] of Decimal;
        I: Integer;
    begin
        // [THEN] Document amount should be posted as Amount + Sales Tax Amount from lines with "Use Tax" = TRUE
        // [THEN] Vendor amount should be posted as Amount + Sales Tax Amount from lines with "Use Tax" = FALSE
        GLEntry.SetRange("Document No.", DocumentNo);
        GetActualAmounts(GLEntry, ActualAmountArray, GLAccountArray);
        for I := 1 to ArrayLen(GLAccountArray) do
            Assert.AreNearlyEqual(ExpectedAmountArray[I], ActualAmountArray[I], 0.1, GLEntryAmountErr);
    end;

    local procedure VerifyGLEntryTaxAmount(DocumentNo: Code[20]; TaxAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", TaxAccountNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, TaxAmountErr)
    end;

    local procedure VerifyGLEntryAmountNearlyEqual(var GLEntry: Record "G/L Entry"; TaxAccountNo: Code[20]; ExpectedAmount: Decimal)
    begin
        GLEntry.SetRange("G/L Account No.", TaxAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(ExpectedAmount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), GLEntryAmountErr);
    end;

    local procedure VerifyItemChargeIsPosted(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetFilter("Item Charge No.", '<>%1', '');
        Assert.IsFalse(ValueEntry.IsEmpty, StrSubstNo(ItemChargeVENotPostedErr, ItemNo));
    end;

    local procedure VerifyGLEntryCustomAmount(DocNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.FindFirst();
        Assert.AreEqual(GLEntry.Amount, -1248.75, TaxAmountErr);
    end;

    local procedure VerifyCLEAmount(DocumentNo: Code[20]; CustomerNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyVLEAmount(DocumentNo: Code[20]; VendorNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        VendorLedgerEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyGLEntriesCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        DummyGLEntry: Record "G/L Entry";
    begin
        DummyGLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(DummyGLEntry, ExpectedCount);
    end;

    local procedure VerifyGLEntries_TFS216424(VendorNo: Code[20]; DocumentNo: Code[20]; GLAccountNo: Code[20]; TaxJurisdictionCode: array[4] of Code[10])
    begin
        VerifyGLEntriesCount(DocumentNo, 8);
        VerifyGLEntryTaxAmount(DocumentNo, GLAccountNo, 138.99);
        VerifyGLEntryTaxAmount(DocumentNo, GetVendorPayablesAccount(VendorNo), -133.72);
        VerifyGLEntryTaxAmount(DocumentNo, GetJurTaxAccPurchases(TaxJurisdictionCode[1]), 3.34);
        VerifyGLEntryTaxAmount(DocumentNo, GetJurTaxAccPurchases(TaxJurisdictionCode[3]), 8.77);
        VerifyGLEntryTaxAmount(DocumentNo, GetJurTaxAccReverse(TaxJurisdictionCode[1]), -3.34);
        VerifyGLEntryTaxAmount(DocumentNo, GetJurTaxAccReverse(TaxJurisdictionCode[2]), -3.34);
        VerifyGLEntryTaxAmount(DocumentNo, GetJurTaxAccReverse(TaxJurisdictionCode[3]), -8.77);
        VerifyGLEntryTaxAmount(DocumentNo, GetJurTaxAccReverse(TaxJurisdictionCode[4]), -1.93);
    end;

    local procedure VerifyGLEntriesWithUseTax(DocumentNo: Code[20]; VendorNo: Code[20]; TaxJurisdictionCode: Code[10]; TaxAmount: Decimal; PurchAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyGLEntryAmountNearlyEqual(GLEntry, GetJurTaxAccReverse(TaxJurisdictionCode), -TaxAmount);
        VerifyGLEntryAmountNearlyEqual(GLEntry, GetVendorPayablesAccount(VendorNo), -PurchAmount);
        GLEntry.SetRange("G/L Account No.");
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::Purchase);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          TaxAmount + PurchAmount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), GLEntryAmountErr);
    end;

    local procedure VerifyPurchaseTotalTaxBeforeAfterRelease(PurchaseHeader: Record "Purchase Header"; ExpectedValue: Decimal)
    begin
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedValue, PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount, '');

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedValue, PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount, '');
    end;

    local procedure VerifySalesTotalTaxBeforeAfterRelease(SalesHeader: Record "Sales Header"; ExpectedValue: Decimal)
    begin
        SalesHeader.TestField(Status, SalesHeader.Status::Open);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedValue, SalesHeader."Amount Including VAT" - SalesHeader.Amount, '');

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedValue, SalesHeader."Amount Including VAT" - SalesHeader.Amount, '');
    end;

    local procedure VerifySalesLinesAmounts(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; Amount: array[2] of Decimal; AmountIncludingVAT: array[2] of Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.FindFirst();
        SalesLine.TestField(Amount, Amount[1]);
        SalesLine.TestField("Amount Including VAT", AmountIncludingVAT[1]);
        SalesLine.FindLast();
        SalesLine.TestField(Amount, Amount[2]);
        SalesLine.TestField("Amount Including VAT", AmountIncludingVAT[2]);
    end;

    local procedure VerifyPurchaseLinesAmounts(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; Amount: array[2] of Decimal; AmountIncludingVAT: array[2] of Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Amount, Amount[1]);
        PurchaseLine.TestField("Amount Including VAT", AmountIncludingVAT[1]);
        PurchaseLine.FindLast();
        PurchaseLine.TestField(Amount, Amount[2]);
        PurchaseLine.TestField("Amount Including VAT", AmountIncludingVAT[2]);
    end;

    local procedure GetActualAmounts(var GLEntry: Record "G/L Entry"; var ActualAmount: array[4] of Decimal; GLAccountArray: array[4] of Code[20])
    var
        I: Integer;
    begin
        for I := 1 to ArrayLen(GLAccountArray) do begin
            GLEntry.SetRange("G/L Account No.", GLAccountArray[I]);
            GLEntry.FindFirst();
            ActualAmount[I] := GLEntry.Amount;
        end;
    end;

    local procedure GetExpectedAmounts(var ExpectedAmountArray: array[4] of Decimal; Amount: Decimal; SalesTaxAmount: Decimal; CurrencyFactor: Decimal; PurchaseLineCount: Integer; UseTaxLineNo: Integer)
    var
        AmountLCY: Decimal;
        SalesTaxAmountLCY: Decimal;
        I: Integer;
    begin
        AmountLCY := Amount / CurrencyFactor;
        SalesTaxAmountLCY := SalesTaxAmount / CurrencyFactor;
        for I := 1 to PurchaseLineCount do begin
            ExpectedAmountArray[1] += AmountLCY;
            ExpectedAmountArray[2] += -AmountLCY;
            if DoesLineUseTax(UseTaxLineNo, I) then begin
                ExpectedAmountArray[1] += SalesTaxAmountLCY;
                ExpectedAmountArray[4] += -SalesTaxAmountLCY;
            end else begin
                ExpectedAmountArray[2] += -SalesTaxAmountLCY;
                ExpectedAmountArray[3] += SalesTaxAmountLCY;
            end;
        end;
        for I := 1 to ArrayLen(ExpectedAmountArray) do
            ExpectedAmountArray[I] := Round(ExpectedAmountArray[I]);
    end;

    local procedure GetExpectedAmountsProvTax(var ExpectedAmountArray: array[4] of Decimal; Amount: Decimal; SalesTaxAmount: Decimal; ProvTaxAmount: Decimal; CurrencyFactor: Decimal)
    var
        AmountLCY: Decimal;
        SalesTaxAmountLCY: Decimal;
        ProvTaxAmountLCY: Decimal;
        I: Integer;
    begin
        AmountLCY := Amount / CurrencyFactor;
        SalesTaxAmountLCY := SalesTaxAmount / CurrencyFactor;
        ProvTaxAmountLCY := ProvTaxAmount / CurrencyFactor;
        ExpectedAmountArray[1] := AmountLCY;
        ExpectedAmountArray[2] := -AmountLCY;
        ExpectedAmountArray[1] += ProvTaxAmountLCY;
        ExpectedAmountArray[4] := -ProvTaxAmountLCY;
        ExpectedAmountArray[2] += -SalesTaxAmountLCY;
        ExpectedAmountArray[3] := SalesTaxAmountLCY;

        for I := 1 to ArrayLen(ExpectedAmountArray) do
            ExpectedAmountArray[I] := Round(ExpectedAmountArray[I]);
    end;

    local procedure CreateFAJournalLine(var FAJournalLine: Record "FA Journal Line"; FAJournalBatch: Record "FA Journal Batch"; FAPostingType: Enum "FA Journal Line FA Posting Type"; FANo: Code[20]; DepreciationBookCode: Code[10]; Amount: Decimal)
    begin
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document Type", FAJournalLine."Document Type"::" ");
        FAJournalLine.Validate("Document No.", FAJournalLine."Journal Batch Name" + Format(FAJournalLine."Line No."));
        FAJournalLine.Validate("Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Date", WorkDate());
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, Amount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        PurchaseOrderStats.NoOfVATLines_Invoice.DrillDown();  // Opens SalesTaxLinesSubformDynHandler.
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        PurchaseOrderStats.NoOfVATLines_Invoice.DrillDown();  // Opens SalesTaxLinesSubformDynHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxLinesSubformDynHandler(var SalesTaxLinesSubformDyn: TestPage "Sales Tax Lines Subform Dyn")
    begin
        SalesTaxLinesSubformDyn."Tax Amount".SetValue(0);  // Tax Amount 0 is required on Sales TAx Line Subform Dyn page.
        SalesTaxLinesSubformDyn.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch.SuggestItemChargeAssignment.Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesDocumentTest."Sales Header".SetFilter("No.", No);
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseDocumentTest."Purchase Header".SetFilter("No.", No);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceDocumentTestRequestPageHandler(var ServiceDocumentTest: TestRequestPage "Service Document - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceDocumentTest."Service Header".SetFilter("No.", No);
        ServiceDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderRequestPageHandler(var ServiceOrder: TestRequestPage "Service Order")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceOrder."Service Header".SetFilter("No.", No);
        ServiceOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceQuoteRequestPageHandler(var ServiceQuote: TestRequestPage "Service Quote")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceQuote."Service Header".SetFilter("No.", No);
        ServiceQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsTestPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesOrderStats.TaxAmount.AssertEquals(TaxAmount);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatsTestPageHandler(var SalesStats: TestPage "Sales Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesStats.TaxAmount.AssertEquals(TaxAmount);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsTestPageHandlerNM(var SalesOrderStats: TestPage "Sales Order Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesOrderStats.TaxAmount.AssertEquals(TaxAmount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatsTestNonModalPageHandler(var SalesStats: TestPage "Sales Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesStats.TaxAmount.AssertEquals(TaxAmount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsTestPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        PurchaseOrderStats.TaxAmount.AssertEquals(TaxAmount);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatsTestPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        PurchaseOrderStats.TaxAmount.AssertEquals(TaxAmount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatsTestPageHandler(var PurchaseStats: TestPage "Purchase Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        PurchaseStats.TaxAmount.AssertEquals(TaxAmount);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatsTestHandler(var PurchaseStats: TestPage "Purchase Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        PurchaseStats.TaxAmount.AssertEquals(TaxAmount);
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsTestPageHandler(var ServiceOrderStats: TestPage "Service Order Stats.")
    var
        Currency: Record Currency;
        CurrencyCode: Variant;
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        LibraryVariableStorage.Dequeue(TaxAmount);
        Currency.Get(CurrencyCode);
        Assert.AreNearlyEqual(
          TaxAmount, ServiceOrderStats.TaxAmount.AsDecimal(), Currency."Amount Rounding Precision", TaxAmountMustMatchErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatsTestPageHandler(var ServiceStats: TestPage "Service Stats.")
    var
        Currency: Record Currency;
        CurrencyCode: Variant;
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        LibraryVariableStorage.Dequeue(TaxAmount);
        Currency.Get(CurrencyCode);
        Assert.AreNearlyEqual(TaxAmount, ServiceStats.VATAmount.AsDecimal(), Currency."Amount Rounding Precision", TaxAmountMustMatchErr);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsTestPageHandlerNM(var ServiceOrderStats: TestPage "Service Order Stats.")
    var
        Currency: Record Currency;
        CurrencyCode: Variant;
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        LibraryVariableStorage.Dequeue(TaxAmount);
        Currency.Get(CurrencyCode);
        Assert.AreNearlyEqual(TaxAmount, ServiceOrderStats.TaxAmount.AsDecimal(), Currency."Amount Rounding Precision", TaxAmountMustMatchErr);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatsTestPageHandlerNM(var ServiceStats: TestPage "Service Stats.")
    var
        Currency: Record Currency;
        CurrencyCode: Variant;
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        LibraryVariableStorage.Dequeue(TaxAmount);
        Currency.Get(CurrencyCode);
        Assert.AreNearlyEqual(TaxAmount, ServiceStats.VATAmount.AsDecimal(), Currency."Amount Rounding Precision", TaxAmountMustMatchErr);
    end;
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Stats.")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown(); // calls SalesTaxLinesSubformDynPageHandler
        SalesOrderStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Stats.")
    begin
        SalesOrderStatistics.NoOfVATLines_Invoicing.DrillDown(); // calls SalesTaxLinesSubformDynPageHandler
        SalesOrderStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesTaxLinesSubformDynPageHandler(var SalesTaxLinesSubformDyn: TestPage "Sales Tax Lines Subform Dyn")
    var
        NewTaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewTaxAmount);
        SalesTaxLinesSubformDyn."Tax Amount".SetValue(NewTaxAmount);
        SalesTaxLinesSubformDyn.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsPageHandler(var PurchOrderStatistics: TestPage "Purchase Order Stats.")
    begin
        PurchOrderStatistics.NoOfVATLines_Invoice.DrillDown(); // calls SalesTaxLinesSubformDynPageHandler
        PurchOrderStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchOrderStatistics: TestPage "Purchase Order Stats.")
    begin
        PurchOrderStatistics.NoOfVATLines_Invoice.DrillDown(); // calls SalesTaxLinesSubformDynPageHandler
        PurchOrderStatistics.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderListPageHandler(var SalesOrderList: TestPage "Sales Order List")
    begin
        SalesOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderListPageHandler(var PurchaseOrderList: TestPage "Purchase Order List")
    begin
        PurchaseOrderList."No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardSalesOrderConf_RPH(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StandardSalesOrderConf.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrder_RPH(var SalesOrder: TestRequestPage "Sales Order")
    begin
        SalesOrder.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}
