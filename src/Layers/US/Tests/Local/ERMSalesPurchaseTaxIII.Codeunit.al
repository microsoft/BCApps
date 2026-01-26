codeunit 142092 "ERM Sales/Purchase Tax III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Sales Tax]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMTax: Codeunit "Library - ERM Tax";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        DummyTaxCountry: Option US,CA;
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscEqualsTo100Pct_PrepmtExclTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment, invoice discount (prepayment % + discount % = 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = FALSE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Sales order with prepayment (85%), invoice discount (15%), several lines with different tax setup
        CreateSalesOrder_TFS229419(SalesHeader, 15, 85, false);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, 31.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscEqualsTo100Pct_PrepmtInclTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment, invoice discount (prepayment % + discount % = 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = TRUE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Sales order with prepayment (85%), invoice discount (15%), several lines with different tax setup
        CreateSalesOrder_TFS229419(SalesHeader, 15, 85, true);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, AmountIncludingVAT, -31.02, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscMoreThan100Pct_PrepmtExclTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment, invoice discount (prepayment % + discount % > 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = FALSE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Sales order with prepayment (85.01%), invoice discount (15%), several lines with different tax setup
        CreateSalesOrder_TFS229419(SalesHeader, 15, 85.01, false);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, 31.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtAndInvDiscMoreThan100Pct_PrepmtInclTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Sales]
        // [SCENARIO 229419] Sales order post in case of prepayment, invoice discount (prepayment % + discount % > 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = TRUE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Sales order with prepayment (85.01%), invoice discount (15%), several lines with different tax setup
        CreateSalesOrder_TFS229419(SalesHeader, 15, 85.01, true);
        VerifySalesHeaderTotals(SalesHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, AmountIncludingVAT, -31.02, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscEqualsTo100Pct_PrepmtExclTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment, invoice discount (prepayment % + discount % = 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = FALSE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Purchase order with prepayment (85%), invoice discount (15%), several lines with different tax setup
        CreatePurchaseOrder_TFS229419(PurchaseHeader, 15, 85, false);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, 31.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscEqualsTo100Pct_PrepmtInclTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment, invoice discount (prepayment % + discount % = 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = TRUE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Purchase order with prepayment (85%), invoice discount (15%), several lines with different tax setup
        CreatePurchaseOrder_TFS229419(PurchaseHeader, 15, 85, true);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, AmountIncludingVAT, -31.02, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscMoreThan100Pct_PrepmtExclTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment, invoice discount (prepayment % + discount % > 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = FALSE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Purchase order with prepayment (85.01%), invoice discount (15%), several lines with different tax setup
        CreatePurchaseOrder_TFS229419(PurchaseHeader, 15, 85.01, false);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, Amount, 0, 31.02);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepmtAndInvDiscMoreThan100Pct_PrepmtInclTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Invoice Discount] [Rounding] [Purchase]
        // [SCENARIO 229419] Purchase order post in case of prepayment, invoice discount (prepayment % + discount % > 100),
        // [SCENARIO 229419] several lines with different tax detail setup, "Prepmt. Include Tax" = TRUE
        Initialize();
        PrepareExpectedAmounts_TFS229419(Amount, AmountIncludingVAT, InvoiceDiscountAmount, VATAmount);

        // [GIVEN] Purchase order with prepayment (85.01%), invoice discount (15%), several lines with different tax setup
        CreatePurchaseOrder_TFS229419(PurchaseHeader, 15, 85.01, true);
        VerifyPurchaseHeaderTotals(PurchaseHeader, Amount, AmountIncludingVAT, InvoiceDiscountAmount, Amount);

        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Posted prepayment invoice has Amount = 443.27, Amount Including VAT = 443.27
        // [THEN] Posted final invoice has Amount = -31.02, Amount Including VAT = 0
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, AmountIncludingVAT, -31.02, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTwoLinesProvTaxExpenseCapitalize()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        NoTaxAreaCode: Code[20];
        TaxAreaCode: Code[20];
        ProvTaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        GLAccountNo: array[2] of Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 231225] Purchase invoice posting in case of two lines and three tax areas: NOTAX, TAX, Provincial TAX,
        // [SCENARIO 231225] where Provincial TAX has several tax justisdictions invlucding Expense/Capitalize
        Initialize();

        // [GIVEN] "NOTAX", "TAX" ("Tax Below Maximum" = 5), "PROVTAX" ("Tax Below Maximum" = 1.6\3.4\0.56\7.44, where 1.6\0.56 have Expense/Capitalize = TRUE) areas
        CreateTaxSetup_TFS231225(NoTaxAreaCode, TaxAreaCode, ProvTaxAreaCode, TaxGroupCode);
        // [GIVEN] Purchase invoice with header's "Tax Area Code" = NOTAX and two lines:
        // [GIVEN] line1: Type = "G/L Account", "No." = "GLACC1", "Tax Area Code" = TAX, "Provincial Tax Area Code" = "", "Direct Unit Cost" = 100
        // [GIVEN] line2: Type = "G/L Account", "No." = "GLACC2", "Tax Area Code" = NOTAX, "Provincial Tax Area Code" = "PROVTAX", "Direct Unit Cost" = 300
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorWithVATBusPostingGroup(''), NoTaxAreaCode, 0, false);
        GLAccountNo[1] := CreateGLAccountNoWithBlankVATSetup();
        CreatePurchaseLineGLWithProvincialTax(PurchaseHeader, GLAccountNo[1], TaxAreaCode, TaxGroupCode, '', 100);
        GLAccountNo[2] := CreateGLAccountNoWithBlankVATSetup();
        CreatePurchaseLineGLWithProvincialTax(PurchaseHeader, GLAccountNo[2], NoTaxAreaCode, TaxGroupCode, ProvTaxAreaCode, 300);

        // [WHEN] Post the invoice
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] Posted invoice has Amount = 400, Amount Including VAT = 405
        // [THEN] There is GLEntry with "G/L Account No." = "GLACC1", "Amount" = 100
        // [THEN] There is GLEntry with "G/L Account No." = "GLACC2", "Amount" = 306.48
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, 400, 405);
        VerifyGLEntry(PurchInvHeader."No.", GLAccountNo[1], 100);
        VerifyGLEntry(PurchInvHeader."No.", GLAccountNo[2], 306.48);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GetReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationAfterGetReceipLinesOnPurcaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        VendorNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Expense/Capitalize] [Get Receipt Lines]
        // [SCENARIO 233346] Incorrect Tax Amount on the Purchase Invoice subform after Getting Receipt Lines from received not invoiced Purchase Order with "Expense/Capitalize" = TRUE in Tax Details
        Initialize();

        // [GIVEN] Tax area "BC" with "Country/Region" = CA having two lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Received not invoiced Purchase Order for Vendor "V", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        // [GIVEN] Purchase Line with Tax Amount = 100
        CreateCustomPurchaseDocWithOneLine_TFS233346(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, TaxAreaCode, TaxGroupCode[1], '');
        ValidatePurchaseOrderTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine.Type::"G/L Account");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;

        // [GIVEN] Purchase Invoice for Vendor "V", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        CreatePurchaseHeaderWithTaxAreaForVendor(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxAreaCode, VendorNo);

        // [WHEN] Get Receipt Lines
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.GotoRecord(PurchaseHeader);
        PurchaseInvoice.PurchLines.GetReceiptLines.Invoke();

        // [THEN] "Total VAT" on the Purchase Invoice page = 100
        PurchaseInvoice.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,GetReturnShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationAfterGetReturnShipmentLinesOnPurcaseCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        VendorNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Expense/Capitalize] [Get Return Shipment Lines]
        // [SCENARIO 233346] Incorrect Tax Amount on the Purchase Cr. Memo subform after Getting Return Shipment Lines from shipped not invoiced Purchase Cr. Memo with "Expense/Capitalize" = TRUE in Tax Details
        Initialize();

        // [GIVEN] Tax area "BC" with "Country/Region" = CA having two lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Shipped not invoiced Purchase Return Order for Vendor "V", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        // [GIVEN] Purchase Line with Tax Amount = 100
        CreateCustomPurchaseDocWithOneLine_TFS233346(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", TaxAreaCode, TaxGroupCode[1], '');
        ValidatePurchaseReturnOrderTaxAreaThroughPage(PurchaseHeader, TaxAreaCode);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine.Type::"G/L Account");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;

        // [GIVEN] Purchase Credit Memo for Vendor "V", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        CreatePurchaseHeaderWithTaxAreaForVendor(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '', TaxAreaCode, VendorNo);

        // [WHEN] Get Return Shipment Lines
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.GotoRecord(PurchaseHeader);
        PurchaseCreditMemo.PurchLines.GetReturnShipmentLines.Invoke();

        // [THEN] "Total VAT" on the Purchase Credit Memo page = 100
        PurchaseCreditMemo.PurchLines."Total VAT Amount".AssertEquals(VATAmount);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationAfterGetShipmentLinesOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        CustNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Expense/Capitalize] [Get Shipment Lines]
        // [SCENARIO 233346] Incorrect Tax Amount on the Sales Invoice Subform after Getting Shipment Lines from shipped not invoiced Sales Order with "Expense/Capitalize" = TRUE in Tax Details
        Initialize();

        // [GIVEN] Tax area "BC" with "Country/Region" = CA having two lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Shipped not invoiced Sales Order for Customer "C", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        // [GIVEN] Sales Line with Tax Amount = 100
        CreateCustomSalesDocWithOneLine_TFS233346(
          SalesHeader, SalesHeader."Document Type"::Order, TaxAreaCode, TaxGroupCode[1], '');
        ValidateSalesOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CustNo := SalesHeader."Sell-to Customer No.";
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;

        // [GIVEN] Sales Invoice for Customer "C", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        CreateSalesHeaderWithTaxAreaForCustomer(SalesHeader, SalesHeader."Document Type"::Invoice, '', TaxAreaCode, CustNo);

        // [WHEN] Get Shipment Lines
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.SalesLines.GetShipmentLines.Invoke();

        // [THEN] "Total VAT" on the Sales Invoice page = 100
        SalesInvoice.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
    end;

    [Test]
    [HandlerFunctions('GetReturnReceiptLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationAfterGetReturnReceiptLinesOnSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[2] of Code[20];
        CustNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Expense/Capitalize] [Get Return Receipt Lines]
        // [SCENARIO 233346] Incorrect Tax Amount on the Sales Cr. Memo Subform after Getting Return Receipt Lines from Received not invoiced Sales Return Order with "Expense/Capitalize" = TRUE in Tax Details
        Initialize();

        // [GIVEN] Tax area "BC" with "Country/Region" = CA having two lines and custom Tax Detail setup lines including "Expense/Capitalize" = TRUE
        CreateCustomTaxSetup_TFS210430(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);

        // [GIVEN] Received not invoiced Sales Return Order for Customer "C", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        // [GIVEN] Sales Line with Tax Amount = 100
        CreateCustomSalesDocWithOneLine_TFS233346(
          SalesHeader, SalesHeader."Document Type"::"Return Order", TaxAreaCode, TaxGroupCode[1], '');
        ValidateSalesReturnOrderTaxAreaThroughPage(SalesHeader, TaxAreaCode);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        CustNo := SalesHeader."Sell-to Customer No.";
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;

        // [GIVEN] Sales Credit Memo for Customer "C", "Tax Liable" = Yes, "Tax Area Code" = 'BC'
        CreateSalesHeaderWithTaxAreaForCustomer(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '', TaxAreaCode, CustNo);

        // [WHEN] Get Return Receipt Lines
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.SalesLines."Get Return &Receipt Lines".Invoke();

        // [THEN] "Total VAT" on the Sales Credit Memo page = 100
        SalesCreditMemo.SalesLines."Total VAT Amount".AssertEquals(VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmt25PctCustomAmountsIncludeTax()
    var
        SalesHeader: Record "Sales Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
    begin
        // [FEATURE] [Prepayment] [Rounding] [Sales]
        // [SCENARIO 262985] Sales order post in case of 25% prepayment, several lines with custom amount, prepayment include tax
        Initialize();

        // [GIVEN] Sales order with 25% prepayment, several lines with custom amount, prepayment include tax
        CreateSalesOrder_TFS262985(SalesHeader);
        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Invoice has been posted
        VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, 2008.69, 5101.55, 6025.88);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmt25PctCustomAmountsIncludeTax()
    var
        PurchaseHeader: Record "Purchase Header";
        PrepmtDocNo: Code[20];
        InvoiceDocNo: Code[20];
    begin
        // [FEATURE] [Prepayment] [Rounding] [Purchase]
        // [SCENARIO 262985] Purchase order post in case of 25% prepayment, several lines with custom amount, prepayment include tax
        Initialize();

        // [GIVEN] Purchase order with 25% prepayment, several lines with custom amount, prepayment include tax
        CreatePurchaseOrder_TFS262985(PurchaseHeader);
        // [GIVEN] Post prepayment invoice
        PrepmtDocNo := LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [WHEN] Post final invoice
        InvoiceDocNo := PostPurchaseDocument(PurchaseHeader);

        // [THEN] Invoice has been posted
        VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo, InvoiceDocNo, 2008.68, 5101.55, 6025.88);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchExpenseCapitalizePositiveAndNegativeLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Rounding] [Purchase] [Negative Line] [Expense/Capitalize]
        // [SCENARIO 273130] Posting purchase invoice with positive and negative lines, custom Tax setup having Expense/Capitalize, amounts with rounding
        Initialize();

        // [GIVEN] Purchase invoice with positive and negative line, Expense/Capitalize Tax setup, custom amounts with rounding (Total Tax = -829.035)
        CreatePurchaseOrder_TFS273130(PurchaseHeader);
        VerifyPurchaseVATTotalAfterRelease(PurchaseHeader, -829.04);

        // [WHEN] Post the invoice
        PurchInvHeader.Get(PostPurchaseDocument(PurchaseHeader));

        // [THEN] The invoice has been posted
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, 1685, 855.96);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesExpenseCapitalizePositiveAndNegativeLine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // [FEATURE] [Rounding] [Sales] [Negative Line] [Expense/Capitalize]
        // [SCENARIO 273130] Posting sales invoice with positive and negative lines, custom Tax setup having Expense/Capitalize, amounts with rounding
        Initialize();

        // [GIVEN] Sales invoice with positive and negative line, Expense/Capitalize Tax setup, custom amounts with rounding (Total Tax = -829.035)
        CreateSalesOrder_TFS273130(SalesHeader);
        VerifySalesVATTotalAfterRelease(SalesHeader, -829.04);

        // [WHEN] Post the invoice
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The invoice has been posted
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, 1685, 855.96);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPositiveAndNegativeLine_US()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Negative Line]
        // [SCENARIO 280515] Posting of sales order with positive and negative lines, custom Tax setup (Country = US)
        Initialize();

        // [GIVEN] Sales order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        CreateSalesOrder_TFS280515(SalesHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The order has been posted
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPositiveAndNegativeLine_US()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Negative Line]
        // [SCENARIO 280515] Posting of purchase order with positive and negative lines, custom Tax setup (Country = US)
        Initialize();

        // [GIVEN] Purchase order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        CreatePurchaseOrder_TFS280515(PurchaseHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] The order has been posted
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithPositiveAndNegativeLine_US()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Service] [Negative Line]
        // [SCENARIO 280515] Posting of service order with positive and negative lines, custom Tax setup (Country = US)
        Initialize();

        // [GIVEN] Service order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        CreateServiceOrder_TFS280515(ServiceHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The order has been posted
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader);
        VerifyPostedServiceInvoiceTotals(ServiceInvoiceHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithPositiveAndNegativeLine_CA()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Sales] [Negative Line]
        // [SCENARIO 280515] Posting of sales order with positive and negative lines, custom Tax setup (Country = CA)
        Initialize();

        // [GIVEN] Sales order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        CreateSalesOrder_TFS280515(SalesHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [THEN] The order has been posted
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithPositiveAndNegativeLine_CA()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Purchase] [Negative Line]
        // [SCENARIO 280515] Posting of purchase order with positive and negative lines, custom Tax setup (Country = CA)
        Initialize();

        // [GIVEN] Purchase order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        CreatePurchaseOrder_TFS280515(PurchaseHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [THEN] The order has been posted
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, 423.1, 444.26);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceOrderWithPositiveAndNegativeLine_CA()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Rounding] [Service] [Negative Line]
        // [SCENARIO 280515] Posting of service order with positive and negative lines, custom Tax setup (Country = CA)
        Initialize();

        // [GIVEN] Service order with positive and negative lines, custom amounts with rounding (Total Tax = 21.155)
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA);
        CreateServiceOrder_TFS280515(ServiceHeader, TaxAreaCode, TaxGroupCode);

        // [WHEN] Post the order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] The order has been posted
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader);
        VerifyPostedServiceInvoiceTotals(ServiceInvoiceHeader, 423.1, 444.26);
    end;

    [Test]
    [HandlerFunctions('DraftSalesInvoiceRPH')]
    [Scope('OnPrem')]
    procedure TaxCalculationInDraftSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Draft Sales Invoice]
        // [SCENARIO 283166] Draft Sales Invoice in case of Tax Country = CA, two taxes from different jurisdictions
        Initialize();

        // [GIVEN] Tax setup with "Country/Region" = CA and two different jurisdictions with 5% and 7% taxes
        CreateTaxSetup_TFS283166(TaxAreaCode, TaxGroupCode);

        // [GIVEN] Sales Header with custom tax setup and sales line with unit price equal to 77024.70
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithTaxArea(TaxAreaCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountNo(), 1);
        SalesLine.Validate("Unit Price", 77024.7);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        // [WHEN] Report is run
        SalesHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::"Standard Sales - Draft Invoice", true, false, SalesHeader);

        // [THEN] TotalAmountIncludingVAT in report equals to 86267.67
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalAmountIncludingVAT', 86267.67);
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRPH')]
    [Scope('OnPrem')]
    procedure TaxCalculationInSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales Quote]
        // [SCENARIO 283166] Sales Quote in case of Tax Country = CA, two taxes from different jurisdictions
        Initialize();

        // [GIVEN] Tax setup with "Country/Region" = CA and two different jurisdictions with 5% and 7% taxes
        CreateTaxSetup_TFS283166(TaxAreaCode, TaxGroupCode);

        // [GIVEN] Sales Header with custom tax setup and sales line with unit price equal to 77024.70
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomerWithTaxArea(TaxAreaCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountNo(), 1);
        SalesLine.Validate("Unit Price", 77024.7);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        // [WHEN] Report is run
        SalesHeader.SetRecFilter();
        Commit();
        REPORT.Run(REPORT::"Standard Sales - Quote", true, false, SalesHeader);

        // [THEN] TotalAmountIncludingVAT in report equals to 86267.67
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalAmountIncludingVAT', Format(86267.67));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationBeforeEffectiveDateOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Effective Date]
        // [SCENARIO 300462] Tax Amounts recalculated when set Posting Date before Effective Date of Tax Details in Sales Invoice
        Initialize();

        // [GIVEN] Sales Invoice with Amount = 100 and Tax = 5% with Effective Date = 01-01-19
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithTaxArea(TaxAreaCode));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);

        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst();

        // [WHEN] Set Posting Date 31-12-18 on Sales Invoice
        SalesHeader.Validate("Posting Date", TaxDetail."Effective Date" - 1);
        SalesHeader.Modify(true);
        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(SalesLine, VATAmount, TotalSalesLine);

        // [THEN] Sales Line has VAT % = 0 and "Amount Including VAT" = Amount of 100.
        SalesLine.Find();
        SalesLine.TestField("VAT %", 0);
        SalesLine.TestField("Amount Including VAT", SalesLine.Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TaxCalculationBeforeEffectiveDateOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TotalPurchaseLine: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Effective Date]
        // [SCENARIO 300462] Tax Amounts recalculated when set Posting Date before Effective Date of Tax Details in Purchase Invoice
        Initialize();

        // [GIVEN] Purchase Invoice with Amount = 100 and Tax = 5% with Effective Date = 01-01-19
        CreateTaxSetup_TFS280515(TaxAreaCode, TaxGroupCode, DummyTaxCountry::US);
        CreatePurchaseHeaderWithTaxAreaForVendor(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', TaxAreaCode,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(''));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccountNoWithBlankVATSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);

        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst();

        // [WHEN] Set Posting Date 31-12-18 on Purchase Invoice
        PurchaseHeader.Validate("Posting Date", TaxDetail."Effective Date" - 1);
        PurchaseHeader.Modify(true);
        DocumentTotals.PurchaseRedistributeInvoiceDiscountAmounts(PurchaseLine, VATAmount, TotalPurchaseLine);

        // [THEN] Purchase Line has VAT % = 0 and "Amount Including VAT" = Amount of 100.
        PurchaseLine.Find();
        PurchaseLine.TestField("VAT %", 0);
        PurchaseLine.TestField("Amount Including VAT", PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TaxLiablePerSalesLine()
    var
        Customer: Record Customer;
        ShipToAddressNoTax: Record "Ship-to Address";
        ShipToAddressTaxLiable: Record "Ship-to Address";
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        VATEntry: Record "VAT Entry";
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        SalesInvoiceNo: Code[20];
        TaxPercent: Decimal;
        SalesOrderAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Sales] [Invoice] [Combine Shipments]
        // [SCENARIO 334744] Only sales lines up to Tax Liable are included in tax calculation.
        Initialize();
        TaxPercent := LibraryRandom.RandInt(10);

        // [GIVEN] Tax area code "TA", Tax group code = "TG", Tax = 3%.
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA());
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxPercent);

        // [GIVEN] A customer with tax area code "TA" and set up for combine shipments.
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode));
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);

        // [GIVEN] Ship-to address "ADDR1" with "Tax Liable" = FALSE.
        // [GIVEN] Ship-to address "ADDR2" with "Tax Liable" = TRUE.
        LibrarySales.CreateShipToAddress(ShipToAddressNoTax, Customer."No.");
        LibrarySales.CreateShipToAddress(ShipToAddressTaxLiable, Customer."No.");
        ShipToAddressTaxLiable.Validate("Tax Liable", true);
        ShipToAddressTaxLiable.Modify(true);

        // [GIVEN] A new item.
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create two sales orders with tax area "TA" and tax group code "TG".
        // [GIVEN] The difference is that the first order has ship-to address "ADDR1" (no tax), and the second one - "ADDR2" (with tax).
        // [GIVEN] Amount incl. VAT of the first order = 100 LCY.
        CreateAndShipSalesOrderWithShipToAddr(SalesHeader, Customer."No.", ShipToAddressNoTax.Code, ItemNo, TaxGroupCode);
        SalesOrderAmount[1] := SalesHeader."Amount Including VAT";

        // [GIVEN] Amount incl. VAT of the second order = 110 LCY (100 line amount + 10 tax).
        // [GIVEN] Post both orders as ship.
        CreateAndShipSalesOrderWithShipToAddr(SalesHeader, Customer."No.", ShipToAddressTaxLiable.Code, ItemNo, TaxGroupCode);
        SalesOrderAmount[2] := SalesHeader."Amount Including VAT";

        // [GIVEN] Run "Combine shipments" to create a single invoice from both shipments.
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesShipmentHeader.SetRange("Sell-to Customer No.", Customer."No.");
        LibrarySales.CombineShipments(SalesHeader, SalesShipmentHeader, WorkDate(), WorkDate(), false, false, false, false);

        // [WHEN] Post the sales invoice.
        SalesHeaderInvoice.SetRange("Document Type", SalesHeaderInvoice."Document Type"::Invoice);
        SalesHeaderInvoice.SetRange("Sell-to Customer No.", Customer."No.");
        SalesHeaderInvoice.FindFirst();
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeaderInvoice, true, true);

        // [THEN] Invoiced amount = 210 LCY (100 + 110).
        Customer.CalcFields("Net Change");
        asserterror Customer.TestField("Net Change", SalesOrderAmount[1] + SalesOrderAmount[2]);

        // [THEN] VAT entry is created for the taxed amount only.
        // [THEN] "VAT Entry".Base = 100.
        // [THEN] "VAT Entry".Amount = 10.
        VATEntry.SetRange("Document No.", SalesInvoiceNo);
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        asserterror Assert.AreNearlyEqual(-SalesOrderAmount[2] / (1 + TaxPercent / 100), VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), '');
        asserterror Assert.AreEqual(-SalesOrderAmount[2] - VATEntry.Base, VATEntry.Amount, '');

        // [THEN] 10 LCY is posted on tax account to the general ledger.
        VerifyGLEntry(SalesInvoiceNo, TaxJurisdiction."Tax Account (Sales)", VATEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxLiablePerPurchaseLine()
    var
        Vendor: Record Vendor;
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        VATEntry: Record "VAT Entry";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        PurchInvoiceNo: Code[20];
        TaxPercent: Decimal;
        PurchOrderAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice] [Get Receipt Lines]
        // [SCENARIO 334744] Only purchase lines up to Tax Liable are included in tax calculation.
        Initialize();
        TaxPercent := LibraryRandom.RandInt(10);

        // [GIVEN] Tax area code "TA", Tax group code = "TG", Tax = 3%.
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA());
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxPercent);

        // [GIVEN] A vendor with tax area code "TA".
        Vendor.Get(CreateVendorWithTaxArea(TaxAreaCode));

        // [GIVEN] A new item.
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create two purchase orders with tax area "TA" and tax group code "TG".
        // [GIVEN] The first order is tax liable, the second one is not.
        // [GIVEN] Amount incl. VAT of the first order = 110 LCY (100 line amount + 10 tax).
        CreateAndReceivePurchOrder(PurchaseHeader, Vendor."No.", true, ItemNo, TaxAreaCode, TaxGroupCode);
        PurchOrderAmount[1] := PurchaseHeader."Amount Including VAT";

        // [GIVEN] Amount incl. VAT of the second order = 100 LCY (100 line amount, no tax).
        // [GIVEN] Post both orders as receive.
        CreateAndReceivePurchOrder(PurchaseHeader, Vendor."No.", false, ItemNo, TaxAreaCode, TaxGroupCode);
        PurchOrderAmount[2] := PurchaseHeader."Amount Including VAT";

        // [GIVEN] Create purchase invoice and populate lines using "Get Receipt Lines".
        PurchRcptLine.SetRange("Buy-from Vendor No.", Vendor."No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, Vendor."No.");
        PurchaseHeaderInvoice.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeaderInvoice.Modify(true);
        PurchGetReceipt.SetPurchHeader(PurchaseHeaderInvoice);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [WHEN] Post the purchase invoice.
        PurchInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [THEN] Invoiced amount = 210 LCY (110 + 100).
        Vendor.CalcFields("Net Change");
        asserterror Vendor.TestField("Net Change", PurchOrderAmount[1] + PurchOrderAmount[2]);

        // [THEN] VAT entry is created for the taxed amount only.
        // [THEN] "VAT Entry".Base = 100.
        // [THEN] "VAT Entry".Amount = 10.
        VATEntry.SetRange("Document No.", PurchInvoiceNo);
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        asserterror Assert.AreNearlyEqual(PurchOrderAmount[1] / (1 + TaxPercent / 100), VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), '');
        asserterror Assert.AreEqual(PurchOrderAmount[1] - VATEntry.Base, VATEntry.Amount, '');

        // [THEN] 10 LCY is posted on tax account to the general ledger.
        asserterror VerifyGLEntry(PurchInvoiceNo, TaxJurisdiction."Tax Account (Purchases)", VATEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxLiablePerServiceLine()
    var
        Customer: Record Customer;
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
        ServiceHeaderInvoice: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATEntry: Record "VAT Entry";
        ServiceGetShipment: Codeunit "Service-Get Shipment";
        ItemNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        TaxPercent: Decimal;
        ServiceOrderAmount: array[2] of Decimal;
    begin
        // [FEATURE] [Service] [Invoice] [Get Service Shipment Lines]
        // [SCENARIO 334744] Only service lines up to Tax Liable are included in tax calculation.
        Initialize();
        TaxPercent := LibraryRandom.RandInt(10);

        // [GIVEN] Tax area code "TA", Tax group code = "TG", Tax = 3%.
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA());
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxPercent);

        // [GIVEN] A customer with tax area code "TA".
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode));

        // [GIVEN] A new item.
        VATPostingSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        ItemNo := LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Create two service orders with tax area "TA" and tax group code "TG".
        // [GIVEN] The first order is tax liable, the second one is not.
        // [GIVEN] Amount incl. VAT of the first order = 110 LCY (100 line amount + 10 tax).
        CreateAndShipServiceOrder(ServiceHeader, Customer."No.", true, ItemNo, TaxAreaCode, TaxGroupCode);
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceOrderAmount[1] := Round(ServiceLine."Line Amount" * (1 + TaxPercent / 100), LibraryERM.GetAmountRoundingPrecision());

        // [GIVEN] Amount incl. VAT of the second order = 100 LCY (100 line amount, no tax).
        // [GIVEN] Post both orders as ship.
        CreateAndShipServiceOrder(ServiceHeader, Customer."No.", false, ItemNo, TaxAreaCode, TaxGroupCode);
        FindServiceLine(ServiceLine, ServiceHeader);
        ServiceOrderAmount[2] := ServiceLine."Line Amount";

        // [GIVEN] Create service invoice and populate lines using "Get Service Shipment Lines".
        ServiceShipmentLine.SetRange("Customer No.", Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeaderInvoice, ServiceHeaderInvoice."Document Type"::Invoice, Customer."No.");
        ServiceHeaderInvoice.Validate("Tax Area Code", TaxAreaCode);
        ServiceHeaderInvoice.Modify(true);
        ServiceGetShipment.SetServiceHeader(ServiceHeaderInvoice);
        ServiceGetShipment.CreateInvLines(ServiceShipmentLine);

        // [WHEN] Post the service invoice.
        LibraryService.PostServiceOrder(ServiceHeaderInvoice, false, false, false);

        // [THEN] Invoiced amount = 210 LCY (110 + 100).
        Customer.CalcFields("Net Change");
        asserterror Customer.TestField("Net Change", ServiceOrderAmount[1] + ServiceOrderAmount[2]);

        // [THEN] VAT entry is created for the taxed amount only.
        // [THEN] "VAT Entry".Base = 100.
        // [THEN] "VAT Entry".Amount = 10.
        FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeaderInvoice);
        VATEntry.SetRange("Document No.", ServiceInvoiceHeader."No.");
        Assert.RecordCount(VATEntry, 1);
        VATEntry.FindFirst();
        asserterror Assert.AreNearlyEqual(-ServiceOrderAmount[1] / (1 + TaxPercent / 100), VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), '');
        asserterror Assert.AreEqual(-ServiceOrderAmount[1] - VATEntry.Base, VATEntry.Amount, '');

        // [THEN] 10 LCY is posted on tax account to the general ledger.
        asserterror VerifyGLEntry(ServiceInvoiceHeader."No.", TaxJurisdiction."Tax Account (Sales)", VATEntry.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocWithNoTaxLiable()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 354041] VAT Entry with 0 amount is created for the sales invoice with Tax Liable = No
        Initialize();

        // [GIVEN] Tax setup with Tax area code "TA", Tax = 3%.
        CreateTaxSetup(TaxAreaCode, TaxGroupCode, LibraryRandom.RandInt(10));

        // [GIVEN] Sales Invoice for a customer with tax area code "TA" and Tax Liable = No.
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode));
        Customer.Validate("Tax Liable", false);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        CreateSalesLineGL(
          SalesHeader, CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false), TaxGroupCode, LibraryRandom.RandDecInRange(100, 200, 2));
        SalesHeader.CalcFields(Amount);

        // [WHEN] Post the sales invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] VAT Entry is created for the invoice with Amount = 0
        VerifyVATEntry(Customer."No.", -SalesHeader.Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocWithNoTaxLiable()
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Service]
        // [SCENARIO 354041] VAT Entry with 0 amount is created for the service invoice with Tax Liable = No
        Initialize();

        // [GIVEN] Tax setup with Tax area code "TA", Tax = 3%.
        CreateTaxSetup(TaxAreaCode, TaxGroupCode, LibraryRandom.RandInt(10));

        // [GIVEN] Service Invoice for a customer with tax area code "TA" and Tax Liable = No.
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode));
        Customer.Validate("Tax Liable", false);
        Customer.Modify(true);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false));
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        ServiceLine.Modify(true);

        // [WHEN] Post the service invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] VAT Entry is created for the invoice with Amount = 0
        VerifyVATEntry(Customer."No.", -ServiceLine."Line Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseDocWithNoTaxLiable()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 354041] VAT Entry with 0 amount is created for the purchase invoice with Tax Liable = No
        Initialize();

        // [GIVEN] Tax setup with Tax area code "TA", Tax = 3%.
        CreateTaxSetup(TaxAreaCode, TaxGroupCode, LibraryRandom.RandInt(10));

        // [GIVEN] Purchase Invoice for a vendor with tax area code "TA" and Tax Liable = No.
        Vendor.Get(CreateVendorWithTaxArea(TaxAreaCode));
        Vendor.Validate("Tax Liable", false);
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineGL(
          PurchaseHeader, CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false), TaxGroupCode, LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseHeader.CalcFields(Amount);

        // [WHEN] Post the purchase invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] VAT Entry is created for the invoice with Amount = 0
        VerifyVATEntry(Vendor."No.", PurchaseHeader.Amount, 0);
    end;

    [Test]
    procedure SalesIncrDecrPrepmtInvAndCrMemo100PctExclTax()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Exclude Tax]
        // [SCENARIO 388513] Sales order with 100% prepayment excl. Tax, increase\decrease prepayment invoice and credit memo
        Initialize();

        // [GIVEN] Sales order with 5% Tax, 100% prepayment excl. Tax, one line with 1 Qty and Unit Price = 1000
        CreateSalesOrder_Tax5Pct_OneLine(SalesHeader, 100, false, 1000);
        VerifySalesHeaderTotals(SalesHeader, 1000, 1050, 0, 1000);
        // [GIVEN] Posted prepayment invoice has Amount = 1000, Amount Incl. VAT = 1000
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1000, 1000);
        VerifySalesHeaderTotals(SalesHeader, 1000, 1050, 0, 1000);
        // [GIVEN] Reopen and update Quantity = 2
        ReopenAndUpdateQty(SalesHeader, 2);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 2000);
        // [GIVEN] Posted 2nd prepayment invoice has Amount = 1000, Amount Incl. VAT = 1000
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1000, 1000);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 2000);
        // [GIVEN] Posted invoice (1 quantity) has Amount = 0, Amount Incl. VAT = 50
        UpdateQtyToShip(SalesHeader, 1, '');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), 0, 50);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 2000);
        // [GIVEN] Posted prepayment creit memo has Amount = 1000, Amount Incl. VAT = 1000
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 1000, 1000);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 2000);
        // [GIVEN] Reopen and update Quantity = 3
        ReopenAndUpdateQty(SalesHeader, 3);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 3000);
        // [GIVEN] Posted 3rd prepayment invoice has Amount = 2000, Amount Incl. VAT = 2000
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 2000, 2000);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 3000);
        // [GIVEN] Posted 2nd prepayment creit memo has Amount = 2000, Amount Incl. VAT = 2000
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 2000, 2000);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 3000);
        // [GIVEN] Posted 4th prepayment invoice has Amount = 2000, Amount Incl. VAT = 2000
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 2000, 2000);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 3000);
        // [WHEN] Posted final invoice
        // [THEN] Posted final invoice has Amount = 0, Amount Incl. VAT = 100
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), 0, 100);
    end;

    [Test]
    procedure SalesIncrDecrPrepmtInvAndCrMemo100PctInclTax()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Include Tax]
        // [SCENARIO 388513] Sales order with 100% prepayment incl. Tax, increase\decrease prepayment invoice and credit memo
        Initialize();

        // [GIVEN] Sales order with 5% Tax, 100% prepayment incl. Tax, one line with 1 Qty and Unit Price = 1000
        CreateSalesOrder_Tax5Pct_OneLine(SalesHeader, 100, true, 1000);
        VerifySalesHeaderTotals(SalesHeader, 1000, 1050, 0, 1000);
        // [GIVEN] Posted prepayment invoice has Amount = 1050, Amount Incl. VAT = 1050
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1050, 1050);
        VerifySalesHeaderTotals(SalesHeader, 1000, 1050, 0, 1000);
        // [GIVEN] Reopen and update Quantity = 2
        ReopenAndUpdateQty(SalesHeader, 2);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 2000);
        // [GIVEN] Posted 2nd prepayment invoice has Amount = 1050, Amount Incl. VAT = 1050
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1050, 1050);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 2000);
        // [GIVEN] Posted invoice (1 quantity) has Amount = -50, Amount Incl. VAT = 0
        UpdateQtyToShip(SalesHeader, 1, '');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -50, 0);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 2000);
        // [GIVEN] Posted prepayment creit memo has Amount = 1050, Amount Incl. VAT = 1050
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 1050, 1050);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 2000);
        // [GIVEN] Reopen and update Quantity = 3
        ReopenAndUpdateQty(SalesHeader, 3);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 3000);
        // [GIVEN] Posted 3rd prepayment invoice has Amount = 2100, Amount Incl. VAT = 2100
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 2100, 2100);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 3000);
        // [GIVEN] Posted 2nd prepayment creit memo has Amount = 2100, Amount Incl. VAT = 2100
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 2100, 2100);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 3000);
        // [GIVEN] Posted 4th prepayment invoice has Amount = 2100, Amount Incl. VAT = 2100
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 2100, 2100);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 3000);
        // [WHEN] Posted final invoice
        // [THEN] Posted final invoice has Amount = -100, Amount Incl. VAT = 0
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -100, 0);
    end;

    [Test]
    procedure SalesIncrDecrPrepmtInvAndCrMemo80PctExclTax()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Exclude Tax]
        // [SCENARIO 388513] Sales order with 80% prepayment excl. Tax, increase\decrease prepayment invoice and credit memo
        Initialize();

        // [GIVEN] Sales order with 5% Tax, 80% prepayment excl. Tax, one line with 1 Qty and Unit Price = 1000
        CreateSalesOrder_Tax5Pct_OneLine(SalesHeader, 80, false, 1000);
        VerifySalesHeaderTotals(SalesHeader, 1000, 1050, 0, 800);
        // [GIVEN] Posted prepayment invoice has Amount = 800, Amount Incl. VAT = 800
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 800, 800);
        VerifySalesHeaderTotals(SalesHeader, 1000, 1050, 0, 800);
        // [GIVEN] Reopen and update Quantity = 2
        ReopenAndUpdateQty(SalesHeader, 2);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 1600);
        // [GIVEN] Posted 2nd prepayment invoice has Amount = 800, Amount Incl. VAT = 800
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 800, 800);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 1600);
        // [GIVEN] Posted invoice (1 quantity) has Amount = 200, Amount Incl. VAT = 250
        UpdateQtyToShip(SalesHeader, 1, '');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), 200, 250);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 1600);
        // [GIVEN] Posted prepayment creit memo has Amount = 800, Amount Incl. VAT = 800
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 800, 800);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 1600);
        // [GIVEN] Reopen and update Quantity = 3
        ReopenAndUpdateQty(SalesHeader, 3);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 2400);
        // [GIVEN] Posted 3rd prepayment invoice has Amount = 1600, Amount Incl. VAT = 1600
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1600, 1600);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 2400);
        // [GIVEN] Posted 2nd prepayment creit memo has Amount = 1600, Amount Incl. VAT = 1600
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 1600, 1600);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 2400);
        // [GIVEN] Posted 4th prepayment invoice has Amount = 1600, Amount Incl. VAT = 1600
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1600, 1600);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 2400);
        // [WHEN] Posted final invoice
        // [THEN] Posted final invoice has Amount = 400, Amount Incl. VAT = 500
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), 400, 500);
    end;

    [Test]
    procedure SalesIncrDecrPrepmtInvAndCrMemo80PctInclTax()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Include Tax]
        // [SCENARIO 388513] Sales order with 80% prepayment incl. Tax, increase\decrease prepayment invoice and credit memo
        Initialize();

        // [GIVEN] Sales order with 5% Tax, 80% prepayment incl. Tax, one line with 1 Qty and Unit Price = 1000
        CreateSalesOrder_Tax5Pct_OneLine(SalesHeader, 80, true, 1000);
        VerifySalesHeaderTotals(SalesHeader, 1000, 1050, 0, 800);
        // [GIVEN] Posted prepayment invoice has Amount = 840, Amount Incl. VAT = 840
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 840, 840);
        VerifySalesHeaderTotals(SalesHeader, 1000, 1050, 0, 800);
        // [GIVEN] Reopen and update Quantity = 2
        ReopenAndUpdateQty(SalesHeader, 2);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 1600);
        // [GIVEN] Posted 2nd prepayment invoice has Amount = 840, Amount Incl. VAT = 840
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 840, 840);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 1600);
        // [GIVEN] Posted invoice (1 quantity) has Amount = 160, Amount Incl. VAT = 210
        UpdateQtyToShip(SalesHeader, 1, '');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), 160, 210);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 1600);
        // [GIVEN] Posted prepayment creit memo has Amount = 840, Amount Incl. VAT = 840
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 840, 840);
        VerifySalesHeaderTotals(SalesHeader, 2000, 2100, 0, 1600);
        // [GIVEN] Reopen and update Quantity = 3
        ReopenAndUpdateQty(SalesHeader, 3);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 2400);
        // [GIVEN] Posted 3rd prepayment invoice has Amount = 1680, Amount Incl. VAT = 1680
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1680, 1680);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 2400);
        // [GIVEN] Posted 2nd prepayment creit memo has Amount = 1680, Amount Incl. VAT = 1680
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 1680, 1680);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 2400);
        // [GIVEN] Posted 4th prepayment invoice has Amount = 1680, Amount Incl. VAT = 1680
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 1680, 1680);
        VerifySalesHeaderTotals(SalesHeader, 3000, 3150, 0, 2400);
        // [WHEN] Posted final invoice
        // [THEN] Posted final invoice has Amount = 320, Amount Incl. VAT = 420
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), 320, 420);
    end;

    [Test]
    procedure SalesPartialShipReopenDelLine100PctPrepmtInclTax_TFS391586()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        ChicagoILTaxAreaCode: Code[20];
        FurnitureTaxGroupCode: Code[20];
        SuppliesTaxGroupCode: Code[20];
        NonTaxableTaxGroupCode: Code[20];
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Include Tax]
        // [SCENARIO 391586] Sales order with 100% Prepayment Incl. Tax, several lines, partial ship, reopen and deletion of line
        Initialize();

        // [GIVEN] Sales order with 100% Prepayment Incl. Tax, several lines
        CreateTaxSetup_CHICAGO_IL(ChicagoILTaxAreaCode, FurnitureTaxGroupCode, SuppliesTaxGroupCode, NonTaxableTaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, ChicagoILTaxAreaCode, 100, true);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 10);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 10);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 10);
        VerifySalesHeaderTotals(SalesHeader, 300, 315, 0, 300);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 315, 315);

        // [GIVEN] Partially ship lines
        UpdateQtyToShip(SalesHeader, 6, '10000');
        UpdateQtyToShip(SalesHeader, 0, '20000');
        UpdateQtyToShip(SalesHeader, 6, '30000');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -6, 0);

        // [GIVEN] Post prepayment credit memo
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 189, 189);

        // [GIVEN] Reopen the order and delete a line
        DeleteSalesOrderLine(SalesHeader, 20000);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 84, 84);

        // [WHEN] Post final invoice
        // [THEN] Posted final invoice has Amount Incl. VAT = 0
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -4, 0);
    end;

    [Test]
    procedure SalesPartialShipReopenAddLine100PctPrepmtInclTax_TFS391572()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        ChicagoILTaxAreaCode: Code[20];
        FurnitureTaxGroupCode: Code[20];
        SuppliesTaxGroupCode: Code[20];
        NonTaxableTaxGroupCode: Code[20];
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Include Tax]
        // [SCENARIO 391572] Sales order with Prepayment Incl. Tax, several lines, partial ship, reopen and add a line
        Initialize();

        // [GIVEN] Sales order with Prepayment Incl. Tax, several lines with custom prepayment
        CreateTaxSetup_CHICAGO_IL(ChicagoILTaxAreaCode, FurnitureTaxGroupCode, SuppliesTaxGroupCode, NonTaxableTaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, ChicagoILTaxAreaCode, 0, true);
        CreateSalesLineGLQtyPrepmtPct(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 10, 100);
        CreateSalesLineGLQtyPrepmtPct(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 10, 0);
        CreateSalesLineGLQtyPrepmtPct(SalesHeader, GLAccountNo, NonTaxableTaxGroupCode, 10, 10, 100);
        VerifySalesHeaderTotals(SalesHeader, 300, 310, 0, 200);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 205, 205);

        // [GIVEN] Partially ship lines
        UpdateQtyToShip(SalesHeader, 0, '20000');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -5, 0);

        // [GIVEN] Reopen the order and add a line with 100% prepayment
        LibrarySales.ReopenSalesDocument(SalesHeader);
        CreateSalesLineGLQtyPrepmtPct(SalesHeader, GLAccountNo, NonTaxableTaxGroupCode, 10, 10, 100);
        VerifySalesHeaderTotals(SalesHeader, 400, 410, 0, 300);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 100, 100);

        // [WHEN] Post final invoice
        // [THEN] Posted final invoice has Amount Incl. VAT = 105
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), 100, 105);
    end;

    [Test]
    procedure SalesPartialShipReopenDelLine100PctPrepmtInclTax_TFS391577()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        ChicagoILTaxAreaCode: Code[20];
        FurnitureTaxGroupCode: Code[20];
        SuppliesTaxGroupCode: Code[20];
        NonTaxableTaxGroupCode: Code[20];
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Include Tax]
        // [SCENARIO 391577] Sales order with 100% Prepayment Incl. Tax, several lines, partial ship, reopen and delete a line (case 391577)
        Initialize();

        // [GIVEN] Sales order with 100% Prepayment Incl. Tax, several lines
        CreateTaxSetup_CHICAGO_IL(ChicagoILTaxAreaCode, FurnitureTaxGroupCode, SuppliesTaxGroupCode, NonTaxableTaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, ChicagoILTaxAreaCode, 100, true);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 10);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 10);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 10);
        VerifySalesHeaderTotals(SalesHeader, 300, 315, 0, 300);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 315, 315);

        // [GIVEN] Partially ship lines
        UpdateQtyToShip(SalesHeader, 0, '10000');
        UpdateQtyToShip(SalesHeader, 0, '20000');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -5, 0);

        // [GIVEN] Post prepayment credit memo
        VerifySalesPostedCrMemoAmounts(LibrarySales.PostSalesPrepaymentCreditMemo(SalesHeader), 210, 210);

        // [GIVEN] Reopen the order and delete a line
        DeleteSalesOrderLine(SalesHeader, 10000);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 105, 105);

        // [WHEN] Post final invoice
        // [THEN] Posted final invoice has Amount Incl. VAT = 0
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -5, 0);
    end;

    [Test]
    procedure SalesPartialShipCustomAmounts100PctPrepmtInclTax_TFS391587()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        ChicagoILTaxAreaCode: Code[20];
        FurnitureTaxGroupCode: Code[20];
        SuppliesTaxGroupCode: Code[20];
        NonTaxableTaxGroupCode: Code[20];
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Include Tax]
        // [SCENARIO 391587] Sales order with 100% Prepayment Incl. Tax, several lines with custom amounts and partial ship (case 391587)
        Initialize();

        // [GIVEN] Sales order with 100% Prepayment Incl. Tax, several lines with custom amounts
        CreateTaxSetup_CHICAGO_IL(ChicagoILTaxAreaCode, FurnitureTaxGroupCode, SuppliesTaxGroupCode, NonTaxableTaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, ChicagoILTaxAreaCode, 100, true);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 10, 1.68);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, FurnitureTaxGroupCode, 5, 1.68);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, NonTaxableTaxGroupCode, 5, 1.5);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, SuppliesTaxGroupCode, 1, 29.48);
        VerifySalesHeaderTotals(SalesHeader, 62.18, 64.62, 0, 62.18);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 64.62, 64.62);

        // [GIVEN] Partially ship lines
        UpdateQtyToShip(SalesHeader, 1, '20000');
        UpdateQtyToShip(SalesHeader, 1, '30000');
        UpdateQtyToShip(SalesHeader, 1, '40000');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -2.1, 0);

        // [WHEN] Post final invoice
        // [THEN] Posted final invoice has Amount Incl. VAT = 0
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -0.34, 0);
    end;

    [Test]
    procedure SalesPartialShipCustomAmounts100PctPrepmtInclTax_TFS389998()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Include Tax]
        // [SCENARIO 389998] Sales order with 100% Prepayment Incl. Tax, several lines with custom amounts, partial ship (case 389998)
        Initialize();

        // [GIVEN] Sales order with 100% Prepayment Incl. Tax, several lines with custom amounts
        CreateCustomTaxSetup_TFS389998(TaxAreaCode, TaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, TaxAreaCode, 100, true);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, 2, 127.66);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, 5, 644.27);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, 1, 167);
        VerifySalesHeaderTotals(SalesHeader, 3643.67, 3998.93, 0, 3643.67);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 3998.93, 3998.93);

        // [GIVEN] Partially ship lines
        UpdateQtyToShip(SalesHeader, 1, '10000');
        UpdateQtyToShip(SalesHeader, 4, '20000');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -279.99, 0);

        // [WHEN] Post final invoice
        // [THEN] Posted final invoice has Amount Incl. VAT = 0
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -75.27, 0);
    end;

    [Test]
    procedure SalesPartialShipCustomAmountsLineDisc100PctPrepmtInclTax_TFS389998()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [FEATURE] [Prepayment] [Sales] [Prepmt. Include Tax] [Line Discount]
        // [SCENARIO 389998] Sales order with 100% Prepayment Incl. Tax, several lines with custom amounts, line discount and partial ship
        Initialize();

        // [GIVEN] Sales order with 100% Prepayment Incl. Tax, several lines with custom amounts and line discount
        CreateCustomTaxSetup_TFS389998(TaxAreaCode, TaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, TaxAreaCode, 100, true);
        CreateSalesLineGLQtyLineDisc(SalesHeader, GLAccountNo, TaxGroupCode, 2, 127.66, 15);
        CreateSalesLineGLQtyLineDisc(SalesHeader, GLAccountNo, TaxGroupCode, 5, 644.27, 20);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, 1, 167);
        VerifySalesHeaderTotals(SalesHeader, 2961.1, 3249.81, 0, 2961.1);

        // [GIVEN] Post prepayment invoice
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesPrepaymentInvoice(SalesHeader), 3249.81, 3249.81);

        // [GIVEN] Partially ship lines
        UpdateQtyToShip(SalesHeader, 1, '10000');
        UpdateQtyToShip(SalesHeader, 4, '20000');
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -227.87, 0);

        // [WHEN] Post final invoice
        // [THEN] Posted final invoice has Amount Incl. VAT = 0
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), -60.84, 0);
    end;

    [Test]
    procedure CalculationOrderWithCalculateTaxOnTaxAndNegativeLine()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
        TaxJurisdictionCode: Code[10];
        TaxGroupCode: Code[20];
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Calculate Tax on Tax] [Negative Line]
        // [SCENARIO 395667] Calculation Order in case of Calculate Tax on Tax and negative line
        Initialize();

        // [GIVEN] Tax setup with tax group having "Calculate Tax on Tax" = TRUE
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_US();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 10);
        TaxDetail.Validate("Calculate Tax on Tax", true);
        TaxDetail.Modify(true);

        // [GIVEN] Sales Order with positive and negative lines
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, TaxAreaCode, 0, false);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, 1, 1000);
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, -1, 500);

        // [WHEN] Post the order
        // [THEN] The order is posted
        VerifySalesPostedInvAmounts(LibrarySales.PostSalesDocument(SalesHeader, true, true), 500, 560);
    end;

    //r01
    [Test]
    procedure SalesOrderWithLineDiscountAnd100PctPrepmtPartialPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TaxAreaCode: Code[20];
        TaxJurisdictionCode: Code[10];
        TaxGroupCode: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 431075] Sales order with line discount and 100 % prepayment partial posting
        Initialize();

        // [GIVEN] Sales tax setup with 0 % tax rate
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_US();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 0);

        // [GIVEN] Partially posted sales order with 100 % prepayment and line discount
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesHeader(SalesHeader, LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", ''), TaxAreaCode, 100, false);
        CreateSalesLineItem(SalesHeader, CreateItemNo(GeneralPostingSetup."Gen. Prod. Posting Group"), TaxGroupCode, 5917.55);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, 4);
        SalesLine.Validate("Line Discount %", 5);
        SalesLine.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.Validate("Qty. to Ship", 2);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Finally posting sales order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales order successfully posted
        SalesInvoiceHeader.Get(DocNo);
    end;

    [Test]
    procedure SalesOrderWith50PctInvoiceDiscountAnd100PctPrepmtPosting()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TaxAreaCode: Code[20];
        TaxJurisdictionCode: Code[10];
        TaxGroupCode: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 431075] Sales order with 50% invoice discount and 100 % prepayment  posting
        Initialize();

        // [GIVEN] Sales tax setup with 0 % tax rate
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_US();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 0);

        // [GIVEN] 100% prepaid sales order with 50% invoice discount
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesHeader(SalesHeader, LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", ''), TaxAreaCode, 100, false);
        CreateSalesLineItem(SalesHeader, CreateItemNo(GeneralPostingSetup."Gen. Prod. Posting Group"), TaxGroupCode, 1000);
        SalesHeader.Validate("Invoice Discount Value", 500);
        SalesHeader.Modify(true);

        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Finally posting sales order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales order successfully posted
        SalesInvoiceHeader.Get(DocNo);
    end;

    [Test]
    procedure PurchaseOrderWithLineDiscountAnd100PctPrepmtPartialPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        TaxAreaCode: Code[20];
        TaxJurisdictionCode: Code[10];
        TaxGroupCode: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 449207] Purchase order with line discount and 100 % prepayment partial posting
        Initialize();

        // [GIVEN] Sales tax setup with 0 % tax rate
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_US();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 0);

        // [GIVEN] Partially posted purchase order with 100 % prepayment and line discount
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", ''), TaxAreaCode, 100, false);
        CreatePurchaseLineItem(PurchaseHeader, CreateItemNo(GeneralPostingSetup."Gen. Prod. Posting Group"), TaxGroupCode, 5917.55);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate(Quantity, 4);
        PurchaseLine.Validate("Line Discount %", 5);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Receive", 2);
        PurchaseLine.Modify(true);

        PurchaseHeader.Validate("Vendor Invoice No.", 'C1INV1');
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchaseHeader.Validate("Vendor Invoice No.", 'C1INV2');
        PurchaseHeader.Modify(true);
        // [WHEN] Finally posting purchase order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase order successfully posted
        PurchaseInvoiceHeader.Get(DocNo);
    end;

    [Test]
    procedure PurchaseOrderWith50PctInvoiceDiscountAnd100PctPrepmtPosting()
    var
        PurchaseHeader: Record "Purchase Header";
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseInvoiceHeader: Record "Purch. Inv. Header";
        TaxAreaCode: Code[20];
        TaxJurisdictionCode: Code[10];
        TaxGroupCode: Code[20];
        DocNo: Code[20];
    begin
        // [SCENARIO 449207] Purchase order with 50% invoice discount and 100 % prepayment posting
        Initialize();

        // [GIVEN] Sales tax setup with 0 % tax rate
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_US();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 0);

        // [GIVEN] 100% prepaid purchase order with 50% invoice discount
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", ''), TaxAreaCode, 100, false);
        CreatePurchaseLineItem(PurchaseHeader, CreateItemNo(GeneralPostingSetup."Gen. Prod. Posting Group"), TaxGroupCode, 1000);
        PurchaseHeader.Validate("Invoice Discount Value", 500);
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        PurchaseHeader.Validate("Vendor Invoice No.", 'C2INV1');
        PurchaseHeader.Modify(true);
        // [WHEN] Posting purchase order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase order successfully posted
        PurchaseInvoiceHeader.Get(DocNo);
    end;

    [Test]
    procedure NoInconsistencyErrorOnPartialPrepaymentWithCurrency()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        CurrencyCode: Code[10];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
    begin
        // [SCENARIO 562060] Posting a Sales Invoice after posting a Prepayment Invoice for 70% with a Currency Code of EUR in a USD company with US Sales Tax generates an Inconsistency error due to rounding in the GL entries in the US Localized Database
        Initialize();

        // [GIVEN] Create Currency with Exchange Rate as 0.9952
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        CreateExchangeRate(CurrencyExchangeRate, CurrencyCode, DMY2Date(1, 1, Date2DMY(WorkDate(), 3)));

        // [GIVEN] Create Tax Setup for 3 TaxJurisdictionCode with 3%, 1% and 1%
        CreateSalesTaxSetup(TaxAreaCode, TaxGroupCode);

        // [GIVEN] Create Customer with Tax Area Code and Currency
        Customer.Get(CreateCustomerWithTaxArea(TaxAreaCode, CurrencyCode, LibraryRandom.RandIntInRange(70, 70)));

        // [GIVEN] Create Sales Order With Prepayment as 70%
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, '', 4019.29, 1);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify();

        // [GIVEN] Post Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Order with Ship and Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] No inconsitency error should be there in posting of document
    end;

    local procedure Initialize()
    var
        TaxSetup: Record "Tax Setup";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibrarySales.SetReturnOrderNoSeriesInSetup();
        LibraryPurchase.SetReturnOrderNoSeriesInSetup();
        LibraryService.SetupServiceMgtNoSeries();
        LibraryApplicationArea.EnableEssentialSetup();

        if IsInitialized then
            exit;
        IsInitialized := true;

        TaxSetup.DeleteAll();
        TaxSetup.Init();
        TaxSetup.Insert();

        UpdateSalesNoSeries();
        UpdatePurchaseNoSeries();
    end;

    local procedure PrepareTaxBelowMaximumValues_TFS229419(var TaxBelowMaximum: array[3] of Decimal)
    begin
        TaxBelowMaximum[1] := 13;
        TaxBelowMaximum[2] := 5;
        TaxBelowMaximum[3] := 5;
    end;

    local procedure PrepareUnitPrices_TFS229419(var UnitPrice: array[5] of Decimal)
    begin
        UnitPrice[1] := 99;
        UnitPrice[2] := 116.5;
        UnitPrice[3] := 86.5;
        UnitPrice[4] := 66.5;
        UnitPrice[5] := 116.5;
    end;

    local procedure PrepareUnitPrices_TFS262985(var UnitPrice: array[11] of Decimal)
    begin
        UnitPrice[1] := 198.35;
        UnitPrice[2] := 62.15;
        UnitPrice[3] := 1243.5;
        UnitPrice[4] := 8.41;
        UnitPrice[5] := 1.78;
        UnitPrice[6] := 27.08;
        UnitPrice[7] := 2.03;
        UnitPrice[8] := 1.9;
        UnitPrice[9] := 1.09;
        UnitPrice[10] := 78;
        UnitPrice[11] := 70;
    end;

    local procedure PrepareUnitPrices_TFS273130(var UnitPrice: array[2] of Decimal)
    begin
        UnitPrice[1] := 11000;
        UnitPrice[2] := -9315;
    end;

    local procedure PrepareUnitPrices_TFS280515(var UnitPrice: array[2] of Decimal)
    begin
        UnitPrice[1] := 1283.06;
        UnitPrice[2] := -859.96;
    end;

    local procedure PrepareQuantity_TFS262985(var Quantity: array[11] of Decimal)
    begin
        Quantity[1] := 18;
        Quantity[2] := 18;
        Quantity[3] := 1;
        Quantity[4] := 48;
        Quantity[5] := 48;
        Quantity[6] := 10;
        Quantity[7] := 26;
        Quantity[8] := 26;
        Quantity[9] := 18;
        Quantity[10] := 2;
        Quantity[11] := 2;
    end;

    local procedure PrepareExpectedAmounts_TFS229419(var Amount: Decimal; var AmountIncludingVAT: Decimal; var InvoiceDiscountAmount: Decimal; var VATAmount: Decimal)
    begin
        Amount := 412.25;
        AmountIncludingVAT := 443.27;
        InvoiceDiscountAmount := 72.75;
        VATAmount := 31.02;
    end;

    local procedure CreateCustomTaxSetup_5Pct(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdictionCode: array[2] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        for i := 1 to ArrayLen(TaxJurisdictionCode) do begin
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdiction_US();
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode[i]);
        end;
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode, 2);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode, 3);
    end;

    local procedure CreateCustomTaxSetup_TFS210430(var TaxAreaCode: Code[20]; var TaxGroupCode: array[2] of Code[20]; TaxCountry: Option)
    var
        TaxDetail: Record "Tax Detail";
        TaxAreaLine: Record "Tax Area Line";
        TaxJurisdictionCode: array[2] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(TaxCountry);
        for i := 1 to ArrayLen(TaxGroupCode) do begin
            TaxGroupCode[i] := LibraryERMTax.CreateTaxGroupCode();
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(TaxCountry);
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode[i]);
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

    local procedure CreateCustomTaxSetup_TFS389998(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: array[3] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();

        for i := 1 to ARRAYLEN(TaxJurisdictionCode) do begin
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdiction_US();
            LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode[i]);
        end;

        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();

        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode, 2);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode, 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[3], TaxGroupCode, 7.75);
    end;

    local procedure CreateTaxSetup_CHICAGO_IL(var TaxAreaCode: Code[20]; var FurnitureTaxGroupCode: Code[20]; var SuppliesTaxGroupCode: Code[20]; var NonTaxableTaxGroupCode: Code[20])
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode_IL: Code[10];
        TaxJurisdictionCode_ILCHICAGO: Code[10];
        TaxJurisdictionCode_ILCOOK: Code[10];
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();

        TaxJurisdictionCode_IL := LibraryERMTax.CreateTaxJurisdiction_US();
        TaxJurisdictionCode_ILCHICAGO := LibraryERMTax.CreateTaxJurisdiction_US();
        TaxJurisdictionCode_ILCOOK := LibraryERMTax.CreateTaxJurisdiction_US();

        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode_IL);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode_ILCHICAGO);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdictionCode_ILCOOK);

        FurnitureTaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        SuppliesTaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        NonTaxableTaxGroupCode := LibraryERMTax.CreateTaxGroupCode();

        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode_IL, FurnitureTaxGroupCode, 3);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode_IL, SuppliesTaxGroupCode, 2);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode_IL, NonTaxableTaxGroupCode, 0);

        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode_ILCHICAGO, '', 1);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode_ILCHICAGO, NonTaxableTaxGroupCode, 0);

        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode_ILCOOK, '', 1);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode_ILCOOK, NonTaxableTaxGroupCode, 0);
    end;

    local procedure CreateTaxForTaxGroup(TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; CountryRegion: Option; TaxPercent: Decimal; ExpenseCapitalize: Boolean)
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
    begin
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(CountryRegion);
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxPercent);
        UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", ExpenseCapitalize);
    end;

    local procedure CreateTaxSetup(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; TaxPct: Integer)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxDetail: Record "Tax Detail";
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdiction.Get(LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA());
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxPct);
    end;

    local procedure CreateTaxSetup_TFS229419(var TaxAreaCode: Code[20]; var TaxGroupCode: array[3] of Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
        TaxBelowMaximum: array[3] of Decimal;
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_CA();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        PrepareTaxBelowMaximumValues_TFS229419(TaxBelowMaximum);
        for i := 1 to ArrayLen(TaxBelowMaximum) do begin
            TaxGroupCode[i] := LibraryERMTax.CreateTaxGroupCode();
            LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode[i], TaxBelowMaximum[i]);
        end;
    end;

    local procedure CreateTaxSetup_TFS231225(var NoTaxAreaCode: Code[20]; var TaxAreaCode: Code[20]; var ProvTaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        NoTaxJurisdictionCode: Code[10];
        ProvTaxJurisdictionCode: array[4] of Code[10];
        TaxJurisdictionCode: Code[10];
        i: Integer;
    begin
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();

        // No Tax
        NoTaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        NoTaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA();
        LibraryERMTax.CreateTaxAreaLine(NoTaxAreaCode, NoTaxJurisdictionCode);
        LibraryERMTax.CreateTaxDetail(TaxDetail, NoTaxJurisdictionCode, TaxGroupCode, 0);

        // Provincial Tax
        ProvTaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        for i := 1 to ArrayLen(ProvTaxJurisdictionCode) do begin
            ProvTaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA();
            LibraryERMTax.CreateTaxAreaLine(ProvTaxAreaCode, ProvTaxJurisdictionCode[i]);
        end;
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, ProvTaxJurisdictionCode[1], TaxGroupCode, 1.6, true);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, ProvTaxJurisdictionCode[2], TaxGroupCode, 3.4, false);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, ProvTaxJurisdictionCode[3], TaxGroupCode, 0.56, true);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, ProvTaxJurisdictionCode[4], TaxGroupCode, 7.44, false);

        // Tax
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdictionWithSelfReportTo_CA();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 5);
    end;

    local procedure CreateTaxSetup_TFS262985(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: Code[10];
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_CA();
        TaxJurisdictionCode := LibraryERMTax.CreateTaxJurisdiction_CA();
        LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, 13);
    end;

    local procedure CreateTaxSetup_TFS273130(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; var NonTaxGroupCode: Code[20])
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: array[3] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        for i := 1 to ArrayLen(TaxJurisdictionCode) do begin
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdiction_US();
            LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode[i]);
        end;

        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode, 0, false);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode, 8.9, true);
        LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, TaxJurisdictionCode[3], TaxGroupCode, 0, false);

        NonTaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        for i := 1 to ArrayLen(TaxJurisdictionCode) do
            LibraryERMTax.CreateTaxDetailExpenseCapitalize(TaxDetail, TaxJurisdictionCode[i], NonTaxGroupCode, 0, false);
    end;

    local procedure CreateTaxSetup_TFS280515(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; CountyrRegionOption: Option)
    var
        TaxDetail: Record "Tax Detail";
        TaxJurisdictionCode: array[2] of Code[10];
        i: Integer;
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(CountyrRegionOption);
        for i := 1 to ArrayLen(TaxJurisdictionCode) do begin
            TaxJurisdictionCode[i] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(CountyrRegionOption);
            LibraryERMTax.CreateTaxAreaLine(TaxAreaCode, TaxJurisdictionCode[i]);
        end;
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[1], TaxGroupCode, 0);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdictionCode[2], TaxGroupCode, 5);
    end;

    local procedure CreateTaxSetup_TFS283166(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    begin
        TaxAreaCode := LibraryERMTax.CreateTaxAreaWithCountryRegion(DummyTaxCountry::CA);
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();

        CreateTaxForTaxGroup(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA, 5, true);
        CreateTaxForTaxGroup(TaxAreaCode, TaxGroupCode, DummyTaxCountry::CA, 7, true);
    end;

    local procedure CreateSalesOrder_TFS229419(var SalesHeader: Record "Sales Header"; DiscountPct: Decimal; PrepaymentPct: Decimal; PrepmtIncludeTax: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[3] of Code[20];
        ItemNo: Code[20];
        UnitPrices: array[5] of Decimal;
    begin
        CreateTaxSetup_TFS229419(TaxAreaCode, TaxGroupCode);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesHeader(
          SalesHeader,
          CreateCustomerWithInvDiscount(GeneralPostingSetup."Gen. Bus. Posting Group", DiscountPct),
          TaxAreaCode, PrepaymentPct, PrepmtIncludeTax);
        ItemNo := CreateItemNo(GeneralPostingSetup."Gen. Prod. Posting Group");
        PrepareUnitPrices_TFS229419(UnitPrices);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[2], UnitPrices[1]);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[2], UnitPrices[2]);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[1], UnitPrices[3]);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[1], UnitPrices[4]);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode[3], UnitPrices[5]);
        LibrarySales.CalcSalesDiscount(SalesHeader);
    end;

    local procedure CreateSalesOrder_TFS262985(var SalesHeader: Record "Sales Header")
    var
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        UnitPrices: array[11] of Decimal;
        Quantity: array[11] of Decimal;
        i: Integer;
    begin
        CreateTaxSetup_TFS262985(TaxAreaCode, TaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, TaxAreaCode, 25, true);
        PrepareUnitPrices_TFS262985(UnitPrices);
        PrepareQuantity_TFS262985(Quantity);
        for i := 1 to ArrayLen(Quantity) do
            CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, Quantity[i], UnitPrices[i]);
    end;

    local procedure CreateSalesOrder_TFS273130(var SalesHeader: Record "Sales Header")
    var
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        NonTaxGroupCode: Code[20];
        UnitPrices: array[2] of Decimal;
    begin
        CreateTaxSetup_TFS273130(TaxAreaCode, TaxGroupCode, NonTaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, TaxAreaCode, 0, false);
        PrepareUnitPrices_TFS273130(UnitPrices);
        CreateSalesLineGL(SalesHeader, GLAccountNo, NonTaxGroupCode, UnitPrices[1]);
        CreateSalesLineGL(SalesHeader, GLAccountNo, TaxGroupCode, UnitPrices[2]);
    end;

    local procedure CreateSalesOrder_Tax5Pct_OneLine(var SalesHeader: Record "Sales Header"; PrepmtPct: Decimal; PrepmtInclTax: Boolean; UnitPrice: Decimal)
    var
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
    begin
        CreateCustomTaxSetup_5Pct(TaxAreaCode, TaxGroupCode);
        CreateCustomerAndGLAccount(CustomerNo, GLAccountNo);
        CreateSalesHeader(SalesHeader, CustomerNo, TaxAreaCode, PrepmtPct, PrepmtInclTax);
        CreateSalesLineGL(SalesHeader, GLAccountNo, TaxGroupCode, UnitPrice);
    end;

    local procedure CreatePurchaseOrder_TFS262985(var PurchaseHeader: Record "Purchase Header")
    var
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        UnitPrices: array[11] of Decimal;
        Quantity: array[11] of Decimal;
        i: Integer;
    begin
        CreateTaxSetup_TFS262985(TaxAreaCode, TaxGroupCode);
        CreateVendorAndGLAccount(VendorNo, GLAccountNo);
        CreatePurchaseHeader(PurchaseHeader, VendorNo, TaxAreaCode, 25, true);
        PrepareUnitPrices_TFS262985(UnitPrices);
        PrepareQuantity_TFS262985(Quantity);
        for i := 1 to ArrayLen(Quantity) do
            CreatePurchaseLineGLQty(PurchaseHeader, GLAccountNo, TaxGroupCode, Quantity[i], UnitPrices[i]);
    end;

    local procedure CreatePurchaseOrder_TFS273130(var PurchaseHeader: Record "Purchase Header")
    var
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        TaxAreaCode: Code[20];
        TaxGroupCode: Code[20];
        NonTaxGroupCode: Code[20];
        UnitPrices: array[2] of Decimal;
    begin
        CreateTaxSetup_TFS273130(TaxAreaCode, TaxGroupCode, NonTaxGroupCode);
        CreateVendorAndGLAccount(VendorNo, GLAccountNo);
        CreatePurchaseHeader(PurchaseHeader, VendorNo, TaxAreaCode, 0, false);
        PrepareUnitPrices_TFS273130(UnitPrices);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, NonTaxGroupCode, UnitPrices[1]);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, TaxGroupCode, UnitPrices[2]);
    end;

    local procedure CreateSalesOrder_TFS280515(var SalesHeader: Record "Sales Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        UnitPrices: array[2] of Decimal;
    begin
        PrepareUnitPrices_TFS280515(UnitPrices);
        CreateSalesHeader(SalesHeader, LibrarySales.CreateCustomerWithVATBusPostingGroup(''), TaxAreaCode, 0, false);
        CreateSalesLineItem(SalesHeader, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, UnitPrices[1]);
        CreateSalesLineItem(SalesHeader, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, UnitPrices[2]);
    end;

    local procedure CreatePurchaseOrder_TFS280515(var PurchaseHeader: Record "Purchase Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        UnitPrices: array[2] of Decimal;
    begin
        PrepareUnitPrices_TFS280515(UnitPrices);
        CreatePurchaseHeader(PurchaseHeader, LibraryPurchase.CreateVendorWithVATBusPostingGroup(''), TaxAreaCode, 0, false);
        CreatePurchaseLineItem(PurchaseHeader, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, UnitPrices[1]);
        CreatePurchaseLineItem(PurchaseHeader, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, UnitPrices[2]);
    end;

    local procedure CreateServiceOrder_TFS280515(var ServiceHeader: Record "Service Header"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
        UnitPrices: array[2] of Decimal;
    begin
        PrepareUnitPrices_TFS280515(UnitPrices);
        CreateServiceHeader(ServiceHeader, ServiceItemLine, TaxAreaCode);
        CreateServiceLine(
          ServiceHeader, ServiceItemLine, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, 1, UnitPrices[1]);
        CreateServiceLine(
          ServiceHeader, ServiceItemLine, LibraryInventory.CreateItemNoWithVATProdPostingGroup(''), TaxGroupCode, 1, UnitPrices[2]);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; TaxAreaCode: Code[20]; PrepaymentPct: Decimal; PrepmtIncludeTax: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Validate("Prepayment %", PrepaymentPct);
        SalesHeader.Validate("Prepmt. Include Tax", PrepmtIncludeTax);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineItem(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineGL(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; UnitPrice: Decimal)
    begin
        CreateSalesLineGLQty(SalesHeader, GLAccountNo, TaxGroupCode, 1, UnitPrice);
    end;

    local procedure CreateSalesLineGLQty(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, NewQuantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineGLQtyLineDisc(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal; LineDiscountPct: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, NewQuantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Validate("Line Discount %", LineDiscountPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineGLQtyPrepmtPct(SalesHeader: Record "Sales Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; NewQuantity: Decimal; UnitPrice: Decimal; PrepmtPct: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, NewQuantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Tax Group Code", TaxGroupCode);
        SalesLine.Validate("Prepayment %", PrepmtPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomerWithInvDiscount(GenBusPostingGroupCode: Code[20]; DiscountPct: Decimal): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(
          CustInvoiceDisc, LibrarySales.CreateCustomerWithBusPostingGroups(GenBusPostingGroupCode, ''), '', 0);
        CustInvoiceDisc.Validate("Discount %", DiscountPct);
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CreateCustomerWithTaxArea(TaxAreaCode: Code[20]): Code[20]
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

    local procedure CreateCustomerAndGLAccount(var CustomerNo: Code[20]; var GLAccountNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CustomerNo := LibrarySales.CreateCustomerWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", '');
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);
        GLAccountNo := GLAccount."No.";
    end;

    local procedure CreatePurchaseOrder_TFS229419(var PurchaseHeader: Record "Purchase Header"; DiscountPct: Decimal; PrepaymentPct: Decimal; PrepmtIncludeTax: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        TaxAreaCode: Code[20];
        TaxGroupCode: array[3] of Code[20];
        ItemNo: Code[20];
        UnitPrices: array[5] of Decimal;
    begin
        CreateTaxSetup_TFS229419(TaxAreaCode, TaxGroupCode);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseHeader(
          PurchaseHeader,
          CreateVendorWithInvDiscount(GeneralPostingSetup."Gen. Bus. Posting Group", DiscountPct),
          TaxAreaCode, PrepaymentPct, PrepmtIncludeTax);
        ItemNo := CreateItemNo(GeneralPostingSetup."Gen. Prod. Posting Group");
        PrepareUnitPrices_TFS229419(UnitPrices);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[2], UnitPrices[1]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[2], UnitPrices[2]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[1], UnitPrices[3]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[1], UnitPrices[4]);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode[3], UnitPrices[5]);
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; TaxAreaCode: Code[20]; PrepaymentPct: Decimal; PrepmtIncludeTax: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Validate("Prepmt. Include Tax", PrepmtIncludeTax);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseHeaderWithTaxAreaForVendor(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; TaxAreaCode: Code[20]; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Ship-to Address", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateAndReceivePurchOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; TaxLiable: Boolean; ItemNo: Code[20]; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", TaxLiable);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineItem(PurchaseHeader, ItemNo, TaxGroupCode, LibraryRandom.RandDecInRange(100, 200, 2));
        PurchaseHeader.CalcFields("Amount Including VAT");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateSalesHeaderWithTaxAreaForCustomer(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; TaxAreaCode: Code[20]; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Bill-to Address", LibraryUtility.GenerateGUID());
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateAndShipSalesOrderWithShipToAddr(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ShipToCode: Code[10]; ItemNo: Code[20]; TaxGroupCode: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Ship-to Code", ShipToCode);
        SalesHeader.Modify(true);
        CreateSalesLineItem(SalesHeader, ItemNo, TaxGroupCode, LibraryRandom.RandDecInRange(100, 200, 2));
        SalesHeader.CalcFields("Amount Including VAT");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreatePurchaseLineItem(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, 1);
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineGLWithProvincialTax(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; ProvincialTaxAreaCode: Code[20]; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Tax Area Code", TaxAreaCode);
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Validate("Provincial Tax Area Code", ProvincialTaxAreaCode);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineGL(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; DirectUnitCost: Decimal)
    begin
        CreatePurchaseLineGLQty(PurchaseHeader, GLAccountNo, TaxGroupCode, 1, DirectUnitCost);
    end;

    local procedure CreatePurchaseLineGLQty(PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; TaxGroupCode: Code[20]; NewQuantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, NewQuantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Validate("Tax Group Code", TaxGroupCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCustomPurchaseDocWithOneLine_TFS233346(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; CurrencyCode: Code[10])
    var
        GLAccountNo: Code[20];
    begin
        LibraryPurchase.SetInvoiceRounding(false);

        CreatePurchaseHeaderWithTaxAreaForVendor(
          PurchaseHeader, DocumentType, CurrencyCode, TaxAreaCode, CreateVendorWithTaxArea(TaxAreaCode));

        GLAccountNo := CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false);
        CreatePurchaseLineGL(PurchaseHeader, GLAccountNo, TaxGroupCode, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateCustomSalesDocWithOneLine_TFS233346(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; CurrencyCode: Code[10])
    var
        GLAccountNo: Code[20];
    begin
        LibrarySales.SetInvoiceRounding(false);

        CreateSalesHeaderWithTaxAreaForCustomer(
          SalesHeader, DocumentType, CurrencyCode, TaxAreaCode, CreateCustomerWithTaxArea(TaxAreaCode));

        GLAccountNo := CreateGLAccNoWithTaxSetup(TaxAreaCode, TaxGroupCode, false);
        CreateSalesLineGL(SalesHeader, GLAccountNo, TaxGroupCode, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateVendorWithInvDiscount(GenBusPostingGroupCode: Code[20]; DiscountPct: Decimal): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(
          VendorInvoiceDisc, LibraryPurchase.CreateVendorWithBusPostingGroups(GenBusPostingGroupCode, ''), '', 0);
        VendorInvoiceDisc.Validate("Discount %", DiscountPct);
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure CreateVendorWithTaxArea(TaxAreaCode: Code[20]): Code[20]
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

    local procedure CreateVendorAndGLAccount(var VendorNo: Code[20]; var GLAccountNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := LibraryPurchase.CreateVendorWithBusPostingGroups(GeneralPostingSetup."Gen. Bus. Posting Group", '');
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Modify(true);
        GLAccountNo := GLAccount."No.";
    end;

    local procedure CreateItemNo(GenProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithPostingSetup(Item, GenProdPostingGroupCode, '');
        exit(Item."No.");
    end;

    local procedure CreateGLAccountNoWithBlankVATSetup(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.Get('', '');
        exit(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
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

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPrepAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupSalesAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupPurchAccounts(GeneralPostingSetup);
        LibraryERM.SetGeneralPostingSetupMfgAccounts(GeneralPostingSetup);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; var ServiceItemLine: Record "Service Item Line"; TaxAreaCode: Code[20])
    begin
        LibraryService.CreateServiceHeader(
          ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerWithVATBusPostingGroup(''));
        ServiceHeader.Validate("Tax Liable", true);
        ServiceHeader.Validate("Tax Area Code", TaxAreaCode);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", LibraryInventory.CreateItemNo());
        ServiceItemLine.Modify(true);
    end;

    local procedure CreateServiceLine(ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line"; ItemNo: Code[20]; TaxGroupCode: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, Quantity);
        ServiceLine.Validate("Tax Group Code", TaxGroupCode);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Unit Price", UnitPrice);
        ServiceLine.Modify(true);
    end;

    local procedure CreateAndShipServiceOrder(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20]; TaxLiable: Boolean; ItemNo: Code[20]; TaxAreaCode: Code[20]; TaxGroupCode: Code[20])
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        ServiceHeader.Validate("Tax Liable", TaxLiable);
        ServiceHeader.Validate("Tax Area Code", TaxAreaCode);
        ServiceHeader.Modify(true);

        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        ServiceItemLine.Validate("Item No.", LibraryInventory.CreateItemNo());
        ServiceItemLine.Modify(true);

        CreateServiceLine(ServiceHeader, ServiceItemLine, ItemNo, TaxGroupCode, 1, LibraryRandom.RandDecInRange(100, 200, 2));

        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; LineType: Enum "Purchase Line Type")
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, LineType);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20];
                                                                                        LineType: Enum "Sales Line Type")
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, LineType);
        SalesLine.FindFirst();
    end;

    local procedure FindServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
    end;

    local procedure FindServiceInvoiceHeader(var ServiceInvoiceHeader: Record "Service Invoice Header"; ServiceHeader: Record "Service Header")
    begin
        ServiceInvoiceHeader.SetRange("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceHeader.FindFirst();
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateSalesNoSeries()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Posted Prepmt. Inv. Nos." := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup."Posted Prepmt. Cr. Memo Nos." := LibraryERM.CreateNoSeriesCode();
        SalesReceivablesSetup.Modify();
    end;

    local procedure UpdatePurchaseNoSeries()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Posted Prepmt. Inv. Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup.Modify();
    end;

    local procedure UpdateTaxDetailExpenseCapitalize(TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option; NewValue: Boolean)
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxDetail.Get(TaxJurisdictionCode, TaxGroupCode, TaxType, WorkDate());
        TaxDetail.Validate("Expense/Capitalize", NewValue);
        TaxDetail.Modify(true);
    end;

    local procedure UpdateQtyToShip(SalesHeader: Record "Sales Header"; NewQtyToShip: Decimal; LineNoFilter: Text)
    var
        SalesLine: Record "Sales Line";
    begin
        if LineNoFilter <> '' then
            SalesLine.SetFilter("Line No.", LineNoFilter);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        SalesLine.Validate("Qty. to Ship", NewQtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure ReopenAndUpdateQty(SalesHeader: Record "Sales Header"; NewQty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        SalesLine.Validate(Quantity, NewQty);
        SalesLine.Modify(true);
    end;

    local procedure DeleteSalesOrderLine(SalesHeader: Record "Sales Header"; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.SetRange("Line No.", LineNo);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        SalesLine.Delete(true);
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

    local procedure VerifySalesHeaderTotals(SalesHeader: Record "Sales Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal; ExpectedInvDiscAmount: Decimal; ExpectedPrepmtLineAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        SalesHeader.TestField(Amount, ExpectedAmount);
        SalesHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
        SalesHeader.TestField("Invoice Discount Amount", ExpectedInvDiscAmount);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Incl. VAT");
        SalesLine.TestField("Prepmt. Line Amount", ExpectedPrepmtLineAmount);
    end;

    local procedure VerifyPurchaseHeaderTotals(PurchaseHeader: Record "Purchase Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal; ExpectedInvDiscAmount: Decimal; ExpectedPrepmtLineAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT", "Invoice Discount Amount");
        PurchaseHeader.TestField(Amount, ExpectedAmount);
        PurchaseHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
        PurchaseHeader.TestField("Invoice Discount Amount", ExpectedInvDiscAmount);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.CalcSums("Prepmt. Line Amount", "Prepmt. Amt. Incl. VAT");
        PurchaseLine.TestField("Prepmt. Line Amount", ExpectedPrepmtLineAmount);
    end;

    local procedure VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader: Record "Sales Invoice Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
        SalesInvoiceHeader.TestField(Amount, ExpectedAmount);
        SalesInvoiceHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
        SalesInvoiceHeader.TestField("Remaining Amount", ExpectedAmountInclVAT);
    end;

    local procedure VerifyPostedSalesCrMemoTotals(SalesCrMemoHeader: Record 114; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        SalesCrMemoHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
        SalesCrMemoHeader.TestField(Amount, ExpectedAmount);
        SalesCrMemoHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
        SalesCrMemoHeader.TestField("Remaining Amount", -ExpectedAmountInclVAT);
    end;

    local procedure VerifyPostedPurchaseInvoiceTotals(PurchInvHeader: Record "Purch. Inv. Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT", "Remaining Amount");
        PurchInvHeader.TestField(Amount, ExpectedAmount);
        PurchInvHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
        PurchInvHeader.TestField("Remaining Amount", ExpectedAmountInclVAT);
    end;

    local procedure VerifyPostedServiceInvoiceTotals(ServiceInvoiceHeader: Record "Service Invoice Header"; ExpectedAmount: Decimal; ExpectedAmountInclVAT: Decimal)
    begin
        ServiceInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        ServiceInvoiceHeader.TestField(Amount, ExpectedAmount);
        ServiceInvoiceHeader.TestField("Amount Including VAT", ExpectedAmountInclVAT);
    end;

    local procedure VerifySalesPostedPrepmtAndInvAmounts(PrepmtDocNo: Code[20]; InvoiceDocNo: Code[20]; PrepmtAmount: Decimal; InvoiceAmount: Decimal; InvoiceAmountInclVAT: Decimal)
    begin
        VerifySalesPostedInvAmounts(PrepmtDocNo, PrepmtAmount, PrepmtAmount);
        VerifySalesPostedInvAmounts(InvoiceDocNo, InvoiceAmount, InvoiceAmountInclVAT);
    end;

    local procedure VerifySalesPostedInvAmounts(PostedDocNo: Code[20]; Amount: Decimal; AmountInclVAT: Decimal)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(PostedDocNo);
        VerifyPostedSalesInvoiceTotals(SalesInvoiceHeader, Amount, AmountInclVAT);
    end;

    local procedure VerifySalesPostedCrMemoAmounts(PostedDocNo: Code[20]; Amount: Decimal; AmountInclVAT: Decimal)
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(PostedDocNo);
        VerifyPostedSalesCrMemoTotals(SalesCrMemoHeader, Amount, AmountInclVAT);
    end;

    local procedure VerifyPurchasePostedPrepmtAndInvAmounts(PrepmtDocNo: Code[20]; InvoiceDocNo: Code[20]; PrepmtAmount: Decimal; InvoiceAmount: Decimal; InvoiceAmountInclVAT: Decimal)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(PrepmtDocNo);
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, PrepmtAmount, PrepmtAmount);
        PurchInvHeader.Get(InvoiceDocNo);
        VerifyPostedPurchaseInvoiceTotals(PurchInvHeader, InvoiceAmount, InvoiceAmountInclVAT);
    end;

    local procedure VerifyGLEntry(InvoiceNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", InvoiceNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure VerifyPurchaseVATTotalAfterRelease(PurchaseHeader: Record "Purchase Header"; ExpectedAmount: Decimal)
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedAmount, PurchaseHeader."Amount Including VAT" - PurchaseHeader.Amount, '');
    end;

    local procedure VerifySalesVATTotalAfterRelease(SalesHeader: Record "Sales Header"; ExpectedAmount: Decimal)
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");
        Assert.AreEqual(ExpectedAmount, SalesHeader."Amount Including VAT" - SalesHeader.Amount, '');
    end;

    local procedure VerifyVATEntry(AccountNo: Code[20]; VATBase: Decimal; VATAmount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Bill-to/Pay-to No.", AccountNo);
        VATEntry.FindFirst();
        VATEntry.TestField(Base, VATBase);
        VATEntry.TestField(Amount, VATAmount);
    end;

    local procedure CreateExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; CurrencyCode: Code[10]; StartingDate: Date)
    begin
        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);

        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 0.9952);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateSalesTaxSetup(var TaxAreaCode: Code[20]; var TaxGroupCode: Code[20])
    var
        TaxDetail: array[3] of Record "Tax Detail";
        TaxAreaLine: array[3] of Record "Tax Area Line";
        TaxJurisdictionCode: array[3] of Code[10];
    begin
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();

        TaxJurisdictionCode[1] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(DummyTaxCountry::US);
        TaxJurisdictionCode[2] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(DummyTaxCountry::US);
        TaxJurisdictionCode[3] := LibraryERMTax.CreateTaxJurisdictionWithCountryRegion(DummyTaxCountry::US);

        LibraryERMTax.CreateTaxDetailWithTaxType(TaxDetail[1], TaxJurisdictionCode[1], TaxGroupCode, TaxDetail[1]."Tax Type"::"Sales and Use Tax", 3, 0);
        LibraryERMTax.CreateTaxDetailWithTaxType(TaxDetail[2], TaxJurisdictionCode[2], TaxGroupCode, TaxDetail[2]."Tax Type"::"Sales and Use Tax", 1, 0);
        LibraryERMTax.CreateTaxDetailWithTaxType(TaxDetail[3], TaxJurisdictionCode[3], TaxGroupCode, TaxDetail[3]."Tax Type"::"Sales and Use Tax", 1, 0);

        TaxAreaCode := LibraryERMTax.CreateTaxArea_US();
        LibraryERM.CreateTaxAreaLine(TaxAreaLine[1], TaxAreaCode, TaxJurisdictionCode[1]);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine[2], TaxAreaCode, TaxJurisdictionCode[2]);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine[3], TaxAreaCode, TaxJurisdictionCode[3]);
    end;

    local procedure CreateCustomerWithTaxArea(TaxAreaCode: Code[20]; CurrencyCode: Code[10]; PrepaymentPercent: Decimal): Code[20]
    var
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.SetFilter("Sales Account", '<>%1', '');
        GeneralPostingSetup.SetFilter("Gen. Bus. Posting Group", '<>%1', '');
        GeneralPostingSetup.FindFirst();

        Customer.Init();
        Customer.Insert(true);
        Customer.Validate(Name, Customer."No.");
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup());
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Prepayment %", PrepaymentPercent);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReceiptLinesModalPageHandler(var GetReceiptLines: TestPage "Get Receipt Lines")
    begin
        GetReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesModalPageHandler(var GetReturnShipmentLines: TestPage "Get Return Shipment Lines")
    begin
        GetReturnShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesModalPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnReceiptLinesModalPageHandler(var GetReturnReceiptLines: TestPage "Get Return Receipt Lines")
    begin
        GetReturnReceiptLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DraftSalesInvoiceRPH(var DraftSalesInvoice: TestRequestPage "Standard Sales - Draft Invoice")
    begin
        DraftSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRPH(var SalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        SalesQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

