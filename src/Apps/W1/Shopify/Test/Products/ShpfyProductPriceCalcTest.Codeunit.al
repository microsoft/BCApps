// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Pricing;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Product Price Calc. Test (ID 139605).
/// </summary>
codeunit 139605 "Shpfy Product Price Calc. Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";

    [Test]
    procedure UnitTestCalcPriceTest()
    var
        Shop: Record "Shpfy Shop";
        Item: Record Item;
        CustomerDiscountGroup: Record "Customer Discount Group";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductPriceCalculation: Codeunit "Shpfy Product Price Calc.";
        InitUnitCost: Decimal;
        InitPrice: Decimal;
        InitDiscountPerc: Decimal;
        UnitCost: Decimal;
        Price: Decimal;
        ComparePrice: Decimal;
    begin
        // [INIT] Initialization startup data.
        // Extended pricing is on by default in the tenant; explicitly select the V15 handler so the legacy Sales Price / Sales Line Discount data path is exercised.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)");
        Shop := InitializeTest.CreateShop();
        Shop."Allow Line Disc." := false;
        Shop.Modify();
        InitUnitCost := Any.DecimalInRange(10, 100, 1);
        InitPrice := Any.DecimalInRange(2 * InitUnitCost, 4 * InitUnitCost, 1);
        InitDiscountPerc := Any.DecimalInRange(5, 20, 1);
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", InitUnitCost, InitPrice);
        ProductInitTest.CreateSalesPrice(CopyStr(Shop.Code, 1, 10), Item."No.", InitPrice);
        CustomerDiscountGroup := ProductInitTest.CreateSalesLineDiscount(CopyStr(Shop.Code, 1, 10), Item."No.", InitDiscountPerc);

        // [SCENARIO] Doing the price calculation of an product for a shop where the fields "Customer Price Group" and Customer Discount Group" are not filled in.
        // [SCENARIO] After modify de "Customer Discount Group" for the same shop, we must get a discounted price.

        // [GIVEN] the Shop with the fields "Customer Price Group" and Customer Discount Group" not filled in.
        ProductPriceCalculation.SetShop(Shop);
        // [GIVEN] The item and the variable UnitCost, Price and ComparePrice for storing the results.
        // [WHEN] Invoking the procedure: CalcPrice(Item, '', '', UnitCost, Price, ComparePrice)
        ProductPriceCalculation.CalcPrice(Item, '', '', UnitCost, Price, ComparePrice);

        // [THEN] InitUnitCost = UnitCost
        LibraryAssert.AreEqual(InitUnitCost, UnitCost, 'Unit Cost');
        // [THEN] InitPrice = Price
        LibraryAssert.AreEqual(InitPrice, Price, 'Price');

        // [GIVEN] Update the Shop."Customer Discount Group" field and set the shop to the calculation codeunit.
        Shop."Customer Discount Group" := CustomerDiscountGroup.Code;
        Shop."Allow Line Disc." := true;
        Shop.Modify();
        ProductPriceCalculation.SetShop(Shop);

        // [GIVEN] The item and the variable UnitCost, Price and ComparePrice for storing the results.
        // [WHEN] Invoking the procedure: CalcPrice(Item, '', '', UnitCost, Price, ComparePrice)
        ProductPriceCalculation.CalcPrice(Item, '', '', UnitCost, Price, ComparePrice);
        // [THEN] InitUnitCost = UnitCost
        LibraryAssert.AreEqual(InitUnitCost, UnitCost, 'Unit Cost');
        // [THEN] InitPrice = ComparePrice. ComparePrice is the price without the discount.
        LibraryAssert.AreEqual(InitPrice, ComparePrice, 'Compare Price');
        // [THEN] InitPrice - InitDiscountPerc = Price
        LibraryAssert.AreNearlyEqual(InitPrice * (1 - InitDiscountPerc / 100), Price, 0.01, 'Discount Price');
    end;

    [Test]
    [HandlerFunctions('ActivateConfirmHandler')]
    procedure UnitTestCalcPriceTestNewPricing()
    var
        Shop: Record "Shpfy Shop";
        Item: Record Item;
        CustomerDiscountGroup: Record "Customer Discount Group";
        PriceCalculationSetup: Record "Price Calculation Setup";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductPriceCalculation: Codeunit "Shpfy Product Price Calc.";
        InitUnitCost: Decimal;
        InitPrice: Decimal;
        InitDiscountPerc: Decimal;
        UnitCost: Decimal;
        Price: Decimal;
        ComparePrice: Decimal;
    begin
        // [INIT] Initialization startup data.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.FindOrAddSetup(PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Sale, "Price Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        Shop := InitializeTest.CreateShop();
        Shop."Allow Line Disc." := false;
        Shop.Modify();
        InitUnitCost := Any.DecimalInRange(10, 100, 1);
        InitPrice := Any.DecimalInRange(2 * InitUnitCost, 4 * InitUnitCost, 1);
        InitDiscountPerc := Any.DecimalInRange(5, 20, 1);
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", InitUnitCost, InitPrice);
        CustomerDiscountGroup := ProductInitTest.CreatePriceList(CopyStr(Shop.Code, 1, 10), Item."No.", InitPrice, InitDiscountPerc);

        // [SCENARIO] Doing the price calculation of an product for a shop where the fields "Customer Price Group" and Customer Discount Group" are not filled in.
        // [SCENARIO] After modify de "Customer Discount Group" for the same shop, we must get a discounted price.

        // [GIVEN] the Shop with the fields "Customer Price Group" and Customer Discount Group" not filled in.
        ProductPriceCalculation.SetShop(Shop);
        // [GIVEN] The item and the variable UnitCost, Price and ComparePrice for storing the results.
        // [WHEN] Invoking the procedure: CalcPrice(Item, '', '', UnitCost, Price, ComparePrice)
        ProductPriceCalculation.CalcPrice(Item, '', '', UnitCost, Price, ComparePrice);

        // [THEN] InitUnitCost = UnitCost
        LibraryAssert.AreEqual(InitUnitCost, UnitCost, 'Unit Cost');
        // [THEN] InitPrice = Price
        LibraryAssert.AreEqual(InitPrice, Price, 'Price');

        // [GIVEN] Update the Shop."Customer Discount Group" field and set the shop to the calculation codeunit.
        Shop."Customer Discount Group" := CustomerDiscountGroup.Code;
        Shop."Allow Line Disc." := true;
        Shop.Modify();
        ProductPriceCalculation.SetShop(Shop);

        // [GIVEN] The item and the variable UnitCost, Price and ComparePrice for storing the results.
        // [WHEN] Invoking the procedure: CalcPrice(Item, '', '', UnitCost, Price, ComparePrice)
        ProductPriceCalculation.CalcPrice(Item, '', '', UnitCost, Price, ComparePrice);
        // [THEN] InitUnitCost = UnitCost
        LibraryAssert.AreEqual(InitUnitCost, UnitCost, 'Unit Cost');
        // [THEN] InitPrice = ComparePrice. ComparePrice is the price without the discount.
        LibraryAssert.AreEqual(InitPrice, ComparePrice, 'Compare Price');
        // [THEN] InitPrice - InitDiscountPerc = Price
        LibraryAssert.AreNearlyEqual(InitPrice * (1 - InitDiscountPerc / 100), Price, 0.01, 'Discount Price');
    end;

    [Test]
    [HandlerFunctions('ActivateConfirmHandler')]
    procedure UnitTestCalcPriceUsesCurrentWorkDate()
    var
        Shop: Record "Shpfy Shop";
        Item: Record Item;
        PriceCalculationSetup: Record "Price Calculation Setup";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductPriceCalculation: Codeunit "Shpfy Product Price Calc.";
        InitUnitCost: Decimal;
        InitPrice: Decimal;
        DiscUpToBoundary: Decimal;
        DiscFromBoundary: Decimal;
        UnitCost: Decimal;
        PriceBeforeBoundary: Decimal;
        PriceFromBoundary: Decimal;
        ComparePrice: Decimal;
        OriginalWorkDate: Date;
        BoundaryDate: Date;
    begin
        // [SCENARIO] Bug 642194: changing the Work Date mid-session must recalculate prices even though the Shop record has not been modified.
        // [SCENARIO] The price calculation codeunit is SingleInstance and caches a temp Sales Header with Document Date = WorkDate(). A stale cache must not keep applying the previous Work Date's discount.

        // [INIT] Initialization startup data.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.FindOrAddSetup(PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Sale, "Price Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
        Shop := InitializeTest.CreateShop();
        Shop."Allow Line Disc." := true;
        Shop.Modify();
        InitUnitCost := Any.DecimalInRange(10, 100, 1);
        InitPrice := Any.DecimalInRange(2 * InitUnitCost, 4 * InitUnitCost, 1);
        DiscUpToBoundary := 50;
        DiscFromBoundary := 20;
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", InitUnitCost, InitPrice);

        // [GIVEN] Two "All Customers" discount price list lines for the item: 50% up to the boundary date, 20% from the day after the boundary date.
        BoundaryDate := DMY2Date(1, 1, 2027);
        ProductInitTest.CreateDatedAllCustDiscPriceList(Item."No.", DiscUpToBoundary, DiscFromBoundary, BoundaryDate);

        OriginalWorkDate := WorkDate();

        // [WHEN] The Work Date is after the boundary date and the price is calculated for the shop.
        WorkDate(BoundaryDate + 180);
        ProductPriceCalculation.SetShop(Shop);
        ProductPriceCalculation.CalcPrice(Item, '', '', UnitCost, PriceFromBoundary, ComparePrice);

        // [WHEN] The Work Date is moved before the boundary date and the price is calculated again WITHOUT modifying the shop.
        WorkDate(BoundaryDate - 30);
        ProductPriceCalculation.SetShop(Shop);
        ProductPriceCalculation.CalcPrice(Item, '', '', UnitCost, PriceBeforeBoundary, ComparePrice);

        // [THEN] Restore the Work Date before asserting so a failure does not leak into other tests.
        WorkDate(OriginalWorkDate);

        // [THEN] The first calculation applied the 20% discount valid from the boundary date onwards.
        LibraryAssert.AreNearlyEqual(InitPrice * (1 - DiscFromBoundary / 100), PriceFromBoundary, 0.01, 'Price for Work Date after the boundary date');
        // [THEN] The second calculation applied the 50% discount valid up to the boundary date (would still be 20% with a stale WorkDate cache).
        LibraryAssert.AreNearlyEqual(InitPrice * (1 - DiscUpToBoundary / 100), PriceBeforeBoundary, 0.01, 'Price for Work Date before the boundary date');
    end;

    [Test]
    procedure SetShopAfterCatalogDoesNotUseCatalogCurrencyCode()
    var
        Shop: Record "Shpfy Shop";
        Catalog: Record "Shpfy Catalog";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        CatalogInitialize: Codeunit "Shpfy Catalog Initialize";
        ProductPriceCalculation: Codeunit "Shpfy Product Price Calc.";
        LibraryERM: Codeunit "Library - ERM";
        CatalogCurrencyCode: Code[10];
    begin
        // [SCENARIO] Bug 633092 Defect 1: SetShopAndCatalog caches catalog parameters (including a foreign currency)
        // into the SingleInstance state. A subsequent SetShop call for the same unmodified shop must force a
        // re-initialization so that base product prices are calculated in the shop currency, not the catalog currency.

        // [GIVEN] A shop with blank (LCY) currency.
        Shop := InitializeTest.CreateShop();

        // [GIVEN] A market catalog for the same shop with a foreign currency.
        CatalogCurrencyCode := LibraryERM.CreateCurrencyWithRounding();
        Catalog := CatalogInitialize.CreateCatalog("Shpfy Catalog Type"::Market);
        CatalogInitialize.CopyParametersFromShop(Catalog, Shop);
        Catalog."Currency Code" := CatalogCurrencyCode;
        Catalog.Modify();

        // [WHEN] Catalog price sync runs SetShopAndCatalog, then shop product/price sync runs SetShop for the same shop.
        ProductPriceCalculation.SetShopAndCatalog(Shop, Catalog);
        ProductPriceCalculation.SetShop(Shop);

        // [THEN] The price calculation state reflects the shop's blank (LCY) currency, not the catalog's foreign currency.
        LibraryAssert.AreEqual('', ProductPriceCalculation.GetCurrencyCode(), 'Catalog currency must not leak into shop-based price calculation after SetShop.');
    end;

    [Test]
    procedure SetShopAfterCatalogWithCustomerDoesNotUseCustomerPrice()
    var
        Shop: Record "Shpfy Shop";
        Catalog: Record "Shpfy Catalog";
        Item: Record Item;
        Customer: Record Customer;
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        CatalogInitialize: Codeunit "Shpfy Catalog Initialize";
        ProductPriceCalculation: Codeunit "Shpfy Product Price Calc.";
        LibrarySales: Codeunit "Library - Sales";
        InitUnitCost: Decimal;
        InitPrice: Decimal;
        CustDiscPerc: Decimal;
        UnitCost: Decimal;
        Price: Decimal;
        ComparePrice: Decimal;
    begin
        // [SCENARIO] Bug 633092 Defect 2: After SetShopAndCatalog with a B2B catalog that has a Customer No.,
        // SetShop must clear CustomerNo when re-initializing the cached temp sales header. Otherwise the header
        // is built from the catalog customer's price group and discounts even though the caller asked for shop
        // base prices, causing wrong (customer-discounted) prices to be sent to Shopify as the shop base price.

        // [GIVEN] A shop, an item with a base price, and a customer with a specific customer-level discount.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        Shop := InitializeTest.CreateShop();
        Shop."Allow Line Disc." := true;
        Shop.Modify();
        InitUnitCost := Any.DecimalInRange(10, 100, 1);
        InitPrice := Any.DecimalInRange(2 * InitUnitCost, 4 * InitUnitCost, 1);
        CustDiscPerc := Any.DecimalInRange(5, 20, 1);
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", InitUnitCost, InitPrice);
        LibrarySales.CreateCustomer(Customer);
        ProductInitTest.CreateCustomerPriceList(CopyStr(Shop.Code, 1, 10), Item."No.", InitPrice, CustDiscPerc, Customer);

        // [GIVEN] A catalog linked to that customer (B2B catalog, same currency as shop).
        Catalog := CatalogInitialize.CreateCatalog("Shpfy Catalog Type"::Company);
        CatalogInitialize.CopyParametersFromShop(Catalog, Shop);
        Catalog."Customer No." := Customer."No.";
        Catalog.Modify();

        // [WHEN] Catalog price sync runs SetShopAndCatalog.
        ProductPriceCalculation.SetShopAndCatalog(Shop, Catalog);

        // [WHEN] Shop is modified (bumping SystemModifiedAt) and shop price sync runs SetShop.
        Shop.Modify();
        Shop.Get(Shop.Code);
        ProductPriceCalculation.SetShop(Shop);
        ProductPriceCalculation.CalcPrice(Item, '', '', UnitCost, Price, ComparePrice);

        // [THEN] Price equals the item's base price — the catalog customer's discount must not be applied.
        LibraryAssert.AreEqual(InitPrice, Price, 'Catalog customer must not leak into shop-based price calculation after SetShop.');
    end;

    [ConfirmHandler]
    procedure ActivateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}