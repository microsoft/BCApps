// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Variant Batching Test (ID 139620).
/// Tests for variant batch size calculations based on 50,000 inventory quantities limit.
/// </summary>
codeunit 139620 "Shpfy Variant Batching Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        ShpfyInitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
    begin
        if IsInitialized then
            exit;
        IsInitialized := true;
        Shop := ShpfyInitializeTest.CreateShop();
        CommunicationMgt.SetShop(Shop);
    end;

    [Test]
    procedure UnitTestGetMaxVariantsPerBatchNoLocations()
    var
        ShopLocation: Record "Shpfy Shop Location";
        VariantAPI: Codeunit "Shpfy Variant API";
        MaxVariants: Integer;
    begin
        // [SCENARIO] GetMaxVariantsPerBatch returns 250 when no active default product locations exist
        // [GIVEN] No active default product locations for the shop
        Initialize();
        ShopLocation.SetRange("Shop Code", Shop.Code);
        ShopLocation.DeleteAll();
        VariantAPI.SetShop(Shop);

        // [WHEN] GetMaxVariantsPerBatch is called
        MaxVariants := VariantAPI.GetMaxVariantsPerBatch();

        // [THEN] Returns 250 (default batch size)
        LibraryAssert.AreEqual(250, MaxVariants, 'Expected 250 when no inventory locations exist');
    end;

    [Test]
    procedure UnitTestGetMaxVariantsPerBatchSingleLocation()
    var
        ShopLocation: Record "Shpfy Shop Location";
        VariantAPI: Codeunit "Shpfy Variant API";
        MaxVariants: Integer;
    begin
        // [SCENARIO] GetMaxVariantsPerBatch returns 50000 when only 1 active default product location exists
        // [GIVEN] 1 active default product location
        Initialize();
        ShopLocation.SetRange("Shop Code", Shop.Code);
        ShopLocation.DeleteAll();
        CreateShopLocation(Shop.Code, true, true);
        VariantAPI.SetShop(Shop);

        // [WHEN] GetMaxVariantsPerBatch is called
        MaxVariants := VariantAPI.GetMaxVariantsPerBatch();

        // [THEN] Returns 50000 (50000 div 1)
        LibraryAssert.AreEqual(50000, MaxVariants, 'Expected 50000 when 1 location exists (50000 / 1)');
    end;

    [Test]
    procedure UnitTestGetMaxVariantsPerBatchMultipleLocations()
    var
        ShopLocation: Record "Shpfy Shop Location";
        VariantAPI: Codeunit "Shpfy Variant API";
        MaxVariants: Integer;
    begin
        // [SCENARIO] GetMaxVariantsPerBatch returns 50000 div LocationCount when multiple locations exist
        // [GIVEN] 100 active default product locations
        Initialize();
        ShopLocation.SetRange("Shop Code", Shop.Code);
        ShopLocation.DeleteAll();
        CreateMultipleShopLocations(Shop.Code, 100);
        VariantAPI.SetShop(Shop);

        // [WHEN] GetMaxVariantsPerBatch is called
        MaxVariants := VariantAPI.GetMaxVariantsPerBatch();

        // [THEN] Returns 500 (50000 div 100)
        LibraryAssert.AreEqual(500, MaxVariants, 'Expected 500 when 100 locations exist (50000 / 100)');
    end;

    [Test]
    procedure UnitTestGetMaxVariantsPerBatchHighLocationCount()
    var
        ShopLocation: Record "Shpfy Shop Location";
        VariantAPI: Codeunit "Shpfy Variant API";
        MaxVariants: Integer;
    begin
        // [SCENARIO] GetMaxVariantsPerBatch returns correct value for high location count
        // [GIVEN] 500 active default product locations
        Initialize();
        ShopLocation.SetRange("Shop Code", Shop.Code);
        ShopLocation.DeleteAll();
        CreateMultipleShopLocations(Shop.Code, 500);
        VariantAPI.SetShop(Shop);

        // [WHEN] GetMaxVariantsPerBatch is called
        MaxVariants := VariantAPI.GetMaxVariantsPerBatch();

        // [THEN] Returns 100 (50000 div 500)
        LibraryAssert.AreEqual(100, MaxVariants, 'Expected 100 when 500 locations exist (50000 / 500)');
    end;

    [Test]
    procedure UnitTestGetDefaultLocationCountNoLocations()
    var
        ShopLocation: Record "Shpfy Shop Location";
        VariantAPI: Codeunit "Shpfy Variant API";
        LocationCount: Integer;
    begin
        // [SCENARIO] GetDefaultLocationCount returns 0 when no active default product locations exist
        // [GIVEN] No active default product locations for the shop
        Initialize();
        ShopLocation.SetRange("Shop Code", Shop.Code);
        ShopLocation.DeleteAll();
        VariantAPI.SetShop(Shop);

        // [WHEN] GetDefaultLocationCount is called
        LocationCount := VariantAPI.GetDefaultLocationCount();

        // [THEN] Returns 0
        LibraryAssert.AreEqual(0, LocationCount, 'Expected 0 when no default product locations exist');
    end;

    [Test]
    procedure UnitTestGetDefaultLocationCountOnlyActiveDefaultLocations()
    var
        ShopLocation: Record "Shpfy Shop Location";
        VariantAPI: Codeunit "Shpfy Variant API";
        LocationCount: Integer;
    begin
        // [SCENARIO] GetDefaultLocationCount only counts active default product locations
        // [GIVEN] Mix of active/inactive and default/non-default locations
        Initialize();
        ShopLocation.SetRange("Shop Code", Shop.Code);
        ShopLocation.DeleteAll();

        // Active, default product location (should be counted)
        CreateShopLocation(Shop.Code, true, true);
        CreateShopLocation(Shop.Code, true, true);
        // Active, but not default product location (should NOT be counted)
        CreateShopLocation(Shop.Code, true, false);
        // Inactive, default product location (should NOT be counted)
        CreateShopLocation(Shop.Code, false, true);

        VariantAPI.SetShop(Shop);

        // [WHEN] GetDefaultLocationCount is called
        LocationCount := VariantAPI.GetDefaultLocationCount();

        // [THEN] Returns 2 (only active default product locations)
        LibraryAssert.AreEqual(2, LocationCount, 'Expected 2 (only active default product locations)');
    end;

    local procedure CreateShopLocation(ShopCode: Code[20]; Active: Boolean; DefaultProductLocation: Boolean)
    var
        ShopLocation: Record "Shpfy Shop Location";
    begin
        ShopLocation.Init();
        ShopLocation."Shop Code" := ShopCode;
        ShopLocation.Id := Any.IntegerInRange(10000, 9999999);
        ShopLocation.Active := Active;
        ShopLocation."Default Product Location" := DefaultProductLocation;
        ShopLocation.Insert();
    end;

    local procedure CreateMultipleShopLocations(ShopCode: Code[20]; Count: Integer)
    var
        i: Integer;
    begin
        for i := 1 to Count do
            CreateShopLocation(ShopCode, true, true);
    end;
}
