codeunit 142064 SalesDocTotalsSalesEntryCopy
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Document Totals]
        isInitialized := false;
    end;

    var
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedDocToInvoiceDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesDocNo: Code[20];
        CustomerNo: Code[20];
        TaxAreaCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        SalesPostedAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Copy]
        // [SCENARIO 136987] Copy posted Inv to Invoice without recalculate will keep document totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created and posted sales document with sales line with default Tax Group Code
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage);
        CustomerNo := SalesHeader."Sell-to Customer No.";
        TaxAreaCode := SalesHeader."Tax Area Code";
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.

        // Cache the values from the posted document for comparison
        SalesInvoiceHeader.Get(PostedSalesDocNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(SalesInvoiceHeader."Invoice Discount Amount",
          SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT",
          0,
          SalesPostedAmounts);

        // [WHEN] User creates new header and copies the posted document where "Recalculate Lines" is No
        CreateSalesDocumentHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, TaxAreaCode);
        SalesCopyDocument(SalesHeader, PostedSalesDocNo, "Sales Document Type From"::"Posted Invoice", false);
        CollectDataFromSalesInvoicePage(SalesHeader, SalesInvoice, PostAmounts, TotalTax);

        // [THEN] Taxes are calculated and totals updated on page
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValuesEqual(SalesHeader, SalesPostedAmounts, PostAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyPostedDocToInvoiceDisplaysDocTotalsOnRecalculate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: TestPage "Sales Invoice";
        PostedSalesDocNo: Code[20];
        CustomerNo: Code[20];
        TaxAreaCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        SalesPostedAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Copy]
        // [SCENARIO 136987] Copy posted Inv to Invoice with recalculate will update taxes and totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created and posted sales document with sales line with default Tax Group Code
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage);
        CustomerNo := SalesHeader."Sell-to Customer No.";
        TaxAreaCode := SalesHeader."Tax Area Code";
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.

        // Cache the values from the posted document for comparison
        SalesInvoiceHeader.Get(PostedSalesDocNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(SalesInvoiceHeader."Invoice Discount Amount",
          SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT",
          0,
          SalesPostedAmounts);

        // [WHEN] User creates new header and copies the posted document where "Recalculate Lines" is Yes
        CreateSalesDocumentHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, TaxAreaCode);
        SalesCopyDocument(SalesHeader, PostedSalesDocNo, "Sales Document Type From"::"Posted Invoice", true);
        CollectDataFromSalesInvoicePage(SalesHeader, SalesInvoice, PostAmounts, TotalTax);

        // [THEN] Taxes are calculated and totals updated on page
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValuesEqual(SalesHeader, SalesPostedAmounts, PostAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyInvoiceToOrderDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesOrder: TestPage "Sales Order";
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        TaxPercentage: Integer;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Copy]
        // [SCENARIO 136987]  Copy unposted Inv to order without recalculate will keep document totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created sales document with sales line with default Tax Group Code
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          0,
          InvoiceAmounts);

        // [WHEN] User creates new order and copies the Invoice where "Recalculate Lines" is No
        CreateSalesDocumentHeader(SalesHeader2, SalesHeader2."Document Type"::Order,
          SalesHeader."Sell-to Customer No.", SalesHeader."Tax Area Code");
        SalesCopyDocument(SalesHeader2, SalesHeader."No.", "Sales Document Type From"::Invoice, false);
        CollectDataFromSalesOrderPage(SalesHeader2, SalesOrder, OrderAmounts, TotalTax);

        // [THEN] Taxes are calculated and totals updated on page
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValuesEqual(SalesHeader2, InvoiceAmounts, OrderAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyInvoiceToOrderDisplaysDocTotalsOnRecalculate()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesOrder: TestPage "Sales Order";
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        TaxPercentage: Integer;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Copy]
        // [SCENARIO 136987] Copy Invoice to Order with recalculate will update taxes and totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created sales document with sales line with default Tax Group Code
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          0,
          InvoiceAmounts);

        // [WHEN] User creates new order and copies the invoice where "Recalculate Lines" is Yes
        CreateSalesDocumentHeader(SalesHeader2, SalesHeader2."Document Type"::Order,
          SalesHeader."Sell-to Customer No.", SalesHeader."Tax Area Code");
        SalesCopyDocument(SalesHeader2, SalesHeader."No.", "Sales Document Type From"::Invoice, true);
        CollectDataFromSalesOrderPage(SalesHeader2, SalesOrder, OrderAmounts, TotalTax);

        // [THEN] Taxes are calculated and totals updated on page
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValuesEqual(SalesHeader2, InvoiceAmounts, OrderAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyInvoiceToOrderWithInvDiscDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        DiscountPercent: Decimal;
        TaxPercentage: Integer;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Copy] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Invoice Doc Totals, Tax and Inv Discount are calculated on copy when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created sales document with sales line with default Tax Group Code
        CreateSalesDocumentWithInvDisc(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine),
          InvoiceAmounts);

        // [WHEN] User creates new order and copies the invoice where "Recalculate Lines" is Yes
        CreateSalesDocumentHeaderWithInvDisc(SalesHeader2, SalesHeader2."Document Type"::Order,
          SalesHeader."Sell-to Customer No.", SalesHeader."Tax Area Code");
        SalesCopyDocument(SalesHeader2, SalesHeader."No.", "Sales Document Type From"::Invoice, true);
        FindSalesLine(SalesHeader2, SalesLine2);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine2, VATAmount, TotalSalesLine);
        DiscountPercent := SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine2);

        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          DiscountPercent,
          OrderAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader2.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader2."Amount Including VAT" - SalesHeader2.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        Assert.AreNotEqual(SalesHeader2."Invoice Discount Amount", 0,
          'Invoice Discount Amount should not be zero');
        VerifyFieldValuesEqual(SalesHeader2, InvoiceAmounts, OrderAmounts, TotalTax,
          DiscountPercent, RoundingPrecision);
    end;

    [Test]
    [HandlerFunctions('SalesCodePageHandler')]
    [Scope('OnPrem')]
    procedure TestGetStdCustSalesCodesDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        CustomerNo: Code[20];
        TaxAreaCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Standard Sales Code]
        // [SCENARIO 136987] Applying Standard Sales Codes will update document totals
        // Setup
        Initialize();
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has set up standard sales codes and customer
        CreateCustomerWithSalesCodes(CustomerNo, TaxAreaCode);

        // [WHEN] User creates new header and applies the standard codes
        CreateSalesDocumentHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, TaxAreaCode);
        StandardCustomerSalesCode.InsertSalesLines(SalesHeader);
        FindSalesLine(SalesHeader, SalesLine);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyTotals(SalesHeader, PostAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [HandlerFunctions('SalesCodePageHandler')]
    [Scope('OnPrem')]
    procedure TestGetStdCustSalesCodesWithInvDiscDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        CustomerNo: Code[20];
        TaxAreaCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        StockWarningSetup: Boolean;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Standard Sales Code] [Invoice Discount Amount]
        // [SCENARIO 136987] Applying Standard Sales Codes will update totals and inv disc when setup option marked
        // Setup
        Initialize();
        RoundingPrecision := 0.01;
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has set up standard sales codes and customer
        CreateCustomerWithSalesCodesAndInvDisc(CustomerNo, TaxAreaCode);

        // [WHEN] User creates new header and applies the standard codes
        CreateSalesDocumentHeaderWithInvDisc(SalesHeader, SalesHeader."Document Type"::"Credit Memo",
          CustomerNo, TaxAreaCode);
        StandardCustomerSalesCode.InsertSalesLines(SalesHeader);
        FindSalesLine(SalesHeader, SalesLine);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;
        FindSalesLine(SalesHeader, SalesLine);

        // [THEN] Taxes are calculated and totals updated on page
        Assert.AreNotEqual(SalesHeader."Invoice Discount Amount", 0,
          'Invoice Discount Amount should not be zero');
        VerifyTotals(SalesHeader, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine), RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMakeOrderDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesOrder: TestPage "Sales Order";
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        TaxPercentage: Integer;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Make Order]
        // [SCENARIO 136987]  Make Order from Blanket Order will calculate document totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created sales document with sales line with default Tax Group Code
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", TaxPercentage);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          0,
          InvoiceAmounts);

        // [WHEN] User creates order from Blanket Order
        MakeOrder(SalesHeader);
        FindOrder(SalesLine, SalesHeader2, SalesLine2);
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader2);

        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          OrderAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader2.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader2."Amount Including VAT" - SalesHeader2.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValuesEqual(SalesHeader2, InvoiceAmounts, OrderAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestMakeOrderWithInvDiscDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        DiscountPercent: Decimal;
        TaxPercentage: Integer;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Make Order] [Invoice Discount Amount]
        // [SCENARIO 136987] Doc Totals, Tax and Inv Discount are calculated on make order when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created sales document with sales line with default Tax Group Code
        CreateSalesDocumentWithInvDisc(SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", TaxPercentage);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine),
          InvoiceAmounts);

        // [WHEN] User creates order from Blanket Order
        MakeOrder(SalesHeader);
        FindOrder(SalesLine, SalesHeader2, SalesLine2);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine2, VATAmount, TotalSalesLine);
        DiscountPercent := SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine2);

        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          DiscountPercent,
          OrderAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader2.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader2."Amount Including VAT" - SalesHeader2.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        Assert.AreNotEqual(SalesHeader2."Invoice Discount Amount", 0,
          'Invoice Discount Amount should not be zero');
        VerifyFieldValuesEqual(SalesHeader2, InvoiceAmounts, OrderAmounts, TotalTax,
          DiscountPercent, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReopenSalesDocDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesOrder: TestPage "Sales Order";
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        TaxPercentage: Integer;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Reopen]
        // [SCENARIO 136987]  Create Order, release it and then reopen will calc the doc totals
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created sales document with sales line with default Tax Group Code
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, TaxPercentage);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          0,
          InvoiceAmounts);

        // [WHEN] User releases order and then reopens the order
        Release(SalesHeader);
        Reopen(SalesHeader);
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);

        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          OrderAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValuesEqual(SalesHeader, InvoiceAmounts, OrderAmounts, TotalTax,
          0, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReopenSalesDocWithInvDiscDisplaysDocTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        InvoiceAmounts: array[5] of Decimal;
        OrderAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        DiscountPercent: Decimal;
        TaxPercentage: Integer;
        TotalTax: Decimal;
        CalcInvDisc: Boolean;
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Reopen] [Invoice Discount Amount]
        // [SCENARIO 136987] Create Order, Release and then reopen will calc totals and disc when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);
        RoundingPrecision := 0.01;
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created sales document with sales line with default Tax Group Code
        CreateSalesDocumentWithInvDisc(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, TaxPercentage);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Cache the values from document for comparison
        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine),
          InvoiceAmounts);

        // [WHEN] User releases order and then reopens the order
        Release(SalesHeader);
        Reopen(SalesHeader);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);
        DiscountPercent := SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine);

        SetCompareAmounts(TotalSalesLine."Inv. Discount Amount",
          TotalSalesLine.Amount,
          VATAmount,
          TotalSalesLine."Amount Including VAT",
          DiscountPercent,
          OrderAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        Assert.AreNotEqual(SalesHeader."Invoice Discount Amount", 0,
          'Invoice Discount Amount should not be zero');
        VerifyFieldValuesEqual(SalesHeader, InvoiceAmounts, OrderAmounts, TotalTax,
          DiscountPercent, RoundingPrecision);
    end;

    local procedure CreateCustomer(TaxAreaCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        UpdateCustomerTaxAreaCode(Customer, TaxAreaCode);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer; TaxAreaCode: Code[20]; DiscPct: Decimal; MinimumAmount: Decimal)
    begin
        LibrarySales.CreateCustomer(Customer);
        UpdateCustomerTaxAreaCode(Customer, TaxAreaCode);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscPct, MinimumAmount, '');
    end;

    local procedure UpdateCustomerTaxAreaCode(Customer: Record Customer; TaxAreaCode: Code[20])
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Identification Type", Customer."Tax Identification Type"::"Legal Entity");
        Customer.Validate("RFC No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("RFC No.")) - 1));  // Taken Length less than RFC No. Length as Tax Identification Type is Legal Entity.
        Customer.Validate("CURP No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("CURP No."))));
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        VATEntry: Record "VAT Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        VATEntry.DeleteAll();
        Commit();
        CreateVATPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, TaxGroupCode, LibraryRandom.RandInt(10));
        exit(Item."No.");
    end;

    local procedure CreateItemSpecifyUnitPrice(TaxGroupCode: Code[20]; UnitPrice: Decimal): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItem(Item, TaxGroupCode, UnitPrice);
        exit(Item."No.");
    end;

    local procedure UpdateItem(var Item: Record Item; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    begin
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("Unit Price", UnitPrice);
        Item.Modify(true);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercentage);  // Using RANDOM value for Tax Below Maximum.
        TaxDetail.Modify(true);
    end;

    local procedure CreateSalesTaxJurisdiction(): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Report-to Jurisdiction", TaxJurisdiction.Code);
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, TaxPercentage);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxPercentage: Integer)
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        CreateSalesDocumentWithCertainTax(SalesHeader, SalesLine, DocumentType, TaxAreaCode, TaxDetail."Tax Group Code");
    end;

    local procedure CreateSalesDocumentWithCertainTax(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(TaxAreaCode));
        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::None);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(TaxGroupCode),
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
    end;

    local procedure CreateSalesDocumentWithInvDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxPercentage: Integer)
    var
        TaxDetail: Record "Tax Detail";
        Customer: Record Customer;
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        SetupDataForDiscountTypePct(Customer, DiscPct, TaxAreaCode, ItemNo, ItemQuantity, TaxDetail."Tax Group Code");
        CreateSalesDocumentWithCertainTaxAndDisc(SalesHeader, SalesLine, DocumentType, Customer."No.", ItemNo, TaxAreaCode);
    end;

    local procedure CreateSalesDocumentWithCertainTaxAndDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::"%");
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          ItemNo,
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
    end;

    local procedure CreateSalesDocumentHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::None);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify();
    end;

    local procedure CreateSalesDocumentHeaderWithInvDisc(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::"%");
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify();
    end;

    local procedure GetRandomCode(FieldLength: Integer) RandomCode: Code[20]
    begin
        RandomCode := LibraryUtility.GenerateGUID();
        repeat
            RandomCode += Format(LibraryRandom.RandInt(9));  // Generating any Random integer value.
        until StrLen(RandomCode) = FieldLength;
    end;

    local procedure OpenSalesInvoicePageEdit(var SalesInvoice: TestPage "Sales Invoice"; SalesHeader: Record "Sales Header")
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesOrderPageEdit(var SalesOrder: TestPage "Sales Order"; SalesHeader: Record "Sales Header")
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
    end;

    local procedure SetCompareAmounts(InvoiceDiscountAmount: Decimal; TotalAmountExcTax: Decimal; TaxAmount: Decimal; TotalAmountIncTax: Decimal; CustDiscountPercent: Decimal; var Amounts: array[5] of Decimal)
    var
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Amounts[FieldType::InvoiceDiscountAmount] := InvoiceDiscountAmount;
        Amounts[FieldType::TotalAmountExcTax] := TotalAmountExcTax;
        Amounts[FieldType::TaxAmount] := TaxAmount;
        Amounts[FieldType::TotalAmountIncTax] := TotalAmountIncTax;
        Amounts[FieldType::DiscountPercent] := CustDiscountPercent;
    end;

    local procedure VerifyFieldValuesEqual(SalesHeader: Record "Sales Header"; PreAmounts: array[5] of Decimal; PostAmounts: array[5] of Decimal; TotalTax: Decimal; TotalDiscountPercent: Decimal; RoundingPrecision: Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreEqual(
          PreAmounts[FieldType::TotalAmountExcTax],
          PostAmounts[FieldType::TotalAmountExcTax],
          'Before and after amounts for Total Amount Excluding Tax should be equal');
        Assert.AreEqual(
          PreAmounts[FieldType::TotalAmountIncTax],
          PostAmounts[FieldType::TotalAmountIncTax],
          'Before and after amounts for Total Amount Including Tax should be equal');
        Assert.AreEqual(
          PreAmounts[FieldType::TaxAmount],
          PostAmounts[FieldType::TaxAmount],
          'Before and after amounts for Tax Amount should not equal');

        VerifyTotals(SalesHeader, PostAmounts, TotalTax, TotalDiscountPercent, RoundingPrecision);
    end;

    local procedure VerifyFieldValuesNotZero(PostAmounts: array[5] of Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreNotEqual(
          PostAmounts[FieldType::TotalAmountExcTax], 0,
          'Total Amount Excluding Tax should not be zero');
        Assert.AreNotEqual(
          PostAmounts[FieldType::TotalAmountIncTax], 0,
          'Total Amount Including Tax should not be zero');
        Assert.AreNotEqual(
          PostAmounts[FieldType::TaxAmount], 0,
          'Tax Amount should not be zero');
    end;

    local procedure VerifyTotals(SalesHeader: Record "Sales Header"; PostAmounts: array[5] of Decimal; TotalTax: Decimal; TotalDiscountPercent: Decimal; RoundingPrecision: Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::InvoiceDiscountAmount],
          SalesHeader."Invoice Discount Amount",
          RoundingPrecision,
          'An incorrect Invoice Discount Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TotalAmountExcTax],
          SalesHeader.Amount,
          RoundingPrecision,
          'An incorrect Total Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TotalAmountIncTax],
          SalesHeader."Amount Including VAT",
          RoundingPrecision,
          'An incorrect Total Amount Including Tax was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::TaxAmount],
          TotalTax,
          RoundingPrecision,
          'An incorrect Tax Amount was saved');
        Assert.AreNearlyEqual(
          PostAmounts[FieldType::DiscountPercent],
          TotalDiscountPercent,
          RoundingPrecision,
          'Customer Discount Percent value is incorrect');
        VerifyFieldValuesNotZero(PostAmounts);
    end;

    local procedure PrepareSalesReceivableSetupWarnings(var StockWarningSetup: Boolean; var CreditWarningSetup: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        StockWarningSetup := false;
        SetupStockWarning(StockWarningSetup);

        CreditWarningSetup := SalesReceivablesSetup."Credit Warnings"::"No Warning";
        SetupCreditWarning(CreditWarningSetup);
    end;

    local procedure SetupStockWarning(var Option: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OrigianlOption: Boolean;
    begin
        SalesReceivablesSetup.Get();
        OrigianlOption := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", Option);
        SalesReceivablesSetup.Modify(true);
        Option := OrigianlOption;
    end;

    local procedure SetupCreditWarning(var Option: Option)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OrigianlOption: Option;
    begin
        SalesReceivablesSetup.Get();
        OrigianlOption := SalesReceivablesSetup."Credit Warnings";
        SalesReceivablesSetup.Validate("Credit Warnings", Option);
        SalesReceivablesSetup.Modify(true);
        Option := OrigianlOption;
    end;

    local procedure SetupCalcInvoiceDisc(var Option: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OrigianlOption: Boolean;
    begin
        SalesReceivablesSetup.Get();
        OrigianlOption := SalesReceivablesSetup."Calc. Inv. Discount";
        SalesReceivablesSetup.Validate("Calc. Inv. Discount");
        SalesReceivablesSetup.Modify(true);
        Option := OrigianlOption;
    end;

    local procedure SetupDataForDiscountTypePct(var Customer: Record Customer; var DiscPct: Decimal; TaxAreaCode: Code[20]; var ItemNo: Code[20]; var ItemQuantity: Decimal; TaxGroupCode: Code[20])
    var
        MinAmt: Decimal;
        ItemUnitPrice: Decimal;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);

        ItemNo := CreateItemSpecifyUnitPrice(TaxGroupCode, ItemUnitPrice);
        CreateCustomerWithDiscount(Customer, TaxAreaCode, DiscPct, MinAmt);
    end;

    local procedure SalesCopyDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type From"; ReCalculateLines: Boolean)
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        Clear(CopySalesDocument);
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocumentType, DocumentNo, false, ReCalculateLines);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.RunModal();
    end;

    local procedure CreateItemWithDimension(DimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type"; TaxGroupCode: Code[20]) ItemNo: Code[20]
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryInventory.CreateItem(Item);
        // Use Random because value is not important.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2) + LibraryUtility.GenerateRandomFraction());
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        ItemNo := Item."No.";
        if DimensionCode = '' then
            exit;
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateItemWithExtendedText(var Item: Record Item; DimensionCode: Code[20]; TaxGroupCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        Item.Get(CreateItemWithDimension(DimensionCode, DefaultDimension."Value Posting"::" ", TaxGroupCode));
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
    end;

    local procedure CreateStandardSalesLine(var StandardSalesLine: Record "Standard Sales Line"; StandardSalesCode: Code[10]; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateStandardSalesLine(StandardSalesLine, StandardSalesCode);
        StandardSalesLine.Validate(Type, Type);
        StandardSalesLine.Validate("No.", No);

        // Use Random because value is not important.
        StandardSalesLine.Validate(Quantity, LibraryRandom.RandInt(10));
        StandardSalesLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCodePageHandler(var StandardCustomerSalesCodes: Page "Standard Customer Sales Codes"; var Response: Action)
    begin
        // Modal Page Handler.
        StandardCustomerSalesCodes.SetRecord(StandardCustomerSalesCode);
        Response := ACTION::LookupOK;
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerWithSalesCodes(var CustomerNo: Code[20]; var TaxAreaCode: Code[20])
    var
        Dimension: Record Dimension;
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesLine: Record "Standard Sales Line";
        TaxDetail: Record "Tax Detail";
        Item: Record Item;
        TaxPercentage: Decimal;
    begin
        TaxPercentage := LibraryRandom.RandInt(9);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        CustomerNo := CreateCustomer(TaxAreaCode);
        LibraryDimension.FindDimension(Dimension);
        CreateItemWithExtendedText(Item, Dimension.Code, TaxDetail."Tax Group Code");
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);
        CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code, StandardSalesLine.Type::Item, Item."No.");
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, CustomerNo, StandardSalesLine."Standard Sales Code");
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerWithSalesCodesAndInvDisc(var CustomerNo: Code[20]; var TaxAreaCode: Code[20])
    var
        Dimension: Record Dimension;
        StandardSalesCode: Record "Standard Sales Code";
        StandardSalesLine: Record "Standard Sales Line";
        Customer: Record Customer;
        TaxDetail: Record "Tax Detail";
        Item: Record Item;
        TaxPercentage: Decimal;
        MinAmt: Decimal;
        DiscPct: Decimal;
        ItemUnitPrice: Decimal;
    begin
        TaxPercentage := LibraryRandom.RandInt(9);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        ItemUnitPrice := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        MinAmt := LibraryRandom.RandDecInDecimalRange(ItemUnitPrice, ItemUnitPrice * 2, 2);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
        CreateCustomerWithDiscount(Customer, TaxAreaCode, DiscPct, MinAmt);

        LibraryDimension.FindDimension(Dimension);
        CreateItemWithExtendedText(Item, Dimension.Code, TaxDetail."Tax Group Code");
        Item.Validate("Unit Price", ItemUnitPrice);
        Item.Modify(true);

        LibrarySales.CreateStandardSalesCode(StandardSalesCode);
        CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code, StandardSalesLine.Type::Item, Item."No.");
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesLine."Standard Sales Code");
        UpdateCustomerTaxAreaCode(Customer, TaxAreaCode);
        CustomerNo := Customer."No.";
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.Find('-');
    end;

    local procedure CreateVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create Blank VAT Posting Setup with VAT Calculation Type - Sales Tax to fix MX,CA Country failure.
        if not VATPostingSetup.Get('', '') then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', '');
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CollectDataFromSalesInvoicePage(var SalesHeader: Record "Sales Header"; SalesInvoice: TestPage "Sales Invoice"; var PostAmounts: array[5] of Decimal; var TotalTax: Decimal)
    begin
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;
    end;

    [Scope('OnPrem')]
    procedure CollectDataFromSalesOrderPage(var SalesHeader: Record "Sales Header"; SalesOrder: TestPage "Sales Order"; var OrderAmounts: array[5] of Decimal; var TotalTax: Decimal)
    begin
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);

        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          OrderAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;
    end;

    [Scope('OnPrem')]
    procedure MakeOrder(var SalesHeader: Record "Sales Header")
    begin
        CODEUNIT.Run(CODEUNIT::"Blanket Sales Order to Order", SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure FindOrder(SalesLine: Record "Sales Line"; var SalesHeader2: Record "Sales Header"; var SalesLine2: Record "Sales Line")
    begin
        SalesLine2.SetRange("Blanket Order No.", SalesLine."Document No.");
        SalesLine2.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine2.FindFirst();
        SalesHeader2.Get(SalesLine2."Document Type", SalesLine2."Document No.");
    end;

    [Scope('OnPrem')]
    procedure Release(var SalesHeader: Record "Sales Header")
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDoc.PerformManualRelease(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure Reopen(var SalesHeader: Record "Sales Header")
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        ReleaseSalesDoc.PerformManualReopen(SalesHeader);
    end;
}

