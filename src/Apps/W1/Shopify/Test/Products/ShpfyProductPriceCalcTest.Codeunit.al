// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;
using Microsoft.Inventory.Item;
using Microsoft.Sales.Pricing;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Asset;

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
        LibraryPriceCalculation.AddSetup(PriceCalculationSetup, "Price Calculation Method"::"Lowest Price", "Price Type"::Sale, "Price Asset Type"::Item, "Price Calculation Handler"::"Business Central (Version 16.0)", true);
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
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
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

    [ConfirmHandler]
    procedure ActivateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
