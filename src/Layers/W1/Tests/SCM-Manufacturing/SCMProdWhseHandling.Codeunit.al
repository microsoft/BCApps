// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Journal;
using System.TestLibraries.Utilities;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Manufacturing.Journal;
using Microsoft.Warehouse.Structure;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Request;
using Microsoft.Inventory.Posting;

codeunit 137298 "SCM Prod. Whse. Handling"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM] [Production] [Pick] [Put-away]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        ThereIsNothingToCreateMsg: Label 'There is nothing to create.';
        NothingToHandleMsg: Label 'Nothing to handle. The production components are completely picked or not eligible for picking.';
        CannotPostConsumptionMsg: Label 'You cannot post consumption for order no. %1 because a quantity of %2 remains to be picked.', Comment = '%1 - Production Order No., %2 - Quantity';
        PickActivitiesCreatedMsg: Label 'Number of Invt. Pick activities created';

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdConsumpAsNoWhseHandling_ThrowsNothingToCreateMsg()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        MessageShown: Text;
    begin
        // [SCENARIO] 'There is nothing to create' is shown when Production Consumption is set to 'No Warehouse Handling'.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick is run for the production order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] 'There is nothing to create' message is shown.'.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdConsumpAsInvtPickMovement_CreatesInventoryPickLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Production Consumption set to 'Inventory Pick/Movement' creates inventory pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick is run for the produciton order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        // [THEN] 2 inventory pick lines are created with 2 quantities each
        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdConsumpAsWhsePickMandatory_CreateInventoryPickLinesThrowsNothingToCreate()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        MessageShown: Text;
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (Mandatory)' shows 'Nothing to create' message when user tries to create inventory picks.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Inventory Pick document lines is run for the production order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] 'Nothing to create' message is shown.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdConsumpAsWhsePickOptional_CreatesWarehousePickLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (optional)' creates warehouse pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Warehouse Pick document lines is run for the Produciton Order.
        ProductionOrder.SetHideValidationDialog(true);
        ProductionOrder.CreatePick(UserId(), 0, false, false, false);

        // [THEN] 4 warehouse pick lines are created with 2 quantities each. 2 for Take and 2 for Place.
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdConsumpAsWhsePickMandatory_CreatesWarehousePickLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Production Consumption set to 'Mandatory (Mandatory)' creates warehouse pick lines for consumption.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Create Warehouse Pick document lines is run for the Produciton Order.
        ProductionOrder.SetHideValidationDialog(true);
        ProductionOrder.CreatePick(UserId(), 0, false, false, false);

        // [THEN] 4 warehouse pick lines are created with 2 quantities each. 2 for Take and 2 for Place.
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Take);

        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);

        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick,
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        VerifyPickLines(WarehouseActivityLine, Location.Code, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalHandlerWithQtyCheck')]
    procedure ProdConsumpAsWhsePickMandatory_ProductionJournalQtyIs0()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (Mandatory)' sets the qty to 0 on production journal.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Production Journal is open
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        LibraryVariableStorage.Enqueue(0); // Consumption
        LibraryVariableStorage.Enqueue(0); // Consumption
        LibraryVariableStorage.Enqueue(1); // Output
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Consumption Qty. is set to 0
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdOutputAsNoWhseHandling_CreateInventoryPutawayLinesThrowsNothingToCreate()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        MessageShown: Text;
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (Mandatory)' shows 'Nothing to create' message when user tries to create inventory picks.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        WhseOutputProdRelease.Release(ProductionOrder);

        // [WHEN] Create Inventory Pick document lines is run for the production order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", true, false, false);

        // [THEN] 'Nothing to create' message is shown.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdOutputAsInventoryPutaway_CreateInventoryPutawayLines()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
    begin
        // [SCENARIO] Production Consumption set to 'Warehouse Pick (Mandatory)' shows 'Nothing to create' message when user tries to create inventory picks.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"Inventory Put-away";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        WhseOutputProdRelease.Release(ProductionOrder);
        Commit();

        // [WHEN] Create Inventory Pick document lines is run for the production order.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place);

        // [THEN] 1 put-away line is created
        Assert.RecordCount(WarehouseActivityLine, 1);

        // [THEN] 1 put-away line is for the current location
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        Assert.RecordCount(WarehouseActivityLine, 1);

        // [THEN] Source Subtype is set to 'Released'
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Testfield("Source Subtype", 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingProdConsumptionRespectsOnlyProdConsumpWhseHandling()
    var
        ParentItem: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
    begin
        // [SCENARIO] Posting Production Consumption respects only 'Prod. Consump. Whse. Handling' property on Location.
        Initialize();

        // [GIVEN] Create Location with 5 bins and set Prod. Consump. Whse. Handling to 'No Warehouse Handling'.
        CreateLocationSetupWithBins(Location, false, false, true, true, true, 5, false);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);

        // [GIVEN] Create an production item with 2 components.
        CreateProdItemWithTwoComponents(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, '');
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, '');
        until Bin.Next() = 0;

        // [GIVEN] Create Released Produciton Order for 1 quantity of the parent item.
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ParentItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        WhseOutputProdRelease.Release(ProductionOrder);
        Commit();

        // [WHEN] Post Production Consumption for the Production Order.
        Bin.FindFirst();
        PostProductionJournal(ProductionOrder, Location.Code, Bin.Code);

        // [THEN] No error is thrown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickEnforcedWhenWarehousePickIsSet()
    begin
        // Throw error is "Prod. Consump. Whse. Handling" is set to "Warehouse Pick (mandatory)" and there is no pick.
        asserterror CreateAndPostProductionConsumption("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Assert.ExpectedError('remains to be picked.');

        // Allow posting usage if "Prod. Consump. Whse. Handling" is set to "Inventory Pick/Movement" and there is no pick.
        CreateAndPostProductionConsumption("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");

        // Creating and posting succeeds when "Prod. Consump. Whse. Handling" is set to "Warehouse Pick (optional)" or "No Warehouse Handling".
        CreateAndPostProductionConsumption("Prod. Consump. Whse. Handling"::"No Warehouse Handling");
        CreateAndPostProductionConsumption("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
    end;

    local procedure CreateAndPostProductionConsumption(ProdConsumpWhseHandling: Enum "Prod. Consump. Whse. Handling")
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Prod. consumption Posting fails if pick is mandatory.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := ProdConsumpWhseHandling;
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        //[WHEN] Consumption is posted.
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // [THEN] No error is thrown if "Prod. Consump. Whse. Handling" is not set to "Warehouse Pick (Mandatory)".
        // [THEN] Error is thrown if "Prod. Consump. Whse. Handling" is set to "Warehouse Pick (Mandatory)" and the caller validates the error thrown.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateProductionConsumptionAndCalcConsumption()
    begin
        // Production order for an item with 2 components with 2 qty. each is the test data
        CreateProductionConsumptionAndCalcConsumption(Enum::"Prod. Consump. Whse. Handling"::"No Warehouse Handling", 2, 2);
        CreateProductionConsumptionAndCalcConsumption(Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)", 2, 2);
        CreateProductionConsumptionAndCalcConsumption(Enum::"Prod. Consump. Whse. Handling"::"Inventory Pick/Movement", 2, 2);
        CreateProductionConsumptionAndCalcConsumption(Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", 2, 0); // Quantity is set to 0 if Warehouse Pick is mandatory.
    end;

    local procedure CreateProductionConsumptionAndCalcConsumption(ProdConsumpWhseHandling: Enum "Prod. Consump. Whse. Handling"; TotalConsumptionLines: Integer; ExpectedQuantity: Integer)
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Calculate consumption creates consumption line with 0 quantity if the Production Consumption Warehouse Handling is set to 'Warehouse Pick (Manatory)'
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with 2 components
        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := ProdConsumpWhseHandling;
        Location.Modify(true);

        //[WHEN] Consumption is calculated.
        CreateConsumptionJournal(ItemJournalLine, ProductionOrder."No.");

        // [THEN] Expected number of Consumption lines are created.
        Assert.RecordCount(ItemJournalLine, TotalConsumptionLines);

        // [THEN] Expected quantity is set on the consumption lines.
        ItemJournalLine.SetRange(Quantity, ExpectedQuantity);
        Assert.RecordCount(ItemJournalLine, TotalConsumptionLines);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalHandlerWithQtyCheckAndPost,ConfirmationHandlerYes,SimpleMessageHandler')]
    procedure ProdJnlPostSucceedsWhenProdOutputIsNoWhseHandlingAndRequirePutawayON()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Output qty. is set on Production Journal when 'Prod. Output Whe. Handling' is set to 'No Whse. Handling' and 'Require Put-away' is set to 
        // true on Location. Posting succeeds as well.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with no components
        CreateProductionOrderWithLocationBinsAndNoComponents(ProductionOrder, Location, Item);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Set 'Require Put-away' to true and 'Prod. Output Whse. Handling' to 'No Whse. Handling' on Location.
        Location.Validate("Require Put-away", true);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Production Order is Created
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [THEN] Output Qty. is set to 1
        LibraryVariableStorage.Enqueue(1); // Output

        // [WHEN] Production Journal is opened, validated and posted
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Posting succeeds and a message is shown to the user.
        Assert.ExpectedMessage('The journal lines were successfully posted.', LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalHandlerWithQtyCheckAndPost,ConfirmationHandlerYes,SimpleMessageHandler')]
    procedure ProdJnlPostSucceedsWhenProdOutputIsNoWhseHandlingAndRequirePutawayOFF()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Output qty. is set on Production Journal when 'Prod. Output Whe. Handling' is set to 'No Whse. Handling' and 'Require Put-away' is set to 
        // false on Location. Posting succeeds as well.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with no components
        CreateProductionOrderWithLocationBinsAndNoComponents(ProductionOrder, Location, Item);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Set 'Require Put-away' to false and 'Prod. Output Whse. Handling' to 'No Whse. Handling' on Location.
        Location.Validate("Require Put-away", false);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"No Warehouse Handling";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Production Order is Created
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [THEN] Output Qty. is set to 1
        LibraryVariableStorage.Enqueue(1); // Output

        // [WHEN] Production Journal is opened, validated and posted
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Posting succeeds and a message is shown to the user.
        Assert.ExpectedMessage('The journal lines were successfully posted.', LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalHandlerWithQtyCheckAndPost,ConfirmationHandlerYes,SimpleMessageHandler')]
    procedure ProdJnlPostFailsWhenProdOutputIsInventoryPutawayAndRequirePutawayOFF()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO] Output qty. is set to 0 on Production Journal when 'Prod. Output Whe. Handling' is set to 'Inventory Put-away' and 'Require Put-away' is set to 
        // false on Location. Posting fails and nothing to handle message is shown to the user.
        Initialize();

        // [GIVEN] Create needed setup with production order for a item with no components
        CreateProductionOrderWithLocationBinsAndNoComponents(ProductionOrder, Location, Item);
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindFirst();
        ProductionOrder.Validate("Bin Code", Bin.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Set 'Require Put-away' to false and 'Prod. Output Whse. Handling' to 'Inventory Put-away' on Location.
        Location.Validate("Require Put-away", false);
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"Inventory Put-away";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Production Order is Created
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);

        // [THEN] Output Qty. is set to 0
        LibraryVariableStorage.Enqueue(0); // Output

        // [WHEN] Production Journal is opened, validated and posted
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [THEN] Posting succeeds and a message is shown to the user.
        Assert.ExpectedMessage('There is nothing to post because the journal does not contain a quantity or amount.', LibraryVariableStorage.DequeueText());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure ProdOutputAsInventoryPutaway_CheckPutawaySource()
    var
        PutawayTemplateHeader: Record "Put-away Template Header";
        PutawayTemplateLine: Record "Put-away Template Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 481391] Check Source Document on inventory put-away created for production output.
        Initialize();

        // [GIVEN] Location with bin mandatory, put-away bin policy = put-away template, and set up for output posting via inventory put-away.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 2, false);
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Prod. Output Whse. Handling" := "Prod. Output Whse. Handling"::"Inventory Put-away";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Released production order at the location.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);
        Commit();

        // [WHEN] Create inventory put-away to post the output.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);

        // [THEN] Source document fields on the inventory put-away match the production order.
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.TestField("Source Type", Database::"Prod. Order Line");
        WarehouseActivityLine.Testfield("Source Subtype", 3);
        WarehouseActivityLine.TestField("Source No.", ProductionOrder."No.");

        // [THEN] The inventory put-away can be posted.
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        Item.Get(ProductionOrder."Source No.");
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure EnablingDisablingProdConsumpWhseHandlingOnLocation()
    var
        Item: Record Item;
        CompItem1: Record Item;
        CompItem2: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [SCENARIO] Cannot disable prod. consump. whse. handling on location if an inventory activity for prod. order component exists.
        Initialize();

        CreateProductionOrderWithLocationBinsAndTwoComponents(ProductionOrder, Location, Item, CompItem1, CompItem2);
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
        Location.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        Commit();
        asserterror Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"No Warehouse Handling");

        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        WarehouseActivityHeader.Delete(true);

        Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"No Warehouse Handling");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinishingProdOrderChecksConsumptionLocation()
    begin
        // [THEN] Production order finishes without any error
        FinishingProdOrderChecksConsumptionLocation("Prod. Consump. Whse. Handling"::"No Warehouse Handling");
        FinishingProdOrderChecksConsumptionLocation("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        FinishingProdOrderChecksConsumptionLocation("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");

        // [THEN] Production order does not finishe but throws an error.
        asserterror FinishingProdOrderChecksConsumptionLocation("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Assert.ExpectedError('must not be 0');
    end;

    procedure FinishingProdOrderChecksConsumptionLocation(ProdConsumpWhseHanling: Enum "Prod. Consump. Whse. Handling")
    var
        ParentItem, CompItem1, CompItem2 : Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        Initialize();

        // [GIVEN] Create Location with 5 bins where "Prod. Consump. Whse. Handling is set to the value passed.".
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);
        Location."Prod. Consump. Whse. Handling" := ProdConsumpWhseHanling;
        Location.Modify(true);

        // [GIVEN] Create an production item.
        LibraryInventory.CreateItem(ParentItem);

        // [GIVEN] Create 2 components with "Pick + Backward" flushing method.
        LibraryInventory.CreateItem(CompItem1);
        CompItem1.Validate("Flushing Method", "Flushing Method"::"Pick + Backward");
        CompItem1.Modify(true);

        LibraryInventory.CreateItem(CompItem2);
        CompItem2.Validate("Flushing Method", "Flushing Method"::"Pick + Backward");
        CompItem2.Modify(true);

        // [GIVEN] Create Production BOM with 2 components and assign it to the production item.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, CompItem1."No.", CompItem2."No.", 2);
        ParentItem."Production BOM No." := ProductionBOMHeader."No.";
        ParentItem."Replenishment System" := ParentItem."Replenishment System"::"Prod. Order";
        ParentItem.Modify(true);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, '');
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, '');
        until Bin.Next() = 0;

        // [GIVEN] Create Released Produciton Order for 1 quantity of the parent item.
        CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ParentItem."No.", 1, Location.Code);

        // [GIVEN] Create Output Item Journal Template and Batch.
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ParentItem."No.", ProductionOrder."No.");
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Validate("Output Quantity", 1);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post Output Journal without posting the consumption.
        LibraryManufacturing.PostOutputJournal();

        // [WHEN] Finish the Production Order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Caller validates the outcome.
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure NegativeConsumptionAsInventoryPutaway_CheckPutawaySource()
    var
        PutawayTemplateHeader: Record "Put-away Template Header";
        PutawayTemplateLine: Record "Put-away Template Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        xProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        // [SCENARIO 487478] Check Source Document on inventory put-away created for negative consumption. The put-away template is set up for finding a fixed bin.
        Initialize();

        // [GIVEN] Location with bin mandatory, put-away bin policy = put-away template, and set up for consumption posting via inventory pick.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, true, false, false, false, false, false);
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 2, false);
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Released production order at the location.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);

        // [GIVEN] Create prod. order component with negative quantity.
        LibraryInventory.CreateItem(Item);
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", -1);

        WhseProdRelease.ReleaseLine(ProdOrderComponent, xProdOrderComponent);

        // [WHEN] Create inventory put-away to post the negative consumption.
        Commit();
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", true, false, false);

        // [THEN] Source document fields on the inventory put-away match the production order.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.TestField("Source Type", Database::"Prod. Order Component");
        WarehouseActivityLine.Testfield("Source Subtype", 3);
        WarehouseActivityLine.TestField("Source No.", ProductionOrder."No.");

        // [THEN] The inventory put-away can be posted.
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure NegativeConsumptionAsInventoryPutaway_FloatingBin()
    var
        PutawayTemplateHeader: Record "Put-away Template Header";
        PutawayTemplateLine: Record "Put-away Template Line";
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        xProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseProdRelease: Codeunit "Whse.-Production Release";
    begin
        // [SCENARIO 487478] Check Source Document on inventory put-away created for negative consumption. The put-away template is set up for finding a floating bin.
        Initialize();

        // [GIVEN] Location with bin mandatory, put-away bin policy = put-away template, and set up for consumption posting via inventory pick.
        LibraryWarehouse.CreatePutAwayTemplateHeader(PutAwayTemplateHeader);
        LibraryWarehouse.CreatePutAwayTemplateLine(PutAwayTemplateHeader, PutAwayTemplateLine, false, true, false, false, false, false);
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 2, false);
        Location."Put-away Bin Policy" := Location."Put-away Bin Policy"::"Put-away Template";
        Location."Put-away Template Code" := PutAwayTemplateHeader.Code;
        Location."Prod. Consump. Whse. Handling" := "Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
        Location."Always Create Put-away Line" := true;
        Location.Modify(true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);

        // [GIVEN] Released production order at the location.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);

        // [GIVEN] Create prod. order component with negative quantity.
        LibraryInventory.CreateItem(Item);
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", -1);

        WhseProdRelease.ReleaseLine(ProdOrderComponent, xProdOrderComponent);

        // [WHEN] Create inventory put-away to post the negative consumption.
        Commit();
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", true, false, false);

        // [THEN] Source document fields on the inventory put-away match the production order.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away",
          Location.Code, WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.TestField("Source Type", Database::"Prod. Order Component");
        WarehouseActivityLine.Testfield("Source Subtype", 3);
        WarehouseActivityLine.TestField("Source No.", ProductionOrder."No.");

        // [THEN] The inventory put-away can be posted.
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickForwardFlushingBehaviorOnFirmToReleasedProdOrder()
    begin
        // https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/494761
        // Production order finishes without any error
        PickForwardFlushingBehaviorOnFirmToReleasedProdOrder("Prod. Consump. Whse. Handling"::"No Warehouse Handling");
        PickForwardFlushingBehaviorOnFirmToReleasedProdOrder("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        PickForwardFlushingBehaviorOnFirmToReleasedProdOrder("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");

        // Production order does not get released but throws an error.
        asserterror PickForwardFlushingBehaviorOnFirmToReleasedProdOrder("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Assert.ExpectedError('must not be 0');
    end;

    procedure PickForwardFlushingBehaviorOnFirmToReleasedProdOrder(ProdConsumpWhseHanling: Enum "Prod. Consump. Whse. Handling")
    var
        ParentItem, CompItem : Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        Location: Record Location;
        OpenShopFloorBin: Record Bin;
        ProductionOrder: Record "Production Order";
    begin
        Initialize();

        // [GIVEN] Create Location with 5 bins where "Prod. Consump. Whse. Handling is set to the value passed.".
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);
        OpenShopFloorBin.SetRange("Location Code", Location.Code);
        OpenShopFloorBin.FindFirst();
        Location."Prod. Consump. Whse. Handling" := ProdConsumpWhseHanling;
        Location.Validate("Open Shop Floor Bin Code", OpenShopFloorBin.Code);
        Location.Modify(true);

        // [GIVEN] Create an production item.
        LibraryInventory.CreateItem(ParentItem);

        // [GIVEN] Create a component with "Pick + Forward" flushing method.
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Flushing Method", "Flushing Method"::"Pick + Forward");
        CompItem.Modify(true);

        // [GIVEN] Create Production BOM with a component and assign it to the production item.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);
        ParentItem."Production BOM No." := ProductionBOMHeader."No.";
        ParentItem."Replenishment System" := ParentItem."Replenishment System"::"Prod. Order";
        ParentItem.Modify(true);

        // [GIVEN] Ensure necessary quantity of component is available on the Open Shop Floor bin.
        CreateAndPostItemJournalLine(CompItem."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, OpenShopFloorBin.Code, '');

        // [GIVEN] Create Form-Planned Produciton Order for 1 quantity of the parent item.
        CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::"Firm Planned", "Prod. Order Source Type"::Item, ParentItem."No.", 1, Location.Code);

        // [WHEN] Production Order is released.
        LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");

        // [THEN] Caller validates the outcome.
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure InventoryMovementProdComponentAfterPartialPick()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdBin, StorageBin : Record Bin;
        LotNo: Code[50];
    begin
        // [SCENARIO 542288] Inventory movement of production components with item tracking after partial movement.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Lot-tracked item "C".
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Location set up for required inventory pick for production consumption.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(ProdBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(StorageBin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        Location.Validate("To-Production Bin Code", ProdBin.Code);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Production order for 3 pcs of any item "A".
        // [GIVEN] Add item "C" as a component to the production order.
        // [GIVEN] NOTE! that the item "C" is not the first component on the list.
        CreateAndRefreshProductionOrder(
          ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, LibraryInventory.CreateItemNo(), 3, Location.Code);
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, LibraryInventory.CreateItemNo(), 1);
        CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item."No.", 1);
        ProdOrderComponent.Validate("Bin Code", ProdBin.Code);
        ProdOrderComponent.Modify(true);

        // [GIVEN] Post 1 pcs of item "C" with lot to the location.
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 1, Location.Code, StorageBin.Code, LotNo);

        // [GIVEN] Create inventory movement for the production consumption.
        // [GIVEN] Select lot no. and register the inventory movement.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Movement",
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Action Type");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo, true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Add 2 more pcs of item "C" with lot to the location.
        CreateAndPostItemJournalLine(Item."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 2, Location.Code, StorageBin.Code, LotNo);

        // [WHEN] Create the second inventory movement for the remaining 2 pcs of item "C".
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, false, true);

        // [THEN] The system suggests to move 2 pieces.
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Movement",
          Location.Code, WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.TestField(Quantity, 2);

        // [THEN] The second inventory movement can be registered.
        WarehouseActivityLine.SetRange("Action Type");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo, true);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler,WhseSrcCreateDocReqHandler')]
    procedure AllowConsumptionPostingForPickPlusManualFlushingWithoutWarehouseOrInventoryPickWhenNoWarehouseHandlingSelected()
    begin
        // [FEATURE] [Production Order] [Prod. Consump. Whse. Handling with Item Flusing Method Pick + Manual] 
        // [SCENARIO] Allow consumption posting without warehouse or inventory pick when 'No Warehouse Handling' is selected.
        Initialize();
        AllowConsumptionPostingForPickPlusManualFlushingWithoutWarehouseOrInventoryPick("Prod. Consump. Whse. Handling"::"No Warehouse Handling");
    end;

    local procedure AllowConsumptionPostingForPickPlusManualFlushingWithoutWarehouseOrInventoryPick(ProdConsumpWhseHandling: Enum "Prod. Consump. Whse. Handling")
    var
        CompItem, ProdItem : Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
        MessageShown: Text;
    begin
        // [GIVEN] Create Location "A" with specific "Prod. Consump. Whse. Handling" for production consumption. 
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Prod. Consump. Whse. Handling", ProdConsumpWhseHandling);
        Location.Modify(true);

        // [GIVEN] Component item "C" and production item "P" with pick + manual flushing.
        CreateProdItemWithOneComponentAndSpecificFlushing(ProdItem, CompItem, "Flushing Method"::"Pick + Manual");

        // [GIVEN] Post 100 pcs of item "C" to inventory at location "A".
        CreateAndPostItemJournalLine(CompItem."No.", Location.Code, LibraryRandom.RandIntInRange(100, 100));

        // [GIVEN] Create Released Production Order for 10 quantity of the parent item.
        CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item,
            ProdItem."No.", LibraryRandom.RandIntInRange(10, 10), Location.Code);

        // [GIVEN] Open Released Production Order Page
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);

        // [WHEN] Create Warehouse Pick for the production order.
        asserterror ReleasedProductionOrder."Create Warehouse Pick".Invoke();

        // [THEN] 'Nothing to handle' message is shown.'.
        Assert.IsTrue(StrPos(NothingToHandleMsg, GetLastErrorText()) > 0, '');

        // [GIVEN] Run Create Inventory PutAway/Pick/Movement to Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] 'There is nothing to create' message is shown.'.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);

        // [WHEN] Post consumption for the production order component.
        CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder."No.", CompItem."No.", ProductionOrder.Quantity);
        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

        // [THEN] Consumption Posted Item Ledger Entry exists for Component Item
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        FindLastItemLedgerEntry(ItemLedgerEntry, CompItem."No.", Location.Code, false);
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler,WhseSrcCreateDocReqHandler')]
    procedure AllowConsumptionPostingForPickPlusManualFlushingWithoutWarehouseOrInventoryPickWhenWarehousePickOptionalSelected()
    begin
        // [FEATURE] [Production Order] [Prod. Consump. Whse. Handling with Item Flusing Method Pick + Manual]  
        // [SCENARIO] Allow consumption posting without warehouse or inventory pick when 'Warehouse Pick (optional)' is selected.
        Initialize();

        // [GIVEN] Warehouse Pick (optional) - Post consumption with warehouse pick creation 
        AllowConsumptionPostingForPickPlusManualFlushingWithWarehousePickOptional("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)", true, true, false, false);

        // [GIVEN] Warehouse Pick (optional) - Posting consumption with warehouse pick posting 
        AllowConsumptionPostingForPickPlusManualFlushingWithWarehousePickOptional("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)", true, false, true, false);

        // [GIVEN] Warehouse Pick (optional) - Creating inventory pick not allowed
        AllowConsumptionPostingForPickPlusManualFlushingWithWarehousePickOptional("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)", false, false, false, true);
    end;

    local procedure AllowConsumptionPostingForPickPlusManualFlushingWithWarehousePickOptional(
        ProdConsumpWhseHandling: Enum "Prod. Consump. Whse. Handling"; PostConsumption: Boolean; CreateWhsePick: Boolean; WhsePickPosting: Boolean; CreateInvtPick: Boolean)
    var
        CompItem, ProdItem : Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        MessageShown: Text;
    begin
        // [GIVEN] Create Location "A" with specific "Prod. Consump. Whse. Handling" for production consumption. 
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Prod. Consump. Whse. Handling", ProdConsumpWhseHandling);
        Location.Modify(true);

        // [GIVEN] Component item "C" and production item "P" with pick + manual flushing.
        CreateProdItemWithOneComponentAndSpecificFlushing(ProdItem, CompItem, "Flushing Method"::"Pick + Manual");

        // [GIVEN] Post 100 pcs of item "C" to inventory at location "A".
        CreateAndPostItemJournalLine(CompItem."No.", Location.Code, LibraryRandom.RandIntInRange(100, 100));

        // [GIVEN] Create Released Production Order for 10 quantity of the parent item.
        CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item,
            ProdItem."No.", LibraryRandom.RandIntInRange(10, 10), Location.Code);

        // [GIVEN] Open Released Production Order Page
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);

        if CreateInvtPick then begin
            // [GIVEN] Run Create Inventory PutAway/Pick/Movement to Create Inventory Pick.
            LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

            // [THEN] 'There is nothing to create' message is shown.'.
            MessageShown := LibraryVariableStorage.DequeueText();
            Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
        end;

        // [WHEN] Create Warehouse Pick for the production order if required.
        if CreateWhsePick then begin
            // [WHEN] Create Warehouse Pick for the production order.
            ReleasedProductionOrder."Create Warehouse Pick".Invoke();
            Clear(WhseActivityLine);
            WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
            WhseActivityLine.SetRange("Item No.", CompItem."No.");
            WhseActivityLine.SetRange("Location Code", Location.Code);
            WhseActivityLine.FindFirst();
            LibraryVariableStorage.DequeueText();
        end;

        // [WHEN] Warehouse Pick can be posted.
        if WhsePickPosting then begin
            // [WHEN] Create Warehouse Pick for the production order.
            ReleasedProductionOrder."Create Warehouse Pick".Invoke();
            Clear(WhseActivityLine);
            WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
            WhseActivityLine.SetRange("Item No.", CompItem."No.");
            WhseActivityLine.SetRange("Location Code", Location.Code);
            WhseActivityLine.FindFirst();
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity);
            WhseActivityLine.Modify(true);

            // [THEN] Warehouse Pick can be posted.
            Clear(WhseActivityHeader);
            WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Pick");
            WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
            WhseActivityHeader.FindFirst();
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
            LibraryVariableStorage.DequeueText();
        end;

        // [THEN] Consumption should be Posted or not based on "Prod. Consump. Whse. Handling" selected for component item.
        if PostConsumption then begin
            // [WHEN] Post consumption for the production order component.
            CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder."No.", CompItem."No.", ProductionOrder.Quantity);
            Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

            // [THEN] Consumption Posted Item Ledger Entry exists for Component Item
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            FindLastItemLedgerEntry(ItemLedgerEntry, CompItem."No.", Location.Code, false);
        end;
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler,WhseSrcCreateDocReqHandler,CreateInvtPutawayPickMvmtDocReqHandler')]
    procedure AllowConsumptionPostingForPickPlusManualFlushingWithoutWarehouseOrInventoryPickWhenWarehousePickMandatorySelected()
    begin
        // [FEATURE] [Production Order] [Prod. Consump. Whse. Handling with Item Flusing Method Pick + Manual] 
        // [SCENARIO] Allow consumption posting without warehouse or inventory pick when 'Warehouse Pick (mandatory)' is selected.
        Initialize();

        // [GIVEN] Warehouse Pick (mandatory) - Posting consumption with warehouse pick posting
        AllowConsumptionPostingForPickPlusManualFlushingWithWarehousePickMandatory("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", true, false, true, false);

        // [GIVEN] Warehouse Pick (mandatory) - Posting consumption without warehouse pick posting should return as error
        AllowConsumptionPostingForPickPlusManualFlushingWithWarehousePickMandatory("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", false, true, false, false);

        // [GIVEN] Warehouse Pick (optional) - Creating inventory pick not allowed
        AllowConsumptionPostingForPickPlusManualFlushingWithWarehousePickMandatory("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", false, false, false, true);
    end;

    local procedure AllowConsumptionPostingForPickPlusManualFlushingWithWarehousePickMandatory(
            ProdConsumpWhseHandling: Enum "Prod. Consump. Whse. Handling"; PostConsumption: Boolean; CreateWhsePick: Boolean; WhsePickPosting: Boolean; CreateInvtPick: Boolean)
    var
        CompItem, ProdItem : Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        MessageShown: Text;
    begin
        // [GIVEN] Create Location "A" with specific "Prod. Consump. Whse. Handling" for production consumption. 
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Prod. Consump. Whse. Handling", ProdConsumpWhseHandling);
        Location.Modify(true);

        // [GIVEN] Component item "C" and production item "P" with pick + manual flushing.
        CreateProdItemWithOneComponentAndSpecificFlushing(ProdItem, CompItem, "Flushing Method"::"Pick + Manual");

        // [GIVEN] Post 100 pcs of item "C" to inventory at location "A".
        CreateAndPostItemJournalLine(CompItem."No.", Location.Code, LibraryRandom.RandIntInRange(100, 100));

        // [GIVEN] Create Released Production Order for 10 quantity of the parent item.
        CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item,
            ProdItem."No.", LibraryRandom.RandIntInRange(10, 10), Location.Code);

        // [GIVEN] Open Released Production Order Page
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);

        if CreateInvtPick then begin
            // [WHEN] Create Inventory Pick not allowed for the production order.  
            ReleasedProductionOrder."Create Inventor&y Put-away/Pick/Movement".Invoke();

            // [THEN] 'There is nothing to create' message is shown.'.
            MessageShown := LibraryVariableStorage.DequeueText();
            Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);
        end;

        // [WHEN] Create Warehouse Pick for the production order if required.
        if CreateWhsePick then begin
            // [WHEN] Create Warehouse Pick for the production order.
            ReleasedProductionOrder."Create Warehouse Pick".Invoke();
            Clear(WhseActivityLine);
            WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
            WhseActivityLine.SetRange("Item No.", CompItem."No.");
            WhseActivityLine.SetRange("Location Code", Location.Code);
            WhseActivityLine.FindFirst();
            LibraryVariableStorage.DequeueText();
        end;

        if WhsePickPosting then begin
            // [WHEN] Create Warehouse Pick for the production order.
            ReleasedProductionOrder."Create Warehouse Pick".Invoke();
            Clear(WhseActivityLine);
            WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::Pick);
            WhseActivityLine.SetRange("Item No.", CompItem."No.");
            WhseActivityLine.SetRange("Location Code", Location.Code);
            WhseActivityLine.FindFirst();
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine.Quantity);
            WhseActivityLine.Modify(true);

            Clear(WhseActivityHeader);
            WhseActivityHeader.SetRange(Type, WhseActivityHeader.Type::"Pick");
            WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
            WhseActivityHeader.FindFirst();
            LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
            LibraryVariableStorage.DequeueText();
        end;

        // [THEN] Consumption should be Posted or not based on "Prod. Consump. Whse. Handling" selected for component item.
        if PostConsumption then begin
            // [WHEN] Post consumption for the production order component.
            CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder."No.", CompItem."No.", ProductionOrder.Quantity);
            Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

            // [THEN] Consumption Posted Item Ledger Entry exists for Component Item
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            FindLastItemLedgerEntry(ItemLedgerEntry, CompItem."No.", Location.Code, false);
        end else begin
            // [WHEN] Post consumption for the production order component.
            asserterror CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder."No.", CompItem."No.", ProductionOrder.Quantity);

            // [THEN] 'You cannot post consumption for order no.' error message is shown.'.
            Assert.IsTrue(StrPos(GetLastErrorText(), StrSubstNo(CannotPostConsumptionMsg, ProductionOrder."No.", ProductionOrder.Quantity)) > 0, '');
        end;
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler,WhseSrcCreateDocReqHandler')]
    procedure AllowConsumptionPostingForPickPlusManualFlushingWithoutWarehouseOrInventoryPickWhenInventoryPickMovementSelected()
    begin
        // [FEATURE] [Production Order] [Prod. Consump. Whse. Handling with Item Flusing Method] 
        // [SCENARIO] Allow consumption posting without warehouse or inventory pick when 'Inventory Pick/Movement' is selected.
        Initialize();

        // [GIVEN] Inventory Pick/Movement - Posting consumption without inventory pick creation 
        AllowConsumptionPostingForPickPlusManualFlushingWithInventoryPick("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement", true, false, false);

        // [GIVEN] Inventory Pick/Movement - Posting consumption with inventory pick creation 
        AllowConsumptionPostingForPickPlusManualFlushingWithInventoryPick("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement", true, false, true);

        // [GIVEN] Inventory Pick/Movement - Warehouse pick creation should return an error
        AllowConsumptionPostingForPickPlusManualFlushingWithInventoryPick("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement", false, true, false);
    end;

    local procedure AllowConsumptionPostingForPickPlusManualFlushingWithInventoryPick(
        ProdConsumpWhseHandling: Enum "Prod. Consump. Whse. Handling"; PostConsumption: Boolean; CreateWhsePick: Boolean; CreateInvtPick: Boolean)
    var
        CompItem, ProdItem : Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
        MessageShown: Text;
    begin
        // [GIVEN] Create Location "A" with specific "Prod. Consump. Whse. Handling" for production consumption. 
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Prod. Consump. Whse. Handling", ProdConsumpWhseHandling);
        Location.Modify(true);

        // [GIVEN] Component item "C" and production item "P" with pick + manual flushing.
        CreateProdItemWithOneComponentAndSpecificFlushing(ProdItem, CompItem, "Flushing Method"::"Pick + Manual");

        // [GIVEN] Post 100 pcs of item "C" to inventory at location "A".
        CreateAndPostItemJournalLine(CompItem."No.", Location.Code, LibraryRandom.RandIntInRange(100, 100));

        // [GIVEN] Create Released Production Order for 10 quantity of the parent item.
        CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item,
            ProdItem."No.", LibraryRandom.RandIntInRange(10, 10), Location.Code);

        // [GIVEN] Open Released Production Order Page
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);

        if CreateInvtPick then begin
            // [GIVEN] Run Create Inventory PutAway/Pick/Movement to Create Inventory Pick.
            LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

            RegisterInventoryMovement(Location);

            // [THEN] Pick created message is shown.'.
            MessageShown := LibraryVariableStorage.DequeueText();
            Assert.IsTrue(StrPos(MessageShown, PickActivitiesCreatedMsg) > 0, '');
        end;

        // [WHEN] Create Warehouse Pick for the production order if required.
        if CreateWhsePick then begin
            // [WHEN] Create Warehouse Pick for the production order.
            asserterror ReleasedProductionOrder."Create Warehouse Pick".Invoke();
            Assert.IsTrue(StrPos(NothingToHandleMsg, GetLastErrorText()) > 0, '');
        end;

        // [THEN] Consumption should be Posted or not based on "Prod. Consump. Whse. Handling" selected for component item.
        if PostConsumption then begin
            // [WHEN] Post consumption for the production order component.
            CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder."No.", CompItem."No.", ProductionOrder.Quantity);
            Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

            // [THEN] Consumption Posted Item Ledger Entry exists for Component Item
            ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
            FindLastItemLedgerEntry(ItemLedgerEntry, CompItem."No.", Location.Code, false);
        end;
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure AllowConsumptionPostingForManualFlushingWithoutWarehouseOrInventoryPickWhenWarehousePickMandatorySelected()
    begin
        // [FEATURE] [Production Order] [Prod. Consump. Whse. Handling with Item Flusing Method Manual] 
        // [SCENARIO] Allow consumption posting without warehouse or inventory pick when 'Warehouse Pick (mandatory)' is selected.        
        Initialize();
#if not CLEAN26
        // [GIVEN] Force enable feature key Manufacturing_FlushingMethod_ActivateManualWoPick
        EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(true);
#endif

        AllowConsumptionPostingForManualFlushingWithoutWarehouseOrInventoryPick("Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
#if not CLEAN26
        EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(false);
#endif
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure AllowConsumptionPostingForManualFlushingWithoutWarehouseOrInventoryPickWhenWarehousePickOptionalSelected()
    begin
        // [FEATURE] [Production Order] [Prod. Consump. Whse. Handling with Item Flusing Method Manual] 
        // [SCENARIO] Allow consumption posting without warehouse or inventory pick when 'Warehouse Pick (optional)' is selected
        Initialize();
#if not CLEAN26
        // [GIVEN] Force enable feature key Manufacturing_FlushingMethod_ActivateManualWoPick
        EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(true);
#endif

        AllowConsumptionPostingForManualFlushingWithoutWarehouseOrInventoryPick("Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
#if not CLEAN26
        EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(false);
#endif
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure AllowConsumptionPostingForManualFlushingWithoutWarehouseOrInventoryPickWhenInventoryPickMovementSelected()
    begin
        // [FEATURE] [Production Order] [Prod. Consump. Whse. Handling with Item Flusing Method Manual] 
        // [SCENARIO] Allow consumption posting without warehouse or inventory pick when 'Inventory Pick/Movement' is selected.
        Initialize();
#if not CLEAN26
        // [GIVEN] Force enable feature key Manufacturing_FlushingMethod_ActivateManualWoPick
        EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(true);
#endif

        AllowConsumptionPostingForManualFlushingWithoutWarehouseOrInventoryPick("Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
#if not CLEAN26
        EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(false);
#endif
    end;

    [Test]
    [HandlerFunctions('SimpleMessageHandler')]
    procedure AllowConsumptionPostingForManualFlushingWarehouseOrInventoryPickWhenNoWarehouseHandlingSelected()
    begin
        // [FEATURE] [Production Order] [Prod. Consump. Whse. Handling with Item Flusing Method Manual] 
        // [SCENARIO] Allow consumption posting without warehouse or inventory pick when 'No Warehouse Handling' is selected.
        Initialize();
#if not CLEAN26
        // [GIVEN] Force enable feature key Manufacturing_FlushingMethod_ActivateManualWoPick
        EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(true);
#endif

        AllowConsumptionPostingForManualFlushingWithoutWarehouseOrInventoryPick("Prod. Consump. Whse. Handling"::"No Warehouse Handling");
#if not CLEAN26
        EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(false);
#endif
    end;

#if not CLEAN26
    local procedure EnableFeatureManufacturingFlushingMethodActivateManualWithoutPick(SetStatus: Boolean)
    var
        FeatureKeyManagement: Codeunit System.Environment.Configuration."Feature Key Management";
    begin
        FeatureKeyManagement.SetMockEnabledManufacturingFlushingMethodActivateManualWithoutPick(SetStatus);
    end;
#endif

    local procedure AllowConsumptionPostingForManualFlushingWithoutWarehouseOrInventoryPick(ProdConsumpWhseHandling: Enum "Prod. Consump. Whse. Handling")
    var
        CompItem, ProdItem : Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
        MessageShown: Text;
    begin
        // [GIVEN] Create Location "A" with specific "Prod. Consump. Whse. Handling" for production consumption. 
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Prod. Consump. Whse. Handling", ProdConsumpWhseHandling);
        Location.Modify(true);

        // [GIVEN] Component item "C" and production item "P" with manual flushing.
        CreateProdItemWithOneComponentAndSpecificFlushing(ProdItem, CompItem, "Flushing Method"::Manual);

        // [GIVEN] Post 100 pcs of item "C" to inventory at location "A".
        CreateAndPostItemJournalLine(CompItem."No.", Location.Code, LibraryRandom.RandIntInRange(100, 100));

        // [GIVEN] Create Released Production Order for 10 quantity of the parent item.
        CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item,
            ProdItem."No.", LibraryRandom.RandIntInRange(10, 10), Location.Code);

        // [GIVEN] Open Released Production Order Page
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GotoRecord(ProductionOrder);

        // [WHEN] Create Warehouse Pick for the production order.
        ReleasedProductionOrder."Create Warehouse Pick".Invoke();

        // [THEN] 'Nothing to handle' message is shown.'.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(NothingToHandleMsg, MessageShown);

        // [GIVEN] Run Create Inventory PutAway/Pick/Movement to Create Inventory Pick.
        LibraryWarehouse.CreateInvtPutPickMovement("Warehouse Request Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] 'There is nothing to create' message is shown.'.
        MessageShown := LibraryVariableStorage.DequeueText();
        Assert.ExpectedMessage(ThereIsNothingToCreateMsg, MessageShown);

        // [WHEN] Post consumption for the production order component.
        CreateConsumptionJournalLine(ItemJournalLine, ProductionOrder."No.", CompItem."No.", ProductionOrder.Quantity);
        Codeunit.Run(Codeunit::"Item Jnl.-Post Batch", ItemJournalLine);

        // [THEN] Consumption Posted Item Ledger Entry exists for Component Item
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        FindLastItemLedgerEntry(ItemLedgerEntry, CompItem."No.", Location.Code, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Prod. Whse. Handling");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Prod. Whse. Handling");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.CreateVATData();

        LibrarySetupStorage.SavePurchasesSetup();

        NoSeriesSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Prod. Whse. Handling");
    end;

    local procedure CreateConsumptionJournal(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    var
        ItemJournalBatchLoc: Record "Item Journal Batch";
        ItemJournalTemplateLoc: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplateLoc, ItemJournalTemplateLoc.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatchLoc, ItemJournalBatchLoc."Template Type"::Consumption, ItemJournalTemplateLoc.Name);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatchLoc."Journal Template Name", ItemJournalBatchLoc.Name);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatchLoc."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatchLoc.Name);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindFirst();
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalBatchLoc: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplateLoc: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplateLoc, ItemJournalTemplateLoc.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ItemJournalBatchLoc, ItemJournalBatchLoc."Template Type"::Consumption, ItemJournalTemplateLoc.Name);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatchLoc."Journal Template Name", ItemJournalBatchLoc.Name);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatchLoc."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatchLoc.Name);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.SetRange(Quantity, 0);
        if ItemJournalLine.FindSet(true) then begin
            ItemJournalLine.Validate(Quantity, 1);
            ItemJournalLine.Modify(true);
        end;

        ItemJournalLine.SetRange(Quantity);
        Assert.IsFalse(ItemJournalLine.IsEmpty(), 'Item Journal Line is empty.');
        LibraryInventory.PostItemJournalLine(ItemJournalBatchLoc."Journal Template Name", ItemJournalBatchLoc.Name);
    end;

    local procedure CreateProdItemWithTwoComponents(var ParentItem: Record Item; var CompItem1: Record Item; var CompItem2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(CompItem1);
        LibraryInventory.CreateItem(CompItem2);
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, CompItem1."No.", CompItem2."No.", 2);

        ParentItem."Production BOM No." := ProductionBOMHeader."No.";
        ParentItem."Replenishment System" := ParentItem."Replenishment System"::"Prod. Order";
        ParentItem.Modify(true);
    end;

    local procedure CreateProductionOrderWithLocationBinsAndTwoComponents(var ProductionOrder: Record "Production Order"; var Location: Record Location; var ParentItem: Record Item; var CompItem1: Record Item; var CompItem2: Record Item)
    var
        Bin: Record Bin;
    begin
        // [GIVEN] Create Location with 5 bins.
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);

        // [GIVEN] Create an production item with 2 components.
        CreateProdItemWithTwoComponents(ParentItem, CompItem1, CompItem2);

        // [GIVEN] Ensure all Bins have quantity 20 of the created item.
        Bin.SetRange("Location Code", Location.Code);
        Bin.FindSet(true);
        repeat
            CreateAndPostItemJournalLine(CompItem1."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, '');
            CreateAndPostItemJournalLine(CompItem2."No.", "Item Ledger Entry Type"::"Positive Adjmt.", 20, Location.Code, Bin.Code, '');
        until Bin.Next() = 0;

        // [GIVEN] Create Released Produciton Order for 1 quantity of the parent item.
        CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ParentItem."No.", 1, Location.Code);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ProdOrderStatus: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProdOrderStatus, SourceType, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; QtyPer: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Location Code", ProdOrderLine."Location Code");
        ProdOrderComponent.Validate("Quantity per", QtyPer);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateProductionOrderWithLocationBinsAndNoComponents(var ProductionOrder: Record "Production Order"; var Location: Record Location; var ProdItem: Record Item)
    begin
        // [GIVEN] Create Location with 5 bins.
        CreateLocationSetupWithBins(Location, false, false, false, false, true, 5, false);

        // [GIVEN] Create an production item with 2 components.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Modify(true);

        // [GIVEN] Create Released Produciton Order for 1 quantity of the parent item.
        LibraryManufacturing.CreateAndRefreshProductionOrder(ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, ProdItem."No.", 1);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
    end;

    local procedure VerifyPickLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; LocationCode: Code[10]; ExpectedPickLines: Integer)
    begin
        // [THEN] Expected number of pick lines are created
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);

        // [THEN] Expected number of pick lines are created
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);

        // [THEN] Bin is set
        WarehouseActivityLine.SetFilter("Bin Code", '<>%1', '');
        Assert.RecordCount(WarehouseActivityLine, ExpectedPickLines);
    end;

    local procedure FindFirstProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreateLocationSetupWithBins(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean; NoOfBins: Integer; UseBinRanking: Boolean)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NoOfBins, false); // Value required.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        if UseBinRanking then begin
            Bin.SetRange("Location Code", Location.Code);
            if Bin.FindSet() then
                repeat
                    Bin.Validate("Bin Ranking", LibraryRandom.RandIntInRange(100, 1000));
                    Bin.Modify(true);
                until Bin.Next() = 0;
        end;
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
        InventorySetup: Record "Inventory Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibraryInventory.NoSeriesSetup(InventorySetup);
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate1: Record "Item Journal Template"; var ItemJournalBatch1: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate1, ItemJournalTemplateType);
        ItemJournalTemplate1.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate1.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch1, ItemJournalTemplate1.Type, ItemJournalTemplate1.Name);
        ItemJournalBatch1.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch1.Modify(true);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch1: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch1.Validate("No. Series", NoSeries);
        ItemJournalBatch1.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; Quantity: Decimal;
                                                                                  LocationCode: Code[10];
                                                                                  BinCode: Code[20];
                                                                                  LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if LotNo <> '' then
            LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order"; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);

        ProductionJournalMgt.InitSetupValues();
        ProductionJournalMgt.SetTemplateAndBatchName();
        ProductionJournalMgt.CreateJnlLines(ProductionOrder, ProdOrderLine."Line No.");
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Document No.", ProductionOrder."No.");
        ItemJournalLine.ModifyAll("Location Code", LocationCode);
        ItemJournalLine.ModifyAll("Bin Code", BinCode);

        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.FindFirst();
        if ItemJournalLine."Quantity (Base)" = 0 then
            ItemJournalLine.ModifyAll("Quantity (Base)", 2);

        ItemJournalLine.SetRange("Entry Type");
        ItemJournalLine.FindFirst();

        CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
    end;

    local procedure RegisterInventoryMovement(Location: Record Location)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.Init();
        WarehouseActivityHeader.SetCurrentKey("Location Code");
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindLast();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        WarehouseActivityHeader."Registering No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        WarehouseActivityHeader.Modify(true);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CreateProdItemWithOneComponentAndSpecificFlushing(var ParentItem: Record Item; var CompItem: Record Item; FlushingMethod: Enum "Flushing Method")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(ParentItem);
        ParentItem.Validate("Flushing Method", FlushingMethod);
        ParentItem.Modify(true);

        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Flushing Method", FlushingMethod);
        CompItem.Modify(true);

        LibraryManufacturing.CreateProductionBOM(ProductionBOMHeader, ParentItem, CompItem, 1, '');
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateConsumptionJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalTemplateLoc: Record "Item Journal Template";
        ItemJournalBatchLoc: Record "Item Journal Batch";
    begin
        InitItemJournalBatch(ItemJournalBatchLoc, ItemJournalBatchLoc."Template Type"::Consumption);
        ItemJournalLine.Init();
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Consumption;

        ItemJournalTemplateLoc.Get(ItemJournalBatchLoc."Journal Template Name");
        LibraryInventory.CreateItemJnlLineWithNoItem(ItemJournalLine, ItemJournalBatchLoc, ItemJournalTemplateLoc.Name, ItemJournalBatchLoc.Name, ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderNo);
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Modify(true);
    end;

    local procedure InitItemJournalBatch(var ItemJournalBatchPar: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplateLoc: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplateLoc, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatchPar, TemplateType, ItemJournalTemplateLoc.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplateLoc, ItemJournalBatchPar);
    end;

    local procedure FindLastItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; LocationCode: Code[10]; IsPositive: Boolean)
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange(Positive, IsPositive);
        ItemLedgerEntry.FindLast();
    end;

    [RequestPageHandler]
    procedure CreateInvtPutawayPickMvmtDocReqHandler(var CreateInvtPutawayPickMvmtReqPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPickMvmtReqPage.CInvtPick.SetValue(true);
        CreateInvtPutawayPickMvmtReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure WhseSrcCreateDocReqHandler(var CreatePickReqPage: TestRequestPage "Whse.-Source - Create Document")
    begin
        CreatePickReqPage.DoNotFillQtytoHandle.SetValue(true);
        CreatePickReqPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandlerWithQtyCheck(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.First();
        repeat
            ProductionJournal.Quantity.AssertEquals(LibraryVariableStorage.DequeueInteger());
        until ProductionJournal.Next() = false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandlerWithQtyCheckAndPost(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.First();
        repeat
            ProductionJournal.Quantity.AssertEquals(LibraryVariableStorage.DequeueInteger());
        until ProductionJournal.Next() = false;

        ProductionJournal.Post.Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

