codeunit 134167 "Copy Price Data Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Price List Line] [Upgrade]
    end;

    var
        Assert: Codeunit Assert;
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryCRMIntegration: Codeunit "Library - CRM Integration";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: codeunit "Library - Marketing";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ResType: Option Resource,"Group(Resource)",All;
        IsInitialized: Boolean;

    [Test]
    procedure T001_CopySalesPriceToSeparateHeaders()
    var
        Currency: Record Currency;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        PriceListCode: Code[20];
    begin
        Initialize();
        SalesPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Sales Prices, for All Customers, Item, with/without Currency.
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateCurrency(Currency);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), Currency.Code, '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), '', '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with/without "Currency Code"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        PriceListLine.Next();
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T002_CopySalesPriceToSameHeader()
    var
        Currency: Record Currency;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        PriceListCode: Code[20];
    begin
        Initialize();
        SalesPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Sales Prices, for All Customers, different Items, same Currency.
        LibraryERM.CreateCurrency(Currency);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), Currency.Code, '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), Currency.Code, '', Item."Base Unit of Measure", 10, LibraryRandom.RandDec(1000, 2));

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines to one Header with "Currency Code"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        PriceListLine.Next();
        Assert.AreEqual(PriceListCode, PriceListLine."Price List Code", 'different price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T003_CopySalesPriceDiscoutToSeparateHeaders()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        PriceListCode: Code[20];
    begin
        Initialize();
        SalesPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] Sales Price and Discount, for Customer 'C', Item
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateCurrency(Currency);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::Customer, Customer."No.",
            Today(), Currency.Code, '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, "Sales Line Discount Type"::Item, Item."No.",
            "Sales Price Type"::Customer.AsInteger(), Customer."No.", Today(), '', '', Item."Base Unit of Measure", 10);

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with Amount Type "Price" and "Discount"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T004_CopySalesPriceCampaignToSeparateHeaders()
    var
        Campaign: Record Campaign;
        Currency: Record Currency;
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        PriceListCode: Code[20];
    begin
        // [FEATURE] [Campaign]
        // [SCENARIO 379607] Campaign Sales Price should be converted to Campaign price list line.
        Initialize();
        SalesPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Sales Prices, for Campaign andf Customer Price Group, Item, with/without Currency.
        LibraryInventory.CreateItem(Item);
        LibraryMarketing.CreateCampaign(Campaign);
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryERM.CreateCurrency(Currency);
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::Campaign, Campaign."No.",
            Today(), Currency.Code, '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"Customer Price Group", CustomerPriceGroup.Code,
            Today(), '', '', Item."Base Unit of Measure", 5, LibraryRandom.RandDec(1000, 2));

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with/without "Currency Code"
        PriceListLine.FindFirst();
        PriceListLine.TestField("Source Type", "Price Source Type"::"Customer Price Group");
        PriceListLine.TestField("Source No.", CustomerPriceGroup.Code);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] Price line for Campaign belongs to the header, where "Source Group" is 'Customer'
        PriceListLine.Next();
        PriceListLine.TestField("Source Type", "Price Source Type"::Campaign);
        PriceListLine.TestField("Source No.", Campaign."No.");
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T005_CopySalesPriceWithInconsistentData()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVar: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        UnitofMeasure: Record "Unit of Measure";
    begin
        Initialize();
        SalesPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 5 Sales Prices, where inconsistent Customer, Item, Item Variant, Unit of measure, Currency.
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(ItemVar);
        LibraryInventory.CreateItemVariant(ItemVariant, ItemVar."No.");
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, ItemVar."No.", UnitofMeasure.Code, 3);
        LibraryERM.CreateCurrency(Currency);
        LibrarySales.CreateSalesPrice(
            SalesPrice, ItemVar."No.", "Sales Price Type"::Customer, Customer."No.",
            Today(), '', '', '', 1, LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesPrice(
            SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '',
            Today(), '', '', '', 2, LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesPrice(
            SalesPrice, ItemVar."No.", "Sales Price Type"::"All Customers", '',
            Today(), '', ItemVariant.Code, '', 3, LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesPrice(
            SalesPrice, ItemVar."No.", "Sales Price Type"::"All Customers", '',
            Today(), '', '', UnitofMeasure.Code, 4, LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesPrice(
            SalesPrice, ItemVar."No.", "Sales Price Type"::"All Customers", '',
            Today(), Currency.Code, '', '', 5, LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Customer, Item, Variant, Unit of measure, Currency are removed
        Customer.Delete();
        Item.Delete();
        ItemVariant.Delete();
        ItemUnitofMeasure.Delete();
        Currency.Delete();

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [THEN] Price List Line is not created
        Assert.IsFalse(PriceListLine.FindFirst(), 'line is created');
        Assert.IsFalse(PriceListHeader.Get(PriceListLine."Price List Code"), 'header is created');
    end;

    [Test]
    procedure T006_CopySalesLineDiscWithInconsistentData()
    var
        Customer: Record Customer;
        Currency: Record Currency;
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVar: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        SalesLineDiscount: Record "Sales Line Discount";
        UnitofMeasure: Record "Unit of Measure";
    begin
        Initialize();
        SalesLineDiscount.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 5 Sales Line Discounts, where inconsistent Customer, Item, Item Variant, Unit of measure, Currency.
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(ItemVar);
        LibraryInventory.CreateItemVariant(ItemVariant, ItemVar."No.");
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, ItemVar."No.", UnitofMeasure.Code, 3);
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, "Sales Line Discount Type"::Item, ItemVar."No.", "Sales Price Type"::Customer.AsInteger(), Customer."No.",
            Today(), '', '', '', 1);
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, "Sales Line Discount Type"::Item, Item."No.", "Sales Price Type"::"All Customers".AsInteger(), '',
            Today(), '', '', '', 2);
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, "Sales Line Discount Type"::Item, ItemVar."No.", "Sales Price Type"::"All Customers".AsInteger(), '',
            Today(), '', ItemVariant.Code, '', 3);
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, "Sales Line Discount Type"::Item, ItemVar."No.", "Sales Price Type"::"All Customers".AsInteger(), '',
            Today(), '', '', UnitofMeasure.Code, 4);
        LibraryERM.CreateLineDiscForCustomer(
            SalesLineDiscount, "Sales Line Discount Type"::Item, ItemVar."No.", "Sales Price Type"::"All Customers".AsInteger(), '',
            Today(), Currency.Code, '', '', 5);

        // [GIVEN] Customer, Item, Variant, Unit of measure, Currency are removed
        Customer.Delete();
        Item.Delete();
        ItemVariant.Delete();
        ItemUnitofMeasure.Delete();
        Currency.Delete();

        // [WHEN] Copy SalesPrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // [THEN] Price List Line is not created
        Assert.IsFalse(PriceListLine.FindFirst(), 'line is created');
        Assert.IsFalse(PriceListHeader.Get(PriceListLine."Price List Code"), 'header is created');
    end;

    [Test]
    procedure T011_CopyPurchPriceToSeparateHeaders()
    var
        Currency: Record Currency;
        Item: Record Item;
        Vendor: Record Vendor;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        PriceListCode: Code[20];
    begin
        Initialize();
        PurchasePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Purchase Prices, for Vendor 'V', Item, with/without Currency.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateCurrency(Currency);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), Currency.Code, '', Item."Base Unit of Measure", 5);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), '', '', Item."Base Unit of Measure", 10);

        // [WHEN] Copy PurchasePrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with/without "Currency Code"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        PriceListLine.Next();
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T012_CopyPurchPriceToSameHeader()
    var
        Currency: Record Currency;
        Item: Record Item;
        Vendor: Record Vendor;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        PriceListCode: Code[20];
    begin
        Initialize();
        PurchasePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 2 Purchase Prices, for Vendor 'V', different Items, same Currency.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateCurrency(Currency);
        LibraryInventory.CreateItem(Item);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), Currency.Code, '', Item."Base Unit of Measure", 5);
        LibraryInventory.CreateItem(Item);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), Currency.Code, '', Item."Base Unit of Measure", 5);

        // [WHEN] Copy PurchasePrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);

        // [THEN] Added 2 Price List Lines to one Header with "Currency Code"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        PriceListLine.Next();
        Assert.AreEqual(PriceListCode, PriceListLine."Price List Code", 'different price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T013_CopyPurchPriceDiscoutToSeparateHeaders()
    var
        Currency: Record Currency;
        Vendor: Record Vendor;
        Item: Record Item;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PriceListCode: Code[20];
    begin
        Initialize();
        PurchasePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] Purchase Price and Discount, for Vendor 'V', Item
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateCurrency(Currency);
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, Vendor."No.", Item."No.", Today(), Currency.Code, '', Item."Base Unit of Measure", 5);
        LibraryERM.CreateLineDiscForVendor(
            PurchaseLineDiscount, Item."No.", Vendor."No.", Today(), '', '', Item."Base Unit of Measure", 10);

        // [WHEN] Copy PurchasePrices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with Amount Type "Price" and "Discount"
        PriceListLine.FindFirst();
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        Assert.AreNotEqual(PriceListCode, PriceListLine."Price List Code", 'Same price list code');
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T015_CopyPurchPriceWithInconsistentData()
    var
        Vendor: Record Vendor;
        VendorToDelete: Record Vendor;
        Currency: Record Currency;
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVar: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        UnitofMeasure: Record "Unit of Measure";
    begin
        Initialize();
        PurchasePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 5 Purchase Prices, where inconsistent Vendor, Item, Item Variant, Unit of measure, Currency.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendor(VendorToDelete);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(ItemVar);
        LibraryInventory.CreateItemVariant(ItemVariant, ItemVar."No.");
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, ItemVar."No.", UnitofMeasure.Code, 3);
        LibraryERM.CreateCurrency(Currency);
        LibraryCosting.CreatePurchasePrice(PurchasePrice, VendorToDelete."No.", ItemVar."No.", Today(), '', '', '', 1);
        LibraryCosting.CreatePurchasePrice(PurchasePrice, Vendor."No.", Item."No.", Today(), '', '', '', 2);
        LibraryCosting.CreatePurchasePrice(PurchasePrice, Vendor."No.", ItemVar."No.", Today(), '', ItemVariant.Code, '', 3);
        LibraryCosting.CreatePurchasePrice(PurchasePrice, Vendor."No.", ItemVar."No.", Today(), '', '', UnitofMeasure.Code, 4);
        LibraryCosting.CreatePurchasePrice(PurchasePrice, Vendor."No.", ItemVar."No.", Today(), Currency.Code, '', '', 5);

        // [GIVEN] Vendor, Item, Variant, Unit of measure, Currency are removed
        VendorToDelete.Delete();
        Item.Delete();
        ItemVariant.Delete();
        ItemUnitofMeasure.Delete();
        Currency.Delete();

        // [WHEN] Copy Purchase Prices with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(PurchasePrice, PriceListLine);

        // [THEN] Price List Line is not created
        Assert.IsFalse(PriceListLine.FindFirst(), 'line is created');
        Assert.IsFalse(PriceListHeader.Get(PriceListLine."Price List Code"), 'header is created');
    end;

    [Test]
    procedure T016_CopyPurchLineDiscWithInconsistentData()
    var
        Vendor: Record Vendor;
        VendorToDelete: Record Vendor;
        Currency: Record Currency;
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVar: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        UnitofMeasure: Record "Unit of Measure";
    begin
        Initialize();
        PurchaseLineDiscount.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] 5 Purchase Line Discounts, where inconsistent Vendor, Item, Item Variant, Unit of measure, Currency.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendor(VendorToDelete);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(ItemVar);
        LibraryInventory.CreateItemVariant(ItemVariant, ItemVar."No.");
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitofMeasure, ItemVar."No.", UnitofMeasure.Code, 3);
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateLineDiscForVendor(
            PurchaseLineDiscount, ItemVar."No.", VendorToDelete."No.", Today(), '', '', '', 1);
        LibraryERM.CreateLineDiscForVendor(
            PurchaseLineDiscount, Item."No.", Vendor."No.", Today(), '', '', '', 2);
        LibraryERM.CreateLineDiscForVendor(
            PurchaseLineDiscount, ItemVar."No.", Vendor."No.", Today(), '', ItemVariant.Code, '', 3);
        LibraryERM.CreateLineDiscForVendor(
            PurchaseLineDiscount, ItemVar."No.", Vendor."No.", Today(), '', '', UnitofMeasure.Code, 4);
        LibraryERM.CreateLineDiscForVendor(
            PurchaseLineDiscount, ItemVar."No.", Vendor."No.", Today(), Currency.Code, '', '', 5);

        // [GIVEN] Vendor, Item, Variant, Unit of measure, Currency are removed
        VendorToDelete.Delete();
        Item.Delete();
        ItemVariant.Delete();
        ItemUnitofMeasure.Delete();
        Currency.Delete();

        // [WHEN] Copy Purchase Line Discount with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(PurchaseLineDiscount, PriceListLine);

        // [THEN] Price List Line is not created
        Assert.IsFalse(PriceListLine.FindFirst(), 'line is created');
        Assert.IsFalse(PriceListHeader.Get(PriceListLine."Price List Code"), 'header is created');
    end;

    [Test]
    procedure T020_CopyJobItemPriceToNone()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where both "Apply Job Price" and "Apply Job Discount" are false.
        CreateJobItemPrice(JobItemPrice, false, false);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] None price list lines added.
        Assert.RecordIsEmpty(PriceListHeader);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    [Test]
    procedure T021_CopyJobItemPriceToOnePriceLine()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where "Apply Job Price" is true, "Apply Job Discount" is false.
        CreateJobItemPrice(JobItemPrice, true, false);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] One price list line added, where Amount Type is 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobItemPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobItemPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T022_CopyJobItemPriceToOneDiscountLine()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where "Apply Job Price" is false, "Apply Job Discount" is true.
        CreateJobItemPrice(JobItemPrice, false, true);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] One price list line added, where Amount Type is  'Discount'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", JobItemPrice."Line Discount %");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T023_CopyJobItemPriceToTwoHeaders()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where "Apply Job Price" is true, "Apply Job Discount" is true.
        CreateJobItemPrice(JobItemPrice, true, true);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with Amount Type "Price" and "Discount"
        PriceListLine.FindFirst();
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobItemPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobItemPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", JobItemPrice."Line Discount %");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T024_CopyJobItemPriceZeroDiscToTwoHeaders()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where "Apply Job Price" is true, "Apply Job Discount" is true, "Line Discount %" is 0.
        CreateJobItemPrice(JobItemPrice, true, true);
        JobItemPrice."Line Discount %" := 0;
        JobItemPrice.Modify();

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with Amount Type "Price" and "Discount"
        PriceListLine.FindFirst();
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobItemPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobItemPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] The discount line, where "Line Discount %" is 0
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T025_CopyJobItemPriceZeroPriceToTwoHeaders()
    var
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where "Apply Job Price" is true, "Apply Job Discount" is true, "Unit Price" is 0.
        CreateJobItemPrice(JobItemPrice, true, true);
        JobItemPrice."Unit Price" := 0;
        JobItemPrice."Unit Cost Factor" := 0;
        JobItemPrice.Modify();

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] Added 2 Price List Lines and 2 Headers with Amount Type "Price" and "Discount"
        // [THEN] The price line, where "Unit Price" is 0
        PriceListLine.FindFirst();
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", JobItemPrice."Line Discount %");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T026_CopyJobItemPriceInconsistentData()
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobItemPrice: Record "Job Item Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();

        // [GIVEN] 1 JobItemPrice, without "Item No."
        CreateJobItemPrice(JobItemPrice, true, true);
        JobItemPrice.Rename(JobItemPrice."Job No.", JobItemPrice."Job Task No.", '', JobItemPrice."Variant Code", JobItemPrice."Unit of Measure Code", JobItemPrice."Currency Code");

        // [GIVEN] 6 JobItemPrices, where "Apply Job Price" is true, "Apply Job Discount" is true.
        CreateJobItemPrice(JobItemPrice, true, true);
        Job.Get(JobItemPrice."Job No.");
        CreateJobItemPrice(JobItemPrice, true, true);
        JobTask.Get(JobItemPrice."Job No.", JobItemPrice."Job Task No.");
        CreateJobItemPrice(JobItemPrice, true, true);
        Item.Get(JobItemPrice."Item No.");
        CreateJobItemPrice(JobItemPrice, true, true);
        ItemVariant.Get(JobItemPrice."Item No.", JobItemPrice."Variant Code");
        CreateJobItemPrice(JobItemPrice, true, true);
        ItemUnitofMeasure.Get(JobItemPrice."Item No.", JobItemPrice."Unit of Measure Code");
        CreateJobItemPrice(JobItemPrice, true, true);
        Currency.Get(JobItemPrice."Currency Code");

        // [GIVEN] Job, JobTask, Item, Variant, UoM, Currency are deleted
        Job.Delete();
        JobTask.Delete();
        Item.Delete();
        ItemVariant.Delete();
        ItemUnitofMeasure.Delete();
        Currency.Delete();

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobItemPrice, PriceListLine);

        // [THEN] Added zero Price List Header/Line
        Assert.RecordIsEmpty(PriceListHeader);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    [Test]
    procedure T030_CopyJobGLAccPriceToTwoHeaders()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobGLAccountPrice, where Price, Cost and Discount are set
        CreateJobGLAccPrice(
            JobGLAccountPrice, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(50, 2), LibraryRandom.RandDec(100, 2));

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Added 1st Price List Header, where "Price Type" 'Sale', "Amount Type" 'Any'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Any);
        PriceListLine.TestField("Unit Price", JobGLAccountPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobGLAccountPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", JobGLAccountPrice."Line Discount %");
        PriceListLine.TestField("Unit Cost", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] Added 2nd Price List Header, where "Price Type" 'Purchase', "Amount Type" 'Price'
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", 0);
        PriceListLine.TestField("Unit Cost", JobGLAccountPrice."Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T031_CopyJobGLAccPriceToSalesHeader()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where Price and Discount are set
        CreateJobGLAccPrice(JobGLAccountPrice, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(50, 2), 0);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Any'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Any);
        PriceListLine.TestField("Unit Price", JobGLAccountPrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobGLAccountPrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", JobGLAccountPrice."Line Discount %");
        PriceListLine.TestField("Unit Cost", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T032_CopyJobGLAccPriceToPurchHeader()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where Cost is set
        CreateJobGLAccPrice(JobGLAccountPrice, 0, 0, LibraryRandom.RandDec(100, 2));

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Added 2nd Price List Header, where "Price Type" 'Purchase', "Amount Type" 'Price'
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", 0);
        PriceListLine.TestField("Unit Cost", JobGLAccountPrice."Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T033_CopyJobGLAccPriceDiscToSalesHeader()
    var
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobItemPrice, where Discount is set
        CreateJobGLAccPrice(JobGLAccountPrice, 0, LibraryRandom.RandDec(50, 2), 0);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Discount'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListLine.TestField("Line Discount %", JobGLAccountPrice."Line Discount %");
        PriceListLine.TestField("Unit Cost", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T035_CopyJobGLAccPriceInconsistentData()
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
        Job: Record Job;
        JobTask: Record "Job Task";
        JobGLAccountPrice: Record "Job G/L Account Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        JobGLAccountPrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();

        // [GIVEN] 1 JobItemPrice, without "G/L Account No."
        CreateJobGLAccPrice(JobGLAccountPrice, 1, LibraryRandom.RandDec(50, 2), 0);
        JobGLAccountPrice.Rename(JobGLAccountPrice."Job No.", JobGLAccountPrice."Job Task No.", '', JobGLAccountPrice."Currency Code");

        // [GIVEN] 4 JobItemPrices, where Discount is set
        CreateJobGLAccPrice(JobGLAccountPrice, 1, LibraryRandom.RandDec(50, 2), 0);
        Job.Get(JobGLAccountPrice."Job No.");
        JobGLAccountPrice.Rename(
            JobGLAccountPrice."Job No.", '', JobGLAccountPrice."G/L Account No.", JobGLAccountPrice."Currency Code");
        CreateJobGLAccPrice(JobGLAccountPrice, 2, LibraryRandom.RandDec(50, 2), 0);
        JobTask.Get(JobGLAccountPrice."Job No.", JobGLAccountPrice."Job Task No.");
        CreateJobGLAccPrice(JobGLAccountPrice, 3, LibraryRandom.RandDec(50, 2), 0);
        GLAccount.Get(JobGLAccountPrice."G/L Account No.");
        CreateJobGLAccPrice(JobGLAccountPrice, 4, LibraryRandom.RandDec(50, 2), 0);
        LibraryERM.CreateCurrency(Currency);
        JobGLAccountPrice.Rename(
            JobGLAccountPrice."Job No.", JobGLAccountPrice."Job Task No.",
            JobGLAccountPrice."G/L Account No.", Currency.Code);

        // [GIVEN] Job, JobTask, G/L Account, Currency are deleted
        Job.Delete();
        JobTask.Delete();
        Currency.Delete();
        GLAccount.Delete();

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobGLAccountPrice, PriceListLine);

        // [THEN] Price List Line is not created
        Assert.IsFalse(PriceListLine.FindFirst(), 'line is created');
        Assert.IsFalse(PriceListHeader.Get(PriceListLine."Price List Code"), 'header is created');
    end;

    [Test]
    procedure T040_CopyJobResourcePriceToTwoHeaders()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is true, "Apply Job Discount" is true.
        CreateJobResourcePrice(JobResourcePrice, true, true);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added 1st Price List Header, where "Price Type" 'Sale', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobResourcePrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobResourcePrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] Added 2nd Price List Header, where "Price Type" 'Sale', "Amount Type" 'Discount'
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Line Discount %", JobResourcePrice."Line Discount %");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T041_CopyJobResourcePriceToPriceHeader()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is true, "Apply Job Discount" is false.
        CreateJobResourcePrice(JobResourcePrice, true, false);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobResourcePrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobResourcePrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T042_CopyJobResourcePriceToDiscHeaders()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is false, "Apply Job Discount" is true.
        CreateJobResourcePrice(JobResourcePrice, false, true);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Amount Type" 'Discount'
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Line Discount %", JobResourcePrice."Line Discount %");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T043_CopyJobResourcePriceToNone()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is false, "Apply Job Discount" is false.
        CreateJobResourcePrice(JobResourcePrice, false, false);

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added zero Price List Header/Line
        Assert.RecordIsEmpty(PriceListHeader);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    [Test]
    procedure T044_CopyJobResourcePriceZeroDiscToTwoHeaders()
    var
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        // [SCENARIO] Copy even zero discount to a new discount line.
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] JobResourcePrice, where "Apply Job Price" is true, "Apply Job Discount" is true, "Line Discount %" is 0
        CreateJobResourcePrice(JobResourcePrice, true, true);
        JobResourcePrice."Line Discount %" := 0;
        JobResourcePrice.Modify();

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added 1st Price List Header, where "Price Type" 'Sale', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", JobResourcePrice."Unit Price");
        PriceListLine.TestField("Cost Factor", JobResourcePrice."Unit Cost Factor");
        PriceListLine.TestField("Line Discount %", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] Added 2nd Price List Header, where "Price Type" 'Sale', "Amount Type" 'Discount', "Line Discount %" is 0
        Assert.IsTrue(PriceListLine.Next() <> 0, 'not found second line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Discount);
        PriceListLine.TestField("Line Discount %", 0);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Cost Factor", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
    end;

    [Test]
    procedure T045_CopyJobResourcePriceInconsistentData()
    var
        Currency: Record Currency;
        Resource: Record Resource;
        Job: Record Job;
        JobTask: Record "Job Task";
        WorkType: Record "Work Type";
        JobResourcePrice: Record "Job Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        JobResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();

        // [GIVEN] 1 JobResourcePrice, without "Resource Code"
        CreateJobResourcePrice(JobResourcePrice, true, true);
        JobResourcePrice.Rename(JobResourcePrice."Job No.", JobResourcePrice."Job Task No.", JobResourcePrice.Type, '', JobResourcePrice."Work Type Code", JobResourcePrice."Currency Code");

        // [GIVEN] 5 JobResourcePrices, where "Apply Job Price" is true, "Apply Job Discount" is true.
        CreateJobResourcePrice(JobResourcePrice, true, true);
        Job.Get(JobResourcePrice."Job No.");
        CreateJobResourcePrice(JobResourcePrice, true, true);
        JobTask.Get(JobResourcePrice."Job No.", JobResourcePrice."Job Task No.");
        CreateJobResourcePrice(JobResourcePrice, true, true);
        Resource.Get(JobResourcePrice."Code");
        CreateJobResourcePrice(JobResourcePrice, true, true);
        WorkType.Get(JobResourcePrice."Work Type Code");
        CreateJobResourcePrice(JobResourcePrice, true, true);
        LibraryERM.CreateCurrency(Currency);
        JobResourcePrice.Rename(
            JobResourcePrice."Job No.", JobResourcePrice."Job Task No.", JobResourcePrice.Type,
            JobResourcePrice."Code", JobResourcePrice."Work Type Code", Currency.Code);

        // [GIVEN] Job, JobTask, Resource, Work type, Currency are deleted
        Job.Delete();
        JobTask.Delete();
        Currency.Delete();
        Resource.Delete();
        WorkType.Delete();

        // [WHEN] Copy JobItemPrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(JobResourcePrice, PriceListLine);

        // [THEN] Added zero Price List Header/Line
        Assert.RecordIsEmpty(PriceListHeader);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    [Test]
    procedure T050_CopyResourcePriceToPriceHeader()
    var
        ResourcePrice: Record "Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        ResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] ResourcePrice
        CreateResourcePrice(ResourcePrice);

        // [WHEN] Copy ResourcePrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourcePrice, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Sale', "Source Type" 'All Customers', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Sale);
        PriceListLine.TestField("Source Group", "Price Source Group"::Customer);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Customers");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", ResourcePrice."Unit Price");
        PriceListLine.TestField("Unit Cost", 0);
        PriceListLine.TestField("Direct Unit Cost", 0);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T055_CopyResourcePriceInconsistentData()
    var
        Currency: Record Currency;
        Resource: Record Resource;
        WorkType: Record "Work Type";
        ResourcePrice: Record "Resource Price";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        Initialize();
        ResourcePrice.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();

        // [GIVEN] 1 ResourcePrice, without "Resource Code"
        CreateResourcePrice(ResourcePrice);
        ResourcePrice.Rename(ResourcePrice.Type, '', ResourcePrice."Work Type Code", ResourcePrice."Currency Code");

        // [GIVEN] 3 ResourcePrice
        CreateResourcePrice(ResourcePrice);
        Resource.Get(ResourcePrice.Code);
        CreateResourcePrice(ResourcePrice);
        WorkType.get(ResourcePrice."Work Type Code");
        CreateResourcePrice(ResourcePrice);
        LibraryERM.CreateCurrency(Currency);
        ResourcePrice.Rename(ResourcePrice.Type, ResourcePrice."Code", ResourcePrice."Work Type Code", Currency.Code);

        // [GIVEN] Resource, Work type, Currency are deleted
        Currency.Delete();
        Resource.Delete();
        WorkType.Delete();

        // [WHEN] Copy ResourcePrice with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourcePrice, PriceListLine);

        // [THEN] Added zero Price List Header/Line
        Assert.RecordIsEmpty(PriceListHeader);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    [Test]
    procedure T060_CopyResourceCostToPriceHeader()
    var
        Resource: Record Resource;
        ResourceCost: Record "Resource Cost";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        ResourceCost.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] ResourceCost
        LibraryResource.CreateResource(Resource, '');
        CreateResourceCost(ResourceCost, ResType::Resource, Resource."No.");

        // [WHEN] Copy ResourceCost with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourceCost, PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Purchase', "Source Type" 'All Vendors', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", ResourceCost."Unit Cost");
        PriceListLine.TestField("Direct Unit Cost", ResourceCost."Direct Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T061_CopyResourceCostPctExtraResourceToPriceHeader()
    var
        Resource: Record Resource;
        ResourceCost: array[2] of Record "Resource Cost";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        Resource.DeleteAll();
        ResourceCost[1].DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] ResourceCost for Resource 'A', where "Work Type Code" is 'WT', "Cost Type" is '% Extra', "Unit Cost" is 50, "Direct Unit Cost" is 20.
        LibraryResource.CreateResource(Resource, '');
        CreateResourceCost(ResourceCost[2], ResType::Resource, Resource."No.");
        ResourceCost[1] := ResourceCost[2];
        ResourceCost[2]."Cost Type" := ResourceCost[2]."Cost Type"::"% Extra";
        ResourceCost[2]."Unit Cost" := 50;
        ResourceCost[2]."Direct Unit Cost" := 20;
        ResourceCost[2].Modify();
        // [GIVEN] ResourceCost for Resource 'A', where "Work Type Code" is <blank>, "Cost Type" is 'Fixed', "Unit Cost" is 100, "Direct Unit Cost" is 80.
        ResourceCost[1]."Work Type Code" := '';
        ResourceCost[1].Insert();

        // [WHEN] Copy ResourceCosts with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourceCost[1], PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Purchase', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", '');
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.TestField("Asset No.", ResourceCost[1].Code);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", ResourceCost[1]."Unit Cost");
        PriceListLine.TestField("Direct Unit Cost", ResourceCost[1]."Direct Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] 2nd Line, where "Work Type Code" is 'WT', "Unit Cost" is 150 (+50%), "Direct Unit Cost" is 96 (+20%)
        Assert.IsFalse(PriceListLine.Next() = 0, 'not found second line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", ResourceCost[2]."Work Type Code");
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.TestField("Asset No.", ResourceCost[1].Code);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", ResourceCost[1]."Unit Cost" * (100 + ResourceCost[2]."Unit Cost") / 100);
        PriceListLine.TestField("Direct Unit Cost", ResourceCost[1]."Direct Unit Cost" * (100 + ResourceCost[2]."Direct Unit Cost") / 100);
    end;

    [Test]
    procedure T062_CopyResourceCostLCYExtraResourceGroupToPriceHeader()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResourceCost: array[2] of Record "Resource Cost";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        ResourceGroup.DeleteAll();
        ResourceCost[1].DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Unit Cost" is 110, "Direct Unit Cost" is 90.
        CreateResourceGroup(Resource, ResourceGroup);
        Resource."Unit Cost" := LibraryRandom.RandDec(200, 2);
        Resource."Direct Unit Cost" := LibraryRandom.RandDec(200, 2);
        Resource.Modify();
        // [GIVEN] ResourceCost for Resource Group 'A', where "Work Type Code" is 'WT', "Cost Type" is 'LCY Extra', "Unit Cost" is 50, "Direct Unit Cost" is 20.
        CreateResourceCost(ResourceCost[2], ResType::"Group(Resource)", ResourceGroup."No.");
        ResourceCost[1] := ResourceCost[2];
        ResourceCost[2]."Cost Type" := ResourceCost[2]."Cost Type"::"LCY Extra";
        ResourceCost[2]."Unit Cost" := 50;
        ResourceCost[2]."Direct Unit Cost" := 20;
        ResourceCost[2].Modify();
        // [GIVEN] ResourceCost for Resource Group 'A', where "Work Type Code" is <blank>, "Cost Type" is 'Fixed', "Unit Cost" is 100, "Direct Unit Cost" is 80.
        ResourceCost[1]."Work Type Code" := '';
        ResourceCost[1].Insert();

        // [WHEN] Copy ResourceCosts with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourceCost[1], PriceListLine);

        // [THEN] Added one Price List Header, where "Price Type" 'Purchase', "Amount Type" 'Price'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", '');
        PriceListLine.TestField("Asset Type", "Price Asset Type"::"Resource Group");
        PriceListLine.TestField("Asset No.", ResourceCost[1].Code);
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", ResourceCost[1]."Unit Cost");
        PriceListLine.TestField("Direct Unit Cost", ResourceCost[1]."Direct Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] 2nd Line, where "Asset Type" is 'Resource', "Work Type Code" is 'WT', "Unit Cost" is 150 (100+50), "Direct Unit Cost" is 100 (80+20)
        Assert.IsFalse(PriceListLine.Next() = 0, 'not found second line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", ResourceCost[2]."Work Type Code");
        PriceListLine.TestField("Asset Type", "Price Asset Type"::"Resource");
        PriceListLine.TestField("Asset No.", Resource."No.");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", ResourceCost[1]."Unit Cost" + ResourceCost[2]."Unit Cost");
        PriceListLine.TestField("Direct Unit Cost", ResourceCost[1]."Direct Unit Cost" + ResourceCost[2]."Direct Unit Cost");

        Assert.IsTrue(PriceListLine.Next() = 0, 'found 3rd line');
    end;

    [Test]
    procedure T063_CopyResourceCostPctExtraResourceGroupToPriceHeader()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResourceCost: Record "Resource Cost";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        // [SCEANRIO] Resource Group cost adjusts the costs set in the Resource card, if no ResourceCost for the Resource.
        Initialize();
        ResourceGroup.DeleteAll();
        ResourceCost.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Unit Cost" is 100, "Direct Unit Cost" is 80.
        CreateResourceGroup(Resource, ResourceGroup);
        Resource."Unit Cost" := LibraryRandom.RandDec(200, 2);
        Resource."Direct Unit Cost" := LibraryRandom.RandDec(200, 2);
        Resource.Modify();
        // [GIVEN] ResourceCost for Resource Group 'A', where "Work Type Code" is 'WT', "Cost Type" is '% Extra', "Unit Cost" is 25, "Direct Unit Cost" is 20.
        CreateResourceCost(ResourceCost, ResType::"Group(Resource)", ResourceGroup."No.");
        ResourceCost."Cost Type" := ResourceCost."Cost Type"::"% Extra";
        ResourceCost."Unit Cost" := 25;
        ResourceCost."Direct Unit Cost" := 20;
        ResourceCost.Modify();

        // [WHEN] Copy ResourceCost with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourceCost, PriceListLine);

        // [THEN] Added one Price List Line, "Asset Type" is 'Resource', "Work Type Code" is 'WT', "Unit Cost" is 125 (100+25%), "Direct Unit Cost" is 96 (80+20%)
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", ResourceCost."Work Type Code");
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.TestField("Asset No.", Resource."No.");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", Resource."Unit Cost" * (100 + ResourceCost."Unit Cost") / 100);
        PriceListLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost" * (100 + ResourceCost."Direct Unit Cost") / 100);
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);

        Assert.IsTrue(PriceListLine.Next() = 0, 'found 2nd line');
    end;

    [Test]
    procedure T064_CopyResourceCostPctExtraAllToPriceHeader()
    var
        Resource: array[2] of Record Resource;
        ResourceCost: array[3] of Record "Resource Cost";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        Initialize();
        Resource[1].DeleteAll();
        ResourceCost[1].DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] Two resources 'A' and 'B'
        LibraryResource.CreateResource(Resource[1], '');
        LibraryResource.CreateResource(Resource[2], '');
        // [GIVEN] ResourceCost for Resource 'A', where "Work Type Code" is 'WT'.
        CreateResourceCost(ResourceCost[1], ResType::Resource, Resource[1]."No.");
        // [GIVEN] ResourceCost for Resource 'B', where "Work Type Code" is <blank>.
        ResourceCost[2] := ResourceCost[1];
        ResourceCost[2].Code := Resource[2]."No.";
        ResourceCost[2]."Work Type Code" := '';
        ResourceCost[2].Insert();

        // [GIVEN] ResourceCost for 'All', where "Work Type Code" is 'WT', "Cost Type" is '% Extra', "Unit Cost" is 50, "Direct Unit Cost" is 20
        ResourceCost[3] := ResourceCost[1];
        ResourceCost[3].Type := ResourceCost[3].Type::All;
        ResourceCost[3].Code := '';
        ResourceCost[3]."Cost Type" := ResourceCost[2]."Cost Type"::"% Extra";
        ResourceCost[3]."Unit Cost" := 50;
        ResourceCost[3]."Direct Unit Cost" := 20;
        ResourceCost[3].Insert();

        // [WHEN] Copy ResourceCosts with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourceCost[1], PriceListLine);

        // [THEN] Tree Price List Liens added:
        // [THEN] 1st line, where "Resource" is 'A', "Work Type Code" is 'WT'
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", ResourceCost[1]."Work Type Code");
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.TestField("Asset No.", Resource[1]."No.");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", ResourceCost[1]."Unit Cost");
        PriceListLine.TestField("Direct Unit Cost", ResourceCost[1]."Direct Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        // [THEN] 2nd Line, where "Resource" is 'B', "Work Type Code" is <blank>, "Unit Cost" is 100, "Direct Unit Cost" is 80
        Assert.IsFalse(PriceListLine.Next() = 0, 'not found second line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", '');
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.TestField("Asset No.", Resource[2]."No.");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", ResourceCost[2]."Unit Cost");
        PriceListLine.TestField("Direct Unit Cost", ResourceCost[2]."Direct Unit Cost");

        // [THEN] 3rd Line, where "Resource" is 'B', "Work Type Code" is 'WT', "Unit Cost" is 150 (+50%), "Direct Unit Cost" is 96 (+20%)
        Assert.IsFalse(PriceListLine.Next() = 0, 'not found 3rd line');
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", ResourceCost[3]."Work Type Code");
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.TestField("Asset No.", Resource[2]."No.");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", ResourceCost[2]."Unit Cost" * (100 + ResourceCost[3]."Unit Cost") / 100);
        PriceListLine.TestField("Direct Unit Cost", ResourceCost[2]."Direct Unit Cost" * (100 + ResourceCost[3]."Direct Unit Cost") / 100);

        Assert.IsTrue(PriceListLine.Next() = 0, 'found 4th line');
    end;

    [Test]
    procedure T065_CopyResourceCostLCYExtraResourceGroupAndAll()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        ResourceCost: array[2] of Record "Resource Cost";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        PriceListCode: Code[20];
    begin
        // [SCENARIO] Price List line for 'All' is not created if one is created for the Group with same Work Type.
        Initialize();
        Resource.DeleteAll();
        ResourceCost[1].DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();
        // [GIVEN] Resource 'X', where "Resource Group No." is 'A', "Unit Cost" is 100, "Direct Unit Cost" is 80.
        CreateResourceGroup(Resource, ResourceGroup);
        Resource."Unit Cost" := LibraryRandom.RandDec(200, 2);
        Resource."Direct Unit Cost" := LibraryRandom.RandDec(200, 2);
        Resource.Modify();
        // [GIVEN] ResourceCost for Resource Group 'A', where "Work Type Code" is 'WT', "Cost Type" is 'LCY Extra', "Unit Cost" is 50, "Direct Unit Cost" is 20.
        CreateResourceCost(ResourceCost[1], ResType::"Group(Resource)", ResourceGroup."No.");
        ResourceCost[1]."Cost Type" := ResourceCost[2]."Cost Type"::"LCY Extra";
        ResourceCost[1]."Unit Cost" := 50;
        ResourceCost[1]."Direct Unit Cost" := 20;
        ResourceCost[1].Modify();
        // [GIVEN] ResourceCost for 'All', where "Work Type Code" is 'WT', "Cost Type" is 'LCY Extra', "Unit Cost" is 55, "Direct Unit Cost" is 25.
        ResourceCost[2] := ResourceCost[1];
        ResourceCost[2].Type := ResourceCost[2].Type::All;
        ResourceCost[2].Code := '';
        ResourceCost[2]."Unit Cost" := 55;
        ResourceCost[2]."Direct Unit Cost" := 25;
        ResourceCost[2].Insert();

        // [WHEN] Copy ResourceCosts with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourceCost[1], PriceListLine);

        // [THEN] Added one Price List Lines, where "Price Type" 'Purchase', "Amount Type" 'Price', "Work Type Code" is 'WT',
        // [THEN] "Asset Type" is 'Resource', "Asset No." is 'X', "Unit Cost" is 150 (100 + 50), "Direct Unit Cost" is 100 (80 + 20)
        PriceListLine.FindFirst();
        PriceListLine.TestField("Price Type", PriceListLine."Price Type"::Purchase);
        PriceListLine.TestField("Source Group", "Price Source Group"::Vendor);
        PriceListLine.TestField("Source Type", "Price Source Type"::"All Vendors");
        PriceListLine.TestField("Amount Type", "Price Amount Type"::Price);
        PriceListLine.TestField("Work Type Code", ResourceCost[1]."Work Type Code");
        PriceListLine.TestField("Asset Type", "Price Asset Type"::Resource);
        PriceListLine.TestField("Asset No.", Resource."No.");
        PriceListLine.TestField("Unit Price", 0);
        PriceListLine.TestField("Unit Cost", Resource."Unit Cost" + ResourceCost[1]."Unit Cost");
        PriceListLine.TestField("Direct Unit Cost", Resource."Direct Unit Cost" + ResourceCost[1]."Direct Unit Cost");
        PriceListCode := PriceListLine."Price List Code";
        VerifyHeader(PriceListLine);
        Assert.IsTrue(PriceListLine.Next() = 0, 'found second line');
    end;

    [Test]
    procedure T066_CopyResourceCostInconsistentData()
    var
        WorkType: array[2] of Record "Work Type";
        Resource: array[2] of Record Resource;
        ResourceGroup: array[2] of Record "Resource Group";
        ResourceCost: Record "Resource Cost";
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
    begin
        // [SCEANRIO] Resource cost containing inconsitent data (Resource, Work Type) is not copied to price list line
        Initialize();
        ResourceGroup[1].DeleteAll();
        ResourceCost.DeleteAll();
        PriceListLine.DeleteAll();
        PriceListHeader.DeleteAll();

        // [GIVEN] Resource 'X', where "Resource Group No." is 'A'
        CreateResourceGroup(Resource[1], ResourceGroup[1]);
        Resource[1]."Unit Cost" := LibraryRandom.RandDec(200, 2);
        Resource[1]."Direct Unit Cost" := LibraryRandom.RandDec(200, 2);
        Resource[1].Modify();
        CreateResourceGroup(Resource[2], ResourceGroup[2]);

        // [GIVEN] 1 ResourceCost, without "Resource Code"
        CreateResourceCost(ResourceCost, ResType::Resource, Resource[2]."No.");
        ResourceCost.Rename(ResourceCost.Type, '', ResourceCost."Work Type Code");

        // [GIVEN] 4 ResourceCost for Resource Group 'A', where "Work Type Code" is 'WT'
        CreateResourceCost(ResourceCost, ResType::"Group(Resource)", ResourceGroup[1]."No.");
        CreateResourceCost(ResourceCost, ResType::"Group(Resource)", ResourceGroup[2]."No.");
        WorkType[1].Get(ResourceCost."Work Type Code");

        CreateResourceCost(ResourceCost, ResType::Resource, Resource[1]."No.");
        ResourceCost."Cost Type" := ResourceCost."Cost Type"::"% Extra";
        ResourceCost.Modify();
        CreateResourceCost(ResourceCost, ResType::Resource, Resource[2]."No.");
        ResourceCost."Cost Type" := ResourceCost."Cost Type"::"% Extra";
        ResourceCost.Modify();
        WorkType[2].Get(ResourceCost."Work Type Code");

        // [GIVEN] Resource Group, Work type are deleted
        Resource[1].Delete();
        ResourceGroup[1].Delete();
        WorkType[1].Delete();
        WorkType[2].Delete();

        // [WHEN] Copy ResourceCost with header generation
        CopyFromToPriceListLine.SetGenerateHeader();
        CopyFromToPriceListLine.CopyFrom(ResourceCost, PriceListLine);

        // [THEN] Added zero Price List Header/Line
        Assert.RecordIsEmpty(PriceListHeader);
        Assert.RecordIsEmpty(PriceListLine);
    end;

    [Test]
    procedure T100_FeatureUpdateIfSalesPriceListNosIsBlank()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        // [FEATURE] [Sales]
        Initialize();
        // [GIVEN] Sales Setup, where "Price List Nos." is blank
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Price List Nos." := '';
        SalesReceivablesSetup.Modify();
        // [GIVEN] Sales Price record exists, Price List Line does not.
        PriceListLine.DeleteAll();
        SalesPrice.DeleteAll();
        LibrarySales.CreateSalesPrice(
            SalesPrice, LibraryInventory.CreateItemNo(),
            "Sales Price Type"::Customer, LibrarySales.CreateCustomerNo(), Today(), '', '', '', 0, 0);
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.FindFirst();

        // [WHEN] Run feature data update
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrice';
        FeatureDataUpdateStatus."Company Name" := CompanyName();
        FeaturePriceCalculation.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Price List Line is created
        PriceListLine.SetRange("Source Type", "Price Source Type"::Customer);
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        Assert.IsTrue(PriceListLine.FindFirst(), 'not found PriceListLine');
        PriceListLine.TestField("Asset No.", SalesPrice."Item No.");
    end;

    [Test]
    procedure T101_FeatureUpdateIfPurchPriceListNosIsBlank()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        // [FEATURE] [Purchase]
        Initialize();
        // [GIVEN] Purchase Setup, where "Price List Nos." is blank
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Price List Nos." := '';
        PurchasesPayablesSetup.Modify();
        // [GIVEN] Purchase Price record exists, Price List Line does not.
        PriceListLine.DeleteAll();
        PurchasePrice.DeleteAll();
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo(), Today(), '', '', '', 2);
        PurchasePrice.FindFirst();

        // [WHEN] Run feature data update
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrice';
        FeatureDataUpdateStatus."Company Name" := CompanyName();
        FeaturePriceCalculation.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Price List Line is created
        PriceListLine.SetRange("Source Type", "Price Source Type"::Vendor);
        Assert.IsTrue(PriceListLine.FindFirst(), 'not found PriceListLine');
        PriceListLine.TestField("Asset No.", PurchasePrice."Item No.");
    end;

    [Test]
    procedure T102_FeatureUpdateIfJobPriceListNosIsBlank()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PriceListLine: Record "Price List Line";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        JobsSetup: Record "Jobs Setup";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        // [FEATURE] [Job]
        Initialize();
        // [GIVEN] Jobs Setup, where "Price List Nos." is blank
        JobsSetup.Get();
        JobsSetup."Price List Nos." := '';
        JobsSetup.Modify();
        // [GIVEN] Job Item Price record exists, Price List Line does not.
        JobGLAccountPrice.DeleteAll();
        JobResourcePrice.DeleteAll();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        CreateJobItemPrice(JobItemPrice, true, false);
        JobItemPrice.FindFirst();

        // [WHEN] Run feature data update
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrice';
        FeatureDataUpdateStatus."Company Name" := CompanyName();
        FeaturePriceCalculation.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Price List Line is created
        PriceListLine.SetRange("Source Type", "Price Source Type"::"Job Task");
        Assert.IsTrue(PriceListLine.FindFirst(), 'not found PriceListLine');
        PriceListLine.TestField("Asset No.", JobItemPrice."Item No.");
    end;

    [Test]
    procedure T105_FeatureUpdateWithDefaultSalesPriceListNo()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PriceListLine: Record "Price List Line";
        SalesPrice: Record "Sales Price";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
        PriceListManagement: Codeunit "Price List Management";
        PriceListCode: Code[20];
    begin
        // [FEATURE] [Sales] [Use Default Price Lists]
        Initialize();
        // [GIVEN] Sales Price record exists, Price List Line does not.
        PriceListLine.DeleteAll();
        SalesPrice.DeleteAll();
        LibrarySales.CreateSalesPrice(
            SalesPrice, LibraryInventory.CreateItemNo(),
            "Sales Price Type"::Customer, LibrarySales.CreateCustomerNo(), Today(), '', '', '', 0, 0);
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.FindFirst();

        // [WHEN] Run feature data update, where "Use Default Price Lists" is 'Yes'
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrice';
        FeatureDataUpdateStatus."Company Name" := CompanyName();
        FeatureDataUpdateStatus."Use Default Price Lists" := true;
        FeaturePriceCalculation.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Price List Line is created, where "Price List Code" is 'Default'.
        PriceListLine.SetRange("Source Type", "Price Source Type"::Customer);
        PriceListLine.SetRange("Asset Type", "Price Asset Type"::Item);
        Assert.IsTrue(PriceListLine.FindFirst(), 'not found PriceListLine');
        PriceListLine.TestField("Asset No.", SalesPrice."Item No.");
        PriceListCode := PriceListManagement.GetDefaultPriceListCode("Price Type"::Sale, "Price Source Group"::Customer, false);
        PriceListLine.TestField("Price List Code", PriceListCode);
    end;

    [Test]
    procedure T106_FeatureUpdateWithDefaultPurchPriceListNo()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PriceListLine: Record "Price List Line";
        PurchasePrice: Record "Purchase Price";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
        PriceListManagement: Codeunit "Price List Management";
        PriceListCode: Code[20];
    begin
        // [FEATURE] [Purchase] [Use Default Price Lists]
        Initialize();
        // [GIVEN] Purchase Price record exists, Price List Line does not.
        PriceListLine.DeleteAll();
        PurchasePrice.DeleteAll();
        LibraryCosting.CreatePurchasePrice(
            PurchasePrice, LibraryPurchase.CreateVendorNo(), LibraryInventory.CreateItemNo(), Today(), '', '', '', 2);
        PurchasePrice.FindFirst();

        // [WHEN] Run feature data update, where "Use Default Price Lists" is 'Yes'
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrice';
        FeatureDataUpdateStatus."Company Name" := CompanyName();
        FeatureDataUpdateStatus."Use Default Price Lists" := true;
        FeaturePriceCalculation.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Price List Line is created, where "Price List Code" is 'Default'.
        PriceListLine.SetRange("Source Type", "Price Source Type"::Vendor);
        Assert.IsTrue(PriceListLine.FindFirst(), 'not found PriceListLine');
        PriceListLine.TestField("Asset No.", PurchasePrice."Item No.");
        PriceListCode := PriceListManagement.GetDefaultPriceListCode("Price Type"::Purchase, "Price Source Group"::Vendor, false);
        PriceListLine.TestField("Price List Code", PriceListCode);
    end;

    [Test]
    procedure T107_FeatureUpdateWithDefaultSalesJobPriceListNo()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PriceListLine: Record "Price List Line";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
        PriceListManagement: Codeunit "Price List Management";
        PriceListCode: Code[20];
    begin
        // [FEATURE] [Job] [Use Default Price Lists]
        Initialize();
        // [GIVEN] Job Item Price record exists, Price List Line does not.
        JobGLAccountPrice.DeleteAll();
        JobResourcePrice.DeleteAll();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        CreateJobItemPrice(JobItemPrice, true, false);
        JobItemPrice.FindFirst();

        // [WHEN] Run feature data update, where "Use Default Price Lists" is 'Yes'
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrice';
        FeatureDataUpdateStatus."Company Name" := CompanyName();
        FeatureDataUpdateStatus."Use Default Price Lists" := true;
        FeaturePriceCalculation.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Price List Line is created, where "Price List Code" is 'Sales Default'.
        PriceListLine.SetRange("Source Type", "Price Source Type"::"Job Task");
        Assert.IsTrue(PriceListLine.FindFirst(), 'not found PriceListLine');
        PriceListLine.TestField("Price Type", "Price Type"::Sale);
        PriceListLine.TestField("Asset No.", JobItemPrice."Item No.");
        PriceListCode := PriceListManagement.GetDefaultPriceListCode("Price Type"::Sale, "Price Source Group"::Job, false);
        PriceListLine.TestField("Price List Code", PriceListCode);
    end;

    [Test]
    procedure T108_FeatureUpdateWithDefaultPurchJobPriceListNo()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        PriceListLine: Record "Price List Line";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
        JobResourcePrice: Record "Job Resource Price";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
        PriceListManagement: Codeunit "Price List Management";
        PriceListCode: Code[20];
    begin
        // [FEATURE] [Job] [Use Default Price Lists]
        Initialize();
        // [GIVEN] Job GlAcc Price record exists, Price List Line does not.
        JobGLAccountPrice.DeleteAll();
        JobResourcePrice.DeleteAll();
        JobItemPrice.DeleteAll();
        PriceListLine.DeleteAll();
        CreateJobGLAccPrice(JobGLAccountPrice, 0, 0, LibraryRandom.RandDec(100, 2));
        JobGLAccountPrice.FindFirst();

        // [WHEN] Run feature data update, where "Use Default Price Lists" is 'Yes'
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrice';
        FeatureDataUpdateStatus."Company Name" := CompanyName();
        FeatureDataUpdateStatus."Use Default Price Lists" := true;
        FeaturePriceCalculation.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Price List Line is created, where "Price List Code" is 'Purch Default'.
        PriceListLine.SetRange("Source Type", "Price Source Type"::"Job Task");
        Assert.IsTrue(PriceListLine.FindFirst(), 'not found PriceListLine');
        PriceListLine.TestField("Asset No.", JobGLAccountPrice."G/L Account No.");
        PriceListLine.TestField("Price Type", "Price Type"::Purchase);
        PriceListCode := PriceListManagement.GetDefaultPriceListCode("Price Type"::Purchase, "Price Source Group"::Job, false);
        PriceListLine.TestField("Price List Code", PriceListCode);
    end;

    [Test]
    procedure T110_TestFeatureKeyMatches()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        FeatureDataUpdateMgt: Codeunit "Feature Data Update Mgt.";
    begin
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrices';
        Assert.IsTrue(FeatureDataUpdateMgt.FeatureKeyMatches(FeatureDataUpdateStatus, Enum::"Feature To Update"::SalesPrices), 'SalesPrices');
    end;

    [Test]
    procedure T111_UseDefaultPriceListsOnPageChangesDescription()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        ScheduleFeatureDataUpdate: Page "Schedule Feature Data Update";
        TestScheduleFeatureDataUpdate: TestPage "Schedule Feature Data Update";
        Description: Text;
    begin
        // [FEATURE] [Use Default Price Lists] [UI]
        // [SCENARIO] Description is changing along with changing "Use Default Price Lists", ('Yes' by default).
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrices';
        ScheduleFeatureDataUpdate.Set(FeatureDataUpdateStatus);
        TestScheduleFeatureDataUpdate.Trap();
        // [WHEN] Open "Schedule Feature Data Update" page for 'SalesPrices'
        ScheduleFeatureDataUpdate.Run();

        // [THEN] "Use Default Price Lists" is 'Yes'
        TestScheduleFeatureDataUpdate."Use Default Price Lists".AssertEquals(true);
        Description := TestScheduleFeatureDataUpdate.SplitDataDescription.Value();
        // [THEN] Description is changing is set "Use Default Price Lists" to 'No'
        TestScheduleFeatureDataUpdate."Use Default Price Lists".SetValue(false);
        Assert.AreNotEqual(Description, TestScheduleFeatureDataUpdate.SplitDataDescription.Value(), 'Description not changed');
    end;

    [Test]
    [HandlerFunctions('DataUpgradeOverviewModalHandler')]
    procedure T200_CountCRMIntegrationRecordsCustPriceGr()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CustomerPriceGroup: Record "Customer Price Group";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        // [FEATURE] [CRM Integration]
        Initialize();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMIntegrationRecord.SetRange("Table ID", Database::"Customer Price Group");
        CRMIntegrationRecord.DeleteAll();

        // [GIVEN] Customer Price Group 'X' coupled to CRM Price List 'X'
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);

        // [WHEN] ReviewData
        Assert.IsTrue(FeaturePriceCalculation.IsDataUpdateRequired(), 'no data to update');
        FeaturePriceCalculation.ReviewData();

        // [THEN] Open page "Data Upgrade Overview", where is line for 1 record of "CRM Integration Record" 
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'count of CRM Int Record'); // from DataUpgradeOverviewModalHandler
    end;

    [Test]
    [HandlerFunctions('DataUpgradeOverviewModalHandler')]
    procedure T201_CountCRMIntegrationRecordsSalesPrice()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductPricelevel: Record "CRM ProductPricelevel";
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPrice: array[2] of Record "Sales Price";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
    begin
        // [SCENARIO] Data update review counts all CRM Integration Records for "Customer Price Group" and "Sales Price" tables
        // [FEATURE] [CRM Integration]
        Initialize();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();

        CRMIntegrationRecord.SetRange("Table ID", Database::"Customer Price Group");
        CRMIntegrationRecord.DeleteAll();

        // [GIVEN] Customer Price Group 'X' coupled to CRM Price List 'X', where one SlaesPrice line is also coupled
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        LibraryCRMIntegration.CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup, SalesPrice[1], CRMProductPricelevel);
        // [GIVEN] Coupled SalesPrice #2, where "Sales Price Type" is "All Customers"
        LibraryCRMIntegration.CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup, SalesPrice[2], CRMProductPricelevel);
        SalesPrice[2].Rename(SalesPrice[2]."Item No.", "Sales Price Type"::"All Customers", '', 0D, '', '', '', 0);

        // [WHEN] ReviewData
        Assert.IsTrue(FeaturePriceCalculation.IsDataUpdateRequired(), 'no data to update');
        FeaturePriceCalculation.ReviewData();

        // [THEN] Open page "Data Upgrade Overview", where is line for 3 records of "CRM Integration Record" 
        Assert.AreEqual(3, LibraryVariableStorage.DequeueInteger(), 'count of CRM Int Record'); // from DataUpgradeOverviewModalHandler
    end;

    [Test]
    procedure T210_TwoPriceHeadersFromOneCustPriceGroup()
    var
        CRMConnectionSetup: Record "CRM Connection Setup";
        CRMIntegrationRecord: Record "CRM Integration Record";
        CRMPricelevel: Record "CRM Pricelevel";
        CRMProductPricelevel: array[2] of Record "CRM ProductPricelevel";
        CustomerPriceGroup: Record "Customer Price Group";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        IntegrationTableMapping: Record "Integration Table Mapping";
        JobQueueEntry: Record "Job Queue Entry";
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[2] of Record "Price List Line";
        SalesPrice: array[2] of Record "Sales Price";
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
        FeaturePriceCalculation: Codeunit "Feature - Price Calculation";
        RecId: RecordId;
        CRMId: Guid;
    begin
        // [FEATURE] [CRM Integration]
        // [SCENARIO] All CRM coupling for 'Customer Price Group' and 'Sales Price' gets removed during datat update.
        Initialize();
        LibraryCRMIntegration.ResetEnvironment();
        LibraryCRMIntegration.ConfigureCRM();
        CRMConnectionSetup.Get();
        CRMSetupDefaults.ResetConfiguration(CRMConnectionSetup);
        // [GIVEN] Customer Price Group 'X' coupled to CRM Price List 'X', with two lines
        LibraryCRMIntegration.CreateCoupledPriceGroupAndPricelevel(CustomerPriceGroup, CRMPricelevel);
        // [GIVEN] Coupled SalesPrices, where "Starting Date" is different, one is '010121', second is '020121'
        LibraryCRMIntegration.CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup, SalesPrice[1], CRMProductPricelevel[1]);
        SalesPrice[1].Rename(SalesPrice[1]."Item No.", SalesPrice[1]."Sales Type", SalesPrice[1]."Sales Code", WorkDate(), '', '', '', 0);
        LibraryCRMIntegration.CreateCoupledSalesPriceAndPricelistLine(CustomerPriceGroup, SalesPrice[2], CRMProductPricelevel[2]);
        SalesPrice[2].Rename(SalesPrice[2]."Item No.", SalesPrice[2]."Sales Type", SalesPrice[2]."Sales Code", WorkDate() + 1, '', '', '', 0);

        // [WHEN] UpdateData for 'SalesPrice'
        FeatureDataUpdateStatus."Company Name" := CompanyName();
        FeatureDataUpdateStatus."Feature Key" := 'SalesPrice';
        FeatureDataUpdateStatus."Use Default Price Lists" := false;
        FeaturePriceCalculation.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Price List Header #1, where "Starting Date" is '010121', not coupled
        PriceListHeader[1].SetRange("Source Type", "Price Source Type"::"Customer Price Group");
        PriceListHeader[1].SetRange("Source No.", CustomerPriceGroup.Code);
        PriceListHeader[1].SetRange("Starting Date", SalesPrice[1]."Starting Date");
        Assert.RecordCount(PriceListHeader[1], 1);
        PriceListHeader[1].FindFirst();
        Assert.IsFalse(CRMIntegrationRecord.FindIDFromRecordID(PriceListHeader[1].RecordId, CRMId), 'PL Header#1 is coupled');
        // [THEN] Price List Line #1, where "Starting Date" is '010121', not coupled
        PriceListLine[1].SetRange("Price List Code", PriceListHeader[1].Code);
        Assert.RecordCount(PriceListLine[1], 1);
        PriceListLine[1].FindFirst();
        Assert.IsFalse(CRMIntegrationRecord.FindIDFromRecordID(PriceListLine[1].RecordId, CRMId), 'PL Line#1 is coupled');

        // [THEN] Price List Header #2, where "Starting Date" is '020121', not coupled
        PriceListHeader[2].SetRange("Source Type", "Price Source Type"::"Customer Price Group");
        PriceListHeader[2].SetRange("Source No.", CustomerPriceGroup.Code);
        PriceListHeader[2].SetRange("Starting Date", SalesPrice[2]."Starting Date");
        Assert.RecordCount(PriceListHeader[2], 1);
        PriceListHeader[2].FindFirst();
        Assert.IsFalse(CRMIntegrationRecord.FindIDFromRecordID(PriceListHeader[2].RecordId, CRMId), 'PL Header#2 is coupled');
        // [THEN] Price List Line #2, where "Starting Date" is '020121', not coupled
        PriceListLine[2].SetRange("Price List Code", PriceListHeader[2].Code);
        Assert.RecordCount(PriceListLine[2], 1);
        PriceListLine[2].FindFirst();
        Assert.IsFalse(CRMIntegrationRecord.FindIDFromRecordID(PriceListLine[1].RecordId, CRMId), 'PL Line#1 is coupled');

        // [THEN] CRM Price List 'X' and his lines are not coupled
        Assert.IsFalse(
            CRMIntegrationRecord.FindRecordIDFromID(CRMPricelevel.PriceLevelId, Database::"Customer Price Group", RecId), 'CRM PLHeader is coupled');
        Assert.IsFalse(
            CRMIntegrationRecord.FindRecordIDFromID(CRMProductPricelevel[1].ProductPriceLevelId, Database::"Sales price", RecId), 'CRM PLLine#1 is coupled');
        Assert.IsFalse(
            CRMIntegrationRecord.FindRecordIDFromID(CRMProductPricelevel[2].ProductPriceLevelId, Database::"Sales price", RecId), 'CRM PLLine#2 is coupled');
        // [THEN] Customer Price Group 'X' and Sales Price records are not coupled
        Assert.IsFalse(CRMIntegrationRecord.FindIDFromRecordID(CustomerPriceGroup.RecordId, CRMId), 'CustomerPriceGroup is coupled');
        Assert.IsFalse(CRMIntegrationRecord.FindIDFromRecordID(SalesPrice[1].RecordId, CRMId), 'SalesPrice#1 is coupled');
        Assert.IsFalse(CRMIntegrationRecord.FindIDFromRecordID(SalesPrice[2].RecordId, CRMId), 'SalesPrice#2 is coupled');
        // [THEN] Integration Table Mappings and Job Queue Entries for "Price List Header/Line" are added.
        IntegrationTableMapping.SetRange("Table ID", Database::"Price List Header");
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Header mapping not found');
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
        Assert.IsTrue(JobQueueEntry.FindFirst(), 'Header Job not found');
        IntegrationTableMapping.SetRange("Table ID", Database::"Price List Line");
        Assert.IsTrue(IntegrationTableMapping.FindFirst(), 'Line mapping not found');
        JobQueueEntry.SetRange("Record ID to Process", IntegrationTableMapping.RecordId());
        Assert.IsTrue(JobQueueEntry.FindFirst(), 'Header Job not found');
    end;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        JobsSetup: Record "Jobs Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Copy Price Data Test");
        LibraryVariableStorage.Clear();
        Clear(CopyFromToPriceListLine);

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Copy Price Data Test");

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('SAL'));
        SalesReceivablesSetup.Modify();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('PUR'));
        PurchasesPayablesSetup.Modify();

        JobsSetup.Get();
        JobsSetup.Validate("Price List Nos.", LibraryERM.CreateNoSeriesCode('JOB'));
        JobsSetup.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Copy Price Data Test");
    end;

    local procedure CreateJobGLAccPrice(var JobGLAccountPrice: Record "Job G/L Account Price"; Price: Decimal; Discount: Decimal; Cost: Decimal)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobGLAccountPrice(
            JobGLAccountPrice, Job."No.", JobTask."Job Task No.", LibraryERM.CreateGLAccountNo(), '');
        JobGLAccountPrice."Unit Price" := Price;
        if Price <> 0 then
            JobGLAccountPrice."Unit Cost Factor" := LibraryRandom.RandDec(10, 2);
        JobGLAccountPrice."Line Discount %" := Discount;
        JobGLAccountPrice."Unit Cost" := Cost;
        JobGLAccountPrice.Modify();
    end;

    local procedure CreateJobItemPrice(var JobItemPrice: Record "Job Item Price"; ApplyJobPrice: Boolean; ApplyJobDisc: Boolean)
    var
        Currency: Record Currency;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryJob.CreateJobItemPrice(
            JobItemPrice, Job."No.", JobTask."Job Task No.", Item."No.",
            Currency.Code, ItemVariant.Code, Item."Base Unit of Measure");
        JobItemPrice."Unit Price" := LibraryRandom.RandDec(100, 2);
        JobItemPrice."Unit Cost Factor" := LibraryRandom.RandDec(10, 2);
        JobItemPrice."Line Discount %" := LibraryRandom.RandDec(50, 2);
        JobItemPrice."Apply Job Price" := ApplyJobPrice;
        JobItemPrice."Apply Job Discount" := ApplyJobDisc;
        JobItemPrice.Modify();
    end;

    local procedure CreateJobResourcePrice(var JobResourcePrice: Record "Job Resource Price"; ApplyJobPrice: Boolean; ApplyJobDisc: Boolean)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateWorkType(WorkType);
        LibraryJob.CreateJobResourcePrice(
            JobResourcePrice, Job."No.", JobTask."Job Task No.",
            JobResourcePrice.Type::Resource, Resource."No.", WorkType.Code, '');
        JobResourcePrice."Apply Job Price" := ApplyJobPrice;
        JobResourcePrice."Apply Job Discount" := ApplyJobDisc;
        JobResourcePrice."Unit Price" := LibraryRandom.RandDec(1000, 2);
        JobResourcePrice."Unit Cost Factor" := LibraryRandom.RandDec(10, 2);
        JobResourcePrice."Line Discount %" := LibraryRandom.RandDec(50, 2);
        JobResourcePrice.Modify();
    end;

    local procedure CreateResourcePrice(var ResourcePrice: Record "Resource Price")
    var
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateWorkType(WorkType);
        LibraryResource.CreateResourcePrice(ResourcePrice, ResourcePrice.Type::Resource, Resource."No.", WorkType.Code, '');
        ResourcePrice."Unit Price" := LibraryRandom.RandDec(1000, 2);
        ResourcePrice.Modify();
    end;

    local procedure CreateResourceCost(var ResourceCost: Record "Resource Cost"; ResType: Integer; ResCode: Code[20])
    var
        WorkType: Record "Work Type";
    begin
        ResourceCost.Type := ResType;
        ResourceCost.Code := ResCode;
        LibraryResource.CreateWorkType(WorkType);
        ResourceCost."Work Type Code" := WorkType.Code;
        ResourceCost."Direct Unit Cost" := LibraryRandom.RandDec(1000, 2);
        ResourceCost."Unit Cost" := ResourceCost."Direct Unit Cost" * 1.75;
        ResourceCost.Insert();
    end;

    local procedure CreateResourceGroup(var Resource: Record Resource; var ResourceGroup: Record "Resource Group")
    begin
        if Resource."No." = '' then
            LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateResourceGroup(ResourceGroup);
        Resource."Resource Group No." := ResourceGroup."No.";
        Resource.Modify();
    end;

    local procedure VerifyHeader(PriceListLine: Record "Price List Line")
    var
        PriceListHeader: Record "Price List Header";
    begin
        PriceListLine.TestField("Price List Code");
        PriceListHeader.Get(PriceListLine."Price List Code");
        PriceListHeader.TestField("Amount Type", PriceListLine."Amount Type");
        PriceListHeader.TestField("Price Type", PriceListLine."Price Type");
        PriceListHeader.TestField("Currency Code", PriceListLine."Currency Code");
        PriceListHeader.TestField("Starting Date", PriceListLine."Starting Date");
        PriceListHeader.TestField("Ending Date", PriceListLine."Ending Date");
        PriceListHeader.TestField("Source Type", PriceListLine."Source Type");
        PriceListHeader.TestField("Source No.", PriceListLine."Source No.");
        PriceListHeader.TestField("Parent Source No.", PriceListLine."Parent Source No.");
        Assert.AreNotEqual(PriceListHeader."Source Group", "Price Source Group"::All, 'Source Group is All in header');
    end;

    [ModalPageHandler]
    procedure DataUpgradeOverviewModalHandler(var DataUpgradeOverview: TestPage "Data Upgrade Overview")
    begin
        DataUpgradeOverview.Filter.SetFilter("Table ID", format(Database::"CRM Integration Record"));
        assert.IsTrue(DataUpgradeOverview.First(), 'not found CRM Integration Record line');
        LibraryVariableStorage.Enqueue(DataUpgradeOverview."No. of Records".AsInteger());
    end;
}
