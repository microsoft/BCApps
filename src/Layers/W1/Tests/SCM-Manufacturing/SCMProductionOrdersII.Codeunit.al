// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Warehouse.Journal;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Inventory.Item;
using Microsoft.Warehouse.Structure;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Sales.Document;
using Microsoft.Manufacturing.Planning;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Ledger;
using System.Utilities;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Journal;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Customer;
using Microsoft.Foundation.NoSeries;

codeunit 137072 "SCM Production Orders II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        IsInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        RevaluationItemJournalTemplate: Record "Item Journal Template";
        RevaluationItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LocationGreen: Record Location;
        LocationRed: Record Location;
        LocationYellow: Record Location;
        LocationWhite: Record Location;
        LocationGreen2: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        ShopCalendarMgt: Codeunit "Shop Calendar Management";
        IsInitialized: Boolean;
        NothingToHandleErr: Label 'Nothing to handle';
        FieldValidationErr: Label '%1 must be %2.', Comment = '%1: Caption for the value under test, %2: Expected value';
        PickActivitiesCreatedMsg: Label 'Number of Invt. Pick activities created';
        FinishProductionOrderQst: Label 'Do you still want to finish the order?';
        StartingDateMsg: Label 'Starting Date must be less or equal.';
        EndingDateMsg: Label 'Ending Date must be greater or equal.';
        EntriesNotAffectedMsg: Label 'The change will not affect existing entries';
        RequisitionLineMustNotExistErr: Label 'Requisition Line must not exist for Item %1.', Comment = '%1: Item No.';
        ItemFilterLbl: Label '%1|%2', Locked = true;
        DeleteItemTrackingQst: Label 'has item reservation. Do you want to delete it anyway?';
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Update Quantity","Manual Lot No.";
        ProdOrderRtngLineNotUpdatedMsg: Label 'Prod. Order Routing Line is not updated.';
        CancelReservationTxt: Label 'Cancel reservation';
        PostingProductionJournalQst: Label 'Do you want to post the journal lines?';
        PostingProductionJournalTxt: Label 'The journal lines were successfully posted';
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
        IncorrectValueErr: Label 'Incorrect value of %1.%2.', Comment = '%1: Table name, %2: Field name.';
        ExpectedQuantityErr: Label 'Expected Quantity is wrong.';
        ActualTimeUsedErr: Label 'Actual time used on "Production Order Statistics" Page was incorrect. Should be equal to sum of "Setup Time", "Run Time" and "Stop Time".';
        ConfirmStatusFinishTxt: Label 'has not been finished:\\  * Some output is still missing.\\ Do you still want to finish the order?';
        TimeShiftedOnParentLineMsg: Label 'The production starting date-time of the end item has been moved forward because a subassembly is taking longer than planned.';
        DateConflictInReservErr: Label 'The change leads to a date conflict with existing reservations.';
        QuantityErr: Label '%1 must be %2 in %3', Comment = '%1: Quantity, %2: Consumption Quantity Value, %3: Item Ledger Entry';
        ILENoOfRecordsMustNotBeZeroErr: Label 'Item Ledger Entry No. of Records must not be zero.';
        ItemLedgerEntryMustBeFoundErr: Label 'Item Ledger Entry must be found.';
        ProductionBlockedOutputItemErr: Label 'You cannot produce %1 %2 because the %3 is %4 on the %1 card.', Comment = '%1 - Table Caption (Item), %2 - Item No., %3 - Field Caption, %4 - Field Value';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        InvalidProdOutputHandlingErr: Label 'You cannot select %1 on %2 %3 when %4 is enabled.', Comment = '%1 = Inventory Put-away, %2 = Location Table Caption, %3 = Location Code, %4 = Directed Put-away Field Caption';
        PutAwayActivityNoHasBeenCreatedMsg: Label 'Put-away activity no. %1 has been created.', Comment = '%1 = Put-away Activity No. ';
        ProductionJournalPostedTxt: Label 'The journal lines were successfully posted.';
        ProductionOrderCannotBeReopenedErr: Label 'This production order cannot be reopened because one or more production order lines have no posted output.';
        FieldMustBeEnabledErr: Label '%1 must be enabled in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        FieldMustBeVisibleErr: Label '%1 must be visible in Page %2', Comment = '%1 = Field Caption , %2 = Page Caption';
        WhseActivityHeaderMustBeFoundErr: Label 'Warehouse Activity Header must be found.';
        RegisteredWhseActivityHdrMustBeFoundErr: Label 'Registered Whse. Activity Hdr. must be found.';
        DocumentPutAwayStatusErr: Label 'Document Put-away Status must be %1 in %2', Comment = '%1 = Document Put-away Status value, %2 = Production Order Table';
        PutAwayLinesActionMustBeVisibleErr: Label 'Put-away Lines action must be Visible.';
        PutAwayLinesActionMustBeEnabledErr: Label 'Put-away Lines action must be Enabled.';
        RegPutAwayLinesActionMustBeVisibleErr: Label 'Registered Put-away Lines action must be Visible.';
        RegPutAwayLinesActionMustBeEnabledErr: Label 'Registered Put-away Lines action must be Enabled.';
        ThereIsNothingToCreateErr: Label 'There is nothing to create.';
        CostAmtNonInvtblMustNotBeZeroErr: Label '%1 must not be 0 in %2', Comment = '%1 = Cost Amount (Non-Invtbl.) Caption, %2 = Item Ledger Entry Table';
        LotNoMustBeEqualErr: Label '%1 must be equal to %2 in %3', Comment = '%1 = Lot No. Caption, %2 = Expected Lot No., %3 = Warehouse Activity Line Table';
        ProdOrderLineErr: Label 'Production Order should have two lines for variant-based BOM structure.';

    [Test]
    [Scope('OnPrem')]
    procedure FinishedQuantityOnProductionOrderLineWithoutTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Production Order] [Warehouse]
        // [SCENARIO] Verify Finished Quantity is correct after posting Output and finishing the Production Order on Location with Bins.

        // Setup: Update Components at a Location. Create parent and child Items in a Production BOM and certify it. Update Inventory for child Item. Create and refresh a Released Production Order.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandInt(100);  // Large Random Value required for Test.
        CreateItemsSetup(Item, Item2);
        CreateAndPostItemJournalLine(Item2."No.", Quantity, Bin.Code, LocationRed.Code, false);  // Using Tracking FALSE.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationRed.Code, Bin.Code);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Create and post Consumption with Tracking FALSE.

        // Exercise: Create and post Output Journal for the Production Order. Change Status from Released to Finished.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Use Tracking FALSE.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Status from Released to Finished.

        // Verify: Verify the Finished Quantity after posting Output and finishing the Production Order.
        FindProductionOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.TestField("Finished Quantity", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdComponentAndPostOutputWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and refresh a Released Production Order. Reserve Component.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationGreen.Code);
        Quantity := LibraryRandom.RandInt(100);
        CreateItemsSetupWithProductionAndTracking(Item, Item2, ProductionOrder, Quantity, LocationGreen.Code);
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation();  // Invokes ReservationHandler.

        // Exercise: Create and post the Output Journal with Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, Quantity);

        // Verify: Verify the Item Ledger Entry for the Output posted with Tracking.
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item2."No.", Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ReservationHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderComponentReservationWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for child Item with Tracking. Create and refresh a Released Production Order.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationGreen.Code);
        Quantity := LibraryRandom.RandInt(100);  // Large Random Value required for Test.
        CreateItemsSetupWithProductionAndTracking(Item, Item2, ProductionOrder, Quantity, LocationGreen.Code);

        // Exercise: Reserve Production Order Component.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation();  // Invokes ReservationHandler.

        // Verify: Verify the Reserved Quantity on Production Order Component.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Released, Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostConsumptionAndOutputWithLotTrackingAndFinishedProductionOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO] Verify the Item Ledger Entry for Output and Tracking after finishing Production Order with tracked Items.

        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for child Item with Tracking. Create and refresh a Released Production Order.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationGreen.Code);
        Quantity := LibraryRandom.RandInt(100);  // Large Random Value required for Test.
        CreateItemsSetupWithProductionAndTracking(Item, Item2, ProductionOrder, Quantity, LocationGreen.Code);

        // Create and post Consumption and Output Journal with Tracking.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", true);  // Use Tracking TRUE.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, Quantity);  // Use Tracking TRUE.

        // Exercise: Change status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify that Production Order Status is successfully changed to Finished. Verify the Item Ledger Entry for Output and Tracking.
        VerifyProductionOrder(ProductionOrder, ProductionOrder.Status::Finished, ProductionOrder.Quantity, WorkDate());
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item2."No.", Quantity, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWithHandlingErrorFromProductionOrderWithBin()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Update Components at a Location. Create parent and child Items in a Production BOM and certify it. Update Inventory for Items. Create and refresh a Released Production Order.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, Item2);
        CreateAndPostItemJournalLine(Item2."No.", 100, Bin.Code, LocationRed.Code, false);  // Using Tracking FALSE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // Exercise: Create Pick from Released Production Order.
        asserterror LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // Verify: Verify that Pick is not created.
        Assert.ExpectedError(NothingToHandleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionWithLocationAndBin()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        Initialize();
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, Item2);
        CreateAndPostItemJournalLine(Item2."No.", 100, Bin.Code, LocationRed.Code, false);  // Using Tracking FALSE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), LocationRed.Code, Bin.Code);

        // Exercise: Create and post Consumption.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Using Tracking FALSE.

        // Verify: Verify the posted Consumption.
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, Item2."No.", -ProductionOrder.Quantity, false);  // Use Tracking FALSE.
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnPlannedProductionOrderComponent()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Items, create Production BOM. Create and release Purchase Order and post as Receive and Invoice. Create a Planned Production Order.
        Initialize();
        CreateItemsSetup(Item, Item2);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item2."No.", Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Planned, Item."No.", Quantity, '', '');

        // Exercise: Reserve Components on Planned Production Order.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation();  // Invokes ReservationHandler.

        // Verify: Verify that Quantity is not reserved.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Planned, Item2."No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderWithLocation()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create parent and child Items and update Inventory for child Item. Create Production BOM and certify it.
        Initialize();
        CreateItemsSetup(Item, Item2);

        // Exercise: Create and refresh Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item2."No.", LibraryRandom.RandDec(100, 2), LocationGreen.Code, '');

        // Verify: Verify that Firm Planned Production Order Line is updated with correct Location Code and correct Quantity.
        FindProductionOrderLine(ProdOrderLine, Item2."No.");
        ProdOrderLine.TestField("Location Code", LocationGreen.Code);
        ProdOrderLine.TestField(Quantity, ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromProductionOrderWithLotTracking()
    begin
        // Verify the Inventory Pick is created from Released Production Order with Lot Tracking and Bins.
        // Setup.
        Initialize();
        WarehouseActivityFromProductionOrderWithLotTracking(false);  // Post Inventory Pick FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostedPartialInventoryPickFromProductionOrderWithLotTracking()
    begin
        // Verify that Inventory Pick is posted successfully from Released Production Order with Lot Tracking, Partial quantity and Bins.
        // Setup.
        Initialize();
        WarehouseActivityFromProductionOrderWithLotTracking(true);  // Post Inventory Pick TRUE.
    end;

    local procedure WarehouseActivityFromProductionOrderWithLotTracking(PostInventoryPick: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for child Item with Tracking. Create and refresh a Released Production Order.
        LibraryManufacturing.SetComponentsAtLocation(LocationYellow.Code);
        LibraryWarehouse.FindBin(Bin, LocationYellow.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemSetupWithLotTracking(Item, Item2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, Bin.Code, LocationYellow.Code, true);  // Using Tracking TRUE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationYellow.Code, Bin.Code);

        // Exercise: Create Inventory Pick from the Released Production Order.
        LibraryVariableStorage.Enqueue(PickActivitiesCreatedMsg);  // Enqueue variable required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
        if PostInventoryPick then begin
            // Auto fill Quantity To Handle for whole Quantity. Update Lot No and partial quantity on Whse Activity Line and post Inventory Pick.
            WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
            UpdateQuantityAndLotNoOnWarehouseActivityLine(
              Item."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Quantity / 2);
            FindWarehouseActivityHeader(
              WarehouseActivityHeader, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption",
              WarehouseActivityLine."Action Type"::Take);
            LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Invoice False.
        end;

        if PostInventoryPick then
            // Verify: Verify that Inventory Pick posted successfully with partial Quantity and Lot Tracking.
            VerifyPostedInventoryPickLine(ProductionOrder."No.", Item."No.", Bin.Code, Quantity / 2, LocationYellow.Code)
        else
            // Verify that Inventory Pick created successfully.
            VerifyWarehouseActivityLine(
            ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Item."No.", Quantity,
            WarehouseActivityLine."Action Type"::Take);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanFirmPlannedProductionOrderWithRouting()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Create and refresh a Firm Planned Production Order.
        Initialize();
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Exercise: Replan Production Order.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // Verify: Verify the Input Quantity remains same on Replan Production Order.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Input Quantity", ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure PartialAutoReservationOnSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Inventory for the Item.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '', '', false);  // Using Tracking FALSE.

        // Exercise: Create and release a Sales Order with partial reservation.
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item."No.", Quantity / 2, '');  // Partial Auto Reservation.

        // Verify: Verify the Quantity reserved on Sales Line.
        VerifyReservationQtyOnSalesLine(SalesHeader."No.", Quantity / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterWarehousePickFromProductionOrderWithComponent()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
        AlwaysCreatePickLine: Boolean;
    begin
        // Setup: Update Location Setup, update Components at Location. Create parent and child Items in a Production BOM and certify it. Update Inventory for Child Item. Create and refresh a Released Production Order.
        // Create Warehouse Pick from the Released Production Order.
        Initialize();
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        LibraryManufacturing.SetComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);  // Integer value required.
        CreateItemsSetup(Item, Item2);
        UpdateInventoryWithWhseItemJournal(Item2, LocationWhite, Quantity);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // Exercise: Update Bin on Warehouse Activity Line. Register the Pick created.
        UpdateBinCodeOnWarehouseActivityLine(ProductionOrder."No.");
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // Verify: Verify that Pick is registered successfully.
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", Item2."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Take);
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", Item2."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Place);

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionWithProductionOrderAfterRegisterPick()
    begin
        // Verify the Item Ledger Entry for the consumption posted after register Warehouse Pick from Production Order.
        // Setup.
        Initialize();
        PostJournalsWithProductionOrder(false);  // Post Output -FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputWithProductionOrderWarehousePick()
    begin
        // Verify the Item Ledger Entry for the Output posted after register Warehouse Pick from Production Order.
        // Setup.
        Initialize();
        PostJournalsWithProductionOrder(true);  // Post Output -TRUE.
    end;

    local procedure PostJournalsWithProductionOrder(PostOutput: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        AlwaysCreatePickLine: Boolean;
    begin
        // Update Components at a Location. Create parent and child Items in a Production BOM and certify it. Update Inventory for child Item. Create and refresh a Released Production Order, create and register Pick from it.
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        LibraryManufacturing.SetComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);  // Integer value required.
        CreateItemsSetup(Item, Item2);
        UpdateInventoryWithWhseItemJournal(Item2, LocationWhite, Quantity);
        CreateAndRegisterPickWithProductionOrderSetup(ProductionOrder, LocationWhite, Item."No.", Quantity);

        // Exercise: Post Consumption for the Production Order.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Create and post Consumption with Tracking FALSE.

        if PostOutput then begin
            // Create and post Output Journal.
            CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Use Tracking FALSE.

            // Verify: Verify the Item Ledger Entry for the Output and Consumption posted after register Warehouse Pick from Production Order.
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item."No.", Quantity, false);  // Use Tracking FALSE.
        end else
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, Item2."No.", -Quantity, false);  // Use Tracking FALSE.

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustItemCostWithProductionOrderAndWarehouseActivity()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production] [Warehouse]
        // [SCENARIO] Verify the Item Ledger Entry after Adjust Cost Item Entries is run with consumption posted with Production Order.

        // Setup.
        Initialize();
        ItemsWithProductionOrderAndWarehouseActivity(false);  // Calculate Inventory -FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InventoryValueWithProductionOrderAndWarehouseActivity()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Revaluation] [Production] [Warehouse]
        // [SCENARIO] Verify the Revaluation Journal Line after Calculate Inventory is run with consumption and output posted with Production Order.

        // Setup.
        Initialize();
        ItemsWithProductionOrderAndWarehouseActivity(true);  // Calculate Inventory -TRUE.
    end;

    local procedure ItemsWithProductionOrderAndWarehouseActivity(InventoryValue: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        AlwaysCreatePickLine: Boolean;
    begin
        // Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and refresh a Released Production order.
        AlwaysCreatePickLine := UpdateLocationSetup(LocationWhite, true);  // Always Create Pick Line as TRUE.
        LibraryManufacturing.SetComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100);  // Integer value required.
        CreateItemsSetup(Item, Item2);
        UpdateInventoryWithWhseItemJournal(Item2, LocationWhite, Quantity);
        CreateAndRegisterPickWithProductionOrderSetup(ProductionOrder, LocationWhite, Item."No.", Quantity);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Use Tracking FALSE.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Use Tracking FALSE.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Exercise: Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item2."No.", '');

        if InventoryValue then begin
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, RevaluationItemJournalTemplate.Name, RevaluationItemJournalBatch.Name, ItemJournalLine."Entry Type",
              Item2."No.", 0);
            CalculateInventoryValue(Item2);

            // Verify:
            VerifyRevaluationJournalLine(Item2."No.", Quantity);
        end else
            VerifyItemLedgerEntryCostAmountActual(
              ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", Quantity * Item2."Unit Cost", LocationWhite.Code);

        // Tear Down.
        UpdateLocationSetup(LocationWhite, AlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputPostFromReleasedProductionOrderWithLocation()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it. Create and post Purchase Order as Receive and Invoice. Create and refresh a Released Production Order.
        Initialize();
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, ChildItem);
        CreateAndPostPurchaseOrderWithLocationAndBin(PurchaseLine, ChildItem."No.", LocationRed.Code, Bin.Code);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", PurchaseLine.Quantity, LocationRed.Code, Bin.Code);

        // Exercise: Create and post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, PurchaseLine.Quantity);  // Use Tracking FALSE.

        // Verify: Verify the Location Code in Item Ledger Entry for the posted Output. Verify the Cost Amount Actual as Zero without Adjust Cost.
        VerifyItemLedgerEntryCostAmountActual(ItemJournalLine."Entry Type"::Output, Item."No.", 0, LocationRed.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryForConsumptionAfterAdjustCostWithProductionOrder()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production] [Warehouse]
        // [SCENARIO] Verify Item Ledger Entry Cost Amount is correct after posting Consumption of Released Production Order (with Bins used) and run Adjust Cost.

        // Setup: Update Components at a Location. Create parent and child Items in a Production BOM and certify it. Create and post Purchase Order as Receive and Invoice. Create and refresh a Released Production Order.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationRed.Code);
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, ChildItem);
        UpdateUnitCostOnItem(ChildItem);
        CreateAndPostPurchaseOrderWithLocationAndBin(PurchaseLine, ChildItem."No.", LocationRed.Code, Bin.Code);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", PurchaseLine.Quantity, LocationRed.Code, Bin.Code);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Create and post Consumption with Tracking FALSE.

        // Exercise: Adjust Cost Item Entries.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Verify the Consumption Entry for the Child Item in Item Ledger Entry after Cost adjustment.
        VerifyItemLedgerEntryCostAmountActual(
          ItemJournalLine."Entry Type"::Consumption, ChildItem."No.", -PurchaseLine.Quantity * ChildItem."Unit Cost", LocationRed.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure FinishedProductionOrderForLessOutputWithLocationAndBin()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production] [Warehouse]
        // [SCENARIO] Verify that Status can be changed to Finished for Released Production Order, when Output is posted (Order uses Location with Bins).

        // Setup: Create parent and child Items in a Production BOM and certify it. Create and post Item  Journal. Create and refresh a Released Production Order.
        Initialize();
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetup(Item, ChildItem);
        CreateAndPostItemJournalLine(ChildItem."No.", 100, Bin.Code, LocationRed.Code, false);  // Use Tracking FALSE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), LocationRed.Code, Bin.Code);

        // Create and post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, ProductionOrder.Quantity);  // Use Tracking FALSE.

        // Exercise: Change Production Order Status from Released to Finished.
        LibraryVariableStorage.Enqueue(FinishProductionOrderQst);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the Status successfully changed to Finished.
        VerifyProductionOrder(ProductionOrder, ProductionOrder.Status::Finished, ProductionOrder.Quantity, WorkDate());
        ProductionOrder.TestField("Location Code", LocationRed.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputPostFromReleasedProductionOrderWithoutLocation()
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify the Output Quantity posted from Released Production Order without Location.

        // Setup.
        Initialize();
        JournalsPostFromReleasedProductionOrderWithoutLocation(false);  // Adjust Cost Item Entries FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryForOutputAfterAdjustCostWithReleasedProductionOrder()
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Production]
        // [SCENARIO] Verify the Output Entry for the Parent Item in Item Ledger Entry after Cost adjustment from Released Production Order without Location.

        // Setup.
        Initialize();
        JournalsPostFromReleasedProductionOrderWithoutLocation(true);  // Adjust Cost Item Entries TRUE.
    end;

    local procedure JournalsPostFromReleasedProductionOrderWithoutLocation(AdjustCost: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Create parent and child Items in a Production BOM and certify it. Update Inventory for child Item. Create and refresh a Released Production Order.
        CreateItemsSetup(Item, ChildItem);
        UpdateUnitCostOnItem(ChildItem);
        Quantity := LibraryRandom.RandInt(100);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity, '', '', false);  // Use Tracking FALSE.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, '', '');
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Create and post Consumption with Tracking FALSE.

        // Exercise: Create and post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Use Tracking FALSE.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Status from Released to Finished.
        if AdjustCost then
            // Adjust Cost Item Entries.
            LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Verify the Output Entry for the Parent Item in Item Ledger Entry after Cost Adjustment. Verify the Output posted.
        if AdjustCost then
            VerifyItemLedgerEntryCostAmountActual(ItemJournalLine."Entry Type"::Output, Item."No.", Quantity * ChildItem."Unit Cost", '') // Cost for the Parent Item calculated from the Child Item.
        else
            VerifyItemLedgerEntryCostAmountActual(ItemJournalLine."Entry Type"::Output, Item."No.", 0, '');  // The Cost Amount Actual is zero without Adjust Cost.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionPostFromReleasedProductionOrderWithoutLocation()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it. Update Inventory of Child Item. Create and refresh a Released Production Order.
        Initialize();
        CreateItemsSetup(Item, ChildItem);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(100) + 100, '', '', false);  // Using Tracking FALSE. Large Quantity required for positive Inventory.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), '', '');

        // Exercise: Create and Post Consumption.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Use Tracking FALSE.

        // Verify: Verify the Item Ledger Entry for the Posted Consumption without Location.
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Consumption, ChildItem."No.", -ProductionOrder.Quantity, false);  // Use Tracking FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProductionOrderWithFamily()
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        FamilyItemQuantity: Decimal;
    begin
        // Setup: Create parent and child Items for a Family. Update Inventory for child Items. Create a Family.
        Initialize();
        FamilyItemQuantity := LibraryRandom.RandDec(10, 2);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2);
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);

        // Exercise: Create and refresh a Released Production Order.
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", FamilyItemQuantity);

        // Verify: Verify the Production Order Lines.
        FindProductionOrderLine(ProdOrderLine, ParentItem."No.");
        ProdOrderLine.TestField(Quantity, FamilyItemQuantity * FamilyItemQuantity);  // Production Order Quantity calculated from Family Item Quantity.
        FindProductionOrderLine(ProdOrderLine, ParentItem2."No.");
        ProdOrderLine.TestField(Quantity, FamilyItemQuantity * FamilyItemQuantity);  // Production Order Quantity calculated from Family Item Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActualCostOnFinishedProductionOrderStatisticsPageForFamily()
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
        FamilyItemQuantity: Decimal;
        ActualCost: Decimal;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Cost Amount is correct on Finished Production Order which source is Family, and Consumption and Output is posted.

        // Setup: Create parent and child Items for a Family. Update Inventory for child Items. Create a Family. Create and refresh a Released Production Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2) + 100;  // Large Quantity required for positive Inventory.
        FamilyItemQuantity := LibraryRandom.RandInt(10);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2);
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", FamilyItemQuantity);

        // Create and post Consumption and Output journals.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Using Tracking FALSE.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Using Tracking FALSE.

        // Exercise: Change Production Order Status from Released to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the correct Actual Cost Amount on Finished Production Order Statistics page.
        ActualCost := FamilyItemQuantity * (FamilyItemQuantity * ChildItem."Unit Cost" + FamilyItemQuantity * ChildItem2."Unit Cost");
        VerifyCostAmountActualOnFinishedProductionOrderStatisticsPage(ProductionOrder."No.", ActualCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ActualCapactiyNeedOnFinishedProductionOrderCalculatedCorrectly()
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
        RoutingHeader: Record "Routing Header";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ReleasedProdOrderPage: TestPage "Released Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        Quantity: Integer;
        SetupTime: Integer;
        RunTime: Integer;
        StopTime: Integer;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Actual Time Used in "Production Order Statistics" is correct after posting Output Journal with setup time, run time and stop time.
        // Created for bug 443592: The actual capacity Need in the production order statistics Card shows an incorrect result
        Initialize();
        Quantity := LibraryRandom.RandInt(10) + 10;
        SetupTime := LibraryRandom.RandInt(10) + 10;
        RunTime := LibraryRandom.RandInt(10) + 10;
        StopTime := LibraryRandom.RandInt(10) + 10;

        // [GIVEN] WorkCenter with routing
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Parent and Child Items in with Production BOM and routing
        CreateItemsSetup(ParentItem, ChildItem);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Validate("Routing No.", RoutingHeader."No.");
        ParentItem.Modify(true);

        // [GIVEN] Inventory of child item we create a Production Order (released) for ParentItem and refresh it
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(100) + 100, '', '', false);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Output journal is posted (creating Capacity Ledger Entries)
        CreateAndPostOutputJournal(ProductionOrder."No.", Quantity, SetupTime, RunTime, StopTime);

        // [THEN] The "Production Order Statistics" page shows the correct time used (by summing the created Capacity Ledger Entries)
        ReleasedProdOrderPage.OpenEdit();
        ReleasedProdOrderPage.FILTER.SetFilter("No.", ProductionOrder."No.");
        ProductionOrderStatistics.Trap();
        ReleasedProdOrderPage.Statistics.Invoke();
        Assert.AreEqual(SetupTime + RunTime + StopTime, ProductionOrderStatistics.ActTimeUsed.AsInteger(), ActualTimeUsedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostConsumptionForReleasedProductionOrderWithFamily()
    begin
        // Verify the correct Item Ledger entries for the Consumption posted for the Production Order using Items in a Family.
        // Setup.
        Initialize();
        PostConsumptionAndOutputForReleasedProductionOrderWithFamily(false);  // Post Output FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputForReleasedProductionOrderWithFamily()
    begin
        // Verify the correct Item Ledger entries for the Output posted for the Production Order using Items in a Family.
        // Setup.
        Initialize();
        PostConsumptionAndOutputForReleasedProductionOrderWithFamily(true);  // Post Output TRUE.
    end;

    local procedure PostConsumptionAndOutputForReleasedProductionOrderWithFamily(PostOutput: Boolean)
    var
        ParentItem: Record Item;
        ParentItem2: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Family: Record Family;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        FamilyItemQuantity: Decimal;
    begin
        // Create parent and child Items for a Family. Update Inventory for child Items. Create a Family. Create and refresh a Released Production Order.
        Quantity := LibraryRandom.RandDec(100, 2) + 100;  // Large Quantity required for positive Inventory.
        FamilyItemQuantity := LibraryRandom.RandInt(10);
        CreateItemHierarchyForFamily(ParentItem, ParentItem2, ChildItem, ChildItem2);
        CreateFamily(Family, ParentItem."No.", ParentItem2."No.", FamilyItemQuantity);
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", FamilyItemQuantity);

        // Exercise: Create and post Consumption Journal for the Production Order.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Using Tracking FALSE.
        if PostOutput then
            // Create and post Output Journal for the Production Order.
            CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);  // Using Tracking FALSE.

        // Verify: Verify the Item Ledger Entries for the posted Output of Parent Items. Verify the Consumption Entries for the Posted Consumption.
        if PostOutput then begin
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, ParentItem."No.", Quantity, false);  // Using Tracking FALSE.
            VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, ParentItem2."No.", FamilyItemQuantity * FamilyItemQuantity, false);  // Using Tracking FALSE.
        end else begin
            VerifyItemLedgerEntry(
              ItemJournalLine."Entry Type"::Consumption, ChildItem."No.", -FamilyItemQuantity * FamilyItemQuantity, false);  // Using Tracking FALSE.
            VerifyItemLedgerEntry(
              ItemJournalLine."Entry Type"::Consumption, ChildItem2."No.", -FamilyItemQuantity * FamilyItemQuantity, false);  // Using Tracking FALSE.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingQuantityWithMultipleProductionOrderComponents()
    begin
        // Verify the total Remaining Quantity on Production Order Component with multiple Components.
        // Setup.
        Initialize();
        RemainingQuantityOnProductionOrderComponents(false);  // Delete Production Order Component FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingQuantityAfterDeleteProductionComponent()
    begin
        // Verify the total Remaining Quantity on Production Order Components is correct when deleting one Production Order Component.
        // Setup.
        Initialize();
        RemainingQuantityOnProductionOrderComponents(true);  // Delete Production Order Component TRUE.
    end;

    local procedure RemainingQuantityOnProductionOrderComponents(DeleteComponent: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Create parent and multiple child Items in a Production BOM and certify it. Update Inventory of Child Items. Create and refresh a Released Production Order.
        CreateProdBOMSetupMultipleComponents(Item, ChildItem, ChildItem2);
        CreateAndPostItemJournalLine(ChildItem."No.", 100, '', '', false);  // Using Tracking FALSE.
        CreateAndPostItemJournalLine(ChildItem2."No.", 100, '', '', false);  // Using Tracking FALSE.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), '', '');

        // Exercise: Calculate Consumption.
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        if DeleteComponent then begin
            // Delete First Production Order Compnent and Calculate Consumption.
            DeleteProductionOrderComponent(ProductionOrder."No.");
            LibraryManufacturing.CalculateConsumption(
              ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        end;

        // Verify: Verify total Remaining Quantity on Production Order Component is reduced after deleting Component. Verify total Remaining Quantity on Production Order Component.
        if DeleteComponent then
            VerifyRemainingQuantityOnProdOrderComponents(
              ProductionOrder."No.", ProductionOrder.Status::Released, ChildItem2."No.", ProductionOrder.Quantity)
        else
            VerifyRemainingQuantityOnProdOrderComponents(
              ProductionOrder."No.", ProductionOrder.Status::Released, ChildItem."No.", ProductionOrder.Quantity + ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingOnAllocatedCapacityForFirmPlannedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item.
        Initialize();
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the Routing and Work Center on Production Order Allocated Capacity.
        VerifyRoutingOnAllocatedCapacity(ProductionOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingOnAllocatedCapacityForFirmPlannedProductionOrderAfterCalcPlanAndCarryOut()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Setup: Create parent and child Items, create Production BOM. Update Planning parameters on Item. Create Routing Setup and update Routing on Item. Create and release Sales Order.
        Initialize();
        CreateItemsSetup(Item, Item2);
        UpdateItemParametersForPlanning(Item);
        CreateRoutingAndUpdateItem(Item);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2));

        // Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessage(Item."No.");

        // Verify: Verify the Routing and Work Center on Production Order Allocated Capacity.
        FilterFirmPlannedProductionOrder(ProductionOrder, Item."No.");
        VerifyRoutingOnAllocatedCapacity(ProductionOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAheadQuantityForFirmPlannedProdOrderAfterCalcPlanAndCarryOut()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Item2: Record Item;
        SendAheadQuantity: Decimal;
    begin
        // Setup: Create parent and child Items, create Production BOM. Update Planning parameters on Item. Create Routing Setup and update Routing on Item. Update Send Ahead Quantity on Routing Line. Create and release a Sales Order.
        Initialize();
        CreateItemsSetup(Item, Item2);
        UpdateItemParametersForPlanning(Item);
        CreateRoutingAndUpdateItem(Item);
        SendAheadQuantity := LibraryRandom.RandDec(100, 2);
        UpdateRoutingLineSendAheadQty(Item."Routing No.", SendAheadQuantity);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", LibraryRandom.RandDec(100, 2));

        // Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessage(Item."No.");

        // Verify: Verify the Send Ahead Quantity and Routing on Production Order Routing Line.
        FilterFirmPlannedProductionOrder(ProductionOrder, Item."No.");
        VerifyProductionOrderRoutingLine(ProductionOrder."No.", Item."Routing No.", SendAheadQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAheadQuantityForFirmPlannedProductionOrderWithRouting()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        SendAheadQuantity: Decimal;
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Update Send Ahead Quantity on Routing Line.
        Initialize();
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);
        SendAheadQuantity := LibraryRandom.RandDec(100, 2);
        UpdateRoutingLineSendAheadQty(Item."Routing No.", SendAheadQuantity);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the Send Ahead Quantity and Routing on Production Order Routing Line.
        VerifyProductionOrderRoutingLine(ProductionOrder."No.", Item."Routing No.", SendAheadQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingDateOnRoutingAfterProdOrderRefreshSchedulingBack()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Create a Firm Planned Production Order.
        Initialize();
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(100, 2) + 100);  // Large Quantity required.

        // Exercise: Refresh Firm Planned Production Order with Scheduling Direction Back.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Verify: Verify that the Starting Date is less than or equal to the Due Date on Production Order Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine."Starting Date" <= ProductionOrder."Due Date", StartingDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EndingDateOnRoutingAfterProdOrderRefreshSchedulingForward()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Setup: Create parent and child Items, create Production BOM. Create Routing Setup and update Routing on Item. Create a Firm Planned Production Order.
        Initialize();
        CreateItemsSetup(Item, Item2);
        CreateRoutingAndUpdateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(100, 2) + 1000);  // Large Quantity required.

        // Exercise: Refresh Firm Planned Production Order with Scheduling Direction Forward.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // Verify: Verify that the Ending Date is greater than or equal to the Due Date on Production Order Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        Assert.IsTrue(ProdOrderRoutingLine."Ending Date" >= ProductionOrder."Due Date", EndingDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineAfterCalculateRegenPlan()
    begin
        // Verify that the Input Quantity on Planning Routing Line is same as Quantity on Requisition Line.
        // Setup.
        Initialize();
        PlanningRoutingLineAfterCalculatePlan(false);  // Update Quantity on Requisition Line FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningRoutingLineWithUpdatedReqLineAfterCalculateRegenPlan()
    begin
        // Verify that the Input Quantity on Planning Routing Line is same as Quantity on Requisition Line after update Quantity on Requisition Line and refresh it.
        // Setup.
        Initialize();
        PlanningRoutingLineAfterCalculatePlan(true);  // Update Quantity on Requisition Line TRUE.
    end;

    local procedure PlanningRoutingLineAfterCalculatePlan(UpdateRequisitionLine: Boolean)
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Create Parent and Child Items in a Production BOM with Routing. Update Planning parameters on Item. Create and release Sales Order.
        CreateItemsSetup(Item, ChildItem);
        UpdateItemParametersForPlanning(Item);
        CreateRoutingAndUpdateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity);

        // Exercise: Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        FindRequisitionLine(RequisitionLine, Item."No.");
        if UpdateRequisitionLine then begin
            // Update Quantity On Requisition Line and refresh the Planning Line.
            UpdateQuantityOnRequisitionLine(RequisitionLine, 2 * Quantity);  // Change Quantity on Requisition Line.
            LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Backward, true, true);
        end;

        // Verify: Verify the Input Quantity on Planning Routing Line is same as the Quantity on Requisition Line.
        VerifyInputQuantityOnPlanningRoutingLine(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineFirmPlannedProdOrderAfterCalcRegenPlanAndCarryOut()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ChildItem: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
    begin
        // Setup: Create Parent and Child Items in a Production BOM with Routing. Update Planning parameters on Item. Create and release Sales Order.
        Initialize();
        CreateItemsSetup(Item, ChildItem);
        UpdateItemParametersForPlanning(Item);
        CreateRoutingAndUpdateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity);

        // Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Exercise: Accept and Carry Out Action Message.
        AcceptAndCarryOutActionMessage(Item."No.");

        // Verify: Verify the Production Order Quantity and Input Quantity on Prod Order Routing Line is same as Initial Sales Order Quantity.
        FilterFirmPlannedProductionOrder(ProductionOrder, Item."No.");
        ProductionOrder.TestField(Quantity, Quantity);
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Input Quantity", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterCalculateRegenPlan()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Planning Parameters for Item. Create and release a Sales Order.
        Initialize();
        CreateLotForLotItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity);

        // Exercise: Calculate Regenerative Plan on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify Reservation Entry for the Item after Calculate Plan.
        VerifyReservationEntry(Item."No.", Quantity, ReservationEntry."Reservation Status"::Tracking, false, true);  // Positive Reservation Entry TRUE.
        VerifyReservationEntry(Item."No.", -Quantity, ReservationEntry."Reservation Status"::Tracking, false, false);  // Positive Reservation Entry FALSE.
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryForProdOrderReservationAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Update Planning Parameters for Item. Create and release a Sales Order.
        Initialize();
        CreateLotForLotItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);

        // Exercise: Reserve Production Order Line created.
        FindProductionOrderLine(ProdOrderLine, Item."No.");
        ProdOrderLine.ShowReservation();  // Invokes ReservationHandler.

        // Verify: Verify the Reservation Entry after Reservation On Production Order Line.
        VerifyReservationEntry(Item."No.", Quantity, ReservationEntry."Reservation Status"::Reservation, false, true);  // Positive Reservation Entry TRUE.
        VerifyReservationEntry(Item."No.", -Quantity, ReservationEntry."Reservation Status"::Reservation, false, false);  // Positive Reservation Entry FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationEntryAfterAssignTrackingOnProdOrderWithCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // Setup: Create Parent and Child Items in a Production BOM with Lot Tracking. Update Planning parameters on Parent Item. Create and release a Sales Order.
        Initialize();
        CreateItemSetupWithLotTracking(ChildItem, Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateItemParametersForPlanning(Item);
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);

        // Exercise: Assign Lot Tracking on Production Order created.
        FindProductionOrderLine(ProdOrderLine, Item."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Assign Lot No.
        ProdOrderLine.OpenItemTrackingLines();  // Invokes ItemTrackingPageHandler.

        // Verify: Verify the Reservation Entry after assign Lot Tracking on Production Order Line.
        VerifyReservationEntry(Item."No.", Quantity, ReservationEntry."Reservation Status"::Tracking, true, true);  // Positive Reservation Entry and Tracking TRUE.
        VerifyReservationEntry(Item."No.", -Quantity, ReservationEntry."Reservation Status"::Tracking, false, false);  // Positive Reservation Entry and Tracking FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineAfterRoutingLinkCodeUpdateOnRoutingLine()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingLinkCode: Code[20];
    begin
        // Setup: Create Parent and Child Items. Create Certified Production BOM with Routing Link Code for Child Items. Create Production Item with Routing.
        Initialize();
        CreateItemsSetup(Item, ChildItem);
        RoutingLinkCode := CreateRoutingAndUpdateItem(Item);

        // Exercise: Create and Refresh a Released Production Order.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the Production Order Routing Line is populated with Routing Link Code from Routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Routing Link Code", RoutingLinkCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeOutputPostedForProductionOrderWithMultipleComponents()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create parent and child Items in a Production BOM with Routing and certify it. Create and refresh a Released Production Order.
        Initialize();
        CreateItemsSetup(Item, ChildItem);
        CreateRoutingAndUpdateItem(Item);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Exercise: Create and post negative Output for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, -ProductionOrder.Quantity);  // Use Tracking FALSE.

        // Verify: Verify the negative Output Entry for the posted Output in Item Ledger Entry.
        VerifyItemLedgerEntry(ItemJournalLine."Entry Type"::Output, Item."No.", -ProductionOrder.Quantity, false);  // Using Tracking FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationEntryForPickAndReleasedProductionOrderAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO] Verify that tracking Reservation Entries are there and correct after Warehouse Pick created from Released Production Order, which is a supply to demanded Sales Order, respectively planned and carried out.

        // Setup: Update Components at Location. Create Parent and Child Items in a Production BOM and certify it. Update Item Planning Parameters. Update Inventory for Child Item. Create and release a Sales Order. Calculate Plan and Carry Out Action.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationGreen2.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemsSetup(Item, ChildItem);
        UpdateItemParametersForPlanning(Item);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity, '', LocationGreen2.Code, false);  // Using Tracking FALSE.
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);
        ProductionOrderNo := ChangeStatusFromFirmPlannedToReleased(Item."No.");  // Change Status from Firm Planned to Released.

        // Exercise: Create Pick from Production Order.
        CreatePickFromReleasedProductionOrder(ProductionOrderNo);

        // Verify: Verify the Reservation Entry after Create Pick from Production Order.
        VerifyReservationEntry(Item."No.", Quantity, ReservationEntry."Reservation Status"::Tracking, false, true);  // Positive Reservation Entry TRUE.
        VerifyReservationEntry(Item."No.", -Quantity, ReservationEntry."Reservation Status"::Tracking, false, false);  // Positive Reservation Entry FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseActivityLineForReleasedProductionOrderAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Warehouse]
        // [SCENARIO] Verify the Pick is created successfully for the Child Item, when Production Order is a supply for Sales Order demand, respectively planned and carried out.

        // Setup: Update Components at Location. Create Parent and Child Items in a Production BOM and certify it. Update Item Planning Parameters. Update Inventory for Child Item. Create and release a Sales Order. Calculate Plan and Carry Out Action.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateLotForLotItemSetupWithInventoryOnLocation(Item, ChildItem, LocationWhite, Quantity);
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);
        ProductionOrderNo := ChangeStatusFromFirmPlannedToReleased(Item."No.");  // Change Production Order Status from Firm Planned to Released.

        // Exercise: Create Pick from Production Order.
        CreatePickFromReleasedProductionOrder(ProductionOrderNo);

        // Verify: Verify the Pick is created successfully for the Child Item.
        VerifyWarehouseActivityLine(
          ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", ChildItem."No.", Quantity,
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(
          ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", ChildItem."No.", Quantity,
          WarehouseActivityLine."Action Type"::Place);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickFromReleasedProductionOrderAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Warehouse]
        // [SCENARIO] Verify the Registered Pick for the Child Item, when: Production Order is a supply for Sales Order demand, respectively planned and carried out, then Pick created, then Bin Code updated, then Registered.

        // Stup: Update Components at Location. Create Parent and Child Items in a Production BOM and certify it. Update Item Planning Parameters. Update Inventory for Child Item. Create and release a Sales Order. Calculate Plan and Carry Out Action.
        Initialize();
        LibraryManufacturing.SetComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateLotForLotItemSetupWithInventoryOnLocation(Item, ChildItem, LocationWhite, Quantity);
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);
        ProductionOrderNo := ChangeStatusFromFirmPlannedToReleased(Item."No.");  // Change Production Order Status from Firm Planned to Released.
        CreatePickFromReleasedProductionOrder(ProductionOrderNo);  // Create Pick from Released Production Order.

        // Exercise: Update Bin on Warehouse Activity Line. Register the Pick created.
        UpdateBinCodeOnWarehouseActivityLine(ProductionOrderNo);
        RegisterWarehouseActivity(
          ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // Verify: Verify the Registered Pick for the Child Item.
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrderNo, ChildItem."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Take);
        VerifyRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrderNo, ChildItem."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Place);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPlannedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ChildItem: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create Parent and Child Items in a Production BOM. Update Order Tracking Policy on Item. Create and release Sales Order.
        Initialize();
        CreateItemsSetup(Item, ChildItem);
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking Only");
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", Quantity);

        // Exercise: Create and refresh a Planned Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Planned, Item."No.", Quantity, '', '');

        // Verify: Verify the ItemNo and Quantity on Order Tracking Page.
        VerifyOrderTrackingForProductionOrder(Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForFirmPlannedProductionOrderAfterCalculatePlanAndCarryOutAction()
    var
        Item: Record Item;
        ChildItem: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Create Parent and Child Items in a Production BOM. Update Planning parameters on Item.
        Initialize();
        CreateItemsSetup(Item, ChildItem);
        UpdateOrderTrackingPolicyOnItem(Item, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        UpdateItemParametersForPlanning(Item);
        Quantity := LibraryRandom.RandDec(100, 2);

        // Exercise: Create Demand, calculate Plan and Carry Out Action Message.
        CreateDemandForCalculatePlanAndCarryOutAction(Item."No.", Quantity);

        // Verify: Verify the ItemNo and Quantity on Order Tracking Page.
        VerifyOrderTrackingForProductionOrder(Item."No.", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineAfterCalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem()
    begin
        // Verify the Location, Action Message and Quantity on Requisition Line created.
        // Setup.
        Initialize();
        CalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem(false);  // Accept and Carry Out Action FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineAfterCalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem()
    begin
        // Verify the Location Code and Quantity on Purchase Line created.
        // Setup.
        Initialize();
        CalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem(true);  // Accept and Carry Out Action TRUE.
    end;

    local procedure CalcPlanReqWkshWithLocationAndSKUMaximumQuantityItem(AcceptAndCarryOutAction: Boolean)
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create item with Reordering Policy. Create StockKeeping Unit for Location. Update Inventory for Item. Create and post Sales Order with Item Maximum Quantity.
        CreateMaximumQtyItem(Item, LibraryRandom.RandDec(100, 2) + 100);  // Large Quantity required for Item Maximum Inventory.
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationGreen.Code, Item."No.", '');
        CreateAndPostItemJournalLine(Item."No.", Item."Maximum Inventory", '', LocationGreen.Code, false);  // Using Tracking FALSE.
        CreateAndPostSalesOrderWithUpdatedQuantityToShip(
          Item, Item."Maximum Inventory" + LibraryRandom.RandDec(10, 2), LocationGreen.Code);  // Large Quantity required.

        // Exercise: Calculate Plan for Requisition Worksheet on WORKDATE. Accept and Carry Out Requisition Worksheet.
        CalculatePlanForRequisitionWorksheet(Item);
        if AcceptAndCarryOutAction then
            AcceptAndCarryOutActionMessageForRequisitionWorksheet(Item."No.");

        // Verify: Verify the Location Code and Quantity on Purchase Line created.
        if AcceptAndCarryOutAction then
            VerifyLocationAndQuantityOnPurchaseLine(Item."No.", LocationGreen.Code, Item."Maximum Inventory")
        else
            // Verify the Location, Action Message and Quantity on Requisition Line created.
            VerifyRequisitionLine(Item."No.", RequisitionLine."Action Message"::New, Item."Maximum Inventory", LocationGreen.Code);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionLineComponentItemAfterCalcRegenPlanOnPlanningWkshWithMRP()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine2: Record "Requisition Line";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        Quantity: Decimal;
    begin
        // Setup: Create Lot for Lot Items in a Production BOM and certify it. Update Inventory for the Parent Item. Create and post Sales Order.
        Initialize();
        CreateLotForLotItemsSetup(Item, ChildItem);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '', '', false);  // Using Tracking FALSE.
        CreateSalesOrder(SalesHeader, SalesLine, ChildItem."No.", Quantity, '');
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship only.

        // Set to calculate MPS
        LibraryVariableStorage.Enqueue(false);

        // Exercise: Calculate Regenerative Plan with MRP - TRUE for Planning Worksheet through CalculatePlanPlanWkshRequestPageHandler.
        CalcRegenPlanForPlanningWorksheetPage(PlanningWorksheet, ChildItem."No.", ChildItem."No.", false);

        // Verify: Verify the Action Message and Quantity on Requisition Line for Child Item. Verify that Requisition Line is not created for Parent Item.
        VerifyRequisitionLine(ChildItem."No.", RequisitionLine."Action Message"::New, Quantity, '');
        FilterRequisitionLine(RequisitionLine2, Item."No.");
        Assert.IsTrue(RequisitionLine2.IsEmpty, StrSubstNo(RequisitionLineMustNotExistErr, Item."No."));
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler,CarryOutActionMessageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderWithParentAndChild()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // Setup: Create Parent and Child Items. Create Sales Order for Parent Item.
        Initialize();
        CreateBomItemsWithReorderingPolicy(ParentItem, ChildItem);
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", LibraryRandom.RandInt(10), '');

        // Set to calculate MPS
        LibraryVariableStorage.Enqueue(true);

        // Exercise: Carry Out Planning Worksheet as Firm Planned Production Order.
        CalcRegenPlanForPlanningWorksheetPage(PlanningWorksheet, ParentItem."No.", ChildItem."No.", true);

        // Verify Parent and Child items are carried out into one Firm Planned Production Order.
        FilterFirmPlannedProductionOrder(ProductionOrder, ParentItem."No.");
        FindProductionOrderLine(ProdOrderLine, ChildItem."No.");
        ProductionOrder.TestField("No.", ProdOrderLine."Prod. Order No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure FinishProdOrderWithExistingItemTrackingEntry()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Production order can be finished with existing item tracking entries.

        // Setup: Create Item with Lot Tracking No. Create and refresh Releashed Production Order, assign Item Tracking on Prod. Order Line.
        Initialize();
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode());
        CreateRleasedProdOrderWithItemTracking(ProductionOrder, Item."No.", ItemTrackingMode::"Assign Lot No.");

        // Create Output Journal for Production Order and reduce the quantity on Journal Line.
        CreateAndPostOutputJnlWithUpdateQtyAndItemTracking(ProductionOrder."No.", ProductionOrder.Quantity / 2); // 2 is not important, just to get a partial quantity

        // Exercise: Change Production Order Status from Released to Finished.
        // Verify: No error pops up.
        LibraryVariableStorage.Enqueue(FinishProductionOrderQst); // Enqueue for Confirm Handler
        LibraryVariableStorage.Enqueue(DeleteItemTrackingQst); // Enqueue for Confirm Handler
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify the Quantity and Finished Quantity on Finished Production Order Line.
        VerifyProdOrderLine(
          Item."No.", ProductionOrder.Status::Finished, ProductionOrder.Quantity, ProductionOrder.Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderWithItemTrackingForBackwardFlushingComp()
    var
        Item: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify that Production order can be finished with component item tracking entries when Flushing Method = Backward.

        // Setup: Create parent and child Item in a Production BOM and certify it. Update Inventory for child Item.
        // Create and refresh a Released Production Order, update Flushing Method on Prod. Order Component
        Initialize();
        CreateItemsSetupWithProductionAndTracking(Item, ParentItem, ProductionOrder, LibraryRandom.RandInt(100), '');
        UpdateFlushingMethodOnProdComp(ProductionOrder."No.", Item."Flushing Method"::Backward);

        // Open Components and add an existing Item Tracking.
        SelectItemTrackingForProdOrderComponents(Item."No.");

        // Create and post the Output Journal.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, ProductionOrder.Quantity); // Tracking = TRUE

        // Exercise: Change the Production Order Status to Finished
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify change status successfully. The Finished Quantity is correct and finishing the Production Order.
        VerifyProdOrderLine(
          ParentItem."No.", ProductionOrder.Status::Finished, ProductionOrder.Quantity, ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotChangeDurationOfOperationsInManuallyScheduledProdOrderRoutingLine()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NewSetupTime: Decimal;
    begin
        // [SCENARIO 379761] Leaving total duration of setup-wait-move operations unchanged within the period between Starting and Ending Dates should not cause errors in Prod. Order Routing Line with "Schedule Manually" flag on.
        Initialize();

        // [GIVEN] Released Production Order.
        // [GIVEN] "Schedule Manually" flag is set to TRUE in Prod. Order Routing Line "L".
        CreateReleasedProdOrderWithManuallyScheduledRoutingLine(ProdOrderRoutingLine);

        // [WHEN] Setup Time in "L" is revalidated with the same value.
        NewSetupTime := ProdOrderRoutingLine."Setup Time";
        UpdateSetupTimeInProdOrderRoutingLine(ProdOrderRoutingLine, NewSetupTime);

        // [THEN] Validation causes no error. Setup Time in "L" is left unchanged.
        Assert.AreEqual(NewSetupTime, ProdOrderRoutingLine."Setup Time", ProdOrderRtngLineNotUpdatedMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanTwoLevelProdOrderWithChildLineReservedToParentLineComponent()
    var
        ProductionOrder: Record "Production Order";
        ItemNo: array[5] of Code[20];
        ReducedQty: Decimal;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 381078] Reducing quantity on a parent line in two level Production Order reduces quantity on a child line. It also reduces the quantity of the component to be produced in other Production Order.
        Initialize();

        // [GIVEN] Production chain - a purchased component and three levels of manufacturing items "I1", "I2", "I3". "I3" is the highest level.
        // [GIVEN] Items "I2" and "I3" have Make-to-Order manufacturing policy.
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] Firm planned two level Production Order "PO" for items "I3" and "I2". Quantity = "Q".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo[3], LibraryRandom.RandIntInRange(11, 20), '', '');

        // [GIVEN] Replan procedure is run for "PO".
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [GIVEN] Quantity on Prod. Order Line for "I3" is reduced to "q".
        ReducedQty := LibraryRandom.RandInt(10);
        UpdateQuantityOnProdOrderLine(ItemNo[3], ReducedQty);

        // [WHEN] Replan the Production Order "PO" for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Quantity on Prod. Order Line for "I2" is reduced to "q".
        VerifyOneProdOrderLine(ItemNo[2], ReducedQty);

        // [THEN] Production Order for "I1" created by the replanning of "PO", has one line with reduced quantity "q".
        VerifyOneProdOrderLine(ItemNo[1], ReducedQty);
    end;

    [Test]
    [HandlerFunctions('ReservationEntriesModalPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReplanTwoLevelProdOrderWithChildLineNotReserved()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[5] of Code[20];
        ReducedQty: Decimal;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 381078] Reducing quantity on a parent line in two level Production Order with removed binding between the lines, reduces quantity on a child line. It also reduces the quantity of the component to be produced in other Production Order.
        Initialize();

        // [GIVEN] Production chain - a purchased component and three levels of manufacturing items "I1", "I2", "I3". "I3" is the highest level.
        // [GIVEN] Items "I2" and "I3" have Make-to-Order manufacturing policy.
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] Firm planned two level Production Order "PO" for items "I3" and "I2". Quantity = "Q".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo[3], LibraryRandom.RandIntInRange(11, 20), '', '');

        // [GIVEN] Replan procedure is run for "PO".
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [GIVEN] Reservation of Prod. Order Line for "I2" is canceled.
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.ShowReservationEntries(true);

        // [GIVEN] Quantity on Prod. Order Line for "I3" is reduced to "q".
        ReducedQty := LibraryRandom.RandInt(10);
        UpdateQuantityOnProdOrderLine(ItemNo[3], ReducedQty);

        // [WHEN] Replan the Production Order "PO" for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Quantity on Prod. Order Line for "I2" is reduced to "q".
        VerifyOneProdOrderLine(ItemNo[2], ReducedQty);

        // [THEN] Production Order for "I1" created by the replanning of "PO", has one line with reduced quantity "q".
        VerifyOneProdOrderLine(ItemNo[1], ReducedQty);
    end;

    [Test]
    [HandlerFunctions('ReservationEntriesModalPageHandler,ReservationHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReplanTwoLevelProdOrderWithChildLineReservedForExternalDemand()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: array[5] of Code[20];
        ProductionQty: Decimal;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 381078] When child line in two level Production Order is reserved to Sales Order, replanning of the Production Order increases the quantity of the child line to supply the parent line and the Sales Order.
        Initialize();

        // [GIVEN] Production chain - a purchased component and three levels of manufacturing items "I1", "I2", "I3". "I3" is the highest level.
        // [GIVEN] Items "I2" and "I3" have Make-to-Order manufacturing policy.
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] Firm planned two level Production Order "PO" for items "I3" and "I2". Quantity = "Q".
        ProductionQty := LibraryRandom.RandIntInRange(11, 20);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo[3], ProductionQty, '', '');

        // [GIVEN] Replan procedure is run for "PO".
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [GIVEN] Reservation of Prod. Order Line for "I2" is canceled.
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.ShowReservationEntries(true);

        // [GIVEN] Quantity "q" is reserved from Prod. Order Line for "I2" by a Sales Line.
        SalesQty := LibraryRandom.RandInt(10);
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo[2], SalesQty, '');
        SalesLine.ShowReservation();

        // [WHEN] Replan the Production Order "PO" for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Quantity of production of "I2" is equal to "Q" + "q".
        VerifyOneProdOrderLine(ItemNo[2], ProductionQty + SalesQty);

        // [THEN] Production Order for "I1" created by the replanning of "PO", has one line with quantity = "Q" + "q".
        VerifyOneProdOrderLine(ItemNo[1], ProductionQty + SalesQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ComponentPlanningLevelDecreasedWhenSupplyProdOrderLineDeleted()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: array[5] of Code[20];
    begin
        // [FEATURE] [Make-to-Order]
        // [SCENARIO 210802] Planning Level Code on prod. order component should be decreased if prod. order line that supplies this component is deleted.
        Initialize();

        // [GIVEN] BOM structure of 4 items "I1".."I4" created with "Make-to-Order" manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3", "I3" is a component of "I4".
        CreateProductionChainOfItems(ItemNo, 4);

        // [GIVEN] Released production order for "I4".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemNo[4], LibraryRandom.RandInt(10), '', '');

        // [WHEN] Delete the lowest level prod. order line (with Item No. = "I2" and Planning Level Code = 2).
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.Delete(true);

        // [THEN] Item "I2" in the list of prod. order components for "I3" has Planning Level Code = 1.
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        FindProdOrderComponentByItem(ProdOrderComponent, ProdOrderLine, ItemNo[2]);
        ProdOrderComponent.TestField("Planning Level Code", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProdOrderWithAddedProdOrderCompRecalculatesMTOStructure()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: array[3] of Code[20];
        NewItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 230435] When you run Replan Production Order after adding prod. order component for the finished item, this component is inserted in the prod. order lines tree.
        Initialize();

        // [GIVEN] BOM structure of 3 items "I1".."I3" with Make-to-Order manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3".
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] BOM structure of 2 items "J1".."J2". "J2" has a Make-to-Order manufacturing policy, "J1" is a component of "J2".
        CreateProductionChainOfItems(NewItemNo, 2);

        // [GIVEN] Released production order for "I3".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemNo[3], LibraryRandom.RandInt(10), '', '');

        // [GIVEN] Add "J2" to the list of prod. order components for "I3".
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", NewItemNo[2]);
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);

        // [WHEN] Replan the production order for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] A new multi-level structure of the production order is as follows:
        // [THEN]   I3
        // [THEN]  /  \
        // [THEN] I2  J2
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        ProdOrderLine.TestField("Planning Level Code", 0);

        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.TestField("Planning Level Code", 1);

        FindProductionOrderLine(ProdOrderLine, NewItemNo[2]);
        ProdOrderLine.TestField("Planning Level Code", 1);

        // [THEN] Planning Level Code of component "J2" is equal to 1.
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Planning Level Code", 1);

        // [THEN] No additional production order is created for "J2".
        ProdOrderLine.SetFilter("Prod. Order No.", '<>%1', ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", NewItemNo[2]);
        Assert.RecordIsEmpty(ProdOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinedProdOrderKeepsItsStructureAfterReplan()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[5] of Code[20];
        BOMStructureDepth: Integer;
        i: Integer;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 210802] A multi-level production order should keep its structure of prod. order lines after Replan Production Order function is carried out.
        Initialize();

        // [GIVEN] BOM structure of 4 items "I1".."I4" created with "Make-to-Order" manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3", "I3" is a component of "I4".
        BOMStructureDepth := 4;
        CreateProductionChainOfItems(ItemNo, BOMStructureDepth);

        // [GIVEN] Released production order for "I4". It has 3-level structure with "I4" at the highest level, then "I3", and "I2" at the lowest.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemNo[BOMStructureDepth], LibraryRandom.RandInt(10), '', '');

        // [WHEN] Replan the production order for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] The production order keeps its 3-level structure of prod. order lines.
        for i := 2 to BOMStructureDepth do begin
            FindProductionOrderLine(ProdOrderLine, ItemNo[i]);
            ProdOrderLine.TestField("Prod. Order No.", ProductionOrder."No.");
            ProdOrderLine.TestField("Planning Level Code", BOMStructureDepth - i);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineWithAlternateUOMReplan()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[3] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Make-to-Order] [Replan Production Order] [Unit of Measure]
        // [SCENARIO 218585] Production Order can be replanned if there is a prod. order line with "Qty. per Unit of Measure" > 1 in it.
        Initialize();

        // [GIVEN] Production BOM structure of 3 items "I1", "I2", "I3" created with "Make-to-Order" manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3".
        CreateProductionChainOfItems(ItemNo, 3);

        // [GIVEN] BOM for "I3" is modified - Unit of Measure Code for component "I2" is changed.
        UpdateUOMOnProdBOMLineByItemNo(ItemNo[3], ItemNo[2], LibraryRandom.RandIntInRange(2, 5));

        // [GIVEN] Released production order for "I3". It has 2-level structure with "I3" at the high level and "I2" at the low.
        Qty := LibraryRandom.RandIntInRange(11, 20);
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ItemNo[3], Qty, '', '');

        // [GIVEN] Quantity on prod. order line for "I3" is doubled.
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        ProdOrderLine.Validate(Quantity, Qty * 2);
        ProdOrderLine.Modify(true);

        // [WHEN] Replan the production order for all levels of manufacturing.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Prod. order line for "I2" is replanned, quantity is doubled.
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.TestField(Quantity, Round(Qty * 2 / ProdOrderLine."Qty. per Unit of Measure", 0.00001));
    end;

    [Test]
    [HandlerFunctions('AllLevelsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure StandardCostWithScrapCalculation()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        FixedScrapQuantity: Decimal;
        ParentItemScrapPercent: Decimal;
        LotSize: Decimal;
        ProductionBOMScrapPercent: Decimal;
    begin
        // [FEATURE] [Standard Cost]
        // [SCENARIO 221770] "Fixed Scrap Quantity" is an additional member in "Standard Cost" calculation formula
        Initialize();

        // [GIVEN] "MachineCenter" "MC" with "Fixed Scrap Quantity" = 20
        // [GIVEN] Production Item "PI" with Child Item as Production BOM with "Scrap %" = 10
        // [GIVEN] "PI" has Routing with "MC", "PI"."Scrap %" = 5, PI."Lot Size" = 50
        FixedScrapQuantity := LibraryRandom.RandIntInRange(10, 20);
        ParentItemScrapPercent := LibraryRandom.RandInt(5);
        LotSize := LibraryRandom.RandIntInRange(50, 100);
        ProductionBOMScrapPercent := LibraryRandom.RandIntInRange(5, 10);
        CreateItemCostingMethodFIFO(ChildItem);
        CreateProdOrderItemWithScrapPercent(
          ParentItem, CreateRoutingWithMachineCenter(CreateMachineCenterWithFixedScrap(FixedScrapQuantity)),
          CreateProductionBOMWitScrapPercent(ChildItem, ProductionBOMScrapPercent), ParentItemScrapPercent, LotSize);

        // [WHEN] Calculate Standard Cost for "PI"
        CalculateStandardCost.CalcItem(ParentItem."No.", false);

        // [THEN] "PI"."Standard Cost" = (1 + 5 / 100) * (1 + 10 / 100) + 20 / 50 = 1.555
        ParentItem.Find();
        AssertNearlyEqual(
          (1 + ParentItemScrapPercent / 100) * (1 + ProductionBOMScrapPercent / 100) + FixedScrapQuantity / LotSize,
          ParentItem."Standard Cost", StrSubstNo(IncorrectValueErr, ParentItem.TableName, ParentItem.FieldName("Standard Cost")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemScrapPercentForProdOrderComponentCalculationWhenRefresh()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ParentProductionBOMHeader: Record "Production BOM Header";
        ChildProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        UOMMgt: Codeunit "Unit of Measure Management";
        ScrapPercent: Integer;
        ChildQtyPer: Integer;
        ParentQtyPer: Integer;
        Qty: Integer;
    begin
        // [FEATURE] [Production Order] [Item Scrap %]
        // [SCENARIO 222911] "Scrap %" from Item Card participates in calculation of field "Expected Quantity" and doesn't participate in calculation of field "Quantity Per" of "Prod. Order Component"
        Initialize();

        // [GIVEN] 2-level structure of "Production BOM" "PB" of Parent Item "PI", "CI" is Child Item at level 2
        ScrapPercent := LibraryRandom.RandIntInRange(5, 10);
        ChildQtyPer := LibraryRandom.RandIntInRange(10, 15);
        ParentQtyPer := LibraryRandom.RandIntInRange(15, 20);
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] For "PB" "Quantity Per" of first level is 10, "Quantity Per" of second level is 15
        LibraryInventory.CreateItem(ChildItem);
        CreateCertifiedProductionBOMWithQtyPer(
          ChildProductionBOMHeader, ChildItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.", ChildQtyPer);
        CreateCertifiedProductionBOMWithQtyPer(
          ParentProductionBOMHeader, ChildProductionBOMHeader."Unit of Measure Code",
          ProductionBOMLine.Type::"Production BOM", ChildProductionBOMHeader."No.", ParentQtyPer);

        // [GIVEN] "PI"."Scrap %" is 5
        CreateProductionItemWithScrapPercent(ParentItem, ParentProductionBOMHeader."No.", ScrapPercent);

        // [GIVEN] Production Order "PO" for "I" with Quantity 100
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", Qty);

        // [WHEN] Refresh Production Order "PO"
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Component of "PO" for "CI" has "Quantity per" = 10 * 15 = 150, "Expected Quantity" = 10 * 15 * 100 * (1 + 5 / 100) = 15750
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
        ProdOrderComponent.TestField("Quantity per", ParentQtyPer * ChildQtyPer);
        Assert.AreEqual(
          ProdOrderComponent."Expected Quantity",
          UOMMgt.RoundToItemRndPrecision(ParentQtyPer * ChildQtyPer * Qty * (1 + ScrapPercent / 100), ParentItem."Rounding Precision"), ExpectedQuantityErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemScrapPercentForPlanningComponentCalculationWhenRefresh()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ParentProductionBOMHeader: Record "Production BOM Header";
        ChildProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        ScrapPercent: Integer;
        Qty: Integer;
    begin
        // [FEATURE] [Planning Component] [Item Scrap %]
        // [SCENARIO 222911] "Scrap %" from Item Card participates in calculation of field "Expected Quantity" and does not of field "Quantity Per" on planning component.
        Initialize();
        ScrapPercent := LibraryRandom.RandIntInRange(5, 10);
        Qty := LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Create production BOM "Comp_BOM" with component item "C".
        // [GIVEN] Create production BOM "Prod_BOM" using "Comp_BOM" as a component.
        LibraryInventory.CreateItem(ChildItem);
        CreateCertifiedProductionBOMWithQtyPer(
          ChildProductionBOMHeader, ChildItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ChildItem."No.", 1);
        CreateCertifiedProductionBOMWithQtyPer(
          ParentProductionBOMHeader, ChildProductionBOMHeader."Unit of Measure Code",
          ProductionBOMLine.Type::"Production BOM", ChildProductionBOMHeader."No.", 1);

        // [GIVEN] Create a production item "P", set "Production BOM" = "Prod_BOM" and "Scrap %" = 5.
        CreateProductionItemWithScrapPercent(ParentItem, ParentProductionBOMHeader."No.", ScrapPercent);

        // [GIVEN] Create planning line with item "P" and quantity = 100.
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate("No.", ParentItem."No.");
        RequisitionLine.Validate(Quantity, Qty);
        RequisitionLine.Modify(true);

        // [WHEN] Refresh the planning line.
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, 0, false, true);

        // [THEN] Scrap percent does not affect "Quantity per" of the planning component "C".
        // [THEN] Expected Quantity on the planning component = 105 (100 + 5% scrap).
        FindPlanningComponent(PlanningComponent, RequisitionLine, ChildItem."No.");
        PlanningComponent.TestField("Quantity per", 1);
        PlanningComponent.TestField(
          "Expected Quantity", Round(RequisitionLine.Quantity * (1 + ScrapPercent / 100), ChildItem."Rounding Precision"));
    end;

    [Test]
    [HandlerFunctions('AllLevelsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure FixedScrapQtyMultipliedByQtyPerUoM()
    var
        ChildItem: Record Item;
        ProdItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        QtyPerUoM: Decimal;
        QtyPerBOMLine: Decimal;
        FixedScrapQty: Decimal;
        LotSize: Decimal;
    begin
        // [FEATURE] [Routing] [Scrap]
        // [SCENARIO 225829] Standard lot size and fixed scrap quantity should be multiplied by "Quantity per UoM" of the production BOM line when calculating component quantity

        Initialize();

        QtyPerUoM := LibraryRandom.RandIntInRange(5, 10);
        QtyPerBOMLine := LibraryRandom.RandIntInRange(5, 10);
        FixedScrapQty := LibraryRandom.RandIntInRange(5, 10);
        LotSize := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] BOM component item "C" with unit cost = 10
        LibraryInventory.CreateItem(ChildItem);
        UpdateUnitCostOnItem(ChildItem);

        // [GIVEN] Production BOM "B". Item "C" is included in the BOM in additional unit of measure with quantity per UOM = 3, "Quantity" in BOM line is 4
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader, ChildItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeader, ProdBOMLine, '', ProdBOMLine.Type::Item, ChildItem."No.", QtyPerBOMLine);
        UpdateUOMOnProdBOMLine(ProdBOMHeader."No.", ChildItem."No.", QtyPerUoM);

        // [GIVEN] Routing "R" with fixed scrap quantity = 7
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', '', RoutingLine.Type::"Machine Center", CreateMachineCenterWithFixedScrap(FixedScrapQty));
        RoutingLine.Modify(true);

        // [GIVEN] Manufactured item "P" with lot size = 20. Production BOM and routing for the item are "B" and "R", respectievely
        CreateProductionItem(ProdItem, ProdBOMHeader."No.");
        ProdItem.Validate("Routing No.", CreateRoutingWithMachineCenter(CreateMachineCenterWithFixedScrap(FixedScrapQty)));
        ProdItem.Validate("Lot Size", LotSize);
        ProdItem.Modify(true);

        // [WHEN] Calculate standard cost for the item "P"
        CalculateStandardCost.CalcItem(ProdItem."No.", false);

        // [THEN] Standard cost is (20 + 7) * 3 * 4 * 10 / 20 = 162
        ProdItem.Find();
        AssertNearlyEqual(
          (LotSize + FixedScrapQty) * QtyPerUoM * QtyPerBOMLine * ChildItem."Unit Cost" / LotSize,
          ProdItem."Standard Cost",
          StrSubstNo(IncorrectValueErr, ProdItem.TableName, ProdItem.FieldName("Standard Cost")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOnChildPlanningLineInMakeToOrderStructureEqualsBinCodeOnPlanningComp()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemNo: array[3] of Code[20];
        LocationCode: Code[10];
        ProdBinCode: Code[20];
        OpenShopFloorBin: Code[20];
    begin
        // [FEATURE] [Make-to-Order] [Planning Component] [Planning Worksheet] [Bin]
        // [SCENARIO 229617] Bin Code on requisition line representing a child item in make-to-order structure, shows the bin, that the child item is placed into before being consumed by the production of the parent item.
        Initialize();

        // [GIVEN] Make-to-order structure - item "I1" is a component of "I2", and "I2" is a component of "I3".
        // [GIVEN] "From-production Bin Code" is "B3" at location. The output of "I3" will be placed into this bin.
        // [GIVEN] The bin code where the child item "I2" will be consumed from is set up in "Open Shop Floor Bin Code" ("B2") in work center, linked to the production BOM of "I3".
        CreateMakeToOrderProdItemWithComponentsTakenFromOpenShopFloorBin(ItemNo, LocationCode, ProdBinCode, OpenShopFloorBin);

        // [GIVEN] Demand for "X" pcs of item "I3".
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo[3], LibraryRandom.RandInt(10), LocationCode);

        // [WHEN] Calculate regenerative plan in planning worksheet for items "I2" and "I3".
        Item.SetFilter("No.", '%1|%2', ItemNo[2], ItemNo[3]);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [THEN] Bin Code on the requisition line for parent item "I3" is equal to "B3".
        FindRequisitionLine(RequisitionLine, ItemNo[3]);
        RequisitionLine.TestField("Bin Code", ProdBinCode);

        // [THEN] Bin Code on the requisition line for child item "I2" is equal to "B2".
        FindRequisitionLine(RequisitionLine, ItemNo[2]);
        RequisitionLine.TestField("Bin Code", OpenShopFloorBin);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeOnChildMakeToOrderProdOrderLineEqualsBinCodeOnSuppliedProdOrderComp()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: array[3] of Code[20];
        LocationCode: Code[10];
        ProdBinCode: Code[20];
        OpenShopFloorBin: Code[20];
    begin
        // [FEATURE] [Make-to-Order] [Bin]
        // [SCENARIO 229617] Bin Code on prod. order line representing a child item in make-to-order structure is equal to Bin Code on the prod. order component the child item supplies, when the production order is created via planning worksheet.
        Initialize();

        // [GIVEN] Make-to-order structure - item "I1" is a component of "I2", and "I2" is a component of "I3".
        // [GIVEN] "From-production Bin Code" is "B3" at location. The output of "I3" will be placed into this bin.
        // [GIVEN] The bin code where the child item "I2" will be consumed from is set up in "Open Shop Floor Bin Code" ("B2") in work center, linked to the production BOM of "I3".
        CreateMakeToOrderProdItemWithComponentsTakenFromOpenShopFloorBin(ItemNo, LocationCode, ProdBinCode, OpenShopFloorBin);

        // [GIVEN] Demand for "X" pcs of item "I3".
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo[3], LibraryRandom.RandInt(10), LocationCode);

        // [GIVEN] Regenerative plan in planning worksheet is calculated for items "I2" and "I3".
        Item.SetFilter("No.", '%1|%2', ItemNo[2], ItemNo[3]);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] Carry out action message - create a production order.
        AcceptActionMessage(RequisitionLine, ItemNo[2]);
        AcceptActionMessage(RequisitionLine, ItemNo[3]);
        Item.CopyFilter("No.", RequisitionLine."No.");
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [THEN] Bin Code on the parent prod order line is equal to "B3".
        FindProductionOrderLine(ProdOrderLine, ItemNo[3]);
        ProdOrderLine.TestField("Bin Code", ProdBinCode);

        // [THEN] Bin Code on prod. order component for the parent line is equal to "B2".
        FindProdOrderComponentByItem(ProdOrderComponent, ProdOrderLine, ItemNo[2]);
        ProdOrderComponent.TestField("Bin Code", OpenShopFloorBin);

        // [THEN] Bin Code on the child prod order line is equal to "B2".
        FindProductionOrderLine(ProdOrderLine, ItemNo[2]);
        ProdOrderLine.TestField("Bin Code", OpenShopFloorBin);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickingMTOItemAfterPlanning()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: array[3] of Code[20];
        Quantity: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Make-to-Order] [Component]
        // [SCENARIO 252705] A component which has sufficient stock must be picked up from stock when planning.

        Initialize();

        // [GIVEN] Update Manuf. Setup: setting "Components at Location" field with 'white' location code.
        LibraryManufacturing.SetComponentsAtLocation(LocationWhite.Code);

        // [GIVEN] BOM structure of 3 items "I1".."I3" created with "Make-to-Order" manufacturing policy.
        // [GIVEN] "I1" is a component of "I2", "I2" is a component of "I3". I1 - 'Grandchild', I2 - 'Child', I3 - 'Parent'
        CreateProductionChainOfItems(ItemNo, 3);
        for i := 1 to 3 do begin
            Item.Get(ItemNo[i]);
            Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
            Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
            Item.Modify(true);
        end;

        // [GIVEN] Create Inventory for Child Item on the 'white' location which was set to "Components at Location" above.
        Quantity := LibraryRandom.RandInt(10);
        Item.Get(ItemNo[2]);
        UpdateInventoryWithWhseItemJournal(Item, LocationWhite, Quantity);

        // [GIVEN] Create and release Sales Order for the Parent item.
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo[3], LibraryRandom.RandInt(Quantity), LocationWhite.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Calculate Regenerative Plan for the Parent item and its components (Child and Grandchild items).
        Item.SetFilter("No.", '%1|%2|%3', ItemNo[1], ItemNo[2], ItemNo[3]);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));

        // [GIVEN] Accept and Carry Out Action Message. 'Firm Planned Prod. Order' is created as a result.
        AcceptAndCarryOutActionMessage(ItemNo[3]);
        FilterFirmPlannedProductionOrder(ProductionOrder, ItemNo[3]);

        // [GIVEN] Release Prod. Order
        ProductionOrder.Get(
          ProductionOrder.Status::Released,
          LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No."));

        // [WHEN] Create Whse. Pick from Released Prod. Order
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption",
          WarehouseActivityLine."Action Type"::Take);

        // [THEN] Whse. Pick must contain 2 lines of Child Item, which must be picked up from stock.
        WarehouseActivityLine.TestField("Item No.", ItemNo[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ProductionOrderStatusToFinishedWhenLastOutputJournalLineForFamilyIsPosted()
    var
        Item: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Family: Record Family;
        FamilyLine: Record "Family Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        i: Integer;
    begin
        // [FEATURE] [Output Journal] [Family] [Production Order Status]
        // [SCENARIO 265553] Can change production order status to Finished when last output journal line for family is posted
        Initialize();

        // [GIVEN] Routing "R" with two lines
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 1 to 2 do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine, '', LibraryUtility.GenerateGUID(), RoutingLine.Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Family "F" with two items
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        for i := 1 to 2 do begin
            CreateProductionItemWithRoutingNo(Item, RoutingHeader."No.");
            LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item."No.", 1);
        end;

        // [GIVEN] Production Order "O" with Source = "F"
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", 1);

        // [GIVEN] Post output journal with only one line - last "Operation No." for last item of family
        FindLastProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine."Operation No.", 0, 1);

        // [WHEN] Change "O" Status from Released to Finished
        LibraryVariableStorage.Enqueue(ConfirmStatusFinishTxt);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);

        // [THEN] Production Order with Status = Finished and "No." = "O"."No." exists
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesSeparatesItems()
    var
        Item: array[2] of Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
        Family: Record Family;
        FamilyLine: Record "Family Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ValueEntry: Record "Value Entry";
        i: Integer;
        WorkCenterUnitCost: Decimal;
        RunTime: array[2] of Decimal;
    begin
        // [FEATURE] [Adjust cost item entries] [Capacity] [Family]
        // [SCENARIO 266023] Adjust cost item entries separates capacity cost for different items from family with single routing.
        Initialize();

        // [GIVEN] Routing "R" with two lines, "Unit Cost" "U" = 1
        WorkCenterUnitCost := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Unit Cost", WorkCenterUnitCost);
        WorkCenter.Modify(true);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 1 to ArrayLen(RoutingLine) do
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine[i], '', LibraryUtility.GenerateGUID(), RoutingLine[i].Type::"Work Center", WorkCenter."No.");
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Family "F" with two items
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);

        for i := 1 to ArrayLen(Item) do begin
            CreateProductionItemWithRoutingNo(Item[i], RoutingHeader."No.");
            LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", Item[i]."No.", 1);
        end;

        // [GIVEN] Production Order "O" with Source = "F" and with two lines - "L1" for "I1" and "L2" for "I2"
        CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(ProductionOrder, Family."No.", 1);

        // [GIVEN] Post output journal line - last "Operation No." for "L1" with quantity one and zero run time
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine[2]."Operation No.", 0, 1);

        // [GIVEN] Post output journal line - last "Operation No." for "L2" with quantity one and zero run time
        FindLastProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine[2]."Operation No.", 0, 1);

        for i := 1 to ArrayLen(RunTime) do
            RunTime[i] := Power(10, i * i) * LibraryRandom.RandInt(10);

        // [GIVEN] Post output journal line - last "Operation No." for "L1" with zero quantity and "Run Time" "T1" = 10
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine[1]."Operation No.", RunTime[1], 0);

        // [GIVEN] Post output journal line - last "Operation No." for "L2" with zero quantity and "Run Time" "T2" = 10000
        FindLastProdOrderLine(ProdOrderLine, ProductionOrder);
        CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine, RoutingHeader."No.", RoutingLine[1]."Operation No.", RunTime[2], 0);

        // [GIVEN] Change "O" Status from Released to Finished
        LibraryVariableStorage.Enqueue(ConfirmStatusFinishTxt);
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);

        // [WHEN] Adjust cost item entries
        LibraryCosting.AdjustCostItemEntries(StrSubstNo('%1|%2', Item[1]."No.", Item[2]."No."), '');

        // [THEN] "Value Entry" for "I1" with "Expected Cost" = FALSE has "Cost Amount (Actual)" = "U" * "T1" = 10
        ValueEntryCalcSumsCostAmountActual(ValueEntry, Item[1]."No.");
        ValueEntry.TestField("Cost Amount (Actual)", RunTime[1] * WorkCenterUnitCost);

        // [THEN] "Value Entry" for "I2" with "Expected Cost" = FALSE has "Cost Amount (Actual)" = "U" * "T2" = 10000
        ValueEntryCalcSumsCostAmountActual(ValueEntry, Item[2]."No.");
        ValueEntry.TestField("Cost Amount (Actual)", RunTime[2] * WorkCenterUnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderWithMakeToOrderComponentAndComponentAtLocation()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        Location: Record Location;
        Bin: Record Bin;
    begin
        // [FEATURE] [Make-to-Order] [Component]
        // [SCENARIO 285899] Refresh Prod Order with Make-To-Order component and Components at Location using Bin Code
        Initialize();

        // [GIVEN] Manufacturing Setup with "Components at Location" = "Loc"
        CreateAndUpdateLocation(Location, false, false, false, false);
        LibraryManufacturing.SetComponentsAtLocation(Location.Code);

        // [GIVEN] Make-To Order Item "Comp Item" has an item as component
        // [GIVEN] Make-To Order Item "Prod Item" has "Comp Item" as component
        CreateItemsSetup(CompItem, Item);
        CreateMakeToOrderProductionItem(ProdItem, CompItem);
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);

        // [GIVEN] Production Order for "Prod Item" with Location "Red" and Bin Code = "123"
        // [WHEN] Refresh Production Order
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", LibraryRandom.RandInt(100),
          LocationRed.Code, Bin.Code);

        // [THEN] Prod Order Line for "Prod Item" has Location "Red" and Bin Code "123"
        // [THEN] Prod Order Line for "Comp Item" has Location "Loc" and blank Bin Code
        VerifyProdOrderLineWithLocationAndBin(ProdItem."No.", LocationRed.Code, Bin.Code);
        VerifyProdOrderLineWithLocationAndBin(CompItem."No.", Location.Code, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EliminationOfTimeOverlapOnOneParentTwoChildAndSeparateGrandchildMTOLines()
    var
        GrandChildItem: array[2] of Record Item;
        ChildItem: array[2] of Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        EndingDateTime: DateTime;
        OriginalEndingDateTime: array[2] of DateTime;
        i: Integer;
    begin
        // [FEATURE] [Make-to-Order] [Routing]
        // [SCENARIO 286683] Increasing processing time of a semi-finished item in multilined production order shifts the starting date-time of the finished item forward. Case "one parent - two children - two separate grandchildren".
        Initialize();

        // [GIVEN] Make-to-order production tree of items.
        // [GIVEN] Parent item "A".
        // [GIVEN] Child items "B1" and "B2" are the components of "A".
        // [GIVEN] Grandchild item "C1" is a component of "B1", grandchild item "C2" is a component of "B2".
        // [GIVEN] Routings with defined Run Time are assigned to the grandchild items.
        // [GIVEN]      A
        // [GIVEN]     / \
        // [GIVEN]   B1   B2
        // [GIVEN]   /     \
        // [GIVEN]  C1     C2
        for i := 1 to ArrayLen(GrandChildItem) do begin
            CreateProductionItem(GrandChildItem[i], '');
            GrandChildItem[i].Validate("Manufacturing Policy", GrandChildItem[i]."Manufacturing Policy"::"Make-to-Order");
            GrandChildItem[i].Modify(true);
            CreateRoutingAndUpdateItem(GrandChildItem[i]);

            CreateCertifiedProductionBOM(ProductionBOMHeader, GrandChildItem[i]);
            CreateProductionItem(ChildItem[i], ProductionBOMHeader."No.");
            ChildItem[i].Validate("Manufacturing Policy", ChildItem[i]."Manufacturing Policy"::"Make-to-Order");
            ChildItem[i].Modify(true);
        end;

        CreateCertifiedProductionBOMWithMultipleItems(ProductionBOMHeader, ChildItem[1], ChildItem[2]);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Released production order for parent item "A".
        // [GIVEN] The production order has 5 lines:
        // [GIVEN] Item "A", starting date-time 25/01 8:00, ending date-time 25/01 23:00
        // [GIVEN] Item "B1", starting date-time 25/01 8:00, ending date-time 25/01 8:00
        // [GIVEN] Item "B2", starting date-time 25/01 8:00, ending date-time 25/01 8:00
        // [GIVEN] Item "C1", starting date-time 24/01 22:00, ending date-time 24/01 23:00
        // [GIVEN] Item "C2", starting date-time 24/01 22:00, ending date-time 24/01 23:00
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandInt(10), '', '');

        FindProductionOrderLine(ProdOrderLine, GrandChildItem[1]."No.");
        OriginalEndingDateTime[1] := ProdOrderLine."Ending Date-Time";

        FindProductionOrderLine(ProdOrderLine, ChildItem[1]."No.");
        OriginalEndingDateTime[2] := ProdOrderLine."Ending Date-Time";

        FindProductionOrderLine(ProdOrderLine, GrandChildItem[2]."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Increase Run Time on prod. order routing line only for grandchild item "C2".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate("Run Time", ProdOrderRoutingLine."Run Time" * 2);
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Ending date-time on production order line for "C2" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, GrandChildItem[2]."No.");
        EndingDateTime := ProdOrderRoutingLine."Ending Date-Time";

        // [THEN] Starting date-time on production order line for item "B2" is updated to 25/01 9:00.
        // [THEN] Ending date-time on prod. order line for item "B2" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, ChildItem[2]."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);
        ProdOrderLine.TestField("Ending Date-Time", ProdOrderLine."Starting Date-Time");
        EndingDateTime := ProdOrderLine."Ending Date-Time";

        // [THEN] Starting date-time on prod. order line for parent item "A" is updated to 25/01 9:00.
        // [THEN] Thus, we ensure continuous manufacturing process in "C2" - "B2" - "A" chain.
        FindProductionOrderLine(ProdOrderLine, ParentItem."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);

        // [THEN] Time adjustment for "C2" item does not have any impact on "C1" - "B1" chain.
        // [THEN] Starting date-time on "B1" and "C1" lines does not change.
        FindProductionOrderLine(ProdOrderLine, GrandChildItem[1]."No.");
        ProdOrderLine.TestField("Ending Date-Time", OriginalEndingDateTime[1]);

        FindProductionOrderLine(ProdOrderLine, ChildItem[1]."No.");
        ProdOrderLine.TestField("Starting Date-Time", OriginalEndingDateTime[2]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EliminationOfTimeOverlapOnOneParentTwoChildAndCommonGrandchildMTOLines()
    var
        GrandChildItem: Record Item;
        ChildItem: array[2] of Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        EndingDateTime: DateTime;
        i: Integer;
    begin
        // [FEATURE] [Make-to-Order] [Routing]
        // [SCENARIO 286683] Increasing processing time of a semi-finished item in multilined production order shifts the starting date-time of the finished item forward. Case "one parent - two children - one common grandchild".
        Initialize();

        // [GIVEN] Make-to-order production tree of items.
        // [GIVEN] Parent item "A".
        // [GIVEN] Child items "B1" and "B2" are the components of "A".
        // [GIVEN] Grandchild item "C" is a component of both "B1" and "B2" items.
        // [GIVEN] Routing with defined Run Time are assigned to the grandchild item.
        // [GIVEN]     A
        // [GIVEN]    / \
        // [GIVEN]  B1   B2
        // [GIVEN]    \ /
        // [GIVEN]     C
        CreateProductionItem(GrandChildItem, '');
        GrandChildItem.Validate("Manufacturing Policy", GrandChildItem."Manufacturing Policy"::"Make-to-Order");
        GrandChildItem.Modify(true);
        CreateRoutingAndUpdateItem(GrandChildItem);

        for i := 1 to ArrayLen(ChildItem) do begin
            CreateCertifiedProductionBOM(ProductionBOMHeader, GrandChildItem);
            CreateProductionItem(ChildItem[i], ProductionBOMHeader."No.");
            ChildItem[i].Validate("Manufacturing Policy", ChildItem[i]."Manufacturing Policy"::"Make-to-Order");
            ChildItem[i].Modify(true);
        end;

        CreateCertifiedProductionBOMWithMultipleItems(ProductionBOMHeader, ChildItem[1], ChildItem[2]);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Released production order for parent item "A".
        // [GIVEN] The production order has 4 lines:
        // [GIVEN] Item "A", starting date-time 25/01 8:00, ending date-time 25/01 23:00
        // [GIVEN] Item "B1", starting date-time 25/01 8:00, ending date-time 25/01 8:00
        // [GIVEN] Item "B2", starting date-time 25/01 8:00, ending date-time 25/01 8:00
        // [GIVEN] Item "C", starting date-time 24/01 22:00, ending date-time 24/01 23:00
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandInt(10), '', '');

        FindProductionOrderLine(ProdOrderLine, GrandChildItem."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Increase Run Time on prod. order routing line for grandchild item "C".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate("Run Time", ProdOrderRoutingLine."Run Time" * 2);
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Ending date-time on production order line for "C" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, GrandChildItem."No.");
        EndingDateTime := ProdOrderLine."Ending Date-Time";

        // [THEN] Starting date-time on production order line for item "B1" is updated to 25/01 9:00.
        // [THEN] Ending date-time on prod. order line for item "B1" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, ChildItem[1]."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);
        ProdOrderLine.TestField("Ending Date-Time", ProdOrderLine."Starting Date-Time");

        // [THEN] Starting date-time on production order line for item "B2" is updated to 25/01 9:00.
        // [THEN] Ending date-time on prod. order line for item "B2" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, ChildItem[2]."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);
        ProdOrderLine.TestField("Ending Date-Time", ProdOrderLine."Starting Date-Time");
        EndingDateTime := ProdOrderLine."Ending Date-Time";

        // [THEN] Starting date-time on production order line for item "A" is updated to 25/01 9:00.
        FindProductionOrderLine(ProdOrderLine, ParentItem."No.");
        ProdOrderLine.TestField("Starting Date-Time", EndingDateTime);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure WarningOfEliminatedTimeOverlapIsRaisedOnceForSeveralRoutingAdjustments()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ErrorMessage: Record "Error Message";
    begin
        // [FEATURE] [Make-to-Order] [Routing] [UI]
        // [SCENARIO 286683] A message that warns a user of changed starting date-time in production order is raised only once, although the time is adjusted several times.
        Initialize();

        // [GIVEN] Make-to-order production chain - finished item "A" and its component "B".
        CreateProductionItem(ChildItem, '');
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Modify(true);
        CreateRoutingAndUpdateItem(ChildItem);

        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Released production order for parent item "A".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandInt(10), '', '');

        FindProductionOrderLine(ProdOrderLine, ChildItem."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Increase Run Time twice on prod. order routing line for component item "B".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate("Run Time", ProdOrderRoutingLine."Run Time" * 2);
        ProdOrderRoutingLine.Validate("Run Time", ProdOrderRoutingLine."Run Time" * 4);
        ProdOrderRoutingLine.Modify(true);

        // [THEN] Only one warning message of changed starting date-time for finished item is shown to a user.
        Assert.AreEqual(
          TimeShiftedOnParentLineMsg, LibraryVariableStorage.DequeueText(),
          'Warning of changed date-time in the production order must be raised only once.');

        // [THEN] Message log for the prod. order routing line is clear.
        ErrorMessage.SetRange("Record ID", ProdOrderRoutingLine.RecordId);
        Assert.RecordIsEmpty(ErrorMessage);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ShipmentDateOnReservEntriesMatchDueDateOnProdOrderLineAfterEndingDateShiftedForward()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Make-to-Order] [Routing] [Reservation]
        // [SCENARIO 286683] When changing date on prod. order routing line moves the due date on semi-production item to a later date than the end item was initially planned, no date conflict error occurs. "Shipment Date" on reservation entries are update
        Initialize();

        // [GIVEN] Make-to-order production chain - finished item "A" and its component "B".
        CreateProductionItem(ChildItem, '');
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Modify(true);
        CreateRoutingAndUpdateItem(ChildItem);

        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Released production order for parent item "A".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LibraryRandom.RandInt(10), '', '');

        FindProductionOrderLine(ProdOrderLine, ChildItem."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Move Starting Date 10 days forward on prod. order routing line for component item "B".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate(
          "Starting Date", LibraryRandom.RandDateFromInRange(ProdOrderRoutingLine."Starting Date", 10, 20));
        ProdOrderRoutingLine.Modify(true);

        // [THEN] No "Date conflict during reservation..." error message is thrown.
        // [THEN] "Shipment Date" on reservation entries between output of semi-production item and its consumption are moved 10 days forward.
        ProdOrderLine.Find();
        ReservationEntry.SetSourceFilter(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, false);
        ReservationEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Shipment Date", ProdOrderRoutingLine."Ending Date");
        ReservationEntry.TestField("Shipment Date", ProdOrderLine."Due Date");

        ReservationEntry.Reset();
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Shipment Date", ProdOrderRoutingLine."Ending Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AllLevelsStrMenuHandler')]
    [Scope('OnPrem')]
    procedure ShipmentDateOnReservEntriesMatchDueDateOnProdOrderCompWhenReserveFromTransfer()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [Shipment Date] [Prod. Order Component] [Transfer]
        // [SCENARIO 298983] Shipment Date in Reservation Entry respects Prod. Order Component Due Date when reserve from Transfer Line
        Initialize();
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Item X was a production component of Item Y (1 PCS of X required to produce 1 PCS of Y)
        LibraryInventory.CreateItem(ChildItem);
        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] Item X had 100 PCS in Location RED
        LibraryWarehouse.CreateTransferLocations(FromLocation, ToLocation, InTransitLocation);
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity, '', FromLocation.Code, false);

        // [GIVEN] Released Production Order with 100 PCS of Item Y in Location BLUE, Due Date was 28/1/2020 (Due Date = 27/1/2020 in Prod. Order Component)
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", Quantity, ToLocation.Code, '');

        // [GIVEN] Released Transfer Order from RED to BLUE with 100 PCS of Item X and Shipment Date = 21/1/2020
        CreateTransferOrderWithQtyAndShipmentDate(
          TransferHeader, TransferLine, FromLocation.Code, ToLocation.Code, InTransitLocation.Code, ChildItem."No.",
          ProductionOrder.Quantity, CalcDate('<-1W>', WorkDate()));
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);

        // [WHEN] Auto-reserve Inbound Transfer for the Prod. Order Component (done in ReservationHandler and AllLevelsStrMenuHandler)
        TransferLine.ShowReservation();

        // [THEN] Both Reservation Entries for Item X have Shipment Date = 27/1/2020
        ReservationEntry.SetRange("Item No.", ChildItem."No.");
        Assert.RecordCount(ReservationEntry, 2);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.TestField("Shipment Date", CalcDate('<-1D>', WorkDate()))
        until ReservationEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMComponentWithZeroQtyPerAddedToProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production BOM] [Prod. Order Component]
        // [SCENARIO 315417] Production BOM component with "Quantity per" = 0 is added to prod. order components on production order refresh.
        Initialize();

        // [GIVEN] Component item "C", production item "P".
        // [GIVEN] Set "Quantity per" = 0 on the production BOM line for component "C".
        LibraryInventory.CreateItem(CompItem);
        CreateCertifiedProductionBOMWithQtyPer(
          ProductionBOMHeader, CompItem."Base Unit of Measure", ProductionBOMLine.Type::Item, CompItem."No.", 0);
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Released production order for "P".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", LibraryRandom.RandInt(10));

        // [WHEN] Refresh the production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Component "C" is added to the prod. order components with "Quantity per" = 0.
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Quantity per", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMComponentForMTOAndZeroQtyNotAddedToProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production BOM] [Prod. Order Component] [Make-to-Order]
        // [SCENARIO 315417] Production BOM component set up to be a child production item in Make-to-Order tree is not added to prod. order components of the parent item, if the component has "Quantity per" = 0 in the production BOM.
        Initialize();

        // [GIVEN] Component item "C" is a production item and set up for "Make-to-Order" manufacturing policy.
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);

        // [GIVEN] Production item "P" also set up for "Make-to-Order".
        // [GIVEN] Make item "C" a component of "P" with "Quantity per" = 0.
        CreateCertifiedProductionBOMWithQtyPer(
          ProductionBOMHeader, CompItem."Base Unit of Measure", ProductionBOMLine.Type::Item, CompItem."No.", 0);
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Modify(true);

        // [GIVEN] Released production order for "P".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", LibraryRandom.RandInt(10));

        // [WHEN] Refresh the production order.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Component "C" is not added to the prod. order components because there is no child prod. order line for "C" in the make-to-order tree.
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", CompItem."No.");
        Assert.RecordIsEmpty(ProdOrderComponent);

        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", CompItem."No.");
        Assert.RecordIsEmpty(ProdOrderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnnecessaryDueDateRefreshOnProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Production BOM] [Prod. Order Component] [Due Date]
        // [SCENARIO 319012] Due Date/Time fields for Production BOM Component isn't unnecessary refreshed on validating "Quantity per"
        Initialize();

        // [GIVEN] Created Component and Production Items
        LibraryInventory.CreateItem(CompItem);
        CreateCertifiedProductionBOMWithQtyPer(
          ProductionBOMHeader, CompItem."Base Unit of Measure", ProductionBOMLine.Type::Item,
          CompItem."No.", LibraryRandom.RandIntInRange(1, 5));
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Released and refreshed Production Order
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Modified Due Date and Due Time and assign Routing Link Code on Prod. Order Component
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.Validate("Due Date", ProdOrderComponent."Due Date" + 1);
        ProdOrderComponent.Validate("Due Time", ProdOrderComponent."Due Time" + 1);
        ProdOrderComponent.Modify(true);

        // [WHEN] Modify Quantity per on Prod. Order Component
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandIntInRange(6, 10));

        // [GIVEN] Due Date/time fields aren't refreshed
        ProdOrderComponent.TestField("Due Date", ProductionOrder."Starting Date" + 1);
        ProdOrderComponent.TestField("Due Time", ProductionOrder."Starting Time" + 1);
        ProdOrderComponent.TestField(
          "Due Date-Time", CreateDateTime(ProductionOrder."Starting Date" + 1, ProductionOrder."Starting Time" + 1));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLevelCodeZeroMTSSKUForMTOProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Make-to-Order] [Make-to-Stock] [Prod. Order Component]
        // [SCENARIO 333008] Production Order Component for an MTO Item with an MTS SKU has zero Planning Level Code
        Initialize();

        // [GIVEN] Component MTO Item "COMP" With Make-to-Stock Stockkeeping Unit for location "RED"
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);
        CreateStockkkeepingUnit(SKU, CompItem."No.", LocationRed.Code, SKU."Manufacturing Policy"::"Make-to-Stock");

        // [GIVEN] Production MTO Item "PROD" with Component "COMP"
        CreateMakeToOrderProductionItem(ProdItem, CompItem);

        // [WHEN] Create And Refresh Released Production Order for Item "PROD" and location "RED"
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", LibraryRandom.RandDec(10, 2), LocationRed.Code, '');

        // [THEN] Production Order Component for Item "COMP" has Plannning Level Code = 0
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Planning Level Code", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLevelCodeIncreasedMTOSKUForMTOProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Make-to-Order] [Prod. Order Component]
        // [SCENARIO 333008] Production Order Component for an MTO Item with an MTO SKU has Planning Level Code increased
        Initialize();

        // [GIVEN] Component MTO Item "COMP" With Make-to-Order Stockkeeping Unit for location "RED"
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);
        CreateStockkkeepingUnit(SKU, CompItem."No.", LocationRed.Code, SKU."Manufacturing Policy"::"Make-to-Order");

        // [GIVEN] Production MTO Item "PROD" with Component "COMP"
        CreateMakeToOrderProductionItem(ProdItem, CompItem);

        // [WHEN] Create And Refresh Released Production Order for Item "PROD" and location "RED"
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", LibraryRandom.RandDec(10, 2), LocationRed.Code, '');

        // [THEN] Production Order Component for Item "COMP" has Plannning Level Code = 1
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Planning Level Code", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ScrapPercAndFixedScrapQtyOnReplanProductionOrder()
    var
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ScrapPerc: Decimal;
        FixedScrapQty: Decimal;
        OutputQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Replan Production Order] [Scrap] [Routing] [Output]
        // [SCENARIO 349584] Scrap % and fixed scrap quantity are added to output quantity on replanning production order.
        Initialize();
        ScrapPerc := LibraryRandom.RandInt(10);
        FixedScrapQty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Create and certify routing "R" with two lines.
        // [GIVEN] First line. Work center "A", Run Time = 2, Scrap Factor = 10, Fixed Scrap Qty. = 20.
        // [GIVEN] Second line. Work center "B", Run Time = 2, Scrap Factor = 10, Fixed Scrap Qty. = 20.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 1 to ArrayLen(WorkCenter) do begin
            CreateWorkCenter(WorkCenter[i]);
            LibraryManufacturing.CreateRoutingLine(
              RoutingHeader, RoutingLine, '', Format(i), RoutingLine.Type::"Work Center", WorkCenter[i]."No.");
            RoutingLine.Validate("Run Time", LibraryRandom.RandInt(10));
            RoutingLine.Validate("Scrap Factor %", ScrapPerc);
            RoutingLine.Validate("Fixed Scrap Quantity", FixedScrapQty);
            RoutingLine.Modify(true);
        end;
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Create item with the routing "R".
        CreateProductionItemWithRoutingNo(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh production order. Quantity = 5.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Replan the production order.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"No Levels");

        // [THEN] Explode routing in output journal.
        // [THEN] Look through output lines from last to first and verify quantity.
        // [THEN] Output quantity on the second line = 5 (prod. order) * 1.1 (added 10% scrap) + 20 (fixed scrap) = 25.5
        // [THEN] Output quantity on the first line = 25.5 (from the second line) * 1.1 (added 10% scrap) + 20 (fixed scrap) = 48.05
        ExplodeRoutingForProductionOrder(ItemJournalLine, ProductionOrder."No.");
        OutputQty := ProductionOrder.Quantity;
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        for i := ArrayLen(WorkCenter) downto 1 do begin
            ItemJournalLine.SetRange("Work Center No.", WorkCenter[i]."No.");
            ItemJournalLine.FindFirst();
            OutputQty := OutputQty * (1 + ScrapPerc / 100) + FixedScrapQty;
            ItemJournalLine.TestField("Output Quantity", OutputQty);
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure OutputQuantityOnFinishWithBackwardFlushingNotLastOperation()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        JournalOutputQty: Decimal;
        OperationNo: array[3] of Code[10];
        FinishedProdOrderNo: Code[20];
        I: Integer;
    begin
        // [FEATURE] [Output] [Flushing] [Backward]
        // [SCENARIO 360372] Output Quantity in Capacity Ledger Entry for Backward Flushing not posted on Finished Production Order when already posted in Output Journal
        Initialize();

        // [GIVEN] Create and certify routing "R" with three lines.
        // [GIVEN] Operation "10", Work center "A", "Flushing Method" = "Backward"
        // [GIVEN] Operation "20", Work center "B", "Flushing Method" = "Backward"
        // [GIVEN] Operation "30", Work center "C", "Flushing Method" = "Manual"
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for I := 1 to ArrayLen(OperationNo) - 1 do
            OperationNo[I] :=
              CreateRoutingLineWithWorkCenterFlushingMethod(RoutingLine, RoutingHeader, "Flushing Method Routing"::Backward);
        OperationNo[ArrayLen(OperationNo)] :=
          CreateRoutingLineWithWorkCenterFlushingMethod(RoutingLine, RoutingHeader, "Flushing Method Routing"::Manual);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item "I" with Routing "R"
        LibraryInventory.CreateItem(Item);
        UpdateRoutingOnItem(Item."No.", RoutingHeader."No.");

        // [GIVEN] Released Production Order "RPO" for Item "I" and Quantity = 10, refreshed
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);

        // [GIVEN] Output Journal line posted for "RPO", operation "10", "Output Quantity" = 4
        // [GIVEN] Output Journal line posted for "RPO", operation "20", "Output Quantity" = 5
        // [GIVEN] Output Journal line posted for "RPO", operation "30", "Output Quantity" = 6
        JournalOutputQty := LibraryRandom.RandDecInDecimalRange(0, ProdOrderLine.Quantity, 2);
        for I := 1 to ArrayLen(OperationNo) - 1 do
            CreateAndPostOutputJnlForProdOrderLine(
              ProdOrderLine, RoutingHeader."No.", OperationNo[I], LibraryRandom.RandDec(5, 0),
              LibraryRandom.RandDecInDecimalRange(0, JournalOutputQty, 2));
        CreateAndPostOutputJnlForProdOrderLine(
          ProdOrderLine, RoutingHeader."No.", OperationNo[ArrayLen(OperationNo)], LibraryRandom.RandDec(5, 0), JournalOutputQty);

        // [WHEN] Change Production Order status from "Released" to "Finished"
        LibraryVariableStorage.Enqueue(ConfirmStatusFinishTxt);
        FinishedProdOrderNo :=
          LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status::Released, ProductionOrder.Status::Finished);

        // [THEN] Capacity Ledger Entries for operations "10", "20", "30" have total "Output Quantity" = 7 each
        for I := 1 to ArrayLen(OperationNo) do
            VerifyOutputOnCapLedgerEntries(FinishedProdOrderNo, OperationNo[I], JournalOutputQty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputQuantityOnFinishWithBackwardFlushingLastOperation()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        JournalOutputQty: Decimal;
        OperationNo: array[3] of Code[10];
        I: Integer;
        FinishedProdOrderNo: Code[20];
    begin
        // [FEATURE] [Output] [Flushing] [Backward]
        // [SCENARIO 360372] Output Quantity in Capacity Ledger Entry for Backward Flushing not posted on Finished Production Order when already posted in Output Journal
        Initialize();

        // [GIVEN] Create and certify routing "R" with three lines.
        // [GIVEN] Operation "10", Work center "A", "Flushing Method" = "Backward"
        // [GIVEN] Operation "20", Work center "B", "Flushing Method" = "Backward"
        // [GIVEN] Operation "30", Work center "C", "Flushing Method" = "Backward"
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for I := 1 to ArrayLen(OperationNo) do
            OperationNo[I] :=
              CreateRoutingLineWithWorkCenterFlushingMethod(RoutingLine, RoutingHeader, WorkCenter."Flushing Method"::Backward);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item "I" with Routing "R"
        LibraryInventory.CreateItem(Item);
        UpdateRoutingOnItem(Item."No.", RoutingHeader."No.");

        // [GIVEN] Released Production Order "RPO" for Item "I" and Quantity = 10, refreshed
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');
        FindFirstProdOrderLine(ProdOrderLine, ProductionOrder);

        // [GIVEN] Output Journal line posted for "RPO", operation "10", "Output Quantity" = 4
        // [GIVEN] Output Journal line posted for "RPO", operation "20", "Output Quantity" = 5
        // [GIVEN] Output Journal line posted for "RPO", operation "30", "Output Quantity" = 6
        JournalOutputQty := LibraryRandom.RandDecInDecimalRange(0, ProdOrderLine.Quantity, 2);
        for I := 1 to ArrayLen(OperationNo) - 1 do
            CreateAndPostOutputJnlForProdOrderLine(
              ProdOrderLine, RoutingHeader."No.", OperationNo[I], LibraryRandom.RandDec(5, 0),
              LibraryRandom.RandDecInDecimalRange(0, JournalOutputQty, 2));
        CreateAndPostOutputJnlForProdOrderLine(
          ProdOrderLine, RoutingHeader."No.", OperationNo[ArrayLen(OperationNo)], LibraryRandom.RandDec(5, 0), JournalOutputQty);

        // [WHEN] Change Production Order status from "Released" to "Finished"
        FinishedProdOrderNo :=
          LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status::Released, ProductionOrder.Status::Finished);

        // [THEN] Capacity Ledger Entries for operations "10", "20", "30" have total "Output Quantity" = 10 each
        for I := 1 to ArrayLen(OperationNo) do
            VerifyOutputOnCapLedgerEntries(FinishedProdOrderNo, OperationNo[I], ProdOrderLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RoutingCannotBeShiftedForwardWhenThisLeadsToDateConflictInReservation()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Make-to-Order] [Routing] [Reservation]
        // [SCENARIO 375425] Routing cannot be shifted ahead on low-level item in Make-to-Order production order if this leads to date conflict in reservation of the parent item.
        Initialize();

        // [GIVEN] Make-to-order production chain - finished item "A" and its component "B".
        CreateProductionItem(ChildItem, '');
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Modify(true);
        CreateRoutingAndUpdateItem(ChildItem);

        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Sales order for 10 pcs of item "A".
        // [GIVEN] Create firm planned production order from the sales order.
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", LibraryRandom.RandInt(10), '');
        LibraryVariableStorage.Enqueue('Prod. Order');
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", ParentItem."No.");

        // [GIVEN] Ensure that the sales line is now reserved.
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);

        FindProductionOrderLine(ProdOrderLine, ChildItem."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Move Starting Date 10 days ahead on prod. order routing line for component item "B".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        asserterror ProdOrderRoutingLine.Validate(
            "Starting Date", LibraryRandom.RandDateFromInRange(ProdOrderRoutingLine."Starting Date", 10, 20));

        // [THEN] The "Date conflict during reservation..." error message is thrown.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(DateConflictInReservErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RoutingCanBeShiftedForwardWhenThisDoesNotLeadToDateConflictInReservation()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Make-to-Order] [Routing] [Reservation]
        // [SCENARIO 375425] Routing be shifted ahead on low-level item in Make-to-Order production order if this does not lead to date conflict in reservation of the parent item.
        Initialize();

        // [GIVEN] Make-to-order production chain - finished item "A" and its component "B".
        CreateProductionItem(ChildItem, '');
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Modify(true);
        CreateRoutingAndUpdateItem(ChildItem);

        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");
        ParentItem.Validate("Manufacturing Policy", ParentItem."Manufacturing Policy"::"Make-to-Order");
        ParentItem.Modify(true);

        // [GIVEN] Sales order for 10 pcs of item "A".
        // [GIVEN] Create firm planned production order from the sales order.
        CreateSalesOrder(SalesHeader, SalesLine, ParentItem."No.", LibraryRandom.RandInt(10), '');
        LibraryVariableStorage.Enqueue('Prod. Order');
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", ParentItem."No.");

        // [GIVEN] Move "Shipment Date" on the sales order line 30 days adead.
        SalesLine.Find();
        SalesLine.Validate("Shipment Date", LibraryRandom.RandDateFromInRange(SalesLine."Shipment Date", 30, 40));
        SalesLine.Modify(true);

        FindProductionOrderLine(ProdOrderLine, ChildItem."No.");
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProdOrderLine);

        // [WHEN] Move Starting Date 10 days forward on prod. order routing line for component item "B".
        LibraryVariableStorage.Enqueue(TimeShiftedOnParentLineMsg);
        ProdOrderRoutingLine.Validate(
          "Starting Date", LibraryRandom.RandDateFromInRange(ProdOrderRoutingLine."Starting Date", 10, 20));
        ProdOrderRoutingLine.Modify(true);

        // [THEN] No "Date conflict during reservation..." error message is thrown.
        // [THEN] "Shipment Date" on reservation entries for low-level item is moved 10 days ahead.
        ProdOrderLine.Find();
        ReservationEntry.SetSourceFilter(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, false);
        ReservationEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Shipment Date", ProdOrderRoutingLine."Ending Date");
        ReservationEntry.TestField("Shipment Date", ProdOrderLine."Due Date");

        // [THEN] "Shipment Date" on reservation entry for top-level item is moved 30 days ahead.
        FindProductionOrderLine(ProdOrderLine, ParentItem."No.");
        ReservationEntry.SetSourceFilter(
          DATABASE::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", 0, false);
        ReservationEntry.SetSourceFilter('', ProdOrderLine."Line No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Shipment Date", SalesLine."Shipment Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure UsingRemainingQtyOnFlushingConsumptionInMakeToOrder()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProdItemUnitOfMeasure: Record "Item Unit of Measure";
        CompItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitOfMeasureMgt: Codeunit "Unit of Measure Management";
        ProdItemQtyPer: Decimal;
        CompItemQtyPer: Decimal;
        ProdBOMQtyPer: Decimal;
    begin
        // [FEATURE] [Flushing] [Consumption]
        // [SCENARIO 423544] Flushing consumption on finishing production order takes remaining qty. of interim item in make-to-order production order.
        Initialize();
        ProdItemQtyPer := 12240;
        CompItemQtyPer := 60.96;
        ProdBOMQtyPer := 3;

        // [GIVEN] Interim production item "C" set up for backward flushing.
        // [GIVEN] Base unit of measure = "KG", alternate unit of measure = "BOX" = 60.96 "KG".
        CreateProductionItem(CompItem, '');
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::Backward);
        CompItem.Validate("Rounding Precision", UnitOfMeasureMgt.QtyRndPrecision());
        CompItem.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(CompItemUnitOfMeasure, CompItem."No.", CompItemQtyPer);

        // [GIVEN] Finished item "P".
        // [GIVEN] Base unit of measure = "PCS", alternate unit of measure = "PALLET" = 12240 "PCS".
        CreateProductionItem(ProdItem, '');
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ProdItemUnitOfMeasure, ProdItem."No.", ProdItemQtyPer);

        // [GIVEN] Create and cerfity production BOM. 1 "PALLET" of item "P" = 3 "BOX" of item "C".
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItemUnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", ProdBOMQtyPer);
        ProductionBOMLine.Validate("Unit of Measure Code", CompItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create make-to-order production order for items "P" and "C".
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", ProdItemQtyPer, '', '');

        // [GIVEN] Post output of the interim item "C".
        // [GIVEN] Post output of the finished good "P".
        FindProductionOrderLine(ProdOrderLine, CompItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
        FindProductionOrderLine(ProdOrderLine, ProdItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Finish the production order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The production order is finished.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [THEN] The component item "C" is backward flushed.
        // [THEN] Consumption quantity = output quantity = 3 * 60.96 "KG".
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, ProdBOMQtyPer * CompItemQtyPer);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, -ProdBOMQtyPer * CompItemQtyPer);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure FlushingQtyThatDiffersFromRemQtyByLessThanRoundingPrec()
    var
        ProdItem: Record Item;
        InterimItem: Record Item;
        CompItem: Record Item;
        ProdItemUnitOfMeasure: Record "Item Unit of Measure";
        InterimItemUnitOfMeasure: Record "Item Unit of Measure";
        CompItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        UnitOfMeasureMgt: Codeunit "Unit of Measure Management";
        ProdItemQtyPer: Decimal;
        InterimItemQtyPer: Decimal;
        CompItemQtyPer: Decimal;
        ProdBOMQtyPer: Decimal;
        InterimBOMQtyPer: Decimal;
    begin
        // [FEATURE] [Flushing] [Consumption]
        // [SCENARIO 423544] Flushing consumption on finishing production order takes remaining qty. of component item when the difference between remaining qty. and actual qty. is less than the rounding precision.
        Initialize();
        ProdItemQtyPer := 12240;
        InterimItemQtyPer := 60.96;
        CompItemQtyPer := 0.44444;
        ProdBOMQtyPer := 3;
        InterimBOMQtyPer := 0.22;

        // [GIVEN] Component item "C" set up for backward flushing.
        // [GIVEN] Base unit of measure = "CAN", alternate unit of measure = "KG" = 0.44444 "CAN".
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::Backward);
        CompItem.Validate("Rounding Precision", UnitOfMeasureMgt.QtyRndPrecision());
        CompItem.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(CompItemUnitOfMeasure, CompItem."No.", CompItemQtyPer);

        // [GIVEN] Interim production item "I" set up for backward flushing.
        // [GIVEN] Base unit of measure = "KG", alternate unit of measure = "BOX" = 60.96 "KG".
        CreateProductionItem(InterimItem, '');
        InterimItem.Validate("Manufacturing Policy", InterimItem."Manufacturing Policy"::"Make-to-Order");
        InterimItem.Validate("Flushing Method", InterimItem."Flushing Method"::Backward);
        InterimItem.Validate("Rounding Precision", UnitOfMeasureMgt.QtyRndPrecision());
        InterimItem.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(InterimItemUnitOfMeasure, InterimItem."No.", InterimItemQtyPer);

        // [GIVEN] Finished item "P".
        // [GIVEN] Base unit of measure = "PCS", alternate unit of measure = "PALLET" = 12240 "PCS".
        CreateProductionItem(ProdItem, '');
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ProdItemUnitOfMeasure, ProdItem."No.", ProdItemQtyPer);

        // [GIVEN] Create and cerfity production BOM. 1 "PALLET" of item "P" = 3 "BOX" of item "I".
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItemUnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, InterimItem."No.", ProdBOMQtyPer);
        ProductionBOMLine.Validate("Unit of Measure Code", InterimItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create and cerfity production BOM. 1 "BOX" of item "I" = 0.22 "KG" of item "C".
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, InterimItemUnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", InterimBOMQtyPer);
        ProductionBOMLine.Validate("Unit of Measure Code", CompItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        InterimItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        InterimItem.Modify(true);

        // [GIVEN] Create make-to-order production order for items "P" and "C".
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", ProdItemQtyPer, '', '');

        // [GIVEN] Post component item "C" to inventory.
        CreateAndPostItemJournalLine(CompItem."No.", LibraryRandom.RandIntInRange(20, 40), '', '', false);

        // [GIVEN] Post output of the interim item "C".
        // [GIVEN] Post output of the finished good "P".
        FindProductionOrderLine(ProdOrderLine, InterimItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
        FindProductionOrderLine(ProdOrderLine, ProdItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Finish the production order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The production order is finished.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [THEN] The component item "C" is backward flushed.
        // [THEN] Consumption quantity = 3 * 0.22 * 0.44444 = 0.29333 "CAN".
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(
          Quantity, -Round(ProdBOMQtyPer * InterimBOMQtyPer * CompItemQtyPer, CompItem."Rounding Precision"));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalValidateItemNo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SavedGenProdPostingGroup: Code[20];
    begin
        // [FEATURE] [Output Journal]
        // [SCENARIO 429057] Gen. Prod. Posting Group is not changed when validating Item No. for output journal filled in with Explode Routing
        Initialize();

        // [GIVEN] Item with "Gen. Prod. Posting Group" = "X" 
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mock output journal line with "Gen. Prod. Posting Group" = "Y"
        CreateOutputItemJournalLine(ItemJournalLine, Item."No.", 1);
        ChangeItemJnlLineGenProdPostingGroup(ItemJournalLine);
        SavedGenProdPostingGroup := ItemJournalLine."Gen. Prod. Posting Group";
        Assert.AreNotEqual(Item."Gen. Prod. Posting Group", SavedGenProdPostingGroup, 'Groups must be different');

        // [WHEN] Validate same Item No.
        ItemJournalLine.Validate("Item No.", Item."No.");

        // [THEN] "Gen. Prod. Posting Group" is not changed
        ItemJournalLine.TestField("Gen. Prod. Posting Group", SavedGenProdPostingGroup);
    end;

    [Test]
    procedure PostingRemainingQtyWhenRoundedCalculatedAndRemQtyToConsumeAreNearlyEqual()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
        UOMMgt: Codeunit "Unit of Measure Management";
        RoutingLinkCode: Code[10];
        Qty: Decimal;
        ScrapPerc: Decimal;
    begin
        // [FEATURE] [Rounding] [Consumption] [Flushing]
        // [SCENARIO 423937] Posting remaining quantity of prod. order component when rounded calculated quantity to consume is nearly equal to the remaining quantity.
        Initialize();
        Qty := 3;
        ScrapPerc := 22.5;

        // [GIVEN] Production item "P", component item "C", quantity per = 1.
        // [GIVEN] Set "Rounding Precision" = 0.01 for the component.
        CreateItemsSetup(Item, ChildItem);
        ChildItem.Validate("Rounding Precision", 0.01);
        ChildItem.Modify(true);

        // [GIVEN] Create routing with routing link.
        RoutingLinkCode := CreateRoutingAndUpdateItem(Item);
        UpdateRoutingLinkOnProductionBOMLine(Item."No.", ChildItem."No.", RoutingLinkCode);

        // [GIVEN] Post 3.68 pcs of item "C" to inventory.
        CreateAndPostItemJournalLine(
          ChildItem."No.",
          UOMMgt.RoundToItemRndPrecision(Qty * (1 + ScrapPerc / 100), ChildItem."Rounding Precision"), '', '', false);

        // [GIVEN] Create and refresh production order for 3 pcs of "P".
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Qty, '', '');

        // [GIVEN] Set up the prod. order component "C" for backward flushing and update "Scrap %" = 22.5.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::Backward);
        ProdOrderComponent.Validate("Scrap %", ScrapPerc);
        ProdOrderComponent.Modify(true);

        // [GIVEN] Post output for 1 pc of item "P" twice.
        // [GIVEN] The system posts automatic consumption of 1.23 pcs of the component "C".
        // [GIVEN] The precise quantity is 1.225 but it is rounded up to 1.23 according to the rounding precision of 0.01.
        CreateAndPostOutputJournal(ProductionOrder."No.", 1);
        CreateAndPostOutputJournal(ProductionOrder."No.", 1);

        // [WHEN] Post 1 pcs of "P" for the third time.
        CreateAndPostOutputJournal(ProductionOrder."No.", 1);

        // [THEN] The last consumption is posted for 1.22 so that the remaining quantity on the prod. order component = 0.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Item No.", ChildItem."No.");
        ItemLedgerEntry.FindLast();
        ItemLedgerEntry.TestField(Quantity, -1.22);
        ProdOrderComponent.Find();
        ProdOrderComponent.TestField("Remaining Quantity", 0);
    end;

    [Test]
    procedure ProdOrderComponentsWithDifferentCalculationFormulaNotCombined()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        QtyPer: Decimal;
        QtyFixed: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Prod. Order Component] [Calculation Formula]
        // [SCENARIO 436675] Prod. Order Components with different calculation formulas are not combined.
        Initialize();
        QtyPer := LibraryRandom.RandInt(10);
        QtyFixed := LibraryRandom.RandIntInRange(50, 100);
        Qty := LibraryRandom.RandIntInRange(200, 400);

        // [GIVEN] Component item "C".
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Production BOM with two lines - 
        // [GIVEN] 1st line: item = "C", quantity per = 2, calculation formula = <blank>.
        // [GIVEN] 2nd line: item = "C", quantity per = 100, calculation formula = "Fixed Quantity".
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, CompItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", QtyPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", QtyFixed);
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Production item "P", select the production BOM.
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");

        // [WHEN] Create and refresh production order for 500 qty. of item "P".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Two prod. order components have been created -
        // [THEN] Component 1: item = "C", calculation formula = <blank>, expected quantity = 500 * 2 = 1000.
        ProdOrderComponent.SetRange("Calculation Formula", ProdOrderComponent."Calculation Formula"::" ");
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Expected Quantity", Qty * QtyPer);

        // [THEN] Component 2: item = "C", calculation formula = "Fixed Quantity", expected quantity = 100.
        ProdOrderComponent.SetRange("Calculation Formula", ProdOrderComponent."Calculation Formula"::"Fixed Quantity");
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Expected Quantity", QtyFixed);
    end;

    [Test]
    procedure PlanningComponentsWithDifferentCalculationFormulaNotCombined()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        QtyPer: Decimal;
        QtyFixed: Decimal;
        Qty: Decimal;
    begin
        // [FEATURE] [Planning Component] [Calculation Formula]
        // [SCENARIO 436675] Planning Components with different calculation formulas are not combined.
        Initialize();
        QtyPer := LibraryRandom.RandInt(10);
        QtyFixed := LibraryRandom.RandIntInRange(50, 100);
        Qty := LibraryRandom.RandIntInRange(200, 400);

        // [GIVEN] Component item "C".
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Production BOM with two lines - 
        // [GIVEN] 1st line: item = "C", quantity per = 2, calculation formula = <blank>.
        // [GIVEN] 2nd line: item = "C", quantity per = 100, calculation formula = "Fixed Quantity".
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, CompItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", QtyPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", QtyFixed);
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Production item "P", select the production BOM, set "Reordering Policy" = Order.
        CreateProductionItem(ProdItem, ProductionBOMHeader."No.");
        ProdItem.Validate("Reordering Policy", ProdItem."Reordering Policy"::Order);
        ProdItem.Modify(true);

        // [GIVEN] Sales order for 500 qty. of item "P".
        CreateSalesOrder(SalesHeader, SalesLine, ProdItem."No.", Qty, '');

        // [WHEN] Calculate regenerative plan for item "P".
        ProdItem.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(ProdItem, WorkDate(), WorkDate());

        // [THEN] Item "P" has been planned.
        FindRequisitionLine(RequisitionLine, ProdItem."No.");

        // [THEN] Two planning components have been created -
        // [THEN] Component 1: item = "C", calculation formula = <blank>, expected quantity = 500 * 2 = 1000.
        PlanningComponent.SetRange("Calculation Formula", PlanningComponent."Calculation Formula"::" ");
        FindPlanningComponent(PlanningComponent, RequisitionLine, CompItem."No.");
        PlanningComponent.TestField("Expected Quantity", Qty * QtyPer);

        // [THEN] Component 2: item = "C", calculation formula = "Fixed Quantity", expected quantity = 100.
        PlanningComponent.SetRange("Calculation Formula", PlanningComponent."Calculation Formula"::"Fixed Quantity");
        FindPlanningComponent(PlanningComponent, RequisitionLine, CompItem."No.");
        PlanningComponent.TestField("Expected Quantity", QtyFixed);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProdOrderWithChildLineWithInboundWhseHandlingTime()
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        InboundWhseHandlingTimeDateFormula: DateFormula;
        LocationCode: Code[10];
        ItemNo: array[2] of Code[20];
    begin
        // [FEATURE] [Default Safety Lead Time] [Inbound Whse. Handling Time] [Make-to-Order] [Replan Production Order]
        // [SCENARIO 449673] Due Date in child Production Order is equal to Ending Date in main Production Order.
        Initialize();

        // [GIVEN] Set "Default Safety Lead Time" to 1 day.
        LibraryPlanning.SetDefaultSafetyLeadTime('<1D>');

        // [GIVEN] Create Location with "Inbound Whse. Handling Time" set to 2 days.
        LocationCode := LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Evaluate(InboundWhseHandlingTimeDateFormula, '<2D>');
        Location.Validate("Inbound Whse. Handling Time", InboundWhseHandlingTimeDateFormula);
        Location.Modify(true);

        // [GIVEN] Production chain - a purchased component and two levels of manufacturing items: "I1" and "I2". "I2" is the highest level.
        // [GIVEN] Item "I2" have Make-to-Order manufacturing policy.
        CreateProductionChainOfItems(ItemNo, 2);

        // [GIVEN] Firm planned Production Order "PO2" for item "I2". Quantity = "Q".
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ItemNo[2], LibraryRandom.RandIntInRange(11, 20), LocationCode, '');

        // [WHEN] Replan procedure is run for "PO2".
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All levels");

        // [THEN] Another Production Order "PO1" for child Item "I1" is created.
        FindProductionOrderLine(ProdOrderLine[1], ItemNo[1]);
        FindProductionOrderLine(ProdOrderLine[2], ItemNo[2]);

        // [THEN] Check that "PO1 Line"."Due Date" is equal to "PO2 Line"."Starting Date"
        ProdOrderLine[1].TestField("Due Date", ProdOrderLine[2]."Starting Date");

        // [THEN] Check that "PO1 Line"."Ending Date" is 3 days before "Due Date"
        ProdOrderLine[1].TestField("Ending Date", CalcDate('<-3D>', ProdOrderLine[1]."Due Date"));
    end;

    [Test]
    procedure VerifyRefreshFirmPlannedProductionOrderForAddtionalItemUoMWithRoudingPrecision()
    var
        CompItem, ProdItem : Record Item;
        CompItemUnitOfMeasure, ProdItemUnitOfMeasure : Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdItemQtyPer, RoundPrecision, ProdItemUoMQty, ProdBOMQtyPer : Decimal;
    begin
        // [SCENARIO 463487] Verify Refresh Firm Planned Production Order for Additional Item UoM with Rouding Precision
        Initialize();

        ProdItemQtyPer := 310;
        ProdItemUoMQty := 155;
        ProdBOMQtyPer := 18.5;
        RoundPrecision := 0.0001;

        // [GIVEN] Create Component Item
        CreateProductionItem(CompItem, '');
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::Purchase);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::"Pick + Manual");
        CompItem.Validate("Purch. Unit of Measure", CompItem."Base Unit of Measure");
        CompItem.Validate("Rounding Precision", RoundPrecision);
        CompItem.Modify(true);

        // [GIVEN] Update Rounding Precision on Item Unit of Measure
        CompItemUnitOfMeasure.Get(CompItem."No.", CompItem."Base Unit of Measure");
        CompItemUnitOfMeasure.Validate("Qty. Rounding Precision", RoundPrecision);
        CompItemUnitOfMeasure.Modify(true);

        // [GIVEN] Create Producition Item
        CreateProductionItem(ProdItem, '');
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Stock");
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Flushing Method", ProdItem."Flushing Method"::"Pick + Manual");
        ProdItem.Validate("Rounding Precision", 0.00001);
        ProdItem.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ProdItemUnitOfMeasure, ProdItem."No.", ProdItemUoMQty);
        ProdItemUnitOfMeasure.Validate(Weight, ProdItemUoMQty);
        ProdItemUnitOfMeasure.Modify(true);

        // [GIVEN] Create and cerfity production BOM.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItemUnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", ProdBOMQtyPer);
        ProductionBOMLine.Validate("Unit of Measure Code", CompItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Assign Prod. BOM No. to Production Item
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [THEN] Verify refresh production order without error
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ProdItem."No.", ProdItemQtyPer, '', '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    procedure S463293_VerifyWarehousePickFromProductionOrderForItemWithFEFO_WithEarlierLotAlreadyPickedForAnotherProdOrder()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ComponentItem: array[2] of Record Item;
        ProducedItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Location: Record Location;
        Bin: array[4] of Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: array[2] of Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[4] of Code[20];
        QuantityToUse: Decimal;
        ExpirationDate: array[2] of Date;
    begin
        // [FEATURE] [Item Tracking] [Lot Warehouse Tracking] [Use Expiration Dates] [Production BOM] [Released Production Order] [Warehpuse Pick]
        // [SCENARIO 463293] Create Warehouse Pick from Production Order for Item with FEFO Picking when earlier Lots are already picked for another Production Order.
        Initialize();

        QuantityToUse := 10;
        ExpirationDate[1] := WorkDate() - 20;
        ExpirationDate[2] := WorkDate() - 10;

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Component Item [1] with "Item Tracking Code".
        LibraryInventory.CreateItem(ComponentItem[1]);
        ComponentItem[1].Validate("Item Tracking Code", ItemTrackingCode.Code);
        ComponentItem[1].Modify(true);

        // [GIVEN] Create Component Item [2] with "Item Tracking Code".
        LibraryInventory.CreateItem(ComponentItem[2]);
        ComponentItem[2].Validate("Item Tracking Code", ItemTrackingCode.Code);
        ComponentItem[2].Modify(true);

        // [GIVEN] Create Producition Item.
        LibraryInventory.CreateItem(ProducedItem);
        ProducedItem.Validate("Replenishment System", ProducedItem."Replenishment System"::"Prod. Order");
        ProducedItem.Modify(true);

        // [GIVEN] Create and cerfity production BOM with Component Item [1] and Component Item [2] in lines.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProducedItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem[1]."No.", 1);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem[1]."Base Unit of Measure");
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem[2]."No.", 1);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem[2]."Base Unit of Measure");
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Assign Prod. BOM No. to Produced Item.
        ProducedItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProducedItem.Modify(true);

        // [GIVEN] Create and setup Location.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);

        // [GIVEN] Create Bin "B1" and set it as "Shipment Bin Code" at Location.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", Bin[1].Code);

        // [GIVEN] Create Bin "B2" and set it as "To-Production Bin Code" at Location.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("To-Production Bin Code", Bin[2].Code);

        // [GIVEN] Create Bin "B3" and set it as "From-Production Bin Code" at Location.
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Production Bin Code", Bin[3].Code);

        // [GIVEN] Set "Pick According to FEFO" at Location.
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        // [GIVEN] Set Warehouse Employee for Location as default.
        WarehouseEmployee.SetRange("User ID", UserId());
        WarehouseEmployee.DeleteAll();
        WarehouseEmployee.Reset();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create Bin "B4" at Location for Stock.
        LibraryWarehouse.CreateBin(Bin[4], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Put "Lot1" on stock.
        LotNo[1] := LibraryUtility.GenerateGUID();
        PostPositiveAdjustmentWithLotNo(ComponentItem[1]."No.", Location.Code, Bin[4].Code, QuantityToUse, LotNo[1], ExpirationDate[1]);

        // [GIVEN] Put "Lot2" on stock.
        LotNo[2] := LibraryUtility.GenerateGUID();
        PostPositiveAdjustmentWithLotNo(ComponentItem[2]."No.", Location.Code, Bin[4].Code, QuantityToUse, LotNo[2], ExpirationDate[1]);

        // [GIVEN] Put "Lot3" on stock.
        LotNo[3] := LibraryUtility.GenerateGUID();
        PostPositiveAdjustmentWithLotNo(ComponentItem[1]."No.", Location.Code, Bin[4].Code, QuantityToUse, LotNo[3], ExpirationDate[2]);

        // [GIVEN] Put "Lot4" on stock.
        LotNo[4] := LibraryUtility.GenerateGUID();
        PostPositiveAdjustmentWithLotNo(ComponentItem[2]."No.", Location.Code, Bin[4].Code, QuantityToUse, LotNo[4], ExpirationDate[2]);

        // [GIVEN] Create and Refresh Released Production Order 1 for Produced Item.
        CreateAndRefreshProductionOrder(ProductionOrder[1], ProductionOrder[1].Status::Released, ProducedItem."No.", QuantityToUse, Location.Code, Location."To-Production Bin Code");

        // [GIVEN] Create Warehouse Pick for Released Production Order 1.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder[1]);

        // [GIVEN] Register Warehouse Pick.
        RegisterWarehouseActivity(ProductionOrder[1]."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Create and Refresh Released Production Order 2 for Produced Item.
        CreateAndRefreshProductionOrder(ProductionOrder[2], ProductionOrder[2].Status::Released, ProducedItem."No.", QuantityToUse, Location.Code, Location."To-Production Bin Code");

        // [WHEN] Create Warehouse Pick for Released Production Order 2.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder[2]);

        // [THEN] Verify lines of created Warehouse Pick.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", ComponentItem[1]."No.");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder[2]."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, QuantityToUse);
        WarehouseActivityLine.TestField("Lot No.", LotNo[3]);
        WarehouseActivityLine.TestField("Expiration Date", ExpirationDate[2]);

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", ComponentItem[2]."No.");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder[2]."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, QuantityToUse);
        WarehouseActivityLine.TestField("Lot No.", LotNo[4]);
        WarehouseActivityLine.TestField("Expiration Date", ExpirationDate[2]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    procedure S463293_VerifyWarehousePickFromProductionOrderForItemWithFEFO_WithEarlierLotAlreadyPickedForOtherProdOrder_DedicatedBin()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ComponentItem: array[2] of Record Item;
        ProducedItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Location: Record Location;
        Bin: array[4] of Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: array[2] of Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[4] of Code[20];
        QuantityToUse: Decimal;
        ExpirationDate: array[2] of Date;
    begin
        // [FEATURE] [Item Tracking] [Lot Warehouse Tracking] [Use Expiration Dates] [Production BOM] [Released Production Order] [Warehpuse Pick]
        // [SCENARIO 463293] Create Warehouse Pick from Production Order for Item with FEFO Picking when earlier Lots are already picked for another Production Order.
        // [SCENARIO 476832] "To-Production Bin Code" is dedicated bin.
        Initialize();

        QuantityToUse := 10;
        ExpirationDate[1] := WorkDate() - 20;
        ExpirationDate[2] := WorkDate() - 10;

        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create Component Item [1] with "Item Tracking Code".
        LibraryInventory.CreateItem(ComponentItem[1]);
        ComponentItem[1].Validate("Item Tracking Code", ItemTrackingCode.Code);
        ComponentItem[1].Modify(true);

        // [GIVEN] Create Component Item [2] with "Item Tracking Code".
        LibraryInventory.CreateItem(ComponentItem[2]);
        ComponentItem[2].Validate("Item Tracking Code", ItemTrackingCode.Code);
        ComponentItem[2].Modify(true);

        // [GIVEN] Create Producition Item.
        LibraryInventory.CreateItem(ProducedItem);
        ProducedItem.Validate("Replenishment System", ProducedItem."Replenishment System"::"Prod. Order");
        ProducedItem.Modify(true);

        // [GIVEN] Create and cerfity production BOM with Component Item [1] and Component Item [2] in lines.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProducedItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem[1]."No.", 1);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem[1]."Base Unit of Measure");
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem[2]."No.", 1);
        ProductionBOMLine.Validate("Unit of Measure Code", ComponentItem[2]."Base Unit of Measure");
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Assign Prod. BOM No. to Produced Item.
        ProducedItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProducedItem.Modify(true);

        // [GIVEN] Create and setup Location.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);

        // [GIVEN] Create Bin "B1" and set it as "Shipment Bin Code" at Location.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", Bin[1].Code);

        // [GIVEN] Create Bin "B2" as Dedicated and set it as "To-Production Bin Code" at Location.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Bin[2].Validate(Dedicated, true);
        Bin[2].Modify(true);
        Location.Validate("To-Production Bin Code", Bin[2].Code);

        // [GIVEN] Create Bin "B3" and set it as "From-Production Bin Code" at Location.
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Production Bin Code", Bin[3].Code);

        // [GIVEN] Set "Pick According to FEFO" at Location.
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);

        // [GIVEN] Set Warehouse Employee for Location as default.
        WarehouseEmployee.SetRange("User ID", UserId());
        WarehouseEmployee.DeleteAll();
        WarehouseEmployee.Reset();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create Bin "B4" at Location for Stock.
        LibraryWarehouse.CreateBin(Bin[4], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Put "Lot1" on stock.
        LotNo[1] := LibraryUtility.GenerateGUID();
        PostPositiveAdjustmentWithLotNo(ComponentItem[1]."No.", Location.Code, Bin[4].Code, QuantityToUse, LotNo[1], ExpirationDate[1]);

        // [GIVEN] Put "Lot2" on stock.
        LotNo[2] := LibraryUtility.GenerateGUID();
        PostPositiveAdjustmentWithLotNo(ComponentItem[2]."No.", Location.Code, Bin[4].Code, QuantityToUse, LotNo[2], ExpirationDate[1]);

        // [GIVEN] Put "Lot3" on stock.
        LotNo[3] := LibraryUtility.GenerateGUID();
        PostPositiveAdjustmentWithLotNo(ComponentItem[1]."No.", Location.Code, Bin[4].Code, QuantityToUse, LotNo[3], ExpirationDate[2]);

        // [GIVEN] Put "Lot4" on stock.
        LotNo[4] := LibraryUtility.GenerateGUID();
        PostPositiveAdjustmentWithLotNo(ComponentItem[2]."No.", Location.Code, Bin[4].Code, QuantityToUse, LotNo[4], ExpirationDate[2]);

        // [GIVEN] Create and Refresh Released Production Order 1 for Produced Item.
        CreateAndRefreshProductionOrder(ProductionOrder[1], ProductionOrder[1].Status::Released, ProducedItem."No.", QuantityToUse, Location.Code, Location."To-Production Bin Code");

        // [GIVEN] Create Warehouse Pick for Released Production Order 1.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder[1]);

        // [GIVEN] Register Warehouse Pick.
        RegisterWarehouseActivity(ProductionOrder[1]."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Create and Refresh Released Production Order 2 for Produced Item.
        CreateAndRefreshProductionOrder(ProductionOrder[2], ProductionOrder[2].Status::Released, ProducedItem."No.", QuantityToUse, Location.Code, Location."To-Production Bin Code");

        // [WHEN] Create Warehouse Pick for Released Production Order 2.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder[2]);

        // [THEN] Verify lines of created Warehouse Pick.
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", ComponentItem[1]."No.");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder[2]."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, QuantityToUse);
        WarehouseActivityLine.TestField("Lot No.", LotNo[3]);
        WarehouseActivityLine.TestField("Expiration Date", ExpirationDate[2]);

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", ComponentItem[2]."No.");
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.SetRange("Source No.", ProductionOrder[2]."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField(Quantity, QuantityToUse);
        WarehouseActivityLine.TestField("Lot No.", LotNo[4]);
        WarehouseActivityLine.TestField("Expiration Date", ExpirationDate[2]);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CalculatePlanPlanWkshRequestPageHandler')]
    procedure VerifyPlannedProdOrderForOptimizeLowLevelCodeCalculationWithCompLocationSortedBeforeSalesLocation()
    var
        LocationBlue: Record Location;
        Level2Item, Level1Item, Level0Item : Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseEmployee: Record "Warehouse Employee";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [SCENARIO 487326] Verify Planned Production Order for Optimize Low Level Code Calculation with Component Location sorted before Sales Location
        Initialize();

        // [GIVEN] Create Blue and Red Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] Activate Optimize Low Level Code Calculation on Manufacturing Setup
        LibraryPlanning.SetDemandForecast('');
        LibraryManufacturing.SetComponentsAtLocation(LocationBlue.Code);

        // [GIVEN] Set Mandatory Location on Inventory Setup
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Create Level 2 Item
        LibraryInventory.CreateItem(Level2Item);
        Level2Item.Validate("Reordering Policy", Level2Item."Reordering Policy"::"Lot-for-Lot");
        Level2Item.Modify(true);

        // [GIVEN] Create Level 1 Item
        LibraryInventory.CreateItem(Level1Item);
        CreateManufacturingItem(Level1Item, Level1Item."Reordering Policy"::Order, Level1Item."Replenishment System"::"Prod. Order");
        Level1Item.Validate("Manufacturing Policy", Level1Item."Manufacturing Policy"::"Make-to-Order");
        UpdateOrderTrackingPolicyOnItem(Level1Item, Level1Item."Order Tracking Policy"::"Tracking Only");

        // [GIVEN] Create and Certify Production BOM
        CreateCertifiedProductionBOM(ProductionBOMHeader, Level2Item);

        // [GIVEN] Create and Certify Routing
        CreateAndCertifiyRouting(RoutingHeader);

        // [GIVEN] Update Production BOM and Routing on Item
        UpdateProductionBomAndRoutingOnItem(Level1Item, ProductionBOMHeader."No.", RoutingHeader."No.");

        // [GIVEN] Create Level 0 Item
        LibraryInventory.CreateItem(Level0Item);
        CreateManufacturingItem(Level0Item, Level0Item."Reordering Policy"::Order, Level0Item."Replenishment System"::"Prod. Order");
        Level0Item.Validate("Manufacturing Policy", Level0Item."Manufacturing Policy"::"Make-to-Order");
        Level0Item.Validate("Flushing Method", Level0Item."Flushing Method"::Backward);
        UpdateOrderTrackingPolicyOnItem(Level0Item, Level0Item."Order Tracking Policy"::"Tracking Only");

        // [GIVEN] Create and Certified Production BOM
        CreateCertifiedProductionBOM(ProductionBOMHeader, Level1Item);

        // [GIVEN] Create and Certify Routing        
        CreateAndCertifiyRouting(RoutingHeader);

        // [GIVEN] Update Production BOM and Routing on Item
        UpdateProductionBomAndRoutingOnItem(Level0Item, ProductionBOMHeader."No.", RoutingHeader."No.");

        // [GIVEN] Create Warehouse Employee for Blue and Red Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationBlue.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);

        // [GIVEN] Create Sales Order for Level 0 Item
        CreateSalesOrder(SalesHeader, SalesLine, Level0Item."No.", LibraryRandom.RandInt(10), LocationRed.Code);

        // Set to calculate MPS
        LibraryVariableStorage.Enqueue(true);

        // [GIVEN] Carry Out Planning Worksheet as Firm Planned Production Order.        
        CalcRegenPlanForPlanningWorksheetPage(PlanningWorksheet, Level0Item."No.", Level1Item."No.", false);

        // [GIVEN] Accept Action Message for Requisition Lines
        AcceptActionMessage(RequisitionLine, Level0Item."No.");
        AcceptActionMessage(RequisitionLine, Level1Item."No.");

        // [WHEN] Run Carry Out Action Message - Plan.
        RunRequisitionCarryOutReportProdOrder(RequisitionLine);

        // [THEN] Verify Parent and Child items are carried out into one Firm Planned Production Order.
        FilterFirmPlannedProductionOrder(ProductionOrder, Level0Item."No.");
        FindProductionOrderLine(ProdOrderLine, Level0Item."No.");
        ProductionOrder.TestField("No.", ProdOrderLine."Prod. Order No.");
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyRefreshReleasedProductionOrderForAddtionalItemUoMWithRoudingPrecision()
    var
        CompItem, ProdItem : Record Item;
        CompItemUnitOfMeasure, ProdItemUnitOfMeasure : array[2] of Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RoundPrecision: Decimal;
    begin
        // [SCENARIO 492441] Verify Quantity Rounding in Production Order working as expected.
        Initialize();

        // [GIVEN] Save Rounding Precision.
        RoundPrecision := 0.00001;

        // [GIVEN] Set the location mandatory to false in inventory setup.
        LibraryInventory.SetLocationMandatory(false);

        // [GIVEN] Create a component item with an item unit of measure code.
        CreateComponentItemWithItemUnitOfMeasureCode(CompItem, CompItemUnitOfMeasure);

        // [GIVEN] Create a production BOM for the component item.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, CompItemUnitOfMeasure[2].Code);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Update the component item.
        CompItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        CompItem.Validate("Base Unit of Measure", CompItemUnitOfMeasure[1].Code);
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::"Pick + Backward");
        CompItem.Validate("Purch. Unit of Measure", CompItem."Base Unit of Measure");
        CompItem.Validate("Rounding Precision", RoundPrecision);
        CompItem.Modify(true);

        // [GIVEN] Create a production item with an item unit of measure code.
        CreateProductionItemWithItemUnitOfMeasureCode(ProdItem, ProdItemUnitOfMeasure);

        // [GIVEN] Create a production BOM for the production item.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItemUnitOfMeasure[2].Code);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", LibraryRandom.RandIntInRange(1, 1));
        ProductionBOMLine.Validate("Unit of Measure Code", CompItemUnitOfMeasure[2].Code);
        ProductionBOMLine.Modify(true);

        // [GIVEN] Change status of production BOM to Certified for the production item.
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Update the production item.
        ProdItem.Validate("Base Unit of Measure", ProdItemUnitOfMeasure[1].Code);
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Flushing Method", ProdItem."Flushing Method"::"Pick + Backward");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Purch. Unit of Measure", ProdItem."Base Unit of Measure");
        ProdItem.Validate("Rounding Precision", RoundPrecision);
        ProdItem.Modify(true);

        // [GIVEN] Refresh the production order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", LibraryRandom.RandIntInRange(22, 22), '', '');

        // [GIVEN] Post the production journal for the component item.
        FindProductionOrderLine(ProdOrderLine, CompItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Post the production journal for the production item.
        FindProductionOrderLine(ProdOrderLine, ProdItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Finish the production order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [VERIFY] Verify that the status of the production order has been finished successfully.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalPageHandlerOnlyOutput,ConfirmHandlerTrue,MessageHandler')]
    procedure VerifyILEQuantityWhenFlushingMethodIsBackward()
    var
        CompItem, CompItem2, ProdItem : Record Item;
        CompItemUnitOfMeasure, CompItemUnitOfMeasure2, ProdItemUnitOfMeasure : array[2] of Record "Item Unit of Measure";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionJournalMgt: codeunit "Production Journal Mgt";
        QuantityCalculationFormula: Enum "Quantity Calculation Formula";
        ConsumptionQuantity: Decimal;
        ConsumptionQuantity2: Decimal;
    begin
        // [SCENARIO 497746] When stan creates a Released Production Order using Backward Flushing Method, Quantities calculated in Item ledger Entries are correct.
        Initialize();

        // [GIVEN] Create Component Item with Item Unit of Measure Code.
        CreateComponentItemWithItemUnitOfMeasureCode(CompItem, CompItemUnitOfMeasure);

        // [GIVEN] Create Component Item 2 with Item Unit of Measure Code.
        CreateComponentItemWithItemUnitOfMeasureCode(CompItem2, CompItemUnitOfMeasure2);

        // [GIVEN] Create and Post two Item Journal Lines of Component Item and Component Item 2.
        CreateAndPostItemJournalLine(CompItem."No.", LibraryRandom.RandIntInRange(100, 100), '', '', false);
        CreateAndPostItemJournalLine(CompItem2."No.", LibraryRandom.RandIntInRange(100, 100), '', '', false);

        // [GIVEN] Create Production Item with Item Unit of Measure Code.
        CreateProductionItemWithItemUnitOfMeasureCode(ProdItem, ProdItemUnitOfMeasure);

        // [GIVEN] Create Routing Link.
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        // [GIVEN] Create Work Center and Validate Flushing Method, Capacity and Efficiency.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Validate(Capacity, LibraryRandom.RandInt(0));
        WorkCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        WorkCenter.Modify(true);

        // [GIVEN] Create and Certify Routing with Routing Link Code..
        CreateAndCertifyRoutingWithRoutingLinkCode(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingLink.Code);

        // [GIVEN] Create and Certify Production BOM with Routing Link Code.
        CreateAndCertifyProductionBOMwithRoutingLinkCode(ProductionBOMHeader, ProductionBOMLine, ProdItem, CompItem, CompItem2, RoutingLink);

        // [GIVEN] Update Production Item.
        ProdItem.Validate("Base Unit of Measure", ProdItemUnitOfMeasure[1].Code);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Flushing Method", ProdItem."Flushing Method"::Backward);
        ProdItem.Validate("Routing No.", RoutingHeader."No.");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Rounding Precision", 0.001);
        ProdItem.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProdItem."No.",
            LibraryRandom.RandIntInRange(10, 10),
            '',
            '');

        // [GIVEN] Find and Update Prod. Order Component of Component Item.
        FindAndUpdateProdOrderComponentWithCalcFormula(
            ProductionOrder,
            ProdOrderComponent,
            CompItem,
            RoutingLink,
            LibraryRandom.RandIntInRange(3, 3),
            LibraryRandom.RandInt(0),
            LibraryRandom.RandInt(0),
            QuantityCalculationFormula::Length);

        // [GIVEN] Generate and save Consumption Quantity in a Variable.
        ConsumptionQuantity := ProdOrderComponent."Quantity per" * ProdOrderComponent.Length * ProductionOrder.Quantity;

        // [GIVEN] Find and Update Prod. Order Component of Component Item 2.
        FindAndUpdateProdOrderComponentWithCalcFormula(
            ProductionOrder,
            ProdOrderComponent,
            CompItem2,
            RoutingLink,
            LibraryRandom.RandIntInRange(2, 2),
            LibraryRandom.RandIntInRange(2, 2),
            LibraryRandom.RandInt(0),
            QuantityCalculationFormula::"Length * Width");

        // [GIVEN] Generate and save Consumption Quantity 2 in a Variable.
        ConsumptionQuantity2 := ProdOrderComponent."Quantity per" * ProdOrderComponent.Length * ProdOrderComponent.Width * ProductionOrder.Quantity;

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Post Production Journal.
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);
        LibraryVariableStorage.Enqueue(PostingProductionJournalQst);
        LibraryVariableStorage.Enqueue(PostingProductionJournalTxt);
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Document No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.FindFirst();

        // [VERIFY] Consumption Quantity and Item Ledger Entry Quantity are same.
        Assert.AreEqual(
            -ConsumptionQuantity,
            ItemLedgerEntry.Quantity,
            StrSubstNo(
                QuantityErr,
                ItemLedgerEntry.FieldCaption(Quantity),
                -ConsumptionQuantity,
                ItemLedgerEntry.TableCaption()));

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Document No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Item No.", CompItem2."No.");
        ItemLedgerEntry.FindFirst();

        // [VERIFY] Consumption Quantity 2 and Item Ledger Entry Quantity are same.
        Assert.AreEqual(
            -ConsumptionQuantity2,
            ItemLedgerEntry.Quantity,
            StrSubstNo(
                QuantityErr,
                ItemLedgerEntry.FieldCaption(Quantity),
                -ConsumptionQuantity2,
                ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalPageHandler,GLPostingPreviewPageHandler')]
    procedure PreviewPostingOfProductionJournalPostsCorrectConsumptionILE()
    var
        Item, Item2 : Record Item;
        ProductionOrder, ProductionOrder2 : Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ReleasedProdOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 501883] When Preview Post or Post Production Journal From a Released Production Order, it creates correct Item Ledger Entries even if there is a Consumption Journal Line of completely different Production Order No. in Consumption Journal.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            Item."No.",
            LibraryRandom.RandIntInRange(10, 10),
            '',
            '');

        // [GIVEN] Create Item 2.
        LibraryInventory.CreateItem(Item2);

        // [GIVEN] Create and Refresh Production Order 2.
        CreateAndRefreshProductionOrder(
            ProductionOrder2,
            ProductionOrder2.Status::Released,
            Item2."No.",
            LibraryRandom.RandIntInRange(10, 10),
            '',
            '');

        // [GIVEN] Create Consumption Journal Line for Production Order 2.
        CreateConsumptionJournalLine(
            ItemJournalLine,
            ProductionOrder2."No.",
            Item2."No.",
            LibraryRandom.RandIntInRange(10, 10));

        // [WHEN] Open Released Production Order page and run Production Journal action.
        ReleasedProdOrder.OpenEdit();
        ReleasedProdOrder.GoToRecord(ProductionOrder);
        ReleasedProdOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [VERIFY] Item Ledger Entry No. of Records in Posting Preview is not zero.
        Assert.AreNotEqual(0, LibraryVariableStorage.DequeueInteger(), ILENoOfRecordsMustNotBeZeroErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemTrackingAssignSerialNoPageHandler,ProductionJournalPageOutputEntryHandler,ConfirmHandler,MessageHandlerNoText')]
    procedure NegativeQtyOutputEntryIsPostedEvenIfProdConsumpWhseHandlingIsWhsePickMandatoryInLocation()
    var
        CompItem, ProdItem : Record Item;
        Location: Record Location;
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SerialNo: Code[10];
        Quantity: Decimal;
        ReleasedProdOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 504492] Negative Output is posted from Production Journal without error even if Prod. Consump. Whse. Handling is  Warehouse Pick (mandatory) in Location.
        Initialize();

        // [GIVEN] Create a Unit of Measure Code.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);

        // [GIVEN] Create a Component Item with Unit of Measure and Validate Replenishment System.
        CreateItemWithUOM(CompItem, UnitOfMeasure, ItemUnitOfMeasure);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::Purchase);
        CompItem.Modify(true);

        // [GIVEN] Create an Item Tracking Code.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);

        // [GIVEN] Create a Location with Prod. Consump. Whse. Handling.
        CreateLocationWithProdConsumpWhseHandling(Location);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create a Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create an Item Journal Line.
        CreateItemJournalLine(ItemJournalLine, CompItem."No.", LibraryRandom.RandIntInRange(5, 5), '', '');

        // [GIVEN] Post Item Journal Line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create a production BOM for the Production Item.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ItemUnitOfMeasure.Code);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader,
            ProductionBOMLine,
            '',
            ProductionBOMLine.Type::Item,
            CompItem."No.",
            LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Validate Unit of Measure Code in Production BOM.
        ProductionBOMLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);

        // [GIVEN] Change Status of Production BOM.
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Create a Production Item with Unit of Measure and Validate
        // Replenishment System, Reordering Policy, Production BOM No. and Item Tracking Code.
        CreateItemWithUOM(ProdItem, UnitOfMeasure, ItemUnitOfMeasure);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Reordering Policy", ProdItem."Reordering Policy"::Order);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Item Tracking Code", ItemTrackingCode.Code);
        ProdItem.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProdItem."No.",
            LibraryRandom.RandIntInRange(2, 2),
            Location.Code,
            Bin.Code);

        // [GIVEN] Generate and save Serial No and Quantity in two different Variables.
        SerialNo := LibraryUtility.GenerateRandomCode(ProdItem.FieldNo("No."), DATABASE::Item);
        Quantity := LibraryRandom.RandIntInRange(-1, -1);

        // [GIVEN] Open Released Production Order page and run Production Journal action.
        ReleasedProdOrder.OpenEdit();
        ReleasedProdOrder.GoToRecord(ProductionOrder);
        LibraryVariableStorage.Enqueue(ProductionOrder.Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::" ");
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(0));
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin));
        LibraryVariableStorage.Enqueue(LibraryRandom.RandInt(0));
        ReleasedProdOrder.ProdOrderLines.ProductionJournal.Invoke();
        ReleasedProdOrder.Close();

        // [GIVEN] Open Released Production Order page again and run Production Journal action.
        ReleasedProdOrder.OpenEdit();
        ReleasedProdOrder.GoToRecord(ProductionOrder);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(Quantity);
        ReleasedProdOrder.ProdOrderLines.ProductionJournal.Invoke();

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Item No.", ProdItem."No.");
        ItemLedgerEntry.SetRange(Quantity, Quantity);

        // [VERIFY] Item Ledger Entry is found.
        Assert.IsFalse(ItemLedgerEntry.IsEmpty(), ItemLedgerEntryMustBeFoundErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalPageHandlerPostOnlyOutput,ConfirmHandlerTrue,MessageHandler')]
    procedure CalcConsumptionCreatesItemJnlLineOfQtySameAsExpectedQtyOfProdOrderComponent()
    var
        CompItem, ProdItem : Record Item;
        CompItemUnitOfMeasure, ProdItemUnitOfMeasure : array[2] of Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLine: Record "Item Journal Line";
        ProductionJournalMgt: codeunit "Production Journal Mgt";
    begin
        // [SCENARIO 504304] When Stan creates a Released Production Order using Pick + Manual Flushing Method, Quantity calculated by Calcluate Consumption action in Consumption Journal must match with the Expected Quantity of Prod. Order Component.
        Initialize();

        // [GIVEN] Create Component Item with Item Unit of Measure Code and Validate Flushing Method.
        CreateComponentItemWithItemUnitOfMeasureCode(CompItem, CompItemUnitOfMeasure);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::"Pick + Manual");
        CompItem.Modify(true);

        // [GIVEN] Create Production Item with Item Unit of Measure Code and Validate Flushing Method.
        CreateProductionItemWithItemUnitOfMeasureCode(ProdItem, ProdItemUnitOfMeasure);
        ProdItem.Validate("Flushing Method", ProdItem."Flushing Method"::"Pick + Manual");
        ProdItem.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProdItem."No.",
            LibraryRandom.RandIntInRange(400, 400),
            '',
            '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Find Prod. Order Component.
        LibraryManufacturing.CreateProductionOrderComponent(
            ProdOrderComponent,
            ProdOrderLine.Status,
            ProdOrderLine."Prod. Order No.",
            ProdOrderLine."Line No.");

        // [GIVEN] Validate Item No., Quantity per, Scrap %, Length, Width, Depth and Calculation Formula in Prod. Order Component.
        ProdOrderComponent.Validate("Item No.", CompItem."No.");
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandIntInRange(140, 140));
        ProdOrderComponent.Validate("Scrap %", LibraryRandom.RandIntInRange(3, 3));
        ProdOrderComponent.Validate(Length, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderComponent.Validate(Width, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderComponent.Validate(Depth, LibraryRandom.RandInt(0));
        ProdOrderComponent.Validate("Calculation Formula", ProdOrderComponent."Calculation Formula"::"Length * Width * Depth");
        ProdOrderComponent.Modify(true);

        // [GIVEN] Post Production Journal.
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);
        LibraryVariableStorage.Enqueue(PostingProductionJournalQst);
        LibraryVariableStorage.Enqueue(PostingProductionJournalTxt);
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Create Consumption Journal using Calculate Consumption.
        CreateConsumptionJournal(ProductionOrder."No.");

        // [WHEN] Find Item Journal Line.
        ItemJnlLine.SetRange("Item No.", CompItem."No.");
        ItemJnlLine.SetRange("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.FindFirst();

        // [VERIFY] Expected Quantity of Prod. Order Component and Quanity of Item Journal Line are same.
        Assert.AreEqual(
            ProdOrderComponent."Expected Quantity",
            ItemJnlLine.Quantity,
            StrSubstNo(
                QuantityErr,
                ItemJnlLine.FieldCaption(Quantity),
                ProdOrderComponent."Expected Quantity",
                ItemJnlLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalPageHandlerPostOutput,ConfirmHandlerTrue,MessageHandler')]
    procedure StatusOfProdOrderIsChangedToFinishedEvenWhenHaveProdItemWithRoundPrecision()
    var
        CompItem, ProdItem : Record Item;
        Location: Record Location;
        Bin, Bin2, Bin3, Bin4 : Record Bin;
        CompItemUnitOfMeasure, ProdItemUnitOfMeasure : array[2] of Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: array[3] of Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionJournalMgt: codeunit "Production Journal Mgt";
    begin
        // [SCENARIO 523937] Status of Production Order can be changed to Finished even if it has Production Item with Rounding Precision.
        Initialize();

        // [GIVEN] Create Location and Validate Prod. Consump. Whse. Handling.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee.
        WarehouseEmployee.SetRange("User ID", UserId());
        WarehouseEmployee.DeleteAll();
        WarehouseEmployee.Reset();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create four Bins.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');
        LibraryWarehouse.CreateBin(Bin2, Location.Code, Bin2.Code, '', '');
        LibraryWarehouse.CreateBin(Bin3, Location.Code, Bin3.Code, '', '');
        LibraryWarehouse.CreateBin(Bin4, Location.Code, Bin4.Code, '', '');

        // [GIVEN] Validate To-Production Bin Code and From-Production Bin Code.
        Location.Validate("To-Production Bin Code", Bin.Code);
        Location.Validate("From-Production Bin Code", Bin2.Code);
        Location.Modify(true);

        // [GIVEN] Create Component Item with Item Unit of Measure Code.
        CreateCompItemWithItemUnitOfMeasureCode(CompItem, CompItemUnitOfMeasure, 1.60514);

        // [GIVEN] Validate Base Unit of Measure, Flushing Method and Rounding Precision in Component Item.
        CompItem.Validate("Base Unit of Measure", CompItemUnitOfMeasure[1].Code);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::"Pick + Backward");
        CompItem.Validate("Rounding Precision", 0.00001);
        CompItem.Modify(true);

        // [GIVEN] Create Production Item with Item Unit of Measure Code and Validate Flushing Method.
        CreateProdItemWithItemUnitOfMeasureCode(ProdItem, ProdItemUnitOfMeasure, LibraryRandom.RandIntInRange(50, 50));
        ProdItem.Validate("Base Unit of Measure", ProdItemUnitOfMeasure[1].Code);
        ProdItem.Validate("Flushing Method", ProdItem."Flushing Method"::"Pick + Manual");
        ProdItem.Modify(true);

        // [GIVEN] Create Production BOM.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItemUnitOfMeasure[2].Code);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", 4.8);
        ProductionBOMLine.Validate("Unit of Measure Code", CompItemUnitOfMeasure[2].Code);
        ProductionBOMLine.Modify(true);

        // [GIVEN] Validate Status in Production BOM Header.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Validate Production BOM No. in Production Item.
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProdItem."No.",
            LibraryRandom.RandIntInRange(96, 96),
            Location.Code,
            Bin2.Code);

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Post Production Journal.
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);
        LibraryVariableStorage.Enqueue(PostingProductionJournalQst);
        LibraryVariableStorage.Enqueue(PostingProductionJournalTxt);
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Create Item Journal Line 1 and Validate Unit of Measure Code.
        CreateItemJournalLine(ItemJournalLine[1], CompItem."No.", LibraryRandom.RandIntInRange(3, 3), Bin3.Code, Location.Code);
        ItemJournalLine[1].Validate("Unit of Measure Code", CompItemUnitOfMeasure[1].Code);
        ItemJournalLine[1].Modify(true);

        // [GIVEN] Post Item Journal Line 1.
        LibraryInventory.PostItemJournalLine(ItemJournalLine[1]."Journal Template Name", ItemJournalLine[1]."Journal Batch Name");

        // [GIVEN] Create Item Journal Line 2 and Validate Unit of Measure Code.
        CreateItemJournalLine(ItemJournalLine[2], CompItem."No.", LibraryRandom.RandIntInRange(8, 8), Bin4.Code, Location.Code);
        ItemJournalLine[2].Validate("Unit of Measure Code", CompItemUnitOfMeasure[1].Code);
        ItemJournalLine[2].Modify(true);

        // [GIVEN] Post Item Journal Line 2.
        LibraryInventory.PostItemJournalLine(ItemJournalLine[2]."Journal Template Name", ItemJournalLine[2]."Journal Batch Name");

        // [GIVEN] Create Warehouse Pick from Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [GIVEN] Register Warehouse Pick.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Create Item Journal Line 3 and Validate Unit of Measure Code.
        CreateItemJournalLine(ItemJournalLine[3], CompItem."No.", 3.79296, Bin4.Code, Location.Code);
        ItemJournalLine[3].Validate("Unit of Measure Code", CompItemUnitOfMeasure[1].Code);
        ItemJournalLine[3].Modify(true);

        // [GIVEN] Post Item Journal Line 3.
        LibraryInventory.PostItemJournalLine(ItemJournalLine[3]."Journal Template Name", ItemJournalLine[3]."Journal Batch Name");

        // [GIVEN] Create Warehouse Pick from Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [GIVEN] Register Warehouse Pick.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Change Status of Production Order to Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [GIVEN] Find Prod. Order Component.
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.FindFirst();

        // [THEN] Quanity of Item Ledger Entry must match Qty Picked (Base) of Prod. Order Component.
        Assert.AreEqual(
            -ProdOrderComponent."Qty. Picked (Base)",
            ItemLedgerEntry.Quantity,
            StrSubstNo(
                QuantityErr,
                ItemLedgerEntry.FieldCaption(Quantity),
                -ProdOrderComponent."Qty. Picked (Base)",
                ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ProductionJournalPageHandlerOnlyOutput,ConfirmHandlerTrue,MessageHandler')]
    procedure ILEQuantityWhenFlushingMethodIsBackwardandCalculationFormulaUsed()
    var
        CompItem, CompItem2, ProdItem : Record Item;
        CompItemUnitOfMeasure, CompItemUnitOfMeasure2, ProdItemUnitOfMeasure : array[2] of Record "Item Unit of Measure";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        ProductionJournalMgt: codeunit "Production Journal Mgt";
        QuantityCalculationFormula: Enum "Quantity Calculation Formula";
        ConsumptionQuantity: Decimal;
        ConsumptionQuantity2: Decimal;
    begin
        // [SCENARIO 538860] When Calculation formula used in Production BOM and flushing method Pick+Backward is used on Raw Material, ILE should calculated  from quantity in Product
        Initialize();

        // [GIVEN] Create Component Item with Item Unit of Measure Code.
        CreateComponentItemWithItemUnitOfMeasureCode(CompItem, CompItemUnitOfMeasure);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::"Pick + Backward");
        CompItem.Modify(true);

        // [GIVEN] Create Component Item 2 with Item Unit of Measure Code.
        CreateComponentItemWithItemUnitOfMeasureCode(CompItem2, CompItemUnitOfMeasure2);
        CompItem2.Validate("Flushing Method", CompItem2."Flushing Method"::"Pick + Backward");
        CompItem2.Modify(true);

        // [GIVEN] Create and Post two Item Journal Lines of Component Item and Component Item 2.
        CreateAndPostItemJournalLine(CompItem."No.", LibraryRandom.RandIntInRange(100, 100), '', '', false);
        CreateAndPostItemJournalLine(CompItem2."No.", LibraryRandom.RandIntInRange(100, 100), '', '', false);

        // [GIVEN] Create Production Item with Item Unit of Measure Code.
        CreateProductionItemWithItemUnitOfMeasureCode(ProdItem, ProdItemUnitOfMeasure);

        // [GIVEN] Create Routing Link.
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        // [GIVEN] Create Work Center and Validate Flushing Method, Capacity and Efficiency.
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Validate(Capacity, LibraryRandom.RandInt(0));
        WorkCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        WorkCenter.Modify(true);

        // [GIVEN] Create and Certify Routing with Routing Link Code..
        CreateAndCertifyRoutingWithRoutingLinkCode(RoutingHeader, RoutingLine, WorkCenter."No.", RoutingLink.Code);

        // [GIVEN] Create and Certify Production BOM with Routing Link Code.
        CreateAndCertifyProductionBOMwithRoutingLinkCode(ProductionBOMHeader, ProductionBOMLine, ProdItem, CompItem, CompItem2, RoutingLink);

        // [GIVEN] Update Production Item.
        ProdItem.Validate("Base Unit of Measure", ProdItemUnitOfMeasure[1].Code);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Routing No.", RoutingHeader."No.");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Rounding Precision", 0.001);
        ProdItem.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            ProdItem."No.",
            LibraryRandom.RandIntInRange(10, 10),
            '',
            '');

        // [GIVEN] Find and Update Prod. Order Component of Component Item.
        FindAndUpdateProdOrderComponentWithCalcFormula(
            ProductionOrder,
            ProdOrderComponent,
            CompItem,
            RoutingLink,
            LibraryRandom.RandIntInRange(3, 3),
            LibraryRandom.RandInt(0),
            LibraryRandom.RandInt(0),
            QuantityCalculationFormula::Length);

        // [GIVEN] Generate and save Consumption Quantity in a Variable.
        ConsumptionQuantity := ProdOrderComponent."Quantity per" * ProdOrderComponent.Length * ProductionOrder.Quantity;

        // [GIVEN] Find and Update Prod. Order Component of Component Item 2.
        FindAndUpdateProdOrderComponentWithCalcFormula(
            ProductionOrder,
            ProdOrderComponent,
            CompItem2,
            RoutingLink,
            LibraryRandom.RandIntInRange(2, 2),
            LibraryRandom.RandIntInRange(2, 2),
            LibraryRandom.RandInt(0),
            QuantityCalculationFormula::"Length * Width");

        // [GIVEN] Generate and save Consumption Quantity 2 in a Variable.
        ConsumptionQuantity2 := ProdOrderComponent."Quantity per" * ProdOrderComponent.Length * ProdOrderComponent.Width * ProductionOrder.Quantity;

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Post Production Journal.
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);
        LibraryVariableStorage.Enqueue(PostingProductionJournalQst);
        LibraryVariableStorage.Enqueue(PostingProductionJournalTxt);
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Document No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Item No.", CompItem."No.");
        ItemLedgerEntry.FindFirst();

        // [THEN] Consumption Quantity and Item Ledger Entry Quantity are same.
        Assert.AreEqual(
            -ConsumptionQuantity,
            ItemLedgerEntry.Quantity,
            StrSubstNo(
                QuantityErr,
                ItemLedgerEntry.FieldCaption(Quantity),
                -ConsumptionQuantity,
                ItemLedgerEntry.TableCaption()));

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Document No.", ProductionOrder."No.");
        ItemLedgerEntry.SetRange("Item No.", CompItem2."No.");
        ItemLedgerEntry.FindFirst();

        // [THEN] Consumption Quantity 2 and Item Ledger Entry Quantity are same.
        Assert.AreEqual(
            -ConsumptionQuantity2,
            ItemLedgerEntry.Quantity,
            StrSubstNo(
                QuantityErr,
                ItemLedgerEntry.FieldCaption(Quantity),
                -ConsumptionQuantity2,
                ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IncreaseDurationOfOperationsInManuallyScheduledProdOrderRoutingLine()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NewSetupTime: Decimal;
    begin
        // [SCENARIO 532972] When Stan increases Setup Time which increases the total duration 
        // Of setup-wait-move operations in Prod. Order Routing Line having "Schedule Manually" 
        // Set to true then no error occurs.
        Initialize();

        // [GIVEN] Create a Released Production Order with Manually Scheduled Routing Line.
        CreateReleasedProdOrderWithManuallyScheduledRoutingLine(ProdOrderRoutingLine);

        // [GIVEN] Generate and save New Setup Time.
        NewSetupTime := ProdOrderRoutingLine."Setup Time" + LibraryRandom.RandInt(5);

        // [WHEN] Update Setup Time in Prod. Order Routing Line.
        UpdateSetupTimeInProdOrderRoutingLine(ProdOrderRoutingLine, NewSetupTime);

        // [THEN] Setup Time in Prod. Order Routing Line is equal to New Setup Time value.
        Assert.AreEqual(NewSetupTime, ProdOrderRoutingLine."Setup Time", ProdOrderRtngLineNotUpdatedMsg);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,SelectMultiItemsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderComponentSelectMultipleItems()
    var
        Item: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        // [SCENARIO 347825] Run Action "Select items" on Prod. Order Components Page adds selected items.
        Initialize();

        // [GIVEN] Create Items Setup With Production and Tracking.
        CreateItemsSetupWithProductionAndTracking(Item, ParentItem, ProductionOrder, LibraryRandom.RandInt(100), '');

        // [GIVEN] Update Flushing Method On Prod Component.
        UpdateFlushingMethodOnProdComp(ProductionOrder."No.", Item."Flushing Method"::Backward);

        // [WHEN] Run action "Select items" on Prod. Order Component Page.
        ProdOrderComponents.OpenEdit();
        ProdOrderComponents.FILTER.SetFilter("Item No.", Item."No.");
        ProdOrderComponents.SelectMultiItems.Invoke();

        // [VERIFY] Verify the count of Prod. Order Component as one line is added.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(ProdOrderComponent, 2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,SelectCancelMultiItemsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderComponentCancelSelectMultipleItems()
    var
        Item: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        // [SCENARIO 347825] Run Action "Select items" on Prod. Order Components Page not add selected items.
        Initialize();

        // [GIVEN] Create Items Setup With Production and Tracking.
        CreateItemsSetupWithProductionAndTracking(Item, ParentItem, ProductionOrder, LibraryRandom.RandInt(100), '');

        // [GIVEN] Update Flushing Method On Prod Component.
        UpdateFlushingMethodOnProdComp(ProductionOrder."No.", Item."Flushing Method"::Backward);

        // [WHEN] Run action "Select items" on Prod. Order Component Page.
        ProdOrderComponents.OpenEdit();
        ProdOrderComponents.FILTER.SetFilter("Item No.", Item."No.");
        ProdOrderComponents.SelectMultiItems.Invoke();

        // [THEN] Verify the count of Prod. Order Component as line is not added.
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.RecordCount(ProdOrderComponent, 1);
    end;

    [Test]
    [HandlerFunctions('SelectMultiItemsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdBOMLinesSelectMultipleItems()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOM: TestPage "Production BOM";
    begin
        // [SCENARIO 347825] Run Action "Select items" on Prod. BOM Lines Page adds selected items.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");

        // [WHEN] Run action "Select items" on Production BOM Lines Page.
        ProductionBOM.OpenEdit();
        ProductionBOM.GoToRecord(ProductionBOMHeader);
        ProductionBOM.ProdBOMLine.SelectMultiItems.Invoke();

        // [THEN] Verify the count of Prod. BOM Line as one line is added.
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        Assert.RecordCount(ProductionBOMLine, 1);
    end;

    [Test]
    [HandlerFunctions('SelectCancelMultiItemsModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdBOMLinesCancelSelectMultipleItems()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOM: TestPage "Production BOM";
    begin
        // [SCENARIO 347825] Run Action "Select items" on Prod. BOM Lines Page not add selected items.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");

        // [WHEN] Run action "Select items" on Production BOM Lines Page.
        ProductionBOM.OpenEdit();
        ProductionBOM.GoToRecord(ProductionBOMHeader);
        ProductionBOM.ProdBOMLine.SelectMultiItems.Invoke();

        // [THEN] Verify the count of Prod. BOM Line as line is not added.
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        Assert.RecordCount(ProductionBOMLine, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CalculatePlanPlanWkshRequestPageHandler')]
    procedure CarryOutActionMessageShouldThrowErrorIfProductionBlockedIsOutputOnItem()
    var
        LocationBlue: Record Location;
        Level2Item, Level1Item, Level0Item : Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseEmployee: Record "Warehouse Employee";
        RequisitionLine: Record "Requisition Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [SCENARIO 382546] Verify "Carry Out Action Message - Plan" should throw error if "Production Blocked" is Output on Item.
        Initialize();

        // [GIVEN] Create Blue and Red Location
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);

        // [GIVEN] Activate Optimize Low Level Code Calculation on Manufacturing Setup
        LibraryPlanning.SetDemandForecast('');
        LibraryManufacturing.SetComponentsAtLocation(LocationBlue.Code);

        // [GIVEN] Set Mandatory Location on Inventory Setup
        LibraryInventory.SetLocationMandatory(true);

        // [GIVEN] Create Level 2 Item
        LibraryInventory.CreateItem(Level2Item);
        Level2Item.Validate("Reordering Policy", Level2Item."Reordering Policy"::"Lot-for-Lot");
        Level2Item.Modify(true);

        // [GIVEN] Create Level 1 Item
        LibraryInventory.CreateItem(Level1Item);
        CreateManufacturingItem(Level1Item, Level1Item."Reordering Policy"::Order, Level1Item."Replenishment System"::"Prod. Order");
        Level1Item.Validate("Manufacturing Policy", Level1Item."Manufacturing Policy"::"Make-to-Order");
        UpdateOrderTrackingPolicyOnItem(Level1Item, Level1Item."Order Tracking Policy"::"Tracking Only");

        // [GIVEN] Create and Certify Production BOM
        CreateCertifiedProductionBOM(ProductionBOMHeader, Level2Item);

        // [GIVEN] Create and Certify Routing
        CreateAndCertifiyRouting(RoutingHeader);

        // [GIVEN] Update Production BOM and Routing on Item
        UpdateProductionBomAndRoutingOnItem(Level1Item, ProductionBOMHeader."No.", RoutingHeader."No.");

        // [GIVEN] Create Level 0 Item
        LibraryInventory.CreateItem(Level0Item);
        CreateManufacturingItem(Level0Item, Level0Item."Reordering Policy"::Order, Level0Item."Replenishment System"::"Prod. Order");
        Level0Item.Validate("Manufacturing Policy", Level0Item."Manufacturing Policy"::"Make-to-Order");
        Level0Item.Validate("Flushing Method", Level0Item."Flushing Method"::Backward);
        UpdateOrderTrackingPolicyOnItem(Level0Item, Level0Item."Order Tracking Policy"::"Tracking Only");

        // [GIVEN] Create and Certified Production BOM
        CreateCertifiedProductionBOM(ProductionBOMHeader, Level1Item);

        // [GIVEN] Create and Certify Routing        
        CreateAndCertifiyRouting(RoutingHeader);

        // [GIVEN] Update Production BOM and Routing on Item
        UpdateProductionBomAndRoutingOnItem(Level0Item, ProductionBOMHeader."No.", RoutingHeader."No.");

        // [GIVEN] Create Warehouse Employee for Blue and Red Location
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationBlue.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);

        // [GIVEN] Create Sales Order for Level 0 Item
        CreateSalesOrder(SalesHeader, SalesLine, Level0Item."No.", LibraryRandom.RandInt(10), LocationRed.Code);

        // Set to calculate MPS
        LibraryVariableStorage.Enqueue(true);

        // [GIVEN] Carry Out Planning Worksheet as Firm Planned Production Order.        
        CalcRegenPlanForPlanningWorksheetPage(PlanningWorksheet, Level0Item."No.", Level1Item."No.", false);

        // [GIVEN] Accept Action Message for Requisition Lines
        AcceptActionMessage(RequisitionLine, Level0Item."No.");
        AcceptActionMessage(RequisitionLine, Level1Item."No.");

        // [GIVEN] Update "Production Blocked" on Item.
        Level0Item.Validate("Production Blocked", Level0Item."Production Blocked"::Output);
        Level0Item.Modify(true);

        // [GIVEN] Save Expected Error Message.
        LibraryVariableStorage.Enqueue(StrSubstNo(ProductionBlockedOutputItemErr, Level0Item.TableCaption(), Level0Item."No.", Level0Item.FieldCaption("Production Blocked"), Level0Item."Production Blocked"));

        // [WHEN] Run Carry Out Action Message - Plan.
        RunRequisitionCarryOutReportProdOrder(RequisitionLine);

        // [VERIFY] Verify error message through MessageHandler if "Production Blocked" is Output on Item.
    end;

    [Test]
    procedure VerifyProdOutputWhseHandlingShouldThrowWhenDirectedPutAwayIsTrue()
    begin
        // [SCENARIO 476537] Verify "Prod. Output Whse. Handling" should throw error when "Directed Put-away and Pick" is true if it's changed to "Inventory Put-away".
        Initialize();

        // [GIVEN] Update Manufacturing Setup Components in Location.
        LibraryManufacturing.SetComponentsAtLocation(LocationWhite.Code);

        // [WHEN] Update "Prod. Output Whse. Handling" in Location.
        asserterror LocationWhite.Validate("Prod. Output Whse. Handling", LocationWhite."Prod. Output Whse. Handling"::"Inventory Put-away");

        // [THEN] Verify "Prod. Output Whse. Handling" should throw error when "Directed Put-away and Pick" is true if it's changed to "Inventory Put-away".
        Assert.ExpectedError(
            StrSubstNo(
                InvalidProdOutputHandlingErr,
                LocationWhite."Prod. Output Whse. Handling"::"Inventory Put-away",
                LocationWhite.TableCaption(),
                LocationWhite.Code,
                LocationWhite.FieldCaption("Directed Put-away and Pick")));
    end;

    [Test]
    procedure VerifyDocumentPutAwayStatusMustBeCompletelyPutAwayInProductionOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 476537] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order.
        Initialize();

        // [GIVEN] Update Manufacturing Setup Components in Location.
        LibraryManufacturing.SetComponentsAtLocation(LocationRed.Code);

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, Item2);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item2."No.", Quantity, Bin.Code, LocationRed.Code, false);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationRed.Code, Bin.Code);

        // [GIVEN] Create and Post Consumption Journal with Item Tracking.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);

        // [WHEN] Create and Post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);

        // [THEN] Find Warehouse Put Away Request should be created When "Prod. Output Whse. Handling" is "Warehouse Put-away" on Location.
        WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [GIVEN] Find Warehouse Activity Line.
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

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
    procedure VerifyDocumentPutAwayStatusMustBePartiallyPutAwayInProductionOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 476537] Verify "Document Put-away Status" must be "Partially Put Away" in Production Order.
        Initialize();

        // [GIVEN] Update Manufacturing Setup Components in Location.
        LibraryManufacturing.SetComponentsAtLocation(LocationRed.Code);

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, Item2);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item2."No.", Quantity, Bin.Code, LocationRed.Code, false);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationRed.Code, Bin.Code);

        // [GIVEN] Create and Post Consumption Journal with Item Tracking.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);

        // [WHEN] Create and Post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);

        // [THEN] Find Warehouse Put Away Request should be created When "Prod. Output Whse. Handling" is "Warehouse Put-away" on Location.
        WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [GIVEN] Update "Qty to Handle" in Warehouse Activity Line.
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");
        UpdateQtytoHandleInWarehouseActivityLine(WarehouseActivityLine, Quantity - 1);

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Partially Put Away" in Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Partially Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Partially Put Away", ProductionOrder.TableCaption()));
    end;

    [Test]
    procedure VerifyDocumentPutAwayStatusMustBeCompletelyPutAwayInProductionOrderAndWarehouseRequestMustBeDeleted()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 476537] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and and Warehouse Request must be deleted.
        Initialize();

        // [GIVEN] Update Manufacturing Setup Components in Location.
        LibraryManufacturing.SetComponentsAtLocation(LocationRed.Code);

        // [GIVEN] Update "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, Item2);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item2."No.", Quantity, Bin.Code, LocationRed.Code, false);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationRed.Code, Bin.Code);

        // [GIVEN] Create and Post Consumption Journal with Item Tracking.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);

        // [WHEN] Create and Post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);

        // [THEN] Find Warehouse Put Away Request should be created When "Prod. Output Whse. Handling" is "Warehouse Put-away" on Location.
        WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [GIVEN] Update "Qty to Handle" in Warehouse Activity Line.
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");
        UpdateQtytoHandleInWarehouseActivityLine(WarehouseActivityLine, Quantity - 1);

        // [WHEN] Register Warehouse Activity.
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Partially Put Away" in Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Partially Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(ValueMustBeEqualErr, ProductionOrder.FieldCaption("Document Put-away Status"), ProductionOrder."Document Put-away Status"::"Partially Put Away", ProductionOrder.TableCaption()));

        // [GIVEN] Update "Qty to Handle" in Warehouse Activity Line.
        UpdateQtytoHandleInWarehouseActivityLine(WarehouseActivityLine, 1);

        // [WHEN] Register Warehouse Activity.
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");
        RegisterWarehouseActivity(ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");

        // [THEN] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order and and Warehouse Put Away Request must be deleted.
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
    procedure VerifyDocumentPutAwayStatusMustBeCompletelyPutAwayInProductionOrderUsingPutAwayWorkSheet()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        WarehousePutAwayRequest: Record "Whse. Put-away Request";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 476537] Verify "Document Put-away Status" must be "Completely Put Away" in Production Order using Put-Away Worksheet.
        Initialize();

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);

        // [GIVEN] Update Manufacturing Setup Components in Location.
        LibraryManufacturing.SetComponentsAtLocation(LocationRed.Code);

        // [GIVEN] Update "Use Put-away Worksheet" and "Prod. Output Whse. Handling" in Location.
        LocationRed.Validate("Use Put-away Worksheet", true);
        LocationRed.Validate("Prod. Output Whse. Handling", LocationRed."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationRed.Modify();

        // [GIVEN] Find Bin.
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Create Item Setup.
        CreateItemsSetup(Item, Item2);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item2."No.", Quantity, Bin.Code, LocationRed.Code, false);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationRed.Code, Bin.Code);

        // [GIVEN] Create and Post Consumption Journal with Item Tracking.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);

        // [WHEN] Create and Post Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, Quantity);

        // [THEN] Find Warehouse Put Away Request should be created When "Prod. Output Whse. Handling" is "Warehouse Put-away" on Location.
        WarehousePutAwayRequest.Get(WarehousePutAwayRequest."Document Type"::Production, ProductionOrder."No.");

        // [GIVEN] Create Put-Away From Put-Away Worksheet.
        CreatePutAwayFromPutAwayWorksheet(WhseWorksheetLine, LocationRed.Code, Item."No.", Item."No.", Quantity, "Whse. Activity Sorting Method"::None, false);  // Taking 0 for Quantity.

        // [WHEN] Register Warehouse Activity.
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Output", WarehouseActivityLine."Activity Type"::"Put-away");
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
    [HandlerFunctions('ProductionJnlPageHandler,WhsePutAwayDocSelectionPageHandler,ConfirmHandler,MessageHandlerNoText')]
    [Scope('OnPrem')]
    procedure GeWhseDocumentsShowsWhsePutawayWhenDeleteWhsePutawayCreatedByProdJnlOfProdOrderHavingNoLocationCode()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [SCENARIO 561739] When run Get Warehouse Documents action from Put-away Worksheet, it shows 
        // the Warehouse Put-away which is created by posting Production Journal from a Released 
        // Production Order having no Location Code on its header and then deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and 
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Production Order and Validate Location Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Delete Warehouse Activity Header.
        WarehouseActivityHeader.Delete();

        // [WHEN] Create Put-Away from Put-Away Worksheet.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(Format(ProdOrderLine."Location Code"));
        LibraryVariableStorage.Enqueue(Format(ProductionOrder."No."));
        CreatePutawayFromPutawayWorksheet(Location);

        // [THEN] Document No. in Whse. PutAway Doc Selection Page is equal 
        // to Document No. of Prod. Order Line in WhsePutAwayDocSelectionPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoProdOrderLinesHavingDiffLocationsWithOrWithoutWarehousePutawayGivesErrorOnLocationCodeOfProdOrder()
    var
        Item: Record Item;
        Location: array[3] of Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [SCENARIO 563092] If a Location having Warehouse Put-away in Prod. Output Whse. Handling field is 
        // selected on Prod. Order Line and Stan changes the Location Code on Production 
        // Order to another Location or as blank then it gives error and vice versa.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and 
        // Validate Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        Location[1].Validate("Prod. Output Whse. Handling", Location[1]."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location[1].Modify(true);

        // [GIVEN] Create a Location with Inventory Posting Setup and 
        // Validate Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        Location[2].Validate("Prod. Output Whse. Handling", Location[2]."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location[2].Modify(true);

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[3]);

        // [GIVEN] Create a Production Order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);

        // [GIVEN] Validate Location Code in Production Order.
        ProductionOrder.Validate("Location Code", Location[1].Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod. Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine,
            ProdOrderLine.Status::Released,
            ProductionOrder."No.",
            Item."No.",
            '',
            Location[1].Code,
            LibraryRandom.RandIntInRange(2, 2));

        // [GIVEN] Save Production Order and Prod Order Line.
        Commit();

        // [WHEN] Validate Code of Location [2] in Location Code of Production Order.
        asserterror ProductionOrder.Validate("Location Code", Location[2].Code);

        // [THEN] Error on Location Code of Production Order.
        Assert.ExpectedTestFieldError(ProductionOrder.FieldCaption("Location Code"), Location[2].Code);

        // [WHEN] Validate Code of Location [3] in Location Code of Production Order.
        asserterror ProductionOrder.Validate("Location Code", Location[3].Code);

        // [THEN] Error on Location Code of Production Order.
        Assert.ExpectedTestFieldError(ProductionOrder.FieldCaption("Location Code"), Location[3].Code);

        // [WHEN] Validate '' in Location Code of Production Order..
        asserterror ProductionOrder.Validate("Location Code", '');

        // [THEN] Error on Location Code of Production Order.
        Assert.ExpectedTestFieldError(ProductionOrder.FieldCaption("Location Code"), '');

        // [WHEN] Validate Code of Location [2] in Location Code of Prod. Order Line.
        asserterror ProdOrderLine.Validate("Location Code", Location[2].Code);

        // [THEN] Error on Location Code of Prod. Order Line.
        Assert.ExpectedTestFieldError(ProdOrderLine.FieldCaption("Location Code"), Location[2].Code);

        // [WHEN] Validate Code of Location [3] in Location Code of Prod. Order Line.
        asserterror ProdOrderLine.Validate("Location Code", Location[3].Code);

        // [THEN] Error on Location Code of Prod. Order Line.
        Assert.ExpectedTestFieldError(ProdOrderLine.FieldCaption("Location Code"), Location[3].Code);
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler,ConfirmHandler,MessageHandlerText')]
    [Scope('OnPrem')]
    procedure ConfirmMsgAndWhsePutAwayNoCreatedMsgIsShownIfCreateWhsePutAwayFromRelProdOrderPage()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        NoSeriesLine: Record "No. Series Line";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseSetup: Record "Warehouse Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReleasedProductionOrder: TestPage "Released Production Order";
        WhsePutAwayNo: Code[20];
    begin
        // [SCENARIO 563074] When Create Warehouse Put-away from Released Production Order page 
        // then it displays confirm message and Warehouse Put-away No. has been created message.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Production Order and Validate Location Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);
        Commit();

        // [GIVEN] Create and Post Production Journal.
        LibraryVariableStorage.Enqueue(ProductionJournalPostedTxt);
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Delete Warehouse Activity Header.
        WarehouseActivityHeader.Delete(true);

        // [GIVEN] Get Warehouse Setup.
        WarehouseSetup.Get();

        // [GIVEN] Find No. Series Line.
        NoSeriesLine.SetRange("Series Code", WarehouseSetup."Whse. Put-away Nos.");
        NoSeriesLine.FindFirst();

        // [GIVEN] Generate and save Whse. Put-away No. in a Variable.
        WhsePutAwayNo := IncStr(NoSeriesLine."Last No. Used");

        // [WHEN] Open Released Production Order page and run Create Warehouse Put-Away action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        LibraryVariableStorage.Enqueue(PutAwayActivityNoHasBeenCreatedMsg);
        LibraryVariableStorage.Enqueue(WhsePutAwayNo);
        ReleasedProductionOrder."Create Warehouse Put-Away".Invoke();

        // [THEN] Confirm Message is displayed in ConfirmHandler and
        // PutAwayActivityNoHasBeenCreatedMsg is displayed in MessageHandler.
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler2,ChangeStatusOnProdOrderPageHandler,ConfirmHandler,MessageHandlerNoText')]
    [Scope('OnPrem')]
    procedure FinProdOrderCannottBeReopenedIfFinishedQtyIsZeroInItsProdOrderLine()
    var
        Item: array[2] of Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderLine: Record "Prod. Order Line";
        ManufacturingSetup: Record "Manufacturing Setup";
        ReleasedProductionOrder: TestPage "Released Production Order";
        FinishedProductionOrder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 562948] When Stan runs Reopen Finished Prod. Order action from a Finished Production Order having 
        // Finished Quantity equal to 0 in any of its Prod. Order Line then it gives error that
        // this production order cannot be reopened.
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item [1] and Validate Costing Method.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Costing Method", Item[1]."Costing Method"::FIFO);
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', Location.Code, false);

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create Item [2] and Validate Costing Method and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Costing Method", Item[2]."Costing Method"::FIFO);
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Validate Finish Order without Output in Manufacturing Setup.
        ManufacturingSetup.Get();
        ManufacturingSetup."Finish Order without Output" := true;
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.", LibraryRandom.RandInt(0), Location.Code, '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Open Released Production Order page and run Change Status action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [WHEN] Open Finished Production Order and run Reopen Finished Prod. Order action.
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.GoToRecord(ProductionOrder);
        asserterror FinishedProductionOrder.ReopenFinishedProdOrder.Invoke();

        // [THEN] Production order cannot be reopened error is displayed.
        Assert.ExpectedError(ProductionOrderCannotBeReopenedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowWhseOverpickIsVisibleAndEnabledOnItemCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 321914] Allow Whse. Overpick field is Visible and Enabled on Item Card page.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [WHEN] Open Item Card page.
        ItemCard.OpenEdit();
        ItemCard.GoToRecord(Item);

        // [THEN] Allow Whse. Overpick is Visible on Item Card.
        Assert.IsTrue(
            ItemCard."Allow Whse. Overpick".Visible(),
            StrSubstNo(
                FieldMustBeVisibleErr,
                ItemCard."Allow Whse. Overpick".Caption(),
                ItemCard.Caption()));

        // [THEN] Allow Whse. Overpick is Enabled on Item Card.
        Assert.IsTrue(
            ItemCard."Allow Whse. Overpick".Enabled(),
            StrSubstNo(
                FieldMustBeEnabledErr,
                ItemCard."Allow Whse. Overpick".Caption(),
                ItemCard.Caption()));
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocPageHandler,MessageHandlerNoText')]
    [Scope('OnPrem')]
    procedure QtyInWhsePickLinesCanBeMoreThanProdOrderComponentQtyIfAllowWhseOverpickIsTrueInCompItem()
    var
        Bin: array[4] of Record Bin;
        Item: array[2] of Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
    begin
        // [SCENARIO 321914] Quantity in Warehouse Pick Lines can be entered more than the Quantity of 
        // Prod. Order Component if Allow Whse. Overpick in Component Item.
        Initialize();

        // [GIVEN] Create a Location and Validate Prod. Consump. Whse. Handling.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Modify(true);

        // [GIVEN] Create two Bins.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');

        // [GIVEN] Validate From-Production Bin Code and To-Production Bin Code in Location.
        Location.Validate("From-Production Bin Code", Bin[1].Code);
        Location.Validate("To-Production Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Create Item [1] and Validate Costing Method, Replenishment System and Allow Whse. Overpick.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Costing Method", Item[1]."Costing Method"::FIFO);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Validate("Allow Whse. Overpick", true);
        Item[1].Modify(true);

        // [GIVEN] Create and Post two Item Journal Lines.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), Bin[1].Code, Location.Code, false);
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), Bin[2].Code, Location.Code, false);

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader,
            ProductionBOMLine,
            '',
            ProductionBOMLine.Type::Item,
            Item[1]."No.",
            LibraryRandom.RandIntInRange(3, 3));

        // [GIVEN] Validate Status in Production BOM Header.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create Item [2] and Validate Costing Method and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Costing Method", Item[2]."Costing Method"::FIFO);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Validate("Allow Whse. Overpick", true);
        Item[2].Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderComponent.SetRange("Item No.", Item[1]."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Validate Location Code and Bin Code in Prod. Order Component.
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Validate("Bin Code", Bin[1].Code);
        ProdOrderComponent.Modify(true);

        // [GIVEN] Open Released Production Order and run Create Warehouse Pick.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Create Warehouse Pick".Invoke();

        // [GIVEN] Generate and save Quantity in a Variable.
        Quantity := LibraryRandom.RandIntInRange(24, 24);

        // [GIVEN] Find Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        WarehouseActivityLine.FindFirst();

        // [WHEN] Validate Quantity in Warehouse Activity Line.
        WarehouseActivityLine.Validate(Quantity, Quantity);
        WarehouseActivityLine.Modify(true);

        // [THEN] Quantity in Warehouse Activity Line is equal to Quantity.
        Assert.AreEqual(
            Quantity,
            WarehouseActivityLine.Quantity,
            StrSubstNo(
                QuantityErr,
                WarehouseActivityLine.FieldCaption(Quantity),
                Quantity,
                WarehouseActivityLine.TableCaption()));

        // [THEN] Qty. to Handle in Warehouse Activity Line is equal to Quantity.
        Assert.AreEqual(
            Quantity,
            WarehouseActivityLine."Qty. to Handle",
            StrSubstNo(
                QuantityErr,
                WarehouseActivityLine.FieldCaption("Qty. to Handle"),
                Quantity,
                WarehouseActivityLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler3,ConfirmHandler,MessageHandlerNoText')]
    [Scope('OnPrem')]
    procedure QtyInConsumpProdJnlLineCanBeMoreThanProdOrderComponentQtyIfAllowWhseOverpickIsTrueInCompItem()
    var
        Bin: array[2] of Record Bin;
        Item: array[2] of Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // [SCENARIO 321914] Quantity in Consumption Entry Type Production Journal Line can be entered more than 
        // the Quantity of prod. Order Component if Allow Whse. Overpick is true in Component Item.
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Modify(true);

        // [GIVEN] Create two Bins.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');

        // [GIVEN] Validate From-Production Bin Code and To-Production Bin Code in Location.
        Location.Validate("From-Production Bin Code", Bin[1].Code);
        Location.Validate("To-Production Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Create Item [1] and Validate Costing Method, Replenishment System and Allow Whse. Overpick.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Costing Method", Item[1]."Costing Method"::FIFO);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Validate("Allow Whse. Overpick", true);
        Item[1].Modify(true);

        // [GIVEN] Create and Post two Item Journal Lines.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), Bin[1].Code, Location.Code, false);
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), Bin[2].Code, Location.Code, false);

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(3, 3));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create Item [2] and Validate Costing Method and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Costing Method", Item[2]."Costing Method"::FIFO);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Validate("Allow Whse. Overpick", true);
        Item[2].Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Component.
        ProdOrderComponent.SetRange("Item No.", Item[1]."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Validate Location Code and Bin Code in Prod. Order Component.
        ProdOrderComponent.Validate("Location Code", Location.Code);
        ProdOrderComponent.Validate("Bin Code", Bin[1].Code);
        ProdOrderComponent.Modify(true);

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Generate and save Quantity in a Variable.
        Quantity := LibraryRandom.RandIntInRange(5, 5);

        // [WHEN] Create and Post Production Journal.
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Quantity);
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [THEN] Quantity in Production Journal is equal to Quantity in ProductionJnlPageHandler3.
    end;

    [Test]
    [HandlerFunctions('WhseSourceCreateDocPageHandler,ReturnOverpickedQtyPageHandler,MessageHandlerNoText')]
    [Scope('OnPrem')]
    procedure QtyInMovementWorksheetLineIsDiffOfQtyInBinContentAndRemQtyOfProdOrderComponentWhenRunReturnOverPickedQuantity()
    var
        Bin: array[2] of Record Bin;
        BinContent: Record "Bin Content";
        Item: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        MovementWorksheet: TestPage "Movement Worksheet";
    begin
        // [SCENARIO 321914] Quantity in Movement Worksheet Line is equal to difference of Quanity in Bin Content and 
        // Remaining Quantity of Prod. Order Component when Stan runs Return Over-Picked Quantity action.
        Initialize();

        // [GIVEN] Find Bin [1].
        LibraryWarehouse.FindBin(Bin[1], LocationWhite.Code, FindPickZone(LocationWhite.Code), 1);

        // [GIVEN] Find Bin [2].
        Bin[2].Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // [GIVEN] Create Warehouse Employee.
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);

        // [GIVEN] Create Item [1] and Validate Costing Method, Replenishment System and Allow Whse. Overpick.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Costing Method", Item[1]."Costing Method"::FIFO);
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Validate("Allow Whse. Overpick", true);
        Item[1].Modify(true);

        // [GIVEN] Create a Warehouse Journal Line.
        CreateWarehouseItemJournalLine(LocationWhite.Code, Bin[1].Code, Bin[2].Code, Item[1]."No.");

        // [GIVEN] Calculate Warehouse Adjustment and Post Item Journal Line.
        CalculateWarehouseAdjustmentAndPostItemJournalLine(Item[1]);

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader,
            ProductionBOMLine,
            '',
            ProductionBOMLine.Type::Item,
            Item[1]."No.",
            LibraryRandom.RandIntInRange(3, 3));

        // [GIVEN] Validate Status in Production BOM Header.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create Item [2] and Validate Costing Method, Replenishment System, Production BOM No. and Allow Whse. Overpick.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Costing Method", Item[2]."Costing Method"::FIFO);
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Validate("Allow Whse. Overpick", true);
        Item[2].Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.", LibraryRandom.RandInt(0), '', '');

        // [GIVEN] Find Prod. Order Component.
        ProdOrderComponent.SetRange("Item No.", Item[1]."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Validate Location Code and Bin Code in Prod. Order Component.
        ProdOrderComponent.Validate("Location Code", LocationWhite.Code);
        ProdOrderComponent.Validate("Bin Code", Bin[2].Code);
        ProdOrderComponent.Modify(true);

        // [GIVEN] Open Released Production Order page and run Create Warehouse Pick action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Create Warehouse Pick".Invoke();

        // [GIVEN] Find Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        WarehouseActivityLine.FindFirst();

        // [GIVEN] Validate Quantity in Warehouse Activity Line.
        WarehouseActivityLine.Validate(Quantity, LibraryRandom.RandIntInRange(6, 6));
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Find and Validate Quantity in Warehouse Activity Line.
        WarehouseActivityLine.FindLast();
        WarehouseActivityLine.Validate(Quantity, LibraryRandom.RandIntInRange(6, 6));
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");

        // [GIVEN] Register Warehouse Pick.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Create Whse. Worksheet Name.
        CreateWhseWorksheetName(WhseWorksheetName, LocationWhite.Code, WhseWorksheetName."Template Type"::Movement);

        // [GIVEN] Open Movement Worksheet and run Return Over-Picked Quantity action.
        MovementWorksheet.OpenEdit();
        LibraryVariableStorage.Enqueue(Format(WhseWorksheetName."Worksheet Template Name"));
        LibraryVariableStorage.Enqueue(Format(WhseWorksheetName.Name));
        LibraryVariableStorage.Enqueue(Format(LocationWhite.Code));
        LibraryVariableStorage.Enqueue(Format(Bin[2].Code));
        LibraryVariableStorage.Enqueue(Format(Bin[1].Code));
        MovementWorksheet."Return Over-Picked Quantity".Invoke();

        // [GIVEN] Find Bin Content.
        BinContent.Get(LocationWhite.Code, Bin[2].Code, Item[1]."No.", '', Item[1]."Base Unit of Measure");
        BinContent.CalcFields(Quantity);

        // [WHEN] Find Whse. Worksheet Line.
        WhseWorksheetLine.SetRange("From Bin Code", Bin[2].Code);
        WhseWorksheetLine.FindFirst();

        // [THEN] Quantity in Whse. Worksheet Line is equal to difference of Quantity in Bin Content and Remaining Quantity of Prod. Order Component.
        Assert.AreEqual(
            BinContent.Quantity - ProdOrderComponent."Remaining Quantity",
            WhseWorksheetLine.Quantity,
            StrSubstNo(
                QuantityErr,
                WhseWorksheetLine.FieldCaption(Quantity),
                BinContent.Quantity - ProdOrderComponent."Remaining Quantity",
                WhseWorksheetLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler,ConfirmHandler,MessageHandlerText')]
    procedure RelProdOrderDocPutAwayStatusIsUpdatedToPartiallyPutAwayWhenPostAdditionalOutputFromProductionJnlPage()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO 564545] Document Put-away Status of Released Production Order is updated to Partially Put-away
        // When Stan posts additional Output from Production Journal page.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Production Order and Validate Location Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);

        // [GIVEN] Create and Post Production Journal.
        LibraryVariableStorage.Enqueue(ProductionJournalPostedTxt);
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Register Warehouse Activity Header.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [THEN] Document Put-away Status in Production Order is equal to Completely Put-away.
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(
                DocumentPutAwayStatusErr,
                ProductionOrder."Document Put-away Status"::"Completely Put Away",
                ProductionOrder.TableCaption()));

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Validate Quantity in Prod. Order Line.
        ProdOrderLine.Validate(Quantity, ProdOrderLine.Quantity + LibraryRandom.RandIntInRange(1, 1));
        ProdOrderLine.Modify(true);

        // [WHEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [THEN] Document Put-away Status in Production Order is equal to Completely Put-away.
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Completely Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(
                DocumentPutAwayStatusErr,
                ProductionOrder."Document Put-away Status"::"Completely Put Away",
                ProductionOrder.TableCaption()));

        // [GIVEN] Create and Post Production Journal.
        LibraryVariableStorage.Enqueue(ProductionJournalPostedTxt);
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [WHEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [THEN] Document Put-away Status in Production order is equal to Partially Put-away.
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Partially Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(
                DocumentPutAwayStatusErr,
                ProductionOrder."Document Put-away Status"::"Partially Put Away",
                ProductionOrder.TableCaption()));

        // [WHEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [THEN] Put-away Status in Prod. Order Line is equal to Partially Put-away.
        Assert.AreEqual(
            ProdOrderLine."Put-away Status"::"Partially Put Away",
            ProdOrderLine."Put-away Status",
            StrSubstNo(
                DocumentPutAwayStatusErr,
                ProdOrderLine."Put-away Status"::"Partially Put Away",
                ProdOrderLine.TableCaption()));

        // [GIVEN] Find Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.FindFirst();

        // [GIVEN] Validate Qty. to Handle in Warehouse Activity Line.
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. to Handle" / LibraryRandom.RandIntInRange(2, 2));
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Find Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Location Code", Location.Code);
        WarehouseActivityLine.FindLast();

        // [GIVEN] Validate Qty. to Handle in Warehouse Activity Line.
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. to Handle" / LibraryRandom.RandIntInRange(2, 2));
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Register Warehouse Activity Header.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [THEN] Document Put-away Status in Production order is equal to Partially Put-away.
        Assert.AreEqual(
            ProductionOrder."Document Put-away Status"::"Partially Put Away",
            ProductionOrder."Document Put-away Status",
            StrSubstNo(
                DocumentPutAwayStatusErr,
                ProductionOrder."Document Put-away Status"::"Partially Put Away",
                ProductionOrder.TableCaption()));

        // [WHEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [THEN] Put-away Status in Prod. Order Line is equal to Partially Put-away.
        Assert.AreEqual(
            ProdOrderLine."Put-away Status"::"Partially Put Away",
            ProdOrderLine."Put-away Status",
            StrSubstNo(
                DocumentPutAwayStatusErr,
                ProdOrderLine."Put-away Status"::"Partially Put Away",
                ProdOrderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ThereIsNothingToCreateErrorIsThrownWhenCreateWhsePutAwayWithoutPostingOutputFromProductionJnlPage()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 564589] When Create Warehouse Put-away from Released Production Order page 
        // Without posting Output from Production Journal Page then 'There is nothing to create' error is thrown.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Production Order and Validate Location Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);

        // [WHEN] Open Released Production Order page and run Create Warehouse Put-Away action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        asserterror ReleasedProductionOrder."Create Warehouse Put-Away".Invoke();

        // [THEN] 'There is nothing to create' error is thrown.
        Assert.ExpectedError(ThereIsNothingToCreateErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ThereIsNothingToCreateErrorIsThrownWhenCreateWhseputAwayFromRelProdOrderHavingOnlyNo()
    var
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 564704] When Create Warehouse Put-away from Released Production Order page 
        // Having only No. on header then 'There is nothing to create' error is thrown.
        Initialize();

        // [GIVEN] Create a Production Order.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);

        // [WHEN] Open Released Production Order page and run Create Warehouse Put-Away action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        asserterror ReleasedProductionOrder."Create Warehouse Put-Away".Invoke();

        // [THEN] 'There is nothing to create' error is thrown.
        Assert.ExpectedError(ThereIsNothingToCreateErr);
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler2,ChangeStatusOnProdOrderPageHandler,ConfirmHandler,MessageHandlerNoText')]
    procedure PutAwayLinesAndRegisteredPutAwayLinesActionsAreVisibleAndEnabledOnFinProdOrderPage()
    var
        Item: array[2] of Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrderLine: Record "Prod. Order Line";
        ManufacturingSetup: Record "Manufacturing Setup";
        ReleasedProductionOrder: TestPage "Released Production Order";
        FinishedProductionOrder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 564776] Put-away Lines and Registered Put-away Lines actions are Visible
        // and Enabled on Finished Production order page.
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Item [1] and Validate Costing Method.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Costing Method", Item[1]."Costing Method"::FIFO);
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', Location.Code, false);

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create Item [2] and Validate Costing Method and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Costing Method", Item[2]."Costing Method"::FIFO);
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Validate Finish Order without Output in Manufacturing Setup.
        ManufacturingSetup.Get();
        ManufacturingSetup."Finish Order without Output" := true;
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.", LibraryRandom.RandInt(0), Location.Code, '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Open Released Production Order page and run Change Status action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [WHEN] Open Finished Production Order page.
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.GoToRecord(ProductionOrder);

        // [THEN] Put-away Lines action is Visible on Finished Production Order.
        Assert.IsTrue(FinishedProductionOrder."Put-away Lines".Visible(), PutAwayLinesActionMustBeVisibleErr);

        // [THEN] Put-away Lines action is Enabled on Finished Production Order.
        Assert.IsTrue(FinishedProductionOrder."Put-away Lines".Enabled(), PutAwayLinesActionMustBeEnabledErr);

        // [THEN] Registered Put-away Lines action is Visible on Finished Production Order.
        Assert.IsTrue(FinishedProductionOrder."Registered Put-away Lines".Visible(), RegPutAwayLinesActionMustBeVisibleErr);

        // [THEN] Registered Put-away Lines action is Enabled on Finished Production Order.
        Assert.IsTrue(FinishedProductionOrder."Registered Put-away Lines".Enabled(), RegPutAwayLinesActionMustBeEnabledErr);
    end;

    [Test]
    [HandlerFunctions('SalesOrderPlanningPageHandler,CreateOrderFromSalesPageHandler')]
    procedure TwoDiffWhsePutAwayLocationsOnWhenRefreshProdOrderGivesErrorIfCreatedFromSO()
    var
        Item: array[3] of Record Item;
        Customer: Record Customer;
        Bin: Record Bin;
        Location: array[2] of Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 561768] Two different Locations having Prod. Output Whse. Handling as 
        // Warehouse Put-away gives error when Refresh Production Order if created from a Sales Order.
        Initialize();

        // [GIVEN] Create Item [1] and Item [2].
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create Item [3] and Validate Replenishment System.
        LibraryInventory.CreateItem(Item[3]);
        Item[3].Validate("Replenishment System", Item[3]."Replenishment System"::"Prod. Order");
        Item[3].Modify(true);

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[3]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[3]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Validate Replenishment System, Manufacturing Policy and 
        // Production BOM No. in Item [1].
        Item[1].Validate("Replenishment System", Item[1]."Replenishment System"::"Prod. Order");
        Item[1].Validate("Manufacturing Policy", Item[1]."Manufacturing Policy"::"Make-to-Order");
        Item[1].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[1].Modify(true);

        // [GIVEN] Validate Replenishment System, manufacturing Policy and 
        // Production BOM No. in Item [2].
        Item[2].Validate("Replenishment System", Item[2]."Replenishment System"::"Prod. Order");
        Item[2].Validate("Manufacturing Policy", Item[2]."Manufacturing Policy"::"Make-to-Order");
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Create Location [1] with Inventory Posting Setup and
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        Location[1].Validate("Bin Mandatory", true);
        Location[1].Validate("Prod. Output Whse. Handling", Location[1]."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location[1].Modify(true);

        // [GIVEN] Create Location [2] with Inventory Posting Setup and
        // Validate Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);
        Location[2].Validate("Prod. Output Whse. Handling", Location[2]."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location[2].Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location[1].Code, Bin.Code, '', '');

        // [GIVEN] Validate From-Production Bin Code in Location [1].
        Location[1].Validate("From-Production Bin Code", Bin.Code);
        Location[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[3]."No.", LibraryRandom.RandIntInRange(10, 10), '', Location[2].Code);

        // [GIVEN] Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create a Sales Line [1] and Validate Location Code.
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, Item[1]."No.", LibraryRandom.RandInt(0));
        SalesLine[1].Validate("Location Code", Location[1].Code);
        SalesLine[1].Modify(true);

        // [GIVEN] Create a Sales Line [2] and Validate Location Code.
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item[2]."No.", LibraryRandom.RandIntInRange(2, 2));
        SalesLine[2].Validate("Location Code", Location[2].Code);
        SalesLine[2].Modify(true);

        // [WHEN] Open Sales Order page and run Planning action.
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);
        asserterror SalesOrder."Pla&nning".Invoke();

        // [THEN] Error on Location Code of Production Order.
        Assert.ExpectedTestFieldError(ProductionOrder.FieldCaption("Location Code"), Location[1].Code);
        SalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler,ChangeStatusOnProdOrderPageHandler,WhsePutAwayDocSelectionPageHandler,WhseSourceCreateDocumentPageHandler,ConfirmHandler,MessageHandlerNoText')]
    procedure WhsePutAwayIsCreatedFromWhsePutAwayWorksheetIfFinishReleasedProdOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 564940] Warehouse Put-away is created from Put-away Worksheet even if  
        // Stan finishes the Released Production Order.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Production Order and Validate Location Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Delete Warehouse Activity Header.
        WarehouseActivityHeader.Delete(true);

        // [GIVEN] Create Put-Away from Put-Away Worksheet.
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(Format(ProdOrderLine."Location Code"));
        LibraryVariableStorage.Enqueue(Format(ProductionOrder."No."));
        CreatePutawayFromPutawayWorksheet(Location);

        // [GIVEN] Open Released Production Order page and run Change Status action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Whse. Worksheet Line.
        WhseWorksheetLine.SetRange("Location Code", Location.Code);
        WhseWorksheetLine.FindFirst();

        // [GIVEN] Create Put-away from Whse. Worksheet Line.
        WhseWorksheetLine.PutAwayCreate(WhseWorksheetLine);

        // [WHEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Warehouse Activity header is found.
        Assert.IsFalse(WarehouseActivityHeader.IsEmpty(), WhseActivityHeaderMustBeFoundErr);
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler,ChangeStatusOnProdOrderPageHandler,ConfirmHandler,MessageHandlerNoText')]
    procedure WhsePutAwayIsRegisteredIfCreatedByPostingOutputFromProductionJournalAndThenFinishRelProdOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // [SCENARIO 564945] Warehouse Put-away is registered if created by posting Output from Production Journal
        // and then Finish Released Production Order.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Production Order and Validate Location Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Open Released Production Order page and run Change Status action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Register Warehouse Activity Header.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Registered Whse. Activity Hdr.
        RegisteredWhseActivityHdr.SetRange("Location Code", Location.Code);
        RegisteredWhseActivityHdr.FindFirst();

        // [THEN] Registered Whse. Activity Hdr. is found.
        Assert.IsFalse(RegisteredWhseActivityHdr.IsEmpty(), RegisteredWhseActivityHdrMustBeFoundErr);
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler,ChangeStatusOnProdOrderPageHandler,ConfirmHandler,MessageHandlerNoText')]
    procedure WhsePutAwayIsRegisteredIfCreatedFromFinishedProdOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        ReleasedProductionOrder: TestPage "Released Production Order";
        FinishedProductionOrder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 564945] Warehouse Put-away is registered if created from a Finish Production Order.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Production Order and Validate Location Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Delete Warehouse Activity Header.
        WarehouseActivityHeader.Delete(true);

        // [GIVEN] Open Released Production Order page and run Change Status action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [GIVEN] Open Finished Production Order page and run Create Warehouse Put-Away action.
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.GoToRecord(ProductionOrder);
        FinishedProductionOrder."Create Warehouse Put-Away".Invoke();

        // [GIVEN] Run Reopen Finished production Order action.
        ReleasedProductionOrder.Trap();
        FinishedProductionOrder.ReopenFinishedProdOrder.Invoke();

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Register Warehouse Activity Header.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Registered Whse. Activity Hdr.
        RegisteredWhseActivityHdr.SetRange("Location Code", Location.Code);
        RegisteredWhseActivityHdr.FindFirst();

        // [THEN] Registered Whse. Activitry Hdr. is found.
        Assert.IsFalse(RegisteredWhseActivityHdr.IsEmpty(), RegisteredWhseActivityHdrMustBeFoundErr);
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler,ChangeStatusOnProdOrderPageHandler,ConfirmHandler,MessageHandlerNoText')]
    procedure WhsePutAwayCreatedFromFinProdOrderIsStillFoundIfReopenFinProdOrder()
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ReleasedProductionOrder: TestPage "Released Production Order";
        FinishedProductionOrder: TestPage "Finished Production Order";
    begin
        // [SCENARIO 564943] Warehouse Put-away created from a Finish Production Order
        // Is still found if Stan reopens Finished produtcion Order.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location with Inventory Posting Setup and
        // Validate Bin Mandatory, Prod. Output Whse. Handling.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Output Whse. Handling", Location."Prod. Output Whse. Handling"::"Warehouse Put-away");
        Location.Modify(true);

        // [GIVEN] Create a Bin.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create a Production Order and Validate Location Code.
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, '', 0);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Create a Prod Order Line and Validate Bin Code.
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductionOrder."No.", Item."No.", '', Location.Code, LibraryRandom.RandIntInRange(2, 2));
        ProdOrderLine.Validate("Bin Code", Bin.Code);
        ProdOrderLine.Modify(true);

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [GIVEN] Delete Warehouse Activity Header.
        WarehouseActivityHeader.Delete(true);

        // [GIVEN] Open Released Production Order page and run Change Status action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [GIVEN] Find Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");

        // [GIVEN] Open Finished Production Order page and run Create Warehouse Put-Away action.
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.GoToRecord(ProductionOrder);
        FinishedProductionOrder."Create Warehouse Put-Away".Invoke();

        // [GIVEN] Run Reopen Finished Production Order action.
        ReleasedProductionOrder.Trap();
        FinishedProductionOrder.ReopenFinishedProdOrder.Invoke();

        // [WHEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();

        // [THEN] Warehouse Activity Header.
        Assert.IsFalse(WarehouseActivityHeader.IsEmpty(), WhseActivityHeaderMustBeFoundErr);
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler2,ConfirmHandler,MessageHandlerNoText')]
    procedure CostAmtNonInvtblIsNotZeroInReversedConsumpTypeILEHavingNonInvItem()
    var
        Item: array[2] of Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        UndoProdPostingMgmt: Codeunit "Undo Prod. Posting Mgmt.";
    begin
        // [SCENARIO 565139] Cost Amount (Non-Invtbl.) is not equal to 0 in Reversed 
        // Item Ledger Entry of the posted Consumption Type Item Ledger Entry 
        // Having Non - Inventory Type Item.
        Initialize();

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Create Item [1].
        LibraryInventory.CreateItem(Item[1]);

        // [GIVEN] Create Item [2] and Validate Type and Unit Cost.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Type", Item[2].Type::"Non-Inventory");
        Item[2].Validate("Unit Cost", LibraryRandom.RandIntInRange(1, 1));
        Item[2].Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[1]."No.", LibraryRandom.RandIntInRange(1, 1), '', '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(ProdOrderLine.Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Create Prod. Order Component and Validate Item No. and Quantity per.
        LibraryManufacturing.CreateProductionOrderComponent(ProdOrderComponent, ProdOrderComponent.Status::Released, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", Item[2]."No.");
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandIntInRange(10, 10));
        ProdOrderComponent.Modify(true);

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Find Item Ledger Entry.
        ItemLedgerEntry.SetRange("Item No.", Item[2]."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.FindFirst();

        // [GIVEN] Reverse Production Item Ledger Entry.
        ItemLedgerEntry.SetRange("Entry No.", ItemLedgerEntry."Entry No.");
        UndoProdPostingMgmt.ReverseProdItemLedgerEntry(ItemLedgerEntry);

        // [WHEN] Find Item Ledger Entry.
        ItemLedgerEntry.Reset();
        ItemLedgerEntry.SetRange("Item No.", Item[2]."No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Consumption);
        ItemLedgerEntry.FindLast();

        // [THEN] Cost Amount (Non-Invtbl.) is not equal to 0 in Item Ledger Entry.
        ItemLedgerEntry.CalcFields("Cost Amount (Non-Invtbl.)");
        Assert.IsTrue(
            ItemLedgerEntry."Cost Amount (Non-Invtbl.)" <> 0,
            StrSubstNo(
                CostAmtNonInvtblMustNotBeZeroErr,
                ItemLedgerEntry.FieldCaption("Cost Amount (Non-Invtbl.)"),
                ItemLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,WhseSourceCreateDocPageHandler,MessageHandlerNoText')]
    procedure WhsePutAwayRegisteredIfCreatedByWarehousePickFromReleasedProdOrderIfAllowWhseOverpickIsTrueInLotTrackedCompItem()
    var
        Bin: array[3] of Record Bin;
        Item: array[2] of Record Item;
        Location: Record Location;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        Quantity: Decimal;
        i: Integer;
    begin
        // [SCENARIO 578160] Verify Warehouse put-away is registered if it is created by a warehouse pick from a released production order, 
        // and if 'Allow Whse. Overpick' is set to true for a lot-tracked component item.
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);

        // [GIVEN] Create three bins.
        for i := 1 to LibraryRandom.RandIntInRange(3, 3) do
            LibraryWarehouse.CreateBin(Bin[i], Location.Code, Bin[i].Code, '', '');

        // [GIVEN] Validate From-Production Bin Code,To-Production Bin Code & Open Shop Floor Bin Code in Location.
        Location.Get(Location.Code);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Validate("From-Production Bin Code", Bin[1].Code);
        Location.Validate("To-Production Bin Code", Bin[2].Code);
        Location.Validate("Open Shop Floor Bin Code", Bin[3].Code);
        Location.Modify(true);

        // [GIVEN] Create Item and Validate Costing Method, Replenishment System and Allow Whse. Overpick.
        CreateLotTrackedItemWithAllowWhseOverpick(Item[1]);

        // [GIVEN] Create and Post Item Journal Lines with Lot No.
        LotNo := LibraryRandom.RandText(50);

        CreateAndPostItemJournalLineWithManualLot(
            Item[1]."No.", LibraryRandom.RandIntInRange(150, 200),
            Bin[3].Code, Location.Code, LotNo, true);

        // [GIVEN] Create a Production BOM Header.
        CreateProductionBOM(Item[1], ProductionBOMHeader);

        // [GIVEN] Create Item [2] and Validate Costing Method and Production BOM No.
        CreateItemWithProductionBOM(Item[2], ProductionBOMHeader."No.");

        // [GIVEN] Create Released Production Order.
        CreateAndRefreshProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.",
            LibraryRandom.RandIntInRange(80, 100), Location.Code, '');

        // [GIVEN] Find Prod. Order Component.
        FindAndUpdateProdOrderComponent(Item[1]."No.", Location.Code, Bin[1].Code);

        // [GIVEN] Create warehouse pick from released production order.
        OpenReleasedProdOrderPageAndCreateWarehousePick(ProductionOrder);

        // [GIVEN] Generate and save Quantity in a variable.
        Quantity := LibraryRandom.RandIntInRange(110, 120);

        // [WHEN] Find and update Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate(Quantity, Quantity);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.FindLast();
        WarehouseActivityLine.Validate(Quantity, Quantity);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");

        // [WHEN] Register Warehouse Pick.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Find Registered Whse. Activity Hdr.
        RegisteredWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityLine."No.");
        RegisteredWhseActivityHdr.SetRange("Location Code", Location.Code);
        RegisteredWhseActivityHdr.FindFirst();

        // [THEN] Registered Whse. Activity Hdr. is found.
        Assert.IsFalse(RegisteredWhseActivityHdr.IsEmpty(), RegisteredWhseActivityHdrMustBeFoundErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerWithExpiration,WhseSourceCreateDocPageHandler,MessageHandlerNoText')]
    procedure WarehousePickWithBinsAndLotTrackingForProduction()
    var
        Bin: array[5] of Record Bin;
        Item: array[2] of Record Item;
        Location: Record Location;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
    begin
        // [SCENARIO 578385] Verify Warehouse Pick with Bins have Lot tracking for Production Order when Quantity is limited
        Initialize();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);

        // [GIVEN] Create three bins.
        CreateBin(Bin, Location.Code);

        // [GIVEN] Assign two bins as dedicated bins
        Bin[1].Validate(Dedicated, true);
        Bin[1].Modify();
        Bin[2].Validate(Dedicated, true);
        Bin[2].Modify();

        // [GIVEN] Set Bins in Location and Pick According to FEFO.
        Location.Get(Location.Code);
        Location.Validate("Pick According to FEFO", true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)");
        Location.Validate("Open Shop Floor Bin Code", Bin[1].Code);
        Location.Validate("To-Production Bin Code", Bin[2].Code);
        Location.Validate("From-Production Bin Code", Bin[3].Code);
        Location.Validate("Shipment Bin Code", Bin[4].Code);
        Location.Modify(true);

        // [GIVEN] Create Lot tracked item with Use Expiration Date
        CreateLotTrackedItemWithUseExpirationDate(Item[1]);

        // [GIVEN] Set Lot No.
        LotNo := LibraryRandom.RandText(50);

        // [GIVEN] Create and Post Item Journal Line with Lot No. and Expiration Date.
        CreateAndPostItemJournalLineWithManualLotExpiration(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), Bin[5].Code, Location.Code, LotNo, true);

        // [GIVEN] Create a Production BOM Header with Qty. per.
        CreateProductionBOMWithQtyPer(Item[1], ProductionBOMHeader, 1);

        // [GIVEN] Create production item and validate Production BOM No.
        CreateItemWithProductionBOM(Item[2], ProductionBOMHeader."No.");

        // [GIVEN] Create Released Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.", LibraryRandom.RandIntInRange(6, 6), Location.Code, Bin[3].Code);

        // [GIVEN] Create warehouse pick from released production order.
        OpenReleasedProdOrderPageAndCreateWarehousePick(ProductionOrder);

        // [GIVEN] Find Warehouse Activity Line. and register Pick
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.", LibraryRandom.RandIntInRange(4, 4), Location.Code, Bin[3].Code);

        // [WHEN] Release Prod . Order and Create Warehouse Pick.
        OpenReleasedProdOrderPageAndCreateWarehousePick(ProductionOrder);

        // [THEN] Find and verify Lot No. in Warehouse Activity Line.
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        WarehouseActivityLine.FindFirst();

        // [THEN] Lot No. in Warehouse Activity Line must be equal to Lot No. in Item Journal Line.
        Assert.AreEqual(WarehouseActivityLine."Lot No.", LotNo,
                        StrSubstNo(LotNoMustBeEqualErr, WarehouseActivityLine.FieldCaption("Lot No."), LotNo, WarehouseActivityLine.TableCaption));
        WarehouseActivityLine.FindLast();
        Assert.AreEqual(WarehouseActivityLine."Lot No.", LotNo,
                        StrSubstNo(LotNoMustBeEqualErr, WarehouseActivityLine.FieldCaption("Lot No."), LotNo, WarehouseActivityLine.TableCaption));
    end;

    [Test]
    procedure VerifyProdOrderWithVariantBasedBOMStructure()
    var
        ComponentItem: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        MainItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ReqLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
        StockkeepingUnit2: Record "Stockkeeping Unit";
        NewProdOrderChoice: Option " ",Planned,"Firm Planned","Firm Planned & Print","Copy to Req. Wksh";
    begin
        // [SCENARIO 608781] Create production order with variant-based BOM structure and verify production lines,
        Initialize();

        // [GIVEN] Create component item with Lot-for-Lot reordering policy
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItem.Validate("Reordering Policy", ComponentItem."Reordering Policy"::"Lot-for-Lot");
        ComponentItem.Validate("Replenishment System", ComponentItem."Replenishment System"::"Purchase");
        ComponentItem.Validate("Flushing Method", ComponentItem."Flushing Method"::Manual);
        ComponentItem.Modify(true);

        // [GIVEN] Create main item with Make-to-Order manufacturing policy
        LibraryInventory.CreateItem(MainItem);
        MainItem.Validate("Manufacturing Policy", MainItem."Manufacturing Policy"::"Make-to-Order");
        MainItem.Validate("Replenishment System", MainItem."Replenishment System"::"Prod. Order");
        MainItem.Validate("Reordering Policy", MainItem."Reordering Policy"::Order);
        MainItem.Validate("Flushing Method", MainItem."Flushing Method"::Manual);
        MainItem.Modify(true);

        // [GIVEN] Create PINK and VIOLET variants for main item
        LibraryInventory.CreateItemVariant(ItemVariant, MainItem."No.");
        ItemVariant.Validate(Description, 'PINK');
        ItemVariant.Modify(true);
        LibraryInventory.CreateItemVariant(ItemVariant2, MainItem."No.");
        ItemVariant2.Validate(Description, 'VIOLET');
        ItemVariant2.Modify(true);

        // [GIVEN] Create Stockkeeping Units for both variants
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, '', MainItem."No.", ItemVariant.Code);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit2, '', MainItem."No.", ItemVariant2.Code);

        // [GIVEN] Create Production BOM for PINK variant with component item
        CreateProductionBOMAndCertify(
            ProductionBOMHeader, MainItem."Base Unit of Measure", ProductionBOMLine.Type::Item, ComponentItem."No.", 1, 'PINK', '');
        StockkeepingUnit.Validate("Production BOM No.", ProductionBOMHeader."No.");
        StockkeepingUnit.Modify(true);

        // [GIVEN] Create Production BOM for VIOLET variant with main item and PINK variant
        CreateProductionBOMAndCertify(
            ProductionBOMHeader, MainItem."Base Unit of Measure", ProductionBOMLine.Type::Item, MainItem."No.", 1, 'VIOLET', ItemVariant.Code);
        StockkeepingUnit2.Validate("Production BOM No.", ProductionBOMHeader."No.");
        StockkeepingUnit2.Modify(true);

        // [GIVEN] Create Sales Order with VIOLET variant
        CreateSalesOrder(SalesHeader, MainItem."No.", 1, ItemVariant2.Code);

        // [GIVEN] Calculate regenerative plan in planning worksheet update Planning Worksheet.
        CalculatePlanOnPlanningWorksheet(MainItem, WorkDate(), CalcDate('<1Y>', WorkDate()), false, false);

        // [GIVEN] Set "Accept Action Message" on all Requisition lines.
        UpdatePlanningWorkSheetwithVendor(ReqLine, MainItem."No.", ItemVariant2.Code);

        // [WHEN] Running Carry Out Action Message For Requisition lines "Action Message"::Cancel.
        ReqLine.SetRange("Action Message", ReqLine."Action Message"::New);
        LibraryPlanning.CarryOutPlanWksh(ReqLine, NewProdOrderChoice::"Firm Planned", 0, 0, 0, '', '', '', '');

        // [THEN] Verify Firm Planned Production Order has two lines
        VerifyProductionOrderLines(MainItem."No.");
    end;

    [Test]
    [HandlerFunctions('ProductionJnlPageHandler2,ChangeStatusOnProdOrderPageHandler,ConfirmHandler,MessageHandlerNoText')]
    procedure FinishProdOrderNoOutputUseNewPostingDateForWIPAdjustments()
    var
        Item: array[2] of Record Item;
        Location: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ReleasedProductionOrder: TestPage "Released Production Order";
        FinishPostingDate: Date;
    begin
        // [SCENARIO 606044] When using 'Finish Order Without Output' posted on different Posting Date in period is using current Posting Date on Finish status change.
        Initialize();

        // [GIVEN] Set Finish Posting Date to Work Date.
        FinishPostingDate := WorkDate();

        // [GIVEN] Create a Location with Inventory Posting Setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Update Allow Posting From/To in General Ledger Setup.
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Allow Posting From" := CalcDate('<-1M>', WorkDate() - 1);
        GeneralLedgerSetup."Allow Posting To" := CalcDate('<+3M>', WorkDate());
        GeneralLedgerSetup.Modify();

        // [GIVEN] Create Item [1] and Validate Costing Method.
        LibraryInventory.CreateItem(Item[1]);
        Item[1].Validate("Costing Method", Item[1]."Costing Method"::FIFO);
        Item[1].Modify(true);

        // [GIVEN] Create and Post Item Journal Line.
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(10, 10), '', Location.Code, false);

        // [GIVEN] Create a Production BOM Header.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");

        // [GIVEN] Create a Production BOM Line.
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandIntInRange(2, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        // [GIVEN] Create Item [2] and Validate Costing Method and Production BOM No.
        LibraryInventory.CreateItem(Item[2]);
        Item[2].Validate("Costing Method", Item[2]."Costing Method"::FIFO);
        Item[2].Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item[2].Modify(true);

        // [GIVEN] Validate Finish Order without Output in Manufacturing Setup.
        ManufacturingSetup.Get();
        ManufacturingSetup."Finish Order without Output" := true;
        ManufacturingSetup.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item[2]."No.", LibraryRandom.RandInt(0), Location.Code, '');

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [GIVEN] Create and Post Production Journal.
        CreateAndPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Open Released Production Order page and run Change Status action.
        WorkDate(FinishPostingDate);

        // [WHEN] Open Released Production Order page and run Change Status action.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Change &Status".Invoke();

        // [THEN] Finished Production Order status is found.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
        Assert.RecordIsNotEmpty(ProductionOrder);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Production Orders II");
        LibraryVariableStorage.Clear();

        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Production Orders II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        OutputJournalSetup();
        ConsumptionJournalSetup();
        RevaluationJournalSetup();
        ShopCalendarMgt.ClearInternals(); // clear single instance codeunit vars to avoid influence of other test codeunits
        LibrarySetupStorage.SaveInventorySetup();
        LibrarySetupStorage.SaveManufacturingSetup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Production Orders II");
    end;

    local procedure ChangeItemJnlLineGenProdPostingGroup(var ItemJournalLine: Record "Item Journal Line")
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.SetFilter(Code, '<>%1', ItemJournalLine."Gen. Prod. Posting Group");
        GenProductPostingGroup.FindFirst();
        ItemJournalLine."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        ItemJournalLine.Modify();
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

        CreateAndUpdateLocation(LocationGreen2, true, true, true, false);  // Location Green.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen2.Code, false);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        SalesSetup.Get();
        SalesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", '');  // Value required to avoid the Document No mismatch.
        ItemJournalBatch.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure RevaluationJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(RevaluationItemJournalTemplate, RevaluationItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(
          RevaluationItemJournalBatch, RevaluationItemJournalTemplate.Type, RevaluationItemJournalTemplate.Name);
    end;

    local procedure AssertNearlyEqual(Expected: Decimal; Actual: Decimal; Msg: Text)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(Expected, Actual, GeneralLedgerSetup."Unit-Amount Rounding Precision", Msg);
    end;

    local procedure AssignNoSeriesForItemJournalBatch(var ItemJnlBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJnlBatch.Validate("No. Series", NoSeries);
        ItemJnlBatch.Modify(true);
    end;

    local procedure AcceptAndCarryOutActionMessage(No: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, No);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, false, RequireShipment);
    end;

    local procedure CreateLocationWithBins(var Location: Record Location; var BinCode: array[5] of Code[20]; NoOfBins: Integer)
    var
        Bin: Record Bin;
        i: Integer;
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', NoOfBins, false);
        for i := 1 to NoOfBins do begin
            LibraryWarehouse.FindBin(Bin, Location.Code, '', i);
            BinCode[i] := Bin.Code;
        end;
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(Item2);

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionItemWithScrapPercent(var Item: Record Item; ProductionBOMNo: Code[20]; ScrapPercent: Integer)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Scrap %", ScrapPercent);
        Item.Modify(true);
    end;

    local procedure CreateMachineCenterWithFixedScrap(FixedScrapQuantity: Decimal): Code[20]
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenter."No.", 1);
        MachineCenter.Validate("Fixed Scrap Quantity", FixedScrapQuantity);
        MachineCenter.Modify(true);
        exit(MachineCenter."No.");
    end;

    local procedure CreateRoutingWithMachineCenter(MachineCenterNo: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '',
          LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
          RoutingLine.Type::"Machine Center", MachineCenterNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateItemCostingMethodFIFO(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Unit Cost", 1);
        Item.Validate("Rounding Precision", 0.01);
        Item.Modify(true);
    end;

    local procedure CreateProductionBOMWitScrapPercent(Item: Record Item; ScrapPercent: Decimal): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
        ProductionBOMLine.Validate("Scrap %", ScrapPercent);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProdOrderItemWithScrapPercent(var Item: Record Item; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ScrapPercent: Decimal; LotSize: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Rounding Precision", 0.01);
        Item.Validate("Routing No.", RoutingNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Scrap %", ScrapPercent);
        Item.Validate("Lot Size", LotSize);
        Item.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);  // Value important.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateCertifiedProductionBOMWithQtyPer(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20]; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No, QtyPer);
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

    local procedure CreateProductionItemWithRoutingNo(var Item: Record Item; RoutingNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateMakeToOrderProductionItem(var Item: Record Item; CompItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::Order);
        Item.Validate("Flushing Method", Item."Flushing Method"::Backward);
        Item.Modify(true);
    end;

    local procedure CreateProductionChainOfItems(var ItemNo: array[5] of Code[20]; BOMStructureDepth: Integer)
    var
        CompItem: Record Item;
        ProdItem: array[5] of Record Item;
        i: Integer;
    begin
        CreateItemsSetup(ProdItem[1], CompItem);
        ItemNo[1] := ProdItem[1]."No.";

        for i := 2 to BOMStructureDepth do begin
            CreateMakeToOrderProductionItem(ProdItem[i], ProdItem[i - 1]);
            ItemNo[i] := ProdItem[i]."No.";
        end;
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateItemSetupWithLotTracking(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode());
        CreateItemWithItemTrackingCode(Item2, CreateItemTrackingCode());
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item);
        Item2.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item2.Modify(true);
    end;

    local procedure CreateItemsSetupWithProductionAndTracking(var Item: Record Item; var Item2: Record Item; var ProductionOrder: Record "Production Order"; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateItemSetupWithLotTracking(Item, Item2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '', LocationCode, true);  // Using Tracking TRUE.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationCode, '');
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateBomItemsWithReorderingPolicy(var ParentItem: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Parent and Child Item.
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ChildItem);
        UpdateItemParametersForPlanningWorksheet(
          ParentItem, ParentItem."Manufacturing Policy"::"Make-to-Order",
          ParentItem."Reordering Policy"::Order, ParentItem."Replenishment System"::"Prod. Order");
        UpdateItemParametersForPlanningWorksheet(
          ChildItem, ChildItem."Manufacturing Policy"::"Make-to-Order",
          ChildItem."Reordering Policy"::Order, ChildItem."Replenishment System"::"Prod. Order");

        // Create Production BOM and attach Production BOM to Parent Item.
        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateMakeToOrderProdItemWithComponentsTakenFromOpenShopFloorBin(var ItemNo: array[3] of Code[20]; var LocationCode: Code[10]; var ProdBinCode: Code[20]; var OpenShopFloorBin: Code[20])
    var
        Location: Record Location;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
        BinCode: array[5] of Code[20];
    begin
        CreateLocationWithBins(Location, BinCode, 2);
        LocationCode := Location.Code;
        ProdBinCode := BinCode[1];
        OpenShopFloorBin := BinCode[2];
        Location.Validate("From-Production Bin Code", ProdBinCode);
        Location.Modify(true);

        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Location Code", LocationCode);
        WorkCenter.Validate("Open Shop Floor Bin Code", OpenShopFloorBin);
        WorkCenter.Modify(true);

        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateRoutingWithRoutingLink(RoutingHeader, WorkCenter."No.", RoutingLink.Code);

        CreateProductionChainOfItems(ItemNo, 3);
        UpdateRoutingOnItem(ItemNo[3], RoutingHeader."No.");
        UpdateRoutingLinkOnProductionBOMLine(ItemNo[3], ItemNo[2], RoutingLink.Code);
    end;

    local procedure CreateAndPostOutputJournalWithItemTracking(ProductionOrderNo: Code[20]; Tracking: Boolean; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ItemJournalLine, ProductionOrderNo);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Assign Lot No.
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20]; OutputQty: Decimal; SetupTime: Decimal; RunTime: Decimal; StopTime: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQty);
        ItemJournalLine.Validate("Setup Time", SetupTime);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Validate("Stop Time", StopTime);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20]; OutputQty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQty);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostConsumptionJournalWithItemTracking(ProductionOrderNo: Code[20]; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Select Tracking Entries TRUE.
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExlpodeRouting(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Assign Lot No TRUE.
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.ShowReservation();  // Invokes ReservationHandler.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, '');
        LibrarySales.ReleaseSalesDocument(SalesHeader);
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

    local procedure CreateRoutingAndUpdateItem(var Item: Record Item): Code[10]
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.FindFirst();
        CreateWorkCenter(WorkCenter);
        CreateRoutingWithRoutingLink(RoutingHeader, WorkCenter."No.", RoutingLink.Code);

        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
        exit(RoutingLink.Code);
    end;

    local procedure CreateRoutingWithRoutingLink(var RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; RoutingLinkCode: Code[10])
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenterNo);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingWithSetupWaitAndMoveTime(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(5)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(10));
        RoutingLine.Validate("Wait Time", LibraryRandom.RandInt(10));
        RoutingLine.Validate("Move Time", LibraryRandom.RandInt(10));
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CalculateInventoryValue(var Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectItemJournalLine(ItemJournalLine, RevaluationItemJournalTemplate.Name, RevaluationItemJournalBatch.Name);
        Item.SetRange("No.", Item."No.");
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."),
          "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure CreateAndRegisterPickWithProductionOrderSetup(var ProductionOrder: Record "Production Order"; Location: Record Location; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemNo, Quantity, Location.Code, Location."To-Production Bin Code");
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        UpdateBinCodeOnWarehouseActivityLine(ProductionOrder."No.");
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);
    end;

    local procedure CreateWarehouseJournalLine(var Item: Record Item; var WarehouseJournalLine: Record "Warehouse Journal Line"; Location: Record Location; Quantity: Decimal)
    var
        Bin: Record Bin;
    begin
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code",
          Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
    end;

    local procedure CreateAndPostPurchaseOrderWithLocationAndBin(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithSourceTypeFamily(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Family, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateFamily(var Family: Record Family; ItemNo: Code[20]; ItemNo2: Code[20]; Quantity: Decimal)
    var
        FamilyLine: Record "Family Line";
    begin
        LibraryManufacturing.CreateFamily(Family);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo, Quantity);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo2, Quantity);
    end;

    local procedure CreateItemHierarchyForFamily(var ParentItem: Record Item; var ParentItem2: Record Item; var ChildItem: Record Item; var ChildItem2: Record Item)
    begin
        CreateItemsSetup(ParentItem, ChildItem);
        CreateItemsSetup(ParentItem2, ChildItem2);
        UpdateUnitCostOnItem(ChildItem);
        UpdateUnitCostOnItem(ChildItem2);
        CreateAndPostItemJournalLine(ChildItem."No.", LibraryRandom.RandInt(100) + 100, '', '', false);  // Use Tracking FALSE.
        CreateAndPostItemJournalLine(ChildItem2."No.", LibraryRandom.RandInt(100) + 100, '', '', false);  // Use Tracking FALSE.
    end;

    local procedure CalculateRemainingQuantityOnProductionOrderComponent(ProductionOrderNo: Code[20]) TotalRemainingQuantity: Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        repeat
            TotalRemainingQuantity += ProdOrderComponent."Remaining Quantity";
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure CreateProdBOMSetupMultipleComponents(var Item: Record Item; var Item2: Record Item; var Item3: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Items.
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateCertifiedProductionBOMWithMultipleItems(ProductionBOMHeader, Item2, Item3);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateCertifiedProductionBOMWithMultipleItems(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; Item2: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);  // Value important.
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", 1);  // Value important.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateDemandForCalculatePlanAndCarryOutAction(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity);

        // Calculate Regenerative Plan on WORKDATE. Accept and Carry Out Action Message.
        Item.Get(ItemNo);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        AcceptAndCarryOutActionMessage(ItemNo);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItemParametersForPlanning(Item);
    end;

    local procedure ChangeStatusFromFirmPlannedToReleased(ItemNo: Code[20]) ProductionOrderNo: Code[20]
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProductionOrder.Get(ProdOrderLine.Status::"Firm Planned", ProdOrderLine."Prod. Order No.");

        // Change Production Order Status from Firm Planned to Released.
        ProductionOrderNo :=
          LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");
    end;

    local procedure CreatePickFromReleasedProductionOrder(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
    end;

    local procedure CreateLotForLotItemSetupWithInventoryOnLocation(var Item: Record Item; var ChildItem: Record Item; Location: Record Location; Quantity: Decimal)
    begin
        CreateItemsSetup(Item, ChildItem);
        UpdateItemParametersForPlanning(Item);
        UpdateInventoryWithWhseItemJournal(ChildItem, Location, Quantity);
    end;

    local procedure CreateMaximumQtyItem(var Item: Record Item; MaximumInventory: Decimal)
    begin
        CreateManufacturingItem(Item, Item."Reordering Policy"::"Maximum Qty.", Item."Replenishment System"::Purchase);
        Item.Validate("Reorder Point", LibraryRandom.RandDec(10, 2) + 10);  // Large Random Value required for test.
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Minimum Order Quantity", LibraryRandom.RandDec(10, 2));  // Minimum Order Quantity less than Reorder Point Quantity.
        Item.Validate("Maximum Order Quantity", MaximumInventory + LibraryRandom.RandDec(100, 2));  // Maximum Order Quantity more than Maximum Inventory.
        Item.Modify(true);
    end;

    local procedure CreateAndPostSalesOrderWithUpdatedQuantityToShip(var Item: Record Item; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity, LocationCode);
        UpdateQuantityToShipOnSalesLine(SalesLine, Item."Maximum Inventory");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship only.
    end;

    local procedure AcceptActionMessage(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        FindRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure AcceptAndCarryOutActionMessageForRequisitionWorksheet(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var Item: Record Item)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, WorkDate(), WorkDate());
    end;

    local procedure CreateManufacturingItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItemsSetup(var Item: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateManufacturingItem(ChildItem, ChildItem."Reordering Policy"::"Lot-for-Lot", ChildItem."Replenishment System"::Purchase);
        CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem);
        CreateManufacturingItem(Item, Item."Reordering Policy"::"Lot-for-Lot", Item."Replenishment System"::Purchase);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name"; Type: Enum "Req. Worksheet Template Type")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, Type);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateRleasedProdOrderWithItemTracking(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; ItemTrackingMode: Option)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ItemNo, LibraryRandom.RandInt(10), '', '');

        // Assign Item Tracking On Production Order Line
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode);
        ProdOrderLine.OpenItemTrackingLines();
    end;

    local procedure CreateReleasedProdOrderWithManuallyScheduledRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreateRoutingWithSetupWaitAndMoveTime(RoutingHeader);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.Validate("Schedule Manually", true);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure CreateAndPostOutputJnlWithUpdateQtyAndItemTracking(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);

        // Update the quantity on Item Tracking Line of Output Journal
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Update Quantity");
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);

        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostOutputJnlForProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; RoutingNo: Code[20]; OperationNo: Code[10]; RunTime: Decimal; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProdOrderLine."Prod. Order No.");
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        ItemJournalLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJournalLine.Validate("Item No.", ProdOrderLine."Item No.");
        ItemJournalLine.Validate("Routing No.", RoutingNo);
        ItemJournalLine.Validate("Operation No.", OperationNo);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Validate("Output Quantity", Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateTransferOrderWithQtyAndShipmentDate(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; InTransitLocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal; ShipmentDate: Date)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocationCode);
        TransferHeader.Validate("Posting Date", ShipmentDate);
        TransferHeader.Validate("Shipment Date", ShipmentDate);
        TransferHeader.Modify(true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
    end;

    local procedure CreateStockkkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10]; ManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::"Prod. Order");
        StockkeepingUnit.Validate("Manufacturing Policy", ManufacturingPolicy);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CalcRegenPlanForPlanningWorksheetPage(var PlanningWorksheet: TestPage "Planning Worksheet"; ItemNo: Code[20]; ItemNo2: Code[20]; Accept: Boolean)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ProductionOrderType: Option " ",Planned,"Firm Planned","Firm Planned & Print";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryVariableStorage.Enqueue(ItemNo);  // Required for CalculatePlanPlanWkshRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo2);  // Required for CalculatePlanPlanWkshRequestPageHandler.
        Commit();  // Required for Test.
        OpenPlanningWorksheetPage(PlanningWorksheet, RequisitionWkshName.Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.

        if Accept then begin
            // Accept Action Message and Carry Out Action Message
            LibraryVariableStorage.Enqueue(ProductionOrderType::"Firm Planned"); // Required for CarryOutActionMessageHandler.
            AcceptActionMessage(RequisitionLine, ItemNo);
            AcceptActionMessage(RequisitionLine, ItemNo2);
            Commit(); // Required for Test.
            PlanningWorksheet.CarryOutActionMessage.Invoke(); // Invoke Carry Out Action Message handler.
        end;
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure CreateOutputItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::Output);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name, ItemJournalLine."Entry Type"::Output, ItemNo, Quantity);
    end;

    local procedure DeleteProductionOrderComponent(ProductionOrderNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        ProdOrderComponent.Delete(true);
    end;

    local procedure ExplodeRoutingForProductionOrder(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20])
    begin
        CreateOutputItemJournalLine(ItemJournalLine, '', 0);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderNo);
        ItemJournalLine.Modify(true);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProdOrderComponentByItem(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProdOrderComponentByOrderNoAndItem(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.");
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
    end;

    local procedure FindProductionOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.FindFirst();
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

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindRegisteredWarehouseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindSet();
    end;

    local procedure FilterFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        FilterRequisitionLine(RequisitionLine, No);
        RequisitionLine.FindFirst();
    end;

    local procedure FindPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRoutingLine.FindFirst();
    end;

    local procedure FindPlanningComponent(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    begin
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningComponent.SetRange("Item No.", ItemNo);
        PlanningComponent.FindFirst();
    end;

    local procedure FindFirstProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindLastProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindLast();
    end;

    local procedure ValueEntryCalcSumsCostAmountActual(var ValueEntry: Record "Value Entry"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.CalcSums("Cost Amount (Actual)");
    end;

    local procedure FilterRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
    end;

    local procedure OpenPlanningWorksheetPage(var PlanningWorksheet: TestPage "Planning Worksheet"; Name: Code[10])
    begin
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(Name);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo, SourceDocument, ActionType);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure SelectItemTrackingForProdOrderComponents(ItemNo: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenEdit();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries"); // Enqueue ItemTrackingMode for ItemTrackingPageHandler.
        ProdOrderComponents.ItemTrackingLines.Invoke();
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure UpdateFlushingMethodOnProdComp(ProductionOrderNo: Code[20]; FlushingMethod: Enum "Flushing Method")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        ProdOrderComponent.Validate("Flushing Method", FlushingMethod);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateQuantityAndLotNoOnWarehouseActivityLine(ItemNo: Code[20]; ProductionOrderNo: Code[20]; ActionType: Enum "Warehouse Action Type"; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", ActionType);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate(Quantity, Quantity);
            WarehouseActivityLine.Validate("Lot No.", ItemLedgerEntry."Lot No.");
            WarehouseActivityLine.Modify(true);
            ItemLedgerEntry.Next();
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateLocationSetup(var Location: Record Location; NewAlwaysCreatePickLine: Boolean) AlwaysCreatePickLine: Boolean
    begin
        AlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateInventoryWithWhseItemJournal(var Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Register the Warehouse Item Journal Lines.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateWarehouseJournalLine(Item, WarehouseJournalLine, Location, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // Calculate Warehouse adjustment and post Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');  // Value required to avoid the Document No mismatch.
    end;

    local procedure UpdateBinCodeOnWarehouseActivityLine(SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Bin: Record Bin;
    begin
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        FindWarehouseActivityLine(
          WarehouseActivityLine, SourceNo, WarehouseActivityLine."Source Document"::"Prod. Consumption",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateUnitCostOnItem(var Item: Record Item)
    begin
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
    end;

    local procedure UpdateRoutingOnItem(ItemNo: Code[20]; RoutingNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateRoutingLineSendAheadQty(RoutingNo: Code[20]; SendAheadQuantity: Decimal)
    var
        RoutingLine: Record "Routing Line";
        RoutingHeader: Record "Routing Header";
    begin
        RoutingHeader.Get(RoutingNo);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindFirst();
        RoutingLine.Validate("Send-Ahead Quantity", SendAheadQuantity);
        RoutingLine.Modify(true);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure UpdateRoutingLinkOnProductionBOMLine(ProdItemNo: Code[20]; CompItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        Item.Get(ProdItemNo);
        ProductionBOMHeader.Get(Item."Production BOM No.");
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange("No.", CompItemNo);
        ProductionBOMLine.FindFirst();
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure UpdateSetupTimeInProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; NewSetupTime: Decimal)
    begin
        ProdOrderRoutingLine.Validate("Setup Time", NewSetupTime);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateItemParametersForPlanning(var Item: Record Item)
    var
        Vendor: Record Vendor;
    begin
        Item.Find();  // Used to avoid the Transaction error.
        LibraryPurchase.CreateVendor(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure UpdateItemParametersForPlanningWorksheet(var Item: Record Item; ManufacturingPolicy: Enum "Manufacturing Policy"; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityOnRequisitionLine(var RequisitionLine: Record "Requisition Line"; Quantity: Decimal)
    begin
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Modify(true);
    end;

    local procedure UpdateOrderTrackingPolicyOnItem(var Item: Record Item; OrderTrackingPolicy: Enum "Order Tracking Policy")
    begin
        LibraryVariableStorage.Enqueue(EntriesNotAffectedMsg);  // Enqueue variable for use in MessageHandler.
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtytoShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtytoShip);
        SalesLine.Modify(true);
    end;

    local procedure UpdateQuantityOnProdOrderLine(ItemNo: Code[20]; Qty: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.Validate("Quantity (Base)", Qty);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateUOMOnProdBOMLine(ProdBOMNo: Code[20]; CompItemNo: Code[20]; QtyPerUoM: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CompItemNo, QtyPerUoM);
        ProductionBOMHeader.Get(ProdBOMNo);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange("No.", CompItemNo);
        ProductionBOMLine.FindFirst();
        ProductionBOMLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure UpdateUOMOnProdBOMLineByItemNo(ProdItemNo: Code[20]; CompItemNo: Code[20]; QtyPerUoM: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ProdItemNo);
        UpdateUOMOnProdBOMLine(Item."Production BOM No.", CompItemNo, QtyPerUoM);
    end;

    local procedure VerifyItemLedgerEntryCostAmountActual(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; CostAmountActual: Decimal; LocationCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        Assert.AreNearlyEqual(
          CostAmountActual, ItemLedgerEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldValidationErr, ItemLedgerEntry.FieldCaption("Cost Amount (Actual)"), CostAmountActual));
        ItemLedgerEntry.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyProdOrderComponent(ProdOrderNo: Code[20]; Status: Enum "Production Order Status"; ItemNo: Code[20]; ReservedQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField(Status, Status);
        ProdOrderComponent.TestField("Item No.", ItemNo);
        ProdOrderComponent.CalcFields("Reserved Quantity");
        ProdOrderComponent.TestField("Reserved Quantity", ReservedQuantity);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; Tracking: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify the Item Ledger Entry has correct Quantity and has Tracking.
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        repeat
            ItemLedgerEntry.TestField(Quantity, Quantity);
            if Tracking then
                ItemLedgerEntry.TestField("Lot No.");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyProductionOrder(ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; Quantity: Decimal; DueDate: Date)
    begin
        ProductionOrder.Get(Status, ProductionOrder."No.");
        ProductionOrder.TestField(Quantity, Quantity);
        ProductionOrder.TestField("Due Date", DueDate);
    end;

    local procedure VerifyReservationQtyOnSalesLine(DocumentNo: Code[20]; ReservedQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", ReservedQuantity);
    end;

    local procedure VerifyWarehouseActivityLine(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ItemNo: Code[20]; Quantity: Decimal; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument, ActionType);
        repeat
            WarehouseActivityLine.TestField("Item No.", ItemNo);
            WarehouseActivityLine.TestField(Quantity, Quantity);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyPostedInventoryPickLine(SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.FindFirst();
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField("Bin Code", BinCode);
        PostedInvtPickLine.TestField(Quantity, Quantity);
        PostedInvtPickLine.TestField("Location Code", LocationCode);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
        PostedInvtPickLine.TestField("Lot No.", ItemLedgerEntry."Lot No.");
    end;

    local procedure VerifyRegisteredWarehouseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; ActionType: Enum "Warehouse Action Type")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWarehouseActivityLine(RegisteredWhseActivityLine, SourceDocument, SourceNo, ActionType);
        RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRevaluationJournalLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Unit Cost (Revalued)", Item."Last Direct Cost");
        ItemJournalLine.TestField("Inventory Value (Revalued)", Round(Quantity * Item."Last Direct Cost"));
    end;

    local procedure VerifyCostAmountActualOnFinishedProductionOrderStatisticsPage(ProductionOrderNo: Code[20]; ActualCost: Decimal)
    var
        FinishedProductionOrder: TestPage "Finished Production Order";
        ProductionOrderStatistics: TestPage "Production Order Statistics";
    begin
        FinishedProductionOrder.OpenEdit();
        FinishedProductionOrder.FILTER.SetFilter("No.", ProductionOrderNo);
        ProductionOrderStatistics.Trap();
        FinishedProductionOrder.Statistics.Invoke();
        ProductionOrderStatistics.MaterialCost_ActualCost.AssertEquals(ActualCost);
    end;

    local procedure VerifyRemainingQuantityOnProdOrderComponents(ProdOrderNo: Code[20]; Status: Enum "Production Order Status"; ItemNo: Code[20]; RemainingQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        TotalRemainingQuantity: Decimal;
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProdOrderNo);
        ProdOrderComponent.TestField(Status, Status);
        ProdOrderComponent.TestField("Item No.", ItemNo);
        TotalRemainingQuantity := CalculateRemainingQuantityOnProductionOrderComponent(ProdOrderNo);
        Assert.AreEqual(TotalRemainingQuantity, RemainingQuantity, FieldValidationErr);
    end;

    local procedure VerifyRoutingOnAllocatedCapacity(ProductionOrder: Record "Production Order")
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderCapacityNeed.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderCapacityNeed.FindSet();
        repeat
            ProdOrderCapacityNeed.TestField("Routing No.", ProductionOrder."Routing No.");
            ProdOrderCapacityNeed.TestField("Work Center No.", ProdOrderRoutingLine."Work Center No.");
        until ProdOrderCapacityNeed.Next() = 0;
    end;

    local procedure VerifyOutputOnCapLedgerEntries(ProdOrderNo: Code[20]; OperationNo: Code[10]; ExpectedOutputQty: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        CapacityLedgerEntry.SetRange("Operation No.", OperationNo);
        CapacityLedgerEntry.CalcSums("Output Quantity");
        CapacityLedgerEntry.TestField("Output Quantity", ExpectedOutputQty);
    end;

    local procedure VerifyProductionOrderRoutingLine(ProductionOrderNo: Code[20]; RoutingNo: Code[20]; SendAheadQuantity: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo);
        ProdOrderRoutingLine.TestField("Routing No.", RoutingNo);
        ProdOrderRoutingLine.TestField("Send-Ahead Quantity", SendAheadQuantity);
    end;

    local procedure VerifyInputQuantityOnPlanningRoutingLine(RequisitionLine: Record "Requisition Line")
    var
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningRoutingLine.TestField("Input Quantity", RequisitionLine.Quantity);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; Quantity: Decimal; ReservationStatus: Enum "Reservation Status"; Tracking: Boolean; Positive: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange(Positive, Positive);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.TestField(Quantity, Quantity);
            ReservationEntry.TestField("Reservation Status", ReservationStatus);
            if Tracking then
                ReservationEntry.TestField("Lot No.");
        until ReservationEntry.Next() = 0;
    end;

    local procedure VerifyLocationAndQuantityOnPurchaseLine(No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField("Location Code", LocationCode);
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRequisitionLine(No: Code[20]; ActionMessage: Enum "Action Message Type"; Quantity: Decimal; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, No);
        RequisitionLine.TestField("Location Code", LocationCode);
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Action Message", ActionMessage);
    end;

    local procedure VerifyOrderTrackingForProductionOrder(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
        OrderTracking: Page "Order Tracking";
        OrderTracking2: TestPage "Order Tracking";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        OrderTracking.SetVariantRec(
            ProdOrderLine, ProdOrderLine."Item No.", ProdOrderLine."Remaining Qty. (Base)",
            ProdOrderLine."Starting Date", ProdOrderLine."Ending Date");
        OrderTracking2.Trap();
        OrderTracking.Run();
        OrderTracking2."Item No.".AssertEquals(ItemNo);
        OrderTracking2.Quantity.AssertEquals(Quantity);
    end;

    local procedure VerifyProdOrderLine(ItemNo: Code[20]; Status: Enum "Production Order Status"; Quantity: Decimal; FinishedQuantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField(Status, Status);
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Finished Quantity", FinishedQuantity);
    end;

    local procedure VerifyProdOrderLineWithLocationAndBin(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField("Location Code", LocationCode);
        ProdOrderLine.TestField("Bin Code", BinCode);
    end;

    local procedure VerifyOneProdOrderLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        Assert.RecordCount(ProdOrderLine, 1);
        ProdOrderLine.TestField(Quantity, Quantity);
    end;

    local procedure PostPositiveAdjustmentWithLotNo(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; PositiveAdjustmentQuantity: Decimal; LotNo: Code[20]; ExpirationDate: Date)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, PositiveAdjustmentQuantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Manual Lot No."); // Enqueue value for ItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PositiveAdjustmentQuantity);
        ItemJournalLine.OpenItemTrackingLines(false);

        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalLine."Journal Batch Name");
        ReservationEntry.FindFirst();
        ReservationEntry.Validate("Expiration Date", ExpirationDate);
        ReservationEntry.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, Type);
        WarehouseActivityHeader.Get(Type, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure RunRequisitionCarryOutReportProdOrder(RequisitionLine: Record "Requisition Line")
    var
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        ProdOrderChoice: Enum "Planning Create Prod. Order";
    begin
        CarryOutActionMsgPlan.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgPlan.InitializeRequest(ProdOrderChoice::"Firm Planned".AsInteger(), 0, 0, 0);
        CarryOutActionMsgPlan.UseRequestPage(false);
        CarryOutActionMsgPlan.RunModal();
    end;

    local procedure UpdateProductionBomAndRoutingOnItem(var Item: Record Item; ProductionBOMNo: Code[20]; RoutingNo: Code[20])
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateAndCertifiyRouting(var RoutingHeader: Record "Routing Header")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.FindFirst();
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(10)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateComponentItemWithItemUnitOfMeasureCode(var CompItem: Record Item; var CompItemUnitOfMeasure: array[2] of Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(CompItemUnitOfMeasure[1], CompItem."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryInventory.CreateItemUnitOfMeasureCode(CompItemUnitOfMeasure[2], CompItem."No.", LibraryRandom.RandDecInDecimalRange(2.67, 2.67, 2));
    end;

    local procedure CreateProductionItemWithItemUnitOfMeasureCode(var ProdItem: Record Item; var ProdItemUnitOfMeasure: array[2] of Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(ProdItemUnitOfMeasure[1], ProdItem."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryInventory.CreateItemUnitOfMeasureCode(ProdItemUnitOfMeasure[2], ProdItem."No.", LibraryRandom.RandDecInDecimalRange(12.4, 12.4, 1));
    end;

    local procedure FindAndUpdateProdOrderComponentWithCalcFormula(
        var ProductionOrder: Record "Production Order";
        var ProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        RoutingLink: Record "Routing Link";
        Length: Decimal;
        Width: Decimal;
        Depth: Decimal;
        CalculationFormula: Enum "Quantity Calculation Formula")
    begin
        FindProdOrderComponentByOrderNoAndItem(ProdOrderComponent, ProductionOrder."No.", Item."No.");
        ProdOrderComponent.Validate(Length, Length);
        ProdOrderComponent.Validate(Width, Width);
        ProdOrderComponent.Validate(Depth, Depth);
        ProdOrderComponent.Validate("Calculation Formula", CalculationFormula);
        ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::Backward);
        ProdOrderComponent.Validate("Routing Link Code", RoutingLink.Code);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOMwithRoutingLinkCode(
        var ProductionBOMHeader: Record "Production BOM Header";
        var ProductionBOMLine: Record "Production BOM Line";
        ProdItem: Record Item;
        CompItem: Record Item;
        CompItem2: Record Item;
        RoutingLink: Record "Routing Link")
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader,
            ProductionBOMLine,
            '',
            ProductionBOMLine.Type::Item,
            CompItem."No.",
            LibraryRandom.RandIntInRange(2, 2));

        ProductionBOMLine.Validate("Unit of Measure Code", CompItem."Base Unit of Measure");
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);

        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader,
            ProductionBOMLine,
            '',
            ProductionBOMLine.Type::Item,
            CompItem2."No.",
            LibraryRandom.RandIntInRange(2, 2));

        ProductionBOMLine.Validate("Unit of Measure Code", CompItem2."Base Unit of Measure");
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);

        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateAndCertifyRoutingWithRoutingLinkCode(
        var RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkcenterNo: Code[20];
        RoutingLinkCode: Code[10])
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader,
            RoutingLine,
            '',
            Format(LibraryRandom.RandIntInRange(10, 10)),
            RoutingLine.Type::"Work Center",
            WorkCenterNo);

        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);

        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateConsumptionJournalLine(
        var ItemJournalLine: Record "Item Journal Line";
        ProdOrderNo: Code[20];
        ItemNo: Code[20];
        Qty: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        InitItemJournalBatch(ItemJnlBatch, ItemJnlBatch."Template Type"::Consumption);
        ItemJournalLine.Init();
        ItemJournalLine."Entry Type" := ItemJournalLine."Entry Type"::Consumption;

        ItemJnlTemplate.Get(ItemJnlBatch."Journal Template Name");
        LibraryInventory.CreateItemJnlLineWithNoItem(
            ItemJournalLine,
            ItemJnlBatch,
            ItemJnlTemplate.Name,
            ItemJnlBatch.Name,
            ItemJournalLine."Entry Type"::Consumption);

        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderNo);
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Modify(true);
    end;

    local procedure InitItemJournalBatch(var ItemJnlBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJnlBatch, TemplateType, ItemJnlTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJnlTemplate, ItemJnlBatch);
    end;

    local procedure CreateItemWithUOM(
        var Item: Record Item;
        var UnitOfMeasure: Record "Unit of Measure";
        var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);

        LibraryInventory.CreateItemUnitOfMeasure(
            ItemUnitOfMeasure,
            Item."No.",
            UnitOfMeasure.Code,
            LibraryRandom.RandInt(0));

        Item.Validate("Base Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateLocationWithProdConsumpWhseHandling(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Modify(true);
    end;

    local procedure CreateConsumptionJournal(ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateCompItemWithItemUnitOfMeasureCode(
        var CompItem: Record Item;
        var CompItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        Qty: Decimal)
    begin
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(CompItemUnitOfMeasure[1], CompItem."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryInventory.CreateItemUnitOfMeasureCode(CompItemUnitOfMeasure[2], CompItem."No.", Qty);
    end;

    local procedure CreateProdItemWithItemUnitOfMeasureCode(
        var ProdItem: Record Item;
        var ProdItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        Qty: Decimal)
    begin
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(ProdItemUnitOfMeasure[1], ProdItem."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryInventory.CreateItemUnitOfMeasureCode(ProdItemUnitOfMeasure[2], ProdItem."No.", Qty);
    end;

    local procedure UpdateQtytoHandleInWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandle: Decimal)
    begin
        WarehouseActivityLine.SetLoadFields("Action Type", "Qty. to Handle");
        WarehouseActivityLine.SetRange("Action Type");
        WarehouseActivityLine.FindFirst();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify();
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure CreatePutAwayFromPutAwayWorksheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20]; QuantityToHandle: Decimal; SortActivity: Enum "Whse. Activity Sorting Method"; BreakbulkFilter: Boolean)
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

        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, SortActivity, false, false, BreakbulkFilter);
    end;

    local procedure CreatePutawayFromPutawayWorksheet(Location: Record Location)
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        GetWhsePutAwayDoc: Codeunit "Get Source Doc. Inbound";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::"Put-away");
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        GetWhsePutAwayDoc.GetSingleWhsePutAwayDoc(WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Location.Code);
        WhseWorksheetLine.SortWhseWkshLines(WhseWorksheetTemplate.Name, WhseWorksheetName.Name, Location.Code, "Whse. Activity Sorting Method"::None);
    end;

    local procedure CreateAndPostProductionJournal(ProductionOrder: Record "Production Order"; ProdOrderLineNo: Integer)
    var
        ReleaseProdOrder: TestPage "Released Production Order";
    begin
        ReleaseProdOrder.OpenView();
        ReleaseProdOrder.GoToRecord(ProductionOrder);
        ReleaseProdOrder.ProdOrderLines.Filter.SetFilter("Line No.", Format(ProdOrderLineNo));
        ReleaseProdOrder.ProdOrderLines.ProductionJournal.Invoke();
    end;

    local procedure FindPickZone(LocationCode: Code[10]): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();

        exit(Zone.Code);
    end;

    local procedure CreateWhseWorksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; Type: Enum "Warehouse Worksheet Template Type")
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, Type);
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure CreateWarehouseItemJournalLine(LocationCode: Code[10]; BinCode1: Code[20]; BinCode2: Code[20]; ItemNo: Code[20])
    var
        WarehouseJnlBatch: Record "Warehouse Journal Batch";
        WarehouseJnlLine: array[2] of Record "Warehouse Journal Line";
    begin
        CreateWarehouseJournalBatch(WarehouseJnlBatch, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJnlLine[1], WarehouseJnlBatch."Journal Template Name", WarehouseJnlBatch.Name, LocationCode, '', BinCode1,
            WarehouseJnlLine[1]."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandIntInRange(100, 100));
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJnlLine[2], WarehouseJnlBatch."Journal Template Name", WarehouseJnlBatch.Name, LocationCode, '', BinCode2,
            WarehouseJnlLine[2]."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandIntInRange(100, 100));

        LibraryWarehouse.PostWhseJournalLine(WarehouseJnlBatch."Journal Template Name", WarehouseJnlBatch.Name, LocationCode);
    end;

    local procedure CreateWarehouseJournalBatch(var WarehouseJnlBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJnlTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJnlTemplate, WarehouseJnlTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJnlBatch, WarehouseJnlTemplate.Name, LocationCode);
    end;

    local procedure CalculateWarehouseAdjustmentAndPostItemJournalLine(var Item: Record Item)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        ItemJnlBatch.Validate("No. Series", LibraryERM.CreateNoSeriesCode());
        ItemJnlBatch.Modify(true);

        LibraryInventory.ClearItemJournal(ItemJnlTemplate, ItemJnlBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJnlBatch);
        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10])
    var
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLineWithUnitCost(ItemJnlBatch, ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode, LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name);
    end;

    local procedure CreateItemJournalLineWithUnitCost(var ItemJnlBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; UnitCost: Decimal)
    begin
        ItemJournalSetup(ItemJnlBatch);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJnlBatch."Journal Template Name", ItemJnlBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure ItemJournalSetup(var ItemJnlBatch: Record "Item Journal Batch")
    var
        ItemJnlTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.ItemJournalSetup(ItemJnlTemplate, ItemJnlBatch);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateLotTrackedItemWithAllowWhseOverpick(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Allow Whse. Overpick", true);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLineWithManualLot(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; LotNo: Code[50]; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Manual Lot No.");
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(Quantity);  // Assign Quantity.
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateProductionBOM(Item: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(3, 3));

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateItemWithProductionBOM(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);

        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure FindAndUpdateProdOrderComponent(ItemNo: Code[20]; LocationCode: Code[20]; BinCode: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();

        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Bin Code", BinCode);
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);
    end;

    local procedure OpenReleasedProdOrderPageAndCreateWarehousePick(ProductionOrder: Record "Production Order")
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.GoToRecord(ProductionOrder);
        ReleasedProductionOrder."Create Warehouse Pick".Invoke(); //Create Warehouse Pick
        Commit();
        ReleasedProductionOrder.Close();
    end;

    local procedure CreateProductionBOMWithQtyPer(Item: Record Item; var ProductionBOMHeader: Record "Production BOM Header"; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QtyPer);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateLotTrackedItemWithUseExpirationDate(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure CreateBin(var Bin: array[5] of Record Bin; LocationCode: Code[10])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(Bin) do
            LibraryWarehouse.CreateBin(Bin[i], LocationCode, Bin[i].Code, '', '');
    end;

    local procedure CreateAndPostItemJournalLineWithManualLotExpiration(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; LotNo: Code[50]; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode);
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Manual Lot No.");
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(Quantity);// Assign Quantity.
            LibraryVariableStorage.Enqueue(CalcDate('<+1Y>', WorkDate()));
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure VerifyProductionOrderLines(MainItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Item No.", MainItemNo);
        if ProdOrderLine.FindSet() then;
        Assert.AreEqual(2, ProdOrderLine.Count(), ProdOrderLineErr);
    end;

    local procedure CalculatePlanOnPlanningWorksheet(var ItemRec: Record Item; OrderDate: Date; ToDate: Date; RespectPlanningParameters: Boolean; Regenerative: Boolean)
    var
        TmpItemRec: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        CalculatePlanPlanWksh: Report "Calculate Plan - Plan. Wksh.";
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);  // Find Requisition Worksheet Name to Calculate Plan.
        Commit();
        CalculatePlanPlanWksh.InitializeRequest(OrderDate, ToDate, RespectPlanningParameters, true, true, '', 0D, false);
        CalculatePlanPlanWksh.SetTemplAndWorksheet(RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name, Regenerative);
        if ItemRec.HasFilter then
            TmpItemRec.CopyFilters(ItemRec)
        else begin
            ItemRec.Get(ItemRec."No.");
            TmpItemRec.SetRange("No.", ItemRec."No.");
        end;
        CalculatePlanPlanWksh.SetTableView(TmpItemRec);
        CalculatePlanPlanWksh.UseRequestPage(false);
        CalculatePlanPlanWksh.RunModal();
    end;

    local procedure UpdatePlanningWorkSheetwithVendor(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindSet();
        repeat
            RequisitionLine."Variant Code" := VariantCode;
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateProductionBOMAndCertify(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20]; QuantityPer: Integer; Description: Text[10]; VariantCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        CreateProductionBOM(ProductionBOMHeader, ProductionBOMLine, BaseUnitOfMeasure, Type, No, QuantityPer);
        ProductionBOMHeader.Validate(Description, Description);
        ProductionBOMHeader.Modify(true);
        ProductionBOMLine.Validate("Variant Code", VariantCode);
        ProductionBOMLine.Modify(true);
        UpdateProductionBOMHeaderStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; BaseUnitOfMeasure: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20]; QuantityPer: Integer)
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No, QuantityPer);
    end;

    local procedure UpdateProductionBOMHeaderStatus(var ProductionBOMHeader: Record "Production BOM Header"; Status: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
    end;

    [ModalPageHandler]
    procedure ProductionJournalModalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        LibraryVariableStorage.Enqueue(PostingProductionJournalQst);
        LibraryVariableStorage.Enqueue(PostingProductionJournalTxt);
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);  // Dequeue variable.
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::"Update Quantity":
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                end;
            ItemTrackingMode::"Manual Lot No.":
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Lot No.".SetValue(DequeueVariable);
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemNo: Variant;
        ItemNo2: Variant;
    begin
        CalculatePlanPlanWksh.MPS.SetValue(LibraryVariableStorage.DequeueBoolean());
        // Calculate Regenerative Plan on WORKDATE.
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ItemNo2);
        CalculatePlanPlanWksh.Item.SetFilter("No.", StrSubstNo(ItemFilterLbl, ItemNo, ItemNo2));
        CalculatePlanPlanWksh.MRP.SetValue(true);  // Use MRP True.
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationEntriesModalPageHandler(var ReservationEntries: TestPage "Reservation Entries")
    begin
        LibraryVariableStorage.Enqueue(CancelReservationTxt);
        ReservationEntries.CancelReservation.Invoke();
        ReservationEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateOrderFromSalesModalPageHandler(var CreateOrderFromSales: TestPage "Create Order From Sales")
    begin
        CreateOrderFromSales.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandlerOnlyOutput(var ProductionJournal: TestPage "Production Journal")
    var
        EntryType: Enum "Item Ledger Entry Type";
        FlushingMethod: Enum "Flushing Method";
    begin
        ProductionJournal.FlushingFilter.SetValue(FlushingMethod::Backward);
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", EntryType::Output), '');
        ProductionJournal."Output Quantity".SetValue(LibraryVariableStorage.DequeueInteger());
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.PreviewPosting.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingAssignSerialNoPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::" ":
                begin
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                end;
            ItemTrackingMode::"Select Entries":
                begin
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageOutputEntryHandler(var ProductionJournal: TestPage "Production Journal")
    var
        EntryType: Enum "Item Ledger Entry Type";
    begin
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", EntryType::Output), '');
        ProductionJournal."Output Quantity".SetValue(LibraryVariableStorage.DequeueInteger());
        ProductionJournal.ItemTrackingLines.Invoke();
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandlerPostOnlyOutput(var ProductionJournal: TestPage "Production Journal")
    var
        EntryType: Enum "Item Ledger Entry Type";
        FlushingMethodFilter: Enum "Flushing Method Filter";
    begin
        ProductionJournal.FlushingFilter.SetValue(FlushingMethodFilter::"All Methods");
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", EntryType::Consumption), '');
        ProductionJournal.Quantity.SetValue(0);
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", EntryType::Output), '');
        ProductionJournal."Output Quantity".SetValue(LibraryVariableStorage.DequeueInteger());
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandlerPostOutput(var ProductionJournal: TestPage "Production Journal")
    var
        EntryType: Enum "Item Ledger Entry Type";
    begin
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", EntryType::Output), '');
        ProductionJournal."Output Quantity".SetValue(LibraryVariableStorage.DequeueInteger());
        ProductionJournal.Post.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewPageHandler(var ShowAllEntries: TestPage "G/L Posting Preview")
    begin
        ShowAllEntries.Filter.SetFilter("Table Name", 'Item Ledger Entry');
        LibraryVariableStorage.Enqueue(ShowAllEntries."No. of Records".AsInteger());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerNoText(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerText(Message: Text[1024])
    var
        ExpectedMessage: Text;
    begin
        ExpectedMessage := LibraryVariableStorage.DequeueText();
        if ExpectedMessage = Message then
            Assert.ExpectedMessage(ExpectedMessage, Message)
        else
            Assert.ExpectedMessage(StrSubstNo(ExpectedMessage, LibraryVariableStorage.DequeueText()), Message)
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMessageHandler(var CarryOutActionMsgPlan: TestRequestPage "Carry Out Action Msg. - Plan.")
    var
        ProductionOrderType: Variant;
    begin
        LibraryVariableStorage.Dequeue(ProductionOrderType);
        CarryOutActionMsgPlan.ProductionOrder.SetValue(ProductionOrderType); // Production Order field of page.
        CarryOutActionMsgPlan.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocPageHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentPageHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure AllLevelsStrMenuHandler(StrMenuText: Text; var Choice: Integer; InstructionText: Text)
    begin
        Choice := 2; // All levels
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectMultiItemsModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Next();
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCancelMultiItemsModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Next();
        ItemList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJnlPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Next();
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhsePutAwayDocSelectionPageHandler(var WhsePutAwayDocSelection: TestPage "Put-away Selection")
    var
        SelectWhsePutAway: Boolean;
    begin
        SelectWhsePutAway := LibraryVariableStorage.DequeueBoolean();
        if not SelectWhsePutAway then begin
            WhsePutAwayDocSelection.Filter.SetFilter("Location Code", LibraryVariableStorage.DequeueText());
            WhsePutAwayDocSelection."Document No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end else
            WhsePutAwayDocSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJnlPageHandler2(var ProductionJournal: TestPage "Production Journal")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ProductionJournal.Filter.SetFilter("Entry Type", Format("Item Ledger Entry Type"::Output));
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.SetRange("Item No.", Format(ProductionJournal."Item No."));
        ItemJournalLine.FindFirst();
        ItemJournalLine.Delete(true);

        ProductionJournal.Filter.SetFilter("Entry Type", Format("Item Ledger Entry Type"::Consumption));
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ChangeStatusOnProdOrderPageHandler(var ChangeStatusOnProdOrder: TestPage "Change Status on Prod. Order")
    begin
        ChangeStatusOnProdOrder.FirmPlannedStatus.SetValue("Production Order Status"::Finished);
        ChangeStatusOnProdOrder.PostingDate.SetValue(WorkDate());
        ChangeStatusOnProdOrder."Finish Order without Output".SetValue(true);
        ChangeStatusOnProdOrder.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJnlPageHandler3(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Filter.SetFilter("Entry Type", Format("Item Ledger Entry Type"::Consumption));
        ProductionJournal.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        ProductionJournal.Quantity.AssertEquals(LibraryVariableStorage.DequeueText());
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReturnOverpickedQtyPageHandler(var ReturnOverpickedQuantity: TestPage "Return Overpicked Quantity")
    begin
        ReturnOverpickedQuantity.WorksheetTemplName.SetValue(LibraryVariableStorage.DequeueText());
        ReturnOverpickedQuantity.WorksheetName.SetValue(LibraryVariableStorage.DequeueText());
        ReturnOverpickedQuantity.LocationCode.SetValue(LibraryVariableStorage.DequeueText());
        ReturnOverpickedQuantity.FromBinCode.SetValue(LibraryVariableStorage.DequeueText());
        ReturnOverpickedQuantity.ToBinCode.SetValue(LibraryVariableStorage.DequeueText());
        ReturnOverpickedQuantity.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningPageHandler(var SalesOrderPlanning: TestPage "Sales Order Planning")
    begin
        SalesOrderPlanning.Last();
        SalesOrderPlanning."&Create Prod. Order".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateOrderFromSalesPageHandler(var CreateOrderFromSales: TestPage "Create Order From Sales")
    begin
        CreateOrderFromSales.Status.SetValue("Create Production Order Status"::Released);
        CreateOrderFromSales.OrderType.SetValue("Create Production Order Type"::ProjectOrder);
        CreateOrderFromSales.Yes().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandlerWithExpiration(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);  // Dequeue variable.
        ItemTrackingMode := DequeueVariable;
        case ItemTrackingMode of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::"Update Quantity":
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                end;
            ItemTrackingMode::"Manual Lot No.":
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Lot No.".SetValue(DequeueVariable);
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Quantity (Base)".SetValue(DequeueVariable);
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    ItemTrackingLines."Expiration Date".SetValue(DequeueVariable);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;
}

