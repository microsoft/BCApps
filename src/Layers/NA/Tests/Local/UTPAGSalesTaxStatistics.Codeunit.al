codeunit 141018 "UT PAG Sales Tax Statistics"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Statistics] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        AmountMustEqualMsg: Label 'Amount must be equal';
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERMTax: Codeunit "Library - ERM Tax";

    [Test]
    [Scope('OnPrem')]
    procedure FieldPositiveInSalesTaxAmountLineIsSetToTrue()
    var
        SalesTaxAmountLine: Record "Sales Tax Amount Line";
        TaxAreaLine: Record "Tax Area Line";
        TaxArea: Record "Tax Area";
        TaxJurisdiction: Record "Tax Jurisdiction";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
        SalesLineType: Enum "Sales Line Type";
        TaxCountry: Enum "Sales Tax Country";
        ExchangeFactor: Decimal;
    begin
        // [SCENARIO] The field Positive in the table "Sales Tax Amount Line" is correctly updated to true based on the value of the field LineAmount

        // [GIVEN] All the tables and parameters required by the method CalcSalesOrServLineSalesTaxAmountLine
        SalesTaxAmountLine.DeleteAll();
        SalesTaxAmountLine."Tax Area Code" := 'CA';
        SalesTaxAmountLine."Tax Jurisdiction Code" := 'CA';
        SalesTaxAmountLine."Tax %" := 10;
        SalesTaxAmountLine."Use Tax" := true;
        SalesTaxAmountLine."Tax Type" := SalesTaxAmountLine."Tax Type"::"Sales and Use Tax";
        SalesTaxAmountLine."Tax Area Code for Key" := 'CA';
        SalesTaxAmountLine."Expense/Capitalize" := true;
        SalesTaxAmountLine.Positive := false;
        SalesTaxAmountLine."Line Amount" := 100;
        SalesTaxAmountLine.Insert();

        TaxAreaLine.DeleteAll();
        TaxAreaLine."Tax Area" := 'CA';
        TaxAreaLine."Tax Jurisdiction Code" := 'CA';
        TaxAreaLine.Insert();

        TaxArea.DeleteAll();
        TaxArea.Code := 'CA';
        TaxArea.Insert();

        TaxJurisdiction.DeleteAll();
        TaxJurisdiction.Code := 'CA';
        TaxJurisdiction.Insert();

        SalesInvoiceLine.DeleteAll();
        SalesInvoiceLine."Document No." := '1234';
        SalesInvoiceLine."Line No." := 1;
        SalesInvoiceLine.Type := SalesLineType::Item;
        SalesInvoiceLine."Tax Area Code" := 'CA';
        SalesInvoiceLine."Tax Group Code" := 'CA';
        SalesInvoiceLine."VAT Base Amount" := 10;
        SalesInvoiceLine."Line Amount" := 100;
        SalesInvoiceLine."Quantity (Base)" := 1;
        SalesInvoiceLine."Tax Liable" := true;
        SalesInvoiceLine.Insert();

        ExchangeFactor := 1;

        // [WHEN] The variable LineType in the codeunit SalesTaxAmountLineCalc is properly initialized
        // [WHEN] Running the method CalcSalesTaxAmountLine to properly update the field Positive in the SalesTaxAmountLine table
        SalesTaxCalculate.CalcSalesTaxAmountLine(
            SalesTaxAmountLine, TaxCountry, ExchangeFactor,
            SalesInvoiceLine."Tax Area Code", SalesInvoiceLine."Tax Group Code", SalesInvoiceLine.Type.AsInteger(),
            SalesInvoiceLine."Line Amount", SalesInvoiceLine."VAT Base Amount", SalesInvoiceLine."Quantity (Base)",
            SalesInvoiceLine."Posting Date", SalesInvoiceLine."Tax Liable", false, "Sales Tax Document Area"::"Posted Sale");

        // [THEN] The field Positive in the SalesTaxAmountLine table is properly updated
        Assert.AreEqual(true, SalesTaxAmountLine.Positive, 'The field Positive in the table SalesTaxAmountLine should be true');
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsServiceCreditMemos()
    var
        ServiceLine: Record "Service Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9320, Service Credit Memos without Tax Area.

        // Setup: Create Service Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo", '', '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := ServiceLine.Quantity * ServiceLine."Unit Price" * ServiceLine."VAT %" / 100;
        AmountIncVAT := ServiceLine.Quantity * ServiceLine."Unit Price" + VATAmount;

        // Enqueue values for use in ServiceStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page Service Credit Memos and verify the VAT Amount and Amount Incl. VAT on Statistics page in ServiceStatisticsPageHandler.
        OpenStatisticsPageForServiceCreditMemo(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaServiceCreditMemos()
    var
        TaxDetail: Record "Tax Detail";
        ServiceLine: Record "Service Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9320, Service Credit Memos with Tax Area.

        // Setup: Create Tax Setup and Service Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := ServiceLine.Quantity * ServiceLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := ServiceLine.Quantity * ServiceLine."Unit Price" + TaxAmount;

        // Enqueue values for use in ServiceStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Page Service Credit Memos and verify the Tax Amount and Amount Incl. Tax on Statistics page in ServiceStatsPageHandler.
        OpenStatisticsPageForServiceCreditMemo(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsServiceCreditMemosNM()
    var
        ServiceLine: Record "Service Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9320, Service Credit Memos without Tax Area.

        // Setup: Create Service Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo", '', '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := ServiceLine.Quantity * ServiceLine."Unit Price" * ServiceLine."VAT %" / 100;
        AmountIncVAT := ServiceLine.Quantity * ServiceLine."Unit Price" + VATAmount;

        // Enqueue values for use in ServiceStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page Service Credit Memos and verify the VAT Amount and Amount Incl. VAT on Statistics page in ServiceStatisticsPageHandler.
        OpenStatisticsPageForServiceCreditMemoNM(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [HandlerFunctions('ServiceStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaServiceCreditMemosNM()
    var
        TaxDetail: Record "Tax Detail";
        ServiceLine: Record "Service Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9320, Service Credit Memos with Tax Area.

        // Setup: Create Tax Setup and Service Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::"Credit Memo", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);  // Tax Liable TRUE.
        TaxAmount := ServiceLine.Quantity * ServiceLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := ServiceLine.Quantity * ServiceLine."Unit Price" + TaxAmount;

        // Enqueue values for use in ServiceStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Page Service Credit Memos and verify the Tax Amount and Amount Incl. Tax on Statistics page in ServiceStatsPageHandler.
        OpenStatsPageForServiceCreditMemoNM(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesQuotes()
    var
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9300, Sales Quotes without Tax Area.

        // Setup: Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, '', '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page on Sales Quotes and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenStatisticsPageForSalesQuote(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesQuotesStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesQuotes()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9300, Sales Quotes with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesQuotesStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Quotes and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesQuotesStatsPageHandler.
        OpenStatisticsPageForSalesQuote(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderList()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9305, Sales Order List without Tax Area.

        // Setup: Create a Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Order List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesOrderList()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9305, Sales Order List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics Sales Order List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesInvoiceList()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9301, Sales Invoice List without Tax Area.

        // Setup: Create a Sales Invoice. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Invoice List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenStatisticsPageForSalesInvoice(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesInvoiceList()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9301, Sales Invoice List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Invoice. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Invoice List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesInvoice(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsBlanketSalesOrders()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9303, Blanket Sales Orders without Tax Area.

        // Setup: Create a Blanket Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Blanket Sales Orders and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaBlanketSalesOrders()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9303, Blanket Sales Orders with Tax Area.

        // Setup: Create Tax Setup. Create a Blanket Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Blanket Sales Orders and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesReturnOrderList()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9304, Sales Return Order List without Tax Area.

        // Setup: Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenStatisticsPageForSalesReturnOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesReturnOrderList()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9304, Sales Return Order List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesReturnOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesCreditMemos()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9302, Sales Credit Memos without Tax Area.

        // Setup: Create a Sales Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Credit Memos and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenStatisticsPageForSalesCreditMemo(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesCreditMemos()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9302, Sales Credit Memos with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Credit Memos and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenStatisticsPageForSalesCreditMemo(SalesLine."Document No.");
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesQuotesNM()
    var
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9300, Sales Quotes without Tax Area.

        // Setup: Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, '', '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Page on Sales Quotes and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenSalesStatisticsPageForSalesQuote(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesQuotesStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesQuotesNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9300, Sales Quotes with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Quote. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Quote, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesQuotesStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Page Sales Quotes and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesQuotesStatsPageHandler.
        OpenSalesStatsPageForSalesQuote(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderListNM()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9305, Sales Order List without Tax Area.

        // Setup: Create a Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Order List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenSalesOrderStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesOrderListNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9305, Sales Order List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics Sales Order List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenSalesOrderStatsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesInvoiceListNM()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9301, Sales Invoice List without Tax Area.

        // Setup: Create a Sales Invoice. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Invoice List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenSalesStatisticsPageForSalesInvoice(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesInvoiceListNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9301, Sales Invoice List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Invoice. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice, TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Invoice List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenSalesOrderStatsPageForSalesInvoice(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsBlanketSalesOrdersNM()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9303, Blanket Sales Orders without Tax Area.

        // Setup: Create a Blanket Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Blanket Sales Orders and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenSalesOrderStatisticsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaBlanketSalesOrdersNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9303, Blanket Sales Orders with Tax Area.

        // Setup: Create Tax Setup. Create a Blanket Sales Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Blanket Order", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Blanket Sales Orders and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenSalesOrderStatsPageForBlanketSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesReturnOrderListNM()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9304, Sales Return Order List without Tax Area.

        // Setup: Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order List and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesOrderStatisticsPageHandler.
        OpenSalesOrderStatisticsPageForSalesReturnOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesReturnOrderListNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9304, Sales Return Order List with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Return Order. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Return Order List and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenSalesOrderStatsPageForSalesReturnOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesCreditMemosNM()
    var
        SalesLine: Record "Sales Line";
        TaxGroup: Record "Tax Group";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9302, Sales Credit Memos without Tax Area.

        // Setup: Create a Sales Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", TaxGroup.Code, '', false);  // Blank Tax Area and Tax Liable FALSE.
        VATAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100;
        AmountIncVAT := SalesLine.Quantity * SalesLine."Unit Price" + VATAmount;

        // Enqueue values for use in SalesStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise & Verify: Invokes Action - Statistics on Sales Credit Memos and verify the VAT Amount and Amount Incl. VAT on Statistics page in SalesStatisticsPageHandler.
        OpenSalesStatisticsPageForSalesCreditMemo(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaSalesCreditMemosNM()
    var
        TaxDetail: Record "Tax Detail";
        SalesLine: Record "Sales Line";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction trigger of the Page ID: 9302, Sales Credit Memos with Tax Area.

        // Setup: Create Tax Setup, Create a Sales Credit Memo. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Credit Memo", TaxDetail."Tax Group Code", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), true);  // Tax Liable TRUE.
        TaxAmount := SalesLine.Quantity * SalesLine."Unit Price" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := SalesLine.Quantity * SalesLine."Unit Price" + TaxAmount;

        // Enqueue values for use in SalesOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise & Verify: Invokes Action - Statistics on Sales Credit Memos and verify the Tax Amount and Amount Incl. Tax on Statistics page in SalesOrderStatsPageHandler.
        OpenSalesOrderStatsPageForSalesCreditMemo(SalesLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9307 Purchase Order List.

        // Setup: Create Purchase Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Order List and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchaseOrder(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9307 Purchase Order List.

        // Setup: Create Purchase Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Order List and verify VAT Amount and Amount Inclusive VAT on PurchOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchaseOrderStatistics(PurchaseLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchReturnOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9311 Purchase Return Order List.

        // Setup: Create Purchase Return Order with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseOrderStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order List and verify Tax Amount and Amount Inclusive Tax on PurchaseOrderStatsPageHandler.
        OpenStatsPageForPurchReturnOrder(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseReturnOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9311 Purchase Return Order List.

        // Setup: Create Purchase Return Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order List and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchaseReturnOrder(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchReturnOrderList()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9311 Purchase Return Order List.

        // Setup: Create Purchase Return Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Return Order List and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForPurchReturnOrder(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsBlanketPurchaseOrders()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9310 Blanket Purchase Order List.

        // Setup: Create Blanket Purchase Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Blanket Order", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Blanket Purchase Order List and verify VAT Amount and Amount Inclusive VAT on PurchaseOrderStatisticsPageHandler.
        OpenStatisticsPageForBlanketPurchaseOrder(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsBlanketPurchOrders()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9310 Blanket Purchase Order List.

        // Setup: Create Blanket Purchase Order without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Blanket Order", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchOrderStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Blanket Purchase Order List and verify VAT Amount and Amount Inclusive VAT on PurchOrderStatisticsPageHandler.
        OpenPurchaseOrderStatisticsPageForBlanketPurchaseOrder(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseQuotes()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9306 Purchase Quotes.

        // Setup: Create Purchase Quote with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Quote, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Quotes and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatisticsPageForPurchaseQuote(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchQuotes()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9306 Purchase Quotes.

        // Setup: Create Purchase Quote with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Quote, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Quotes and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatsPageForPurchQuote(PurchaseLine."Document No.");
    end;


#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseQuotes()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9306 Purchase Quotes.

        // Setup: Create Purchase Quote without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Quote, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Quotes and verify VAT Amount and Amount Inclusive VAT on PurchaseStatisticsPageHandler.
        OpenPurchaseStatisticsPageForPurchaseQuote(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchQuotes()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9306 Purchase Quotes.

        // Setup: Create Purchase Quote without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Quote, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Quotes and verify VAT Amount and Amount Inclusive VAT on PurchaseStatisticsPageHandler.
        OpenStatisticsPageForPurchQuote(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseCreditMemos()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9309 Purchase Credit Memos.

        // Setup: Create Purchase Credit Memo with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Credit Memos and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatisticsPageForPurchaseCreditMemo(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchCreditMemos()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9309 Purchase Credit Memos.

        // Setup: Create Purchase Credit Memo with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Credit Memos and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatisticsPageForPurchCreditMemo(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseCreditMemos()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9309 Purchase Credit Memos.

        // Setup: Create Purchase Credit Memo without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Credit Memos and verify VAT Amount and Amount Inclusive VAT on PurchaseStatisticsPageHandler.
        OpenStatisticsPageForPurchaseCreditMemo(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchCreditMemos()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9309 Purchase Credit Memos.

        // Setup: Create Purchase Credit Memo without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Credit Memos and verify VAT Amount and Amount Inclusive VAT on PurchStatisticsPageHandler.
        OpenPurchaseStatisticsPageForPurchaseCreditMemo(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchaseInvoices()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9308 Purchase Invoices.

        // Setup: Create Purchase Invoice with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Invoices and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatisticsPageForPurchaseInvoice(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaPurchInvoices()
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9308 Purchase Invoices.

        // Setup: Create Purchase Invoice with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := PurchaseLine."Line Amount" * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + TaxAmount;

        // Enqueue required inside PurchaseStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Invoices and verify Tax Amount and Amount Inclusive Tax on PurchaseStatsPageHandler.
        OpenStatisticsPageForPurchInvoice(PurchaseLine."Document No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchaseInvoices()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9308 Purchase Invoices.

        // Setup: Create Purchase Invoice without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."VAT %" * PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchaseStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Invoices and verify VAT Amount and Amount Inclusive VAT on PurchaseStatisticsPageHandler.
        OpenStatisticsPageForPurchaseInvoice(PurchaseLine."Document No.");
    end;
#endif

    [Test]
    [HandlerFunctions('PurchStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsPurchInvoices()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9308 Purchase Invoices.

        // Setup: Create Purchase Invoice without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := PurchaseLine."VAT %" * PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity / 100;
        AmountIncVAT := PurchaseLine."Direct Unit Cost" * PurchaseLine.Quantity + VATAmount;

        // Enqueue required inside PurchStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Purchase Invoices and verify VAT Amount and Amount Inclusive VAT on PurchStatisticsPageHandler.
        OpenPurchaseStatisticsPageForPurchaseInvoice(PurchaseLine."Document No.");
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceStatsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaServiceInvoices()
    var
        ServiceLine: Record "Service Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9319 Service Invoices.

        // Setup: Create Service Invoice with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := ServiceLine."Unit Price" * ServiceLine.Quantity + TaxAmount;

        // Enqueue required inside ServiceStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Service Invoices and verify Tax Amount and Amount Inclusive Tax on ServiceStatsPageHandler.
        OpenStatisticsPageForServiceInvoice(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsServiceInvoices()
    var
        ServiceLine: Record "Service Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9319 Service Invoices.

        // Setup: Create Service Invoice without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * ServiceLine."VAT %" / 100;
        AmountIncVAT := ServiceLine."Unit Price" * ServiceLine.Quantity + VATAmount;

        // Enqueue required inside ServiceStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Service Invoices and verify VAT Amount and Amount Inclusive VAT on ServiceStatisticsPageHandler.
        OpenStatisticsPageForServiceInvoice(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsWithTaxAreaServiceInvoicesNM()
    var
        ServiceLine: Record "Service Line";
        TaxDetail: Record "Tax Detail";
        TaxAmount: Decimal;
        AmountIncTax: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9319 Service Invoices.

        // Setup: Create Service Invoice with Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateTaxDetail(TaxDetail, CreateTaxGroup(), LibraryRandom.RandDec(10, 2));
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice, CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code"), TaxDetail."Tax Group Code", true);
        TaxAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * TaxDetail."Tax Below Maximum" / 100;
        AmountIncTax := ServiceLine."Unit Price" * ServiceLine.Quantity + TaxAmount;

        // Enqueue required inside ServiceStatsPageHandler.
        LibraryVariableStorage.Enqueue(TaxAmount);
        LibraryVariableStorage.Enqueue(AmountIncTax);

        // Exercise and Verify: Invokes Action - Statistics on Page Service Invoices and verify Tax Amount and Amount Inclusive Tax on ServiceStatsPageHandler.
        OpenStatsPageForServiceInvoiceNM(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

    [Test]
    [HandlerFunctions('ServiceStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsServiceInvoicesNM()
    var
        ServiceLine: Record "Service Line";
        VATAmount: Decimal;
        AmountIncVAT: Decimal;
        OldInvoiceRounding: Boolean;
    begin
        // Purpose of the test is to validate Statistics - OnAction Trigger of Page ID - 9319 Service Invoices.

        // Setup: Create Service Invoice without Tax Area Code. The Transaction Model is AutoCommit for explicit commit used in On Action - Statistics trigger.
        Initialize();
        OldInvoiceRounding := UpdateInvoiceRoundingOnSalesReceivablesSetup(false);  // Update Invoice Rounding to FALSE on Sales & Receivables Setup.
        CreateServiceDocument(ServiceLine, ServiceLine."Document Type"::Invoice, '', '', false);  // Blank for Tax Area Code and Tax Group Code, Tax Liable - FALSE.
        VATAmount := ServiceLine."Unit Price" * ServiceLine.Quantity * ServiceLine."VAT %" / 100;
        AmountIncVAT := ServiceLine."Unit Price" * ServiceLine.Quantity + VATAmount;

        // Enqueue required inside ServiceStatisticsPageHandler.
        LibraryVariableStorage.Enqueue(VATAmount);
        LibraryVariableStorage.Enqueue(AmountIncVAT);

        // Exercise and Verify: Invokes Action - Statistics on Page Service Invoices and verify VAT Amount and Amount Inclusive VAT on ServiceStatisticsPageHandler.
        OpenStatisticsPageForServiceInvoiceNM(ServiceLine."Document No.");

        // Tear Down.
        UpdateInvoiceRoundingOnSalesReceivablesSetup(OldInvoiceRounding);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: array[2] of Record "Tax Detail";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 375493] Statistics for Sales Order shows correct Tax Amount when complex fractional tax percents present for Tax Area.

        // [GIVEN] Tax Area with two Tax Jurisdictions, each with fractional tax percents: 6.875 % and 0.25 %.
        Initialize();
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail[1], TaxGroupCode, 6.875); // specific value needed for test
        CreateTaxDetail(TaxDetail[2], TaxGroupCode, 0.25); // specific value needed for test
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail[1]."Tax Jurisdiction Code");
        CreateTaxAreaLine(TaxAreaCode, TaxDetail[2]."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with Tax Area and Unit Price = 75
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1, TaxGroupCode, TaxAreaCode, true, 0, 75, 75); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 5.34
        LibraryVariableStorage.Enqueue(5.34); // specific value for SalesOrderStatsPageHandler2 verification
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderThreeTaxAreas()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 375322] Statistics for Sales Order shows correct Tax Amount when there are three Tax Area with fractional tax Amounts.

        // [GIVEN] Three Tax Areas with with tax percents: 10 %.
        Initialize();
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail, TaxGroupCode, 10); // specific value needed for test
        for i := 1 to 3 do
            TaxAreaCode[i] := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with three lines with Tax Areas, each Unit Price = 13.333
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode[1]);
        for i := 1 to 3 do
            CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, '', 1, TaxGroupCode, TaxAreaCode[i], true, 0, 13.333, 13.333); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 4 (13.333 * 10% * 3 => 3.9999, rounded to 4.00)
        LibraryVariableStorage.Enqueue(4); // specific value for SalesOrderStatsPageHandler2 verification
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderCanadaRounding()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: Record "Tax Area";
        TaxDetail: array[2] of Record "Tax Detail";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 381348] Statistics for Sales Order shows correct Tax Amount by rounding each Sales Tax Line per Tax Jurisdiction

        // [GIVEN] Tax Area with two Tax Jurisdictions for Country/Region = "CA", each with fractional tax percents: 6.875 % and 0.25 %.
        Initialize();
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail[1], TaxGroupCode, 6.875); // specific value needed for test
        CreateTaxDetail(TaxDetail[2], TaxGroupCode, 0.25); // specific value needed for test
        TaxAreaCode := CreateTaxAreaWithSpecificCountryRegionAndLine(TaxDetail[1]."Tax Jurisdiction Code", TaxArea."Country/Region"::CA);
        CreateTaxAreaLine(TaxAreaCode, TaxDetail[2]."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with Tax Area and Unit Price = 75
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1, TaxGroupCode, TaxAreaCode, true, 0, 75, 75); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 5.35 (75 * 6.875 / 100 = 5.15625 (rounded = 5.16); 75 * 0.25 / 100 = 0.1875 (rounded = 0.19); Total = 5.16 + 0.19 = 5.35)
        LibraryVariableStorage.Enqueue(5.35); // specific value for SalesOrderStatsPageHandler2 verification
        OpenStatisticsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesInvoiceWithPositiveAndNegativeAmounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 318205] Statistics for Sales Invoice with positive and negative Line Amounts shows correct Tax Amount.
        Initialize();

        // [GIVEN] Tax setup with Tax Detail having "Tax Below Maximum" := 1, "Maximum Amount/Qty." = 5000.
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail, TaxGroupCode, 1);
        TaxDetail."Maximum Amount/Qty." := 5000;
        TaxDetail.Modify();
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        // [GIVEN] G/L Account with Tax setup.
        GLAccountNo := CreateGLAccountWithTaxGroup(TaxGroupCode);

        // [GIVEN] Sales Invoice with:
        // [GIVEN] Sales Line with Type = "Item", Qty = 1, Amount = 6000;
        // [GIVEN] Sales Line with Type = "G/L Account"", Qty = -1, Amount = 1000.
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1, TaxGroupCode, TaxAreaCode, true, 0, 6000, 6000);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, -1, TaxGroupCode, TaxAreaCode, true, 0, 1000, 1000);

        // [WHEN] Statistics opened for Sales Invoice.
        // [THEN] On Statistics page: Tax Amount = 50 ((6000 - 1000) / 100 = 50)
        LibraryVariableStorage.Enqueue(50);
        OpenStatisticsPageForSalesInvoice(SalesHeader."No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPH,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesIncreasePositive()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Increasing of the Sales Tax Difference for the positive tax line
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 1010 for the positive line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLines(SalesHeaderNo, 10, 1000, 10, -100, 10, 0);

        // [THEN] Positive Tax Line: Tax% = 10.1, Tax Amount = 1010
        // [THEN] Negative Tax Line: Tax% = 10, Tax Amount = -100
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 1);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 10.1, 10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPH,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesDecreasePositive()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Decreasing of the Sales Tax Difference for the positive tax line
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 990 for the positive line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLines(SalesHeaderNo, 10, 1000, 10, -100, -10, 0);

        // [THEN] Positive Tax Line: Tax% = 9.9, Tax Amount = 990
        // [THEN] Negative Tax Line: Tax% = 10, Tax Amount = -100
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 1);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 9.9, -10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPH,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesIncreaseNegative()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Increasing of the Sales Tax Difference for the negative tax line
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = -90 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLines(SalesHeaderNo, 10, 1000, 10, -100, 0, 10);

        // [THEN] Positive Tax Line: Tax% = 10, Tax Amount = 1000
        // [THEN] Negative Tax Line: Tax% = 9, Tax Amount = -90
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 1);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -9, 10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPH,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesDecreasingNegative()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Decreasing of the Sales Tax Difference for the negative tax line
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = -110 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLines(SalesHeaderNo, 10, 1000, 10, -100, 0, -10);

        // [THEN] Positive Tax Line: Tax% = 10, Tax Amount = 1000
        // [THEN] Negative Tax Line: Tax% = 11, Tax Amount = -110
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 1);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -11, -10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPH,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesIncreaseBoth()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Increasing of the Sales Tax Difference for both tax lines
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 1005 for the positive line, -95 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLines(SalesHeaderNo, 10, 1000, 10, -100, 5, 5);

        // [THEN] Positive Tax Line: Tax% = 10.05, Tax Amount = 1005
        // [THEN] Negative Tax Line: Tax% = 9.5, Tax Amount = -95
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 2);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 10.05, 5);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -9.5, 5);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPH,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesDecreaseBoth()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Decreasing of the Sales Tax Difference for both tax lines
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 995 for the positive line, -105 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLines(SalesHeaderNo, 10, 1000, 10, -100, -5, -5);

        // [THEN] Positive Tax Line: Tax% = 9.95, Tax Amount = 995
        // [THEN] Negative Tax Line: Tax% = 9.5, Tax Amount = -95
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 2);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 9.95, -5);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -10.5, -5);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPH,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesMix()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Changing of the Sales Tax Difference for both tax lines
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 1005 for the positive line, -105 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLines(SalesHeaderNo, 10, 1000, 10, -100, 5, -5);

        // [THEN] Positive Tax Line: Tax% = 10.05, Tax Amount = 1005
        // [THEN] Negative Tax Line: Tax% = 10.5, Tax Amount = -105
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 2);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 10.05, 5);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -10.5, -5);
        LibraryVariableStorage.AssertEmpty();
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2NM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: array[2] of Record "Tax Detail";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 375493] Statistics for Sales Order shows correct Tax Amount when complex fractional tax percents present for Tax Area.

        // [GIVEN] Tax Area with two Tax Jurisdictions, each with fractional tax percents: 6.875 % and 0.25 %.
        Initialize();
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail[1], TaxGroupCode, 6.875); // specific value needed for test
        CreateTaxDetail(TaxDetail[2], TaxGroupCode, 0.25); // specific value needed for test
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail[1]."Tax Jurisdiction Code");
        CreateTaxAreaLine(TaxAreaCode, TaxDetail[2]."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with Tax Area and Unit Price = 75
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1, TaxGroupCode, TaxAreaCode, true, 0, 75, 75); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 5.34
        LibraryVariableStorage.Enqueue(5.34); // specific value for SalesOrderStatsPageHandler2 verification
        OpenSalesOrderStatsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2NM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderThreeTaxAreasNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: array[3] of Code[20];
        TaxGroupCode: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 375322] Statistics for Sales Order shows correct Tax Amount when there are three Tax Area with fractional tax Amounts.

        // [GIVEN] Three Tax Areas with with tax percents: 10 %.
        Initialize();
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail, TaxGroupCode, 10); // specific value needed for test
        for i := 1 to 3 do
            TaxAreaCode[i] := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with three lines with Tax Areas, each Unit Price = 13.333
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode[1]);
        for i := 1 to 3 do
            CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, '', 1, TaxGroupCode, TaxAreaCode[i], true, 0, 13.333, 13.333); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 4 (13.333 * 10% * 3 => 3.9999, rounded to 4.00)
        LibraryVariableStorage.Enqueue(4); // specific value for SalesOrderStatsPageHandler2 verification
        OpenSalesOrderStatsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2NM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesOrderCanadaRoundingNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: Record "Tax Area";
        TaxDetail: array[2] of Record "Tax Detail";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 381348] Statistics for Sales Order shows correct Tax Amount by rounding each Sales Tax Line per Tax Jurisdiction

        // [GIVEN] Tax Area with two Tax Jurisdictions for Country/Region = "CA", each with fractional tax percents: 6.875 % and 0.25 %.
        Initialize();
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail[1], TaxGroupCode, 6.875); // specific value needed for test
        CreateTaxDetail(TaxDetail[2], TaxGroupCode, 0.25); // specific value needed for test
        TaxAreaCode := CreateTaxAreaWithSpecificCountryRegionAndLine(TaxDetail[1]."Tax Jurisdiction Code", TaxArea."Country/Region"::CA);
        CreateTaxAreaLine(TaxAreaCode, TaxDetail[2]."Tax Jurisdiction Code");

        // [GIVEN] Sales Order with Tax Area and Unit Price = 75
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1, TaxGroupCode, TaxAreaCode, true, 0, 75, 75); // specific values needed for test

        // [WHEN] Statistics opened for Sales Order
        // [THEN] On Statistics page: Tax Amount = 5.35 (75 * 6.875 / 100 = 5.15625 (rounded = 5.16); 75 * 0.25 / 100 = 0.1875 (rounded = 0.19); Total = 5.16 + 0.19 = 5.35)
        LibraryVariableStorage.Enqueue(5.35); // specific value for SalesOrderStatsPageHandler2 verification
        OpenSalesOrderStatsPageForSalesOrder(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler2NM')]
    [Scope('OnPrem')]
    procedure OnActionStatisticsSalesInvoiceWithPositiveAndNegativeAmountsNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 318205] Statistics for Sales Invoice with positive and negative Line Amounts shows correct Tax Amount.
        Initialize();

        // [GIVEN] Tax setup with Tax Detail having "Tax Below Maximum" := 1, "Maximum Amount/Qty." = 5000.
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail, TaxGroupCode, 1);
        TaxDetail."Maximum Amount/Qty." := 5000;
        TaxDetail.Modify();
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        // [GIVEN] G/L Account with Tax setup.
        GLAccountNo := CreateGLAccountWithTaxGroup(TaxGroupCode);

        // [GIVEN] Sales Invoice with:
        // [GIVEN] Sales Line with Type = "Item", Qty = 1, Amount = 6000;
        // [GIVEN] Sales Line with Type = "G/L Account"", Qty = -1, Amount = 1000.
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', 1, TaxGroupCode, TaxAreaCode, true, 0, 6000, 6000);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, -1, TaxGroupCode, TaxAreaCode, true, 0, 1000, 1000);

        // [WHEN] Statistics opened for Sales Invoice.
        // [THEN] On Statistics page: Tax Amount = 50 ((6000 - 1000) / 100 = 50)
        LibraryVariableStorage.Enqueue(50);
        OpenSalesOrderStatsPageForSalesInvoice(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPHNM,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesIncreasePositiveNM()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Increasing of the Sales Tax Difference for the positive tax line
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 1010 for the positive line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLinesNM(SalesHeaderNo, 10, 1000, 10, -100, 10, 0);

        // [THEN] Positive Tax Line: Tax% = 10.1, Tax Amount = 1010
        // [THEN] Negative Tax Line: Tax% = 10, Tax Amount = -100
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 1);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 10.1, 10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPHNM,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesDecreasePositiveNM()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Decreasing of the Sales Tax Difference for the positive tax line
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 990 for the positive line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLinesNM(SalesHeaderNo, 10, 1000, 10, -100, -10, 0);

        // [THEN] Positive Tax Line: Tax% = 9.9, Tax Amount = 990
        // [THEN] Negative Tax Line: Tax% = 10, Tax Amount = -100
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 1);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 9.9, -10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPHNM,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesIncreaseNegativeNM()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Increasing of the Sales Tax Difference for the negative tax line
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = -90 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLinesNM(SalesHeaderNo, 10, 1000, 10, -100, 0, 10);

        // [THEN] Positive Tax Line: Tax% = 10, Tax Amount = 1000
        // [THEN] Negative Tax Line: Tax% = 9, Tax Amount = -90
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 1);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -9, 10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPHNM,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesDecreasingNegativeNM()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Decreasing of the Sales Tax Difference for the negative tax line
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = -110 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLinesNM(SalesHeaderNo, 10, 1000, 10, -100, 0, -10);

        // [THEN] Positive Tax Line: Tax% = 10, Tax Amount = 1000
        // [THEN] Negative Tax Line: Tax% = 11, Tax Amount = -110
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 1);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -11, -10);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPHNM,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesIncreaseBothNM()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Increasing of the Sales Tax Difference for both tax lines
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 1005 for the positive line, -95 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLinesNM(SalesHeaderNo, 10, 1000, 10, -100, 5, 5);

        // [THEN] Positive Tax Line: Tax% = 10.05, Tax Amount = 1005
        // [THEN] Negative Tax Line: Tax% = 9.5, Tax Amount = -95
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 2);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 10.05, 5);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -9.5, 5);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPHNM,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesDecreaseBothNM()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Decreasing of the Sales Tax Difference for both tax lines
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 995 for the positive line, -105 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLinesNM(SalesHeaderNo, 10, 1000, 10, -100, -5, -5);

        // [THEN] Positive Tax Line: Tax% = 9.95, Tax Amount = 995
        // [THEN] Negative Tax Line: Tax% = 9.5, Tax Amount = -95
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 2);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 9.95, -5);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -10.5, -5);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatsInvokeInvVATLinesMPHNM,SalesTaxLinesSubformDynPosNegLinesMPH')]
    procedure SalesTaxDiffPosAndNegLinesMixNM()
    var
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Tax Difference]
        // [SCENAIRO 377669] Changing of the Sales Tax Difference for both tax lines
        // [SCENAIRO 377669] in case of sales invoice with both positive and negative tax lines
        Initialize();

        // [GIVEN] Allowed max tax difference = 10
        LibraryERM.SetMaxVATDifferenceAllowed(10);
        LibrarySales.SetAllowVATDifference(true);

        // [GIVEN] Sales invoice with tax 10% and 2 lines: qty = 1, unit price = 10000, qty = -1, unit price = 1000
        SalesHeaderNo := PapareSalesInvoiceWithNegAndPosLines(10, 10000, 1000);

        // [GIVEN] Open Tax lines from statistics and set Tax Amount = 1005 for the positive line, -105 for the negative line, close statistics
        // [WHEN] Open Tax lines from statistics again
        UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLinesNM(SalesHeaderNo, 10, 1000, 10, -100, 5, -5);

        // [THEN] Positive Tax Line: Tax% = 10.05, Tax Amount = 1005
        // [THEN] Negative Tax Line: Tax% = 10.5, Tax Amount = -105
        VerifySalesTaxAmountDifferenceCount(SalesHeaderNo, 2);
        VerifySalesTaxAmountDifference(SalesHeaderNo, true, 10.05, 5);
        VerifySalesTaxAmountDifference(SalesHeaderNo, false, -10.5, -5);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure PapareSalesInvoiceWithNegAndPosLines(TaxPct: Decimal; LineAmountPos: Decimal; LineAmountNeg: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
        GLAccountNo: Code[20];
    begin
        TaxGroupCode := CreateTaxGroup();
        CreateTaxDetail(TaxDetail, TaxGroupCode, TaxPct);
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail."Tax Jurisdiction Code");

        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, TaxAreaCode);
        GLAccountNo := CreateGLAccountWithTaxGroup(TaxGroupCode);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1, TaxGroupCode, TaxAreaCode, true, 0, LineAmountPos, LineAmountPos);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, -1, TaxGroupCode, TaxAreaCode, true, 0, LineAmountNeg, LineAmountNeg);
        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, TaxAreaCode);
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 2),
          TaxGroupCode, TaxAreaCode, TaxLiable, LibraryRandom.RandInt(3), LibraryRandom.RandDec(2, 2),
          LibraryRandom.RandDec(2, 2));
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20])
    begin
        SalesHeader."Document Type" := DocumentType;
        SalesHeader."No." := LibraryUTUtility.GetNewCode();
        SalesHeader."Tax Area Code" := TaxAreaCode;
        SalesHeader.Status := SalesHeader.Status::Released;
        SalesHeader.Insert();
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineType: Enum "Sales Line Type"; No: Code[20]; Qty: Decimal; TaxGroupCode: Code[20]; TaxAreaCode: Code[20]; TaxLiable: Boolean; VATPct: Decimal; UnitPrice: Decimal; LineAmount: Decimal)
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        //if SalesLine.FindLast() then;

        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." += 10000;
        SalesLine.Type := LineType;
        SalesLine."No." := No;
        SalesLine.Quantity := Qty;
        SalesLine."Qty. to Invoice" := Qty;
        SalesLine."Tax Group Code" := TaxGroupCode;
        SalesLine."Tax Area Code" := TaxAreaCode;
        SalesLine."Tax Liable" := TaxLiable;
        SalesLine."VAT %" := VATPct;
        SalesLine."Unit Price" := UnitPrice;
        SalesLine."Line Amount" := LineAmount;
        SalesLine.Amount := LineAmount;
        SalesLine.Insert();
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
        ServiceHeader."Tax Area Code" := TaxAreaCode;
        ServiceHeader.Insert();

        ServiceLine."Document Type" := ServiceHeader."Document Type";
        ServiceLine."Document No." := ServiceHeader."No.";
        ServiceLine."Line No." := LibraryRandom.RandInt(100);
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."Unit Price" := LibraryRandom.RandDec(10, 2);
        ServiceLine.Quantity := LibraryRandom.RandDec(10, 2);
        ServiceLine."Tax Area Code" := TaxAreaCode;
        ServiceLine."Tax Group Code" := TaxGroupCode;
        ServiceLine."Tax Liable" := TaxLiable;
        ServiceLine."VAT %" := LibraryRandom.RandInt(10);
        ServiceLine.Insert();
    end;

    local procedure CreateTaxAreaWithSpecificCountryRegionAndLine(TaxJurisdictionCode: Code[10]; CountryRegion: Option) TaxAreaCode: Code[20]
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(CountryRegion);
        CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
    end;

    local procedure CreateTaxAreaWithLine(TaxJurisdictionCode: Code[10]): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        CreateTaxAreaLine(TaxArea.Code, TaxJurisdictionCode);
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaLine(TaxAreaCode: Code[20]; TaxJurisdictionCode: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.Init();
        TaxAreaLine."Tax Area" := TaxAreaCode;
        TaxAreaLine."Tax Jurisdiction Code" := TaxJurisdictionCode;
        TaxAreaLine.Insert();
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxGroupCode: Code[20]; TaxBelowMax: Decimal)
    begin
        TaxDetail."Tax Jurisdiction Code" := CreateTaxJurisdiction();
        TaxDetail."Tax Group Code" := TaxGroupCode;
        TaxDetail."Tax Below Maximum" := TaxBelowMax;
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

    local procedure CreateGLAccountWithTaxGroup(TaxGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Tax Group Code" := TaxGroupCode;
        GLAccount.Modify();
        exit(GLAccount."No.");
    end;

#if not CLEAN27
    local procedure OpenStatisticsPageForServiceCreditMemo(No: Code[20])
    var
        ServiceCreditMemos: TestPage "Service Credit Memos";
    begin
        ServiceCreditMemos.OpenEdit();
        ServiceCreditMemos.FILTER.SetFilter("No.", No);
        ServiceCreditMemos.Statistics.Invoke();  // Opens Handler - ServiceStatisticsPageHandler and ServiceStatsPageHandler.
        ServiceCreditMemos.Close();
    end;
#endif
    local procedure OpenStatisticsPageForServiceCreditMemoNM(No: Code[20])
    var
        ServiceCreditMemos: TestPage "Service Credit Memos";
    begin
        ServiceCreditMemos.OpenEdit();
        ServiceCreditMemos.FILTER.SetFilter("No.", No);
        ServiceCreditMemos.ServiceStatistics.Invoke();  // Opens Handler - ServiceStatisticsPageHandler.
        ServiceCreditMemos.Close();
    end;

    local procedure OpenStatsPageForServiceCreditMemoNM(No: Code[20])
    var
        ServiceCreditMemos: TestPage "Service Credit Memos";
    begin
        ServiceCreditMemos.OpenEdit();
        ServiceCreditMemos.FILTER.SetFilter("No.", No);
        ServiceCreditMemos.ServiceStats.Invoke();  // Opens Handler - ServiceStatsPageHandler.
        ServiceCreditMemos.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForSalesQuote(No: Code[20])
    var
        SalesQuotes: TestPage "Sales Quotes";
    begin
        SalesQuotes.OpenEdit();
        SalesQuotes.FILTER.SetFilter("No.", No);
        SalesQuotes.Statistics.Invoke();  // Opens Handler - SalesStatisticsPageHandler and SalesQuotesStatsPageHandler.
        SalesQuotes.Close();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForSalesOrder(No: Code[20])
    var
        SalesOrderList: TestPage "Sales Order List";
    begin
        SalesOrderList.OpenEdit();
        SalesOrderList.FILTER.SetFilter("No.", No);
        SalesOrderList.Statistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesOrderList.Close();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForSalesInvoice(No: Code[20])
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.FILTER.SetFilter("No.", No);
        SalesInvoiceList.Statistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesInvoiceList.Close();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForBlanketSalesOrder(No: Code[20])
    var
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        BlanketSalesOrders.OpenEdit();
        BlanketSalesOrders.FILTER.SetFilter("No.", No);
        BlanketSalesOrders.Statistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        BlanketSalesOrders.Close();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        SalesReturnOrderList.OpenEdit();
        SalesReturnOrderList.FILTER.SetFilter("No.", No);
        SalesReturnOrderList.Statistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesReturnOrderList.Close();
    end;

    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure OpenStatisticsPageForSalesCreditMemo(No: Code[20])
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        SalesCreditMemos.OpenEdit();
        SalesCreditMemos.FILTER.SetFilter("No.", No);
        SalesCreditMemos.Statistics.Invoke();  // Opens Handler - SalesStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesCreditMemos.Close();
    end;
#endif
    local procedure OpenSalesStatisticsPageForSalesQuote(No: Code[20])
    var
        SalesQuotes: TestPage "Sales Quotes";
    begin
        SalesQuotes.OpenEdit();
        SalesQuotes.FILTER.SetFilter("No.", No);
        SalesQuotes.SalesStatistics.Invoke();  // Opens Handler - SalesStatisticsPageHandler and SalesQuotesStatsPageHandler.
        SalesQuotes.Close();
    end;

    local procedure OpenSalesOrderStatisticsPageForSalesOrder(No: Code[20])
    var
        SalesOrderList: TestPage "Sales Order List";
    begin
        SalesOrderList.OpenEdit();
        SalesOrderList.FILTER.SetFilter("No.", No);
        SalesOrderList.SalesOrderStatistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesOrderList.Close();
    end;

    local procedure OpenSalesStatisticsPageForSalesInvoice(No: Code[20])
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.FILTER.SetFilter("No.", No);
        SalesInvoiceList.SalesStatistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesInvoiceList.Close();
    end;

    local procedure OpenSalesOrderStatisticsPageForBlanketSalesOrder(No: Code[20])
    var
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        BlanketSalesOrders.OpenEdit();
        BlanketSalesOrders.FILTER.SetFilter("No.", No);
        BlanketSalesOrders.SalesOrderStatistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        BlanketSalesOrders.Close();
    end;

    local procedure OpenSalesOrderStatisticsPageForSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        SalesReturnOrderList.OpenEdit();
        SalesReturnOrderList.FILTER.SetFilter("No.", No);
        SalesReturnOrderList.SalesOrderStatistics.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesReturnOrderList.Close();
    end;

    local procedure OpenSalesStatisticsPageForSalesCreditMemo(No: Code[20])
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        SalesCreditMemos.OpenEdit();
        SalesCreditMemos.FILTER.SetFilter("No.", No);
        SalesCreditMemos.SalesStatistics.Invoke();  // Opens Handler - SalesStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesCreditMemos.Close();
    end;

    local procedure OpenSalesStatsPageForSalesQuote(No: Code[20])
    var
        SalesQuotes: TestPage "Sales Quotes";
    begin
        SalesQuotes.OpenEdit();
        SalesQuotes.FILTER.SetFilter("No.", No);
        SalesQuotes.SalesStats.Invoke();  // Opens Handler - SalesStatisticsPageHandler and SalesQuotesStatsPageHandler.
        SalesQuotes.Close();
    end;

    local procedure OpenSalesOrderStatsPageForSalesOrder(No: Code[20])
    var
        SalesOrderList: TestPage "Sales Order List";
    begin
        SalesOrderList.OpenEdit();
        SalesOrderList.FILTER.SetFilter("No.", No);
        SalesOrderList.SalesOrderStats.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesOrderList.Close();
    end;

    local procedure OpenSalesOrderStatsPageForSalesInvoice(No: Code[20])
    var
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.FILTER.SetFilter("No.", No);
        SalesInvoiceList.SalesOrderStats.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesInvoiceList.Close();
    end;

    local procedure OpenSalesOrderStatsPageForBlanketSalesOrder(No: Code[20])
    var
        BlanketSalesOrders: TestPage "Blanket Sales Orders";
    begin
        BlanketSalesOrders.OpenEdit();
        BlanketSalesOrders.FILTER.SetFilter("No.", No);
        BlanketSalesOrders.SalesOrderStats.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        BlanketSalesOrders.Close();
    end;

    local procedure OpenSalesOrderStatsPageForSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrderList: TestPage "Sales Return Order List";
    begin
        SalesReturnOrderList.OpenEdit();
        SalesReturnOrderList.FILTER.SetFilter("No.", No);
        SalesReturnOrderList.SalesOrderStats.Invoke();  // Opens Handler - SalesOrderStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesReturnOrderList.Close();
    end;

    local procedure OpenSalesOrderStatsPageForSalesCreditMemo(No: Code[20])
    var
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        SalesCreditMemos.OpenEdit();
        SalesCreditMemos.FILTER.SetFilter("No.", No);
        SalesCreditMemos.SalesOrderStats.Invoke();  // Opens Handler - SalesStatisticsPageHandler and SalesOrderStatsPageHandler.
        SalesCreditMemos.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenStatisticsPageForPurchaseOrder(No: Code[20])
    var
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        PurchaseOrderList.OpenEdit();
        PurchaseOrderList.FILTER.SetFilter("No.", No);
        PurchaseOrderList.Statistics.Invoke();  // Opens Handler - PurchaseOrderStatsPageHandler and PurchaseOrderStatisticsPageHandler.
        PurchaseOrderList.Close();
    end;
#endif

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenStatisticsPageForPurchaseReturnOrder(No: Code[20])
    var
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        PurchaseReturnOrderList.OpenEdit();
        PurchaseReturnOrderList.FILTER.SetFilter("No.", No);
        PurchaseReturnOrderList.Statistics.Invoke();  // Opens Handler - PurchaseOrderStatsPageHandler and PurchaseOrderStatisticsPageHandler.
        PurchaseReturnOrderList.Close();
    end;
#endif

    local procedure OpenStatisticsPageForPurchReturnOrder(No: Code[20])
    var
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        PurchaseReturnOrderList.OpenEdit();
        PurchaseReturnOrderList.FILTER.SetFilter("No.", No);
        PurchaseReturnOrderList.PurchaseOrderStatistics.Invoke();  // Opens Handler - PurchaseOrderStatsPageHandler and PurchaseOrderStatisticsPageHandler.
        PurchaseReturnOrderList.Close();
    end;

    local procedure OpenStatsPageForPurchReturnOrder(No: Code[20])
    var
        PurchaseReturnOrderList: TestPage "Purchase Return Order List";
    begin
        PurchaseReturnOrderList.OpenEdit();
        PurchaseReturnOrderList.FILTER.SetFilter("No.", No);
        PurchaseReturnOrderList.PurchaseOrderStats.Invoke();  // Opens Handler - PurchaseOrderStatsPageHandler and PurchaseOrderStatisticsPageHandler.
        PurchaseReturnOrderList.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenStatisticsPageForBlanketPurchaseOrder(No: Code[20])
    var
        BlanketPurchaseOrders: TestPage "Blanket Purchase Orders";
    begin
        BlanketPurchaseOrders.OpenEdit();
        BlanketPurchaseOrders.FILTER.SetFilter("No.", No);
        BlanketPurchaseOrders.Statistics.Invoke();  // Opens Handler - PurchaseOrderStatisticsPageHandler and PurchaseOrderStatsPageHandler.
        BlanketPurchaseOrders.Close();
    end;
#endif

    local procedure OpenPurchaseOrderStatisticsPageForBlanketPurchaseOrder(No: Code[20])
    var
        BlanketPurchaseOrders: TestPage "Blanket Purchase Orders";
    begin
        BlanketPurchaseOrders.OpenEdit();
        BlanketPurchaseOrders.FILTER.SetFilter("No.", No);
        BlanketPurchaseOrders.PurchaseOrderStatistics.Invoke();  // Opens Handler - PurchaseOrderStatisticsPageHandler and PurchaseOrderStatsPageHandler.
        BlanketPurchaseOrders.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenStatisticsPageForPurchaseQuote(No: Code[20])
    var
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        PurchaseQuotes.OpenEdit();
        PurchaseQuotes.FILTER.SetFilter("No.", No);
        PurchaseQuotes.Statistics.Invoke();  // Opens Handler - PurchaseStatsPageHandler and PurchaseStatisticsPageHandler.
        PurchaseQuotes.Close();
    end;
#endif

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenPurchaseStatisticsPageForPurchaseQuote(No: Code[20])
    var
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        PurchaseQuotes.OpenEdit();
        PurchaseQuotes.FILTER.SetFilter("No.", No);
        PurchaseQuotes.Statistics.Invoke();  // Opens Handler - PurchaseStatsPageHandler and PurchaseStatisticsPageHandler.
        PurchaseQuotes.Close();
    end;
#endif

    local procedure OpenStatisticsPageForPurchQuote(No: Code[20])
    var
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        PurchaseQuotes.OpenEdit();
        PurchaseQuotes.FILTER.SetFilter("No.", No);
        PurchaseQuotes.PurchaseStatistics.Invoke();  // Opens Handler - PurchStatsPageHandler and PurchStatisticsPageHandler.
        PurchaseQuotes.Close();
    end;

    local procedure OpenStatsPageForPurchQuote(No: Code[20])
    var
        PurchaseQuotes: TestPage "Purchase Quotes";
    begin
        PurchaseQuotes.OpenEdit();
        PurchaseQuotes.FILTER.SetFilter("No.", No);
        PurchaseQuotes.PurchaseStats.Invoke();  // Opens Handler - PurchStatsPageHandler and PurchStatisticsPageHandler.
        PurchaseQuotes.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenStatisticsPageForPurchaseCreditMemo(No: Code[20])
    var
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        PurchaseCreditMemos.OpenEdit();
        PurchaseCreditMemos.FILTER.SetFilter("No.", No);
        PurchaseCreditMemos.Statistics.Invoke();  // Opens Handler-  PurchaseStatsPageHandler and PurchaseStatisticsPageHandler..
        PurchaseCreditMemos.Close();
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenStatisticsPageForPurchaseInvoice(No: Code[20])
    var
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        PurchaseInvoices.OpenEdit();
        PurchaseInvoices.FILTER.SetFilter("No.", No);
        PurchaseInvoices.Statistics.Invoke();  // Opens Handler - PurchaseStatsPageHandler and PurchaseStatisticsPageHandler.
        PurchaseInvoices.Close();
    end;
#endif

    local procedure OpenPurchaseStatisticsPageForPurchaseCreditMemo(No: Code[20])
    var
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        PurchaseCreditMemos.OpenEdit();
        PurchaseCreditMemos.FILTER.SetFilter("No.", No);
        PurchaseCreditMemos.PurchaseStatistics.Invoke();  // Opens Handler-  PurchaseStatsPageHandler and PurchaseStatisticsPageHandler..
        PurchaseCreditMemos.Close();
    end;

    local procedure OpenPurchaseStatisticsPageForPurchaseInvoice(No: Code[20])
    var
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        PurchaseInvoices.OpenEdit();
        PurchaseInvoices.FILTER.SetFilter("No.", No);
        PurchaseInvoices.PurchaseStatistics.Invoke();  // Opens Handler - PurchaseStatsPageHandler and PurchaseStatisticsPageHandler.
        PurchaseInvoices.Close();
    end;

    local procedure OpenStatisticsPageForPurchaseOrderStatistics(No: Code[20])
    var
        PurchaseOrderList: TestPage "Purchase Order List";
    begin
        PurchaseOrderList.OpenEdit();
        PurchaseOrderList.FILTER.SetFilter("No.", No);
        PurchaseOrderList.PurchaseOrderStatistics.Invoke();  // Opens Handler - PurchOrderStatsPageHandler and PurchOrderStatisticsPageHandler.
        PurchaseOrderList.Close();
    end;

    local procedure OpenStatisticsPageForPurchCreditMemo(No: Code[20])
    var
        PurchaseCreditMemos: TestPage "Purchase Credit Memos";
    begin
        PurchaseCreditMemos.OpenEdit();
        PurchaseCreditMemos.FILTER.SetFilter("No.", No);
        PurchaseCreditMemos.PurchaseStats.Invoke();  // Opens Handler-  PurchaseStatsPageHandler and PurchaseStatisticsPageHandler..
        PurchaseCreditMemos.Close();
    end;

    local procedure OpenStatisticsPageForPurchInvoice(No: Code[20])
    var
        PurchaseInvoices: TestPage "Purchase Invoices";
    begin
        PurchaseInvoices.OpenEdit();
        PurchaseInvoices.FILTER.SetFilter("No.", No);
        PurchaseInvoices.PurchaseStats.Invoke();  // Opens Handler - PurchaseStatsPageHandler and PurchaseStatisticsPageHandler.
        PurchaseInvoices.Close();
    end;
#if not CLEAN27
    local procedure OpenStatisticsPageForServiceInvoice(No: Code[20])
    var
        ServiceInvoices: TestPage "Service Invoices";
    begin
        ServiceInvoices.OpenEdit();
        ServiceInvoices.FILTER.SetFilter("No.", No);
        ServiceInvoices.Statistics.Invoke();  // Opens Handler - ServiceStatsPageHandler and ServiceStatisticsPageHandler.
        ServiceInvoices.Close();
    end;
#endif
    local procedure OpenStatsPageForServiceInvoiceNM(No: Code[20])
    var
        ServiceInvoices: TestPage "Service Invoices";
    begin
        ServiceInvoices.OpenEdit();
        ServiceInvoices.FILTER.SetFilter("No.", No);
        ServiceInvoices.ServiceStats.Invoke();  // Opens Handler - ServiceStatsPageHandler.
        ServiceInvoices.Close();
    end;

    local procedure OpenStatisticsPageForServiceInvoiceNM(No: Code[20])
    var
        ServiceInvoices: TestPage "Service Invoices";
    begin
        ServiceInvoices.OpenEdit();
        ServiceInvoices.FILTER.SetFilter("No.", No);
        ServiceInvoices.ServiceStatistics.Invoke();  // Opens Handler - ServiceStatisticsPageHandler.
        ServiceInvoices.Close();
    end;

    local procedure UpdateInvoiceRoundingOnSalesReceivablesSetup(InvoiceRounding: Boolean) OldInvoiceRounding: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldInvoiceRounding := SalesReceivablesSetup."Invoice Rounding";
        SalesReceivablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        SalesReceivablesSetup.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    local procedure UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLines(SalesHeaderNo: Code[20]; TaxPctPos: Decimal; TaxAmtPos: Decimal; TaxPctNeg: Decimal; TaxAmtNeg: Decimal; PosAmtDelta: Decimal; NegAmtDelta: Decimal)
    var
        NewTaxAmtPos: Decimal;
        NewTaxAmtNeg: Decimal;
    begin
        NewTaxAmtPos := TaxAmtPos + PosAmtDelta;
        NewTaxAmtNeg := TaxAmtNeg + NegAmtDelta;

        LibraryVariableStorage.Enqueue(NewTaxAmtPos); // set new tax amount for positive line
        LibraryVariableStorage.Enqueue(NewTaxAmtNeg); // set new tax amount for negative line
        OpenStatisticsPageForSalesInvoice(SalesHeaderNo);
        VerifyPosAndNegSalesTaxLinesFromStatPage(TaxPctPos, TaxAmtPos, TaxPctNeg, TaxAmtNeg); // previous state

        LibraryVariableStorage.Enqueue(NewTaxAmtPos);
        LibraryVariableStorage.Enqueue(NewTaxAmtNeg);
        OpenStatisticsPageForSalesInvoice(SalesHeaderNo);
        VerifyPosAndNegSalesTaxLinesFromStatPage(
            TaxPctPos * NewTaxAmtPos / TaxAmtPos, NewTaxAmtPos,
            TaxPctNeg * NewTaxAmtNeg / TaxAmtNeg, NewTaxAmtNeg);
    end;
#endif
    local procedure UpdateTaxDiffFromStatisticsReopenStatAndVerifyTaxLinesNM(SalesHeaderNo: Code[20]; TaxPctPos: Decimal; TaxAmtPos: Decimal; TaxPctNeg: Decimal; TaxAmtNeg: Decimal; PosAmtDelta: Decimal; NegAmtDelta: Decimal)
    var
        NewTaxAmtPos: Decimal;
        NewTaxAmtNeg: Decimal;
    begin
        NewTaxAmtPos := TaxAmtPos + PosAmtDelta;
        NewTaxAmtNeg := TaxAmtNeg + NegAmtDelta;

        LibraryVariableStorage.Enqueue(NewTaxAmtPos); // set new tax amount for positive line
        LibraryVariableStorage.Enqueue(NewTaxAmtNeg); // set new tax amount for negative line
        OpenSalesOrderStatsPageForSalesInvoice(SalesHeaderNo);
        VerifyPosAndNegSalesTaxLinesFromStatPage(TaxPctPos, TaxAmtPos, TaxPctNeg, TaxAmtNeg); // previous state

        LibraryVariableStorage.Enqueue(NewTaxAmtPos);
        LibraryVariableStorage.Enqueue(NewTaxAmtNeg);
        OpenSalesOrderStatsPageForSalesInvoice(SalesHeaderNo);
        VerifyPosAndNegSalesTaxLinesFromStatPage(
            TaxPctPos * NewTaxAmtPos / TaxAmtPos, NewTaxAmtPos,
            TaxPctNeg * NewTaxAmtNeg / TaxAmtNeg, NewTaxAmtNeg);
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

    local procedure VerifyPosAndNegSalesTaxLinesFromStatPage(ExpectedTaxPctPos: Decimal; ExpectedTaxAmtPos: Decimal; ExpectedTaxPctNeg: Decimal; ExpectedTaxAmtNeg: Decimal)
    begin
        Assert.AreEqual(ExpectedTaxPctPos, LibraryVariableStorage.DequeueDecimal(), 'tax % for positive line');
        Assert.AreEqual(ExpectedTaxAmtPos, LibraryVariableStorage.DequeueDecimal(), 'tax amount for positive line');

        Assert.AreEqual(ExpectedTaxPctNeg, LibraryVariableStorage.DequeueDecimal(), 'tax % for negative line');
        Assert.AreEqual(ExpectedTaxAmtNeg, LibraryVariableStorage.DequeueDecimal(), 'tax amount for negative line');
    end;

    local procedure VerifySalesTaxAmountDifferenceCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        SalesTaxAmountDifference.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(SalesTaxAmountDifference, ExpectedCount);
    end;

    local procedure VerifySalesTaxAmountDifference(DocumentNo: Code[20]; Positive: Boolean; ExpectedTaxPct: Decimal; ExpectedTaxDiff: Decimal)
    var
        SalesTaxAmountDifference: Record "Sales Tax Amount Difference";
    begin
        SalesTaxAmountDifference.SetRange("Document No.", DocumentNo);
        SalesTaxAmountDifference.SetRange(Positive, Positive);
        SalesTaxAmountDifference.FindFirst();
        SalesTaxAmountDifference.TestField("Tax %", ExpectedTaxPct);
        SalesTaxAmountDifference.TestField("Tax Difference", ExpectedTaxDiff);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        VerifyTaxOnStatisticsPage(SalesOrderStats."VATAmount[2]".AsDecimal(), SalesOrderStats."TotalAmount2[1]".AsDecimal());
        SalesOrderStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler2(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.TaxAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuotesStatsPageHandler(var SalesStats: TestPage "Sales Stats.")
    begin
        VerifyTaxOnStatisticsPage(SalesStats.TaxAmount.AsDecimal(), SalesStats.TotalAmount2.AsDecimal());
        SalesStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        VerifyTaxOnStatisticsPage(SalesStatistics.VATAmount.AsDecimal(), SalesStatistics.TotalAmount2.AsDecimal());
        SalesStatistics.OK().Invoke();
    end;

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
        VerifyTaxOnStatisticsPage(SalesOrderStats."VATAmount[2]".AsDecimal(), SalesOrderStats."TotalAmount2[1]".AsDecimal());
        SalesOrderStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler2NM(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.TaxAmount.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        SalesOrderStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesQuotesStatsPageHandlerNM(var SalesStats: TestPage "Sales Stats.")
    begin
        VerifyTaxOnStatisticsPage(SalesStats.TaxAmount.AsDecimal(), SalesStats.TotalAmount2.AsDecimal());
        SalesStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandlerNM(var SalesStatistics: TestPage "Sales Statistics")
    begin
        VerifyTaxOnStatisticsPage(SalesStatistics.VATAmount.AsDecimal(), SalesStatistics.TotalAmount2.AsDecimal());
        SalesStatistics.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        VerifyTaxOnStatisticsPage(SalesOrderStatistics.VATAmount.AsDecimal(), SalesOrderStatistics."TotalAmount2[1]".AsDecimal());
        SalesOrderStatistics.OK().Invoke();
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatsPageHandler(var ServiceStats: TestPage "Service Stats.")
    begin
        VerifyTaxOnStatisticsPage(ServiceStats.VATAmount.AsDecimal(), ServiceStats."TotalAmount2[1]".AsDecimal());
        ServiceStats.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    begin
        VerifyTaxOnStatisticsPage(ServiceStatistics."VAT Amount_General".AsDecimal(), ServiceStatistics."Total Incl. VAT_General".AsDecimal());
        ServiceStatistics.OK().Invoke();
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatsPageHandlerNM(var ServiceStats: TestPage "Service Stats.")
    begin
        VerifyTaxOnStatisticsPage(ServiceStats.VATAmount.AsDecimal(), ServiceStats."TotalAmount2[1]".AsDecimal());
        ServiceStats.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsPageHandlerNM(var ServiceStatistics: TestPage "Service Statistics")
    begin
        VerifyTaxOnStatisticsPage(ServiceStatistics."VAT Amount_General".AsDecimal(), ServiceStatistics."Total Incl. VAT_General".AsDecimal());
        ServiceStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatsPageHandler(var PurchaseOrderStats: TestPage "Purchase Order Stats.")
    begin
        VerifyTaxOnStatisticsPage(PurchaseOrderStats."VATAmount[2]".AsDecimal(), PurchaseOrderStats."TotalAmount2[1]".AsDecimal());
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
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatsPageHandler(var PurchaseStats: TestPage "Purchase Stats.")
    begin
        VerifyTaxOnStatisticsPage(PurchaseStats.TaxAmount.AsDecimal(), PurchaseStats.TotalAmount2.AsDecimal());
        PurchaseStats.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchStatsPageHandler(var PurchaseStats: TestPage "Purchase Stats.")
    begin
        VerifyTaxOnStatisticsPage(PurchaseStats.TaxAmount.AsDecimal(), PurchaseStats.TotalAmount2.AsDecimal());
        PurchaseStats.OK().Invoke();
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

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        VerifyTaxOnStatisticsPage(PurchaseStatistics.VATAmount.AsDecimal(), PurchaseStatistics.TotalAmount2.AsDecimal());
        PurchaseStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        VerifyTaxOnStatisticsPage(PurchaseStatistics.VATAmount.AsDecimal(), PurchaseStatistics.TotalAmount2.AsDecimal());
        PurchaseStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    procedure SalesOrderStatsInvokeInvVATLinesMPH(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.NoOfVATLines_Invoicing.AssertEquals(2);
        SalesOrderStats.NoOfVATLines_Invoicing.Drilldown();
        SalesOrderStats.OK().Invoke();
    end;
#endif
    [PageHandler]
    procedure SalesOrderStatsInvokeInvVATLinesMPHNM(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        SalesOrderStats.NoOfVATLines_Invoicing.AssertEquals(2);
        SalesOrderStats.NoOfVATLines_Invoicing.Drilldown();
        SalesOrderStats.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SalesTaxLinesSubformDynPosNegLinesMPH(var SalesTaxLinesSubformDyn: TestPage "Sales Tax Lines Subform Dyn")
    var
        SetTaxAmountPositive: Decimal;
        SetTaxAmountNegative: Decimal;
        TaxPctPositive: Decimal;
        TaxPctNegative: Decimal;
        TaxAmtPositive: Decimal;
        TaxAmtNegative: Decimal;
    begin
        SetTaxAmountPositive := LibraryVariableStorage.DequeueDecimal();
        SetTaxAmountNegative := LibraryVariableStorage.DequeueDecimal();

        SalesTaxLinesSubformDyn.First();
        if SalesTaxLinesSubformDyn."Line Amount".AsDecimal() > 0 then begin
            TaxPctPositive := SalesTaxLinesSubformDyn."Tax %".AsDecimal();
            TaxAmtPositive := SalesTaxLinesSubformDyn."Tax Amount".AsDecimal();
            SalesTaxLinesSubformDyn."Tax Amount".SetValue(SetTaxAmountPositive);

            SalesTaxLinesSubformDyn.Next();
            TaxPctNegative := SalesTaxLinesSubformDyn."Tax %".AsDecimal();
            TaxAmtNegative := SalesTaxLinesSubformDyn."Tax Amount".AsDecimal();
            SalesTaxLinesSubformDyn."Tax Amount".SetValue(SetTaxAmountNegative);
        end else begin
            TaxPctNegative := SalesTaxLinesSubformDyn."Tax %".AsDecimal();
            TaxAmtNegative := SalesTaxLinesSubformDyn."Tax Amount".AsDecimal();
            SalesTaxLinesSubformDyn."Tax Amount".SetValue(SetTaxAmountNegative);

            SalesTaxLinesSubformDyn.Next();
            TaxPctPositive := SalesTaxLinesSubformDyn."Tax %".AsDecimal();
            TaxAmtPositive := SalesTaxLinesSubformDyn."Tax Amount".AsDecimal();
            SalesTaxLinesSubformDyn."Tax Amount".SetValue(SetTaxAmountPositive);
        end;

        LibraryVariableStorage.Enqueue(TaxPctPositive);
        LibraryVariableStorage.Enqueue(TaxAmtPositive);
        LibraryVariableStorage.Enqueue(TaxPctNegative);
        LibraryVariableStorage.Enqueue(TaxAmtNegative);
    end;
}
