codeunit 142063 SalesDocTotalsSalesEntryUI
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Document Totals]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceDisplaysDocTotalsAddTaxGroupCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        SalesInvoice: TestPage "Sales Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
        OriginalUnitPrice: Decimal;
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when adding Tax Group Code on Sales Invoice
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesInvoice.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesInvoice.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesInvoice.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceDisplaysDocTotalsUpdateQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        SalesInvoice: TestPage "Sales Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
        VATAmount: Decimal;
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when changing Quantity on Sales Invoice
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created a sales document with a sales line item that defaults the Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        SalesInvoice.SalesLines.Next();

        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceDisplaysDocTotalsNoInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesInvoice: TestPage "Sales Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        CalcInvDisc: Boolean;
        OriginalUnitPrice: Decimal;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Invoice Doc Totals, Sales Tax are calculated but Invoice Discount is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(0);

        SalesInvoice.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesInvoice.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesInvoice.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceDisplaysDocTotalsWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesInvoice: TestPage "Sales Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Invoice Doc Totals, Tax and Inv Discount are calculated when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesInvoice.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        SalesInvoice.SalesLines."Unit Price".SetValue(SalesLine."Unit Price");
        SalesInvoice.SalesLines.Next();

        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalSalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        SalesInvoice: TestPage "Sales Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        TotalTax: Decimal;
        VATAmount: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Invoice Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that defaults the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoicePosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TotalSalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesInvoice: TestPage "Sales Invoice";
        SalesHeaderAmounts: array[5] of Decimal;
        SalesPostedAmounts: array[5] of Decimal;
        VATAmount: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        PostedSalesDocNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Post]
        // [SCENARIO 136987] Doc Totals and taxes match before and after posting on Sales Invoice
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line with no default Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesInvoice.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesInvoice.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          SalesHeaderAmounts);

        // [WHEN] User Posts the invoice
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.
        SalesInvoiceHeader.Get(PostedSalesDocNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(SalesInvoiceHeader."Invoice Discount Amount",
          SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT",
          0,
          SalesPostedAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        VerifyPostedFieldValues(SalesHeaderAmounts, SalesPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderDisplaysDocTotalsAddTaxGroupCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesOrder: TestPage "Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when adding Tax Group Code on Sales Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesOrder.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderDisplaysDocTotalsUpdateQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesOrder: TestPage "Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when changing Quantity on Sales Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created a sales document with a sales line item that defaults the Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        SalesOrder.SalesLines.Next();

        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderDisplaysDocTotalsNoInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesOrder: TestPage "Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Order Doc Totals, Sales Tax are calculated but Invoice Discount is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::Order, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        SalesOrder.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderDisplaysDocTotalsWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesOrder: TestPage "Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Order Doc Totals, Tax and Inv Discount are calculated when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::Order, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        SalesOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        SalesOrder.SalesLines."Unit Price".SetValue(SalesLine."Unit Price");
        SalesOrder.SalesLines.Next();

        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalSalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesOrder: TestPage "Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Order Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that defaults the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesOrder: TestPage "Sales Order";
        SalesHeaderAmounts: array[5] of Decimal;
        SalesPostedAmounts: array[5] of Decimal;
        VATAmount: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        PostedSalesDocNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Post]
        // [SCENARIO 136987] Doc Totals and taxes match before and after posting on Sales Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line with no default Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesOrderPageEdit(SalesOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          SalesHeaderAmounts);

        // [WHEN] User Posts the invoice
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.
        SalesInvoiceHeader.Get(PostedSalesDocNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(SalesInvoiceHeader."Invoice Discount Amount",
          SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT",
          0,
          SalesPostedAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        VerifyPostedFieldValues(SalesHeaderAmounts, SalesPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderDisplaysDocTotalsAddTaxGroupCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesReturnOrder: TestPage "Sales Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when adding Tax Group Code on Sales Return Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Return Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesReturnOrder.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesReturnOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        SalesReturnOrder.SalesLines."Unit Price".SetValue(SalesLine."Unit Price");
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesReturnOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesReturnOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderDisplaysDocTotalsUpdateQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesReturnOrder: TestPage "Sales Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when changing Quantity on Sales Return Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created a sales document with a sales line item that defaults the Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Return Order", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        SalesReturnOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        if SalesReturnOrder.SalesLines.Next() then
            SalesReturnOrder.SalesLines.Previous();

        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderDisplaysDocTotalsNoInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesReturnOrder: TestPage "Sales Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Return Order Doc Totals, Sales Tax are calculated but Inv Disc is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::"Return Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesReturnOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        SalesReturnOrder.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesReturnOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesReturnOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesReturnOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        SalesReturnOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderDisplaysDocTotalsWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        SalesReturnOrder: TestPage "Sales Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Return Order Doc Totals, Tax and Inv Discount are calc'd when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::"Return Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        SalesReturnOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesReturnOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesReturnOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);
        SalesReturnOrder.SalesLines.Next();

        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalSalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesReturnOrder: TestPage "Sales Return Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Return Order Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that defaults the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Return Order", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        SalesReturnOrder.SalesLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesReturnOrderPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesHeaderAmounts: array[5] of Decimal;
        SalesPostedAmounts: array[5] of Decimal;
        VATAmount: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        PostedSalesDocNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Post]
        // [SCENARIO 136987] Doc Totals and taxes match before and after posting on Sales Return Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line with no default Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Return Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesReturnOrderPageEdit(SalesReturnOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesReturnOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesReturnOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesReturnOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Total VAT Amount".AsDecimal(),
          SalesReturnOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesReturnOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          SalesHeaderAmounts);

        // [WHEN] User Posts the invoice
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.
        SalesCrMemoHeader.Get(PostedSalesDocNo);
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(SalesCrMemoHeader."Invoice Discount Amount",
          SalesCrMemoHeader.Amount,
          SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount,
          SalesCrMemoHeader."Amount Including VAT",
          0,
          SalesPostedAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        VerifyPostedFieldValues(SalesHeaderAmounts, SalesPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCrMemoDisplaysDocTotalsAddTaxGroupCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesCrMemo: TestPage "Sales Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        TotalTax: Decimal;
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when adding Tax Group Code on Credit Memo
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesCrMemo.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesCrMemo.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesCrMemo.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesCrMemo.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCrMemoDisplaysDocTotalsUpdateQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesCrMemo: TestPage "Sales Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when changing Quantity on Credit Memo
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created a sales document with a sales line item that defaults the Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        SalesCrMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        SalesCrMemo.SalesLines.Next();

        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCrMemoDisplaysDocTotalsNoInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCrMemo: TestPage "Sales Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Credit Memo Doc Totals, Sales Tax are calculated but Inv Disc is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesCrMemo.SalesLines."Invoice Discount Amount".AssertEquals(0);
        SalesCrMemo.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesCrMemo.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesCrMemo.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesCrMemo.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        SalesCrMemo.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCrMemoDisplaysDocTotalsWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesCrMemo: TestPage "Sales Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Credit Memo Doc Totals, Tax and Inv Discount are calc'd when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        SalesCrMemo.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesCrMemo.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesCrMemo.SalesLines."Unit Price".SetValue(OriginalUnitPrice);
        SalesCrMemo.SalesLines.Next();

        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalSalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCrMemoDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesCrMemo: TestPage "Sales Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Credit Memo Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that defaults the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        SalesCrMemo.SalesLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCrMemoPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCrMemo: TestPage "Sales Credit Memo";
        SalesHeaderAmounts: array[5] of Decimal;
        SalesPostedAmounts: array[5] of Decimal;
        VATAmount: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        PostedSalesDocNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Post]
        // [SCENARIO 136987] Doc Totals and taxes match before and after posting on Credit Memo
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line with no default Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCrMemo, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesCrMemo.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesCrMemo.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesCrMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCrMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCrMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          SalesHeaderAmounts);

        // [WHEN] User Posts the invoice
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.
        SalesCrMemoHeader.Get(PostedSalesDocNo);
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT");
        SetCompareAmounts(SalesCrMemoHeader."Invoice Discount Amount",
          SalesCrMemoHeader.Amount,
          SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount,
          SalesCrMemoHeader."Amount Including VAT",
          0,
          SalesPostedAmounts);

        // [THEN] Posted amounts should match the pre-posted amounts
        VerifyPostedFieldValues(SalesHeaderAmounts, SalesPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesBlanketOrderDisplaysDocTotalsAddTaxGroupCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when adding Tax Group Code on Blanket Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Blanket Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesBlanketOrderPageEdit(BlanketSalesOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        BlanketSalesOrder.SalesLines."Total VAT Amount".AssertEquals(0);
        BlanketSalesOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesBlanketOrderPageEdit(BlanketSalesOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        BlanketSalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        BlanketSalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesBlanketOrderDisplaysDocTotalsUpdateQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when changing Quantity on Blanket Order
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created a sales document with a sales line item that defaults the Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Blanket Order", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesBlanketOrderPageEdit(BlanketSalesOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        BlanketSalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));

        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesBlanketOrderDisplaysDocTotalsNoInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Blanket Order Doc Totals, Sales Tax are calculated but Invoice Discount is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::"Blanket Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesBlanketOrderPageEdit(BlanketSalesOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        BlanketSalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        BlanketSalesOrder.SalesLines."Total VAT Amount".AssertEquals(0);
        BlanketSalesOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesBlanketOrderPageEdit(BlanketSalesOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        BlanketSalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        BlanketSalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        BlanketSalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesBlanketOrderDisplaysDocTotalsWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Blanket Order Doc Totals, Tax and Inv Discount are calculated when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::"Blanket Order", TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesBlanketOrderPageEdit(BlanketSalesOrder, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        BlanketSalesOrder.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesBlanketOrderPageEdit(BlanketSalesOrder, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        BlanketSalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        BlanketSalesOrder.SalesLines."Unit Price".SetValue(OriginalUnitPrice);
        BlanketSalesOrder.SalesLines.Next();

        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalSalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesBlanketOrderDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Blanket Order Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that defaults the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Blanket Order", TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesBlanketOrderPageEdit(BlanketSalesOrder, SalesHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        BlanketSalesOrder.SalesLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(BlanketSalesOrder.SalesLines."Invoice Discount Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total VAT Amount".AsDecimal(),
          BlanketSalesOrder.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          BlanketSalesOrder.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteDisplaysDocTotalsAddTaxGroupCode()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesQuote: TestPage "Sales Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Tax Group Code]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when adding Tax Group Code on Sales Quote
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesQuote.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesQuote.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesQuote.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesQuote.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteDisplaysDocTotalsUpdateQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesQuote: TestPage "Sales Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CreditWarningSetup: Option "Both Warnings","Credit Limit","Overdue Balance","No Warning";
        StockWarningSetup: Boolean;
    begin
        // [FEATURE] [Quantity]
        // [SCENARIO 136987] Doc Totals with Sales Tax are updated when changing Quantity on Sales Quote
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        PrepareSalesReceivableSetupWarnings(StockWarningSetup, CreditWarningSetup);

        // [GIVEN] User has created a sales document with a sales line item that defaults the Tax Group Code
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User changes the quantity
        SalesQuote.SalesLines.Quantity.SetValue(LibraryRandom.RandDec(10, 2));
        SalesQuote.SalesLines.Next();

        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine), RoundingPrecision, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteDisplaysDocTotalsNoInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesQuote: TestPage "Sales Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        OriginalUnitPrice: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Quote Doc Totals, Sales Tax are calculated but Invoice Discount is not per setup option
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := false;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::Quote, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        SalesQuote.SalesLines."Invoice Discount Amount".AssertEquals(0);
        SalesQuote.SalesLines."Total VAT Amount".AssertEquals(0);
        SalesQuote.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        OriginalUnitPrice := SalesLine."Unit Price";
        SalesQuote.SalesLines."Unit Price".SetValue(OriginalUnitPrice + 1);
        SalesQuote.SalesLines."Unit Price".SetValue(OriginalUnitPrice);

        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page but Inv Discount is 0
        SalesQuote.SalesLines."Invoice Discount Amount".AssertEquals(0);
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          PostAmounts[FieldType::DiscountPercent], RoundingPrecision, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteDisplaysDocTotalsWithInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesQuote: TestPage "Sales Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Quote Doc Totals, Tax and Inv Discount are calculated when setup option marked
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that did not default the Tax Code Group
        CreateSalesDocumentWithInvDisc(SalesLine, SalesHeader."Document Type"::Quote, TaxPercentage, false, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);
        SalesQuote.Close();

        // [WHEN] User sets the Tax Group Code
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);
        // Re-assign this value to get RedistributeTotalsOnAfterValidate invoked
        // Mimic the behavior of assigning the Tax Group Code through the page,
        // which is not feasible through Page Testability because Visible == FALSE
        SalesQuote.SalesLines."Unit Price".SetValue(SalesLine."Unit Price");
        SalesQuote.SalesLines.Next();

        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated, Invoice Discount and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, false);

        LibraryNotificationMgt.RecallNotificationsForRecord(OriginalSalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteDisplaysDocTotalsUpdateInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        SalesQuote: TestPage "Sales Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        VATAmount: Decimal;
        TotalTax: Decimal;
        TaxPercentage: Integer;
        TaxGroupCode: Code[20];
        CalcInvDisc: Boolean;
    begin
        // [FEATURE] [Invoice Discount Amount]
        // [SCENARIO 136987] Sales Quote Doc Totals, Tax and Invoice Discount are updated when changing Inv Disc Amount
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        CalcInvDisc := true;
        SetupCalcInvoiceDisc(CalcInvDisc);

        // [GIVEN] User has created a sales document with a sales line that defaults the Tax Code Group
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote, TaxPercentage, true, TaxGroupCode);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);

        // Store values from window before setting the Invoice Discount Amount
        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PreAmounts);

        // [WHEN] User sets the Invoice Discount Amount
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(LibraryRandom.RandIntInRange(1, 1));

        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the TotalTax, and flowfields
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        // [THEN] Taxes are calculated and totals updated on page
        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax,
          SalesCalcDiscByType.GetCustInvoiceDiscountPct(OriginalSalesLine), RoundingPrecision, true);
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
    var
        LibrarySmallBusiness: Codeunit "Library - Small Business";
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
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        VATEntry.DeleteAll();

        LibrarySetupStorage.Restore();
        LibraryApplicationArea.ClearApplicationAreaCache();
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        CreateVATPostingSetup();
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

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
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

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxPercentage: Integer; DefaultTaxCodeOnItem: Boolean; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxGroupCodeItem: Code[20];
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        TaxGroupCode := TaxDetail."Tax Group Code";
        if DefaultTaxCodeOnItem then
            TaxGroupCodeItem := TaxGroupCode;
        CreateSalesDocumentWithCertainTax(SalesLine, DocumentType, TaxAreaCode, TaxGroupCodeItem);
    end;

    local procedure CreateSalesDocumentWithCertainTax(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateTaxGroup(TaxGroupCode);
        CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(TaxAreaCode));
        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::None);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(TaxGroupCode),
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify();
    end;

    local procedure CreateSalesDocumentWithInvDisc(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxPercentage: Integer; DefaultTaxCodeOnItem: Boolean; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        Customer: Record Customer;
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCodeItem: Code[20];
        ItemQuantity: Decimal;
        DiscPct: Decimal;
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxPercentage);
        TaxGroupCode := TaxDetail."Tax Group Code";
        if DefaultTaxCodeOnItem then
            TaxGroupCodeItem := TaxGroupCode;
        SetupDataForDiscountTypePct(Customer, DiscPct, TaxAreaCode, ItemNo, ItemQuantity, TaxGroupCodeItem);
        CreateSalesDocumentWithCertainTaxAndDisc(SalesLine, DocumentType, Customer."No.", ItemNo, TaxAreaCode);
    end;

    local procedure CreateSalesDocumentWithCertainTaxAndDisc(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; ItemNo: Code[20]; TaxAreaCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        CreateTaxGroup('');
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        if IsCalcInvDiscountMarked() then
            SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::"%");
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify();
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          ItemNo,
          LibraryRandom.RandInt(10));  // Using RANDOM value for Quantity.
        Item.Get(ItemNo);
        SalesLine.Validate("Tax Group Code", Item."Tax Group Code");
        SalesLine.Modify();
    end;

    local procedure GetRandomCode(FieldLength: Integer) RandomCode: Code[20]
    begin
        RandomCode := LibraryUtility.GenerateGUID();
        repeat
            RandomCode += Format(LibraryRandom.RandInt(9));  // Generating any Random integer value.
        until StrLen(RandomCode) = FieldLength;
    end;

    local procedure OpenSalesCrMemoPageEdit(var SalesCreditMemo: TestPage "Sales Credit Memo"; SalesHeader: Record "Sales Header")
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesInvoicePageEdit(var SalesInvoice: TestPage "Sales Invoice"; SalesHeader: Record "Sales Header")
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesQuotePageEdit(var SalesQuote: TestPage "Sales Quote"; SalesHeader: Record "Sales Header")
    begin
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesOrderPageEdit(var SalesOrder: TestPage "Sales Order"; SalesHeader: Record "Sales Header")
    begin
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesReturnOrderPageEdit(var SalesReturnOrder: TestPage "Sales Return Order"; SalesHeader: Record "Sales Header")
    begin
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesBlanketOrderPageEdit(var BlanketSalesOrder: TestPage "Blanket Sales Order"; SalesHeader: Record "Sales Header")
    begin
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);
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

    local procedure VerifyFieldValues(SalesHeader: Record "Sales Header"; PreAmounts: array[5] of Decimal; PostAmounts: array[5] of Decimal; TotalTax: Decimal; TotalDiscountPercent: Decimal; RoundingPrecision: Decimal; LineAmountUpdated: Boolean)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        if LineAmountUpdated then
            Assert.AreNotEqual(
              PreAmounts[FieldType::TotalAmountExcTax],
              PostAmounts[FieldType::TotalAmountExcTax],
              'Before and after amounts for Total Amount Excluding Tax should not be equal')
        else
            Assert.AreEqual(
              PreAmounts[FieldType::TotalAmountExcTax],
              PostAmounts[FieldType::TotalAmountExcTax],
              'Before and after amounts for Total Amount Excluding Tax should be equal');

        Assert.AreNotEqual(
          PreAmounts[FieldType::TotalAmountIncTax],
          PostAmounts[FieldType::TotalAmountIncTax],
          'Before and after amounts for Total Amount Including Tax should not be equal');
        Assert.AreNotEqual(
          PreAmounts[FieldType::TaxAmount],
          PostAmounts[FieldType::TaxAmount],
          'Before and after amounts for Tax Amount should not be equal');

        VerifyTotals(SalesHeader, PostAmounts, TotalTax, TotalDiscountPercent, RoundingPrecision);
    end;

    local procedure VerifyPostedFieldValues(SalesHeaderAmounts: array[5] of Decimal; SalesPostedAmounts: array[5] of Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreEqual(SalesHeaderAmounts[FieldType::InvoiceDiscountAmount], SalesPostedAmounts[FieldType::InvoiceDiscountAmount],
          'Posted Invoice Discount Amount not equal to pre-posted value.');
        Assert.AreEqual(SalesHeaderAmounts[FieldType::TotalAmountExcTax], SalesPostedAmounts[FieldType::TotalAmountExcTax],
          'Posted Total Amount Excluding Tax not equal to pre-posted value.');
        Assert.AreEqual(SalesHeaderAmounts[FieldType::TaxAmount], SalesPostedAmounts[FieldType::TaxAmount],
          'Posted Tax Amount not equal to pre-posted value.');
        Assert.AreEqual(SalesHeaderAmounts[FieldType::TotalAmountIncTax], SalesPostedAmounts[FieldType::TotalAmountIncTax],
          'Posted Total Amount Including Tax not equal to pre-posted value.');
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
        Assert.AreNotEqual(PostAmounts[FieldType::TaxAmount], 0,
          'The Tax Amount is zero and should not be');
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
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", Option);
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

    [Scope('OnPrem')]
    procedure IsCalcInvDiscountMarked(): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        exit(SalesReceivablesSetup."Calc. Inv. Discount");
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

    local procedure CreateTaxGroup(TaxGroupCode: Code[20])
    var
        TaxGroup: Record "Tax Group";
    begin
        if not TaxGroup.Get(TaxGroupCode) then begin
            TaxGroup.Init();
            TaxGroup.Validate(Code, TaxGroupCode);
            TaxGroup.Validate(Description, TaxGroup.Code);
            TaxGroup.Insert(true);
        end;
    end;
}

