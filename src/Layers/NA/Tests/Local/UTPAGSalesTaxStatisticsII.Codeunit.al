codeunit 141020 "UT PAG Sales Tax Statistics II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Statistics]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        AmountMustEqualMsg: Label 'Amount must be equal';

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrder()
    var
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 42, Sales Order without Tax Area.

        // Setup: Create and open Sales Order Statistics without Tax Area Code.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, '', '', false);
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Create a Sales Order, Invokes Action - Statistics on Sales Order and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesOrder()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 42, Sales Order with Tax Area and Tax Liable TRUE.

        // Setup: Create and open Sales Order Statistics with Tax Area Code.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true);
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Create a Sales Order, Invokes Action - Statistics on Sales Order and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesReturnOrder()
    var
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 6630, Sales Return Order without Tax Area.

        // Setup: Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxDetail."Tax Group Code", '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForSalesReturnOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesReturnOrder()
    var
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 6630, Sales Return Order with Tax Area and Tax Liable.

        // Setup: Create Tax Setup, Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesReturnOrder(SalesLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderNM()
    var
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 42, Sales Order without Tax Area.

        // Setup: Create and open Sales Order Statistics without Tax Area Code.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, '', '', false);
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Create a Sales Order, Invokes Action - Statistics on Sales Order and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenSalesOrderStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesOrderNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 42, Sales Order with Tax Area and Tax Liable TRUE.

        // Setup: Create and open Sales Order Statistics with Tax Area Code.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true);
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Create a Sales Order, Invokes Action - Statistics on Sales Order and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenSalesOrderStatsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesReturnOrderNM()
    var
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 6630, Sales Return Order without Tax Area.

        // Setup: Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxDetail."Tax Group Code", '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenSalesOrderStatisticsPageForSalesReturnOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesReturnOrderNM()
    var
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 6630, Sales Return Order with Tax Area and Tax Liable.

        // Setup: Create Tax Setup, Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenSalesOrderStatsPageForSalesReturnOrder(SalesLine."Document No.");
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsServiceOrder()
    var
        TaxDetail: Record "Tax Detail";
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 5900, Service Order with Tax Area and Tax Liable.

        // Setup: Create and open Service Order Statistics with Tax Area Code.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateAndOpenServiceOrderStatistics(TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true, TaxDetail."Tax Below Maximum");  // Tax Liable TRUE.
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaServiceOrder()
    var
        TaxDetail: Record "Tax Detail";
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 5900, Service Order without Tax Area and Tax Liable.

        // Setup: Create and open Service Order Statistics without Tax Area Code.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateAndOpenServiceOrderStatistics(TaxDetail."Tax Group Code", '', false, TaxDetail."Tax Below Maximum");  // Tax Liable FALSE.
    end;

    local procedure CreateAndOpenServiceOrderStatistics(TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean; TaxBelowMaximum: Decimal)
    var
        ServiceLine: Record "Service Line";
        TaxAmount: Decimal;
    begin
        // Create Service Order with Tax Area Code.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order, TaxAreaCode, TaxGroupCode, TaxLiable);
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxBelowMaximum / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceOrderStatisticsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Order and verified Tax Amount on ServiceOrderStatisticsPageHandler.
        OpenStatisticsPageForServiceOrder(ServiceLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsServiceOrderNM()
    var
        TaxDetail: Record "Tax Detail";
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 5900, Service Order with Tax Area and Tax Liable.

        // Setup: Create and open Service Order Statistics with Tax Area Code.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateAndOpenServiceOrderStatsNM(TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true, TaxDetail."Tax Below Maximum");  // Tax Liable TRUE.
    end;

    [Test]
    [HandlerFunctions('ServiceOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaServiceOrderNM()
    var
        TaxDetail: Record "Tax Detail";
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 5900, Service Order without Tax Area and Tax Liable.

        // Setup: Create and open Service Order Statistics without Tax Area Code.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateAndOpenServiceOrderStatisticsNM(TaxDetail."Tax Group Code", '', false, TaxDetail."Tax Below Maximum");  // Tax Liable FALSE.
    end;

    local procedure CreateAndOpenServiceOrderStatsNM(TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean; TaxBelowMaximum: Decimal)
    var
        ServiceLine: Record "Service Line";
        TaxAmount: Decimal;
    begin
        // Create Service Order with Tax Area Code.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order, TaxAreaCode, TaxGroupCode, TaxLiable);
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxBelowMaximum / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceOrderStatisticsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Order and verified Tax Amount on ServiceOrderStatisticsPageHandler.
        OpenStatsPageForServiceOrderNM(ServiceLine."Document No.");
    end;

    local procedure CreateAndOpenServiceOrderStatisticsNM(TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean; TaxBelowMaximum: Decimal)
    var
        ServiceLine: Record "Service Line";
        TaxAmount: Decimal;
    begin
        // Create Service Order with Tax Area Code.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Order, TaxAreaCode, TaxGroupCode, TaxLiable);
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxBelowMaximum / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Required inside ServiceOrderStatisticsPageHandler.

        // Exercise and verify: Invokes Action - Statistics on Page Service Order and verified Tax Amount on ServiceOrderStatisticsPageHandler.
        OpenStatisticsPageForServiceOrderNM(ServiceLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 50 Purchase Order.

        // Setup: Create and open Purchase Order Statistics with Tax Area Code.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Order and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchaseOrder(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchOrder()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 50 Purchase Order.

        // Setup: Create and open Purchase Order Statistics with Tax Area Code.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Order and verify VAT Amount and Amount Inclusive VAT on PurchOrderStatisticsPageHandler.
        OpenStatsPageForPurchOrder(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseOrder()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 50 Purchase Order.

        // Setup: Create and open Purchase Order Statistics without Tax Area Code.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Order and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchaseOrder(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchOrder()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 50 Purchase Order.

        // Setup: Create and open Purchase Order Statistics without Tax Area Code.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Order and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchOrder(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseReturnOrder()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 6640 Purchase Return Order.

        // Setup: Create Purchase Return Order with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order and verify Tax Amount and Amount Inclusive Tax on PurchaseOrderStatsPageHandler.
        OpenStatisticsPageForPurchaseReturnOrder(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchReturnOrder()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 6640 Purchase Return Order.

        // Setup: Create Purchase Return Order with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order and verify Tax Amount and Amount Inclusive Tax on PurchaseOrderStatsPageHandler.
        OpenStatsPageForPurchReturnOrder(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseReturnOrder()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 6640 Purchase Return Order.

        // Setup: Create Purchase Return Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchaseReturnOrder(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchReturnOrder()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 6640 Purchase Return Order.

        // Setup: Create Purchase Return Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchReturnOrder(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsQuoteModalPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesQuote()
    var
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 41, Sales Quote without Tax Area.

        // Setup: Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, '', '', false);   // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesStatisticsQuoteModalPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Quote and verify the VAT Amount on Statistics page in SalesStatisticsQuoteModalPageHandler.
        OpenStatisticsPageForSalesQuote(SalesLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsQuotePageHandler')]
    [Scope('OnPrem')]
    procedure OnActionSalesStatisticsSalesQuote()
    var
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 41, Sales Quote without Tax Area.

        // Setup: Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, '', '', false);   // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesStatisticsQuotePageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Quote and verify the VAT Amount on Statistics page in SalesStatisticsQuotePageHandler.
        OpenSalesStatisticsPageForSalesQuote(SalesLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatsQuotePageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesQuote()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 41, Sales Quote with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesStatsQuotePageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Quote and verify the Tax Amount on Statistics page in SalesStatsQuotePageHandler.
        OpenStatisticsPageForSalesQuote(SalesLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatsQuoteNonModalPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionSalesStatsWithTaxAreaSalesQuote()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 41, Sales Quote with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesStatsQuotePageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Quote and verify the Tax Amount on Statistics page in SalesStatsQuotePageHandler.
        OpenSalesStatsPageForSalesQuote(SalesLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsBlanketSalesOrder()
    var
        SalesLine: Record "Sales Line";
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 507, Blanket Sales Order without Tax Area.

        // Setup: Create a Blanket Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", '', '', false);   // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page Blanket Sales Order and verify the VAT Amount on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaBlanketSalesOrder()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 507, Blanket Sales Order with Tax Area.

        // Setup: Create Tax Setup, Create a Blanket Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page Blanket Sales Order and verify the Tax Amount on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsBlanketSalesOrderNM()
    var
        SalesLine: Record "Sales Line";
        AmountIncVAT: Decimal;
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 507, Blanket Sales Order without Tax Area.

        // Setup: Create a Blanket Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", '', '', false);   // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page Blanket Sales Order and verify the VAT Amount on Statistics page in SalesOrderStatisticsPageHandler.
        OpenSalesOrderStatisticsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaBlanketSalesOrderNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 507, Blanket Sales Order with Tax Area.

        // Setup: Create Tax Setup, Create a Blanket Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", TaxDetail."Tax Group Code", CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page Blanket Sales Order and verify the Tax Amount on Statistics page in SalesOrderStatsPageHandler.
        OpenSalesOrderStatsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesInvoice()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 132, Posted Sales Invoice without Tax Area.

        // Setup: Create Posted Sales Invoice.
        CreatePostedSalesInvoice(SalesInvoiceLine, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesInvoiceLine."Line Amount" * SalesInvoiceLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesInvoiceStatisticsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Invoice and verify the VAT Amount on Statistics page in SalesInvoiceStatisticsPageHandler.
        OpenStatisticsPageForPostedSalesInvoice(SalesInvoiceLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceStatsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPostedSalesInvoice()
    var
        TaxDetail: Record "Tax Detail";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 132, Posted Sales Invoice with Tax Area.

        // Setup: Create Tax Setup, Create Posted Sales Invoice.
        CreateTaxDetail(TaxDetail);
        CreatePostedSalesInvoice(SalesInvoiceLine, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := SalesInvoiceLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesInvoiceStatsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Invoice and verify the Tax Amount on Statistics page in SalesInvoiceStatsPageHandler.
        OpenStatisticsPageForPostedSalesInvoice(SalesInvoiceLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsPageHandlerNM')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesInvoiceNM()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 132, Posted Sales Invoice without Tax Area.

        // Setup: Create Posted Sales Invoice.
        CreatePostedSalesInvoice(SalesInvoiceLine, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesInvoiceLine."Line Amount" * SalesInvoiceLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesInvoiceStatisticsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Invoice and verify the VAT Amount on Statistics page in SalesInvoiceStatisticsPageHandler.
        OpenStatisticsPageForPostedSalesInvoiceNM(SalesInvoiceLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceStatsPageHandlerNM')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPostedSalesInvoiceNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 132, Posted Sales Invoice with Tax Area.

        // Setup: Create Tax Setup, Create Posted Sales Invoice.
        CreateTaxDetail(TaxDetail);
        CreatePostedSalesInvoice(SalesInvoiceLine, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := SalesInvoiceLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesInvoiceStatsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Invoice and verify the Tax Amount on Statistics page in SalesInvoiceStatsPageHandler.
        OpenStatsPageForPostedSalesInvoiceNM(SalesInvoiceLine."Document No.");
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesInvList()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 143, Posted Sales Invoices without Tax Area.

        // Setup: Create Posted Sales Invoice.
        CreatePostedSalesInvoice(SalesInvoiceLine, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesInvoiceLine."Line Amount" * SalesInvoiceLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesInvoiceStatisticsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Invoices and verify the VAT Amount on Statistics page in SalesInvoiceStatisticsPageHandler.
        OpenStatisticsPageForPostedSalesInvoiceList(SalesInvoiceLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceStatsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPostedSalesInvoiceList()
    var
        TaxDetail: Record "Tax Detail";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 143, Posted Sales Invoices with Tax Area.

        // Setup: Create Tax Setup, Create Posted Sales Invoice.
        CreateTaxDetail(TaxDetail);
        CreatePostedSalesInvoice(SalesInvoiceLine, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := SalesInvoiceLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesInvoiceStatsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Invoices and verify the Tax Amount on Statistics page in SalesInvoiceStatsPageHandler.
        OpenStatisticsPageForPostedSalesInvoiceList(SalesInvoiceLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesInvoiceStatisticsPageHandlerNM')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesInvListNM()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 143, Posted Sales Invoices without Tax Area.

        // Setup: Create Posted Sales Invoice.
        CreatePostedSalesInvoice(SalesInvoiceLine, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesInvoiceLine."Line Amount" * SalesInvoiceLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesInvoiceStatisticsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Invoices and verify the VAT Amount on Statistics page in SalesInvoiceStatisticsPageHandler.
        OpenStatisticsPageForPostedSalesInvoiceListNM(SalesInvoiceLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceStatsPageHandlerNM')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPostedSalesInvoiceListNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesInvoiceLine: Record "Sales Invoice Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 143, Posted Sales Invoices with Tax Area.

        // Setup: Create Tax Setup, Create Posted Sales Invoice.
        CreateTaxDetail(TaxDetail);
        CreatePostedSalesInvoice(SalesInvoiceLine, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := SalesInvoiceLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesInvoiceStatsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Invoices and verify the Tax Amount on Statistics page in SalesInvoiceStatsPageHandler.
        OpenStatsPageForPostedSalesInvoiceListNM(SalesInvoiceLine."Document No.");
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('SalesCreditMemoStatisticsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesCrMemo()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 134, Posted Sales Credit Memo without Tax Area.

        // Setup: Create Posted Sales Credit Memo.
        CreatePostedSalesCreditMemo(SalesCrMemoLine, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesCrMemoLine."Line Amount" * SalesCrMemoLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesCreditMemoStatisticsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Credit Memo and verify the VAT Amount on Statistics page in SalesCreditMemoStatisticsPageHandler.
        OpenStatisticsPageForPostedSalesCrMemo(SalesCrMemoLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoStatsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPostedSalesCrMemo()
    var
        TaxDetail: Record "Tax Detail";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 132, Posted Sales Credit Memo with Tax Area.

        // Setup: Create Tax Setup, Create Posted Sales Credit Memo.
        CreateTaxDetail(TaxDetail);
        CreatePostedSalesCreditMemo(SalesCrMemoLine, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := SalesCrMemoLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesCreditMemoStatsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Credit Memo and verify the Tax Amount on Statistics page in SalesCreditMemoStatsPageHandler.
        OpenStatisticsPageForPostedSalesCrMemo(SalesCrMemoLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesCreditMemoStatisticsPageHandlerNM')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesCrMemoNM()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 134, Posted Sales Credit Memo without Tax Area.

        // Setup: Create Posted Sales Credit Memo.
        CreatePostedSalesCreditMemo(SalesCrMemoLine, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesCrMemoLine."Line Amount" * SalesCrMemoLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesCreditMemoStatisticsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Credit Memo and verify the VAT Amount on Statistics page in SalesCreditMemoStatisticsPageHandler.
        OpenStatisticsPageForPostedSalesCrMemoNM(SalesCrMemoLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoStatsPageHandlerNM')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPostedSalesCrMemoNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 132, Posted Sales Credit Memo with Tax Area.

        // Setup: Create Tax Setup, Create Posted Sales Credit Memo.
        CreateTaxDetail(TaxDetail);
        CreatePostedSalesCreditMemo(SalesCrMemoLine, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := SalesCrMemoLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesCreditMemoStatsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Credit Memo and verify the Tax Amount on Statistics page in SalesCreditMemoStatsPageHandler.
        OpenStatsPageForPostedSalesCrMemoNM(SalesCrMemoLine."Document No.");
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('SalesCreditMemoStatisticsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesCrMemoList()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 144, Posted Sales Credit Memos without Tax Area.

        // Setup: Create Posted Sales Credit Memo.
        CreatePostedSalesCreditMemo(SalesCrMemoLine, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesCrMemoLine."Line Amount" * SalesCrMemoLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesCreditMemoStatisticsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Credit Memos and verify the VAT Amount on Statistics page in SalesCreditMemoStatisticsPageHandler.
        OpenStatisticsPageForPostedSalesCrMemoList(SalesCrMemoLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoStatsPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPostedSalesCrMemoList()
    var
        TaxDetail: Record "Tax Detail";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 144, Posted Sales Credit Memos with Tax Area.

        // Setup: Create Tax Setup, Create Posted Sales Credit Memo.
        CreateTaxDetail(TaxDetail);
        CreatePostedSalesCreditMemo(SalesCrMemoLine, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := SalesCrMemoLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesCreditMemoStatsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Credit Memos and verify the Tax Amount on Statistics page in SalesCreditMemoStatsPageHandler.
        OpenStatisticsPageForPostedSalesCrMemoList(SalesCrMemoLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesCreditMemoStatisticsPageHandlerNM')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPostedSalesCrMemoListNM()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 144, Posted Sales Credit Memos without Tax Area.

        // Setup: Create Posted Sales Credit Memo.
        CreatePostedSalesCreditMemo(SalesCrMemoLine, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := SalesCrMemoLine."Line Amount" * SalesCrMemoLine."VAT %" / 100;
        LibraryVariableStorage.Enqueue(VATAmount);  // Enqueue values for use in SalesCreditMemoStatisticsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Credit Memos and verify the VAT Amount on Statistics page in SalesCreditMemoStatisticsPageHandler.
        OpenStatisticsPageForPostedSalesCrMemoListNM(SalesCrMemoLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesCreditMemoStatsPageHandlerNM')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPostedSalesCrMemoListNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TaxAmount: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 144, Posted Sales Credit Memos with Tax Area.

        // Setup: Create Tax Setup, Create Posted Sales Credit Memo.
        CreateTaxDetail(TaxDetail);
        CreatePostedSalesCreditMemo(SalesCrMemoLine, CreateTaxAreaLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := SalesCrMemoLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        LibraryVariableStorage.Enqueue(TaxAmount);  // Enqueue values for use in SalesCreditMemoStatsPageHandler.

        // Exercise & Verify: Invokes Action - Statistics on Page Posted Sales Credit Memos and verify the Tax Amount on Statistics page in SalesCreditMemoStatsPageHandler.
        OpenStatsPageForPostedSalesCrMemoListNM(SalesCrMemoLine."Document No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySales.DisableWarningOnCloseUnpostedDoc();
        LibrarySales.DisableWarningOnCloseUnreleasedDoc();
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.FindFirst();
        Customer."No." := LibraryUTUtility.GetNewCode();
        Customer."Customer Posting Group" := CustomerPostingGroup.Code;
        Customer.Insert();
        exit(Customer."No.")
    end;

    local procedure CreatePostedSalesCreditMemo(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader."No." := LibraryUTUtility.GetNewCode();
        SalesCrMemoHeader."Tax Area Code" := TaxAreaCode;
        SalesCrMemoHeader.Insert();

        SalesCrMemoLine."Document No." := SalesCrMemoHeader."No.";
        SalesCrMemoLine.Type := SalesCrMemoLine.Type::Item;
        SalesCrMemoLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesCrMemoLine."VAT %" := LibraryRandom.RandInt(10);
        SalesCrMemoLine."Unit Price" := LibraryRandom.RandDec(10, 2);
        SalesCrMemoLine.Amount := SalesCrMemoLine.Quantity * SalesCrMemoLine."Unit Price";
        SalesCrMemoLine."Line Amount" := SalesCrMemoLine.Amount;
        SalesCrMemoLine."VAT Base Amount" := SalesCrMemoLine."Line Amount";
        SalesCrMemoLine."Amount Including VAT" := SalesCrMemoLine.Amount + ((SalesCrMemoLine.Amount * SalesCrMemoLine."VAT %") / 100);  // Calculation for Amount Including VAT.
        SalesCrMemoLine."Tax Area Code" := TaxAreaCode;
        SalesCrMemoLine."Tax Group Code" := TaxGroupCode;
        SalesCrMemoLine."Tax Liable" := TaxLiable;
        SalesCrMemoLine.Insert();
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Tax Area Code" := TaxAreaCode;
        SalesHeader.Insert();

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryRandom.RandInt(100);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesLine."Tax Group Code" := TaxGroupCode;
        SalesLine."Tax Area Code" := TaxAreaCode;
        SalesLine."Tax Liable" := TaxLiable;
        SalesLine."VAT %" := LibraryRandom.RandInt(10);
        SalesLine."Unit Price" := LibraryRandom.RandDec(10, 2);
        SalesLine."Line Amount" := LibraryRandom.RandDec(10, 2);
        SalesLine.Insert();
    end;

    local procedure CreatePostedSalesInvoice(var SalesInvoiceLine: Record "Sales Invoice Line"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader."No." := LibraryUTUtility.GetNewCode();
        SalesInvoiceHeader."Tax Area Code" := TaxAreaCode;
        SalesInvoiceHeader.Insert();

        SalesInvoiceLine."Document No." := SalesInvoiceHeader."No.";
        SalesInvoiceLine.Type := SalesInvoiceLine.Type::Item;
        SalesInvoiceLine.Quantity := LibraryRandom.RandDec(10, 2);
        SalesInvoiceLine."VAT %" := LibraryRandom.RandInt(10);
        SalesInvoiceLine."Unit Price" := LibraryRandom.RandDec(10, 2);
        SalesInvoiceLine.Amount := SalesInvoiceLine.Quantity * SalesInvoiceLine."Unit Price";
        SalesInvoiceLine."Line Amount" := SalesInvoiceLine.Amount;
        SalesInvoiceLine."VAT Base Amount" := SalesInvoiceLine."Line Amount";
        SalesInvoiceLine."Amount Including VAT" := SalesInvoiceLine.Amount + ((SalesInvoiceLine.Amount * SalesInvoiceLine."VAT %") / 100);  // Calculation for Amount Including VAT.
        SalesInvoiceLine."Tax Area Code" := TaxAreaCode;
        SalesInvoiceLine."Tax Group Code" := TaxGroupCode;
        SalesInvoiceLine."Tax Liable" := TaxLiable;
        SalesInvoiceLine.Insert();
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := DocumentType;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader.Insert();

        PurchaseLine."Document Type" := DocumentType;
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := LibraryInventory.CreateItemNo();
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDec(10, 2);
        PurchaseLine.Quantity := LibraryRandom.RandDec(10, 2);
        PurchaseLine."Line Amount" := LibraryRandom.RandDec(10, 2);
        PurchaseLine."VAT %" := LibraryRandom.RandInt(10);
        PurchaseLine."Tax Area Code" := TaxAreaCode;
        PurchaseLine."Tax Group Code" := TaxGroupCode;
        PurchaseLine."Tax Liable" := TaxLiable;
        PurchaseLine.Insert();
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; DocumentType: Enum "Service Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxLiable: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceHeader."Document Type" := DocumentType;
        ServiceHeader."No." := LibraryUTUtility.GetNewCode();
        ServiceHeader."Customer No." := CreateCustomer();
        ServiceHeader."Bill-to Customer No." := ServiceHeader."Customer No.";
        ServiceHeader."Tax Area Code" := TaxAreaCode;
        ServiceHeader.Insert();

        ServiceLine."Document Type" := ServiceLine."Document Type"::Order;
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."Tax Area Code" := TaxAreaCode;
        ServiceLine."Tax Group Code" := TaxGroupCode;
        ServiceLine."Tax Liable" := TaxLiable;
        ServiceLine.Quantity := LibraryRandom.RandInt(10);
        ServiceLine.Insert();
    end;

    local procedure CreateTaxArea(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea.Insert();
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaLine(TaxJurisdictionCode: Code[10]): Code[20]
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine."Tax Area" := CreateTaxArea();
        TaxAreaLine."Tax Jurisdiction Code" := TaxJurisdictionCode;
        TaxAreaLine.Insert();
        exit(TaxAreaLine."Tax Area");
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail")
    begin
        TaxDetail."Tax Jurisdiction Code" := CreateTaxJurisdiction();
        TaxDetail."Tax Group Code" := CreateTaxGroup();
        TaxDetail."Tax Below Maximum" := LibraryRandom.RandDec(10, 2);
        TaxDetail.Insert();
    end;

    local procedure CreateTaxGroup(): Code[20]
    var
        TaxGroup: Record "Tax Group";
    begin
        TaxGroup.Code := LibraryUTUtility.GetNewCode10();
        TaxGroup.Insert();
        exit(TaxGroup.Code);
    end;

    local procedure CreateTaxJurisdiction(): Code[10]
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        TaxJurisdiction.Code := LibraryUTUtility.GetNewCode10();
        TaxJurisdiction.Insert();
        exit(TaxJurisdiction.Code);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForBlanketSalesOrder(No: Code[20])
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", No);
        BlanketSalesOrder.Statistics.Invoke();  // Opens Handler - SalesInvoiceStatisticsPageHandler or SalesOrderStatsPageHandler.
        BlanketSalesOrder.Close();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Statistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesOrder.Close();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForSalesQuote(No: Code[20])
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", No);
        SalesQuote.Statistics.Invoke();  // Opens Handler - SalesStatisticsModalQuotePageHandler or SalesStatsQuotePageHandler.
        SalesQuote.Close();
    end;
#endif
    local procedure OpenSalesOrderStatisticsPageForBlanketSalesOrder(No: Code[20])
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", No);
        BlanketSalesOrder.SalesOrderStatistics.Invoke();  // Opens Handler - SalesInvoiceStatisticsPageHandler or SalesOrderStatsPageHandler.
        BlanketSalesOrder.Close();
    end;

    local procedure OpenSalesOrderStatsPageForBlanketSalesOrder(No: Code[20])
    var
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", No);
        BlanketSalesOrder.SalesOrderStats.Invoke();  // Opens Handler - SalesInvoiceStatisticsPageHandler or SalesOrderStatsPageHandler.
        BlanketSalesOrder.Close();
    end;

    local procedure OpenSalesOrderStatisticsPageForSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesOrderStatistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesOrder.Close();
    end;

    local procedure OpenSalesOrderStatsPageForSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesOrderStats.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesOrder.Close();
    end;

    local procedure OpenSalesStatisticsPageForSalesQuote(No: Code[20])
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", No);
        SalesQuote.SalesStatistics.Invoke();  // Opens Handler - SalesStatisticsQuotePageHandler or SalesStatsQuotePageHandler.
        SalesQuote.Close();
    end;

    local procedure OpenSalesStatsPageForSalesQuote(No: Code[20])
    var
        SalesQuote: TestPage "Sales Quote";
    begin
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", No);
        SalesQuote.SalesStats.Invoke();  // Opens Handler - SalesStatisticsQuotePageHandler or SalesStatsQuotePageHandler.
        SalesQuote.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.Statistics.Invoke();  // Opens Handler - SalesOrderStatsPageHandler and SalesOrderStatisticsPageHandler.
        SalesReturnOrder.Close();
    end;
#endif
    local procedure OpenSalesOrderStatisticsPageForSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.SalesOrderStatistics.Invoke();  // Opens Handler - SalesOrderStatsPageHandler and SalesOrderStatisticsPageHandler.
        SalesReturnOrder.Close();
    end;

    local procedure OpenSalesOrderStatsPageForSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.SalesOrderStats.Invoke();  // Opens Handler - SalesOrderStatsPageHandler and SalesOrderStatisticsPageHandler.
        SalesReturnOrder.Close();
    end;

#if not CLEAN27
    local procedure OpenStatisticsPageForPostedSalesCrMemo(No: Code[20])
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", No);
        PostedSalesCreditMemo.Statistics.Invoke();  // SalesCreditMemoStatisticsPageHandler or SalesCreditMemoStatsPageHandler.
        PostedSalesCreditMemo.Close();
    end;

    local procedure OpenStatisticsPageForPostedSalesCrMemoList(No: Code[20])
    var
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        PostedSalesCreditMemos.OpenEdit();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", No);
        PostedSalesCreditMemos.Statistics.Invoke();  // SalesCreditMemoStatisticsPageHandler or SalesCreditMemoStatsPageHandler.
        PostedSalesCreditMemos.Close();
    end;

    local procedure OpenStatisticsPageForPostedSalesInvoice(No: Code[20])
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.FILTER.SetFilter("No.", No);
        PostedSalesInvoice.Statistics.Invoke();  // Opens Handler - SalesInvoiceStatisticsPageHandler or SalesOrderStatsPageHandler.
        PostedSalesInvoice.Close();
    end;

    local procedure OpenStatisticsPageForPostedSalesInvoiceList(No: Code[20])
    var
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        PostedSalesInvoices.OpenEdit();
        PostedSalesInvoices.FILTER.SetFilter("No.", No);
        PostedSalesInvoices.Statistics.Invoke();  // Opens Handler - SalesInvoiceStatisticsPageHandler or SalesOrderStatsPageHandler.
        PostedSalesInvoices.Close();
    end;

    local procedure OpenStatisticsPageForServiceOrder(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.Statistics.Invoke();  // Opens Handler - ServiceOrderStatsPageHandler and ServiceOrderStatisticsPageHandlerPageHandler.
        ServiceOrder.Close();
    end;
#endif
    local procedure OpenStatisticsPageForPostedSalesCrMemoNM(No: Code[20])
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", No);
        PostedSalesCreditMemo.SalesCrMemoStatistics.Invoke();  // SalesCreditMemoStatisticsPageHandler.
        PostedSalesCreditMemo.Close();
    end;

    local procedure OpenStatsPageForPostedSalesCrMemoNM(No: Code[20])
    var
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", No);
        PostedSalesCreditMemo.SalesCrMemoStats.Invoke();  // SalesCreditMemoStatsPageHandler.
        PostedSalesCreditMemo.Close();
    end;

    local procedure OpenStatisticsPageForPostedSalesCrMemoListNM(No: Code[20])
    var
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        PostedSalesCreditMemos.OpenEdit();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", No);
        PostedSalesCreditMemos.SalesCrMemoStatistics.Invoke();  // SalesCreditMemoStatisticsPageHandler.
        PostedSalesCreditMemos.Close();
    end;

    local procedure OpenStatsPageForPostedSalesCrMemoListNM(No: Code[20])
    var
        PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos";
    begin
        PostedSalesCreditMemos.OpenEdit();
        PostedSalesCreditMemos.FILTER.SetFilter("No.", No);
        PostedSalesCreditMemos.SalesCrMemoStats.Invoke();  // SalesCreditMemoStatsPageHandler.
        PostedSalesCreditMemos.Close();
    end;

    local procedure OpenStatisticsPageForPostedSalesInvoiceNM(No: Code[20])
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.FILTER.SetFilter("No.", No);
        PostedSalesInvoice.SalesInvoiceStatistics.Invoke();  // Opens Handler - SalesInvoiceStatisticsPageHandler.
        PostedSalesInvoice.Close();
    end;

    local procedure OpenStatsPageForPostedSalesInvoiceNM(No: Code[20])
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.FILTER.SetFilter("No.", No);
        PostedSalesInvoice.SalesInvoiceStats.Invoke();  // Opens Handler - SalesOrderStatsPageHandler.
        PostedSalesInvoice.Close();
    end;

    local procedure OpenStatisticsPageForPostedSalesInvoiceListNM(No: Code[20])
    var
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        PostedSalesInvoices.OpenEdit();
        PostedSalesInvoices.FILTER.SetFilter("No.", No);
        PostedSalesInvoices.SalesInvoiceStatistics.Invoke();  // Opens Handler - SalesInvoiceStatisticsPageHandler.
        PostedSalesInvoices.Close();
    end;

    local procedure OpenStatsPageForPostedSalesInvoiceListNM(No: Code[20])
    var
        PostedSalesInvoices: TestPage "Posted Sales Invoices";
    begin
        PostedSalesInvoices.OpenEdit();
        PostedSalesInvoices.FILTER.SetFilter("No.", No);
        PostedSalesInvoices.SalesInvoiceStats.Invoke();  // Opens Handler - SalesOrderStatsPageHandler.
        PostedSalesInvoices.Close();
    end;

    local procedure OpenStatisticsPageForServiceOrderNM(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServiceOrderStatistics.Invoke();  // Opens Handler - ServiceOrderStatisticsPageHandlerPageHandler.
        ServiceOrder.Close();
    end;

    local procedure OpenStatsPageForServiceOrderNM(No: Code[20])
    var
        ServiceOrder: TestPage "Service Order";
    begin
        ServiceOrder.OpenEdit();
        ServiceOrder.FILTER.SetFilter("No.", No);
        ServiceOrder.ServiceOrderStats.Invoke();  // Opens Handler - ServiceOrderStatsPageHandler.
        ServiceOrder.Close();
    end;
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenStatisticsPageForPurchaseOrder(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.Statistics.Invoke();  // Opens Handler - PurchaseOrderStatsPageHandler and PurchaseOrderStatisticsPageHandler.
        PurchaseOrder.Close();
    end;
#endif

    local procedure OpenStatsPageForPurchOrder(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchaseOrderStats.Invoke();  // Opens Handler - PurchOrderStatsPageHandler and PurchOrderStatisticsPageHandler.
        PurchaseOrder.Close();
    end;

    local procedure OpenStatisticsPageForPurchOrder(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchaseOrderStatistics.Invoke();  // Opens Handler - PurchOrderStatsPageHandler and PurchOrderStatisticsPageHandler.
        PurchaseOrder.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenStatisticsPageForPurchaseReturnOrder(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.Statistics.Invoke();  // Opens Handler - PurchaseOrderStatsPageHandler and PurchaseOrderStatisticsPageHandler.
        PurchaseReturnOrder.Close();
    end;
#endif

    local procedure OpenStatsPageForPurchReturnOrder(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.PurchaseOrderStats.Invoke();  // Opens Handler - PurchOrderStatsPageHandler and PurchOrderStatisticsPageHandler.
        PurchaseReturnOrder.Close();
    end;

    local procedure OpenStatisticsPageForPurchReturnOrder(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.PurchaseOrderStatistics.Invoke();  // Opens Handler - PurchOrderStatsPageHandler and PurchOrderStatisticsPageHandler.
        PurchaseReturnOrder.Close();
    end;

    local procedure VerifyTaxOnStatisticsPage(TaxAmount: Decimal; AmountIncTax: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ExpectedTaxAmount: Variant;
        ExpectedAmountIncTax: Variant;
    begin
        GeneralLedgerSetup.Get();
        LibraryVariableStorage.Dequeue(ExpectedTaxAmount);
        LibraryVariableStorage.Dequeue(ExpectedAmountIncTax);
        Assert.AreNearlyEqual(ExpectedTaxAmount, TaxAmount, GeneralLedgerSetup."Amount Rounding Precision", AmountMustEqualMsg);
        Assert.AreNearlyEqual(ExpectedAmountIncTax, AmountIncTax, GeneralLedgerSetup."Amount Rounding Precision", AmountMustEqualMsg);
        Assert.AreNotEqual(ExpectedTaxAmount, 0, 'Tax Amount must not be zero');
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        VerifyTaxOnStatisticsPage(SalesOrderStats.TaxAmount.AsDecimal(), SalesOrderStats."TotalAmount2[1]".AsDecimal());
        SalesOrderStats.OK().Invoke();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        VerifyTaxOnStatisticsPage(SalesOrderStatistics.VATAmount.AsDecimal(), SalesOrderStatistics."TotalAmount2[1]".AsDecimal());
        SalesOrderStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandlerNM(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        VerifyTaxOnStatisticsPage(SalesOrderStats.TaxAmount.AsDecimal(), SalesOrderStats."TotalAmount2[1]".AsDecimal());
        SalesOrderStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        VerifyTaxOnStatisticsPage(SalesOrderStatistics.VATAmount.AsDecimal(), SalesOrderStatistics."TotalAmount2[1]".AsDecimal());
        SalesOrderStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        VerifyTaxOnStatisticsPage(PurchaseOrderStats.TaxAmount.AsDecimal(), PurchaseOrderStats."TotalAmount2[1]".AsDecimal());
        PurchaseOrderStats.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        VerifyTaxOnStatisticsPage(PurchaseOrderStats.TaxAmount.AsDecimal(), PurchaseOrderStats."TotalAmount2[1]".AsDecimal());
        PurchaseOrderStats.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        VerifyTaxOnStatisticsPage(PurchaseOrderStatistics."VATAmount[1]".AsDecimal(), PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal());
        PurchaseOrderStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        VerifyTaxOnStatisticsPage(PurchaseOrderStatistics."VATAmount[1]".AsDecimal(), PurchaseOrderStatistics.TotalInclVAT_General.AsDecimal());
        PurchaseOrderStatistics.OK().Invoke();
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsPageHandler(var ServiceOrderStats: TestPage "Service Order Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceOrderStats."VATAmount[2]".AssertEquals(TaxAmount);
        ServiceOrderStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatisticsPageHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceOrderStatistics."VATAmount[2]".AssertEquals(TaxAmount);
        ServiceOrderStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatsPageHandlerNM(var ServiceOrderStats: TestPage "Service Order Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceOrderStats."VATAmount[2]".AssertEquals(TaxAmount);
        ServiceOrderStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatisticsPageHandlerNM(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        ServiceOrderStatistics."VATAmount[2]".AssertEquals(TaxAmount);
        ServiceOrderStatistics.OK().Invoke();
    end;
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsQuoteModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesStatistics.VATAmount.AssertEquals(VATAmount);
        SalesStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsQuotePageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesStatistics.VATAmount.AssertEquals(VATAmount);
        SalesStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatsQuotePageHandler(var SalesStats: TestPage "Sales Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesStats.TaxAmount.AssertEquals(TaxAmount);
        SalesStats.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatsQuoteNonModalPageHandler(var SalesStats: TestPage "Sales Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesStats.TaxAmount.AssertEquals(TaxAmount);
        SalesStats.OK().Invoke();
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsPageHandler(var SalesInvoiceStatistics: TestPage "Sales Invoice Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesInvoiceStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesInvoiceStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatsPageHandler(var SalesInvoiceStats: TestPage "Sales Invoice Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesInvoiceStats.Subform."Tax Amount".AssertEquals(TaxAmount);
        SalesInvoiceStats.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsPageHandlerNM(var SalesInvoiceStatistics: TestPage "Sales Invoice Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesInvoiceStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesInvoiceStatistics.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatsPageHandlerNM(var SalesInvoiceStats: TestPage "Sales Invoice Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesInvoiceStats.Subform."Tax Amount".AssertEquals(TaxAmount);
        SalesInvoiceStats.OK().Invoke();
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoStatisticsPageHandler(var SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesCreditMemoStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesCreditMemoStatistics.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoStatsPageHandler(var SalesCreditMemoStats: TestPage "Sales Credit Memo Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesCreditMemoStats.Subform."Tax Amount".AssertEquals(TaxAmount);
        SalesCreditMemoStats.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoStatisticsPageHandlerNM(var SalesCreditMemoStatistics: TestPage "Sales Credit Memo Statistics")
    var
        VATAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(VATAmount);
        SalesCreditMemoStatistics.Subform."VAT Amount".AssertEquals(VATAmount);
        SalesCreditMemoStatistics.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesCreditMemoStatsPageHandlerNM(var SalesCreditMemoStats: TestPage "Sales Credit Memo Stats.")
    var
        TaxAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(TaxAmount);
        SalesCreditMemoStats.Subform."Tax Amount".AssertEquals(TaxAmount);
        SalesCreditMemoStats.OK().Invoke();
    end;
}
