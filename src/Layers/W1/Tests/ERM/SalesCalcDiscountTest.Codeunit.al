codeunit 132522 "Sales-Calc. Discount Test"
{
    // This test is developed for the C/AL Test Design Workshop (Sep 2009).
    // In this workshop it is the end result of a series of refactorings.
    // Most of the comments are for educational purpose.
    // 
    // This codeunit contains six unit tests for the Sales-Calc. Discount codeunit,
    // that calculates customer invoice discounts.

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Discount]
        // PATTERN: Implicit Setup
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        Initialized: Boolean;
        LineDiscountPctErr: Label 'The value in the Line Discount % field must be between 0 and 100.';
        LineDscPctErr: Label 'Wrong value of Line Discount %.';
        LineAmountInvalidErr: Label 'You have set the line amount to a value that results in a discount that is not valid. Consider increasing the unit price instead.';
        InvDscPctErr: Label 'Wrong value of Invoice Discount %.';

    local procedure Initialize()
    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Sales-Calc. Discount Test");
        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Sales-Calc. Discount Test");
        Commit();
        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Sales-Calc. Discount Test");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LcyDiscountTest()
    begin
        // Test: eligible for LCY discount on LCY sales order

        // Setup
        // PATTERN: Delegated Setup
        Initialize();

        DiscountTest('', '', 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LcyNoDiscountTest()
    begin
        // Test: not eligible for LCY discount on LCY sales order

        // PATTERN: Delegated Setup
        Initialize();

        DiscountTest('', '', -1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FcyDiscountTest()
    var
        Currency: Record Currency;
    begin
        // Test: eligible for FCY discount on FCY sales order

        // PATTERN: Delegated Setup
        Initialize();
        // PATTERN: In-line Setup
        // PATTERN: Random Generated Value
        Currency.Next(LibraryRandom.RandInt(Currency.Count));

        DiscountTest(Currency.Code, Currency.Code, 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FcyNoDiscountTest()
    var
        Currency: Record Currency;
    begin
        // PATTERN: Delegated Setup
        Initialize();
        // PATTERN: In-line Setup
        // PATTERN: Random Generated Value
        Currency.Next(LibraryRandom.RandInt(Currency.Count));

        // Test: not eligible for FCY discount on FCY sales order
        DiscountTest(Currency.Code, Currency.Code, -1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FcyOrderLcyDiscountTest()
    var
        Currency: Record Currency;
    begin
        // Test: eligible for LCY discount on FCY sales order

        // PATTERN: Delegated Setup
        Initialize();
        // PATTERN: In-line Setup
        // PATTERN: Random Generated Value
        Currency.Next(LibraryRandom.RandInt(Currency.Count));

        DiscountTest('', Currency.Code, 1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FcyOrderLcyNoDiscountTest()
    var
        Currency: Record Currency;
    begin
        // Test: not eligible for LCY discount on FCY sales order

        // PATTERN: Delegated Setup
        Initialize();
        // PATTERN: In-line Setup
        // PATTERN: Random Generated Value
        Currency.Next(LibraryRandom.RandInt(Currency.Count));

        DiscountTest('', Currency.Code, -1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctPositiveWhenQuantityUnitPriceLineDiscAmountArePositive()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] The "Sales Line"."Line Discount %" is positive when "Quantity", "Unit Price" and "Line Discount Amount" are positive
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, 1, 100);
        SalesLine.Validate("Line Discount Amount", 50);
        Assert.IsTrue(SalesLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctErrorWhenQuantityUnitPriceArePositiveLineDiscAmountIsNegative()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate negative "Line Discount Amount" when "Quantity" and "Unit Price" are positive.
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, LibraryRandom.RandIntInRange(10, 100), LibraryRandom.RandIntInRange(10, 100));
        asserterror SalesLine.Validate("Line Discount Amount", -LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctPositiveWhenQuantityIsPositiveUnitPriceLineDiscAmountIsNegative()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] The "Sales Line"."Line Discount %" is positive when "Quantity" is positive, and "Unit Price" and "Line Discount Amount" are negative
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, 1, -100);
        SalesLine.Validate("Line Discount Amount", -50);
        Assert.IsTrue(SalesLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctErrorWhenQuantityUnitPriceLineDiscAmountAreNegative()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate negative "Line Discount Amount" when "Quantity" and "Unit Price" are negative.
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, -LibraryRandom.RandIntInRange(10, 100), -LibraryRandom.RandIntInRange(10, 100));
        asserterror SalesLine.Validate("Line Discount Amount", -LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctPositiveWhenQuantityUnitPriceAreNegativeLineDiscAmountIsPositive()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] The "Sales Line"."Line Discount %" is positive when "Quantity" and "Unit Price" are negative, and "Line Discount Amount" is positive
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, -1, -100);
        SalesLine.Validate("Line Discount Amount", 50);
        Assert.IsTrue(SalesLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctErrorWhenQuantityIsNegativeUnitPriceLineDiscAmountArePostive()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate positive "Line Discount Amount" when "Quantity" is negative and "Unit Price" is positive.
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, -LibraryRandom.RandIntInRange(10, 100), LibraryRandom.RandIntInRange(10, 100));
        asserterror SalesLine.Validate("Line Discount Amount", LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctErrorWhenQuantityLineDiscAmountArePositiveUnitPriceAreNegative()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate positive "Line Discount Amount" when "Quantity" is positive and "Unit Price" is negative.
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, LibraryRandom.RandIntInRange(10, 100), -LibraryRandom.RandIntInRange(10, 100));
        asserterror SalesLine.Validate("Line Discount Amount", LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctPositiveWhenQuantityLineDiscAmountAreNegativeUnitPriceArePositive()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] The "Sales Line"."Line Discount %" is positive when "Quantity" and "Line Discount Amount" are negative, and "Unit Price" is positive
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, -1, 100);
        SalesLine.Validate("Line Discount Amount", -50);
        Assert.IsTrue(SalesLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctErrorWhenLineDiscountPctMoreThan100()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Discount Amount" and the calculated "Line Discount %" more than 100
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, 1, 100);
        asserterror SalesLine.Validate("Line Discount Amount", 150);
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctErrorWhenLineAmountMoreThanAmount()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Amount" and the calculated "Line Discount %" less than 0
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, 1, 100);
        asserterror SalesLine.Validate("Line Amount", SalesLine.Amount * 2);
        Assert.ExpectedError(LineAmountInvalidErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctWhenLineAmountIsPositiveAndLessThanAmount()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348]  The "Sales Line"."Line Discount %" is positive when "Line Amount" is positive and less than "Amount"
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, 1, 100);
        SalesLine.Validate("Line Amount", SalesLine.Amount / 2);
        Assert.IsTrue(SalesLine."Line Discount %" in [1 .. 100], LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountPctErrorWhenLineAmountIsNegative()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Amount" and the calculated "Line Discount %" is more than 100
        Initialize();
        CreateSalesOrderWithQuantityAndUnitPrice(SalesLine, 1, 100);
        asserterror SalesLine.Validate("Line Amount", -SalesLine.Amount);
        Assert.ExpectedError(LineAmountInvalidErr);
    end;

    [Test]
    procedure InvDiscPerShowCorrectValueAfterAddingLineDiscount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        InvoiceDiscPer: Decimal;
    begin
        // [SCENARIO 560958] Invoice discount percentage shows correct value after adding a line discount.
        Initialize();

        // [GIVEN] Enable invoice discount calculation on "Sales & Receivables Setup".
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Generate invoice discount percentage.
        InvoiceDiscPer := CreateCustomerInvDiscount(Customer."No.");

        // [GIVEN] Create Item.
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Create Sales Order.    
        CreateSalesOrder(SalesHeader, Customer."No.", ItemNo);

        // [GIVEN] Calculate discount.
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [GIVEN] Update line discount percentage in Sales Line.
        FindSalesLine(SalesHeader, SalesLine, ItemNo);
        UpdateSalesLineByField(SalesLine, SalesLine.FieldNo("Line Discount %"), LibraryRandom.RandInt(5));

        // [THEN] Verify invoice discount percentage does not change after calculation of Line Discount.
        SalesHeader.Find();
        Assert.AreEqual(InvoiceDiscPer, SalesHeader."Invoice Discount Value", InvDscPctErr);
    end;

    local procedure DiscountTest(DiscCurrencyCode: Code[10]; SOCurrencyCode: Code[10]; QuantityDelta: Integer)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesLine: Record "Sales Line";
        ExpectedDiscountAmount: Decimal;
    begin
        // QuantityDelta is used to get above (if positive) or below (if negative) the quantity required to be awarded a discount

        // PATTERN: Parameterized Test
        // PATTERN: Four-Phase Test: Setup, Exercise, Verify, Teardown

        // Setup
        // PATTERN: Fresh Fixture
        // PATTERN: Delegated Setup
        CreateCustInvoiceDisc(DiscCurrencyCode, CustInvoiceDisc);
        CreateSalesLine(CustInvoiceDisc, SOCurrencyCode, SalesLine);
        SalesLine.Validate(Quantity, MinDiscountQuantity(CustInvoiceDisc, SalesLine) + QuantityDelta);
        SalesLine.Modify(true);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");

        // Verify
        // PATTERN: Derived Expectation
        if QuantityDelta >= 0 then
            ExpectedDiscountAmount := RoundCurrency(SalesLine."Line Amount" * CustInvoiceDisc."Discount %" / 100, SOCurrencyCode)
        else // if ordered less than the minimum amount no discount is awarded
            ExpectedDiscountAmount := 0;

        // PATTERN: Assertion Message
        Assert.AreEqual(
          ExpectedDiscountAmount,
          SalesLine."Inv. Discount Amount",
          StrSubstNo(
            'SOCurrencyCode: %1; %2; %3',
            SOCurrencyCode,
            CustInvoiceDiscToText(CustInvoiceDisc),
            SalesLineToText(SalesLine)));

        // Tear down
        // PATTERN: In-line Tear down
        CustInvoiceDisc.Delete(true);
        // PATTERN: Delegated Tear Down
        TearDownSalesLine(SalesLine)
    end;

    local procedure CreateSalesLine(CustInvoiceDisc: Record "Cust. Invoice Disc."; CurrencyCode: Code[10]; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // PATTERN: Creation Function
        // PATTERN: Generated Value
        Customer.Next(LibraryRandom.RandInt(Customer.Count));
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Customer.Validate("Bill-to Customer No.", '');
        Customer.Validate("Allow Line Disc.", false);
        Customer.Modify(true);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // PATTERN: Generate Value
        LibraryInventory.CreateItemWithoutVAT(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Allow Invoice Disc.", true);
        Item.Modify(true);

        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", 10000);
        SalesLine.Insert(true);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", Item."No.");
        SalesLine.Modify(true);
    end;

    local procedure CreateCustInvoiceDisc(CurrencyCode: Code[10]; var CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
        Clear(CustInvoiceDisc);
        // PATTERN: Self-Describing Value
        CustInvoiceDisc.Validate(Code, 'TESTDISCOUNT');
        CustInvoiceDisc.Validate("Currency Code", CurrencyCode);
        CustInvoiceDisc.Validate("Minimum Amount", 100 * LibraryRandom.RandInt(1000));
        CustInvoiceDisc.Insert(true);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(100));
        CustInvoiceDisc.Modify(true)
    end;

    local procedure CreateSalesOrderWithQuantityAndUnitPrice(var SalesLine: Record "Sales Line"; Quanitiy: Integer; UnitPrice: Integer)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), Quanitiy);
        SalesLine.Validate("Unit Price", UnitPrice);
    end;

    local procedure TearDownSalesLine(SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        // PATTERN: Tear Down Function
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.Delete(true);
        SalesHeader.Delete(true)
    end;

    local procedure MinDiscountQuantity(CustInvoiceDisc: Record "Cust. Invoice Disc."; SalesLine: Record "Sales Line"): Decimal
    var
        SalesHeader: Record "Sales Header";
        MinAmountSOCurrency: Decimal;
    begin
        // PATTERN: Test-Utility Function
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        case true of
            CustInvoiceDisc."Currency Code" = SalesHeader."Currency Code":
                MinAmountSOCurrency := CustInvoiceDisc."Minimum Amount";
            CustInvoiceDisc."Currency Code" = '':
                MinAmountSOCurrency := ConvertLcy(CustInvoiceDisc."Minimum Amount", SalesHeader."Currency Code")
            else
                Assert.Fail('FCY discounts are not awarded to LCY sales orders.')
        end;

        exit(MinAmountSOCurrency / SalesLine."Unit Price")
    end;

    local procedure ConvertLcy(Amount: Decimal; LcyCurrencyCode: Code[10]): Decimal
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // PATTERN: Test-Utility Function
        exit(Amount * CurrencyExchangeRate.ExchangeRate(WorkDate(), LcyCurrencyCode))
    end;

    local procedure RoundCurrency(Amount: Decimal; CurrencyCode: Code[10]): Decimal
    var
        Currency: Record Currency;
    begin
        // PATTERN: Test-Utility Function
        if CurrencyCode = '' then
            exit(Round(Amount));

        Currency.Get(CurrencyCode);
        exit(Round(Amount, Currency."Amount Rounding Precision"));
    end;

    local procedure SalesLineToText(SalesLine: Record "Sales Line"): Text[1024]
    var
        SalesHeader: Record "Sales Header";
    begin
        // PATTERN: Test-Utility Function
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        exit('SALES LINE: Item No.=' + SalesLine."No." +
          ', Unit Price=' + Format(SalesLine."Unit Price") +
          ', Quantity=' + Format(SalesLine.Quantity) +
          ', Line Amount=' + Format(SalesLine."Line Amount") +
          ', Inv. Discount Amount=' + Format(SalesLine."Inv. Discount Amount") +
          ', Bill-to Custumer No.=' + SalesHeader."Bill-to Customer No.")
    end;

    local procedure CustInvoiceDiscToText(CustInvoiceDisc: Record "Cust. Invoice Disc."): Text[1024]
    begin
        // PATTERN: Test-Utility Function
        exit('CUST. INVOICE DISC.: Currency=' + CustInvoiceDisc."Currency Code" +
              ', Minimum Amount=' + Format(CustInvoiceDisc."Minimum Amount") +
              ', Discount=' + Format(CustInvoiceDisc."Discount %"))
    end;

    local procedure CreateCustomerInvDiscount(CustomerNo: Code[20]): Decimal
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDecInRange(10, 20, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc."Discount %");
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        UnitPrice: Decimal;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        UnitPrice := LibraryRandom.RandDecInRange(1000, 2000, 2);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(0));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure FindSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
    end;

    local procedure UpdateSalesLineByField(var SalesLine: Record "Sales Line"; FieldNo: Integer; Val: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(SalesLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Val);
        RecRef.SetTable(SalesLine);
        SalesLine.Modify(true);
    end;
}

