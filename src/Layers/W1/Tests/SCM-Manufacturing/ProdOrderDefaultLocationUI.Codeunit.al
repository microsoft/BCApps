// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using System.TestLibraries.Utilities;

codeunit 137438 "Prod. Order Default Loc. UI"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Default Location] [UI]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        IsInitialized: Boolean;

    [Test]
    procedure DefaultLocationReleasedCard()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ManufacturingSetup: Record "Manufacturing Setup";
        Fixture: Codeunit "SCM Production Orders";
        ReleasedProductionOrder: TestPage "Released Production Order";
        OrderNo: Code[20];
    begin
        // [SCENARIO] A new released order shows the setup location before entry and retains it when saved.
        Initialize();
        // [GIVEN] A default manufacturing location and an item.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Fixture.ConfigureDefaultLocation(Location.Code, '');
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Released Order Nos."));
        // [WHEN] A user opens a new released production order.
        ReleasedProductionOrder.OpenNew();
        // [THEN] The location is defaulted before the user supplies any fields.
        ReleasedProductionOrder."Location Code".AssertEquals(Location.Code);
        // [WHEN] The user enters an item and quantity and saves the order.
        ReleasedProductionOrder."Source No.".SetValue(Item."No.");
        ReleasedProductionOrder.Quantity.SetValue(2);
        OrderNo := ReleasedProductionOrder."No.".Value();
        ReleasedProductionOrder.Close();
        // [THEN] The saved order retains the location and quantity.
        ProductionOrder.Get(ProductionOrder.Status::Released, OrderNo);
        ProductionOrder.TestField("Location Code", Location.Code);
        ProductionOrder.TestField(Quantity, 2);
        LibrarySetupStorage.Restore();
    end;

    [Test]
    procedure DefaultLocationCardOverride()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        DefaultLocation: Record Location;
        OtherLocation: Record Location;
        ProductionOrder: Record "Production Order";
        ManufacturingSetup: Record "Manufacturing Setup";
        Fixture: Codeunit "SCM Production Orders";
        ReleasedProductionOrder: TestPage "Released Production Order";
        LocationCode: Code[10];
        OrderNo: Code[20];
        Iteration: Integer;
    begin
        // [SCENARIO] A user's cleared or replacement location survives source entry, saving and reopening.
        Initialize();
        // [GIVEN] A default location, an alternative location and an item variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(DefaultLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(OtherLocation);
        Fixture.ConfigureDefaultLocation(DefaultLocation.Code, '');
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Released Order Nos."));
        for Iteration := 1 to 2 do begin
            LocationCode := '';
            if Iteration = 2 then
                LocationCode := OtherLocation.Code;
            ReleasedProductionOrder.OpenNew();
            ReleasedProductionOrder."Location Code".AssertEquals(DefaultLocation.Code);
            // [WHEN] The user clears or replaces the default, then enters the item and variant.
            ReleasedProductionOrder."Location Code".SetValue(LocationCode);
            ReleasedProductionOrder."Source No.".SetValue(Item."No.");
            ReleasedProductionOrder."Variant Code".SetValue(ItemVariant.Code);
            ReleasedProductionOrder.Quantity.SetValue(2);
            // [THEN] Source entry and saving respect the user's location.
            ReleasedProductionOrder."Location Code".AssertEquals(LocationCode);
            OrderNo := ReleasedProductionOrder."No.".Value();
            ReleasedProductionOrder.Close();
            ProductionOrder.Get(ProductionOrder.Status::Released, OrderNo);
            ProductionOrder.TestField("Location Code", LocationCode);
            ProductionOrder.TestField("Variant Code", ItemVariant.Code);
            // [WHEN] The user reopens the existing order.
            ReleasedProductionOrder.OpenEdit();
            ReleasedProductionOrder.GoToRecord(ProductionOrder);
            // [THEN] The setup default is not applied again.
            ReleasedProductionOrder."Location Code".AssertEquals(LocationCode);
            ReleasedProductionOrder.Close();
        end;
        LibrarySetupStorage.Restore();
    end;

    [Test]
    procedure DefaultLocationOtherInitialStatuses()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ManufacturingSetup: Record "Manufacturing Setup";
        Fixture: Codeunit "SCM Production Orders";
        SimulatedProductionOrder: TestPage "Simulated Production Order";
        PlannedProductionOrder: TestPage "Planned Production Order";
        FirmPlannedProductionOrder: TestPage "Firm Planned Prod. Order";
        OrderStatus: Enum "Production Order Status";
        OrderNo: Code[20];
        StatusIndex: Integer;
    begin
        // [SCENARIO] Simulated, planned and firm planned cards default the location on new orders.
        Initialize();
        // [GIVEN] A default manufacturing location and number series for all three statuses.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Fixture.ConfigureDefaultLocation(Location.Code, '');
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Simulated Order Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Planned Order Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Manufacturing Setup", ManufacturingSetup.FieldNo("Firm Planned Order Nos."));
        for StatusIndex := 0 to 2 do begin
            OrderStatus := Enum::"Production Order Status".FromInteger(StatusIndex);
            // [WHEN] A new order is opened in each card and populated with an item and quantity.
            case OrderStatus of
                OrderStatus::Simulated:
                    begin
                        SimulatedProductionOrder.OpenNew();
                        SimulatedProductionOrder."Location Code".AssertEquals(Location.Code);
                        SimulatedProductionOrder."Source No.".SetValue(Item."No.");
                        SimulatedProductionOrder.Quantity.SetValue(2);
                        OrderNo := SimulatedProductionOrder."No.".Value();
                        SimulatedProductionOrder.Close();
                    end;
                OrderStatus::Planned:
                    begin
                        PlannedProductionOrder.OpenNew();
                        PlannedProductionOrder."Location Code".AssertEquals(Location.Code);
                        PlannedProductionOrder."Source No.".SetValue(Item."No.");
                        PlannedProductionOrder.Quantity.SetValue(2);
                        OrderNo := PlannedProductionOrder."No.".Value();
                        PlannedProductionOrder.Close();
                    end;
                OrderStatus::"Firm Planned":
                    begin
                        FirmPlannedProductionOrder.OpenNew();
                        FirmPlannedProductionOrder."Location Code".AssertEquals(Location.Code);
                        FirmPlannedProductionOrder."Source No.".SetValue(Item."No.");
                        FirmPlannedProductionOrder.Quantity.SetValue(2);
                        OrderNo := FirmPlannedProductionOrder."No.".Value();
                        FirmPlannedProductionOrder.Close();
                    end;
            end;
            // [THEN] Each saved order retains the setup location and entered quantity.
            ProductionOrder.Get(OrderStatus, OrderNo);
            ProductionOrder.TestField("Location Code", Location.Code);
            ProductionOrder.TestField(Quantity, 2);
        end;
        LibrarySetupStorage.Restore();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Order Default Loc. UI");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Order Default Loc. UI");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.SaveInventorySetup();
        LibrarySetupStorage.SaveManufacturingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Order Default Loc. UI");
    end;
}
