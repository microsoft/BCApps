// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using System.TestLibraries.Utilities;

codeunit 137084 "SCM Production Orders V"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        IsInitialized := false;
    end;

    var
        LocationGreen: Record Location;
        LocationRed: Record Location;
        LocationYellow: Record Location;
        LocationWhite: Record Location;
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SerialItemTrackingMode: Option "None",AssignSerial,SelectSerial,VerifyValue;
        LotItemTrackingMode: Option "None",AssignLot,SelectLot,VerifyValue;
        IsInitialized: Boolean;
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';

    [Test]
    procedure VerifyDifferentLocationMustNotBeAllowedInProdOrderLineWhenWhsePutAwayOnLocation()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 559653] Verify Different Location must not be allowed in Production Order Line When "Prod. Output Whse. Handling" is "Warehouse Put-away" on Location.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationGreen.Validate("Prod. Output Whse. Handling", LocationGreen."Prod. Output Whse. Handling"::"No Warehouse Handling");
        LocationGreen.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationWhite.Validate("Prod. Output Whse. Handling", LocationWhite."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationWhite.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"No Warehouse Handling");
        LocationRed.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationYellow.Validate("Prod. Output Whse. Handling", LocationYellow."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationYellow.Modify();

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, Item2);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationWhite.Code, '');

        // [WHEN] Insert Production Order Line with different Location "Warehouse Put-away".
        asserterror InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationGreen.Code);

        // [THEN] Verify different Location must not be allowed in Production Order Line When Location "Warehouse Put-away" is selected on first Line.
        Assert.ExpectedTestFieldError(ProductionOrderLine.FieldCaption("Location Code"), LocationWhite.Code);

        // [WHEN] Insert Production Order Line with Same Location.
        InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationWhite.Code);

        // [THEN] Verify Same Location must be allowed in Production Order Line When Location "Warehouse Put-away" is selected on first Line.
        Assert.AreEqual(
            LocationWhite.Code,
            ProductionOrderLine."Location Code",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrderLine.FieldCaption("Location Code"), LocationWhite.Code, ProductionOrderLine.TableCaption()));

        // [WHEN] Insert Production Order Line with different Location "No Warehouse Handling".
        asserterror InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationGreen.Code);

        // [THEN] Verify Different Location "No Warehouse Handling" must not be allowed in Production Order Line When Location "Warehouse Put-away" is selected on first Line.
        Assert.ExpectedTestFieldError(ProductionOrderLine.FieldCaption("Location Code"), LocationWhite.Code);
    end;

    [Test]
    procedure VerifyWhsePutAwayLocationCannotBeSelectedOnProdOrderLine()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 559653] Verify "Warehouse Put-away" Location must not be allowed in another Production Order Line When "No Warehouse Handling" Location is selected on first line.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationGreen.Validate("Prod. Output Whse. Handling", LocationGreen."Prod. Output Whse. Handling"::"No Warehouse Handling");
        LocationGreen.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationWhite.Validate("Prod. Output Whse. Handling", LocationWhite."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationWhite.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"No Warehouse Handling");
        LocationRed.Modify();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationYellow.Validate("Prod. Output Whse. Handling", LocationYellow."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationYellow.Modify();

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, Item2);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationRed.Code, '');

        // [WHEN] Insert Production Order Line with different Location "Warehouse Put-away".
        asserterror InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationWhite.Code);

        // [THEN] Verify different Location "Warehouse Put-away" must not be allowed in Production Order Line When Location "No Warehouse Handling" is selected on first Line.
        Assert.ExpectedTestFieldError(ProductionOrderLine.FieldCaption("Location Code"), LocationRed.Code);

        // [WHEN] Insert Production Order Line with Same Location.
        InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationRed.Code);

        // [THEN] Verify Same Location must be allowed in Production Order Line When Location "No Warehouse Handling" is selected on first Line.
        Assert.AreEqual(
            LocationRed.Code,
            ProductionOrderLine."Location Code",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrderLine.FieldCaption("Location Code"), LocationRed.Code, ProductionOrderLine.TableCaption()));

        // [WHEN] Insert Production Order Line with different Location "No Warehouse Handling".
        InsertProdOrderLineWithLocation(ProductionOrderLine, ProductionOrder, LibraryRandom.RandInt(10000), LocationGreen.Code);

        // [THEN] Verify different Location "No Warehouse Handling" must be allowed in Production Order Line When Location "No Warehouse Handling" is selected on first Line.
        Assert.AreEqual(
            LocationGreen.Code,
            ProductionOrderLine."Location Code",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrderLine.FieldCaption("Location Code"), LocationGreen.Code, ProductionOrderLine.TableCaption()));
    end;

    [Test]
    procedure VerifyDocumentPutAwayStatusMustBeCompletelyPutAwayInReleasedProductionOrderForSourceTypeFamilyAndFlushingMethodForward()
    var
        Bin: Record Bin;
        Family: Record Family;
        Item: array[3] of Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        FamilyLine: array[3] of Record "Family Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
    begin
        // [SCENARIO 559026] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order When "Source Type" is Family and "Flushing Method" is "Forward".
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Validate("Use Put-away Worksheet", false);
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Forward);

        // [GIVEN] Create three items.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create Family with three items.
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item[2]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[3], Family."No.", Item[3]."No.", 1);

        // [GIVEN] Update "Routing No." in Family. 
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        // [GIVEN] Create and Refresh Production Order with "Source Type" Family.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(ProductionOrder, ProductionOrder.Status::Released, Family."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [GIVEN] Warehouse Put Away Request must be created When "Prod. Output Whse. Handling" is "Warehouse Put-away" on Location.
        WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request should be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNoText,ChangeStatusOnProdOrderOk')]
    procedure VerifyWarehousePutAwayMustBeCreatedForSourceTypeFamilyAndFlushingMethodBackwardWhenStatusIsChanged()
    var
        Bin: Record Bin;
        Family: Record Family;
        Item: array[3] of Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        FamilyLine: array[3] of Record "Family Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 559653] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order When "Source Type" is Family and "Flushing Method" is "Backward".
        // Warehouse Put Away must be created when Changing the status from Released to Finished Production Order.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Backward);

        // [GIVEN] Create three items.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create Family with three items.
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item[2]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[3], Family."No.", Item[3]."No.", 1);

        // [GIVEN] Update "Routing No." in Family. 
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        // [WHEN] Create and Refresh Production Order with "Source Type" Family.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(ProductionOrder, ProductionOrder.Status::Released, Family."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [THEN] Verify Warehouse Put Away Request must not be created with Flushing Method Backward.
        asserterror WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [GIVEN] Open Released Production Order.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Invoke "Change Status" action.
        ReleasedProductionOrder."Change &Status".Invoke();

        // [WHEN] Register Warehouse Activity.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNoText,ChangeStatusOnProdOrderOk')]
    procedure VerifyWarehousePutAwayMustBeCreatedForFlushingMethodBackwardUsingPutAwayWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 559987] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order using "Put Away Worksheet" and "Flushing Method" is "Backward".
        // Warehouse Put Away must be created using "Put Away Worksheet" when Changing the status from Released to Finished Production Order.
        Initialize();

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Validate("Use Put-away Worksheet", true);
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Backward);

        // [GIVEN] Create an tem.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Update "Routing No." in item. 
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [WHEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [THEN] Verify Warehouse Put Away Request must not be created with Flushing Method Backward.
        asserterror WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [GIVEN] Open Released Production Order.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Invoke "Change Status" action.
        ReleasedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, LocationRed.Code, Item."No.", Item."No.", ProductionOrder.Quantity, "Whse. Activity Sorting Method"::None, false);

        // [WHEN] Register Warehouse Activity.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNoText,ChangeStatusOnProdOrderOk')]
    procedure VerifyWarehousePutAwayMustBeCreatedForFamilyAndFlushingMethodForwardWhenStatusIsChangedFromFirmPlannedToReleased()
    var
        Bin: Record Bin;
        Family: Record Family;
        Item: array[3] of Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        FamilyLine: array[3] of Record "Family Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        FirmPlannedProductionOrder: TestPage "Firm Planned Prod. Order";
    begin
        // [SCENARIO 559984] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order When "Source Type" is Family and "Flushing Method" is "Forward".
        // Warehouse Put Away must be created when Changing the status from Firm Planned to Released Production Order.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Validate("Use Put-away Worksheet", false);
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Forward);

        // [GIVEN] Create three items.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItem(Item[3]);

        // [GIVEN] Create Family with three items.
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item[2]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[3], Family."No.", Item[3]."No.", 1);

        // [GIVEN] Update "Routing No." in Family. 
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        // [WHEN] Create and Refresh Production Order with "Source Type" Family.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(ProductionOrder, ProductionOrder.Status::"Firm Planned", Family."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [THEN] Verify Warehouse Put Away Request must not be created with Flushing Method Forward.
        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);

        // [GIVEN] Open Firm Planned Production Order.
        FirmPlannedProductionOrder.OpenEdit();
        FirmPlannedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Invoke "Change Status" action.
        FirmPlannedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Production Order.
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, Family."No.");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    procedure VerifyWarehousePutAwayMustBeCreatedAndRegisteredForItemWithSerialNoTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
    begin
        // [SCENARIO 560035] Verify Warehouse Put Away must be created and registered for Item with serial no. tracking.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item Tracking Code and item with Serial No.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), Location.Code, Bin.Code);

        // [WHEN] Create and post the Output Journal with Item Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, false, ProductionOrder.Quantity);

        // [THEN] Verify Warehouse Put Away Request must be created.
        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 1);

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,QuantityToCreatePageHandler')]
    procedure VerifyWarehousePutAwayMustBeCreatedAndRegisteredForItemWithSerialNoTrackingUsingPutAwayWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
    begin
        // [SCENARIO 560035] Verify Warehouse Put Away must be created and registered for Item with serial no. tracking using Put Away Worksheet.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item Tracking Code and item with Serial No.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), Location.Code, Bin.Code);

        // [WHEN] Create and post the Output Journal with Item Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, false, ProductionOrder.Quantity);

        // [THEN] Verify Warehouse Put Away Request must be created.
        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 1);

        // [GIVEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", ProductionOrder.Quantity, "Whse. Activity Sorting Method"::None, false);

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    procedure VerifyWarehousePutAwayMustBeCreatedAndRegisteredForItemWithLotNoTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
    begin
        // [SCENARIO 560035] Verify Warehouse Put Away must be created and registered for Item with Lot No. tracking.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item Tracking Code and item with Lot No.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), Location.Code, Bin.Code);

        // [WHEN] Create and post the Output Journal with Item Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, true, ProductionOrder.Quantity);

        // [THEN] Verify Warehouse Put Away Request must be created.
        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 1);

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    procedure VerifyWarehousePutAwayMustBeCreatedAndRegisteredForItemWithLotNoTrackingUsingPutAwayWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
    begin
        // [SCENARIO 560035] Verify Warehouse Put Away must be created and registered for Item with Lot No. tracking using Put Away Worksheet.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item Tracking Code and item with Lot No.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), Location.Code, Bin.Code);

        // [WHEN] Create and post the Output Journal with Item Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, true, ProductionOrder.Quantity);

        // [THEN] Verify Warehouse Put Away Request must be created.
        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 1);

        // [GIVEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", ProductionOrder.Quantity, "Whse. Activity Sorting Method"::None, false);

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    procedure VerifyWarehousePutAwayMustBeCreatedAndRegisteredForItemWithLotNoTrackingWhenOutputIsPartiallyPosted()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        LotNo1: Text;
        LotNo2: Text;
    begin
        // [SCENARIO 560035] Verify Warehouse Put Away must be created and registered for Item with Lot No. tracking When Output is partially posted.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item Tracking Code and item with Lot No.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandIntInRange(10, 10), Location.Code, Bin.Code);

        // [WHEN] Create and post the Output Journal with Item Tracking Lot1.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, true, LibraryRandom.RandIntInRange(5, 5));
        LotNo1 := LibraryVariableStorage.DequeueText();

        // [THEN] Warehouse Activity must be created with Lot No. Lot1.
        WarehouseActivityLine.SetRange("Lot No.", LotNo1);
        WarehouseActivityLine.SetRange(Quantity, LibraryRandom.RandIntInRange(5, 5));
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Create and post the Output Journal with Item Tracking Lot2.
        LibraryVariableStorage.Clear();
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, true, LibraryRandom.RandIntInRange(5, 5));
        LotNo2 := LibraryVariableStorage.DequeueText();

        // [THEN] Warehouse Activity must be created with Lot No. Lot2.
        WarehouseActivityLine.SetRange("Lot No.", LotNo2);
        WarehouseActivityLine.SetRange(Quantity, LibraryRandom.RandIntInRange(5, 5));
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Partially Put Away" in Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Partially Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Partially Put Away", ProductionOrder.TableCaption()));

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    procedure VerifyWarehousePutAwayMustBeCreatedAndRegisteredForItemWithLotNoTrackingWhenOutputIsPartiallyPostedUsingPutAwayWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo1: Text;
        LotNo2: Text;
    begin
        // [SCENARIO 560035] Verify Warehouse Put Away must be created and registered for Item with Lot No. tracking When Output is partially posted using Put Away Worksheet.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Use Put-away Worksheet", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item Tracking Code and item with Lot No.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandIntInRange(10, 10), Location.Code, Bin.Code);

        // [GIVEN] Create and post the Output Journal with Item Tracking Lot1.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, true, LibraryRandom.RandIntInRange(5, 5));
        LotNo1 := LibraryVariableStorage.DequeueText();

        // [GIVEN] Create and post the Output Journal with Item Tracking Lot2.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, true, LibraryRandom.RandIntInRange(5, 5));
        LotNo2 := LibraryVariableStorage.DequeueText();

        // [WHEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", LibraryRandom.RandIntInRange(4, 4), "Whse. Activity Sorting Method"::None, false);

        // [THEN] Warehouse Activity must be created with Lot No. Lot1.
        WarehouseActivityLine.SetRange("Lot No.", LotNo1);
        WarehouseActivityLine.SetRange(Quantity, LibraryRandom.RandIntInRange(4, 4));
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Partially Put Away" in Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Partially Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Partially Put Away", ProductionOrder.TableCaption()));

        // [GIVEN] Update "Qty. To Handle" in Put Away Worksheet.
        WhseWorksheetLine.Get(WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", WhseWorksheetLine."Line No.");
        WhseWorksheetLine.Validate("Qty. to Handle", LibraryRandom.RandIntInRange(1, 1));
        WhseWorksheetLine.Modify();

        // [WHEN] Create Put Away Document.
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);

        // [THEN] Warehouse Activity must be created with Lot No. Lot1.
        WarehouseActivityLine.SetRange("Lot No.", LotNo1);
        WarehouseActivityLine.SetRange(Quantity, LibraryRandom.RandIntInRange(1, 1));
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Partially Put Away" in Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Partially Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Partially Put Away", ProductionOrder.TableCaption()));

        // [GIVEN] Update "Qty. To Handle" in Put Away Worksheet.
        WhseWorksheetLine.Get(WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name, WhseWorksheetLine."Location Code", WhseWorksheetLine."Line No.");
        WhseWorksheetLine.Validate("Qty. to Handle", LibraryRandom.RandIntInRange(5, 5));
        WhseWorksheetLine.Modify();

        // [WHEN] Create Put Away Document.
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);

        // [THEN] Warehouse Activity must be created with Lot No. Lot2.
        WarehouseActivityLine.SetRange("Lot No.", LotNo2);
        WarehouseActivityLine.SetRange(Quantity, LibraryRandom.RandIntInRange(5, 5));
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    procedure VerifyWarehousePutAwayMustBeCreatedForItemWithLotNoTrackingUsingPutAwayWorksheetWithAdditionalQty()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        AddedProdOrderQty: Decimal;
        LotNo1: Text;
        LotNo2: Text;
    begin
        // [SCENARIO 566077] Verify Warehouse Put Away must be created and registered for Item with Lot No. tracking using Put Away Worksheet.
        // When Quantity is increased after Production Order is completely posted.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);

        // [GIVEN] Generate Random Quantity. 
        AddedProdOrderQty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item Tracking Code and item with Lot No.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), Location.Code, Bin.Code);

        // [GIVEN] Create and post the Output Journal with Item Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, false, ProductionOrder.Quantity);
        LotNo1 := LibraryVariableStorage.DequeueText();

        // [WHEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", ProductionOrder.Quantity, "Whse. Activity Sorting Method"::None, false);

        // [THEN] Warehouse Activity must be created with Lot No. Lot1.
        WarehouseActivityLine.SetRange("Lot No.", LotNo1);
        WarehouseActivityLine.SetRange(Quantity, ProductionOrder.Quantity);
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Find Prod Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");
        ProdOrderLine.Validate(Quantity, ProdOrderLine.Quantity + AddedProdOrderQty);
        ProdOrderLine.Modify();

        // [GIVEN] Create and post the Output Journal with Item Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, false, AddedProdOrderQty);
        LotNo2 := LibraryVariableStorage.DequeueText();

        // [WHEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", AddedProdOrderQty, "Whse. Activity Sorting Method"::None, false);

        // [THEN] Warehouse Activity must be created with Lot No. Lot2.
        WarehouseActivityLine.SetRange("Lot No.", LotNo2);
        WarehouseActivityLine.SetRange(Quantity, AddedProdOrderQty);
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
        LibraryVariableStorage.Clear();
    end;

    [Test]
    procedure VerifyWarehousePutAwayMustBeCreatedForItemWithUsingPutAwayWorksheetWithAdditionalQty()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        AddedProdOrderQty: Decimal;
    begin
        // [SCENARIO 566077] Verify Warehouse Put Away must be created and registered for Item using Put Away Worksheet.
        // When Quantity is increased after Production Order is completely posted.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);

        // [GIVEN] Generate Random Quantity. 
        AddedProdOrderQty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), Location.Code, Bin.Code);

        // [GIVEN] Create and post the Output Journal.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, false, ProductionOrder.Quantity);

        // [WHEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", ProductionOrder.Quantity, "Whse. Activity Sorting Method"::None, false);

        // [THEN] Warehouse Activity must be created.
        WarehouseActivityLine.SetRange(Quantity, ProductionOrder.Quantity);
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Find Prod Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");
        ProdOrderLine.Validate(Quantity, ProdOrderLine.Quantity + AddedProdOrderQty);
        ProdOrderLine.Modify();

        // [GIVEN] Create and post the Output Journal.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, false, AddedProdOrderQty);

        // [WHEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", AddedProdOrderQty, "Whse. Activity Sorting Method"::None, false);

        // [THEN] Warehouse Activity must be created.
        WarehouseActivityLine.SetRange(Quantity, AddedProdOrderQty);
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLotPageHandler')]
    procedure VerifyWarehousePutAwayMustBeCreatedForItemWithLotNoTrackingWithAdditionalQtyUsingPutAwayWorksheet()
    var
        Bin: Record Bin;
        Item: Record Item;
        Location: Record Location;
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        ItemTrackingCode: Record "Item Tracking Code";
        WarehouseEmployee: Record "Warehouse Employee";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        AddedProdOrderQty: Decimal;
        LotNo1: Text;
        LotNo2: Text;
    begin
        // [SCENARIO 566092] Verify Warehouse Put Away must be created and registered for Item with Lot No. tracking using Put Away Worksheet.
        // When Quantity is increased after Production Order is completely posted.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Validate("Use Put-away Worksheet", true);
        Location.Modify(true);

        // [GIVEN] Generate Random Quantity. 
        AddedProdOrderQty := LibraryRandom.RandInt(10);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create Item Tracking Code and item with Lot No.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), Location.Code, Bin.Code);

        // [GIVEN] Create and post the Output Journal with Item Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, false, ProductionOrder.Quantity);
        LotNo1 := LibraryVariableStorage.DequeueText();

        // [WHEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", ProductionOrder.Quantity, "Whse. Activity Sorting Method"::None, false);

        // [THEN] Warehouse Activity must be created with Lot No. Lot1.
        WarehouseActivityLine.SetRange("Lot No.", LotNo1);
        WarehouseActivityLine.SetRange(Quantity, ProductionOrder.Quantity);
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Find Prod Order Line.
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.");
        ProdOrderLine.Validate(Quantity, ProdOrderLine.Quantity + AddedProdOrderQty);
        ProdOrderLine.Modify();

        // [GIVEN] Create and post the Output Journal with Item Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, false, AddedProdOrderQty);
        LotNo2 := LibraryVariableStorage.DequeueText();

        // [WHEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, Location.Code, Item."No.", Item."No.", AddedProdOrderQty, "Whse. Activity Sorting Method"::None, false);

        // [THEN] Warehouse Activity must be created with Lot No. Lot2.
        WarehouseActivityLine.SetRange("Lot No.", LotNo2);
        WarehouseActivityLine.SetRange(Quantity, AddedProdOrderQty);
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
        LibraryVariableStorage.Clear();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerNoText,ChangeStatusOnProdOrderOk')]
    procedure VerifyWarehousePutAwayMustBeCreatedForFamilyAndFlushingMethodForwardWhenStatusIsChanged()
    var
        Bin: Record Bin;
        Family: Record Family;
        Item: array[3] of Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        FamilyLine: array[3] of Record "Family Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        FirmPlannedProductionOrder: TestPage "Firm Planned Prod. Order";
    begin
        // [SCENARIO 566092] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order When "Source Type" is Family and "Flushing Method" is "Forward".
        // Warehouse Put Away must be created when Changing the status from Firm Planned to Released Production Order.
        Initialize();

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Validate("Use Put-away Worksheet", false);
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);

        // [GIVEN] Create Routing with Flushing Method.
        CreateRoutingWithFlushingMethodRouting(RoutingHeader, "Flushing Method Routing"::Forward);

        // [GIVEN] Create three items.
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItem(Item[3]);

        // [GIVEN] Create Family with three items.
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item[2]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[3], Family."No.", Item[3]."No.", 1);

        // [GIVEN] Update "Routing No." in Family. 
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        // [WHEN] Create and Refresh Production Order with "Source Type" Family.
        CreateAndRefreshProductionOrderWithSourceTypeFamily(ProductionOrder, ProductionOrder.Status::"Firm Planned", Family."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // [THEN] Verify Warehouse Put Away Request must not be created with Flushing Method Forward.
        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);

        // [GIVEN] Open Firm Planned Production Order.
        FirmPlannedProductionOrder.OpenEdit();
        FirmPlannedProductionOrder.GoToRecord(ProductionOrder);

        // [GIVEN] Invoke "Change Status" action.
        FirmPlannedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Production Order.
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, Family."No.");

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and Warehouse Put Away Request must be deleted.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Completely Put Away", ProductionOrder.TableCaption()));

        WarehousePutAwayRequest.SetRange("Document Type", WarehousePutAwayRequest."Document Type"::Production);
        WarehousePutAwayRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.RecordCount(WarehousePutAwayRequest, 0);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Production Orders V");
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Production Orders V");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        CreateLocationSetup();

        LibrarySetupStorage.SaveManufacturingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Production Orders V");
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);

        CreateAndUpdateLocation(LocationGreen, false, false, false, false);  // Location Green.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);

        CreateAndUpdateLocation(LocationRed, false, false, false, true);  // Location Red.
        LibraryWarehouse.CreateNumberOfBins(LocationRed.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        CreateAndUpdateLocation(LocationYellow, true, true, false, true);  // Location Yellow.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationYellow.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, false, RequireShipment);
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(Item2);

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateAndCertifiedProductionBOM(ProductionBOMHeader, Item2);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateAndCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshProductionOrderWithSourceTypeFamily(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[20]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Family, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure InsertProdOrderLineWithLocation(var ProductionOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; LineNo: Integer; LocationCode: Code[20])
    begin
        ProductionOrderLine.Init();
        ProductionOrderLine.Status := ProductionOrder.Status;
        ProductionOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProductionOrderLine."Line No." := LineNo;
        ProductionOrderLine.Insert();

        ProductionOrderLine.Validate("Item No.", ProductionOrder."Source No.");
        ProductionOrderLine.Validate("Location Code", LocationCode);
        ProductionOrderLine.Modify();
    end;

    local procedure CreateRoutingWithFlushingMethodRouting(var RoutingHeader: Record "Routing Header"; FlushingMethodRouting: Enum "Flushing Method Routing")
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithWorkCenterFlushingMethod(RoutingLine, RoutingHeader, FlushingMethodRouting);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingLineWithWorkCenterFlushingMethod(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; FlushingMethod: Enum "Flushing Method Routing"): Code[10]
    var
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);

        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        exit(RoutingLine."Operation No.")
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo, SourceDocument, ActionType);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument, ActionType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure CreatePutAwayFromPutAwayWorksheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; QuantityToHandle: Decimal; SortActivity: Enum "Whse. Activity Sorting Method"; BreakBulkFilter: Boolean)
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::"Put-away");
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePutAwayRequest.SetRange("Completely Put Away", false);
        WhsePutAwayRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetInboundSourceDocuments(WhsePutAwayRequest, WhseWorksheetName, LocationCode);
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplate.Name);
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetFilter("Item No.", ItemNo + '|' + ItemNo2);
        WhseWorksheetLine.FindFirst();

        if QuantityToHandle <> 0 then begin
            WhseWorksheetLine.Validate("Qty. to Handle", QuantityToHandle);
            WhseWorksheetLine.Modify(true);
        end;

        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, SortActivity, false, false, BreakBulkFilter);
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source Type", SourceType);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
    end;

    local procedure CreateAndPostOutputJournalWithItemTracking(ProductionOrderNo: Code[20]; SerialTracking: Boolean; LotTracking: Boolean; Quantity: Decimal)
    var
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        OutputJournalSetup(OutputItemJournalTemplate, OutputItemJournalBatch);
        CreateOutputJournalWithExplodeRouting(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ProductionOrderNo);
        ItemJournalLine.Validate(Quantity, Quantity);
        if SerialTracking or LotTracking then begin
            if LotTracking then
                LibraryVariableStorage.Enqueue(LotItemTrackingMode::AssignLot);
            if SerialTracking then
                LibraryVariableStorage.Enqueue(SerialItemTrackingMode::AssignSerial);

            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExplodeRouting(var ItemJournalLine: Record "Item Journal Line"; OutputItemJournalTemplate: Record "Item Journal Template"; OutputItemJournalBatch: Record "Item Journal Batch"; ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure OutputJournalSetup(var OutputItemJournalTemplate: Record "Item Journal Template"; var OutputItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerNoText(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure ChangeStatusOnProdOrderOk(var ChangeStatusOnProductionOrder: TestPage "Change Status on Prod. Order")
    begin
        ChangeStatusOnProductionOrder.Yes().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        SerialItemTrackingMode := DequeueVariable;
        case SerialItemTrackingMode of
            SerialItemTrackingMode::AssignSerial:
                ItemTrackingLines."Assign Serial No.".Invoke();
            SerialItemTrackingMode::SelectSerial:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.OK().Invoke();
                end;
        end;
    end;

    [ModalPageHandler]
    procedure ItemTrackingLotPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        Clear(LibraryVariableStorage);
        LotItemTrackingMode := DequeueVariable;
        case LotItemTrackingMode of
            LotItemTrackingMode::AssignLot:
                begin
                    ItemTrackingLines."Assign &Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value());
                end;
            LotItemTrackingMode::SelectLot:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines.OK().Invoke();
                end;
        end;
    end;

    [ModalPageHandler]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;
}