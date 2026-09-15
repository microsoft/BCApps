codeunit 138013 "O365 Purch. Calc Disc. By Type"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Invoice Discount] [SMB] [Purchase]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyDefaultInvoiceDiscountTypeAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);

        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::Amount);
        PurchaseHeader.Modify();

        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        VerifyInvoiceDiscountTypeAmount(PurchaseHeader, InvoiceDiscountAmount, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyDefaultInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);

        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount, PurchaseHeader);

        VerifyInvoiceDiscountTypePercentage(PurchaseHeader, DiscPct, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvoiceDiscountAmountOnInvoiceWithoutDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);

        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        VerifyInvoiceDiscountTypeAmount(PurchaseHeader, InvoiceDiscountAmount, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvoiceDiscountAmountOverridesInvoiceDiscountTypePercentage()
    var
        PurchaseHeader: Record "Purchase Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(InvoiceDiscountAmount, PurchaseHeader);

        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        VerifyInvoiceDiscountTypeAmount(PurchaseHeader, InvoiceDiscountAmount, NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetVendInvoiceDiscPctWhenItExists()
    var
        PurchaseHeader: Record "Purchase Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);
        VerifyVendorDiscountPercentage(PurchaseHeader, 0);

        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);
        VerifyVendorDiscountPercentage(PurchaseHeader, DiscPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetVendInvoiceDiscPctWhenNoneIsDefined()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        NumberOfLines: Decimal;
        ItemUnitPrice: Decimal;
        ItemQuantity: Integer;
    begin
        Initialize();
        NumberOfLines := 1;
        ItemUnitPrice := LibraryRandom.RandDecInRange(10, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);

        LibrarySmallBusiness.CreateVendor(Vendor);
        CreateNewInvoiceWithLines(PurchaseHeader, Vendor, NumberOfLines, ItemUnitPrice, ItemQuantity);

        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);

        VerifyVendorDiscountPercentage(PurchaseHeader, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetVendInvoiceDiscPctWhenInvDiscTypeIsAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);

        VerifyVendorDiscountPercentageFromAmount(PurchaseHeader, InvoiceDiscountAmount / NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetVendInvoiceDscPctWhenAmountChangesInvDiscGroup()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
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

        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.SetInvoiceDiscountToVendor(Vendor, DiscPct1, MinAmount1, '');
        LibrarySmallBusiness.SetInvoiceDiscountToVendor(Vendor, DiscPct2, MinAmount2, '');

        CreateNewInvoiceWithLines(PurchaseHeader, Vendor, NumberOfLines, ItemUnitPrice, ItemQuantity);

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();

        PurchaseLine.Validate("Line Amount", MinAmount1);
        PurchaseLine.Modify(true);
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);
        VerifyVendorDiscountPercentage(PurchaseHeader, DiscPct1);

        PurchaseLine.Validate("Line Amount", MinAmount2);
        PurchaseLine.Modify(true);

        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);
        VerifyVendorDiscountPercentage(PurchaseHeader, DiscPct2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvDiscAmountWhenInvDiscBaseAmountIsZero()
    var
        PurchaseHeader: Record "Purchase Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);
        SetAllowInvoiceDiscountOnAllLines(PurchaseHeader, false);

        asserterror PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
        Assert.ExpectedError('Cannot apply an invoice discount because the document does not include lines where the Allow Invoice Disc. field is selected.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetInvDiscAmountHigherThanInvDiscBaseAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);

        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();

        InvoiceDiscountAmount := NumberOfLines * PurchaseLine."Line Amount" + 1;
        asserterror PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, PurchaseHeader);
        Assert.ExpectedError('that you can apply is');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountPercentageIsNotAppliedIfThereAreNoLinesThatAllowDiscPct()
    var
        PurchaseHeader: Record "Purchase Header";
        DiscPct: Decimal;
        NumberOfLines: Integer;
        InvoiceDiscountAmount: Decimal;
    begin
        Initialize();
        GenerateTestData(DiscPct, NumberOfLines, InvoiceDiscountAmount);

        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, NumberOfLines, DiscPct);
        SetAllowInvoiceDiscountOnAllLines(PurchaseHeader, false);

        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);

        Assert.AreEqual(0, PurchaseHeader."Invoice Discount Value", 'Invoice Discount Amount was not set to correct value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorInvoiceDiscountSetFromVendorCard()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        VendorCard: TestPage "Vendor Card";
        VendInvoiceDiscounts: TestPage "Vend. Invoice Discounts";
        DiscPct: Decimal;
    begin
        // [SCENARIO 169593] It should be possible to open "Vend. Invoice Discounts" page from vendor card

        Initialize();

        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // [GIVEN] Create a new vendor "V" and open "Vendor Card" page
        LibrarySmallBusiness.CreateVendor(Vendor);
        DiscPct := LibraryRandom.RandDecInRange(10, 20, 2);

        VendorCard.OpenView();
        VendorCard.GotoRecord(Vendor);
        VendInvoiceDiscounts.Trap();

        // [GIVEN] Run "Page Vend. Invoice Discounts" action from vendor card to open vendor discounts. Set "Discount %" = "X"
        VendorCard."Invoice &Discounts".Invoke();
        VendInvoiceDiscounts."Minimum Amount".SetValue(LibraryRandom.RandDec(100, 2));
        VendInvoiceDiscounts."Discount %".SetValue(DiscPct);
        VendInvoiceDiscounts.OK().Invoke();
        VendorCard.OK().Invoke();

        // [GIVEN] Create a purchase invoice for vendor "V"
        CreateNewInvoiceWithLines(PurchaseHeader, Vendor, 1, LibraryRandom.RandDecInRange(200, 300, 2), LibraryRandom.RandInt(10));

        // [WHEN] Calculate invoice discount
        PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);

        // [THEN] Invoice discount percentage = "X"
        VerifyVendorDiscountPercentage(PurchaseHeader, DiscPct);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcInvoiceDiscountTypeAmountOnDeletePurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DiscPct: Decimal;
        ExpectedDiscountPercent: Decimal;
    begin
        // [SCENARIO 280220] Calculate Invoice Discount Amount based on Amount when purchase line is deleted from document
        Initialize();

        LibraryLowerPermissions.SetPurchDocsCreate();
        LibraryLowerPermissions.AddO365Setup();

        // [GIVEN] Purchase Invoice with with two lines. Amount = 200 in each line. Invoice Discount calculation is based on amount
        CreateInvoiceWithLinesAndVendorDiscount(PurchaseHeader, 2, 0);
        PurchaseHeader.Validate("Invoice Discount Calculation", PurchaseHeader."Invoice Discount Calculation"::Amount);
        PurchaseHeader.Modify();

        // [GIVEN] Invoice's "Invoice Discount Amount" = 100, Invoice Discount % = 25.
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(LibraryRandom.RandIntInRange(100, 200), PurchaseHeader);
        FindLastPurchaseLine(PurchaseLine, PurchaseHeader);
        ExpectedDiscountPercent := PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine);

        // [WHEN] Delete line from invoice
        PurchaseLine.Delete(true);

        // [THEN] Invoice Discount % = 0, reset due to performance issue
        FindLastPurchaseLine(PurchaseLine, PurchaseHeader);
        DiscPct := PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine);
        Assert.AreEqual(ExpectedDiscountPercent, DiscPct, 'Invalid calculated discount percent.');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Purch. Calc Disc. By Type");
        // Lazy Setup
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Purch. Calc Disc. By Type");

        ClearTable(DATABASE::Resource);

        LibraryERMCountryData.CreateVATData();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Purch. Calc Disc. By Type");
    end;

    local procedure ClearTable(TableID: Integer)
    var
        Resource: Record Resource;
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        case TableID of
            DATABASE::Resource:
                Resource.DeleteAll();
        end;
        LibraryLowerPermissions.SetO365Full();
    end;

    local procedure CreateItem(var Item: Record Item; LastPurchasePrice: Decimal)
    begin
        LibrarySmallBusiness.CreateItem(Item);
        Item.Validate("Last Direct Cost", LastPurchasePrice);
        Item.Modify(true);
    end;

    local procedure CreateNewInvoiceWithLines(var PurchaseHeader: Record "Purchase Header"; var Vendor: Record Vendor; NumberOfLines: Integer; LastPurchasePrice: Decimal; ItemQuantity: Integer)
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        CreateItem(Item, LastPurchasePrice);
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);

        for I := 1 to NumberOfLines do
            LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, ItemQuantity);
    end;

    local procedure CreateVendorWithDiscount(var Vendor: Record Vendor; DiscPct: Decimal; MinDiscAmount: Decimal)
    begin
        LibrarySmallBusiness.CreateVendor(Vendor);
        LibrarySmallBusiness.SetInvoiceDiscountToVendor(Vendor, DiscPct, MinDiscAmount, '');
    end;

    local procedure CreateInvoiceWithLinesAndVendorDiscount(var PurchaseHeader: Record "Purchase Header"; NumberOfLines: Decimal; DiscPct: Decimal)
    var
        Vendor: Record Vendor;
        MinDiscAmount: Decimal;
        LastPurchasePrice: Decimal;
        ItemQuantity: Integer;
    begin
        LastPurchasePrice := LibraryRandom.RandDecInRange(10, 10000, 2);
        ItemQuantity := LibraryRandom.RandIntInRange(1, 100);
        MinDiscAmount := NumberOfLines * LastPurchasePrice * ItemQuantity;

        CreateVendorWithDiscount(Vendor, DiscPct, MinDiscAmount);
        CreateNewInvoiceWithLines(PurchaseHeader, Vendor, NumberOfLines, LastPurchasePrice, ItemQuantity);
    end;

    local procedure FindLastPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindLast();
    end;

    local procedure VerifyInvoiceDiscountTypeAmount(PurchaseHeader: Record "Purchase Header"; InvoiceDiscountAmount: Decimal; NumberOfLines: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();

        Assert.AreEqual(InvoiceDiscountAmount, PurchaseHeader."Invoice Discount Value", 'Invoice Discount Amount was not set to correct value');
        Assert.AreEqual(
          PurchaseHeader."Invoice Discount Calculation"::Amount, PurchaseHeader."Invoice Discount Calculation", 'Invoice Discount Calclulation should be Amount');

        Assert.AreEqual(
          RoundAmount(InvoiceDiscountAmount / NumberOfLines), PurchaseLine."Inv. Discount Amount",
          'Invoice Discount Amount was not distributed equaly accross the lines');
    end;

    local procedure VerifyInvoiceDiscountTypePercentage(PurchaseHeader: Record "Purchase Header"; DiscPct: Decimal; NumberOfLines: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        InvoiceDiscountAmount: Decimal;
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();

        InvoiceDiscountAmount := NumberOfLines * PurchaseLine."Line Amount" * DiscPct / 100;

        Assert.AreEqual(DiscPct, PurchaseHeader."Invoice Discount Value", 'Invoice Discount Value was not set to correct value');
        Assert.AreEqual(
          PurchaseHeader."Invoice Discount Calculation"::"%", PurchaseHeader."Invoice Discount Calculation", 'Invoice Discount Calclulation should be %');

        Assert.AreEqual(
          RoundAmount(InvoiceDiscountAmount / NumberOfLines), PurchaseLine."Inv. Discount Amount",
          'Invoice Discount Amount was not distributed equaly accross the lines');
    end;

    local procedure SetAllowInvoiceDiscountOnAllLines(PurchaseHeader: Record "Purchase Header"; AllowInvoiceDiscount: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");

        PurchaseLine.ModifyAll("Allow Invoice Disc.", AllowInvoiceDiscount, true);
    end;

    local procedure VerifyVendorDiscountPercentage(PurchaseHeader: Record "Purchase Header"; VendDiscPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();
        Assert.AreEqual(
          VendDiscPct, PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine),
          'VendorDiscountPercentage was not set to expected value');
    end;

    local procedure VerifyVendorDiscountPercentageFromAmount(PurchaseHeader: Record "Purchase Header"; InvoiceDiscAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        VendDiscPct: Decimal;
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();
        VendDiscPct := Round((InvoiceDiscAmount / (PurchaseLine.Amount + InvoiceDiscAmount) * 100), 0.01);
        Assert.AreEqual(
          VendDiscPct, PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchaseLine),
          'VendorDiscountPercentage was not set to expected value');
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

