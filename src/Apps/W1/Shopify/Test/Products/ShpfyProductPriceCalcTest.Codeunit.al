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
        ExpectedPriceUpToBoundary: Decimal;
        ExpectedPriceFromBoundary: Decimal;
        UnitCost: Decimal;
        PriceBeforeBoundary: Decimal;
        PriceFromBoundary: Decimal;
        ComparePrice: Decimal;
        OriginalWorkDate: Date;
        BoundaryDate: Date;
    begin
        // [SCENARIO] Bug 642194: changing the Work Date mid-session must recalculate prices even though the Shop record has not been modified.
        // [SCENARIO] The price calculation codeunit is SingleInstance and caches a temp Sales Header with Document Date = WorkDate(). A stale cache must not keep applying the previous Work Date's price.

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
        ExpectedPriceUpToBoundary := Round(InitPrice * (1 - DiscUpToBoundary / 100));
        ExpectedPriceFromBoundary := Round(InitPrice * (1 - DiscFromBoundary / 100));
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", InitUnitCost, InitPrice);

        // [GIVEN] Two dated "All Customers" price list lines for the item: a lower price up to the boundary date, a higher price from the day after the boundary date.
        BoundaryDate := DMY2Date(1, 1, 2027);
        ProductInitTest.CreateDatedAllCustPriceList(Item."No.", ExpectedPriceUpToBoundary, ExpectedPriceFromBoundary, BoundaryDate);

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

        // [THEN] The first calculation used the price valid from the boundary date onwards.
        LibraryAssert.AreNearlyEqual(ExpectedPriceFromBoundary, PriceFromBoundary, 0.01, 'Price for Work Date after the boundary date');
        // [THEN] The second calculation used the price valid up to the boundary date (would still be the from-boundary price with a stale WorkDate cache).
        LibraryAssert.AreNearlyEqual(ExpectedPriceUpToBoundary, PriceBeforeBoundary, 0.01, 'Price for Work Date before the boundary date');
    end;

    [Test]
    [HandlerFunctions('ActivateConfirmHandler')]
    procedure ExplicitZeroDiscountByVariantInV16()
    begin
        // [SCENARIO 649151] A variant-specific Discount 0% removes the generic discount from the Shopify selling price.
        VerifyVariantZeroDiscount("Price Amount Type"::Discount, 100, 0);
    end;

    [Test]
    [HandlerFunctions('ActivateConfirmHandler')]
    procedure IncidentalZeroDiscountByVariantInV16()
    begin
        // [SCENARIO 649151] A variant-specific Price & Discount line with 0% must preserve the generic discount.
        VerifyVariantZeroDiscount("Price Amount Type"::Any, 70, 100);
    end;

    local procedure VerifyVariantZeroDiscount(VariantAmountType: Enum "Price Amount Type"; ExpectedPrice: Decimal; ExpectedComparePrice: Decimal)
    var
        Shop: Record "Shpfy Shop";
        TempResetShop: Record "Shpfy Shop" temporary;
        TempResetCatalog: Record "Shpfy Catalog" temporary;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceListHeader: Record "Price List Header";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ProductPriceCalculation: Codeunit "Shpfy Product Price Calc.";
        PriceCalculationLibrary: Codeunit "Library - Price Calculation";
        LibraryInventory: Codeunit "Library - Inventory";
        UnitCost: Decimal;
        Price: Decimal;
        ComparePrice: Decimal;
    begin
        // [GIVEN] A shop with line discounts enabled, LCY and prices excluding VAT.
        // CreateShop commits its initialization; configure pricing only after those commits.
        Shop := InitializeTest.CreateShop();
        Shop."Allow Line Disc." := true;
        Shop."Currency Code" := '';
        Shop."Customer Price Group" := '';
        Shop."Customer Discount Group" := '';
        Shop."Prices Including VAT" := false;
        Shop."Tax Liable" := false;
        Shop.Modify();
        PriceCalculationLibrary.EnableExtendedPriceCalculation();
        PriceCalculationLibrary.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Item cost 50, item-card price 125, and a variant. The distinct card price detects a price-list fallback.
        Item := ProductInitTest.CreateItem(Shop."Item Templ. Code", 50, 125);
        Item.Validate("Sales Unit of Measure", Item."Base Unit of Measure");
        Item.Modify(true);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] One active list: generic Price 100, generic Discount 30%, then the variant-specific zero.
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Sale, PriceListHeader."Source Type"::"All Customers", '');
        CreateVariantDiscountPriceLine(PriceListHeader, Item, '', "Price Amount Type"::Price, 0);
        CreateVariantDiscountPriceLine(PriceListHeader, Item, '', "Price Amount Type"::Discount, 30);
        CreateVariantDiscountPriceLine(PriceListHeader, Item, ItemVariant.Code, VariantAmountType, 0);
        PriceListHeader.Validate(Status, "Price Status"::Active);
        PriceListHeader.Modify(true);

        // SetShop does not clear a customer cached by an earlier catalog test. Reset through the catalog API,
        // using a non-Shopify catalog ID and a blank shop so SetShop must rebuild the actual shop context next.
        TempResetCatalog.Id := -1;
        ProductPriceCalculation.SetShopAndCatalog(TempResetShop, TempResetCatalog);

        // [WHEN] The connector calculates the generic item's price, not a manually constructed Sales Line.
        ProductPriceCalculation.SetShop(Shop);
        ProductPriceCalculation.CalcPrice(Item, '', Item."Sales Unit of Measure", UnitCost, Price, ComparePrice);

        // [THEN] The generic discount is applicable and produces a discounted selling price and a compare-at price.
        VerifyCalculatedVariantPrice(UnitCost, Price, ComparePrice, 70, 100);

        // [WHEN] The same calculator prices the variant, retaining the previous outputs to detect failure to clear compare-at.
        ProductPriceCalculation.CalcPrice(Item, ItemVariant.Code, Item."Sales Unit of Measure", UnitCost, Price, ComparePrice);

        // [THEN] Only an explicit Discount 0% removes the discount and clears the compare-at price.
        VerifyCalculatedVariantPrice(UnitCost, Price, ComparePrice, ExpectedPrice, ExpectedComparePrice);

        // [WHEN] The same calculator prices the generic item again.
        ProductPriceCalculation.CalcPrice(Item, '', Item."Sales Unit of Measure", UnitCost, Price, ComparePrice);

        // [THEN] The variant exception has not leaked into the generic calculation.
        VerifyCalculatedVariantPrice(UnitCost, Price, ComparePrice, 70, 100);
        PriceCalculationLibrary.DisableExtendedPriceCalculation();
    end;

    local procedure CreateVariantDiscountPriceLine(PriceListHeader: Record "Price List Header"; Item: Record Item; VariantCode: Code[10]; AmountType: Enum "Price Amount Type"; DiscountPct: Decimal)
    var
        PriceListLine: Record "Price List Line";
    begin
        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, AmountType, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Variant Code", VariantCode);
        PriceListLine.Validate("Unit of Measure Code", Item."Sales Unit of Measure");
        if AmountType in ["Price Amount Type"::Price, "Price Amount Type"::Any] then begin
            PriceListLine.Validate("Unit Price", 100);
            PriceListLine.Validate("Allow Line Disc.", true);
        end;
        if AmountType in ["Price Amount Type"::Discount, "Price Amount Type"::Any] then
            PriceListLine.Validate("Line Discount %", DiscountPct);
        PriceListLine.Modify(true);
    end;

    local procedure VerifyCalculatedVariantPrice(UnitCost: Decimal; Price: Decimal; ComparePrice: Decimal; ExpectedPrice: Decimal; ExpectedComparePrice: Decimal)
    begin
        LibraryAssert.AreEqual(50, UnitCost, 'The Shopify unit cost must remain unchanged.');
        LibraryAssert.AreEqual(ExpectedPrice, Price, 'The Shopify selling price must reflect the applicable line discount.');
        LibraryAssert.AreEqual(ExpectedComparePrice, ComparePrice, 'The Shopify compare-at price must be cleared when there is no discount.');
    end;

    [ConfirmHandler]
    procedure ActivateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}