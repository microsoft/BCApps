codeunit 142054 SalesDocTotalsWithSalesTax
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
        LibraryUtility: Codeunit "Library - Utility";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        SalesInvoice: TestPage "Sales Invoice";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
    begin
        // [SCENARIO 136984] For page Mini Sales Invoice Subform (1305) Entry
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        LibraryLowerPermissions.SetSalesDocsCreate();
        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          0,
          PreAmounts);
        SalesInvoice.Close();

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);
        SalesInvoice.SalesLines."Invoice Discount Amount".AssertEquals(0);

        // [WHEN] User sets the Invoice Discount Amount
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        SalesInvoice.Close();

        // [THEN] Total amounts match Sales Header amounts
        // Reopen the window with the updated record
        OpenSalesInvoicePageView(SalesInvoice, SalesHeader);

        SetCompareAmounts(SalesInvoice.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(),
          SalesInvoice.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesInvoice.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find();
        PreAmounts[FieldType::DiscountPercent] := SalesCalcDiscountByType.GetCustInvoiceDiscountPct(SalesLine);
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithExciseTax()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        SalesInvoice: TestPage "Sales Invoice";
        TaxPercent: Decimal;
        TaxAreaCode: Code[20];
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        Item: Record Item;
        CustomerCreated: Code[20];
        ItemCreated: Code[20];
    begin
        // The following verifies excise tax when there is no unit cost or amount per line.  Bug 313016 reported by customer.
        Initialize();

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // Create excise tax to be used by purchase invoice
        TaxPercent := LibraryRandom.RandIntInRange(10, 20);
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Excise Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercent);
        TaxDetail.Validate("Expense/Capitalize", false);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");

        CustomerCreated := CreateCustomer(TaxAreaCode);
        ItemCreated := CreateItem(TaxDetail."Tax Group Code");
        Item.Get(ItemCreated);
        Item."Unit Price" := 0;
        Item.Modify(true);

        // Create sales invoice and assign tax area
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerCreated);
        SalesHeader."Tax Area Code" := TaxArea.Code;
        SalesHeader."Tax Liable" := true;
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine,
          SalesHeader, SalesLine.Type::Item, ItemCreated, LibraryRandom.RandInt(10));
        SalesLine.Modify();
        SalesLine."Line No." += 10000;
        SalesLine.Insert();

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Verify amounts:  "Total Amoun Excl. Tax" = 0, "Total VAT Amount" and "Total Amount Incl. VAT" = (2 * quantity * excise tax amount) 
        SalesInvoice.SalesLines."Total Amount Excl. VAT".AssertEquals(0);
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(Round(2 * SalesLine.Quantity * TaxPercent));
        SalesInvoice.SalesLines."Total Amount Incl. VAT".AssertEquals(0 + 2 * SalesLine.Quantity * TaxPercent);
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithExciseTaxPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        SalesInvoice: TestPage "Sales Invoice";
        TaxPercent: Decimal;
        TaxAreaCode: Code[20];
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
        TaxGroup: Record "Tax Group";
        Item: Record Item;
        CustomerCreated: Code[20];
        ItemCreated: Code[20];
        SalesInvHeader: Record "Sales Invoice Header";
        PostedSalesDocNo: Code[20];
        Assert: Codeunit Assert;
    begin
        // The following verifies the posting of excise tax when there is no unit cost or amount per line.  Bug 313016 reported by customer.
        Initialize();

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // Create excise tax to be used by purchase invoice
        TaxPercent := LibraryRandom.RandIntInRange(10, 20);
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Excise Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercent);
        TaxDetail.Validate("Expense/Capitalize", false);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");

        CustomerCreated := CreateCustomer(TaxAreaCode);
        ItemCreated := CreateItem(TaxDetail."Tax Group Code");
        Item.Get(ItemCreated);
        Item."Unit Price" := 0;
        Item.Modify(true);

        // Create sales invoice and assign tax area
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerCreated);
        SalesHeader."Tax Area Code" := TaxArea.Code;
        SalesHeader."Tax Liable" := true;
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine,
          SalesHeader, SalesLine.Type::Item, ItemCreated, LibraryRandom.RandInt(10));
        SalesLine.Modify();
        SalesLine."Line No." += 10000;
        SalesLine.Insert();

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // Verify amounts:  "Total Amoun Excl. Tax" = 0, "Total VAT Amount" and "Total Amount Incl. VAT" = (2 * quantity * excise tax amount) 
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        SalesInvoice.SalesLines."Total Amount Excl. VAT".AssertEquals(0);
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(Round(2 * SalesLine.Quantity * TaxPercent));
        SalesInvoice.SalesLines."Total Amount Incl. VAT".AssertEquals(0 + 2 * SalesLine.Quantity * TaxPercent);
        Assert.AreEqual(0, SalesHeader.Amount, 'SalesHeader.Amount is incorrect');
        Assert.AreEqual(2 * SalesLine.Quantity * TaxPercent, SalesHeader."Amount Including VAT", 'SalesHeader."Amount Including VAT" is incorrect');
        SalesInvoice.Close();

        // Post invoice and verify amounts
        LibraryLowerPermissions.SetSalesDocsPost();
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvHeader.Get(PostedSalesDocNo);
        SalesInvHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        Assert.AreEqual(0, SalesInvHeader.Amount, 'SalesHeader.Amount is incorrect');
        Assert.AreEqual(2 * SalesLine.Quantity * TaxPercent, SalesInvHeader."Amount Including VAT", 'SalesHeader."Amount Including VAT" is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        OriginalSalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        SalesHeaderAmounts: array[5] of Decimal;
        SalesPostedAmounts: array[5] of Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        PostedSalesDocNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 136984] For page Sales Invoice Subform (43) Posting
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);
        SalesInvoice.SalesLines."Invoice Discount Amount".SetValue(
          SalesInvoice.SalesLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        SalesInvoice.Close();

        // Reopen the window with the updated record
        OpenSalesInvoicePageView(SalesInvoice, SalesHeader);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find();
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");

        SetCompareAmounts(SalesHeader."Invoice Discount Amount",
          SalesHeader.Amount,
          SalesHeader."Amount Including VAT" - SalesHeader.Amount,
          SalesHeader."Amount Including VAT", 0, SalesHeaderAmounts);

        // [WHEN] User posts the Sales Invoice
        LibraryLowerPermissions.SetSalesDocsPost();
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.

        // [THEN] Posted amounts should match the pre-posted amounts
        SalesInvoiceHeader.Get(PostedSalesDocNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SetCompareAmounts(SalesInvoiceHeader."Invoice Discount Amount",
          SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount,
          SalesInvoiceHeader."Amount Including VAT", 0, SalesPostedAmounts);

        VerifyPostedFieldValues(SalesHeaderAmounts, SalesPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
    begin
        // [SCENARIO 136984] For page Mini Sales Credit Memo Subform (1320) Entry
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        LibraryLowerPermissions.SetSalesDocsCreate();
        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCreditMemo, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          0,
          PreAmounts);
        SalesCreditMemo.Close();

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesCrMemoPageEdit(SalesCreditMemo, SalesHeader);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".AssertEquals(0);

        // [WHEN] User sets the Invoice Discount Amount and Tax Group Code
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        SalesCreditMemo.Close();

        // [THEN] Total amounts match Sales Header amounts
        // Reopen the window with the updated record
        OpenSalesCrMemoPageView(SalesCreditMemo, SalesHeader);

        SetCompareAmounts(SalesCreditMemo.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesCreditMemo.SalesLines."Total VAT Amount".AsDecimal(),
          SalesCreditMemo.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesCreditMemo.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find();
        PreAmounts[FieldType::DiscountPercent] := SalesCalcDiscountByType.GetCustInvoiceDiscountPct(SalesLine);
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        SalesHeaderAmounts: array[5] of Decimal;
        SalesPostedAmounts: array[5] of Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        PostedSalesDocNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 136984] For page Mini Sales Credit Memo Subform (1320) Posting
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        LibraryLowerPermissions.SetSalesDocsPost();
        OriginalSalesLine := SalesLine;

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesCrMemoPageEdit(SalesCreditMemo, SalesHeader);
        SalesCreditMemo.SalesLines."Invoice Discount Amount".SetValue(
          SalesCreditMemo.SalesLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        SalesCreditMemo.Close();

        // Reopen the window with the updated record
        OpenSalesCrMemoPageView(SalesCreditMemo, SalesHeader);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find();
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");

        SetCompareAmounts(SalesHeader."Invoice Discount Amount",
          SalesHeader.Amount,
          SalesHeader."Amount Including VAT" - SalesHeader.Amount,
          SalesHeader."Amount Including VAT", 0, SalesHeaderAmounts);

        // [WHEN] User posts the Sales Credit Memo
        PostedSalesDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Posted amounts should match the pre-posted amounts
        SalesCrMemoHeader.Get(PostedSalesDocNo);
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SetCompareAmounts(SalesCrMemoHeader."Invoice Discount Amount",
          SalesCrMemoHeader.Amount,
          SalesCrMemoHeader."Amount Including VAT" - SalesCrMemoHeader.Amount,
          SalesCrMemoHeader."Amount Including VAT", 0, SalesPostedAmounts);

        VerifyPostedFieldValues(SalesHeaderAmounts, SalesPostedAmounts);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        SalesQuote: TestPage "Sales Quote";
        PreAmounts: array[5] of Decimal;
        PostAmounts: array[5] of Decimal;
        RoundingPrecision: Decimal;
        InvDiscAmtPct: Decimal;
        TaxPercentage: Integer;
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
        TotalTax: Decimal;
    begin
        // [SCENARIO 136984] For page Mini Sales Quote Subform (1325) Entry
        // Setup
        Initialize();
        TaxPercentage := LibraryRandom.RandInt(9);
        InvDiscAmtPct := LibraryRandom.RandDecInDecimalRange(0.01, 0.09, 1);

        // [GIVEN] User has created a sales document with a sales line containing sales tax
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Quote, TaxGroupCode, TaxPercentage, TaxAreaCode);

        // Store away the line created, to pull back in later
        LibraryLowerPermissions.SetSalesDocsPost();
        OriginalSalesLine := SalesLine;
        RoundingPrecision := 0.01;

        SalesHeader.Get(OriginalSalesLine."Document Type", OriginalSalesLine."Document No.");
        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);

        // Store values from window before setting the Tax Group Code
        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          0,
          PreAmounts);
        SalesQuote.Close();

        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        OpenSalesQuotePageEdit(SalesQuote, SalesHeader);
        SalesQuote.SalesLines."Invoice Discount Amount".AssertEquals(0);

        // [WHEN] User sets the Invoice Discount Amount and Tax Group Code
        SalesQuote.SalesLines."Invoice Discount Amount".SetValue(
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal() * InvDiscAmtPct);
        SalesQuote.Close();

        // [THEN] Total amounts match Sales Header amounts
        // Reopen the window with the updated record
        OpenSalesQuotePageView(SalesQuote, SalesHeader);

        SetCompareAmounts(SalesQuote.SalesLines."Invoice Discount Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Excl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Total VAT Amount".AsDecimal(),
          SalesQuote.SalesLines."Total Amount Incl. VAT".AsDecimal(),
          SalesQuote.SalesLines."Invoice Disc. Pct.".AsDecimal(),
          PostAmounts);

        // Calculate the CustInvoiceDiscountPct, TotalTax, and flowfields
        SalesLine := OriginalSalesLine;
        SalesLine.Find();
        PreAmounts[FieldType::DiscountPercent] := SalesCalcDiscountByType.GetCustInvoiceDiscountPct(SalesLine);
        SalesHeader.CalcFields("Invoice Discount Amount", Amount, "Amount Including VAT");
        TotalTax := SalesHeader."Amount Including VAT" - SalesHeader.Amount;

        VerifyFieldValues(SalesHeader, PreAmounts, PostAmounts, TotalTax, RoundingPrecision);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TaxAreaOnSalesOrderFromShipToAddress()
    var
        SalesHeader: Record "Sales Header";
        ShipToAddressTaxAreaCode: Code[20];
        SellToCustomerTaxAreaCode: Code[20];
        BillToCustomerTaxAreaCode: Code[20];
    begin
        // [FEATURE] [Tax Area]
        // [SCENARIO 358143] Tax Area Code on Sales Order should be the same as Tax Area Code of Ship-to Address if specified 
        Initialize();

        // [GIVEN] Tax Area Code specified for Sell-to Customer, Bill-to Customer and Ship-to Address
        ShipToAddressTaxAreaCode := CreateTaxAreaCode();
        SellToCustomerTaxAreaCode := CreateTaxAreaCode();
        BillToCustomerTaxAreaCode := CreateTaxAreaCode();

        // [WHEN] Create a Sales Order
        CreateSalesOrderWithTaxAreaSetup(SalesHeader, ShipToAddressTaxAreaCode, SellToCustomerTaxAreaCode, BillToCustomerTaxAreaCode);

        // [THEN] Tax Area Code of Sales Order have to be the same as Tax Area Code of Ship-to Address 
        SalesHeader.TestField("Tax Area Code", ShipToAddressTaxAreaCode);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TaxAreaOnSalesOrderFromSellToCustomer()
    var
        SalesHeader: Record "Sales Header";
        ShipToAddressTaxAreaCode: Code[20];
        SellToCustomerTaxAreaCode: Code[20];
        BillToCustomerTaxAreaCode: Code[20];
    begin
        // [FEATURE] [Tax Area]
        // [SCENARIO 358143] Tax Area Code on Sales Order should be the same as Tax Area Code of Sell-to Customer if there is no Tax Area Code for Ship-to Address
        Initialize();

        // [GIVEN] Tax Area Code specified for Sell-to Customer and Bill-to Customer
        ShipToAddressTaxAreaCode := '';
        SellToCustomerTaxAreaCode := CreateTaxAreaCode();
        BillToCustomerTaxAreaCode := CreateTaxAreaCode();

        // [WHEN] Create a Sales Order
        CreateSalesOrderWithTaxAreaSetup(SalesHeader, ShipToAddressTaxAreaCode, SellToCustomerTaxAreaCode, BillToCustomerTaxAreaCode);

        // [THEN] Tax Area Code of Sales Order have to be the same as Tax Area Code of Sell-to Customer
        SalesHeader.TestField("Tax Area Code", SellToCustomerTaxAreaCode);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure TaxAreaOnSalesOrderFromBillToCustomer()
    var
        SalesHeader: Record "Sales Header";
        ShipToAddressTaxAreaCode: Code[20];
        SellToCustomerTaxAreaCode: Code[20];
        BillToCustomerTaxAreaCode: Code[20];
    begin
        // [FEATURE] [Tax Area]
        // [SCENARIO 358143] Tax Area Code on Sales Order should be the same as Tax Area Code of Bill-to Customer if there are no Tax Area Code for Ship-to Address and Sell-to Customer
        Initialize();

        // [GIVEN] Tax Area Code specified only for Bill-to Customer
        ShipToAddressTaxAreaCode := '';
        SellToCustomerTaxAreaCode := '';
        BillToCustomerTaxAreaCode := CreateTaxAreaCode();

        // [WHEN] Create a Sales Order
        CreateSalesOrderWithTaxAreaSetup(SalesHeader, ShipToAddressTaxAreaCode, SellToCustomerTaxAreaCode, BillToCustomerTaxAreaCode);

        // [THEN] Tax Area Code of Sales Order have to be the same as Tax Area Code of Bill-to Customer 
        SalesHeader.TestField("Tax Area Code", BillToCustomerTaxAreaCode);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ShipToAddressListModalPageHandler,ConfirmHandlerYes')]
    procedure SalesTaxUpdatedInSalesInvoiceWhenShipToChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetailCust: Record "Tax Detail";
        TaxDetailAddr: Record "Tax Detail";
        DocumentTotals: Codeunit "Document Totals";
        SalesInvoice: TestPage "Sales Invoice";
        CustomerNo: Code[20];
        ShipToCode: Code[10];
        TaxAreaCodeCust: Code[20];
        TaxAreaCodeAddr: Code[20];
        ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
    begin
        // [SCENARIO 371637] Change Ship-to Code in Sales Invoice in case Customer and Ship-to Address have different Tax Areas.
        Initialize();
        TaxAreaCodeCust := CreateTaxAreaWithLine(TaxDetailCust, LibraryRandom.RandIntInRange(5, 10));
        TaxAreaCodeAddr := CreateTaxAreaWithLine(TaxDetailAddr, LibraryRandom.RandIntInRange(15, 20));
        TaxDetailAddr.Rename(
            TaxDetailAddr."Tax Jurisdiction Code", TaxDetailCust."Tax Group Code",
            TaxDetailAddr."Tax Type", TaxDetailAddr."Effective Date");

        // [GIVEN] Customer with Tax Area "CTA" with "Tax Below Maximum" = 5%.
        // [GIVEN] Customer has Ship-to Address "SHA" with Tax Area "ATA" with "Tax Below Maximum" = 15%.
        CustomerNo := CreateCustomer(TaxAreaCodeCust);
        ShipToCode := CreateShipToAddressCode(CustomerNo, TaxAreaCodeAddr);
        UpdateShipToCodeOnCustomer(CustomerNo, ShipToCode);
        LibraryVariableStorage.Enqueue(ShipToCode);

        // [GIVEN] Sales Invoice for Customer.
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo,
            CreateItem(TaxDetailCust."Tax Group Code"), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        DocumentTotals.SalesRedistributeInvoiceDiscountAmountsOnDocument(SalesHeader);

        // [GIVEN] Opened Sales Invoice card. Ship-to is "Alternate Shipping Address", Ship-to Code is "SHA".
        SalesInvoice.OpenEdit();
        SalesInvoice.Filter.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.ShippingOptions.AssertEquals(ShipToOptions::"Alternate Shipping Address");

        // [WHEN] Change Ship-to to "Default (Sell-to Address)".
        SalesInvoice.ShippingOptions.SetValue(ShipToOptions::"Default (Sell-to Address)");

        // [THEN] Tax Area Code is changed to "CTA" (tax 5%). "Total VAT Amount" is changed to SalesLine.Amount * 0.05.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesInvoice."Tax Area Code".AssertEquals(TaxAreaCodeCust);
        Assert.AreNearlyEqual(
            SalesLine.Amount * TaxDetailCust."Tax Below Maximum" / 100,
            SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), '');

        // [WHEN] Change Ship-to back to "Alternate Shipping Address". Select Ship-to Address "SHA" in the Ship-to Address list.
        SalesInvoice.ShippingOptions.SetValue(ShipToOptions::"Alternate Shipping Address");

        // [THEN] Tax Area Code is changed to "ATA" (tax 15%). "Total VAT Amount" is changed to SalesLine.Amount * 0.15.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesInvoice."Tax Area Code".AssertEquals(TaxAreaCodeAddr);
        Assert.AreNearlyEqual(
            SalesLine.Amount * TaxDetailAddr."Tax Below Maximum" / 100,
            SalesInvoice.SalesLines."Total VAT Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ShipToAddressListModalPageHandler,ConfirmHandlerYes')]
    procedure SalesTaxUpdatedInSalesOrderWhenShipToChanged()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetailCust: Record "Tax Detail";
        TaxDetailAddr: Record "Tax Detail";
        DocumentTotals: Codeunit "Document Totals";
        SalesOrder: TestPage "Sales Order";
        CustomerNo: Code[20];
        ShipToCode: Code[10];
        TaxAreaCodeCust: Code[20];
        TaxAreaCodeAddr: Code[20];
        ShipToOptions: Option "Default (Sell-to Address)","Alternate Shipping Address","Custom Address";
    begin
        // [SCENARIO 371637] Change Ship-to Code in Sales Order in case Customer and Ship-to Address have different Tax Areas.
        Initialize();
        TaxAreaCodeCust := CreateTaxAreaWithLine(TaxDetailCust, LibraryRandom.RandIntInRange(5, 10));
        TaxAreaCodeAddr := CreateTaxAreaWithLine(TaxDetailAddr, LibraryRandom.RandIntInRange(15, 20));
        TaxDetailAddr.Rename(
            TaxDetailAddr."Tax Jurisdiction Code", TaxDetailCust."Tax Group Code",
            TaxDetailAddr."Tax Type", TaxDetailAddr."Effective Date");

        // [GIVEN] Customer with Tax Area "CTA" with "Tax Below Maximum" = 5%.
        // [GIVEN] Customer has Ship-to Address "SHA" with Tax Area "ATA" with "Tax Below Maximum" = 15%.
        CustomerNo := CreateCustomer(TaxAreaCodeCust);
        ShipToCode := CreateShipToAddressCode(CustomerNo, TaxAreaCodeAddr);
        UpdateShipToCodeOnCustomer(CustomerNo, ShipToCode);
        LibraryVariableStorage.Enqueue(ShipToCode);

        // [GIVEN] Sales Order for Customer.
        LibrarySales.CreateSalesDocumentWithItem(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo,
            CreateItem(TaxDetailCust."Tax Group Code"), LibraryRandom.RandDecInRange(10, 20, 2), '', WorkDate());
        DocumentTotals.SalesRedistributeInvoiceDiscountAmountsOnDocument(SalesHeader);

        // [GIVEN] Opened Sales Order card. Ship-to is "Alternate Shipping Address", Ship-to Code is "SHA".
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.ShippingOptions.AssertEquals(ShipToOptions::"Alternate Shipping Address");

        // [WHEN] Change Ship-to to "Default (Sell-to Address)".
        SalesOrder.ShippingOptions.SetValue(ShipToOptions::"Default (Sell-to Address)");

        // [THEN] Tax Area Code is changed to "CTA" (tax 5%). "Total VAT Amount" is changed to SalesLine.Amount * 0.05.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesOrder."Tax Area Code".AssertEquals(TaxAreaCodeCust);
        Assert.AreNearlyEqual(
            SalesLine.Amount * TaxDetailCust."Tax Below Maximum" / 100,
            SalesOrder.SalesLines."Total VAT Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), '');

        // [WHEN] Change Ship-to back to "Alternate Shipping Address". Select Ship-to Address "SHA" in the Ship-to Address list.
        SalesOrder.ShippingOptions.SetValue(ShipToOptions::"Alternate Shipping Address");

        // [THEN] Tax Area Code is changed to "ATA" (tax 15%). "Total VAT Amount" is changed to SalesLine.Amount * 0.15.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesOrder."Tax Area Code".AssertEquals(TaxAreaCodeAddr);
        Assert.AreNearlyEqual(
            SalesLine.Amount * TaxDetailAddr."Tax Below Maximum" / 100,
            SalesOrder.SalesLines."Total VAT Amount".AsDecimal(), LibraryERM.GetAmountRoundingPrecision(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceSalesTaxWithExpenseTaxDetails()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        SalesInvoice: TestPage "Sales Invoice";
        TaxPercent: Decimal;
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Invoice] [Expense/Capitalize]
        // [SCENARIO 407399] Tax Amount must be calculated in Document Totals when "Expense/Capitalize" is true in Tax Details
        Initialize();

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // [GIVEN] Tax setup where tax detail with "Expense/Capitalize" = true and "Tax Below Maximum" = 10%
        TaxPercent := LibraryRandom.RandIntInRange(10, 20);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, true, TaxPercent);

        CreateSalesDocumentWithCertainTax(SalesLine, SalesHeader."Document Type"::Invoice, TaxDetail, TaxAreaCode, TaxDetail."Tax Group Code");

        // [WHEN] Open Sales Invoice card page
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesInvoicePageEdit(SalesInvoice, SalesHeader);

        // [THEN] "Total Amoun Excl. Tax" = 100
        // [THEN] "Total Tax" = (100 * 10%) = 10;
        // [THEN] "Total Amoun Incl. Tax" = 110
        SalesLine.TestField(Amount);
        SalesInvoice.SalesLines."Total Amount Excl. VAT".AssertEquals(Round(SalesLine.Amount));
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(Round(SalesLine.Amount * TaxPercent / 100));
        SalesInvoice.SalesLines."Total Amount Incl. VAT".AssertEquals(Round(SalesLine.Amount * (100 + TaxPercent) / 100));
        SalesInvoice.Close();
    end;

    [Test]
    procedure SalesInvoiceWithExciseTaxACY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        TaxGroup: array[2] of Record "Tax Group";
        TaxArea: Record "Tax Area";
        TaxJurisdiction: array[3] of Record "Tax Jurisdiction";
        GLEntry: Record "G/L Entry";
        ExchangeRate: Decimal;
        TaxRate: array[3] of Decimal;
    begin
        // [FEATURE] [FCY] [ACY] [Sales Tax]
        // [SCENARIO 409905] The ACY Amount must be calculated within other amount for Excise Tax with "Calculate Tax on Tax" option.

        Initialize();

        LibraryERM.CreateTaxArea(TaxArea);
        TaxArea.Validate("Country/Region", TaxArea."Country/Region"::CA);
        TaxArea.Modify(true);

        TaxRate[1] := 6.36;
        TaxRate[2] := 15;
        TaxRate[3] := 0;
        CreateTaxGroupCode3JurisdictionWithExciseTax(TaxGroup[1], TaxJurisdiction, TaxArea.Code, TaxRate);

        CreateCustomerFCY(Customer, ExchangeRate, TaxArea.Code);

        LibraryERM.SetAddReportingCurrency(Customer."Currency Code");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::Item, CreateItem(TaxGroup[1].Code), LibraryRandom.RandIntInRange(10, 20));

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        TaxJurisdiction[1].TestField("Tax Account (Sales)");
        GLEntry.SetRange("G/L Account No.", TaxJurisdiction[1]."Tax Account (Sales)");
        GLEntry.FindFirst();
        GLEntry.TestField("Additional-Currency Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShippedNotInvoicedWithExpenseTaxDetails()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TaxPercent: Decimal;
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Order] [Expense/Capitalize]
        // [SCENARIO 407399] 
        Initialize();

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Full();

        // [GIVEN] Tax setup where tax detail with "Expense/Capitalize" = true and "Tax Below Maximum" = 10%
        TaxPercent := LibraryRandom.RandIntInRange(10, 20);
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, true, TaxPercent);

        // [GIVEN] Sales order with Quantity = 10, "Unit Price" = 7, "Qty. to Invoice" = 3 and "Qty. to Ship" = 10
        CreateSalesDocumentWithCertainTax(SalesLine, SalesHeader."Document Type"::Order, TaxDetail, TaxAreaCode, TaxDetail."Tax Group Code");
        SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity / 3);
        SalesLine.Modify(true);

        // [WHEN] Post order
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "Shipped not Invoiced" = (Quantity - Qty. Invoiced) * "Unit Price" * "Tax Percent" = (10 - 3) * 7 * (100 + 10%) = 53.9
        SalesLine.Find();
        SalesLine.TestField("Qty. Shipped Not Invoiced", SalesLine.Quantity * 2 / 3);
        SalesLine.TestField("Shipped Not Invoiced", SalesLine."Unit Price" * SalesLine.Quantity * 2 / 3 * (1 + TaxPercent / 100));
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;

        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        LibraryERMCountryData.CreateVATData();
        Clear(VATPostingSetup);
        if not VATPostingSetup.Get('', '') then begin
            VATPostingSetup."VAT Bus. Posting Group" := '';
            VATPostingSetup."VAT Prod. Posting Group" := '';
            VATPostingSetup."VAT Calculation Type" := VATPostingSetup."VAT Calculation Type"::"Sales Tax";
            VATPostingSetup.Insert(true);
        end;
        LibraryInventory.NoSeriesSetup(InventorySetup);

        isInitialized := true;
        Commit();
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", '');
        Item.Validate("Unit Price", LibraryRandom.RandIntInRange(10, 20));
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        exit(Item."No.");
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
        Customer.Validate("RFC No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("RFC No.")) - 1));  // Taken Length less than RFC No. Length as Tax Identification Type is Legal Entity.
        Customer.Validate("CURP No.", GetRandomCode(LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("CURP No."))));
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerFCY(var Customer: Record 18; var ExchangeRate: Decimal; TaxAreaCode: Code[20])
    var
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), ExchangeRate, ExchangeRate);

        Customer.Get(CreateCustomer(TaxAreaCode));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; TaxAreaCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader."Tax Area Code" := TaxAreaCode;
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercentage);
        TaxDetail.Modify(true);
    end;

    local procedure CreateSalesTaxDetailWithTaxPercent(var TaxDetail: Record "Tax Detail"; TaxGroupCode: Code[20]; TaxJurisdictionCode: Code[10]; TaxType: Option; TaxPercentage: Decimal);
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxType, WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercentage);
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

    local procedure CreateSalesTaxJurisdiction_CA(var TaxJurisdiction: Record "Tax Jurisdiction"; CalculateTaxOnTax: Boolean);
    begin
        TaxJurisdiction.Get(CreateSalesTaxJurisdiction());
        TaxJurisdiction.Validate("Country/Region", TaxJurisdiction."Country/Region"::CA);
        TaxJurisdiction.Validate("Calculate Tax on Tax", CalculateTaxOnTax);
        TaxJurisdiction.Modify(true);
    end;

    local procedure CreateSalesTaxAreaLineWithOrder(TaxAreaCode: Code[20]; TaxJurisdictionCode: Code[10]; CalculationOrder: Integer);
    var
        TaxAreaLine: Record 319;
    begin
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
        TaxAreaLine.Validate("Calculation Order", CalculationOrder);
        TaxAreaLine.Modify(true);
    end;

    local procedure CreateTaxAreaWithLine(var TaxDetail: Record "Tax Detail"; TaxPercentage: Integer): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, TaxPercentage);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxGroupCode3JurisdictionWithExciseTax(var TaxGroup: Record "Tax Group"; var TaxJurisdiction: array[3] of Record "Tax Jurisdiction"; TaxAreaCode: Code[20]; TaxRate: array[3] of Decimal);
    var
        TaxDetail: array[3] of Record "Tax Detail";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);

        CreateSalesTaxJurisdiction_CA(TaxJurisdiction[1], true);
        CreateSalesTaxJurisdiction_CA(TaxJurisdiction[2], false);
        CreateSalesTaxJurisdiction_CA(TaxJurisdiction[3], false);

        CreateSalesTaxDetailWithTaxPercent(
            TaxDetail[1], TaxGroup.Code, TaxJurisdiction[1].Code, TaxDetail[1]."Tax Type"::"Excise Tax", TaxRate[1]);
        CreateSalesTaxDetailWithTaxPercent(
            TaxDetail[2], TaxGroup.Code, TaxJurisdiction[2].Code, TaxDetail[2]."Tax Type"::"Sales and Use Tax", TaxRate[2]);
        CreateSalesTaxDetailWithTaxPercent(
            TaxDetail[3], TaxGroup.Code, TaxJurisdiction[3].Code, TaxDetail[3]."Tax Type"::"Sales and Use Tax", TaxRate[3]);

        CreateSalesTaxAreaLineWithOrder(TaxAreaCode, TaxDetail[1]."Tax Jurisdiction Code", 1);
        CreateSalesTaxAreaLineWithOrder(TaxAreaCode, TaxDetail[2]."Tax Jurisdiction Code", 2);
        CreateSalesTaxAreaLineWithOrder(TaxAreaCode, TaxDetail[3]."Tax Jurisdiction Code", 3);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; var TaxGroupCode: Code[20]; TaxPercentage: Integer; var TaxAreaCode: Code[20]): Decimal
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxAreaCode := CreateTaxAreaWithLine(TaxDetail, TaxPercentage);
        TaxGroupCode := TaxDetail."Tax Group Code";
        exit(CreateSalesDocumentWithCertainTax(SalesLine, DocumentType, TaxDetail, TaxAreaCode, TaxGroupCode));
    end;

    local procedure CreateSalesDocumentWithCertainTax(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(TaxAreaCode), TaxAreaCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(TaxGroupCode),
          LibraryRandom.RandIntInRange(10, 20) * 3);
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure CreateShipToAddressCode(CustomerNo: Code[20]; TaxAreaCode: Code[20]): Code[10]
    var
        ShipToAddress: Record "Ship-to Address";
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        ShipToAddress.Validate("Tax Liable", true);
        ShipToAddress.Validate("Tax Area Code", TaxAreaCode);
        ShipToAddress.Modify(true);
        exit(ShipToAddress.Code);
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

    local procedure OpenSalesCrMemoPageView(var SalesCreditMemo: TestPage "Sales Credit Memo"; SalesHeader: Record "Sales Header")
    begin
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesInvoicePageView(var SalesInvoice: TestPage "Sales Invoice"; SalesHeader: Record "Sales Header")
    begin
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
    end;

    local procedure OpenSalesQuotePageView(var SalesQuote: TestPage "Sales Quote"; SalesHeader: Record "Sales Header")
    begin
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
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

    local procedure UpdateShipToCodeOnCustomer(CustomerNo: Code[20]; ShipToCode: Code[10])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Ship-to Code", ShipToCode);
        Customer.Modify(true);
    end;

    local procedure VerifyFieldValues(SalesHeader: Record "Sales Header"; PreAmounts: array[5] of Decimal; PostAmounts: array[5] of Decimal; TotalTax: Decimal; RoundingPrecision: Decimal)
    var
        Assert: Codeunit Assert;
        FieldType: Option ,InvoiceDiscountAmount,TotalAmountExcTax,TaxAmount,TotalAmountIncTax,DiscountPercent;
    begin
        Assert.AreNotEqual(
          PreAmounts[FieldType::TotalAmountExcTax],
          PostAmounts[FieldType::TotalAmountExcTax],
          'Before and after amounts for Total Amount Excluding Tax should not be equal');
        Assert.AreNotEqual(
          PreAmounts[FieldType::TotalAmountIncTax],
          PostAmounts[FieldType::TotalAmountIncTax],
          'Before and after amounts for Total Amount Including Tax should not be equal');
        Assert.AreEqual(
          PreAmounts[FieldType::TaxAmount],
          PostAmounts[FieldType::TaxAmount],
          'Before and after amounts for Tax Amount should not be equal');

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
          PreAmounts[FieldType::DiscountPercent],
          RoundingPrecision,
          'Customer Discount Percent value is incorrect');
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

    local procedure CreateSalesOrderWithTaxAreaSetup(var SalesHeader: Record "Sales Header"; ShipToAddressTaxAreaCode: Code[20]; SellToCustomerTaxAreaCode: Code[20]; BillToCustomerTaxAreaCode: Code[20])
    var
        SellToCustomer: Record Customer;
        BillToCustomer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
    begin
        SellToCustomer.Get(CreateCustomer(SellToCustomerTaxAreaCode));
        BillToCustomer.Get(CreateCustomer(BillToCustomerTaxAreaCode));

        LibrarySales.CreateShipToAddress(ShipToAddress, SellToCustomer."No.");
        ShipToAddress.Validate("Tax Liable", true);
        ShipToAddress.Validate("Tax Area Code", ShipToAddressTaxAreaCode);
        ShipToAddress.Modify(true);

        SellToCustomer.Validate("Ship-to Code", ShipToAddress.Code);
        SellToCustomer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Modify(true);
    end;

    local procedure CreateTaxAreaCode(): Code[20];
    var
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"; ExpenseCapitalize: Boolean; TaxPercent: Decimal): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, ExpenseCapitalize, TaxPercent);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; ExpenseCapitalize: Boolean; TaxPercent: Decimal)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxDetail."Tax Type"::"Sales Tax Only", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxPercent);
        TaxDetail.Validate("Expense/Capitalize", ExpenseCapitalize);
        TaxDetail.Modify(true);
    end;

    [ModalPageHandler]
    procedure ShipToAddressListModalPageHandler(var ShipToAddressList: TestPage "Ship-to Address List");
    begin
        ShipToAddressList.Filter.SetFilter(Code, LibraryVariableStorage.DequeueText());
        ShipToAddressList.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := True;
    end;
}

