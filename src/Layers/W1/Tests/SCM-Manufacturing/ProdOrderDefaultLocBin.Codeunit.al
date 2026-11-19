// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Structure;
using System.TestLibraries.Utilities;

codeunit 137440 "Prod. Order Default Loc. Bin"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Default Location] [Bin]
    end;

    var
        Assert: Codeunit Assert;
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Fixture: Codeunit "SCM Production Orders";
        IsInitialized: Boolean;

    [Test]
    procedure RoutingOutputBinOverridesLocationDefault()
    var
        Item: Record Item;
        Location: Record Location;
        RoutingBin: Record Bin;
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Defaulting a location before item entry does not override the routing output bin.
        Initialize();
        // [GIVEN] Different output bins on the default location and the item's final work center.
        CreateBinFixture(Item, Location, RoutingBin);
        CreateNewOrder(ProductionOrder);
        // [WHEN] The item is selected and the order is refreshed.
        ProductionOrder.Validate("Source No.", Item."No.");
        ProductionOrder.Validate(Quantity, 1);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        // [THEN] Finished output uses the routing bin, not the location bin selected before item entry.
        VerifyOutputBin(ProductionOrder, Location.Code, RoutingBin.Code);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    procedure ExplicitOutputBinSurvivesSourceSelection()
    var
        Item: Record Item;
        Location: Record Location;
        RoutingBin: Record Bin;
        ExplicitBin: Record Bin;
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Selecting an item and refreshing preserves an explicitly entered output bin.
        Initialize();
        // [GIVEN] A new order with an explicit bin different from the location and routing defaults.
        CreateBinFixture(Item, Location, RoutingBin);
        LibraryWarehouse.CreateBin(ExplicitBin, Location.Code, '', '', '');
        CreateNewOrder(ProductionOrder);
        ProductionOrder.Validate("Bin Code", ExplicitBin.Code);
        ProductionOrder.Modify(true);
        // [WHEN] The item is selected and the order is refreshed.
        ProductionOrder.Validate("Source No.", Item."No.");
        ProductionOrder.Validate(Quantity, 1);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        // [THEN] The user's bin takes precedence over both automatic defaults.
        VerifyOutputBin(ProductionOrder, Location.Code, ExplicitBin.Code);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    procedure SalesSourceDoesNotInheritDefaultLocationBin()
    var
        Item: Record Item;
        DefaultLocation: Record Location;
        SourceLocation: Record Location;
        RoutingBin: Record Bin;
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationCode: Code[10];
        Iteration: Integer;
    begin
        // [SCENARIO] Sales sources at another or blank location do not inherit a bin from the setup location.
        Initialize();
        CreateBinFixture(Item, DefaultLocation, RoutingBin);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SourceLocation);
        for Iteration := 1 to 2 do begin
            LocationCode := '';
            if Iteration = 1 then
                LocationCode := SourceLocation.Code;
            // [GIVEN] A new defaulted order and a sales source with an authoritative location.
            Fixture.CreateDefaultLocationSalesLine(SalesHeader, SalesLine, Item."No.", LocationCode, 1);
            SalesHeader."Location Code" := LocationCode;
            SalesHeader.Modify(true);
            CreateNewOrder(ProductionOrder);
            // [WHEN] The sales source is selected and the order is refreshed.
            ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::"Sales Header");
            ProductionOrder.Validate("Source No.", SalesHeader."No.");
            ProductionOrder.Modify(true);
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
            // [THEN] Refresh uses the sales location without attempting to use the setup location's bin.
            ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
            ProductionOrder.TestField("Location Code", LocationCode);
            VerifyOutputBin(ProductionOrder, LocationCode, '');
        end;
        LibrarySetupStorage.Restore();
    end;

    local procedure CreateBinFixture(var Item: Record Item; var Location: Record Location; var RoutingBin: Record Bin)
    var
        Component: Record Item;
        LocationBin: Record Bin;
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(LocationBin, Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(RoutingBin, Location.Code, '', '', '');
        Location.Validate("From-Production Bin Code", LocationBin.Code);
        Location.Modify(true);
        Fixture.ConfigureDefaultLocation(Location.Code, '');
        Fixture.CreateDefaultLocationItem(Item, Component, Component."Flushing Method"::Manual);
        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.SetRange("Version Code", '');
        RoutingLine.FindFirst();
        WorkCenter.Get(RoutingLine."No.");
        WorkCenter.Validate("Location Code", Location.Code);
        WorkCenter.Validate("From-Production Bin Code", RoutingBin.Code);
        WorkCenter.Modify(true);
    end;

    local procedure CreateNewOrder(var ProductionOrder: Record "Production Order")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Released Order Nos."));
        Clear(ProductionOrder);
        ProductionOrder.Status := ProductionOrder.Status::Released;
        ProductionOrder.SetDefaultLocation();
        ProductionOrder.Insert(true);
    end;

    local procedure VerifyOutputBin(ProductionOrder: Record "Production Order"; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(ProdOrderLine, 1);
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField("Location Code", LocationCode);
        ProdOrderLine.TestField("Bin Code", BinCode);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Order Default Loc. Bin");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Order Default Loc. Bin");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveInventorySetup();
        LibrarySetupStorage.SaveManufacturingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Order Default Loc. Bin");
    end;
}
