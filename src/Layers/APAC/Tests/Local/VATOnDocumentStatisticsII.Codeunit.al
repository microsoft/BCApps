codeunit 141080 "VAT On Document Statistics II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure BlnktPurchOrderStatsWithAddReportingCurrSetup()
    var
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [Purchase] [Blanket Order]
        // [SCENARIO] values on Statistics page for Blanket Purchase Order with Additional Reporting Currency setup.

        // [GIVEN] Run Additional Reporting Currency job and Create Blanket Purchase Order.
        Initialize();
        RunAddReportingCurrAndCreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Blanket Order");
        EnqueueValuesForHandler(PurchaseLine."Amount Including VAT", PurchaseLine.Amount * PurchaseLine."VAT %" / 100);  // Enqueue values for PurchaseOrderStatisticsModalPageHandler.
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");

        // Exercise.
        BlanketPurchaseOrder.Statistics.Invoke();  // Opens PurchaseOrderStatisticsModalPageHandler.

        // Verify: Verification is done in PurchaseOrderStatisticsModalPageHandler.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlnktPurchaseOrderStatsWithAddReportingCurrSetup()
    var
        PurchaseLine: Record "Purchase Line";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // [FEATURE] [Purchase] [Blanket Order]
        // [SCENARIO] values on Statistics page for Blanket Purchase Order with Additional Reporting Currency setup.

        // [GIVEN] Run Additional Reporting Currency job and Create Blanket Purchase Order.
        Initialize();
        RunAddReportingCurrAndCreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Blanket Order");
        EnqueueValuesForHandler(PurchaseLine."Amount Including VAT", PurchaseLine.Amount * PurchaseLine."VAT %" / 100);  // Enqueue values for PurchaseOrderStatisticsPageHandler.
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.FILTER.SetFilter("No.", PurchaseLine."Document No.");

        // Exercise.
        BlanketPurchaseOrder.PurchaseOrderStatistics.Invoke();  // Opens PurchaseOrderStatisticsPageHandler.

        // Verify: Verification is done in PurchaseOrderStatisticsPageHandler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure BlnktSalesOrderStatsWithAddReportingCurrSetup()
    var
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [Sales] [Blanket Order]
        // [SCENARIO] values on Statistics page for Blanket Sales Order with Additional Reporting Currency setup.

        // [GIVEN] Run Additional Reporting Currency job and Create Blanket Sales Order.
        Initialize();
        RunAddReportingCurrAndCreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order");
        EnqueueValuesForHandler(SalesLine."Amount Including VAT", SalesLine.Amount * SalesLine."VAT %" / 100);  // Enqueue values for SalesOrderStatisticsModalPageHandler.
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", SalesLine."Document No.");

        // Exercise.
        BlanketSalesOrder.Statistics.Invoke();  // Opens SalesOrderStatisticsModalPageHandler.

        // Verify: Verification is done in SalesOrderStatisticsModalPageHandler.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure BlnktSalesOrderStatsWithAddReportingCurrSetupNM()
    var
        SalesLine: Record "Sales Line";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [Sales] [Blanket Order]
        // [SCENARIO] values on Statistics page for Blanket Sales Order with Additional Reporting Currency setup.

        // [GIVEN] Run Additional Reporting Currency job and Create Blanket Sales Order.
        Initialize();
        RunAddReportingCurrAndCreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order");
        EnqueueValuesForHandler(SalesLine."Amount Including VAT", SalesLine.Amount * SalesLine."VAT %" / 100);  // Enqueue values for SalesOrderStatisticsPageHandler.
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", SalesLine."Document No.");

        // Exercise.
        BlanketSalesOrder.SalesOrderStatistics.Invoke();  // Opens SalesOrderStatisticsPageHandler.

        // Verify: Verification is done in SalesOrderStatisticsPageHandler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteStatisticsWithAddReportingCurrSetup()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Purchase] [Quote]
        // [SCENARIO] values on Statistics page for Purchase Quote with Additional Reporting Currency setup.

        // [GIVEN] Run Additional Reporting Currency job and Create Purchase Quote.
        Initialize();
        RunAddReportingCurrAndCreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Quote);
        EnqueueValuesForHandler(PurchaseLine."Amount Including VAT", PurchaseLine.Amount * PurchaseLine."VAT %" / 100);  // Enqueue values for PurchaseStatisticsModalPageHandler.
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseLine."Document No.");

        // Exercise.
        PurchaseQuote.Statistics.Invoke();  // Opens PurchaseStatisticsModalPageHandler.

        // Verify: Verification is done in PurchaseStatisticsModalPageHandler.
    end;
#endif

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchQuotePageStatisticsWithAddReportingCurrSetup()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [Purchase] [Quote]
        // [SCENARIO] values on Statistics page for Purchase Quote with Additional Reporting Currency setup.

        // [GIVEN] Run Additional Reporting Currency job and Create Purchase Quote.
        Initialize();
        RunAddReportingCurrAndCreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Quote);
        EnqueueValuesForHandler(PurchaseLine."Amount Including VAT", PurchaseLine.Amount * PurchaseLine."VAT %" / 100);  // Enqueue values for PurchaseStatisticsPageHandler.
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseLine."Document No.");

        // Exercise.
        PurchaseQuote.PurchaseStatistics.Invoke();  // Opens PurchaseStatisticsPageHandler.

        // Verify: Verification is done in PurchaseStatisticsPageHandler.
    end;


    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteStatisticsWithAddReportingCurrSetup()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO] values on Statistics page for Sales Quote with Additional Reporting Currency setup.

        // [GIVEN] Run Additional Reporting Currency job and Create Sales Quote.
        Initialize();
        RunAddReportingCurrAndCreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote);
        EnqueueValuesForHandler(SalesLine."Amount Including VAT", SalesLine.Amount * SalesLine."VAT %" / 100);  // Enqueue values for SalesStatisticsModalPageHandler.
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", SalesLine."Document No.");

        // Exercise.
        SalesQuote.Statistics.Invoke();  // Opens SalesStatisticsModalPageHandler.

        // Verify: Verification is done in SalesStatisticsModalPageHandler.
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [Test]
    [HandlerFunctions('StatisticsVerifyUpdateHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsGSTAmountRounding()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO] VAT Amount is correct when it is changed in Invoice Statistics Page and recalculated after statistics page been reopened.
        // [SCENARIO] Certain amounts cause a rounding issue

        // Setup
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandIntInRange(5, 10) * LibraryERM.GetAmountRoundingPrecision());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, 10);
        LibrarySales.SetAllowVATDifference(true);

        // Excercise
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLineWithCustomAmounts(SalesLine, SalesHeader, VATPostingSetup, 1, 220, 0);
        CreateSalesLineWithCustomAmounts(SalesLine, SalesHeader, VATPostingSetup, 1, 119.55, 0);

        // [THEN] Verify VAT Amount field on VAT Amount Lines page.
        CalcSalesLinesAmounts(SalesHeader, VATAmount, TotalAmount);
        VATAmount -= LibraryERM.GetAmountRoundingPrecision();

        // FALSE means update VAT Amount to get some VAT Difference
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenSalesInvoiceStatistics(SalesHeader."No.");

        // TRUE means verify VAT Amount after Statistic page reopened.
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenSalesInvoiceStatistics(SalesHeader."No.");
    end;
#endif

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteSalesStatisticsWithAddReportingCurrSetup()
    var
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO] values on Statistics page for Sales Quote with Additional Reporting Currency setup.

        // [GIVEN] Run Additional Reporting Currency job and Create Sales Quote.
        Initialize();
        RunAddReportingCurrAndCreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote);
        EnqueueValuesForHandler(SalesLine."Amount Including VAT", SalesLine.Amount * SalesLine."VAT %" / 100);  // Enqueue values for SalesStatisticsPageHandler.
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", SalesLine."Document No.");

        // Exercise.
        SalesQuote.SalesStatistics.Invoke();  // Opens SalesStatisticsPageHandler.

        // Verify: Verification is done in SalesStatisticsPageHandler.
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsVerifyUpdateHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceSalesStatisticsGSTAmountRounding()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO] VAT Amount is correct when it is changed in Invoice Statistics Page and recalculated after statistics page been reopened.
        // [SCENARIO] Certain amounts cause a rounding issue

        // Setup
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandIntInRange(5, 10) * LibraryERM.GetAmountRoundingPrecision());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, 10);
        LibrarySales.SetAllowVATDifference(true);

        // Excercise
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLineWithCustomAmounts(SalesLine, SalesHeader, VATPostingSetup, 1, 220, 0);
        CreateSalesLineWithCustomAmounts(SalesLine, SalesHeader, VATPostingSetup, 1, 119.55, 0);

        // [THEN] Verify VAT Amount field on VAT Amount Lines page.
        CalcSalesLinesAmounts(SalesHeader, VATAmount, TotalAmount);
        VATAmount -= LibraryERM.GetAmountRoundingPrecision();

        // FALSE means update VAT Amount to get some VAT Difference
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenSalesInvoiceSalesStatistics(SalesHeader."No.");

        // TRUE means verify VAT Amount after Statistic page reopened.
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenSalesInvoiceSalesStatistics(SalesHeader."No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsVerifyUpdateHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsGSTAmountRounding()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO] VAT Amount is correct when it is changed in Invoice Statistics Page and recalculated after statistics page been reopened.
        // [SCENARIO] Certain amounts cause a rounding issue

        // Setup.
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandIntInRange(5, 10) * LibraryERM.GetAmountRoundingPrecision());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, 10);
        LibraryPurchase.SetAllowVATDifference(true);

        // Excercise
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, 220, 0);
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, 119.55, 0);

        // Verify: Verify VAT Amount field on VAT Amount Lines page.
        CalcPurchaseLineAmounts(PurchaseHeader, VATAmount, TotalAmount);
        VATAmount -= LibraryERM.GetAmountRoundingPrecision();

        // FALSE means update VAT Amount to get some VAT Difference
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenPurchaseInvoiceStatistics(PurchaseHeader."No.");

        // TRUE means verify VAT Amount after Statistic page reopened.
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenPurchaseInvoiceStatistics(PurchaseHeader."No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchStatisticsVerifyUpdateHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceStatisticsGSTAmountRounding()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO] VAT Amount is correct when it is changed in Invoice Statistics Page and recalculated after statistics page been reopened.
        // [SCENARIO] Certain amounts cause a rounding issue

        // Setup.
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandIntInRange(5, 10) * LibraryERM.GetAmountRoundingPrecision());
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, 10);
        LibraryPurchase.SetAllowVATDifference(true);

        // Excercise
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, 220, 0);
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, 119.55, 0);

        // Verify: Verify VAT Amount field on VAT Amount Lines page.
        CalcPurchaseLineAmounts(PurchaseHeader, VATAmount, TotalAmount);
        VATAmount -= LibraryERM.GetAmountRoundingPrecision();

        // FALSE means update VAT Amount to get some VAT Difference
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenPurchInvoiceStatistics(PurchaseHeader."No.");

        // TRUE means verify VAT Amount after Statistic page reopened.
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenPurchInvoiceStatistics(PurchaseHeader."No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsVerifyUpdateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVatAmountShouldNotChangeWhenChangingPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        TotalAmount: Decimal;
        VatDifference: Decimal;
    begin
        // [SCENARIO 493308] VAT Amount changes when change the posting date causing VAT amount difference

        // [GIVEN] Setup
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandIntInRange(1, 1));
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, 10);
        LibraryPurchase.SetAllowVATDifference(true);

        // [THEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, 220, 0);

        // [VERIFY] Verify: Verify VAT Amount field on VAT Amount Lines page.
        CalcPurchaseLineAmounts(PurchaseHeader, VATAmount, TotalAmount);
        VatDifference := LibraryRandom.RandDecInRange(0, 1, 2);
        VATAmount += VatDifference;

        // [THEN] FALSE means update VAT Amount to get some VAT Difference
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenPurchaseInvoiceStatistics(PurchaseHeader."No.");

        // [WHEN] Change posting date in purchase header to 02.01.2021
        PurchaseHeader.Validate("Posting Date", PurchaseHeader."Posting Date" + LibraryRandom.RandIntInRange(10, 20));// WorkDate() + 1);
        PurchaseHeader.Modify(true);

        // [VERIFY] Verify: Vat Difference not set to Zero on Purchase Line
        VerifyVatDifferenceOnPurchaseLine(PurchaseHeader."No.", VatDifference);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchStatisticsVerifyUpdateHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyVatAmtShouldNotChangeWhenChangingPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        TotalAmount: Decimal;
        VatDifference: Decimal;
    begin
        // [SCENARIO 493308] VAT Amount changes when change the posting date causing VAT amount difference

        // [GIVEN] Setup
        LibraryERM.SetMaxVATDifferenceAllowed(LibraryRandom.RandIntInRange(1, 1));
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, 10);
        LibraryPurchase.SetAllowVATDifference(true);

        // [THEN] Create Purchase Invoice
        LibraryPurchase.CreatePurchHeader(
            PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
            LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchaseLineWithCustomAmounts(PurchaseLine, PurchaseHeader, VATPostingSetup, 1, 220, 0);

        // [VERIFY] Verify: Verify VAT Amount field on VAT Amount Lines page.
        CalcPurchaseLineAmounts(PurchaseHeader, VATAmount, TotalAmount);
        VatDifference := LibraryRandom.RandDecInRange(0, 1, 2);
        VATAmount += VatDifference;

        // [THEN] FALSE means update VAT Amount to get some VAT Difference
        LibraryVariableStorage.Enqueue(TotalAmount);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(VATAmount);
        OpenPurchInvoiceStatistics(PurchaseHeader."No.");

        // [WHEN] Change posting date in purchase header to 02.01.2021
        PurchaseHeader.Validate("Posting Date", PurchaseHeader."Posting Date" + LibraryRandom.RandIntInRange(10, 20));// WorkDate() + 1);
        PurchaseHeader.Modify(true);

        // [VERIFY] Verify: Vat Difference not set to Zero on Purchase Line
        VerifyVatDifferenceOnPurchaseLine(PurchaseHeader."No.", VatDifference);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        Commit();
        IsInitialized := true;
    end;

    local procedure CreateCurrencyWithExchangeRate(GenPostingType: Enum "General Posting Type"): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Residual Gains Account", CreateGLAccount(GenPostingType));
        Currency.Validate("Residual Losses Account", CreateGLAccount(GenPostingType));
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGLAccount(GenPostingType: Enum "General Posting Type"): Code[20]
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(GLAccount."Gen. Posting Type"::Purchase),
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccount(GLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithCustomAmounts(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; UnitPrice: Decimal; DiscountPct: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", DiscountPct);
        SalesLine.Modify();
    end;

    local procedure CreatePurchaseLineWithCustomAmounts(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; Quantity: Decimal; DirectUnitCost: Decimal; LineDiscountPct: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase),
          Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Line Discount %", LineDiscountPct);
        PurchaseLine.Modify(true);
    end;

    local procedure CalcSalesLinesAmounts(SalesHeader: Record "Sales Header"; var VATAmount: Decimal; var TotalAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        VATAmount := 0;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                VATAmount += SalesLine."Line Amount" * SalesLine."VAT %" / 100;
            until SalesLine.Next() = 0;
        SalesLine.CalcSums(Amount);
        TotalAmount := SalesLine.Amount;
    end;

    local procedure CalcPurchaseLineAmounts(PurchaseHeader: Record "Purchase Header"; var VATAmount: Decimal; var TotalAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        VATAmount := 0;
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindSet() then
            repeat
                VATAmount += PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100;
            until PurchaseLine.Next() = 0;
        PurchaseLine.CalcSums(Amount);
        TotalAmount := PurchaseLine.Amount;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    local procedure OpenSalesInvoiceStatistics(DocumentNo: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", DocumentNo);
        SalesInvoice.Statistics.Invoke();
    end;
#endif
    local procedure OpenSalesInvoiceSalesStatistics(DocumentNo: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", DocumentNo);
        SalesInvoice.SalesStatistics.Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenPurchaseInvoiceStatistics(DocumentNo: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", DocumentNo);
        PurchaseInvoice.Statistics.Invoke();
    end;
#endif
    local procedure OpenPurchInvoiceStatistics(DocumentNo: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", DocumentNo);
        PurchaseInvoice.PurchaseStatistics.Invoke();
    end;

    local procedure EnqueueValuesForHandler(AmountInclVAT: Decimal; VATAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(AmountInclVAT);
        LibraryVariableStorage.Enqueue(VATAmount);
    end;

    local procedure RunAddReportingCurrAndCreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.RunAddnlReportingCurrency(
          CreateCurrencyWithExchangeRate(GLAccount."Gen. Posting Type"::Purchase), Format(LibraryRandom.RandInt(100)),
          CreateGLAccount(GLAccount."Gen. Posting Type"::Purchase));  // Random value used for Document No.
        CreatePurchaseDocument(PurchaseLine, DocumentType);
    end;

    local procedure RunAddReportingCurrAndCreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.RunAddnlReportingCurrency(
          CreateCurrencyWithExchangeRate(GLAccount."Gen. Posting Type"::Sale), Format(LibraryRandom.RandInt(100)),
          CreateGLAccount(GLAccount."Gen. Posting Type"::Sale));  // Random value used for Document No.
        CreateSalesDocument(SalesLine, DocumentType);
    end;

    local procedure VerifyStatisticsPage(TotalInclVATValue: Decimal; AmountInclVAT: Decimal; TotalInclVATCap: Text; VATAmountValue: Decimal; VATAmount: Decimal; VATAmountCap: Text; StatisticsCap: Text)
    begin
        Assert.AreNearlyEqual(
          TotalInclVATValue, AmountInclVAT, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(
            AmountErr, TotalInclVATCap, AmountInclVAT, StatisticsCap));
        Assert.AreNearlyEqual(
          VATAmountValue, VATAmount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(AmountErr, VATAmountCap, VATAmount, StatisticsCap));
    end;

    local procedure VerifyVatDifferenceOnPurchaseLine(DocumentNo: Code[20]; VatDifference: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, DocumentNo);
        Assert.IsTrue((PurchaseLine."VAT Difference" = VatDifference), '');
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsModalPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        AmountInclVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyStatisticsPage(
          PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal(), AmountInclVAT, PurchaseOrderStatistics.TotalInclVAT_General.Caption,
          PurchaseOrderStatistics."VATAmount[1]".AsDecimal(), VATAmount, PurchaseOrderStatistics."VATAmount[1]".Caption,
          PurchaseOrderStatistics.Caption);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        AmountInclVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyStatisticsPage(
          PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal(), AmountInclVAT, PurchaseOrderStatistics.TotalInclVAT_General.Caption,
          PurchaseOrderStatistics."VATAmount[1]".AsDecimal(), VATAmount, PurchaseOrderStatistics."VATAmount[1]".Caption,
          PurchaseOrderStatistics.Caption);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsModalPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        AmountInclVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyStatisticsPage(
          PurchaseStatistics.TotalAmount2.AsDecimal(), AmountInclVAT, PurchaseStatistics.TotalAmount2.Caption,
          PurchaseStatistics.VATAmount.AsDecimal(), VATAmount, PurchaseStatistics.VATAmount.Caption, PurchaseStatistics.Caption);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        AmountInclVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyStatisticsPage(
          PurchaseStatistics.TotalAmount2.AsDecimal(), AmountInclVAT, PurchaseStatistics.TotalAmount2.Caption,
          PurchaseStatistics.VATAmount.AsDecimal(), VATAmount, PurchaseStatistics.VATAmount.Caption, PurchaseStatistics.Caption);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        AmountInclVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyStatisticsPage(
          SalesOrderStatistics."TotalAmount2[1]".AsDecimal(), AmountInclVAT, SalesOrderStatistics."TotalAmount2[1]".Caption,
          SalesOrderStatistics.VATAmount.AsDecimal(), VATAmount, SalesOrderStatistics.VATAmount.Caption, SalesOrderStatistics.Caption);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        AmountInclVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyStatisticsPage(
          SalesStatistics.TotalAmount2.AsDecimal(), AmountInclVAT, SalesStatistics.TotalAmount2.Caption,
          SalesStatistics.VATAmount.AsDecimal(), VATAmount, SalesStatistics.VATAmount.Caption, SalesStatistics.Caption);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        AmountInclVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyStatisticsPage(
          SalesOrderStatistics."TotalAmount2[1]".AsDecimal(), AmountInclVAT, SalesOrderStatistics."TotalAmount2[1]".Caption,
          SalesOrderStatistics.VATAmount.AsDecimal(), VATAmount, SalesOrderStatistics.VATAmount.Caption, SalesOrderStatistics.Caption);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        AmountInclVAT: Variant;
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        LibraryVariableStorage.Dequeue(VATAmount);
        VerifyStatisticsPage(SalesStatistics.TotalAmount2.AsDecimal(), AmountInclVAT, SalesStatistics.TotalAmount2.Caption, SalesStatistics.VATAmount.AsDecimal(), VATAmount, SalesStatistics.VATAmount.Caption, SalesStatistics.Caption);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsVerifyUpdateHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        CheckVATAmount: Boolean;
    begin
        // Modal Page 161 Handler.
        PurchaseStatistics.TotalAmount1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        CheckVATAmount := LibraryVariableStorage.DequeueBoolean();
        if CheckVATAmount then
            PurchaseStatistics.VATAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal())
        else
            PurchaseStatistics.SubForm."VAT Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        PurchaseStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchStatisticsVerifyUpdateHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        CheckVATAmount: Boolean;
    begin
        // Modal Page 161 Handler.
        PurchaseStatistics.TotalAmount1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        CheckVATAmount := LibraryVariableStorage.DequeueBoolean();
        if CheckVATAmount then
            PurchaseStatistics.VATAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal())
        else
            PurchaseStatistics.SubForm."VAT Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        PurchaseStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StatisticsVerifyUpdateHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        CheckVATAmount: Boolean;
    begin
        // Modal Page 160 Handler.
        SalesStatistics.TotalAmount1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        CheckVATAmount := LibraryVariableStorage.DequeueBoolean();
        if CheckVATAmount then
            SalesStatistics.VATAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal())
        else
            SalesStatistics.SubForm."VAT Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        SalesStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsVerifyUpdateHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        CheckVATAmount: Boolean;
    begin
        // Modal Page 160 Handler.
        SalesStatistics.TotalAmount1.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        CheckVATAmount := LibraryVariableStorage.DequeueBoolean();
        if CheckVATAmount then
            SalesStatistics.VATAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal())
        else
            SalesStatistics.SubForm."VAT Amount".SetValue(LibraryVariableStorage.DequeueDecimal());
        SalesStatistics.OK().Invoke();
    end;
}

