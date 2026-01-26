codeunit 144002 "Unit GST Prepayment-Sales"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST] [Prepayment]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryAULocalization: Codeunit "Library - AU Localization";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        isInitialized: Boolean;
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        PrepaymentTotalAmount: Decimal;
        ValidationError: Label '%1 must be %2 in %3.';
        VATProdPostingGroupError: Label '%1 must be equal to ''%2''  in %3: %4=%5. Current value is ''%6''.', Comment = '%1=Field Caption;%2=Field Value;%3=Field Value;%4=Field Caption;%5=Field Value;%6=Field Value;';
        PrepaymentVATPctError: Label '%1 must be %2, the same as in the field %3 in %4 %5=''%6'',%7=''%8'',%9=''%10''', Comment = '%1=Field Caption;%2=Field Value;%3=Field Caption;%4=Table Caption;%5=Field Caption;%6=Field Value;%7=Field Caption;%8=Field Value;%9=Field Caption;%10=Field Value;';

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        LibraryAULocalization.EnableGSTSetup(true, true);

        isInitialized := true;
        Commit();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithLineDiscountExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with Line Discount and Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, LibraryRandom.RandInt(50), false);

        // [WHEN] Calculation of Line Discount,Open sales order statistics page and Calculate Global Variables for Verification.
        ModifyLineDiscountPercentOnSalesLine(SalesLine);
        CalculateSalesLinePrepaymentValuesExclVAT(SalesLine);
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandler.
        VerifySalesLinePrepaymentLineAmtExclVAT(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithLineDiscountInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with Line Discount and Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, LibraryRandom.RandInt(50), true);

        // [WHEN] Calculation of Line Discount,Open sales order statistics page and Calculate Global Variables for Verification.
        ModifyLineDiscountPercentOnSalesLine(SalesLine);
        CalculateSalesLinePrepaymentValuesInclVAT(SalesLine);
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandler.
        VerifySalesLinePrepaymentLineAmtInclVAT(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithInvoiceDiscountExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with Invoice Discount and Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, LibraryRandom.RandInt(50), false);
        CreateCustomerInvoiceDiscount(SalesHeader."Sell-to Customer No.");

        // [WHEN] Calculation of Invoice Discount,Open sales order statistics page and Calculate Global Variables for Verification.
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        CalculateSalesLinePrepaymentValuesExclVAT(SalesLine);
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandler.
        VerifySalesLinePrepaymentLineAmtExclVAT(SalesLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithInvoiceDiscountInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with Invoice Discount and Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, LibraryRandom.RandInt(50), true);
        CreateCustomerInvoiceDiscount(SalesHeader."Sell-to Customer No.");

        // [WHEN] Calculation of Invoice Discount,Open sales order statistics page and Calculate Global Variables for Verification.
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        CalculateSalesLinePrepaymentValuesInclVAT(SalesLine);
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandler.
        VerifySalesLinePrepaymentLineAmtInclVAT(SalesLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithLinePrepay100ExclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with 100% prepayment and Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, 100, false);

        // [WHEN] Open sales order statistics page and Calculate Global Variables for Verification.
        CalculateSalesLinePrepaymentValuesExclVAT(SalesLine);
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page throught SalesPrepmtFieldsStatisticsHandler.
        VerifySalesLinePrepaymentLineAmtExclVAT(SalesLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithLinePrepay100InclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line with 100% prepayment and Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, 100, true);

        // [WHEN] Open sales order statistics page and Calculate Global Variables for Verification.
        CalculateSalesLinePrepaymentValuesInclVAT(SalesLine);
        OpenSalesOrderStatistics(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandler.
        VerifySalesLinePrepaymentLineAmtInclVAT(SalesLine);
    end;
#endif
    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithLineDiscountExclVATNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with Line Discount and Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, LibraryRandom.RandInt(50), false);

        // [WHEN] Calculation of Line Discount,Open sales order statistics page and Calculate Global Variables for Verification.
        ModifyLineDiscountPercentOnSalesLine(SalesLine);
        CalculateSalesLinePrepaymentValuesExclVAT(SalesLine);
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandlerNM.
        VerifySalesLinePrepaymentLineAmtExclVAT(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithLineDiscountInclVATNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with Line Discount and Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, LibraryRandom.RandInt(50), true);

        // [WHEN] Calculation of Line Discount,Open sales order statistics page and Calculate Global Variables for Verification.
        ModifyLineDiscountPercentOnSalesLine(SalesLine);
        CalculateSalesLinePrepaymentValuesInclVAT(SalesLine);
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandlerNM.
        VerifySalesLinePrepaymentLineAmtInclVAT(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithInvoiceDiscountExclVATNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with Invoice Discount and Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, LibraryRandom.RandInt(50), false);
        CreateCustomerInvoiceDiscount(SalesHeader."Sell-to Customer No.");

        // [WHEN] Calculation of Invoice Discount,Open sales order statistics page and Calculate Global Variables for Verification.
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        CalculateSalesLinePrepaymentValuesExclVAT(SalesLine);
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandlerNM.
        VerifySalesLinePrepaymentLineAmtExclVAT(SalesLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithInvoiceDiscountInclVATNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with Invoice Discount and Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, LibraryRandom.RandInt(50), true);
        CreateCustomerInvoiceDiscount(SalesHeader."Sell-to Customer No.");

        // [WHEN] Calculation of Invoice Discount,Open sales order statistics page and Calculate Global Variables for Verification.
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        CalculateSalesLinePrepaymentValuesInclVAT(SalesLine);
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandlerNM.
        VerifySalesLinePrepaymentLineAmtInclVAT(SalesLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesSetup);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithLinePrepay100ExclVATNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line and Statistics with 100% prepayment and Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, 100, false);

        // [WHEN] Open sales order statistics page and Calculate Global Variables for Verification.
        CalculateSalesLinePrepaymentValuesExclVAT(SalesLine);
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page throught SalesPrepmtFieldsStatisticsHandlerNM.
        VerifySalesLinePrepaymentLineAmtExclVAT(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesPrepmtFieldsStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesPrepaymentAmtWithLinePrepay100InclVATNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Sales Line with 100% prepayment and Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Sales Order with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, GeneralPostingSetup, 100, true);

        // [WHEN] Open sales order statistics page and Calculate Global Variables for Verification.
        CalculateSalesLinePrepaymentValuesInclVAT(SalesLine);
        OpenSalesOrderStatisticsNM(SalesLine."Document No.");

        // [THEN] Prepayment Line Amount on Sales Line and Sales Order Statistics Page through SalesPrepmtFieldsStatisticsHandlerNM.
        VerifySalesLinePrepaymentLineAmtInclVAT(SalesLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentAmtWithLineDiscountExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line and Statistics with Line Discount Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, LibraryRandom.RandInt(50), false);

        // [WHEN] Calculation of Line Discount,Open Purchase order statistics page and Calculate Global Variables for Verification.
        ModifyLineDiscountPercentOnPurchaseLine(PurchaseLine);
        CalculatePurchaseLinePrepaymentValuesExclVAT(PurchaseLine);
        OpenPurchaseOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsHandler.
        VerifyPurchaseLinePrepaymentLineAmtExclVAT(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentAmountWithLineDiscountExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line and Statistics with Line Discount Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, LibraryRandom.RandInt(50), false);

        // [WHEN] Calculation of Line Discount,Open Purchase order statistics page and Calculate Global Variables for Verification.
        ModifyLineDiscountPercentOnPurchaseLine(PurchaseLine);
        CalculatePurchLinePrepaymentValuesExclVAT(PurchaseLine);
        OpenPurchOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsPageHandler.
        VerifyPurchaseLinePrepaymentLineAmtExclVAT(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentAmtWithLineDiscountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line and Statistics with Line Discount Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, LibraryRandom.RandInt(50), true);

        // [WHEN] Calculation of Line Discount,Open Purchase order statistics page and Calculate Global Variables for Verification.
        ModifyLineDiscountPercentOnPurchaseLine(PurchaseLine);
        CalculatePurchaseLinePrepaymentValuesInclVAT(PurchaseLine);
        OpenPurchaseOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsHandler.
        VerifyPurchaseLinePrepaymentLineAmtInclVAT(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentAmtWithLineDiscountIncludingVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line and Statistics with Line Discount Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, LibraryRandom.RandInt(50), true);

        // [WHEN] Calculation of Line Discount,Open Purchase order statistics page and Calculate Global Variables for Verification.
        ModifyLineDiscountPercentOnPurchaseLine(PurchaseLine);
        CalculatePurchLinePrepaymentValuesInclVAT(PurchaseLine);
        OpenPurchOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsPageHandler.
        VerifyPurchaseLinePrepaymentLineAmtInclVAT(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentAmtWithInvoiceDiscountExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line and Statistics with Invocie Discount Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, LibraryRandom.RandInt(50), false);
        CreateVendorInvoiceDiscount(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Calculation of Invoice Discount,Open Purchase order statistics page and Calculate Global Variables for Verification.
        PurchCalcDiscount.Run(PurchaseLine);
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        CalculatePurchaseLinePrepaymentValuesExclVAT(PurchaseLine);
        OpenPurchaseOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsHandler.
        VerifyPurchaseLinePrepaymentLineAmtExclVAT(PurchaseLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepaymentAmtWithInvoiceDiscountExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line and Statistics with Invocie Discount Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, LibraryRandom.RandInt(50), false);
        CreateVendorInvoiceDiscount(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Calculation of Invoice Discount,Open Purchase order statistics page and Calculate Global Variables for Verification.
        PurchCalcDiscount.Run(PurchaseLine);
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        CalculatePurchLinePrepaymentValuesExclVAT(PurchaseLine);
        OpenPurchOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsPageHandler.
        VerifyPurchaseLinePrepaymentLineAmtExclVAT(PurchaseLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentAmtWithInvoiceDiscountInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line and Statistics with Invocie Discount Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, LibraryRandom.RandInt(50), true);
        CreateVendorInvoiceDiscount(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Calculation of Invoice Discount,Open Purchase order statistics page and Calculate Global Variables for Verification.
        PurchCalcDiscount.Run(PurchaseLine);
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        CalculatePurchaseLinePrepaymentValuesInclVAT(PurchaseLine);
        OpenPurchaseOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsHandler.
        VerifyPurchaseLinePrepaymentLineAmtInclVAT(PurchaseLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentAmtWithInvoiceDiscInclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line and Statistics with Invocie Discount Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, LibraryRandom.RandInt(50), true);
        CreateVendorInvoiceDiscount(PurchaseHeader."Buy-from Vendor No.");

        // [WHEN] Calculation of Invoice Discount,Open Purchase order statistics page and Calculate Global Variables for Verification.
        PurchCalcDiscount.Run(PurchaseLine);
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        CalculatePurchLinePrepaymentValuesInclVAT(PurchaseLine);
        OpenPurchOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsPageHandler.
        VerifyPurchaseLinePrepaymentLineAmtInclVAT(PurchaseLine);
        LibraryNotificationMgt.RecallNotificationsForRecord(PurchSetup);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepaymentAmtWithLinePrepay100ExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line with 100% prepayment Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, 100, false);

        // [WHEN] Open Purchase order statistics page and Calculate Global Variables for Verification.
        CalculatePurchaseLinePrepaymentValuesExclVAT(PurchaseLine);
        OpenPurchaseOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsHandler.
        VerifyPurchaseLinePrepaymentLineAmtExclVAT(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepaymentAmountWithLinePrepay100ExclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line with 100% prepayment Price Excl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, 100, false);

        // [WHEN] Open Purchase order statistics page and Calculate Global Variables for Verification.
        CalculatePurchLinePrepaymentValuesExclVAT(PurchaseLine);
        OpenPurchOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsPageHandler.
        VerifyPurchaseLinePrepaymentLineAmtExclVAT(PurchaseLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepaymentAmtWithLinePrepay100InclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line with 100% prepayment Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, 100, true);

        // [WHEN] Open Purchase order statistics page and Calculate Global Variables for Verification.
        CalculatePurchaseLinePrepaymentValuesInclVAT(PurchaseLine);
        OpenPurchaseOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsHandler.
        VerifyPurchaseLinePrepaymentLineAmtInclVAT(PurchaseLine);
    end;
#endif

    [Test]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepaymentAmtWithLinePrepayment100InclVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        // [SCENARIO] Prepayment Amount on Purchase Line with 100% prepayment Price Incl. VAT.
        Initialize();

        // [GIVEN] Create Purchase Header with Random Prepayment %.
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, GeneralPostingSetup, 100, true);

        // [WHEN] Open Purchase order statistics page and Calculate Global Variables for Verification.
        CalculatePurchLinePrepaymentValuesInclVAT(PurchaseLine);
        OpenPurchOrderStatistics(PurchaseLine."Document No.");

        // [THEN] Prepayment Line Amount on Purchase Line and Purchase Order Statistics Page through PurchasePrepmtFieldsStatisticsPageHandler.
        VerifyPurchaseLinePrepaymentLineAmtInclVAT(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorWhenPurchLineVATPctGreaterThanPrepmtAccVATPct()
    var
        NonZeroVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] error comes when Purchase Prepayment Account has VAT Posting setup with zero percent VAT and VAT Setup on an purchase order line has VAT percentage greater than zero.

        Initialize();
        FindVATPostingGroupsWithDiffVATRate(NonZeroVATPostingSetup, ZeroVATPostingSetup);
        PurchaseLineVATPctDifferentFromPrepmtAccVATPct(NonZeroVATPostingSetup, ZeroVATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorWhenPurchLineVATPctLessThanPrepmtAccVATPct()
    var
        NonZeroVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] error comes when Purchase Prepayment Account has VAT Posting setup with VAT percent greater than zero and VAT Setup on an purchase order line has zero VAT percentage.

        Initialize();
        FindVATPostingGroupsWithDiffVATRate(NonZeroVATPostingSetup, ZeroVATPostingSetup);
        PurchaseLineVATPctDifferentFromPrepmtAccVATPct(ZeroVATPostingSetup, NonZeroVATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorWhenSalesLineVATPctGreaterThanPrepmtAccVATPct()
    var
        NonZeroVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] error comes when Sales Prepayment Account has VAT Posting setup with zero percent VAT and VAT Setup on an sales order line has VAT percentage greater than zero.

        Initialize();
        FindVATPostingGroupsWithDiffVATRate(NonZeroVATPostingSetup, ZeroVATPostingSetup);
        SalesLineVATPctDifferentFromPrepmtAccVATPct(NonZeroVATPostingSetup, ZeroVATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestErrorWhenSalesLineVATPctLessThanPrepmtAccVATPct()
    var
        NonZeroVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] error comes when Sales Prepayment Account has VAT Posting setup with VAT percent greater than zero and VAT Setup on an sales order line has zero VAT percentage.

        Initialize();
        FindVATPostingGroupsWithDiffVATRate(NonZeroVATPostingSetup, ZeroVATPostingSetup);
        SalesLineVATPctDifferentFromPrepmtAccVATPct(ZeroVATPostingSetup, NonZeroVATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPrepmtErrorWhenPurchLineVATPctGreaterThanPrepmtAccVATPct()
    var
        NonZeroVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] error comes while posting prepayment when Purchase Prepayment Account and purchase line has VAT Posting setup with zero percent VAT and then change Purchase line VAT Product Posting Group having VAT Percentage greater than zero.

        Initialize();
        FindVATPostingGroupsWithDiffVATRate(NonZeroVATPostingSetup, ZeroVATPostingSetup);
        PostPurchPrepmtWhenVATPctDifferentFromPrepmtVATPct(NonZeroVATPostingSetup, ZeroVATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPrepmtErrorWhenPurchLineVATPctLessThanPrepmtAccVATPct()
    var
        NonZeroVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] error comes while posting prepayment when Purchase Prepayment Account and purchase line has VAT Posting setup with zero percent VAT and then change Purchase line VAT Product Posting Group having VAT Percentage greater than zero.

        Initialize();
        FindVATPostingGroupsWithDiffVATRate(NonZeroVATPostingSetup, ZeroVATPostingSetup);
        PostPurchPrepmtWhenVATPctDifferentFromPrepmtVATPct(ZeroVATPostingSetup, NonZeroVATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPrepmtErrorWhenSalesLineVATPctGreaterThanPrepmtAccVATPct()
    var
        NonZeroVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] error comes while posting prepayment when Sales Prepayment Account and sales line has VAT Posting setup with zero percent VAT and then change Sales line VAT Product Posting Group having VAT Percentage greater than zero.

        Initialize();
        FindVATPostingGroupsWithDiffVATRate(NonZeroVATPostingSetup, ZeroVATPostingSetup);
        PostSalesPrepmtWhenVATPctDifferentFromPrepmtVATPct(NonZeroVATPostingSetup, ZeroVATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPrepmtErrorWhenSalesLineVATPctLessThanPrepmtAccVATPct()
    var
        NonZeroVATPostingSetup: Record "VAT Posting Setup";
        ZeroVATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO] error comes while posting prepayment when Sales Prepayment Account and Sales line has VAT Posting setup with zero percent VAT and then change Sales line VAT Product Posting Group having VAT Percentage greater than zero.

        Initialize();
        FindVATPostingGroupsWithDiffVATRate(NonZeroVATPostingSetup, ZeroVATPostingSetup);
        PostSalesPrepmtWhenVATPctDifferentFromPrepmtVATPct(ZeroVATPostingSetup, NonZeroVATPostingSetup);
    end;

    local procedure CalculateSalesLinePrepaymentValuesExclVAT(SalesLine: Record "Sales Line")
    begin
        // Assign global variable for page handler.
        PrepaymentAmount := SalesLine."Line Amount" * SalesLine."Prepayment %" / 100;
        PrepaymentAmount := Round(PrepaymentAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentVATAmount := SalesLine.Amount * SalesLine."Prepayment VAT %" / 100;
        PrepaymentVATAmount := Round(PrepaymentVATAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentTotalAmount := PrepaymentVATAmount + PrepaymentAmount;
    end;

    local procedure CalculateSalesLinePrepaymentValuesInclVAT(SalesLine: Record "Sales Line")
    begin
        // Assign global variable for page handler.
        PrepaymentVATAmount := SalesLine.Amount * SalesLine."Prepayment VAT %" / 100;
        PrepaymentVATAmount := Round(PrepaymentVATAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentTotalAmount := SalesLine.Amount * SalesLine."Prepayment %" / 100;
        PrepaymentTotalAmount := Round(PrepaymentTotalAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentAmount := PrepaymentVATAmount + PrepaymentTotalAmount;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsHandler')]
    local procedure CalculatePurchaseLinePrepaymentValuesExclVAT(PurchaseLine: Record "Purchase Line")
    begin
        // Assign global variable for page handler.
        PrepaymentAmount := PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100;
        PrepaymentAmount := Round(PrepaymentAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentVATAmount := PurchaseLine.Amount * PurchaseLine."Prepayment VAT %" / 100;
        PrepaymentVATAmount := Round(PrepaymentVATAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentTotalAmount := PrepaymentVATAmount + PrepaymentAmount;
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [HandlerFunctions('PurchasePrepmtFieldsStatisticsHandler')]
    local procedure CalculatePurchaseLinePrepaymentValuesInclVAT(PurchaseLine: Record "Purchase Line")
    begin
        // Assign global variable for page handler.
        PrepaymentVATAmount := PurchaseLine.Amount * PurchaseLine."Prepayment VAT %" / 100;
        PrepaymentVATAmount := Round(PrepaymentVATAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentTotalAmount := PurchaseLine.Amount * PurchaseLine."Prepayment %" / 100;
        PrepaymentTotalAmount := Round(PrepaymentTotalAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentAmount := PrepaymentVATAmount + PrepaymentTotalAmount;
    end;
#endif

    [HandlerFunctions('PurchasePrepmtFieldsStatisticsPageHandler')]
    local procedure CalculatePurchLinePrepaymentValuesExclVAT(PurchaseLine: Record "Purchase Line")
    begin
        // Assign global variable for page handler.
        PrepaymentAmount := PurchaseLine."Line Amount" * PurchaseLine."Prepayment %" / 100;
        PrepaymentAmount := Round(PrepaymentAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentVATAmount := PurchaseLine.Amount * PurchaseLine."Prepayment VAT %" / 100;
        PrepaymentVATAmount := Round(PrepaymentVATAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentTotalAmount := PrepaymentVATAmount + PrepaymentAmount;
    end;

    [HandlerFunctions('PurchasePrepmtFieldsStatisticsPageHandler')]
    local procedure CalculatePurchLinePrepaymentValuesInclVAT(PurchaseLine: Record "Purchase Line")
    begin
        // Assign global variable for page handler.
        PrepaymentVATAmount := PurchaseLine.Amount * PurchaseLine."Prepayment VAT %" / 100;
        PrepaymentVATAmount := Round(PrepaymentVATAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentTotalAmount := PurchaseLine.Amount * PurchaseLine."Prepayment %" / 100;
        PrepaymentTotalAmount := Round(PrepaymentTotalAmount, LibraryERM.GetAmountRoundingPrecision());
        PrepaymentAmount := PrepaymentVATAmount + PrepaymentTotalAmount;
    end;

    local procedure ModifyLineDiscountPercentOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
    end;

    local procedure ModifyLineDiscountPercentOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GeneralPostingSetup: Record "General Posting Setup"; PrepaymentPercent: Decimal; IncludingVAT: Boolean)
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GeneralPostingSetup."Gen. Bus. Posting Group"));
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Validate("Prices Including VAT", IncludingVAT);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"),
          LibraryRandom.RandInt(10) * 2);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; GeneralPostingSetup: Record "General Posting Setup"; PrepaymentPercent: Decimal; IncludingVAT: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group"));
        PurchaseHeader.Validate("Prepayment %", PrepaymentPercent);
        PurchaseHeader.Validate("Prices Including VAT", IncludingVAT);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"),
          LibraryRandom.RandInt(20) * 2); // Qty to let at least 2 partial postings
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAccount(GenProdPostingGroup: Code[20]; Description: Code[30]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate(Name, Description); // add description for readability of the results
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateCustomer(GenBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.ABN := '53004084612'; // Assignment with Valid ABN No. done to bypass the confirm handler message.
        Vendor.Validate(Registered, true);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithVAT(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithVAT(VATProdPostGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroup."Def. VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group"; // bypassing triggers to avoid UI Confirm
        GenProdPostingGroup.Modify(true);
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        GenBusPostingGroup."Def. VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group"; // bypassing triggers to avoid UI Confirm
        GenBusPostingGroup.Modify(true);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup.Code, GenProdPostingGroup.Code);
        GeneralPostingSetup.Validate(
          "Sales Account", CreateAccount(GenProdPostingGroup.Code, GeneralPostingSetup.FieldCaption("Sales Account")));
        GeneralPostingSetup.Validate(
          "Sales Prepayments Account",
          CreateAccount(GenProdPostingGroup.Code, GeneralPostingSetup.FieldCaption("Sales Prepayments Account")));
        GeneralPostingSetup.Validate(
          "Purch. Account", CreateAccount(GenProdPostingGroup.Code, GeneralPostingSetup.FieldCaption("Purch. Account")));
        GeneralPostingSetup.Validate(
          "Purch. Prepayments Account",
          CreateAccount(GenProdPostingGroup.Code, GeneralPostingSetup.FieldCaption("Purch. Prepayments Account")));
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateCustomerInvoiceDiscount(CustomerNo: Code[20])
    var
        CustomerInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustomerInvoiceDisc, CustomerNo, '', 0); // Set Zero for Minimum Amount.
        CustomerInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        CustomerInvoiceDisc.Modify(true);
    end;

    local procedure CreateVendorInvoiceDiscount(VendorNo: Code[20])
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0); // Set Zero for Minimum Amount.
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateCustomerWithVAT(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreatePurchOrder(var PurchaseLine: Record "Purchase Line"; BuyFromVendorNo: Code[20]; No: Code[20]; PrePaymentPct: Decimal; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, BuyFromVendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Prepayment %", PrePaymentPct);
        UpdateVendorInvoiceNo(PurchaseHeader, PurchaseHeader."No.");
        CreatePurchLineWithRndQtyAndPrice(PurchaseLine, PurchaseHeader, No);
    end;

    local procedure CreatePurchLineWithRndQtyAndPrice(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", 100 + LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; SellToCustomerNo: Code[20]; No: Code[20]; PrePaymentPct: Decimal; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prepayment %", PrePaymentPct);
        SalesHeader.Modify(true);
        CreateSalesLineWithRndQtyAndPrice(SalesLine, SalesHeader, No);
    end;

    local procedure CreateSalesLineWithRndQtyAndPrice(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", 100 + LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
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

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>''''');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindVATPostingGroupsWithDiffVATRate(var VATPostingSetup: Record "VAT Posting Setup"; var ZeroVATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        FindVATPostingSetupForZeroVATPct(ZeroVATPostingSetup, VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure FindVATPostingSetupForZeroVATPct(var VATPostingSetup2: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    begin
        VATPostingSetup2.SetFilter("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup2.SetFilter("VAT Prod. Posting Group", '<>''''');
        VATPostingSetup2.SetRange("VAT Calculation Type", VATPostingSetup2."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup2.SetFilter("VAT %", '0');
        VATPostingSetup2.FindFirst();
    end;

    local procedure SetRandomPrepmtPctOnPurchHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Modify(true);
    end;

    local procedure SetRandomPrepmtPctOnSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
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

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenPurchaseOrderStatistics(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.Statistics.Invoke();
    end;
#endif

    local procedure OpenPurchOrderStatistics(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
    end;

    local procedure PurchaseLineVATPctDifferentFromPrepmtAccVATPct(VATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup2: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchPrepaymentsAccount: Code[20];
        OldPurchPrepaymentsAccount: Code[20];
    begin
        // Setup: Find General Posting Setup, Create Prepayment GL Account with VAT Product Posting Group received and update the prepayment account to General Posting Setup.
        PurchPrepmtSetup(GeneralPostingSetup, VATPostingSetup, PurchPrepaymentsAccount);

        // Exercise: Create Purchase Header with Prepayment %. Create Purchase line for GL Account with different VAT Product Posting Group than attached on Prepayment Account.
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithVAT(VATPostingSetup."VAT Bus. Posting Group"));
        SetRandomPrepmtPctOnPurchHeader(PurchaseHeader);
        asserterror LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
            CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(10, 2));

        // Verify: Verify expected error with the actual error.
        Assert.ExpectedError(
          StrSubstNo(
            VATProdPostingGroupError, VATPostingSetup.FieldCaption("VAT Prod. Posting Group"), VATPostingSetup2."VAT Prod. Posting Group",
            PurchaseLine.Type, PurchaseLine.FieldCaption("No."), PurchPrepaymentsAccount, VATPostingSetup."VAT Prod. Posting Group"));

        // Tear Down: Restore the original prepayment account on General Posting Setup.
        UpdatePurchasePrepmtAccount(
          OldPurchPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure PostPurchPrepmtWhenVATPctDifferentFromPrepmtVATPct(VATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup2: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        PurchPrepaymentsAccount: Code[20];
        OldPurchPrepaymentsAccount: Code[20];
    begin
        // Setup: Set Full GST on Prepayment as TRUE on GLSetup, Find General Posting Setup, Create Prepayment GL Account with VAT Product Posting Group received and update the prepayment account to General Posting Setup.
        PurchPrepmtSetup(GeneralPostingSetup, VATPostingSetup, PurchPrepaymentsAccount);

        // Exercise: Create Purchase Document with Prepayment %. Update Purchase Line with different VAT Product Posting Group than attached on Prepayment Account. Post Prepayment Invoice.
        CreatePurchOrder(
          PurchaseLine, CreateVendorWithVAT(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItemWithVAT(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2), '');
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        asserterror PurchasePostPrepayments.Invoice(PurchaseHeader);

        // Verify: Verify expected error with the actual error.
        Assert.ExpectedError(
          StrSubstNo(
            PrepaymentVATPctError, PurchaseLine.FieldCaption("Prepayment VAT %"), PurchaseLine."VAT %",
            PurchaseLine.FieldCaption("VAT %"), PurchaseLine.TableCaption(), PurchaseLine.FieldCaption("Document Type"),
            PurchaseLine."Document Type",
            PurchaseLine.FieldCaption("Document No."), PurchaseLine."Document No.", PurchaseLine.FieldCaption("Line No."),
            PurchaseLine."Line No."));

        // Tear Down: Restore the original prepayment account on General Ledger Setup and General Posting Setup.
        UpdatePurchasePrepmtAccount(
          OldPurchPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure PostSalesPrepmtWhenVATPctDifferentFromPrepmtVATPct(VATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup2: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        SalesPrepaymentsAccount: Code[20];
        OldSalesPrepaymentsAccount: Code[20];
    begin
        // Setup: Set Full GST on Prepayment as TRUE on GLSetup, Find General Posting Setup, Create Prepayment GL Account with VAT Product Posting Group received and update the prepayment account to General Posting Setup.
        SalesPrepmtSetup(GeneralPostingSetup, VATPostingSetup, SalesPrepaymentsAccount);

        // Exercise: Create Sales Document with Prepayment %. Update Sales Line with different VAT Product Posting Group than attached on Prepayment Account. Post Prepayment Invoice.
        CreateSalesOrder(
          SalesLine, CreateCustomerWithVAT(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItemWithVAT(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2), '');
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        SalesLine.Modify(true);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        asserterror SalesPostPrepayments.Invoice(SalesHeader);

        // Verify: Verify expected error with the actual error.
        Assert.ExpectedError(
          StrSubstNo(
            PrepaymentVATPctError, SalesLine.FieldCaption("Prepayment VAT %"), SalesLine."VAT %", SalesLine.FieldCaption("VAT %"),
            SalesLine.TableCaption(), SalesLine.FieldCaption("Document Type"), SalesLine."Document Type",
            SalesLine.FieldCaption("Document No."), SalesLine."Document No.", SalesLine.FieldCaption("Line No."), SalesLine."Line No."));

        // Tear Down: Restore the original prepayment account on General Ledger Setup and General Posting Setup.
        UpdateSalesPrepmtAccount(
          OldSalesPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        LibraryAULocalization.EnableGSTSetup(false, false);
    end;

    local procedure PurchPrepmtSetup(var GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; var PurchPrepaymentsAccount: Code[20]): Code[20]
    begin
        LibraryAULocalization.EnableGSTSetup(false, true);
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        PurchPrepaymentsAccount :=
          CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        exit(
          UpdatePurchasePrepmtAccount(
            PurchPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group"));
    end;

    local procedure SalesPrepmtSetup(var GeneralPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; var SalesPrepaymentAccount: Code[20]): Code[20]
    begin
        LibraryAULocalization.EnableGSTSetup(false, true);
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        SalesPrepaymentAccount :=
          CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        exit(
          UpdateSalesPrepmtAccount(
            SalesPrepaymentAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group"));
    end;

    local procedure SalesLineVATPctDifferentFromPrepmtAccVATPct(VATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup2: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrepaymentsAccount: Code[20];
        OldSalesPrepaymentsAccount: Code[20];
    begin
        // Setup: Find General Posting Setup, Create Prepayment GL Account with VAT Product Posting Group received and update the prepayment account to General Posting Setup.
        SalesPrepmtSetup(GeneralPostingSetup, VATPostingSetup, SalesPrepaymentsAccount);

        // Exercise: Create Sales Header with Prepayment %. Create Sales line for GL Account with different VAT Product Posting Group than attached on Prepayment Account.
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerWithVAT(VATPostingSetup."VAT Bus. Posting Group"));
        SetRandomPrepmtPctOnSalesHeader(SalesHeader);
        asserterror LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group"),
            LibraryRandom.RandDec(10, 2));

        // Verify: Verify expected error with the actual error.
        Assert.ExpectedError(
          StrSubstNo(
            VATProdPostingGroupError, VATPostingSetup.FieldCaption("VAT Prod. Posting Group"),
            VATPostingSetup2."VAT Prod. Posting Group", SalesLine.Type, SalesLine.FieldCaption("No."),
            SalesPrepaymentsAccount, VATPostingSetup."VAT Prod. Posting Group"));

        // Tear Down: Restore the original prepayment account on General Posting Setup.
        UpdateSalesPrepmtAccount(
          OldSalesPrepaymentsAccount, GeneralPostingSetup."Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure UpdatePurchasePrepmtAccount(PurchPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldPurchPrepaymentsAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if PurchPrepaymentsAccount = '' then
            exit;
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldPurchPrepaymentsAccount := GeneralPostingSetup."Purch. Prepayments Account";
        GeneralPostingSetup.Validate("Purch. Prepayments Account", PurchPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesPrepmtAccount(SalesPrepaymentsAccount: Code[20]; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) OldSalesPrepaymentsAccount: Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if SalesPrepaymentsAccount = '' then
            exit;
        GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        OldSalesPrepaymentsAccount := GeneralPostingSetup."Sales Prepayments Account";
        GeneralPostingSetup.Validate("Sales Prepayments Account", SalesPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header"; DocumentNo: Code[20])
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", DocumentNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifySalesLinePrepaymentLineAmtExclVAT(SalesLine: Record "Sales Line")
    begin
        Assert.AreNearlyEqual(PrepaymentAmount, SalesLine."Prepmt. Line Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, SalesLine.FieldCaption("Prepmt. Line Amount"), PrepaymentAmount, SalesLine.TableCaption()));
    end;

    local procedure VerifySalesLinePrepaymentLineAmtInclVAT(SalesLine: Record "Sales Line")
    begin
        Assert.AreNearlyEqual(
          PrepaymentTotalAmount + PrepaymentVATAmount, SalesLine."Prepmt. Line Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, SalesLine.FieldCaption("Prepmt. Line Amount"), PrepaymentAmount, SalesLine.TableCaption()));
    end;

    local procedure VerifyPurchaseLinePrepaymentLineAmtInclVAT(PurchaseLine: Record "Purchase Line")
    begin
        Assert.AreNearlyEqual(
          PrepaymentTotalAmount + PrepaymentVATAmount, PurchaseLine."Prepmt. Line Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, PurchaseLine.FieldCaption("Prepmt. Line Amount"), PrepaymentAmount, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyPurchaseLinePrepaymentLineAmtExclVAT(PurchaseLine: Record "Purchase Line")
    begin
        Assert.AreNearlyEqual(PrepaymentAmount, PurchaseLine."Prepmt. Line Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, PurchaseLine.FieldCaption("Prepmt. Line Amount"), PrepaymentAmount, PurchaseLine.TableCaption()));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPrepmtFieldsStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        SalesOrderStatistics.PrepmtTotalAmount.AssertEquals(PrepaymentAmount);
        SalesOrderStatistics.PrepmtVATAmount.AssertEquals(PrepaymentVATAmount);
        SalesOrderStatistics.PrepmtTotalAmount2.AssertEquals(PrepaymentTotalAmount);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesPrepmtFieldsStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        SalesOrderStatistics.PrepmtTotalAmount.AssertEquals(PrepaymentAmount);
        SalesOrderStatistics.PrepmtVATAmount.AssertEquals(PrepaymentVATAmount);
        SalesOrderStatistics.PrepmtTotalAmount2.AssertEquals(PrepaymentTotalAmount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchasePrepmtFieldsStatisticsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        PurchaseOrderStatistics.PrepmtTotalAmount.AssertEquals(PrepaymentAmount);
        PurchaseOrderStatistics.PrepmtVATAmount.AssertEquals(PrepaymentVATAmount);
        PurchaseOrderStatistics.PrepmtTotalAmount2.AssertEquals(PrepaymentTotalAmount);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchasePrepmtFieldsStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        // Format Precision taken to convert Decimal value in Text.
        PurchaseOrderStatistics.PrepmtTotalAmount.AssertEquals(PrepaymentAmount);
        PurchaseOrderStatistics.PrepmtVATAmount.AssertEquals(PrepaymentVATAmount);
        PurchaseOrderStatistics.PrepmtTotalAmount2.AssertEquals(PrepaymentTotalAmount);
    end;
}

