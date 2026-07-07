codeunit 138003 "O365 Sales Calc Disc By Type"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Invoice Discount] [SMB] [Sales]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SalesCalcDiscByType: Codeunit "Sales - Calc Discount By Type";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyDefaultInvoiceDiscountTypeAmount()
    var
        SalesHeader: Record "Sales Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);

        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::Amount);
        SalesHeader.Modify(true);

        SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        VerifyInvoiceDiscountTypeAmount(SalesHeader, InvoiceDiscountAmount, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyDefaultInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);

        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount, SalesHeader);

        VerifyInvoiceDiscountTypePercentage(SalesHeader, DiscPct, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvoiceDiscountAmountOnInvoiceWithoutDiscount()
    var
        SalesHeader: Record "Sales Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);

        SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        VerifyInvoiceDiscountTypeAmount(SalesHeader, InvoiceDiscountAmount, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvoiceDiscountAmountOverridesInvoiceDiscountTypePercentage()
    var
        SalesHeader: Record "Sales Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);
        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount, SalesHeader);

        SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        VerifyInvoiceDiscountTypeAmount(SalesHeader, InvoiceDiscountAmount, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCustInvoiceDiscPctWhenItExists()
    var
        SalesHeader: Record "Sales Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);
        VerifyCustomerDiscountPercentage(SalesHeader, 0);

        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);
        VerifyCustomerDiscountPercentage(SalesHeader, DiscPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCustInvoiceDiscPctWhenNoneIsDefined()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        NumberOfLines: Decimal;
        ItemUnitPrice: Decimal;
        ItemQuantity: Integer;
    begin
        Initialize();
        NumberOfLines := 1;
        ItemUnitPrice := LibraryRandom.RandDecInRange(10, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibrarySmallBusiness.CreateCustomer(Customer);
        CreateNewInvoiceWithLines(SalesHeader, Customer, NumberOfLines, ItemUnitPrice, ItemQuantity);

        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        VerifyCustomerDiscountPercentage(SalesHeader, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCustInvoiceDiscPctWhenInvDiscTypeIsAmount()
    var
        SalesHeader: Record "Sales Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);
        SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);

        VerifyCustomerDiscountPercentageFromAmount(SalesHeader, InvoiceDiscountAmount / NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetCustInvoiceDscPctWhenAmountChangesInvDiscGroup()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        MinAmount1: Decimal;
        MinAmount2: Decimal;
        DiscPct1: Decimal;
        DiscPct2: Decimal;
        NumberOfLines: Decimal;
        ItemUnitPrice: Decimal;
        ItemQuantity: Integer;
    begin
        Initialize();
        DiscPct1 := LibraryRandom.RandDecInDecimalRange(1, 50, 2);
        DiscPct2 := LibraryRandom.RandDecInDecimalRange(51, 99, 2);
        ItemUnitPrice := LibraryRandom.RandDecInRange(10, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);

        NumberOfLines := 1;
        MinAmount1 := ItemUnitPrice * ItemQuantity * NumberOfLines - 1;
        MinAmount2 := ItemUnitPrice * ItemQuantity * NumberOfLines;

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscPct1, MinAmount1, '');
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscPct2, MinAmount2, '');

        CreateNewInvoiceWithLines(SalesHeader, Customer, NumberOfLines, ItemUnitPrice, ItemQuantity);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        SalesLine.Validate("Line Amount", MinAmount1);
        SalesLine.Modify(true);
        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);
        VerifyCustomerDiscountPercentage(SalesHeader, DiscPct1);

        SalesLine.Validate("Line Amount", MinAmount2);
        SalesLine.Modify(true);

        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);
        VerifyCustomerDiscountPercentage(SalesHeader, DiscPct2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvDiscAmountWhenInvDiscBaseAmountIsZero()
    var
        SalesHeader: Record "Sales Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);
        SetAllowInvoiceDiscountOnAllLines(SalesHeader, false);

        asserterror SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        Assert.ExpectedError('Cannot apply an invoice discount because the document does not include lines where the Allow Invoice Disc. field is selected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvDiscAmountHigherThanInvDiscBaseAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);

        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        InvoiceDiscountAmount := NumberOfLines * SalesLine."Line Amount" + 1;
        asserterror SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        Assert.ExpectedError('that you can apply is');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountPercentageIsNotAppliedIfThereAreNoLinesThatAllowDiscPct()
    var
        SalesHeader: Record "Sales Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, NumberOfLines, DiscPct);
        SetAllowInvoiceDiscountOnAllLines(SalesHeader, false);

        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        Assert.AreEqual(0, SalesHeader."Invoice Discount Value", 'Invoice Discount Amount was not set to correct value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerInvoiceDiscountSetFromCustomerCard()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        CustInvoiceDiscounts: TestPage "Cust. Invoice Discounts";
        DiscPct: Decimal;
    begin
        // [SCENARIO 169593] It should be possible to open "Cust. Invoice Discounts" page from customer card

        Initialize();

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // [GIVEN] Create a new customer "C" and open "Customer Card" page
        LibrarySmallBusiness.CreateCustomer(Customer);
        DiscPct := LibraryRandom.RandDecInRange(10, 20, 2);

        CustomerCard.OpenView();
        CustomerCard.GotoRecord(Customer);
        CustInvoiceDiscounts.Trap();

        // [GIVEN] Run "Page Cust. Invoice Discounts" action from customer card to open customer discounts. Set "Discount %" = "X"
        CustomerCard."Invoice &Discounts".Invoke();
        CustInvoiceDiscounts."Minimum Amount".SetValue(LibraryRandom.RandDec(100, 2));
        CustInvoiceDiscounts."Discount %".SetValue(DiscPct);
        CustInvoiceDiscounts.OK().Invoke();
        CustomerCard.OK().Invoke();

        // [GIVEN] Create a sales invoice for customer "C"
        CreateNewInvoiceWithLines(SalesHeader, Customer, 1, LibraryRandom.RandDecInRange(200, 300, 2), LibraryRandom.RandInt(10));

        // [WHEN] Calculate invoice discount
        SalesCalcDiscByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);

        // [THEN] Invoice discount percentage = "X"
        VerifyCustomerDiscountPercentage(SalesHeader, DiscPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInvoiceDiscountTypeAmountOnDeleteSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DiscPct: Decimal;
        ExpectedDiscountPercent: Decimal;
    begin
        // [SCENARIO 280220] Calculate Invoice Discount Amount based on Amount when sales line is deleted from document
        Initialize();

        LibraryLowerPermissions.SetSalesDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // [GIVEN] Sales Invoice with with two lines. Amount = 200 in each line. Invoice Discount calculation is based on amount
        CreateInvoiceWithLinesAndCustomerDiscount(SalesHeader, 2, 0);
        SalesHeader.Validate("Invoice Discount Calculation", SalesHeader."Invoice Discount Calculation"::Amount);
        SalesHeader.Modify(true);

        // [GIVEN] Invoice's "Invoice Discount Amount" = 100, Invoice Discount % = 25.
        SalesCalcDiscByType.ApplyInvDiscBasedOnAmt(LibraryRandom.RandIntInRange(100, 200), SalesHeader);
        FindLastSalesLine(SalesLine, SalesHeader);
        ExpectedDiscountPercent := SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine);

        // [WHEN] Delete line from invoice
        SalesLine.Delete(true);

        // [THEN] Invoice Discount % = 0, reset due to performance issue
        FindLastSalesLine(SalesLine, SalesHeader);
        DiscPct := SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine);
        Assert.AreEqual(ExpectedDiscountPercent, DiscPct, 'Invalid calculated discount percent.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Sales Calc Disc By Type");
        // Lazy Setup.
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Sales Calc Disc By Type");

        ClearTable(DATABASE::Resource);
        ClearTable(DATABASE::"Res. Ledger Entry");
        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        LibraryERMCountryData.CreateVATData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Sales Calc Disc By Type");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Resource: Record Resource;
        ResLedgerEntry: Record "Res. Ledger Entry";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::Resource:
                Resource.DeleteAll();
            DATABASE::"Res. Ledger Entry":
                ResLedgerEntry.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure CreateItem(var Item: Record Item; UnitPrice: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item.Validate("Unit Price", UnitPrice);
        Item.Modify(true);
    end;

    local procedure CreateNewInvoiceWithLines(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; NumberOfLines: Integer; ItemUnitPrice: Decimal; ItemQuantity: Integer)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        CreateItem(Item, ItemUnitPrice);
        LibrarySmallBusiness.CreateSalesInvoiceHeader(SalesHeader, Customer);

        for I := 1 to NumberOfLines do
            LibrarySmallBusiness.CreateSalesLine(SalesLine, SalesHeader, Item, ItemQuantity);
    end;

    local procedure CreateCustomerWithDiscount(var Customer: Record Customer; DiscPct: Decimal; MinDiscAmount: Decimal)
    begin
        LibrarySmallBusiness.CreateCustomer(Customer);
        LibrarySmallBusiness.SetInvoiceDiscountToCustomer(Customer, DiscPct, MinDiscAmount, '');
    end;

    local procedure CreateInvoiceWithLinesAndCustomerDiscount(var SalesHeader: Record "Sales Header"; NumberOfLines: Decimal; DiscPct: Decimal)
    var
        Customer: Record Customer;
        MinDiscAmount: Decimal;
        ItemUnitPrice: Decimal;
        ItemQuantity: Integer;
    begin
        ItemUnitPrice := LibraryRandom.RandDecInRange(10, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinDiscAmount := NumberOfLines * ItemUnitPrice * ItemQuantity;

        CreateCustomerWithDiscount(Customer, DiscPct, MinDiscAmount);
        CreateNewInvoiceWithLines(SalesHeader, Customer, NumberOfLines, ItemUnitPrice, ItemQuantity);
    end;

    local procedure FindLastSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
    end;

    local procedure VerifyInvoiceDiscountTypeAmount(SalesHeader: Record "Sales Header"; InvoiceDiscountAmount: Decimal; NumberOfLines: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        Assert.AreEqual(InvoiceDiscountAmount, SalesHeader."Invoice Discount Value", 'Invoice Discount Amount was not set to correct value');
        Assert.AreEqual(
          SalesHeader."Invoice Discount Calculation"::Amount, SalesHeader."Invoice Discount Calculation", 'Invoice Discount Calclulation should be Amount');

        Assert.AreEqual(
          RoundAmount(InvoiceDiscountAmount / NumberOfLines), SalesLine."Inv. Discount Amount",
          'Invoice Discount Amount was not distributed equaly accross the lines');
    end;

    local procedure VerifyInvoiceDiscountTypePercentage(SalesHeader: Record "Sales Header"; DiscPct: Decimal; NumberOfLines: Decimal)
    var
        SalesLine: Record "Sales Line";
        InvoiceDiscountAmount: Decimal;
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();

        InvoiceDiscountAmount := NumberOfLines * SalesLine."Line Amount" * DiscPct / 100;

        Assert.AreEqual(DiscPct, SalesHeader."Invoice Discount Value", 'Invoice Discount Amount was not set to correct value');
        Assert.AreEqual(
          SalesHeader."Invoice Discount Calculation"::"%", SalesHeader."Invoice Discount Calculation", 'Invoice Discount Calclulation should be %');

        Assert.AreEqual(
          RoundAmount(InvoiceDiscountAmount / NumberOfLines), SalesLine."Inv. Discount Amount",
          'Invoice Discount Amount was not distributed equaly accross the lines');
    end;

    local procedure SetAllowInvoiceDiscountOnAllLines(SalesHeader: Record "Sales Header"; AllowInvoiceDiscount: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");

        SalesLine.ModifyAll("Allow Invoice Disc.", AllowInvoiceDiscount, true);
    end;

    local procedure VerifyCustomerDiscountPercentage(SalesHeader: Record "Sales Header"; CustDiscPct: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        Assert.AreEqual(
          CustDiscPct, SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine),
          'CustomerDiscountPercentage was not set to expected value');
    end;

    local procedure VerifyCustomerDiscountPercentageFromAmount(SalesHeader: Record "Sales Header"; InvoiceDiscAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        Assert.AreEqual(
          Round((InvoiceDiscAmount / (SalesLine.Amount + InvoiceDiscAmount) * 100), 0.01), SalesCalcDiscByType.GetCustInvoiceDiscountPct(SalesLine),
          'CustomerDiscountPercentage was not set to expected value');
    end;

    local procedure GenerateTestData(var DiscPct: Decimal; var NumberOfLines: Integer; var InvoiceDiscountAmount: Decimal)
    begin
        InvoiceDiscountAmount := LibraryRandom.RandDecInDecimalRange(100, 10000, 2);
        NumberOfLines := LibraryRandom.RandIntInRange(2, 50);
        DiscPct := LibraryRandom.RandDecInDecimalRange(1, 100, 2);
    end;

    local procedure RoundAmount(Amount: Decimal): Decimal
    begin
        exit(Round(Amount, LibraryERM.GetAmountRoundingPrecision()));
    end;
}

