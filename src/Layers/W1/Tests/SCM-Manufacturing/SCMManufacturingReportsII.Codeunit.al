// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Journal;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Routing;
using Microsoft.Inventory.Costing;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Reports;
using Microsoft.Inventory.Reports;
using Microsoft.Inventory.Tracking;

codeunit 137310 "SCM Manufacturing Reports -II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Reports] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        NoOfLinesError: Label 'Number of Lines must be the same.';
        FinishProductionOrder: Label 'Do you still want to finish the order?';

    [Test]
    [Scope('OnPrem')]
    procedure CalculateMachineCenterCalendarReport()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Work Center and Machine Center.
        Initialize();
        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(100, 2));  // Random Value for Capacity.

        // Exercise: Run Calculate Machine Center Calendar Report.
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));  // Calculate for the Month.

        // Verify: Verify Calendar Entry for Machine Center.
        VerifyMachineCenterCalendar(MachineCenter, WorkCenter."No.");
    end;

#if not CLEAN26
    [Test]
    [HandlerFunctions('MachineCenterListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MachineCenterListReport()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Work Center and Machine Center.
        Initialize();
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");

        // Exercise: Generate the Machine Center List report.
        Commit();
        MachineCenter.SetRange("No.", MachineCenter."No.");
        REPORT.Run(REPORT::"Machine Center List", true, false, MachineCenter);

        // Verify: Verify Machine Center details on Generated Report.
        VerifyMachineCenterList(MachineCenter);
    end;
#endif

    [Test]
    [HandlerFunctions('ProdOrderRoutingListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingListReport()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Item Setup and Production Order.
        Initialize();
        CreateProdOrderItemsSetup(Item);
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(5));

        // Exercise: Generate the Prod. Order Routing List report.
        FilterOnProductionOrder(ProductionOrder);
        REPORT.Run(REPORT::"Prod. Order - Routing List", true, false, ProductionOrder);

        // Verify: Verify Routing details on Generated Report.
        VerifyProdOrderRoutingList(Item."Routing No.");
    end;

    [Test]
    [HandlerFunctions('ProdOrderListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderListReport()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Item Setup and Production Order.
        Initialize();
        CreateProdOrderItemsSetup(Item);
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(5));

        // Exercise: Generate the Prod. Order List report.
        FilterOnProductionOrder(ProductionOrder);
        REPORT.Run(REPORT::"Prod. Order - List", true, false, ProductionOrder);

        // Verify: Verify Production Order details on Generated Report.
        VerifyProdOrderList(ProductionOrder);
    end;

#if not CLEAN26
    [Test]
    [HandlerFunctions('WorkCenterListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WorkCenterListReport()
    var
        WorkCenter: Record "Work Center";
    begin
        // Setup: Create Work Center.
        Initialize();
        CreateWorkCenter(WorkCenter);

        // Exercise: Run Calculate Work Center List Report.
        Commit();
        WorkCenter.SetRange("No.", WorkCenter."No.");
        REPORT.Run(REPORT::"Work Center List", true, false, WorkCenter);

        // Verify: Verify Work Center details on Generated Report.
        VerifyWorkCenterList(WorkCenter);
    end;
#endif

    [Test]
    [HandlerFunctions('WorkMachineCenterLoadRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WorkMachineCenterLoadReport()
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        // Setup: Create Work Center.
        Initialize();
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");

        // Exercise: Generate the Work Center Load/Bar report.
        Commit();
        WorkCenter.SetRange("No.", WorkCenter."No.");
        LibraryVariableStorage.Enqueue(4);
        Report.Run(Report::"Work/Machine Center Load", true, false, WorkCenter);

        // Verify: Verify Work Center Details on Generated Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyWorkCenterLoadBar(WorkCenter, 4);

        // Verify: Verify Machine Center Details on Generated Report.
        VerifyMachineCenterLoadBar(MachineCenter, 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProductionOrderReportWithNoLevels()
    var
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // Setup.
        Initialize();
        ReplanProductionOrderReport(CalcMethod::"No Levels");  // Calculate Method as No Level.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProductionOrderReportWithOneLevel()
    var
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // Setup.
        Initialize();
        ReplanProductionOrderReport(CalcMethod::"One level");  // Calculate Method as One Level.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProductionOrderReportWithAllLevels()
    var
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // Setup.
        Initialize();
        ReplanProductionOrderReport(CalcMethod::"All levels");  // Calculate Method as All Level.
    end;

    local procedure ReplanProductionOrderReport(CalculateMethod: Option)
    var
        GrandParentItem: Record Item;
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // Setup: Create Item hierarchy setup with GrandParent Item (Replenish: Prod order) -> Parent Item (Replenish: Prod order) -> Child Item (Replenish: Prod order).
        CreateProdOrderItemsSetup(GrandParentItem);   // First Level Hierarchy --> GrandParent - Parent.
        CreateItem(ChildItem, '', '');  // Second Level Hierarchy --> GrandParent - Parent - Child.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        // Update Production BOM on Parent item.
        SelectProductionBOMLine(ProductionBOMLine, GrandParentItem."Production BOM No.");
        ParentItem.Get(ProductionBOMLine."No.");
        UpdateProductionBOMNoOnItem(ParentItem, ProductionBOMHeader."No.");

        // Create Production Order for Grand Parent Item.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, GrandParentItem."No.", LibraryRandom.RandInt(5));

        // Exercise: Run Replan Production Order Report with various Calculate Method Option.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalculateMethod);

        // Verify: Verify Replan Ref. No and Replan Ref. Status on Production Order - No Level.
        VerifyProductionOrderForReplan(ProductionOrder.Status, ProductionOrder."No.", GrandParentItem."No.", ProductionOrder.Quantity);

        // Verify Replan Ref. No. and Replan Ref. Status on New created Production Order for First Level Hierarchy - One Level.
        if CalculateMethod = CalcMethod::"One level" then
            VerifyProductionOrderForReplan(ProductionOrder.Status, ProductionOrder."No.", ParentItem."No.", ProductionOrder.Quantity)
        else  // Verify Replan Ref. No. and Replan Ref. Status on New created Production Orders for Second Level Hierarchy - All Level.
            if CalculateMethod = CalcMethod::"All levels" then begin
                VerifyProductionOrderForReplan(
                  ProductionOrder.Status, ProductionOrder."No.", ParentItem."No.", ProductionOrder.Quantity * ProductionBOMLine."Quantity per");
                SelectProductionBOMLine(ProductionBOMLine, ParentItem."Production BOM No.");
                VerifyProductionOrderForReplan(
                  ProductionOrder.Status, ProductionOrder."No.", ChildItem."No.", ProductionOrder.Quantity * ProductionBOMLine."Quantity per");
            end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProductionOrderReportTwiceOnProductionOrder()
    var
        GrandParentItem: Record Item;
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // Setup: Create Item hierarchy setup with GrandParent Item (Replenish: Prod order) -> Parent Item (Replenish: Prod order) -> Child Item (Replenish: Prod order).
        Initialize();
        CreateProdOrderItemsSetup(GrandParentItem);   // First Level Hierarchy --> GrandParent - Parent.
        CreateItem(ChildItem, '', '');  // Second Level Hierarchy --> GrandParent - Parent - Child.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.");

        // Update Production BOM on Parent item.
        SelectProductionBOMLine(ProductionBOMLine, GrandParentItem."Production BOM No.");
        ParentItem.Get(ProductionBOMLine."No.");
        UpdateProductionBOMNoOnItem(ParentItem, ProductionBOMHeader."No.");

        // Create Production Order for Grand Parent Item and Run Replan Production Order Report.
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, GrandParentItem."No.", LibraryRandom.RandInt(5));
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"One level");
        SelectProductionOrder(ProductionOrder2, ProductionOrder.Status, ParentItem."No.");

        // Exercise: Run Replan Production Order Report again with Calculate Method Option One level on New Created Parent Item Production Order.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder2, Direction::Backward, CalcMethod::"One level");

        // Verify: Verify Replan Ref. No. and Replan Ref. Status on New created Production Orders for Second Level Hierarchy.
        SelectProductionBOMLine(ProductionBOMLine, ParentItem."Production BOM No.");
        VerifyProductionOrderForReplan(
          ProductionOrder.Status, ProductionOrder."No.", ChildItem."No.", ProductionOrder.Quantity * ProductionBOMLine."Quantity per");
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListReportForPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Prod. Order Shortage List Report for the Planned Prod. Order and verify Item No, Needed Quantity and Scheduled Need.
        // Setup.
        Initialize();
        ProdOrderShortageListReport(ProductionOrder.Status::Planned);
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListReportForFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Prod. Order Shortage List Report for the Firm Planned Prod. Order and verify Item No, Needed Quantity and Scheduled Need.
        // Setup.
        Initialize();
        ProdOrderShortageListReport(ProductionOrder.Status::"Firm Planned");
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListReportForReleasedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Prod. Order Shortage List Report for the Released Prod. Order and verify Item No, Needed Quantity and Scheduled Need.
        // Setup.
        Initialize();
        ProdOrderShortageListReport(ProductionOrder.Status::Released);
    end;

    local procedure ProdOrderShortageListReport(Status: Enum "Production Order Status")
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ChildItem: Record Item;
    begin
        // Create Parent and child Items with certified Production BOM and Routing Setup. Update Inventory for the Child Item.
        ChildItem.Get(CreateProdOrderItemsSetup(Item));

        // Create and refresh a Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, Status, Item."No.", LibraryRandom.RandDec(100, 2) + 100);  // Value required for Needed Quantity to exist.

        // Exercise: Run and Save the Production Order Shortage List Report for Parent Item.
        RunAndSaveProdOrderShortageListReport(ProductionOrder, Status, Item."No.");

        // Verify: Verify the Item No, Scheduled Need and Needed Quantity in the report generated for Child Item.
        VerifyProdOrderShortageListReport(ChildItem, ProductionOrder."No.", Status);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListReportForFinishedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ChildItem: Record Item;
    begin
        // Setup: Create Parent and child Items with certified Production BOM and Routing Setup. Update Inventory for the Child Item. Create and refresh a Released Production Order.
        Initialize();
        ChildItem.Get(CreateProdOrderItemsSetup(Item));
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2) + 100);  // Value required for Needed Quantity to exist.
        LibraryVariableStorage.Enqueue(FinishProductionOrder);
        LibraryVariableStorage.Enqueue(FinishProductionOrder);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");  // Change Status from Released to Finished.

        // Exercise: Run and Save the Production Order Shortage List Report for Parent Item.
        RunAndSaveProdOrderShortageListReport(ProductionOrder, ProductionOrder.Status::Finished, Item."No.");

        // Verify: Verify the Item No and Needed Quantity in the report generated for Child Item.
        VerifyProdOrderShortageListReport(ChildItem, ProductionOrder."No.", ProductionOrder.Status::Finished);
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanReportForItem()
    var
        Item: Record Item;
    begin
        // Setup: Create Item. Update Item Inventory.
        Initialize();
        Item.Get(CreateChildItemWithInventory());

        // Exercise: Run and save the Inventory Availability Plan Report.
        Commit();
        RunAndSaveInventoryAvailabilityPlanReport(Item, false);

        // Verify: Verify the Item and Item Inventory exist on the Inventory Availability Plan Report.
        VerifyInvtAvailabilityPlanReport(Item, 'No_Item', Item."No.", 'Inventory_Item');
    end;

    [Test]
    [HandlerFunctions('InventoryAvailabilityPlanRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanReportForItemWithStockKeepingUnit()
    var
        Item: Record Item;
        Location: Record Location;
    begin
        // Setup: Create Item. Update Item Inventory.
        Initialize();
        Item.Get(CreateChildItemWithInventory());
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', LibraryRandom.RandDec(100, 2),
          WorkDate(), LibraryRandom.RandDec(100, 2));
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::Location, false, false);

        // Exercise: Run and save the Inventory Availability Plan Report.
        Commit();
        RunAndSaveInventoryAvailabilityPlanReport(Item, true);

        // Verify: Verify the Item and Item Inventory exist on the Inventory Availability Plan Report.
        VerifyInvtAvailabilityPlanReport(Item, 'LocCode_SKU', Location.Code, 'Inventory1_Item');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ProductionOrderStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderStatisticsWithoutConsumption()
    begin
        // Setup.
        Initialize();
        ProductionOrderStatistics(false);  // Post Consumption Journal as False.
    end;

    [Test]
    [HandlerFunctions('ProductionOrderStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderStatisticsWithConsumption()
    begin
        // Setup.
        Initialize();
        ProductionOrderStatistics(true);  // Post Consumption Journal as True.
    end;

    local procedure ProductionOrderStatistics(PostConsumptionJournal: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Create Production Order Item Setup, Create and Refresh Released Production Order.
        CreateProdOrderItemsSetup(Item);
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(5));

        if PostConsumptionJournal then
            CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // Explode Routing and Post Output Journal.
        ExplodeRoutingAndPostOutputJournal(ProductionOrder."No.");

        // Change Production Order Status Released to Finished.
        LibraryVariableStorage.Enqueue(FinishProductionOrder);  // Enqueue Value for Confirm Handler.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.", ProductionOrder.Status::Finished);

        // Exercise: Generate the Production Order Statistics report.
        GenerateProductionOrderStatisticsReport(ProductionOrder."No.");

        // Verify: Production Order Statistics Report.
        VerifyProductionOrderStatistics(ProductionOrder, ProdOrderComponent."Cost Amount", PostConsumptionJournal);
    end;

    [Test]
    [HandlerFunctions('ExpCostPostingConfirmHandler,ExpCostPostingMsgHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryValuationWIPReportForProductionOrderWithPostOutput()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        InventorySetup: Record "Inventory Setup";
        ValueEntry: Record "Value Entry";
    begin
        // Setup: Update Automatic Cost Setup. Create Item. Create and refresh a Released Production Order.
        Initialize();
        ExecuteUIHandlers();
        UpdateInventorySetup(true, true, InventorySetup."Automatic Cost Adjustment"::Never);
        CreateItem(Item, '', '');
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2));
        ExplodeRoutingAndPostOutputJournal(ProductionOrder."No.");  // Explode Routing and Post Output Journal.

        // Exercise: Run Inventory Valuation WIP Report.
        RunAndSaveInventoryValuationWIPReport(ProductionOrder);

        // Verify: Verify the Source No and Cost Posted to GL field on Inventory Valuation WIP Report.
        FindValueEntryForOutput(ValueEntry, Item."No.");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProductionOrder', ProductionOrder."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('SourceNo_ProductionOrder', ProductionOrder."Source No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('ValueOfOutput',
          -(ValueEntry."Cost Posted to G/L" + ValueEntry."Expected Cost Posted to G/L"));

        // Tear down: Restore the values of Inventory Setup and General Ledger Setup.
        UpdateInventorySetup(InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RFH359248_OneItemMultipleTimesInSingleOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderCompCount: Integer;
    begin
        Initialize();

        // Create Item and Proudction Order
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandDec(100, 2));

        ProdOrderCompCount := 3;
        // Create Production Order Line with a ProdOrderCompCount number of Components
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status::Released, ProductionOrder."No.", Item."No.", '', '', 1);
        CreateSetOfProdOrderComp(ProdOrderLine, Item."No.", LibraryRandom.RandInt(100), ProdOrderCompCount);

        // Change Status from Released to Finished.
        LibraryVariableStorage.Enqueue(FinishProductionOrder);
        LibraryVariableStorage.Enqueue(FinishProductionOrder);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Run and Save the Production Order Shortage List Report.
        Commit();
        RunAndSaveProdOrderShortageListReport(ProductionOrder, ProductionOrder.Status::Finished, Item."No.");

        // Verify Remaining Qty. (Base) for each Component is equal to quantity in ProdOrderComp Table
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
        FilterProdOrderComponent(ProdOrderComponent, ProductionOrder, Item."No.");
        Assert.RecordIsNotEmpty(ProdOrderComponent);
        ProdOrderComponent.CalcSums(Quantity);
        VerifyQtyInProdOrderShortageListReport(
          ProductionOrder."No.", Item."No.", ProdOrderComponent.Quantity, ProdOrderComponent.Quantity);
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderComponentsWithDuplicatedItemAreGroupedInShortageListReport()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: array[3] of Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        QtyRequiredForReleasedOrder: Decimal;
        QtyRequiredForPlannedOrder: Decimal;
        QtySuppliedFromInventory: Decimal;
        QtySuppliedFromPlannedOrder: Decimal;
    begin
        // [FEATURE] [Prod. Order Shortage List] [Prod. Order Component]
        // [SCENARIO 225889] Prod. order components should be grouped by item, location and variant in order to calculate the full need with a consideration of item inventory and planned supplies and demands.
        Initialize();

        // [GIVEN] Production items "P" and "C". "C" is a component of "P".
        LibraryInventory.CreateItem(ProdItem);
        LibraryInventory.CreateItem(CompItem);

        QtyRequiredForReleasedOrder := LibraryRandom.RandIntInRange(20, 40);
        QtySuppliedFromInventory := LibraryRandom.RandIntInRange(5, 10);
        QtySuppliedFromPlannedOrder := LibraryRandom.RandIntInRange(5, 10);
        QtyRequiredForPlannedOrder := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] "X" pcs of "C" are in the inventory.
        PostItemInventory(CompItem."No.", QtySuppliedFromInventory);

        // [GIVEN] Released production order for item "P".
        // [GIVEN] It requires "Y" pcs of "C" to produce "P". The order contains "Y" prod. order component lines with item "C" and quantity = 1.
        CreateAndRefreshProductionOrder(ProductionOrder[1], ProductionOrder[1].Status::Released, ProdItem."No.", 1);
        FindProdOrderLine(ProdOrderLine, ProductionOrder[1]);
        CreateSetOfProdOrderComp(ProdOrderLine, CompItem."No.", 1, QtyRequiredForReleasedOrder);

        // [GIVEN] Firm planned production order for item "P" with "Z" prod. order component lines with item "C" and quantity = 1.
        CreateAndRefreshProductionOrder(ProductionOrder[2], ProductionOrder[2].Status::"Firm Planned", ProdItem."No.", 1);
        FindProdOrderLine(ProdOrderLine, ProductionOrder[2]);
        CreateSetOfProdOrderComp(ProdOrderLine, CompItem."No.", 1, QtyRequiredForPlannedOrder);

        // [GIVEN] Firm planned production order for "W" pcs of item "C".
        CreateAndRefreshProductionOrder(
          ProductionOrder[3], ProductionOrder[3].Status::"Firm Planned", CompItem."No.", QtySuppliedFromPlannedOrder);
        FindProdOrderLine(ProdOrderLine, ProductionOrder[3]);
        ProdOrderLine.Validate("Due Date", WorkDate() - 1);
        ProdOrderLine.Modify(true);

        // [GIVEN] Thus, the overall supply of item "C" is equal to ("X" + "W").
        // [GIVEN] The overall demand = ("Y" + "Z") and is greater than the supply.

        // [WHEN] Run "Prod. Order Shortage List" report.
        Commit();
        RunAndSaveProdOrderShortageListReport(ProductionOrder[1], ProductionOrder[1].Status::Released, ProdItem."No.");

        // [THEN] The report shows ("Y" + "Z") - ("X" + "W") pcs of "C" lacking to produce "P".
        VerifyQtyInProdOrderShortageListReport(
          ProductionOrder[1]."No.", CompItem."No.", QtyRequiredForReleasedOrder,
          QtyRequiredForReleasedOrder + QtyRequiredForPlannedOrder - QtySuppliedFromInventory - QtySuppliedFromPlannedOrder);
    end;

    [Test]
    [HandlerFunctions('ProdOrderShortageListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListReportScheduledNeedAndReceipt()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        Qty: Decimal;
    begin
        // [FEATURE] [Prod. Order Shortage List]
        // [SCENARIO 321733] "Scheduled Need" and "Scheduled Receipt" calculation in Prod. Order Shortage List report.
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Component item "C", manufacturing item "P", both set up for "Prod. Order" replenishment.
        CreateItem(CompItem, '', '');
        CreateAndCertifyProductionBOM(ProductionBOMHeader, CompItem."No.");
        CreateItem(ProdItem, '', ProductionBOMHeader."No.");

        // [GIVEN] Firm planned production order for "C", quantity = 10, due date = WORKDATE.
        // [GIVEN] Firm planned production order for "P", quantity = 10, due date = WORKDATE.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", CompItem."No.", Qty);
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ProdItem."No.", Qty);

        // [GIVEN] Released production order for "P", quantity = 10, due date = WorkDate() + 1 week.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", Qty);
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", LibraryRandom.RandDateFromInRange(WorkDate(), 10, 20));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Run "Prod. Order - Shortage list" report to calculate scheduled need and receipt for the released production order.
        Commit();
        REPORT.Run(REPORT::"Prod. Order - Shortage List", true, false);

        // [THEN] The report shows "Scheduled Need" of the component "C" as 20 (10 needed for firm planned order + 10 for the released order).
        // [THEN] The report shows "Scheduled Receipt" of the component "C" as 10 (expected output in the firm planned order).
        VerifyScheduledQtysInProdOrderShortageListReport(ProductionOrder."No.", 2 * Qty, Qty);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Manufacturing Reports -II");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Manufacturing Reports -II");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ItemJournalSetup();
        ConsumptionJournalSetup();
        OutputJournalSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Manufacturing Reports -II");
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure OutputJournalSetup()
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(100, 2));
        MachineCenter.Modify(true);
    end;

    local procedure OutputJournalExplodeRouting(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure CreateProdOrderItemsSetup(var Item: Record Item) ChildItemNo: Code[20]
    var
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Items.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        ChildItemNo := CreateChildItemWithInventory();

        // Create Production BOM.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItemNo);

        // Create Parent Item and attach Routing and Production BOM.
        CreateRoutingSetup(RoutingHeader);
        CreateItem(Item, RoutingHeader."No.", ProductionBOMHeader."No.");
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure CreateItem(var Item: Record Item; RoutingNo: Code[20]; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::FIFO);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Unit Cost", LibraryRandom.RandDec(50, 2));
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateChildItemWithInventory(): Code[20]
    var
        Item: Record Item;
    begin
        CreateItem(Item, '', '');
        PostItemInventory(Item."No.", LibraryRandom.RandDec(100, 2) + 10);
        exit(Item."No.");
    end;

    local procedure PostItemInventory(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure ExplodeRoutingAndPostOutputJournal(ProductionOrderNo: Code[20])
    begin
        OutputJournalExplodeRouting(ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure FilterOnProductionOrder(var ProductionOrder: Record "Production Order")
    begin
        ProductionOrder.SetRange("No.", ProductionOrder."No.");
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
    end;

    local procedure FilterProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Item No.", ItemNo);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindValueEntryForOutput(var ValueEntry: Record "Value Entry"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.FindFirst();
    end;

    local procedure GenerateProductionOrderStatisticsReport(ProductionOrderNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange("No.", ProductionOrderNo);
        REPORT.Run(REPORT::"Production Order Statistics", true, false, ProductionOrder);
    end;

    local procedure SelectProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.FindFirst();
    end;

    local procedure SelectProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, Status);
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.FindFirst();
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; Status: Enum "Production Order Status")
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.FindFirst();
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure RunAndSaveProdOrderShortageListReport(ProductionOrder: Record "Production Order"; ProductionOrderStatus: Enum "Production Order Status"; SourceNo: Code[20])
    begin
        SelectProductionOrder(ProductionOrder, ProductionOrderStatus, SourceNo);
        REPORT.Run(REPORT::"Prod. Order - Shortage List", true, false, ProductionOrder);
    end;

    local procedure RunAndSaveInventoryAvailabilityPlanReport(var Item: Record Item; UseStockkeepingUnit: Boolean)
    var
        PeriodLength: DateFormula;
    begin
        Item.SetRange("No.", Item."No.");
        Evaluate(PeriodLength, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(UseStockkeepingUnit);
        REPORT.Run(REPORT::"Inventory - Availability Plan", true, false, Item);
    end;

    local procedure UpdateInventorySetup(AutomaticCostPosting: Boolean; ExpectedCostPosting: Boolean; AutomaticCostAdjustment: Enum "Automatic Cost Adjustment Type")
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", AutomaticCostPosting);
        InventorySetup.Validate("Expected Cost Posting to G/L", ExpectedCostPosting);
        InventorySetup.Validate("Automatic Cost Adjustment", AutomaticCostAdjustment);
        InventorySetup.Modify(true);
    end;

    local procedure RunAndSaveInventoryValuationWIPReport(ProductionOrder: Record "Production Order")
    begin
        ProductionOrder.SetRange("No.", ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);
    end;

    local procedure VerifyMachineCenterCalendar(MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    var
        CalendarEntry: Record "Calendar Entry";
    begin
        CalendarEntry.SetRange("Capacity Type", CalendarEntry."Capacity Type"::"Machine Center");
        CalendarEntry.SetRange("No.", MachineCenter."No.");
        CalendarEntry.FindSet();
        repeat
            CalendarEntry.TestField("Work Center No.", WorkCenterNo);
            CalendarEntry.TestField(Efficiency, MachineCenter.Efficiency);
            CalendarEntry.TestField(Capacity, MachineCenter.Capacity);
        until CalendarEntry.Next() = 0;
    end;

#if not CLEAN26
    local procedure VerifyMachineCenterList(MachineCenter: Record "Machine Center")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Machine_Center__No__', MachineCenter."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Machine_Center__Work_Center_No__', MachineCenter."Work Center No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Machine_Center_Capacity', MachineCenter.Capacity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Machine_Center_Efficiency', MachineCenter.Efficiency);
    end;
#endif

    local procedure VerifyMachineCenterLoadBar(MachineCenter: Record "Machine Center"; NoOfPeriods: Integer)
    var
        VarDate: Variant;
        PeriodEndingDate: Date;
        PeriodStartingDate: Date;
        "Count": Integer;
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('MachineCenterNo', MachineCenter."No.");
        while LibraryReportDataset.GetNextRow() do begin
            Count += 1;
            LibraryReportDataset.FindCurrentRowValue('PeriodStartingDate', VarDate);
            Evaluate(PeriodStartingDate, VarDate);
            LibraryReportDataset.FindCurrentRowValue('PeriodEndingDate', VarDate);
            Evaluate(PeriodEndingDate, VarDate);
            MachineCenter.SetRange("Date Filter", PeriodStartingDate, PeriodEndingDate);
            MachineCenter.CalcFields("Capacity (Effective)");
            LibraryReportDataset.AssertCurrentRowValueEquals('MachineCenterCapacityEffective', MachineCenter."Capacity (Effective)");
        end;

        Assert.AreEqual(NoOfPeriods, Count, NoOfLinesError);
    end;

#if not CLEAN26
    local procedure VerifyWorkCenterList(WorkCenter: Record "Work Center")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Work_Center__No__', WorkCenter."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Work_Center__Work_Center_Group_Code_', WorkCenter."Work Center Group Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Work_Center__Shop_Calendar_Code_', WorkCenter."Shop Calendar Code");
        LibraryReportDataset.AssertCurrentRowValueEquals('Work_Center_Capacity', WorkCenter.Capacity);
    end;
#endif

    local procedure VerifyProdOrderList(ProductionOrder: Record "Production Order")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Production_Order__No__', ProductionOrder."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Production_Order__Source_No__', ProductionOrder."Source No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Production_Order__Routing_No__', ProductionOrder."Routing No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Production_Order_Quantity', ProductionOrder.Quantity);
    end;

    local procedure VerifyProdOrderRoutingList(RoutingNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryReportDataset.LoadDataSetFile();

        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindSet();
        repeat
            LibraryReportDataset.SetRange('Prod__Order_Routing_Line__Operation_No__', RoutingLine."Operation No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('Prod__Order_Routing_Line_Type', Format(RoutingLine.Type));
            LibraryReportDataset.AssertCurrentRowValueEquals('Prod__Order_Routing_Line__No__', RoutingLine."No.");
        until RoutingLine.Next() = 0;
    end;

    local procedure VerifyWorkCenterLoadBar(WorkCenter: Record "Work Center"; NoOfPeriods: Integer)
    var
        VarDate: Variant;
        PeriodStartingDate: Date;
        PeriodEndingDate: Date;
        "Count": Integer;
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('WorkCenterNo', WorkCenter."No.");
        while LibraryReportDataset.GetNextRow() do begin
            Count += 1;
            LibraryReportDataset.FindCurrentRowValue('PeriodStartingDate', VarDate);
            Evaluate(PeriodStartingDate, VarDate);
            LibraryReportDataset.FindCurrentRowValue('PeriodEndingDate', VarDate);
            Evaluate(PeriodEndingDate, VarDate);
            WorkCenter.SetRange("Date Filter", PeriodStartingDate, PeriodEndingDate);
            WorkCenter.CalcFields("Capacity (Effective)");
            LibraryReportDataset.AssertCurrentRowValueEquals('WorkCenterCapacityEffective', WorkCenter."Capacity (Effective)");
        end;

        Assert.AreEqual(NoOfPeriods, Count, NoOfLinesError);
    end;

    local procedure VerifyProductionOrderForReplan(ReplanRefStatus: Enum "Production Order Status"; ReplanRefNo: Code[20]; SourceNo: Code[20]; Quantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
    begin
        SelectProductionOrder(ProductionOrder, ReplanRefStatus, SourceNo);
        ProductionOrder.TestField("Replan Ref. Status", ReplanRefStatus);
        ProductionOrder.TestField("Replan Ref. No.", ReplanRefNo);
        ProductionOrder.TestField(Quantity, Quantity);
    end;

    local procedure VerifyProdOrderShortageListReport(Item: Record Item; ProductionOrderNo: Code[20]; Status: Enum "Production Order Status")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo, Status);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_ProdOrderComp', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_ProdOrder', ProductionOrderNo);

        Item.CalcFields(Inventory, "Qty. on Component Lines");
        if Status <> ProdOrderComponent.Status::Finished then begin
            LibraryReportDataset.AssertCurrentRowValueEquals('CompItemSchdldNeedQty', Item."Qty. on Component Lines");
            LibraryReportDataset.AssertCurrentRowValueEquals('NeededQuantity', Item."Qty. on Component Lines" - Item.Inventory);
        end else begin
            LibraryReportDataset.AssertCurrentRowValueEquals('CompItemSchdldNeedQty', ProdOrderComponent."Remaining Quantity");
            LibraryReportDataset.AssertCurrentRowValueEquals('NeededQuantity', ProdOrderComponent."Remaining Quantity" - Item.Inventory);
        end;

        LibraryReportDataset.AssertCurrentRowValueEquals('CompItemInventory', Item.Inventory);
    end;

    local procedure VerifyProductionOrderStatistics(ProductionOrder: Record "Production Order"; MaterialCost: Decimal; Post: Boolean)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProdOrder', ProductionOrder."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Status_ProdOrder', Format(ProductionOrder.Status::Finished));
        LibraryReportDataset.AssertCurrentRowValueEquals('ExpCost1', MaterialCost); // Exp. Material Cost.

        if Post then
            LibraryReportDataset.AssertCurrentRowValueEquals('ActCost1', MaterialCost); // Act. Material Cost.
    end;

    [Normal]
    local procedure VerifyInvtAvailabilityPlanReport(Item: Record Item; KeyElement: Text; KeyValue: Variant; InventoryElement: Text)
    begin
        Item.CalcFields(Inventory);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(KeyElement, KeyValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(InventoryElement, Item.Inventory);
    end;

    local procedure VerifyScheduledQtysInProdOrderShortageListReport(ProdOrderNo: Code[20]; ScheduledNeed: Decimal; ScheduledReceipt: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProdOrder', ProdOrderNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CompItemSchdldNeedQty', ScheduledNeed);
        LibraryReportDataset.AssertCurrentRowValueEquals('CompItemSchdldRcptQty', ScheduledReceipt);
    end;

    local procedure ExecuteUIHandlers()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        Message('');
        if Confirm('') then;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkMachineCenterLoadRequestPageHandler(var WorkMachineCenterLoad: TestRequestPage "Work/Machine Center Load")
    var
        NoOfPeriods: Variant;
    begin
        LibraryVariableStorage.Dequeue(NoOfPeriods);
        WorkMachineCenterLoad.StartingDate.SetValue(WorkDate());
        WorkMachineCenterLoad.NoOfPeriods.SetValue(NoOfPeriods);
        WorkMachineCenterLoad.PeriodLength.SetValue('<1W>');
        WorkMachineCenterLoad.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(ConfirmMessage, ExpectedMessage), ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ExpCostPostingConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExpCostPostingMsgHandler(Message: Text[1024])
    begin
    end;

#if not CLEAN26
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MachineCenterListRequestPageHandler(var MachineCenterList: TestRequestPage "Machine Center List")
    begin
        MachineCenterList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingListRequestPageHandler(var ProdOrderRoutingList: TestRequestPage "Prod. Order - Routing List")
    begin
        ProdOrderRoutingList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderListRequestPageHandler(var ProdOrderList: TestRequestPage "Prod. Order - List")
    begin
        ProdOrderList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN26
    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WorkCenterListRequestPageHandler(var WorkCenterList: TestRequestPage "Work Center List")
    begin
        WorkCenterList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
#endif

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderShortageListRequestPageHandler(var ProdOrderShortageList: TestRequestPage "Prod. Order - Shortage List")
    begin
        ProdOrderShortageList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryAvailabilityPlanRequestPageHandler(var InventoryAvailabilityPlan: TestRequestPage "Inventory - Availability Plan")
    var
        StartingDate: Variant;
        PeriodLength: Variant;
        UseStockeepingUnit: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(PeriodLength);
        LibraryVariableStorage.Dequeue(UseStockeepingUnit);

        InventoryAvailabilityPlan.StartingDate.SetValue(StartingDate);
        InventoryAvailabilityPlan.PeriodLength.SetValue(PeriodLength);
        InventoryAvailabilityPlan.UseStockkeepUnit.SetValue(UseStockeepingUnit);
        InventoryAvailabilityPlan.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ProductionOrderStatisticsRequestPageHandler(var ProductionOrderStatistics: TestRequestPage "Production Order Statistics")
    begin
        ProductionOrderStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationWIPRequestPageHandler(var InventoryValuationWIP: TestRequestPage "Inventory Valuation - WIP")
    var
        StartingDate: Variant;
        EndingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(EndingDate);

        InventoryValuationWIP.StartingDate.SetValue(StartingDate);
        InventoryValuationWIP.EndingDate.SetValue(EndingDate);
        InventoryValuationWIP.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure CreateSetOfProdOrderComp(ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; QtyPer: Decimal; ProdOrderCompCount: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        iProdOrderComp: Integer;
    begin
        for iProdOrderComp := 1 to ProdOrderCompCount do begin
            LibraryManufacturing.CreateProductionOrderComponent(
              ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
            ProdOrderComponent.Validate("Line No.", iProdOrderComp);
            ProdOrderComponent.Insert(true);
            ProdOrderComponent.Validate("Item No.", ItemNo);
            ProdOrderComponent.Validate("Quantity per", QtyPer); // Required to validate "Remaining Qty. (Base)"
            ProdOrderComponent.Validate("Due Date", ProdOrderLine."Due Date" - 1);
            ProdOrderComponent.Modify(true);
        end;
    end;

    local procedure VerifyQtyInProdOrderShortageListReport(ProdOrderNo: Code[20]; ItemNo: Code[20]; RemainingQty: Decimal; RequiredQty: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_ProdOrder', ProdOrderNo);
        LibraryReportDataset.SetRange('ItemNo_ProdOrderComp', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('RemQtyBase_ProdOrderComp', RemainingQty);
        LibraryReportDataset.AssertCurrentRowValueEquals('NeededQuantity', RequiredQty);
    end;
}