// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using System.TestLibraries.Utilities;
using Microsoft.Manufacturing.Journal;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Manufacturing.Document;
using Microsoft.Sales.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Purchases.Document;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Forecast;
using Microsoft.Foundation.Enums;
using System.Utilities;
using Microsoft.Finance.Analysis;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Routing;
using Microsoft.Warehouse.Structure;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Setup;
using System.Environment.Configuration;
using Microsoft.Utilities;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Foundation.UOM;
using Microsoft.Manufacturing.Family;
using Microsoft.Inventory.Planning;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Warehouse.Setup;


codeunit 137069 "SCM Production Orders"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Production Order] [SCM]
        Initialized := false;
    end;

    var
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationSilver: Record Location;
        LocationGreen: Record Location;
        LocationBlue: Record Location;
        LocationWhite: Record Location;
        LibraryERM: Codeunit "Library - ERM";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
        Initialized: Boolean;
        UpdateDimensionMethod: Option ByProductionOrderLine,ByShowDimensionsOnLine,ByProductionOrder;
        AvailabilityWarningsMsg: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        CaptionErr: Label 'Caption must be the same.';
        SummaryTypeItemLedgerEntryTxt: Label 'Item Ledger Entry';
        SummaryTypePurchaseLineOrderTxt: Label 'Purchase Line, Order';
        FirmPlannedProdOrderCreatedTxt: Label 'Firm Planned Prod. Order';
        SerialNoErr: Label 'Serial No does not exist.';
        NumberOfLineEqualErr: Label 'Number of Lines must be same.';
        QtyToHandleErr: Label 'Qty. to Handle (Base) in the item tracking assigned to the document line for item';
        LotNoErr: Label 'You must assign a lot number for item %1.', Comment = '%1 - Item No.';
        ProductionOrderFinishedStatusMsg: Label '\\  * Some consumption is still missing.\\ Do you still want to finish the order?';
        ProductionOrderNotExistErr: Label 'There is no Production Order within the filter';
        NothingToPlanMsg: Label 'There is nothing to plan';
        JournalLinePostedMsg: Label 'The journal lines were successfully posted.';
        ValuedQtyErr: Label 'Valued Quantity in posted Value Entry is incorrect.';
        LedgEntryNotPostedErr: Label 'Production Journal  posting must create %1.';
        ProdOrderLineExistsErr: Label 'There is no Prod. Order Line within the filter.';
        FromProductionBinCodeErr: Label 'When creating PO from SO Bin Code should be taken from Location."From-Production Bin Code" filed';
        WrongFieldValueErr: Label '%1 in %2 must be copied from %3';
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Verify Entries","Set Lot No.","Set Quantity & Lot No.","Get Lot Quantity";
        PostingQst: Label 'Do you want to post the journal lines?';
        JournalPostedMsg: Label 'successfully posted';
        WillNotAffectExistingEntriesTxt: Label 'The change will not affect existing entries.';
        RoutingHeaderExistErr: Label 'Routing No. must have a value in Prod. Order Routing Line';
        ItemMustNotBeShownErr: Label 'Only filtered item must be displayed in the page.', Comment = '%1 = item no.';
        CannotDeleteRecProdOrderErr: Label 'You cannot delete the Quality Measure because it is being used on one or more active Production Orders.';
        CannotDeleteRecActRoutingErr: Label 'You cannot delete the Quality Measure because it is being used on one or more active Routings.';
        MalformedRecLinkErr: Label 'Wrong data in record link found';
        WrongLotQtyOnItemJnlErr: Label 'Wrong lot quantity in item tracking on item journal line.';
        ItemFilterTextErr: Label 'Item filter text is not displayed correctly on the Demand Forecast.';
        ItemFilterBlobErr: Label 'Item filter is not stored correctly in the ItemFilterBlob';
        ItemFilterErr: Label 'Items are not correctly filtered in the demand forecast matrix.';
        LocFilterBlobErr: Label 'Location filter is not stored correctly in the LocationFilterBlob';
        LocFilterErr: Label 'Locations are not correctly filtered in the demand forecast matrix.';
        LocFilterOnLookUpErr: Label 'OnLookUp is not working on the location filter for demand forecast card.';
        VarFilterOnLookUpErr: Label 'OnLookUp is not working on the variant filter for demand forecast card.';
        VariantFilterBlobErr: Label 'Variant filter is not stored correctly in the VariantFilterBlob';
        VariantFilterErr: Label 'Variant are not correctly filtered in the demand forecast matrix.';
        LocFilterNotInitErr: Label 'Location filter is not initialized';
        VarFilterNotInitErr: Label 'Variant filter is not initialized';
        ForecastByLocErr: Label 'Locations ares not added correctly in demand forecast matrix';
        ForecastByVariantErr: Label 'Variants ares not added correctly in demand forecast matrix';
        ForecastByLocVarErr: Label 'Locations and Variants ares not added correctly in demand forecast matrix';
        ItemLocVarFilterErr: Label 'Items, variants and locations are not correctly filtered in the demand forecast matrix.';
        MatrixRowLimitMsg: Label 'Maximum number of rows to be loaded';
        EditableErr: Label 'The value must not be editable.';
        FlowFieldErr: Label 'Quantities are not correctly calculated from the flow fields in demand forecast matrix.';
        ItemShouldExistErr: Label 'Item %1 should exist in Production Forecast Matrix';
        NonEditableErr: Label 'The value must be editable.';
        InvalidDateFilterTxt: Label '100-100-2026..101-101-2026', Locked = true;
        DateFilterErrMsg: Label 'The current format of date filter %1 is not valid. Do you want to remove it?', Comment = '%1 = Date Filter';

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure CreateProductionOrderFromSalesOrderWithDimensions()
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Dimension]
        // [SCENARIO 300589] Global dimensions and Dimension Set ID is copied from sales order line to production order line
        Initialize();
        // [GIVEN] Sales Order with one line, where "Dimension Set ID" is 'X', and
        LibrarySales.CreateSalesOrder(SalesHeader);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        // [GIVEN] "Shortcut Dimension 1 Code" is 'A', "Shortcut Dimension 2 Code" is 'B'
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        SalesLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        SalesLine.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        SalesLine.TestField("Dimension Set ID");
        SalesLine.Modify(true);

        // [WHEN] Create Prod. Order from Sales Order
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, "Production Order Status"::Simulated, "Create Production Order Type"::ItemOrder);

        // [THEN] Prod Order line, where "Dimension Set ID" is 'X', and
        // [THEN] "Shortcut Dimension 1 Code" is 'A', "Shortcut Dimension 2 Code" is 'B'
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Simulated, SalesLine."No.");
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.TestField("Shortcut Dimension 1 Code", SalesLine."Shortcut Dimension 1 Code");
        ProdOrderLine.TestField("Shortcut Dimension 2 Code", SalesLine."Shortcut Dimension 2 Code");
        ProdOrderLine.TestField("Dimension Set ID", SalesLine."Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('ProdOrderCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure ProductrionOrderFromSalesOrderWithEmptyBinCodeCheck()
    var
        SalesLine: Record "Sales Line";
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 360749.1] Location's "From-Production Bin Code" copied to Prod. Order Line "Bin Code" when Sales Line has empty Bin Code.

        Initialize();

        // [GIVEN] Create Sales Order on White Location for Item with Replenishment System = Prod. Order without Bin
        CreateSalesOrderWithLocation(SalesLine, LocationWhite.Code, '');

        // [WHEN] Create Prod. Order from Sales Order Planning with Order Type = Project Order
        CreateProdOrderFromSale.CreateProductionOrder(
            SalesLine, "Production Order Status"::Released, "Create Production Order Type"::ProjectOrder);

        // [THEN] Prod. Order Line has correct Bin Code from Sales Line's Location
        VerifyProdOrderLineBinCode(LocationWhite."From-Production Bin Code", SalesLine);
    end;

    [Test]
    [HandlerFunctions('ProdOrderCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure ProductrionOrderFromSalesOrderWithBinCodeCheck()
    var
        SalesLine: Record "Sales Line";
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
        BinCode: Code[20];
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 360749.2] "Bin Code" is copied to Prod. Order Line from location's "From-Production Bin Code" if both "From-Production Bin Code" and "Location Code" in Sales Line have values.

        Initialize();

        // [GIVEN] Create Sales Order on White Location for Item with Replenishment System = Prod. Order with Bin
        BinCode := LibraryUtility.GenerateGUID();
        CreateSalesOrderWithLocation(SalesLine, LocationWhite.Code, BinCode);

        // [WHEN] Create Prod. Order from Sales Order Planning with Order Type = Project Order
        CreateProdOrderFromSale.CreateProductionOrder(
            SalesLine, "Production Order Status"::Released, "Create Production Order Type"::ProjectOrder);

        // [THEN] Prod. Order Line has correct Bin Code from Location "From-Production Bin Code"
        VerifyProdOrderLineBinCode(LocationWhite."From-Production Bin Code", SalesLine);
    end;

    [Test]
    [HandlerFunctions('ProdOrderCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure RFH360420_CheckStockkeepingUnitReplenishmentSystemPriority2()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 360420.1] Creating Orders from Sales with Order Type = "Project Order" fails if item has Replenishment System = "Purchase".

        Initialize();

        // [GIVEN] Create Item with Replenishment System = "Purchase".
        CreateItem(Item, Item."Replenishment System"::Purchase);

        // [GIVEN] Create Sales Order
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Create Prod. Order from Sales Order Planning with Order Type = Project Order
        CreateProdOrderFromSale.CreateProductionOrder(
            SalesLine, "Production Order Status"::Released, "Create Production Order Type"::ProjectOrder);

        // [THEN] Verify Prod. Order Line does not exists
        VerifyProdOrderLineDoesNotExist(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ProdOrderCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure RFH360420_CheckStockkeepingUnitReplenishmentSystemPriority()
    var
        SalesLine: Record "Sales Line";
        CreateProdOrderFromSale: Codeunit "Create Prod. Order from Sale";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 360420.2] Creating Orders from Sales with Order Type = "Project Order" is ignoring Replenishment System from the higher prioritized Stockkeeping Unit Card Information.
        Initialize();

        // [GIVEN] Create Item with Replenishment System = "Purchase" and SKU - "Prod. Order". Create Sales Order
        CreateItemWithSKU(SalesLine);

        // [WHEN] Create Prod. Order from Sales Order Planning with Order Type = Project Order
        CreateProdOrderFromSale.CreateProductionOrder(
            SalesLine, "Production Order Status"::Released, "Create Production Order Type"::ProjectOrder);

        // [THEN] Verify Prod. Order Line is calculated correctly
        VerifyProdOrderLineFromSalesLine(SalesLine);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ConfirmQstHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnRequisitionLineForProductionOrderComponent()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // Setup: Create Production Item with Lot Specific Tracking and Production BOM. Create Release Production Order and Assign Tracking on Production Order Component line.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateTrackedItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.", false, Quantity,
          ItemTrackingCode.Code);
        CreateTrackedItem(
          Item2, Item2."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Fixed Reorder Qty.", false, Quantity,
          ItemTrackingCode.Code);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."No.", Item2."Base Unit of Measure");
        UpdateProductionBOMOnItem(Item2, ProductionBOMHeader."No.");

        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item2."No.", Quantity);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", Item."No.");
        AssingTrackingOnProdOrderComponent(ProdOrderComponent);

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify Item Tracking on Requisition line.
        FindReservationEntry(ReservationEntry, Item."No.", DATABASE::"Prod. Order Component");
        VerifyTrackingOnRequisitionLine(Item."No.", ReservationEntry."Lot No.", ProdOrderComponent."Expected Quantity");  // verify on Page handler - LotItemTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnRequisitionLineForSalesOrder()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingMode: Option " ","Assign Lot No.","Select Entries","Verify Entries";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Lot Specific Tracking and update inventory. Create Sales Order with Tracking.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateTrackedItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.", false, Quantity,
          ItemTrackingCode.Code);
        CreateAndPostItemJournalLineWithTracking(Item."No.", Quantity);

        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        SalesLine.OpenItemTrackingLines();  // Select Item Tracking on Page handler - LotItemTrackingPageHandler.

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify Item Tracking on Requisition line.
        FindReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line");
        VerifyTrackingOnRequisitionLine(Item."No.", ReservationEntry."Lot No.", SalesLine.Quantity);  // verify on Page handler - LotItemTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnPurchaseLineWithCalcRegenPlanTwice()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item3: Record Item;
        PurchaseLine: Record "Purchase Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Setup: Create Production Item with Lot Specific Tracking and Production BOM. Create Sales Order using Parent Item.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateTrackedItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Lot-for-Lot", true, 0, ItemTrackingCode.Code);
        CreateTrackedItem(
          Item2, Item2."Replenishment System"::"Prod. Order", Item2."Reordering Policy"::"Lot-for-Lot", true, 0, ItemTrackingCode.Code);

        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."No.", Item2."Base Unit of Measure");
        UpdateProductionBOMOnItem(Item2, ProductionBOMHeader."No.");
        CreateSalesOrder(SalesHeader, SalesLine, Item2."No.", LibraryRandom.RandDec(10, 2));

        // Calculate Regenerative Plan and Carry out action message.
        Item3.SetFilter("No.", '%1|%2', Item."No.", Item2."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item3, WorkDate(), WorkDate());
        AcceptActionMessageAndCarryOutActionMessagePlan(Item."No.");
        FindPurchaseLine(PurchaseLine, Item."No.");

        // Assign Item Tracking on Purchase Line.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        PurchaseLine.OpenItemTrackingLines();  // Assign Item Tracking on Page handler - LotItemTrackingPageHandler.
        FindReservationEntry(ReservationEntry, Item."No.", DATABASE::"Purchase Line");

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item3, WorkDate(), WorkDate());

        // Verify: Verify Item Tracking line on Purchase Line.
        // Enqueue for Page Handler - LotItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Verify Entries");
        LibraryVariableStorage.Enqueue(ReservationEntry."Lot No.");
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();  // verify on Page handler - LotItemTrackingPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WorkCenterWithDimension()
    var
        WorkCenter: Record "Work Center";
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        // Setup: Create Work Center.
        Initialize();
        CreateWorkCenter(WorkCenter, 080000T, 160000T);

        // Exercise: Update Global Dimension 1 Code on Work Center.
        UpdateGlobalDimensionOnWorkCenter(DimensionValue, WorkCenter);

        // Verify: Verify Dimension for Work Center on Default Dimension.
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::"Work Center", WorkCenter."No.");
        DefaultDimension.TestField("Dimension Code", DimensionValue."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimulatedProductionOrderWithDimension()
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        Item2: Record Item;
        DimensionValue2: Record "Dimension Value";
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Production Item with dimension.
        Initialize();
        CreateProductionItemWithDimensionSetup(Item, Item2, DimensionValue, DimensionValue2);

        // Exercise: Create and Refresh Simulated Production Order.
        CreateAndRefreshSimulatedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Dimension on Production Order Line and Production Order Component.
        VerifyDimensionOnProductionOrderLine(ProductionOrder.Status, ProductionOrder."No.", DimensionValue);
        VerifyDimensionOnProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", Item2."No.", DimensionValue); // TFS 322868 and 322869
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimulatedProdOrderWithNewDimensionOnProdLineAndChangeStatusToReleased()
    begin
        // [FEATURE] [Dimension] [Production Order]
        // [SCENARIO] Verify dimension in Production Order, having parent and child items with their own dim values, and order line with different dim value, after releasing Production Order.

        // Setup.
        Initialize();
        SimulatedProdOrderWithNewDimensionAndChangeStatusToReleased(true);  // Dimension Update On Production Order Line as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimulatedProdOrderWithNewDimensionOnComponentLineAndChangeStatusToReleased()
    begin
        // [FEATURE] [Dimension] [Production Order]
        // [SCENARIO] Verify dimension in Production Order, having parent and child items with their own dim values, and component line with different dim value, after releasing Production Order.

        // Setup.
        Initialize();
        SimulatedProdOrderWithNewDimensionAndChangeStatusToReleased(false);  // Dimension Update On Production Order Line as False.
    end;

    local procedure SimulatedProdOrderWithNewDimensionAndChangeStatusToReleased(DimensionUpdateOnProductionOrderLine: Boolean)
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        Item2: Record Item;
        DimensionValue2: Record "Dimension Value";
        DimensionValue3: Record "Dimension Value";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
    begin
        // Create Production Item with dimension and update dimension on Production Order Line and Production Order Component.
        CreateProductionItemWithDimensionSetup(Item, Item2, DimensionValue, DimensionValue2);
        CreateAndRefreshSimulatedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        if DimensionUpdateOnProductionOrderLine then
            UpdateDimensionOnProductionOrderLine(DimensionValue3, ProductionOrder)
        else
            UpdateDimensionOnProdOrderComponent(DimensionValue3, ProductionOrder, Item2."No.");

        // Exercise: Change Status of the Production Order - Simulated to Released.
        ProductionOrderNo := LibraryManufacturing.ChangeStatusSimulatedToReleased(ProductionOrder."No.");

        // Verify: Verify Dimension on Production Order Line and Production Order Component.
        VerifyDimensionOnProductionOrderLine(ProductionOrder.Status::Released, ProductionOrderNo, DimensionValue);
        VerifyDimensionOnProdOrderComponent(ProductionOrder.Status::Released, ProductionOrderNo, Item2."No.", DimensionValue); // TFS 322868 and 322869

        if DimensionUpdateOnProductionOrderLine then
            VerifyDimensionOnProductionOrderLine(ProductionOrder.Status::Released, ProductionOrderNo, DimensionValue3)
        else
            VerifyDimensionOnProdOrderComponent(ProductionOrder.Status::Released, ProductionOrderNo, Item2."No.", DimensionValue3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderWithNewDimensionOnComponentLineAndConsumptionJournal()
    begin
        // Setup.
        Initialize();
        ReleasedProdOrderAndConsumptionJournalWithDimension(false);  // Posting Consumption as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderWithNewDimensionOnComponentLineAndPostConsumptionJournal()
    begin
        // Setup.
        Initialize();
        ReleasedProdOrderAndConsumptionJournalWithDimension(true);  // Posting Consumption as True.
    end;

    local procedure ReleasedProdOrderAndConsumptionJournalWithDimension(PostConsumption: Boolean)
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        Item2: Record Item;
        DimensionValue2: Record "Dimension Value";
        DimensionValue3: Record "Dimension Value";
        ProductionOrder: Record "Production Order";
    begin
        // Create Production Item with dimension and update dimension on Production Order Component.
        CreateProductionItemWithDimensionSetup(Item, Item2, DimensionValue, DimensionValue2);
        CreateAndPostItemJournalLine(Item2."No.");
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateDimensionOnProdOrderComponent(DimensionValue3, ProductionOrder, Item2."No.");

        // Exercise: Create Consumption Journal and Post.
        CreateConsumptionJournal(ProductionOrder."No.");
        if PostConsumption then
            LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // Verify: Verify Dimension on Item Journal Line. Verify Dimension on Item Ledger Entry and Value Entry.
        if PostConsumption then begin
            VerifyDimensionsOnItemLedgerEntry(ProductionOrder."No.", Item2."No.", DimensionValue, DimensionValue3); // TFS 322868 and 322869
            VerifyDimensionsOnValueEntry(ProductionOrder."No.", Item2."No.", DimensionValue, DimensionValue3); // TFS 322868 and 322869
        end else
            VerifyDimensionsOnItemJournalLine(Item2."No.", DimensionValue, DimensionValue3); // TFS 322868 and 322869
    end;

    local procedure CreateDemandForecastCard(var DemandForecastCard: TestPage "Demand Forecast Card")
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        DemandForecastCard.OpenNew();
        DemandForecastCard.Name.SetValue(LibraryUtility.GenerateRandomCode(ProductionForecastName.FieldNo(Name), DATABASE::"Production Forecast Name"));
        DemandForecastCard.Description.SetValue(LibraryUtility.GenerateRandomCode(ProductionForecastName.FieldNo(Description), DATABASE::"Production Forecast Name"));
    end;

    // Count the rows based on the column name  and store it in a dictionary for each unique record in the column.
    local procedure CountDemandForecastRows(var DemandForecastCard: TestPage "Demand Forecast Card"; var RowCount: Dictionary of [Text, Integer]; ColumnName: Text)
    var
        RowKey: Text;
    begin
        DemandForecastCard.Matrix.First();
        repeat
            case ColumnName of
                DemandForecastCard.Matrix."No.".Caption:
                    RowKey := DemandForecastCard.Matrix."No.".Value();
                DemandForecastCard.Matrix."Location Code".Caption:
                    RowKey := DemandForecastCard.Matrix."Location Code".Value();
                DemandForecastCard.Matrix."Variant Code".Caption:
                    RowKey := DemandForecastCard.Matrix."Variant Code".Value();
            end;

            if RowCount.ContainsKey(RowKey) then
                RowCount.Set(RowKey, 1 + RowCount.Get(RowKey))
            else
                RowCount.Add(RowKey, 1);
        until DemandForecastCard.Matrix.Next() = false;
    end;

    [Test]
    [HandlerFunctions('ItemFilterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastItemFilter()
    var
        ProductionForecastName: Record "Production Forecast Name";
        Item: Record Item;
        DemandForecastCard: TestPage "Demand Forecast Card";
        InvalidItemNo: Code[20];
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Check Item filters and verify if the matrix contains appropriate records.

        // [GIVEN] Items and Demand Forecast
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item);

        CreateDemandForecastCard(DemandForecastCard);

        // [WHEN] Setting item filter using drill down.
        LibraryVariableStorage.Enqueue(Item."No.");
        DemandForecastCard."Item Filter".Drilldown();

        // [THEN] Item filters are converted to display texts and copied to the page.
        ProductionForecastName.Get(DemandForecastCard.Name.Value);
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ProductionForecastName.GetItemFilterAsDisplayText(), ItemFilterTextErr);
        Assert.AreEqual(ProductionForecastName.GetItemFilterAsDisplayText(), DemandForecastCard."Item Filter".Value, ItemFilterTextErr);

        // [THEN] Demand Forecast Matrix only contains the filtered items.
        DemandForecastCard.Matrix.First();
        Assert.AreEqual(Item."No.", DemandForecastCard.Matrix."No.".Value, ItemFilterErr);
        Assert.IsFalse(DemandForecastCard.Matrix.Next(), ItemFilterErr);

        // [THEN] ItemFilterBlob is correctly stored.
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ProductionForecastName.GetItemFilterBlobAsViewFilters(), ItemFilterBlobErr);

        // [WHEN] Invalid item filter is set
        // Find an invalid item no for the filter.
        repeat
            InvalidItemNo := LibraryRandom.RandText(10);
        until not Item.Get(InvalidItemNo);
        LibraryVariableStorage.Enqueue(InvalidItemNo);
        DemandForecastCard."Item Filter".Drilldown();

        // [THEN] Demand forecast matrix should not have any entries.
        DemandForecastCard.Next();
        Assert.IsFalse(DemandForecastCard.Matrix.First(), ItemFilterErr);

        // [WHEN] Forecast by variant is turned on
        DemandForecastCard."Forecast By Variants".SetValue(true);

        // [THEN] Demand forecast matrix should not have any entries.
        Assert.IsFalse(DemandForecastCard.Matrix.First(), ItemFilterErr);

        // [WHEN] Forecast by location is turned on
        DemandForecastCard."Forecast By Variants".SetValue(false);
        DemandForecastCard."Forecast By Locations".SetValue(true);

        // [THEN] Demand forecast matrix should not have any entries.
        Assert.IsFalse(DemandForecastCard.Matrix.First(), ItemFilterErr);

        // [WHEN] Forecast by variant and Forecast by location is turned on
        DemandForecastCard."Forecast By Variants".SetValue(true);

        // [THEN] Demand forecast matrix should not have any entries.
        Assert.IsFalse(DemandForecastCard.Matrix.First(), ItemFilterErr);
    end;

    [Test]
    [HandlerFunctions('OnLookUpLocationPageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastLocationFilterOnLookUp()
    var
        Location1: Record Location;
        DemandForecastCard: TestPage "Demand Forecast Card";
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Set location filter using OnLookUp.

        // [GIVEN] Location and Demand Forecast
        Initialize();
        LibraryWarehouse.CreateLocation(Location1);
        CreateDemandForecastCard(DemandForecastCard);

        // [WHEN] Forecast by location is checked and look up is used to fill the location filter.
        DemandForecastCard."Forecast By Locations".SetValue(true);
        LibraryVariableStorage.Enqueue(Location1.Code);
        DemandForecastCard."Location Filter".Lookup();

        // [THEN] Location filter is filled with selected location in the modal page.
        Assert.AreEqual(Location1.Code, DemandForecastCard."Location Filter".Value, LocFilterOnLookUpErr);
    end;

    [Test]
    [HandlerFunctions('OnLookUpVariantPageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastVariantFilterOnLookUp()
    var
        Item1: Record Item;
        Variant1: Record "Item Variant";
        DemandForecastCard: TestPage "Demand Forecast Card";
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Set variant filter using OnLookUp.

        // [GIVEN] Item with variant and Demand Forecast
        Initialize();
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateVariant(Variant1, Item1);

        CreateDemandForecastCard(DemandForecastCard);

        // [WHEN] Forecast by variant is checked and look up is used to fill the variant filter.
        DemandForecastCard."Forecast By Variants".SetValue(true);
        LibraryVariableStorage.Enqueue(Variant1.Code);
        DemandForecastCard."Variant Filter".Lookup();

        // [THEN] Location filter is filled with selected location in the modal page.
        Assert.AreEqual(Variant1.Code, DemandForecastCard."Variant Filter".Value, VarFilterOnLookUpErr);
    end;

    [Test]
    [HandlerFunctions('ItemFilterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastLocationFilter()
    var
        ProductionForecastName: Record "Production Forecast Name";
        Item1: Record Item;
        Item2: Record Item;
        Location1: Record Location;
        Location2: Record Location;
        Location3: Record Location;
        DemandForecastCard: TestPage "Demand Forecast Card";
        LocationCount: Dictionary of [Text, Integer];
        ItemCount: Dictionary of [Text, Integer];
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Check Location filters and verify if the matrix contains appropriate records.

        // [GIVEN] Items, Locations (one of them is in-transit location) and Demand Forecast
        Initialize();
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);
        LibraryWarehouse.CreateLocation(Location1);
        LibraryWarehouse.CreateLocation(Location2);
        Location2."Use As In-Transit" := true;
        Location2.Modify();
        LibraryWarehouse.CreateLocation(Location3);

        CreateDemandForecastCard(DemandForecastCard);

        // [THEN] Location and Variant column stays hidden in demand forecast matrix.
        Assert.IsFalse(DemandForecastCard.Matrix."Location Code".Visible(), ForecastByLocErr);
        Assert.IsFalse(DemandForecastCard.Matrix."Variant Code".Visible(), ForecastByVariantErr);

        // [WHEN] Forecast by location is checked.
        DemandForecastCard."Forecast By Locations".SetValue(true);

        // [THEN] Location column is shown in the forecast matrix.
        Assert.IsTrue(DemandForecastCard.Matrix."Location Code".Visible(), ForecastByLocErr);
        Assert.IsFalse(DemandForecastCard.Matrix."Variant Code".Visible(), ForecastByVariantErr);

        // [WHEN] The items are filtered using the created items
        LibraryVariableStorage.Enqueue(Item1."No." + '|' + Item2."No.");
        DemandForecastCard."Item Filter".Drilldown();

        // [THEN] The forecast matrix should consist of (non-transit locations) x (number of items).
        CountDemandForecastRows(DemandForecastCard, ItemCount, DemandForecastCard.Matrix."No.".Caption);
        CountDemandForecastRows(DemandForecastCard, LocationCount, DemandForecastCard.Matrix."Location Code".Caption);
        Assert.AreEqual(2, LocationCount.Get(Location1.Code), LocFilterErr);
        Assert.IsFalse(LocationCount.ContainsKey(Location2.Code), LocFilterErr);
        Assert.AreEqual(2, LocationCount.Get(Location3.Code), LocFilterErr);

        // [WHEN] The locations are filtered
        DemandForecastCard."Location Filter".SetValue(Location1.Code);

        // [THEN] The forecast matrix should consist of (filtered non-transit locations) x (number of items).
        Clear(LocationCount);
        Clear(ItemCount);
        CountDemandForecastRows(DemandForecastCard, ItemCount, DemandForecastCard.Matrix."No.".Caption);
        CountDemandForecastRows(DemandForecastCard, LocationCount, DemandForecastCard.Matrix."Location Code".Caption);
        Assert.AreEqual(2, LocationCount.Get(Location1.Code), LocFilterErr);
        Assert.AreEqual(1, ItemCount.Get(Item1."No."), LocFilterErr);
        Assert.AreEqual(1, ItemCount.Get(Item2."No."), LocFilterErr);
        Assert.AreEqual(1, LocationCount.Count, LocFilterErr);

        // [THEN] Location filters are correctly stored in the blob
        ProductionForecastName.Get(DemandForecastCard.Name.Value);
        Assert.AreEqual(ProductionForecastName.GetLocationFilterBlobAsText(), DemandForecastCard."Location Filter".Value, LocFilterBlobErr);

        // [WHEN] Forecast by locations is disabled
        DemandForecastCard."Forecast By Locations".SetValue(false);

        // [THEN] Location filter field is initialized
        Assert.AreEqual('', DemandForecastCard."Location Filter".Value, LocFilterNotInitErr);
        ProductionForecastName.Get(DemandForecastCard.Name.Value);
        Assert.AreEqual('', ProductionForecastName.GetLocationFilterBlobAsText(), LocFilterNotInitErr);
    end;

    [Test]
    [HandlerFunctions('ItemFilterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastVariantFilter()
    var
        ProductionForecastName: Record "Production Forecast Name";
        Item1: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Variant1_1: Record "Item Variant";
        Variant1_2: Record "Item Variant";
        Variant1_3: Record "Item Variant";
        Variant2_1: Record "Item Variant";
        DemandForecastCard: TestPage "Demand Forecast Card";
        VariantCount: Dictionary of [Text, Integer];
        ItemCount: Dictionary of [Text, Integer];
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Check Variant filters and verify if the matrix contains appropriate records.

        // [GIVEN] Item1 with 3 variants, Item 2 with 1 variant, and Item 3 with 0 variants and Demand Forecast
        Initialize();
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateItem(Item3);
        LibraryInventory.CreateVariant(Variant1_1, Item1);
        LibraryInventory.CreateVariant(Variant1_2, Item1);
        LibraryInventory.CreateVariant(Variant1_3, Item1);
        LibraryInventory.CreateVariant(Variant2_1, Item2);

        CreateDemandForecastCard(DemandForecastCard);

        // [THEN] Location and Variant column stays hidden in demand forecast matrix.
        Assert.IsFalse(DemandForecastCard.Matrix."Location Code".Visible(), ForecastByLocErr);
        Assert.IsFalse(DemandForecastCard.Matrix."Variant Code".Visible(), ForecastByVariantErr);

        // [WHEN] Forecast by Variants is checked.
        DemandForecastCard."Forecast By Variants".SetValue(true);

        // [THEN] Variant column is shown in the forecast matrix.
        Assert.IsFalse(DemandForecastCard.Matrix."Location Code".Visible(), ForecastByLocErr);
        Assert.IsTrue(DemandForecastCard.Matrix."Variant Code".Visible(), ForecastByVariantErr);

        // [WHEN] The items are filtered using the created items
        LibraryVariableStorage.Enqueue(Item1."No." + '|' + Item2."No." + '|' + Item3."No.");
        DemandForecastCard."Item Filter".Drilldown();
        DemandForecastCard.Description.SetValue('Items are filtered'); // Matrix in the test is not refreshed without performing an UI interaction after drill down.

        // [THEN] The forecast matrix should consist of number of items with all variants + number of items without variant.
        CountDemandForecastRows(DemandForecastCard, ItemCount, DemandForecastCard.Matrix."No.".Caption);
        CountDemandForecastRows(DemandForecastCard, VariantCount, DemandForecastCard.Matrix."Variant Code".Caption);
        Assert.AreEqual(3, ItemCount.Get(Item1."No."), VariantFilterErr);
        Assert.AreEqual(1, ItemCount.Get(Item2."No."), VariantFilterErr);
        Assert.AreEqual(1, ItemCount.Get(Item3."No."), VariantFilterErr);

        Assert.AreEqual(1, VariantCount.Get(Variant1_1.Code), VariantFilterErr);
        Assert.AreEqual(1, VariantCount.Get(Variant1_2.Code), VariantFilterErr);
        Assert.AreEqual(1, VariantCount.Get(Variant1_3.Code), VariantFilterErr);
        Assert.AreEqual(1, VariantCount.Get(Variant2_1.Code), VariantFilterErr);

        // [WHEN] The variants are filtered
        DemandForecastCard."Variant Filter".SetValue(Variant1_1."Code" + '|' + Variant1_3."Code" + '|' + Variant2_1."Code");

        // [THEN] The forecast matrix should consist of items with filtered variants.
        Clear(ItemCount);
        Clear(VariantCount);
        CountDemandForecastRows(DemandForecastCard, ItemCount, DemandForecastCard.Matrix."No.".Caption);
        CountDemandForecastRows(DemandForecastCard, VariantCount, DemandForecastCard.Matrix."Variant Code".Caption);
        Assert.AreEqual(2, ItemCount.Get(Item1."No."), VariantFilterErr);
        Assert.AreEqual(1, ItemCount.Get(Item2."No."), VariantFilterErr);
        Assert.IsFalse(ItemCount.ContainsKey(Item3."No."), VariantFilterErr);

        Assert.AreEqual(1, VariantCount.Get(Variant1_1.Code), VariantFilterErr);
        Assert.IsFalse(VariantCount.ContainsKey(Variant1_2.Code), VariantFilterErr);
        Assert.AreEqual(1, VariantCount.Get(Variant1_3.Code), VariantFilterErr);
        Assert.AreEqual(1, VariantCount.Get(Variant2_1.Code), VariantFilterErr);
        Assert.AreEqual(3, VariantCount.Count, VariantFilterErr);

        // [THEN] Variant filters are correctly stored in the blob
        ProductionForecastName.Get(DemandForecastCard.Name.Value);
        Assert.AreEqual(ProductionForecastName.GetVariantFilterBlobAsText(), DemandForecastCard."Variant Filter".Value, VariantFilterBlobErr);

        // [WHEN] Forecast by locations is disabled
        DemandForecastCard."Forecast By Variants".SetValue(false);

        // [THEN] Location filter field is initialized
        Assert.AreEqual('', DemandForecastCard."Variant Filter".Value, VarFilterNotInitErr);
        ProductionForecastName.Get(DemandForecastCard.Name.Value);
        Assert.AreEqual('', ProductionForecastName.GetVariantFilterBlobAsText(), VarFilterNotInitErr);

    end;

    [Test]
    [HandlerFunctions('ItemFilterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastItemVariantAndLocFilter()
    var
        Item1: Record Item;
        Item2: Record Item;
        Variant1_1: Record "Item Variant";
        Variant1_2: Record "Item Variant";
        Variant1_3: Record "Item Variant";
        Location1: Record Location;
        Location2: Record Location;
        DemandForecastCard: TestPage "Demand Forecast Card";
        LocationCount: Dictionary of [Text, Integer];
        VariantCount: Dictionary of [Text, Integer];
        ItemCount: Dictionary of [Text, Integer];
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Check forecast by variant, forecast by locations and verify if the matrix contains appropriate records.

        // [GIVEN] Item1 with 3 variants, Item 2 with 0 variant, 2 locations and a Demand Forecast
        Initialize();
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);
        LibraryInventory.CreateVariant(Variant1_1, Item1);
        LibraryInventory.CreateVariant(Variant1_2, Item1);
        LibraryInventory.CreateVariant(Variant1_3, Item1);

        LibraryWarehouse.CreateLocation(Location1);
        LibraryWarehouse.CreateLocation(Location2);

        CreateDemandForecastCard(DemandForecastCard);

        // [GIVEN] Forecast by Variants and Forecast by Location is checked.
        DemandForecastCard."Forecast By Variants".SetValue(true);
        DemandForecastCard."Forecast By Locations".SetValue(true);

        // [THEN] Variant and Location columns are shown in the forecast matrix.
        Assert.IsTrue(DemandForecastCard.Matrix."Variant Code".Visible(), ForecastByLocVarErr);
        Assert.IsTrue(DemandForecastCard.Matrix."Location Code".Visible(), ForecastByLocVarErr);

        // [WHEN] The items are filtered using the created items
        LibraryVariableStorage.Enqueue(Item1."No." + '|' + Item2."No.");
        DemandForecastCard."Item Filter".Drilldown();

        // [WHEN] Location is filtered to given locations
        DemandForecastCard."Location Filter".SetValue(Location1.Code + '|' + Location2.Code);

        // [THEN] The forecast matrix should consist of (number of items with all variants + number of items without variants) x (number of locations).
        CountDemandForecastRows(DemandForecastCard, ItemCount, DemandForecastCard.Matrix."No.".Caption);
        CountDemandForecastRows(DemandForecastCard, VariantCount, DemandForecastCard.Matrix."Variant Code".Caption);
        CountDemandForecastRows(DemandForecastCard, LocationCount, DemandForecastCard.Matrix."Location Code".Caption);

        Assert.AreEqual(6, ItemCount.Get(Item1."No."), ItemLocVarFilterErr);
        Assert.AreEqual(2, ItemCount.Get(Item2."No."), ItemLocVarFilterErr);

        Assert.AreEqual(4, LocationCount.Get(Location1.Code), ItemLocVarFilterErr);
        Assert.AreEqual(4, LocationCount.Get(Location2.Code), ItemLocVarFilterErr);

        Assert.AreEqual(2, VariantCount.Get(Variant1_1.Code), ItemLocVarFilterErr);
        Assert.AreEqual(2, VariantCount.Get(Variant1_2.Code), ItemLocVarFilterErr);
        Assert.AreEqual(2, VariantCount.Get(Variant1_3.Code), ItemLocVarFilterErr);
        Assert.AreEqual(2, VariantCount.Get(''), ItemLocVarFilterErr);

        // [WHEN] The variants are filtered
        DemandForecastCard."Variant Filter".SetValue(Variant1_1."Code" + '|' + Variant1_3."Code");

        // [THEN] The forecast matrix should consist of items with filtered variants.
        Clear(ItemCount);
        Clear(VariantCount);
        Clear(LocationCount);
        CountDemandForecastRows(DemandForecastCard, ItemCount, DemandForecastCard.Matrix."No.".Caption);
        CountDemandForecastRows(DemandForecastCard, VariantCount, DemandForecastCard.Matrix."Variant Code".Caption);
        CountDemandForecastRows(DemandForecastCard, LocationCount, DemandForecastCard.Matrix."Location Code".Caption);

        Assert.AreEqual(4, ItemCount.Get(Item1."No."), ItemLocVarFilterErr);
        Assert.IsFalse(ItemCount.ContainsKey(Item2."No."), ItemLocVarFilterErr);

        Assert.AreEqual(2, LocationCount.Get(Location1.Code), ItemLocVarFilterErr);
        Assert.AreEqual(2, LocationCount.Get(Location2.Code), ItemLocVarFilterErr);

        Assert.AreEqual(2, VariantCount.Get(Variant1_1.Code), ItemLocVarFilterErr);
        Assert.IsFalse(VariantCount.ContainsKey(Variant1_2.Code), ItemLocVarFilterErr);
        Assert.AreEqual(2, VariantCount.Get(Variant1_3.Code), ItemLocVarFilterErr);
        Assert.IsFalse(VariantCount.ContainsKey(''), ItemLocVarFilterErr);
        Assert.AreEqual(2, VariantCount.Count, ItemLocVarFilterErr);

        // [WHEN] The variants are filtered with blank filter.
        DemandForecastCard."Variant Filter".SetValue('''''');

        // [THEN] The forecast matrix should consist of items with filtered variants.
        Clear(ItemCount);
        Clear(VariantCount);
        Clear(LocationCount);
        CountDemandForecastRows(DemandForecastCard, ItemCount, DemandForecastCard.Matrix."No.".Caption);
        CountDemandForecastRows(DemandForecastCard, VariantCount, DemandForecastCard.Matrix."Variant Code".Caption);
        CountDemandForecastRows(DemandForecastCard, LocationCount, DemandForecastCard.Matrix."Location Code".Caption);

        Assert.IsFalse(ItemCount.ContainsKey(Item1."No."), ItemLocVarFilterErr);
        Assert.AreEqual(2, ItemCount.Get(Item2."No."), ItemLocVarFilterErr);

        Assert.AreEqual(1, LocationCount.Get(Location1.Code), ItemLocVarFilterErr);
        Assert.AreEqual(1, LocationCount.Get(Location2.Code), ItemLocVarFilterErr);

        Assert.IsFalse(VariantCount.ContainsKey(Variant1_1.Code), ItemLocVarFilterErr);
        Assert.IsFalse(VariantCount.ContainsKey(Variant1_2.Code), ItemLocVarFilterErr);
        Assert.IsFalse(VariantCount.ContainsKey(Variant1_3.Code), ItemLocVarFilterErr);
        Assert.AreEqual(2, VariantCount.Get(''), ItemLocVarFilterErr);
        Assert.AreEqual(1, VariantCount.Count, ItemLocVarFilterErr);
    end;

    [Test]
    [HandlerFunctions('ItemFilterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastMatrixFlowFieldsSetQtyFirst()
    var
        Item1: Record Item;
        Variant1_1: Record "Item Variant";
        Location1: Record Location;
        DemandForecastCard: TestPage "Demand Forecast Card";
        PeriodType: Enum "Analysis Period Type";
        WorkYear: Integer;
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Check demand forecast matrix flow fields when quantities are entered first and then forecast by location and variants are set.

        // [GIVEN] Item1 with 1 variants, 1 location, Demand Forecast.
        Initialize();
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateVariant(Variant1_1, Item1);

        LibraryWarehouse.CreateLocation(Location1);

        CreateDemandForecastCard(DemandForecastCard);

        // [GIVEN] Forecast by Variants and Forecast by Location is checked and view by is set to day.
        DemandForecastCard."View By".SetValue(PeriodType::Day);

        // [GIVEN] Set the date filter for the scenario 01-Jan-yyyy.
        WorkYear := Date2DMY(WorkDate(), 3);
        DemandForecastCard."Date Filter".SetValue(Format(DMY2Date(1, 1, WorkYear)));

        // [GIVEN] The items are filtered using the created item
        LibraryVariableStorage.Enqueue(Item1."No.");
        DemandForecastCard."Item Filter".Drilldown();

        // [GIVEN] Quantity is entered for the Item and Date 01-Jan-yyyy. 
        DemandForecastCard.Matrix.First();
        DemandForecastCard.Matrix.Field1.SetValue(LibraryRandom.RandInt(1000));

        // [WHEN] Forecast by Variants is enabled
        DemandForecastCard."Forecast By Variants".SetValue(true);

        // [THEN] The field1 of the forecast matrix should be not contain any value as the quantity was set for the item irrespective of any variants.
        DemandForecastCard.Matrix.First();
        Assert.AreEqual(0, DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);
        while DemandForecastCard.Matrix.Next() do
            Assert.AreEqual(0, DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);

        // [WHEN] Forecast by Location is enabled
        DemandForecastCard."Forecast By Locations".SetValue(true);

        // [THEN] The field1 of the forecast matrix should be not contain any value as the quantity was set for the item irrespective of any locations.
        DemandForecastCard.Matrix.First();
        Assert.AreEqual(0, DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);
        while DemandForecastCard.Matrix.Next() do
            Assert.AreEqual(0, DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);
    end;

    [Test]
    [HandlerFunctions('ItemFilterRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastMatrixFlowFieldsSetQtyLast()
    var
        Item1: Record Item;
        Variant1_1: Record "Item Variant";
        Variant1_2: Record "Item Variant";
        Location1: Record Location;
        Location2: Record Location;
        DemandForecastCard: TestPage "Demand Forecast Card";
        PeriodType: Enum "Analysis Period Type";
        WorkYear: Integer;
        QuantityToEnter: array[4] of Integer;
        Index: Integer;

    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Check demand forecast matrix flow fields when forecast by location and variants are first set and then quantities are entered.

        // [GIVEN] Item1 with 2 variants, 2 locations, Demand Forecast and quantities for the forecasted items.
        Initialize();
        for Index := 1 to 4 do
            QuantityToEnter[Index] := LibraryRandom.RandInt(1000);
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateVariant(Variant1_1, Item1);
        LibraryInventory.CreateVariant(Variant1_2, Item1);

        LibraryWarehouse.CreateLocation(Location1);
        LibraryWarehouse.CreateLocation(Location2);

        CreateDemandForecastCard(DemandForecastCard);

        // [GIVEN] Forecast by Variants and Forecast by Location is checked and view by is set to day.
        DemandForecastCard."Forecast By Variants".SetValue(true);
        DemandForecastCard."Forecast By Locations".SetValue(true);
        DemandForecastCard."View By".SetValue(PeriodType::Day);

        // [GIVEN] Set the date filter for the scenario 01-Jan-yyyy to 02-Jan-yyyy.
        WorkYear := Date2DMY(WorkDate(), 3);
        DemandForecastCard."Date Filter".SetValue(Format(DMY2Date(1, 1, WorkYear)) + '..' + Format(DMY2Date(2, 1, WorkYear)));

        // [GIVEN] The items are filtered using the created item
        LibraryVariableStorage.Enqueue(Item1."No.");
        DemandForecastCard."Item Filter".Drilldown();

        // [WHEN] Quantity is entered for different combinations of Item, Location and Variants 
        DemandForecastCard.Matrix.First();
        DemandForecastCard.Matrix.Field1.SetValue(QuantityToEnter[1]);
        DemandForecastCard.Matrix.Field2.SetValue(QuantityToEnter[2]);
        DemandForecastCard.Matrix.Next();
        DemandForecastCard.Matrix.Field1.SetValue(QuantityToEnter[3]);
        DemandForecastCard.Matrix.Field2.SetValue(QuantityToEnter[4]);

        // [WHEN] View by is changed to year
        DemandForecastCard."View By".SetValue(PeriodType::Year);

        // [THEN] Only field1 of the forecast matrix should be visible and the two rows should be summed.
        DemandForecastCard.Matrix.First();
        Assert.IsFalse(DemandForecastCard.Matrix.Field2.Visible(), CaptionErr);

        Assert.AreEqual(QuantityToEnter[1] + QuantityToEnter[2], DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);
        DemandForecastCard.Matrix.Next();
        Assert.AreEqual(QuantityToEnter[3] + QuantityToEnter[4], DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);

        // [GIVEN] View by is changed back to day
        DemandForecastCard."View By".SetValue(PeriodType::Day);

        // [WHEN] Forecast by Variants is disabled
        DemandForecastCard."Forecast By Variants".SetValue(false);

        // [THEN] The field1 and field2 of the forecast matrix should be visible and the two rows be same as initial values from the first insertion.
        DemandForecastCard.Matrix.First();
        Assert.IsTrue(DemandForecastCard.Matrix.Field1.Visible(), CaptionErr);
        Assert.IsTrue(DemandForecastCard.Matrix.Field2.Visible(), CaptionErr);
        Assert.AreEqual(QuantityToEnter[1], DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);
        Assert.AreEqual(QuantityToEnter[2], DemandForecastCard.Matrix.Field2.AsInteger(), FlowFieldErr);
        DemandForecastCard.Matrix.Next();
        Assert.AreEqual(QuantityToEnter[3], DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);
        Assert.AreEqual(QuantityToEnter[4], DemandForecastCard.Matrix.Field2.AsInteger(), FlowFieldErr);

        // [WHEN] Forecast by Location is disabled
        DemandForecastCard."Forecast By Locations".SetValue(false);

        // [THEN] The rows should be collapsed to one by summing up the values.
        DemandForecastCard.Matrix.First();
        Assert.AreEqual(QuantityToEnter[1] + QuantityToEnter[3], DemandForecastCard.Matrix.Field1.AsInteger(), FlowFieldErr);
        Assert.AreEqual(QuantityToEnter[2] + QuantityToEnter[4], DemandForecastCard.Matrix.Field2.AsInteger(), FlowFieldErr);
        Assert.IsFalse(DemandForecastCard.Matrix.Next(), ItemLocVarFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FilterOnDemandForecastMatrix()
    var
        Item1: Record Item;
        Item2: Record Item;
        DemandForecastCard: TestPage "Demand Forecast Card";
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Check filtering on Demand Forecast Matrix columns can provide expected results.

        // [GIVEN] 2 Items and a Demand Forecast
        Initialize();
        LibraryInventory.CreateItem(Item1);
        LibraryInventory.CreateItem(Item2);

        CreateDemandForecastCard(DemandForecastCard);

        // [WHEN] The items are filtered to the created item using Demand Forecast Matrix "Item No" column.
        DemandForecastCard.Matrix.First();
        DemandForecastCard.Matrix.Filter.SetFilter("No.", Item1."No.");

        // [THEN] Only Item1 should be visible in the forecast matrix.
        DemandForecastCard.Matrix.First();
        Assert.AreEqual(Item1."No.", DemandForecastCard.Matrix."No.".Value, ItemShouldExistErr);
        Assert.IsFalse(DemandForecastCard.Matrix.Next(), ItemFilterErr);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Demand Forecast Variant Matrix", 'OnGetMaxRowsToLoad', '', false, false)]
    local procedure SetMaxRowsToLoadRand1To5(var MaxRowsToLoad: Integer)
    begin
        MaxRowsToLoad := LibraryRandom.RandIntInRange(1, 5);
    end;

    [Test]
    [HandlerFunctions('MatrixRowLimitMessageHandler')]
    [Scope('OnPrem')]
    procedure DemandForecastMatrixRowLimitMessage()
    var
        Item: Record Item;
        SCMProdOrders: Codeunit "SCM Production Orders";
        DemandForecastCard: TestPage "Demand Forecast Card";
        Index: Integer;
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Warn the users when exceeding row limit and allow them to set the filter the result further.

        // [GIVEN] Row limit is between 1 to 5 but there are 6 Items
        Initialize();
        for Index := 1 to 6 do
            LibraryInventory.CreateItem(Item);

        // [WHEN] Creating a demand forecast and max rows is updated in subscribing event SetMaxRowsToLoadRand1To5
        BindSubscription(SCMProdOrders);
        CreateDemandForecastCard(DemandForecastCard);

        // [THEN] Warn the user about the row limit.
        // Checked in MatrixRowLimitMessageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionForecastWithPeriodTypeDay()
    var
        PeriodTypeEnum: Enum "Analysis Period Type";
    begin
        // Setup.
        Initialize();
        CheckPeriodSettingsInDemandForecastMatrix(PeriodTypeEnum::Day);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionForecastWithPeriodTypeWeek()
    var
        PeriodTypeEnum: Enum "Analysis Period Type";
    begin
        // Setup.
        Initialize();
        CheckPeriodSettingsInDemandForecastMatrix(PeriodTypeEnum::Week);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionForecastWithPeriodTypeMonth()
    var
        PeriodTypeEnum: Enum "Analysis Period Type";
    begin
        // Setup.
        Initialize();
        CheckPeriodSettingsInDemandForecastMatrix(PeriodTypeEnum::Month);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionForecastWithPeriodTypeQuarter()
    var
        PeriodTypeEnum: Enum "Analysis Period Type";
    begin
        // Setup.
        Initialize();
        CheckPeriodSettingsInDemandForecastMatrix(PeriodTypeEnum::Quarter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionForecastWithPeriodTypeYear()
    var
        PeriodTypeEnum: Enum "Analysis Period Type";
    begin
        // Setup.
        Initialize();
        CheckPeriodSettingsInDemandForecastMatrix(PeriodTypeEnum::Year);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandForecastCardSetPositionActions()
    var
        PeriodType: Enum "Analysis Period Type";
        DemandForecastCard: TestPage "Demand Forecast Card";
        WorkYear: Integer;
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Check the position actions like next and previous in demand forecast card.

        // [GIVEN] Created Demand Forecast
        Initialize();
        CreateDemandForecastCard(DemandForecastCard);
        WorkYear := Date2DMY(WorkDate(), 3);

        // [WHEN] View by in demand forecast card is changed to Year.
        DemandForecastCard."View By".SetValue(PeriodType::Year);

        // [THEN] The first column caption is set to WorkDate year
        Assert.AreEqual(Format(WorkYear), DemandForecastCard.Matrix.Field1.Caption, CaptionErr);

        // [WHEN] Action: Next Column
        DemandForecastCard."Next Column".Invoke();

        // [THEN] The first column caption is set to WorkDate year + 1.
        Assert.AreEqual(Format(WorkYear + 1), DemandForecastCard.Matrix.Field1.Caption, CaptionErr);

        // [WHEN] Action: Previous Column
        DemandForecastCard."Previous Column".Invoke();

        // [THEN] The first column caption is set to WorkDate year.
        Assert.AreEqual(Format(WorkYear), DemandForecastCard.Matrix.Field1.Caption, CaptionErr);

        // [WHEN] Action: Next Set
        DemandForecastCard."Next Set".Invoke();

        // [THEN] The first column caption is set to WorkDate year + 32.
        Assert.AreEqual(Format(WorkYear + 32), DemandForecastCard.Matrix.Field1.Caption, CaptionErr);

        // [WHEN] Action: Previous Set
        DemandForecastCard."Previous Set".Invoke();

        // [THEN] The first column caption is set to WorkDate year.
        Assert.AreEqual(Format(WorkYear), DemandForecastCard.Matrix.Field1.Caption, CaptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandForecastCheckDateFilter()
    var
        PeriodType: Enum "Analysis Period Type";
        DemandForecastCard: TestPage "Demand Forecast Card";
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Date filter should be respected in the demand forecast matrix.

        // [GIVEN] Created Demand Forecast with WorkDate to +1 day as a date filter.
        Initialize();
        CreateDemandForecastCard(DemandForecastCard);
        DemandForecastCard."Date Filter".SetValue(Format(WorkDate()) + '..' + Format(CalcDate('<+1D>', WorkDate())));

        // [WHEN] View by in demand forecast card is set to day.
        DemandForecastCard."View By".SetValue(PeriodType::Day);

        // [THEN] The first two columns are visible and rest are hidden.
        Assert.AreEqual(Format(WorkDate()), DemandForecastCard.Matrix.Field1.Caption, CaptionErr);
        Assert.AreEqual(Format(CalcDate('<+1D>', WorkDate())), DemandForecastCard.Matrix.Field2.Caption, CaptionErr);
        Assert.IsFalse(DemandForecastCard.Matrix.Field3.Visible(), CaptionErr);
        Assert.IsFalse(DemandForecastCard.Matrix.Field10.Visible(), CaptionErr);
        Assert.IsFalse(DemandForecastCard.Matrix.Field32.Visible(), CaptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionForecastWithPeriodTypeAccountingPeriod()
    var
        PeriodTypeEnum: Enum "Analysis Period Type";
    begin
        // Setup.
        Initialize();
        CheckPeriodSettingsInDemandForecastMatrix(PeriodTypeEnum::"Accounting Period");
    end;

    local procedure CheckPeriodSettingsInDemandForecastMatrix(PeriodType: Enum "Analysis Period Type")
    var
        MatrixRecords: array[32] of Record Date;
        MatrixManagement: Codeunit "Matrix Management";
        ProductionForecast: TestPage "Demand Forecast Card";
        MatrixColumnCaptions: array[32] of Text[80];
        ColumnSet: Text;
        SetPosition: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        PrimaryKeyFirstRecordInCurrentSet: Text;
        CurrentSetLength: Integer;
    begin
        // Using Matrix Management to Generate Period Matrix Data.
        MatrixManagement.GeneratePeriodMatrixData(
          SetPosition, ArrayLen(MatrixRecords), false, PeriodType, '', PrimaryKeyFirstRecordInCurrentSet, MatrixColumnCaptions, ColumnSet,
          CurrentSetLength, MatrixRecords);

        // Create and Open Production Forecast Page.
        CreateDemandForecastCard(ProductionForecast);

        // Exercise: Set Period Type on Production Forecast Page. Using Page Testability for Matrix Page.
        ProductionForecast."View By".SetValue(PeriodType);

        // Verify: Verify Column Captions on Production Forecast Matrix Page.
        Assert.AreEqual(MatrixColumnCaptions[1], ProductionForecast.Matrix.Field1.Caption, CaptionErr);
        Assert.AreEqual(MatrixColumnCaptions[2], ProductionForecast.Matrix.Field2.Caption, CaptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandForecastMatrixFieldsNotEditable()
    var
        DemandForecastCard: TestPage "Demand Forecast Card";
    begin
        // [FEATURE] [Demand Forecast with Variant and Location]
        // [SCENARIO] Item No, Description, location and variant code should not be editable.

        // [GIVEN] Create Demand Forecast.
        Initialize();
        CreateDemandForecastCard(DemandForecastCard);

        // [WHEN] Forecast by location and forecast by variant is turned on.
        DemandForecastCard."Forecast By Locations".SetValue(true);
        DemandForecastCard."Forecast By Variants".SetValue(true);

        // [THEN] Item No, Description, Location code and Variant code is not editable
        Assert.IsFalse(DemandForecastCard.Matrix."No.".Editable(), EditableErr);
        Assert.IsFalse(DemandForecastCard.Matrix.Description.Editable(), EditableErr);
        Assert.IsFalse(DemandForecastCard.Matrix."Location Code".Editable(), EditableErr);
        Assert.IsFalse(DemandForecastCard.Matrix."Variant Code".Editable(), EditableErr);
    end;

    [Test]
    [HandlerFunctions('OrderPlanningPageHandler')]
    [Scope('OnPrem')]
    procedure OrderPlanningForReleasedProductionOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        // Setup. Create Items, Production BOM, Released Production Order and Calculate Order Plan. Create Released Production Order.
        Initialize();
        CreateProductionItemSetup(Item);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Create and Open Released Production Order Page. Page required for verification.
        CreateAndOpenReleasedProductionOrder(ReleasedProductionOrder, Item."No.");
        LibraryVariableStorage.Enqueue(ReleasedProductionOrder."No.".Value);  // Enqueue value for Page Handler - OrderPlanningPageHandler.

        // Exercise and Verify: Calculate Order Plan from Released Production Order Page. Verify Value on Page Handler - OrderPlanningPageHandler.
        // After Calculating Order Planning, Cursor points to selected Production Order Line.
        ReleasedProductionOrder.Planning.Invoke();
    end;

    [Test]
    [HandlerFunctions('ReservationDetailPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationFromSalesOrderUsingProductionOrderWithDifferentVariantCode()
    begin
        // Setup.
        Initialize();
        ReservationFromSalesOrderUsingProductionOrderWithVariantCode(false);  // Same Variant Code On Sales And Production as False.
    end;

    [Test]
    [HandlerFunctions('ReservationDetailPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationFromSalesOrderUsingProductionOrderWithSameVariantCode()
    begin
        // Setup.
        Initialize();
        ReservationFromSalesOrderUsingProductionOrderWithVariantCode(true);  // Same Variant Code On Sales And Production as True.
    end;

    local procedure ReservationFromSalesOrderUsingProductionOrderWithVariantCode(SameVariantCodeOnSalesAndProduction: Boolean)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Production Item and Item Variant. Create Released Production Order with Variant Code.
        CreateProductionItemSetup(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateVariantCodeOnProdOrderLine(ProductionOrder, ItemVariant.Code);

        // Create Sales Order with Variant Code.
        if SameVariantCodeOnSalesAndProduction then
            CreateSalesOrderWithVariantCode(SalesHeader, SalesLine, Item."No.", ItemVariant.Code, ProductionOrder.Quantity)
        else
            CreateSalesOrderWithVariantCode(SalesHeader, SalesLine, Item."No.", ItemVariant2.Code, ProductionOrder.Quantity);

        // Exercise and Verify: Open Reservation form Sales Order. Verify Reservation Quantities through Page Handler - ReservationDetailPageHandler.
        if SameVariantCodeOnSalesAndProduction then
            ReservationFromSalesOrder(SalesLine, ProductionOrder.Quantity, 0) // Total Reserved Quantity as Zero.
        else
            ReservationFromSalesOrder(SalesLine, 0, 0);  // Total Quantity and Total Reserved Quantity as Zero.
    end;

    [Test]
    [HandlerFunctions('ReservationDetailPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationFromMultipleSalesOrderUsingProductionOrder()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
    begin
        // Setup: Create Production Item and Item Variant. Create Released Production Order with Variant Code.
        Initialize();
        CreateProductionItemSetup(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2) + 10);  // Large Random Value required.
        UpdateVariantCodeOnProdOrderLine(ProductionOrder, ItemVariant.Code);

        // Create Sales Order with Variant Code and Reserve Quantity.
        CreateSalesOrderWithVariantCode(SalesHeader, SalesLine, Item."No.", ItemVariant.Code, ProductionOrder.Quantity / 2);  // Partial Quantity.
        LibraryVariableStorage.Enqueue(true);  // Enqueue value for Page Handler - ReservationDetailPageHandler.
        SalesLine.ShowReservation();  // Open Reservation Page through Page Handler - ReservationDetailPageHandler.

        // Create Sales Order with Variant Code.
        CreateSalesOrderWithVariantCode(SalesHeader2, SalesLine2, Item."No.", ItemVariant.Code, ProductionOrder.Quantity / 2);  // Partial Quantity.

        // Exercise and Verify: Open Reservation form Sales Order. Verify Reservation Quantities through Page Handler - ReservationDetailPageHandler.
        ReservationFromSalesOrder(SalesLine2, ProductionOrder.Quantity, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationFromSalesOrderUsingPurchaseOrderPosting()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item. Create and Post Purchase Order and create Purchase Order again.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostPurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LibraryRandom.RandDec(10, 2));
        CreatePurchaseOrder(PurchaseHeader2, PurchaseLine2, Item."No.", LibraryRandom.RandDec(10, 2));

        // Create Sales Order.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", PurchaseLine.Quantity + PurchaseLine2.Quantity);
        UpdateShipmentDateOnSalesLine(SalesLine);

        // Exercise and Verify: Open Reservation form Sales Order. Verify Reservation Quantities through Page Handler - ReservationPageHandler.
        ReservationFromSalesOrderCurrentLine(SalesLine, PurchaseLine.Quantity, PurchaseLine2.Quantity);  // Verify on Page Handler - ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('SalesOrderPlanningPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningWithTrackedItem()
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item Tracking Code for SN Specific Tracking. Create Item and Sales Order.
        Initialize();
        CreateSalesOrderWithTrackedItemSetup(SalesLine);

        // Exercise and Verify: Open Sales Order Planning Page. Verify line on Page Handler SalesOrderPlanningPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."No.");  // Enqueue value for Verifying Item No on Planning Page.
        LibraryVariableStorage.Enqueue(-SalesLine.Quantity);  // Enqueue value for Verifying Available on Planning Page.
        OpenSalesOrderPlanning(SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlannedProductionOrderFromSalesOrderPlanningWithTrackedItem()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Item Tracking Code for SN Specific Tracking. Create Item and Sales Order.
        Initialize();
        CreateSalesOrderWithTrackedItemSetup(SalesLine);
        LibraryVariableStorage.Enqueue(FirmPlannedProdOrderCreatedTxt);  // Enqueue value for Message Handler.

        // Exercise: Create Firm Planned Production Order using Sales Order Planning.
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesLine."Document No.", SalesLine."No.");

        // Verify: Verify Created new Firm Planned Production Order.
        VerifyProductionOrderLine(ProductionOrder.Status, ProductionOrder."No.", SalesLine."No.", SalesLine.Quantity, '');
    end;

    [Test]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,MessageHandler,SerialItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure SerialNoTrackingOnProductionLineWithCalcRegenPlan()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Setup: Create Item Tracking Code for SN Specific Tracking. Create Item and Sales Order.
        Initialize();
        CreateSalesOrderWithTrackedItemSetup(SalesLine);

        // Create Firm Planned Production Order using Sales Order Planning and assign Tracking on Production Order Line.
        LibraryVariableStorage.Enqueue(FirmPlannedProdOrderCreatedTxt);  // Enqueue value for Message Handler.
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesLine."Document No.", SalesLine."No.");
        AssignTrackingOnProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        Item.Get(SalesLine."No.");

        // Exercise. Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify Tracking line on Production Order Line on Page Handler.
        ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        LibraryVariableStorage.Enqueue(false);  // Enqueue value AssignSerialNo as False for Page Handler - SerialItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);  // Enqueue value for Count the number of Tracking line in Tracking page in case of Serial Tracking for Page Handler.
        ProdOrderLine.OpenItemTrackingLines();  // Open Page Handler- SerialItemTrackingPageHandler for Verifying Tracking line.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure FlushingMethodForwardWithLotNoChangeProductionStatusToReleasedError()
    begin
        // [FEATURE] [Item Tracking] [Production Order]
        // [SCENARIO] Verify an error on release Production Order with Lot Tracked component Item, assigned Lot No in Prod Order, but insufficient Quantity in Tracking.

        // Setup.
        Initialize();
        FlushingMethodForwardWithLotNoTracking(true);  // Tracking on Production Order Component as True.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure FlushingMethodForwardWithoutTrackingOnProdOrderComponentLotNoError()
    begin
        // [FEATURE] [Item Tracking] [Production Order]
        // [SCENARIO] Verify an error on release Production Order with Lot Tracked component Item, but not assigned Lot No in Prod Order.

        // Setup.
        Initialize();
        FlushingMethodForwardWithLotNoTracking(false);  // Tracking on Production Order Component as False.
    end;

    local procedure FlushingMethodForwardWithLotNoTracking(TrackingOnProductionOrderComponent: Boolean)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
    begin
        // Create Item Tracking Code for Lot Specific and create Items. Create Production BOM.
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        UpdateFlushingMethodOnItem(Item, Item."Flushing Method"::Forward);

        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."No.", Item2."Base Unit of Measure");
        UpdateProductionBOMOnItem(Item2, ProductionBOMHeader."No.");

        // Update Item Inventory using Tracking.
        CreateAndPostItemJournalLineWithTracking(Item."No.", LibraryRandom.RandDec(10, 2));

        // Create Firm Planned Production Order.
        CreateAndRefreshFirmPlannedProductionOrder(ProductionOrder, Item2."No.", LibraryRandom.RandDec(10, 2) + 10);  // Using large random value more than inventory of the Child item.

        if TrackingOnProductionOrderComponent then
            TrackingOnProdOrderComponent(ProductionOrder, Item."No.");  // Add Tracking on Production Order Component line.

        // Exercise: Change Production Order Status Firm Planned to Released.
        asserterror LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status, ProductionOrder.Status::Released);

        // Verify: Verify error message when Change Production Order Status.
        if TrackingOnProductionOrderComponent then
            Assert.ExpectedError(QtyToHandleErr) // Assign tracking is less then Production Order Component Quantity.
        else
            Assert.ExpectedError(StrSubstNo(LotNoErr, Item."No."));  // Tracking is not assigned on Production Order Component.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMNotCertifiedAndRefreshReleasedProdOrderError()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdBOMHeader: Record "Production BOM Header";
    begin
        // Setup: Create Production Item.
        Initialize();
        ChildItem.Get(CreateProductionItemSetup(Item));

        // Create Child Production BOM with Status New and attached to Parent Production BOM and Recertify Parent BOM.
        UpdateProductionBOMAndRecertify(Item."Production BOM No.", Item."Base Unit of Measure", ChildItem."No.");

        // Exercise: Create and Refresh Released Production Order.
        asserterror CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Production BOM Status error message when Refresh Production Order.
        Assert.ExpectedTestFieldError(ProdBOMHeader.FieldCaption(Status), Format(ProdBOMHeader.Status::Certified));
    end;

    [Test]
    [HandlerFunctions('ConfirmQstHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ConsumptionPostingForFinishedProdOrderError()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Verify an error on Post Consumption Journal after Production Order Status Changed to Finished.

        // Setup: Create Production Item and Post Item Journal. Create and Refresh Released Production Order.
        Initialize();
        ChildItem.Get(CreateProductionItemSetup(Item));
        CreateAndPostItemJournalLine(ChildItem."No.");
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // Create Consumption Journal, Create and Post Output Journal.
        CreateConsumptionJournal(ProductionOrder."No.");
        CreateAndPostOutputJournal(ProductionOrder."No.");

        // Change Production Order Status Released to Finished.
        LibraryVariableStorage.Enqueue(ProductionOrderFinishedStatusMsg);  // Enqueue value for Message Handler.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");
        FindItemJournalLine(ItemJournalLine, ConsumptionItemJournalBatch."Journal Template Name", ConsumptionItemJournalBatch.Name);

        // Exercise: Post Consumption Journal after Production Order Status Changed to Finished.
        asserterror ItemJournalLine.PostingItemJnlFromProduction(false);  // Print as FALSE.

        // Verify: Verify Error message when post Consumption for Finished Production Order.
        Assert.ExpectedErrorCannotFind(Database::"Production Order");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateOrderFromSalesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderFromSalesOrderWithReplenishmentAsPurchaseOnSKUError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Setup: Create Item and Stockkeeping Unit with Replenishment System as Purchase.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateStockkeepingUnit(LocationBlue.Code, Item."No.", StockkeepingUnit."Replenishment System"::Purchase);

        // Create Sales Order, Update Location Code on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateLocationCodeOnSalesLine(SalesLine, LocationBlue.Code);
        LibraryVariableStorage.Enqueue(NothingToPlanMsg);   // Enqueue value for Message Handler.

        // Exercise: Create Production Order from Sales Order.
        asserterror LibraryManufacturing.CreateProdOrderUsingPlanning(
            ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesLine."Document No.", SalesLine."No.");

        // Verify: Verify Error message when Replenishment System as Purchase on SKU.
        Assert.ExpectedError(ProductionOrderNotExistErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CreateOrderFromSalesModalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderFromSalesOrderWithReplenishmentAsProdOrderOnSKU()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        // Setup: Create Item and Stockkeeping Unit with Replenishment System as Prod. Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateStockkeepingUnit(LocationBlue.Code, Item."No.", StockkeepingUnit."Replenishment System"::"Prod. Order");

        // Create Sales Order, Update Location Code on Sales Line.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateLocationCodeOnSalesLine(SalesLine, LocationBlue.Code);
        LibraryVariableStorage.Enqueue(FirmPlannedProdOrderCreatedTxt);  // Enqueue value for Message Handler.

        // Exercise: Create Production Order from Sales Order.
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesLine."Document No.", SalesLine."No.");

        // Verify: Verify Production Order Line when Replenishment System as Prod. Order on SKU.
        VerifyProductionOrderLine(
          ProductionOrder.Status, ProductionOrder."No.", SalesLine."No.", SalesLine.Quantity, SalesLine."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMWhereUsedWithProdBOMVersionCertified()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        ProdBOMWhereUsedWithProdBOMVersion(ProductionBOMVersion.Status::Certified);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMWhereUsedWithProdBOMVersionClosed()
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup.
        Initialize();
        ProdBOMWhereUsedWithProdBOMVersion(ProductionBOMVersion.Status::Closed);
    end;

    local procedure ProdBOMWhereUsedWithProdBOMVersion(ProdBOMVersionStatus: Enum "BOM Status")
    var
        ChildItem: Record Item;
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used";
        ProductionBOMVersion: Code[20];
    begin
        // Create Items and Item Hierarchy : Item -> ChildItem.
        ChildItem.Get(CreateProductionItemSetup(Item));
        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order");

        // Create Production BOM and new Item Hierarchies : Item2 -> Item and Item2 -> ChildItem. Create Production BOM Version and Update Status on Prod. BOM Version.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."No.", Item."Base Unit of Measure");
        UpdateProductionBOMOnItem(Item2, ProductionBOMHeader."No.");
        ProductionBOMVersion := CreateProductionBOMVersionAndUpdateStatus(ProductionBOMHeader, ChildItem."No.", ProdBOMVersionStatus);

        // Exercise: Open Production BOM Where Used Page.
        OpenProdBOMWhereUsedPage(ProdBOMWhereUsed, ChildItem);

        // Verify: Verify Nos of Lines, Version Code and Item No. on Production BOM Where Used Page.
        VerifyProdBOMWhereUsedPageVersion(ProdBOMWhereUsed, ProdBOMVersionStatus, Item2."No.", Item."No.", ProductionBOMVersion);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMWhereUsedWithProdBOMCertified()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Setup.
        Initialize();
        ProdBOMWhereUsedWithProdBOM(ProductionBOMHeader.Status::Certified);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ProdBOMWhereUsedWithProdBOMClosed()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Setup.
        Initialize();
        ProdBOMWhereUsedWithProdBOM(ProductionBOMHeader.Status::Closed);
    end;

    local procedure ProdBOMWhereUsedWithProdBOM(ProdBOMHeaderStatus: Enum "BOM Status")
    var
        ChildItem: Record Item;
        Item: Record Item;
        ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used";
    begin
        // Create Items and Item Hierarchy : Item -> ChildItem.
        ChildItem.Get(CreateProductionItemSetup(Item));
        UpdateProdBOMHeaderStatus(Item."Production BOM No.", ProdBOMHeaderStatus);

        // Exercise: Open Production BOM Where Used Page.
        OpenProdBOMWhereUsedPage(ProdBOMWhereUsed, ChildItem);

        // Verify: Verify Nos of Lines and Item No. on Production BOM Where Used Page.
        VerifyProdBOMWhereUsedPage(ProdBOMWhereUsed, ProdBOMHeaderStatus, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBOMWhereUsedFilterByItemNo()
    var
        ChildItem: Record Item;
        ParentItem: array[2] of Record Item;
        ProdBOMHeader: array[2] of Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used";
        I: Integer;
    begin
        // [FEATURE] [Production BOM] [Where Used]
        // [SCENARIO] "Production - Where Used" can be filtered by item no.

        // [GIVEN] Create a component item "CI" and two production BOMs that use this item
        LibraryInventory.CreateItem(ChildItem);
        // [GIVEN] Create two manufactured items "PI1" and "PI2" and assign each a BOM
        for I := 1 to 2 do begin
            CreateProductionBOM(ProdBOMHeader[I], ProdBOMLine, ChildItem."Base Unit of Measure", ProdBOMLine.Type::Item, ChildItem."No.");

            LibraryManufacturing.CreateItemManufacturing(
              ParentItem[I], ParentItem[I]."Costing Method"::Standard, 0, ParentItem[I]."Reordering Policy"::" ",
              ParentItem[I]."Flushing Method"::Backward, '', ProdBOMHeader[I]."No.");
        end;

        // [GIVEN] Run "Production - Where Used" report for the component item
        OpenProdBOMWhereUsedPage(ProdBOMWhereUsed, ChildItem);

        // [WHEN] Set filter in the "Where Used" page: "Item No." = "PI1"
        ProdBOMWhereUsed.FILTER.SetFilter("Item No.", ParentItem[1]."No.");

        // [THEN] Item "PI1" is displayed in the list, item "PI2" in not in the list
        ProdBOMWhereUsed.First();
        ProdBOMWhereUsed."Item No.".AssertEquals(ParentItem[1]."No.");
        Assert.IsFalse(ProdBOMWhereUsed.Next(), ItemMustNotBeShownErr);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionQuantityOnProdJournalWithLocationBlue()
    begin
        // Setup.
        Initialize();
        ConsumptionQuantityOnProdJournalWithLocation(LocationBlue.Code);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionQuantityOnProdJournalWithLocationSilver()
    begin
        // Setup.
        Initialize();
        ConsumptionQuantityOnProdJournalWithLocation(LocationSilver.Code);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionQuantityOnProdJournalWithLocationWhite()
    begin
        // Setup.
        Initialize();
        ConsumptionQuantityOnProdJournalWithLocation(LocationWhite.Code);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionQuantityOnProdJournalWithLocationGreen()
    begin
        // Setup.
        Initialize();
        ConsumptionQuantityOnProdJournalWithLocation(LocationGreen.Code);
    end;

    local procedure ConsumptionQuantityOnProdJournalWithLocation(LocationCode: Code[10])
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Create Production Item Setup. Create and Refresh Released Production Order with Location.
        ChildItem.Get(CreateProductionItemSetup(Item));
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, Item."No.", LocationCode);

        // Production Journal will contain values for Expected Quantity on Location Blue, Silver but will be Zero on Location White, Green.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        if LocationCode in [LocationBlue.Code, LocationSilver.Code] then begin
            FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ChildItem."No.");
            LibraryVariableStorage.Enqueue(ProdOrderComponent."Expected Quantity");  // Enqueue value of Quantity for ProductionJournalPageHandler Page Handler.
        end else
            LibraryVariableStorage.Enqueue(0);  // Enqueue value of Quantity for ProductionJournalPageHandler Page Handler.

        // Exercise and Verify: Open Production Journal page from Production Order and Verify Consumption Quantity on Page Handler ProductionJournalPageHandler.
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('PostUpdatedProdJournalPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostZeroQtyProdJournalWithLocationSilverAndEmptyBinCode()
    var
        ValueEntry: Record "Value Entry";
        SetupTime: Decimal;
        ProdOrderNo: Code[20];
    begin
        Initialize();

        // Exercise: Create Released Production Order of Silver location and post Production Journal with zero Output Quantity and empty Bin Code.
        // It should not check the Bin Code although Silver is bin mandatory, because we do not post actual inventory item.
        SetupTime := LibraryRandom.RandInt(100);
        ProdOrderNo := CreateAndPostProdJournalWithLocation(CreateItemWithRouting(), LocationSilver.Code, 0, SetupTime);

        // Verify: Verify the Value Entry to assure Production Journal is successfully posted.
        FindValueEntry(ValueEntry, ValueEntry."Item Ledger Entry Type"::" ", ProdOrderNo, ''); // Both Entry Type and Item No. are empty.
        Assert.AreEqual(SetupTime, ValueEntry."Valued Quantity", ValuedQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderComponentWithDiffRoutingLink()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLink: Record "Routing Link";
        RoutingLink2: Record "Routing Link";
        ChildItemNo: Code[20];
    begin
        // Setup: Create Routing Links. Create Production Item setup with Routing and Production BOM using Routing Link Code.
        Initialize();
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRoutingLink(RoutingLink2);
        ChildItemNo := CreateProductionItemsSetupWithRoutingLinkCode(Item, RoutingLink.Code, RoutingLink2.Code);

        // Exercise.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Production Order Component for Routing Link Code.
        VerifyProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", ChildItemNo, RoutingLink.Code);
        VerifyProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", ChildItemNo, RoutingLink2.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalForWorkAndMachineCenter()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLink: Record "Routing Link";
        RoutingLink2: Record "Routing Link";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Routing Links. Create Production Item setup with Routing and Production BOM using Routing Link Code.
        Initialize();
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRoutingLink(RoutingLink2);
        CreateProductionItemsSetupWithRoutingLinkCode(Item, RoutingLink.Code, RoutingLink2.Code);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Create Output Journal and Explode Routing.
        OutputJournalExplodeRouting(ItemJournalLine, ProductionOrder."No.");

        // Verify: Verify Output Journal Line for Type Machine Center and Work Center.
        VerifyOutputJournalLine(ItemJournalLine, ItemJournalLine.Type::"Machine Center", ProductionOrder.Quantity);
        VerifyOutputJournalLine(ItemJournalLine, ItemJournalLine.Type::"Work Center", ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingQuantityOnProdOrderComponentWithRoutingLink()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingLink: Record "Routing Link";
        RoutingLink2: Record "Routing Link";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        ChildItemNo: Code[20];
    begin
        // Setup: Create Routing Links. Create Production Item setup with Routing and Production BOM using Routing Link Code.
        Initialize();
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRoutingLink(RoutingLink2);
        ChildItemNo := CreateProductionItemsSetupWithRoutingLinkCode(Item, RoutingLink.Code, RoutingLink2.Code);

        // Update Inventory for Child item. Create and Refresh Released Production Order. Explode Routing and Delete line for Type as Machine Center.
        CreateAndPostItemJournalLine(ChildItemNo);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));
        OutputJournalExplodeRouting(ItemJournalLine, ProductionOrder."No.");

        ItemJournalLine.SetRange(Type, ItemJournalLine.Type::"Machine Center");
        ItemJournalLine.DeleteAll(true);

        // Exercise: Post Output Journal line.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Remaining Quantity on Production Order Component.
        VerifyProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", ChildItemNo, RoutingLink.Code);
        FindProdOrderComponentForRoutingLinkCode(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ChildItemNo, RoutingLink2.Code);
        ProdOrderComponent.TestField("Remaining Quantity", 0);  // Value required because Output Journal line Posted for Work Center.
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithTrackingUsingPurchaseUnitOfMeasure()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Setup: Create Item Tracking Code with LOT Specific. Create Items and Unit of Measure Code.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateTrackedItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ", false, 0, ItemTrackingCode.Code);  // Reorder Quantity as 0.
        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order");
        CreateAndUpdatePurchUnitOfMeasureOnItem(Item);

        // Exercise: Create and Post Purchase Order with Tracking.
        CreateAndPostPurchaseOrderWithItemTracking(Item."No.");

        // Verify: Verify Unit of Measure on Item Ledger Entry.
        VerifyItemLedgerEntry(Item."No.", Item."Purch. Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlannedProdOrderWithTrackingOnComponentAndChangeStatus()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Production Order] [Item Tracking]
        // [SCENARIO] Verify Status changed without error: Firm Planned to Released (with Tracking).

        // Setup: Create Item Tracking Code with LOT Specific. Create Items and Unit of Measure Code.
        Initialize();
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateTrackedItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ", false, 0, ItemTrackingCode.Code);  // Reorder Quantity as 0.
        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order");
        CreateAndUpdatePurchUnitOfMeasureOnItem(Item);

        // Create Production BOM and Update Unit of Measure Code on Production BOM Line. Create and Post Purchase Order and Create and Refresh Firm Planned Production with Tracking.
        CreateAndCertifyProductionBOMWithDiffUnitOfMeasureCode(
          ProductionBOMHeader, Item2."Base Unit of Measure", Item."No.", Item."Purch. Unit of Measure");
        UpdateProductionBOMOnItem(Item2, ProductionBOMHeader."No.");
        CreateAndPostPurchaseOrderWithItemTracking(Item."No.");
        CreateAndRefreshFirmPlannedProductionOrder(ProductionOrder, Item2."No.", LibraryRandom.RandDec(10, 2));
        TrackingOnProdOrderComponent(ProductionOrder, Item."No.");

        // Exercise: Change Status Firm Planned to Released.
        ProductionOrderNo :=
          LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status, ProductionOrder.Status::Released);

        // Verify: Verify Status changed without error and verify Released Production Order.
        VerifyReleasedProductionOrder(ProductionOrderNo, Item2."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderWithDimChangeStatusToFinished()
    var
        DimensionValue: Record "Dimension Value";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        DimValue1: Code[20];
        DimValue2: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [Dimension] [Production Order]
        // [SCENARIO] Verify Dimension on Production Order lines after change status - Released to Finished, Production Order having production Item with dimension, and Dimension updated on Order.

        // VSTF 324547.
        Initialize();

        // Setup. Create Production Item with dimension and update shortcut dimensions on Production Order Header.
        CreateProductionItemSetup(Item);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        DimValue1 := LibraryDimension.FindDifferentDimensionValue(LibraryERM.GetShortcutDimensionCode(1),
            ProductionOrder."Shortcut Dimension 1 Code");
        ProductionOrder.Validate("Shortcut Dimension 1 Code", DimValue1);

        DimValue2 := LibraryDimension.FindDifferentDimensionValue(LibraryERM.GetShortcutDimensionCode(2),
            ProductionOrder."Shortcut Dimension 2 Code");
        ProductionOrder.Validate("Shortcut Dimension 2 Code", DimValue2);
        ProductionOrder.Modify(true);
        DimSetID := ProductionOrder."Dimension Set ID";

        // Exercise: Change Status of the Production Order - Released To Finished.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // Verify: Verify Dimension on Production Order Line and Header.
        ProductionOrder.Get(ProductionOrder.Status::Finished, ProductionOrder."No.");
        ProductionOrder.TestField("Shortcut Dimension 1 Code", DimValue1);
        ProductionOrder.TestField("Shortcut Dimension 2 Code", DimValue2);
        ProductionOrder.TestField("Dimension Set ID", DimSetID);

        DimensionValue.Get(LibraryERM.GetShortcutDimensionCode(1), DimValue1);
        VerifyDimensionOnProductionOrderLine(ProductionOrder.Status, ProductionOrder."No.", DimensionValue);
        DimensionValue.Get(LibraryERM.GetShortcutDimensionCode(2), DimValue2);
        VerifyDimensionOnProductionOrderLine(ProductionOrder.Status, ProductionOrder."No.", DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimulatedProductionOrderChangeStatusToReleased()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO] Verify Expected Capacity Need on Production Order Routing Line after change Status - Simulated to Released.

        // Setup: Create Production Item setup with Routing and Production BOM. Create and Refresh Simulated Production Order.
        Initialize();
        CreateProductionItemsSetupWithRouting(Item);
        CreateAndRefreshSimulatedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Change Status of the Production Order - Simulated to Released.
        ProductionOrderNo := LibraryManufacturing.ChangeStatusSimulatedToReleased(ProductionOrder."No.");

        // Verify: Verify Expected Capacity Need on Production Order Routing Line.
        VerifyProductionOrderRoutingLine(ProductionOrderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SimulatedProductionOrderChangeStatusToFirmPlanned()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Routing] [Production Order]
        // [SCENARIO] Verify Expected Capacity Need on Production Order Routing Line after change Status - Simulated to Firm Planned.

        // Setup: Create Production Item setup with Routing and Production BOM. Create and Refresh Simulated Production Order.
        Initialize();
        CreateProductionItemsSetupWithRouting(Item);
        CreateAndRefreshSimulatedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // Exercise: Change Status of the Production Order - Simulated to Firm Planned.
        ProductionOrderNo := LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status::Simulated, ProductionOrder.Status::"Firm Planned");

        // Verify: Verify Expected Capacity Need on Production Order Routing Line.
        VerifyProductionOrderRoutingLine(ProductionOrderNo);
    end;

    [Test]
    [HandlerFunctions('PostProdJournalByPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateDimensionOnReleasedProdOrderLineByProdLine()
    begin
        DimensionOnReleasedProdOrder(UpdateDimensionMethod::ByProductionOrderLine);
    end;

    [Test]
    [HandlerFunctions('PostProdJournalByPageHandler,EditDimensionSetEntriesPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateDimensionOnReleasedProdOrderLineByShowDimensionsOnLine()
    begin
        DimensionOnReleasedProdOrder(UpdateDimensionMethod::ByShowDimensionsOnLine);
    end;

    [Test]
    [HandlerFunctions('PostProdJournalByPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure UpdateDimensionOnReleasedProdOrderLineByProdOrder()
    begin
        DimensionOnReleasedProdOrder(UpdateDimensionMethod::ByProductionOrder);
    end;

    local procedure DimensionOnReleasedProdOrder(UpdateDimensionFrom: Option)
    var
        ParentItem: Record Item;
        DimensionValue: Record "Dimension Value";
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ComponentItemNo: Code[20];
    begin
        // Setup: Create Production Item with dimension and update dimension on Production Order Line.
        Initialize();
        CreateItemAndReleasedProdOrderWithDimAndRouting(ParentItem, ProductionOrder, ComponentItemNo);

        // Exercise: Update the dimension. Open and Post the Production Journal.
        UpdateDimensionMethod := UpdateDimensionFrom;
        case UpdateDimensionMethod of
            UpdateDimensionMethod::ByProductionOrderLine:
                UpdateGlobalDimensionByProductionOrderLine(DimensionValue, ProductionOrder);
            UpdateDimensionMethod::ByShowDimensionsOnLine:
                UpdateGlobalDimensionByShowDimensionsOnLine(DimensionValue, ProductionOrder);
            UpdateDimensionMethod::ByProductionOrder:
                UpdateGlobalDimensionByProductionOrder(DimensionValue, ProductionOrder);
        end;
        PostProductionJournal(ProductionOrder);

        // Verify: Verify the dimension on the Item Ledger Entry for ParentItem and ComponentItem. Verify the dimension on the Prod. Order Component.
        VerifyDimensionOnItemLedgerEntry(ProductionOrder."No.", ParentItem."No.", ItemLedgerEntry."Entry Type"::Output, DimensionValue);
        VerifyDimensionOnItemLedgerEntry(ProductionOrder."No.", ComponentItemNo, ItemLedgerEntry."Entry Type"::Consumption, DimensionValue);
        VerifyDimensionOnProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", ComponentItemNo, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalWithRouting()
    begin
        OutputJournalAfterUpdateDimensionOnReleasedProdOrderLine(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalWithoutRouting()
    begin
        OutputJournalAfterUpdateDimensionOnReleasedProdOrderLine(false);
    end;

    local procedure OutputJournalAfterUpdateDimensionOnReleasedProdOrderLine(WithRouting: Boolean)
    var
        ParentItem: Record Item;
        DimensionValue: Record "Dimension Value";
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        ComponentItemNo: Code[20];
    begin
        // Setup: Create Production Item with dimension and update dimension on Production Order Line.
        Initialize();
        if WithRouting then
            CreateItemAndReleasedProdOrderWithDimAndRouting(ParentItem, ProductionOrder, ComponentItemNo)
        else
            CreateItemAndReleasedProdOrderWithDim(ParentItem, ProductionOrder);

        // Exercise: Update the dimension. Create and Explode Routing for Output Journal.
        UpdateGlobalDimensionByProductionOrderLine(DimensionValue, ProductionOrder);
        OutputJournalExplodeRouting(ItemJournalLine, ProductionOrder."No.");

        // Verify: Verify the dimension on Output Journal Line.
        VerifyDimensionOnOutputJournalLine(ItemJournalLine, ParentItem."No.", DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS358868_CapacityEntryPostingDoesNotRequireBin()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify that bin code is not checked on production output lines that post only capacity ledger entries, and not actual output
        Initialize();

        CreateProductionOrderOnLocationWithBin(ProductionOrder, ProdOrderLine);

        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 20, 0, ProdOrderLine.Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        VerifyCapacityEntryPosted(ProductionOrder."No.", ProductionOrder."Source No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS358868_OutputEntryPostingRequiresBin()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify that bin code is checked on the last production output line
        Initialize();

        CreateProductionOrderOnLocationWithBin(ProductionOrder, ProdOrderLine);

        CreateJournalLineLastOutput(ItemJournalLine, ProdOrderLine, '');

        asserterror LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        Assert.ExpectedErrorCannotFind(Database::Bin);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS358868_ConsumptionPostingWithBin()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Bin: Record Bin;
        Item: Record Item;
    begin
        // Verify that bin code is checked on the last production output line
        Initialize();

        CreateProductionOrderOnLocationWithBin(ProductionOrder, ProdOrderLine);
        UpdateFlushingMethodOnProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.");

        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');
        FindProdOrderComponentItem(Item, ProductionOrder.Status, ProductionOrder."No.");
        LibraryInventory.PostPositiveAdjustment(Item, LocationSilver.Code, '', Bin.Code, 1, WorkDate(), 0);
        PostConsumptionJournalLine(ProdOrderLine, Item, WorkDate(), LocationSilver.Code, Bin.Code, 1);

        VerifyItemLedgerEntryPosted(ProductionOrder."No.", Item."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TFS358868_OutputPostingWithBin()
    var
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify that bin code is checked on the last production output line
        Initialize();

        CreateProductionOrderOnLocationWithBin(ProductionOrder, ProdOrderLine);

        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');
        CreateJournalLineLastOutput(ItemJournalLine, ProdOrderLine, Bin.Code);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        VerifyItemLedgerEntryPosted(ProductionOrder."No.", ProductionOrder."Source No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineBinCopiedFromSalesLineWhenFromProdBinCodeBlank()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Production Order] [Warehouse]
        // [SCENARIO 361569] "Bin Code" in prod. order line is taken from Sales Line in the production order that uses sales order as a source and its location has blank "From-Production Bin Code"
        Initialize();

        // [GIVEN] Location X with "Bin Mandatory" and empty "From-Production Bin Code"
        // [GIVEN] Sales order with Location Code = X
        CreateSalesOrderWithLocation(SalesLine, LocationSilver.Code, LibraryUtility.GenerateGUID());

        // [GIVEN] Production order that uses sales order as a source, where Sales Line's "Bin Code" = "B"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::"Sales Header",
          SalesLine."Document No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Production order is refreshed
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Bin code in prod. order line is "B"
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
          SalesLine."Bin Code", ProdOrderLine."Bin Code",
          StrSubstNo(WrongFieldValueErr, ProdOrderLine.FieldCaption("Bin Code"), ProdOrderLine.TableCaption(), SalesLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineBinCopiedFromLocationIfPickRequired()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Production Order] [Warehouse]
        // [SCENARIO 361569] Bin code is not copied from sales line in the production order that uses sales order as a source if pick is required on location
        Initialize();

        // [GIVEN] Location X with "Require Pick" and "From-Production Bin Code" = "B"
        CreateLocationWithProductionAndPick(Location);

        // [GIVEN] Sales order with Location Code = X
        CreateSalesOrderWithLocation(SalesLine, Location.Code, LibraryUtility.GenerateGUID());

        // [GIVEN] Production order that uses sales order as a source
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::"Sales Header",
          SalesLine."Document No.", LibraryRandom.RandDec(100, 2));

        // [WHEN] Production order is refreshed
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Bin code in prod. order line is "B"
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(
          Location."From-Production Bin Code", ProdOrderLine."Bin Code",
          StrSubstNo(WrongFieldValueErr, ProdOrderLine.FieldCaption("Bin Code"), ProdOrderLine.TableCaption(), Location.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateItemNoInSalesPlanningLineSetsLowLevelCode()
    var
        Item: Record Item;
        SalesPlanningLine: Record "Sales Planning Line";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 361569] "Low-Level Code" in Sales Planning Line is copied from Item when "Item No." is validated
        // [GIVEN] Item with "Low-Level Code" = "X"
        LibraryInventory.CreateItem(Item);
        Item."Low-Level Code" := LibraryRandom.RandInt(100);
        Item.Modify();

        // [WHEN] Item No. in Sales Planning Line is set and validated
        SalesPlanningLine.Init();
        SalesPlanningLine.Validate("Item No.", Item."No.");

        // [THEN] "Low-Level Code" in Sales Planning Line is "X"
        Assert.AreEqual(
          Item."Low-Level Code", SalesPlanningLine."Low-Level Code",
          StrSubstNo(WrongFieldValueErr, SalesPlanningLine.FieldCaption("Low-Level Code"), SalesPlanningLine.TableCaption(), Item.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJnlRoutingRefCopiedFromProdOrderLine()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Production Order]
        // [SCENARIO 361710] "Routing No." and "Routing Reference No." in item journal are copied from production order line when "Order Line No. " is validated
        // [GIVEN] Production Order "N" with one line, Line No. = "L", Routing No. = "X", Routing Reference No. = "Y"
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, CreateItemWithRouting(), LibraryRandom.RandInt(100));
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Output journal line for prod. order "N"
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProductionOrder."No.");

        // [WHEN] "Order Line No." in output journal is set to "L"
        ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");

        // [THEN] "Routing No." is "X" and "Routing Reference No." is "Y" in output journal
        Assert.AreEqual(
          ProdOrderLine."Routing No.", ItemJnlLine."Routing No.",
          StrSubstNo(
            WrongFieldValueErr, ItemJnlLine.FieldCaption("Routing No."), ItemJnlLine.TableCaption(), ProdOrderLine.TableCaption()));
        Assert.AreEqual(
          ProdOrderLine."Routing Reference No.", ItemJnlLine."Routing Reference No.",
          StrSubstNo(
            WrongFieldValueErr, ItemJnlLine.FieldCaption("Routing Reference No."), ItemJnlLine.TableCaption(), ProdOrderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingWithTwoShopCalendars()
    var
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // [FEATURE] [Routing] [Refresh Production Order]
        // [SCENARIO 363426] When refreshing back Production Order with different Shop Calendars for Routing lines, first Prod. Order Routing Line starting-ending time is within worktime.

        // [GIVEN] Two work centers: "WC1" work shift - from 06:00:00 to 22:00:00, "WC2" work shift - from 00:00:00 to 23:59:59
        Initialize();

        // [GIVEN] Set WORKDATE to saturday
        WorkDate(CalcDate('<WD6>', WorkDate())); // Saturday
        CreateWorkCenter(WorkCenter1, 060000T, 220000T); // time values needed for test
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter1, CalcDate('<-6M>', WorkDate()), CalcDate('<6M>', WorkDate()));
        CreateWorkCenter(WorkCenter2, 000000T, 235959T); // time values needed for test
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter2, CalcDate('<-6M>', WorkDate()), CalcDate('<6M>', WorkDate()));

        // [GIVEN] Create Item "I" with routing, having three lines:
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Line 1: "WC1", run time 33 minutes
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter1."No.", 0, 33, 0, 0); // specific values needed for test

        // [GIVEN] Line 2: "WC2", wait time 7200 minutes, move time 432 minutes
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter2."No.", 0, 0, 7200, 432);

        // [GIVEN] Line 3: "WC1", run time 66 minutes, wait time 900 minutes, move time 400 minutes
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter1."No.", 0, 66, 900, 400);

        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        UpdateRoutingAndBOMOnItem(Item, '', RoutingHeader."No.");

        // [GIVEN] Create Released Production Order with item "I"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 1);

        // [WHEN] Refresh order back
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, false, false);

        // [THEN] First Production Order Routing Line has Starting Time = 21:27:00, Ending Time = 22:00:00
        VerifyProductionOrderRoutingLineTimes(ProductionOrder."No.", 212700T, 220000T); // specific expected values of test
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ConfirmQstHandlerTRUE,ProductionJournalPageHandler2,MessageHandler')]
    [Scope('OnPrem')]
    procedure LotTrackingOnProductionOrderComponent()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ParentItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        LotNo: Code[50];
        Quantity: Decimal;
        PartQuantity: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Production Journal] [Consumption]
        // [SCENARIO 363503] Can post Production Journal consumption for lot tracked Item, if reservation Entry exist.

        // [GIVEN] Production Item "X" with BOM of component Item "Y" (component is lot tracked).
        Initialize();
        PartQuantity := LibraryRandom.RandInt(10);
        Quantity := LibraryRandom.RandIntInRange(100, 1000);
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateTrackedItem(
          CompItem, CompItem."Replenishment System"::Purchase,
          CompItem."Reordering Policy"::"Lot-for-Lot", false, 0, ItemTrackingCode.Code);
        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, CompItem."No.", CompItem."Base Unit of Measure");
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] "Y" has large quantity on stock of lot "Z".
        CreateAndPostItemJournalLineWithTracking(CompItem."No.", Quantity);
        LotNo := FindAssignedLotNo(CompItem."No.");

        // [GIVEN] Create released Production Order of Item "X", as "Y" stock is enough for that.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", Quantity);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");
        SetLotNoOnProdOrderComponent(ProdOrderComponent, LotNo);

        // [GIVEN] Calculate regenerative plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(ParentItem, WorkDate(), WorkDate());

        // [GIVEN] Post consumption of "Y" lot "Z" of small Quantity.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        SetupPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.", LotNo, PartQuantity);

        // [WHEN] Post consumption of "Y" lot "Z" of small Quantity again.
        SetupPostProductionJournal(ProductionOrder, ProdOrderLine."Line No.", LotNo, PartQuantity);

        // [THEN] Consumption posted successfully.
        // Verification is done in MessageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderBackwardWithZeroRunTime()
    var
        MachineCenter1: Record "Machine Center";
        MachineCenter2: Record "Machine Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RunTime1: Decimal;
        WaitTime2: Decimal;
        SendAheadQty1: Decimal;
        RoutingHeaderNo: Code[20];
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead Quantity]
        // [SCENARIO 371522] Refresh Prod. Order Backward job considers Wait Time of appropriate Routing Line if Run Time is zero
        Initialize();

        RunTime1 := LibraryRandom.RandDec(10, 2);
        WaitTime2 := LibraryRandom.RandDec(10, 2);
        SendAheadQty1 := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Routing Line "L1" with "Run Time" <> 0, "Send-Ahead Quantity" = "Q";
        // [GIVEN] Routing Line "L2" with "Run Time" = 0, "Wait Time" = "X", using Constrained Machine Center
        CreateTwoMachineCenters(MachineCenter1, MachineCenter2);
        RoutingHeaderNo := CreateRoutingHeaderWithTwoLines(
            MachineCenter1."No.", MachineCenter2."No.", RunTime1, 0, 0, WaitTime2, SendAheadQty1, 0);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        UpdateRoutingAndBOMOnItem(Item, '', RoutingHeaderNo);

        // [GIVEN] Released Production Order with "Quantity" > "Q"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", SendAheadQty1 + 1);

        // [WHEN] Refresh Production Order Backward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, false, false);

        // [THEN] Last Prod. Order Routing Line has "Starting Date-Time" = "Ending Date-Time" - "X"
        VerifyLastProdOrderRoutingLineWaitTime(ProductionOrder."No.", WaitTime2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderForwardWithZeroRunTime()
    var
        MachineCenter1: Record "Machine Center";
        MachineCenter2: Record "Machine Center";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RunTime2: Decimal;
        WaitTime1: Decimal;
        SendAheadQty2: Decimal;
        RoutingHeaderNo: Code[20];
    begin
        // [FEATURE] [Routing] [Production Order] [Send-Ahead Quantity]
        // [SCENARIO 371522] Refresh Prod. Order Forward job considers Wait Time of appropriate Routing Line if Run Time is zero
        Initialize();

        RunTime2 := LibraryRandom.RandDec(10, 2);
        WaitTime1 := LibraryRandom.RandDec(10, 2);
        SendAheadQty2 := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Routing Line "L1" with "Run Time" = 0, "Wait Time" = "X", using Constrained Machine Center
        // [GIVEN] Routing Line "L2" with "Run Time" <> 0, "Send-Ahead Quantity" = "Q";
        CreateTwoMachineCenters(MachineCenter1, MachineCenter2);
        RoutingHeaderNo := CreateRoutingHeaderWithTwoLines(
            MachineCenter2."No.", MachineCenter1."No.", 0, RunTime2, WaitTime1, 0, 0, SendAheadQty2);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        UpdateRoutingAndBOMOnItem(Item, '', RoutingHeaderNo);

        // [GIVEN] Released Production Order with "Quantity" > "Q"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", SendAheadQty2 + 1);

        // [WHEN] Refresh Production Order Forward
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, false, false);

        // [THEN] First Prod. Order Routing Line has "Starting Date-Time" = "Ending Date-Time" - "X"
        VerifyFirstProdOrderRoutingLineWaitTime(ProductionOrder."No.", WaitTime1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderRoutingLineWaitTime()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Item: Record Item;
        StartingDateTime: DateTime;
    begin
        // [FEATURE] [Routing] [Production Order Routing Line]
        // [SCENARIO 364340] When setting Production Order Routing Line Wait Time, its starting date-time does not change.

        // [GIVEN] Work center "WC1" work shift - from 06:00:00 to 22:00:00.
        Initialize();

        // [GIVEN] Set WORKDATE to thursday
        WorkDate(CalcDate('<WD4>', WorkDate())); // Thursday
        CreateWorkCenter(WorkCenter, 060000T, 220000T); // time values needed for test
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));

        // [GIVEN] Create Item "I" with routing, having two lines:
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Line 1: "WC1", run time 900 minutes
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 900, 0, 0); // specific values needed for test

        // [GIVEN] Line 2: "WC1", wait time 5790 minutes
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 0, 5760, 0);

        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        UpdateRoutingAndBOMOnItem(Item, '', RoutingHeader."No.");

        // [GIVEN] Create Released Production Order with item "I"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 1);

        // [GIVEN] Refresh order back
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, false, false);
        // [WHEN] Validate "Wait Time" in second Prod. Order Routing Line.
        ProdOrderRoutingLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindLast();
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";
        ProdOrderRoutingLine.Validate("Wait Time", ProdOrderRoutingLine."Wait Time");
        // [THEN] Second Production Order Routing Line "Starting Date-Time" has not changed.
        ProdOrderRoutingLine.TestField("Starting Date-Time", StartingDateTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderCompletelyPickedForNotSuppliedComponents()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [UT] [Production Order Component]
        // [SCENARIO 375248] Field "Completely Picked" of Production Order table should be calculated for not supplied Components

        // [GIVEN] Production Order with not Supplied Completely Picked Component
        CreateRelProdOrder(ProductionOrder);
        CreateProdOrderComp(ProdOrderComponent, ProductionOrder."No.", 0, true);

        // [WHEN] CALCFIELDS for "Completely Picked" of Production Order
        ProductionOrder.CalcFields("Completely Picked");

        // [THEN] "Completely Picked" of Production Order is "TRUE"
        ProductionOrder.TestField("Completely Picked", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderCompletelyPickedForSuppliedComponents()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [UT] [Production Order Component]
        // [SCENARIO 375248] Field "Completely Picked" of Production Order table should not be calculated for supplied Components

        // [GIVEN] Production Order with Supplied Completely Picked Component
        CreateRelProdOrder(ProductionOrder);
        CreateProdOrderComp(ProdOrderComponent, ProductionOrder."No.", LibraryRandom.RandInt(9), true);

        // [WHEN] CALCFIELDS for "Completely Picked" of Production Order
        ProductionOrder.CalcFields("Completely Picked");

        // [THEN] "Completely Picked" of Production Order is "FALSE"
        ProductionOrder.TestField("Completely Picked", false);
    end;

    [Test]
    [HandlerFunctions('CreateOrderFromSalesModalPageHandler,MessageHandler,ReservationModalPageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure CancelReservationOnProdOrderFromSalesOrderPlanning()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Item Tracking] [Reservation] [Order-to-Order Binding]
        // [SCENARIO 136404] "Order-to-Order" binding erased when Reservation cancelled for Tracked Item in Prod. Order.

        // [GIVEN] Lot tracked Item, "Reserve" = "Never", "Order Tracking Policy" = "Tracking & Action Msg.". Create Sales Order.
        Initialize();
        CreateSalesOrderWithLotTrackedItemSetup(SalesLine);
        LibraryVariableStorage.Enqueue(FirmPlannedProdOrderCreatedTxt); // Enqueue value for MessageHandler.

        // [GIVEN] Create Prod. Order from Sales Order Planning.
        LibraryManufacturing.CreateProdOrderUsingPlanning(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesLine."Document No.", SalesLine."No.");

        // [WHEN] Cancel resevation.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.ShowReservation();

        // [THEN] Binding set to empty for reservation entries.
        VerifyReservationEntry(SalesLine."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderRoutingLineWaitTimeBackOneDay()
    var
        WorkCenter: Record "Work Center";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
    begin
        // [FEATURE] [Routing] [Production Order Routing Line]
        // [SCENARIO 375635] Production Order refreshed "Back" should keep Starting Date-Time on Replan "Back"
        Initialize();

        // [GIVEN] Item "I" with routing, having 2 lines:
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // [GIVEN] Line 1: "WC1", run time 1 minutes
        CreateWorkCenter(WorkCenter, 080000T, 160000T); // time values needed for test
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 0, 0, 0);

        // [GIVEN] Line 2: "WC2", wait time 1 day
        LibraryManufacturing.CreateWorkCenterFullWorkingWeek(WorkCenter, 080000T, 230000T); // time values needed for test
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Days);
        CapacityUnitOfMeasure.FindFirst();
        WorkCenter.Validate("Queue Time", 1);
        WorkCenter.Validate("Queue Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Modify(true);
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 0, 0, 0);

        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        UpdateRoutingAndBOMOnItem(Item, '', RoutingHeader."No.");

        // [GIVEN] Create Released Production Order "PO" with item "I"
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", 1);

        // [GIVEN] "PO"."Due Date" = 17/02/2017
        ProductionOrder.Validate("Due Date", WorkDate());
        ProductionOrder.Validate("Location Code", LocationBlue.Code);
        ProductionOrder.Modify(true);

        // [GIVEN] Refresh "PO" back
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, false, false);

        // [GIVEN] "PO"."Starting DateTime" = 15/02/2017
        VerifyProdOrderLineStartingDateTime(ProductionOrder, 'Wrong starting date-time on Refresh');

        // [WHEN] Replan "PO" with "Back" and "No Levels" options
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"No Levels");

        // [THEN] "PO"."Starting DateTime" = 15/02/2017
        VerifyProdOrderLineStartingDateTime(ProductionOrder, 'Wrong starting date-time on Replan');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertRoutingLineWithBlankRoutingNo()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Routing Line] [UT]
        // [SCENARIO 375749] Inserting Routing line should be prohibited if "Routing No." is blank
        Initialize();

        // [GIVEN] Prod. Order Routing Line with blank "Routing No."
        ProdOrderRoutingLine.Init();

        // [WHEN] Insert Prod. Order Routing Line
        asserterror ProdOrderRoutingLine.Insert(true);

        // [THEN] Error is thrown: "Routing No. must have a value in Prod. Order Routing Line"
        Assert.ExpectedError(RoutingHeaderExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderBackWithEndingTimeBlank()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WaitTime: Decimal;
    begin
        // [FEATURE] [Routing] [Production Order Routing Line]
        // [SCENARIO 376121] "Wait Time" of Routing Line should be Considered when Refreshing Production Order Back if "Ending Time" is 0:00:00 and Calenadrar Entry exists for ending day
        Initialize();

        // [GIVEN] Routing Line with "Wait Time" = "10 minutes"
        CreateItemWithRoutingAndWaitTime(Item, WaitTime);

        // [GIVEN] Released Production Order with "Due Date" = "30.09.2015", "Ending Time" = "0:00:00"
        CreateRelProdOrderWithDateTime(ProductionOrder, Item."No.", WorkDate(), WorkDate());

        // [WHEN] Resfresh Production Order "Back"
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, false, false);

        // [THEN] Prod. Order Routing Line is created with "Starting Date-Time" = "29.09.2015 23:50"
        VerifyProdOrderRoutingLine(ProductionOrder."No.", WaitTime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderBackWithEndingTimeBlankNoCalendarEntry()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        WaitTime: Decimal;
    begin
        // [FEATURE] [Routing] [Production Order Routing Line]
        // [SCENARIO 376121] "Wait Time" of Routing Line should be Considered when Refreshing Production Order Back if "Ending Time" is 0:00:00 and Calenadrar Entry does not exist for ending day
        Initialize();

        // [GIVEN] Routing Line with "Wait Time" = "10 minutes"
        CreateItemWithRoutingAndWaitTime(Item, WaitTime);

        // [GIVEN] Released Production Order with "Due Date" = "30.09.2015", "Ending Time" = "0:00:00" with no Calendar Entry on 30.09.2015
        CreateRelProdOrderWithDateTime(ProductionOrder, Item."No.", WorkDate() + 2, WorkDate() + 3);

        // [WHEN] Resfresh Production Order "Back"
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, false, false);

        // [THEN] Prod. Order Routing Line is created with "Starting Date-Time" = "29.09.2015 23:50"
        VerifyProdOrderRoutingLine(ProductionOrder."No.", WaitTime);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,PostProdJournalByPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure FlushedComponentDoesNotInheritOutputItemTrackingRequirements()
    var
        ProdItem: Record Item;
        ProductionOrder: Record "Production Order";
        CompItemNo: Code[20];
        ProdLotNo: Code[50];
    begin
        // [FEATURE] [Flushing] [Item Tracking]
        // [SCENARIO 381952] Component without item tracking is flushed when output of tracked item is posted.
        Initialize();

        // [GIVEN] Production lot-tracked item "I".
        // [GIVEN] Item "C" that is a component of "I" and has no tracking code.
        CompItemNo := CreateProductionItemsSetupWithRouting(ProdItem);
        UpdateTrackingCodeOnItem(ProdItem);

        // [GIVEN] Item "C" is in stock.
        CreateAndPostItemJournalLine(CompItemNo);

        // [GIVEN] Released Production Order for "I". Lot "L" is assigned to the Prod. Order Line.
        CreateAndRefreshReleasedProdOrderWithFlushedComponent(
          ProductionOrder, ProdItem."No.", CompItemNo, LibraryRandom.RandInt(5));
        ProdLotNo := LibraryUtility.GenerateGUID();
        UpdateItemTrackingOnProdOrderLine(ProductionOrder, ProdLotNo);

        // [WHEN] Post the output of "I".
        PostProductionJournal(ProductionOrder);

        // [THEN] Item "I" is posted with lot "L".
        VerifyItemLedgerEntryPosted(ProductionOrder."No.", ProdItem."No.", ProdLotNo);

        // [THEN] Consumption of "C" is posted without lot no.
        VerifyItemLedgerEntryPosted(ProductionOrder."No.", CompItemNo, '');
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler,ItemTrackingSummaryPageHandler,PostProdJournalByPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOfFlushedComponentIsNotMixedWithItemTrackingOfOutput()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdLotNo: Code[50];
        CompLotNo: Code[50];
    begin
        // [FEATURE] [Flushing] [Item Tracking]
        // [SCENARIO 381952] Flushed component and production item are posted with their own item tracking when the production journal is posted.
        Initialize();

        // [GIVEN] Production lot-tracked item "I".
        // [GIVEN] Lot-tracked item "C" that is a component of "I".
        CompItem.Get(CreateProductionItemsSetupWithRouting(ProdItem));
        UpdateTrackingCodeOnItem(ProdItem);
        UpdateTrackingCodeOnItem(CompItem);

        // [GIVEN] Item "C" is in stock with assigned lot no. "LC".
        CreateAndPostItemJournalLineWithTracking(CompItem."No.", LibraryRandom.RandIntInRange(20, 40));
        CompLotNo := FindAssignedLotNo(CompItem."No.");

        // [GIVEN] Released Production Order for "I". Lot "LI" is assigned to the Prod. Order Line.
        // [GIVEN] Lot "LC" is selected on Prod. Order Component "C".
        CreateAndRefreshReleasedProdOrderWithFlushedComponent(
          ProductionOrder, ProdItem."No.", CompItem."No.", LibraryRandom.RandInt(10));
        ProdLotNo := LibraryUtility.GenerateGUID();
        UpdateItemTrackingOnProdOrderLine(ProductionOrder, ProdLotNo);
        UpdateItemTrackingOnProdOrderComponent(ProductionOrder, CompItem."No.");

        // [WHEN] Post the output of "I".
        PostProductionJournal(ProductionOrder);

        // [THEN] Item "I" is posted with lot "LI".
        VerifyItemLedgerEntryPosted(ProductionOrder."No.", ProdItem."No.", ProdLotNo);

        // [THEN] Item "C" is posted with lot "LC".
        VerifyItemLedgerEntryPosted(ProductionOrder."No.", CompItem."No.", CompLotNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure WhereUsedShowsBOMStructureForCertifiedVersionOfClosedBOM()
    var
        ParentItem: Record Item;
        VersionItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used";
    begin
        // [FEATURE] [Production BOM Version] [Where-Used]
        // [SCENARIO 382354] "Where-Used" report should show BOM structure for an item included in a certified version of a closed BOM

        // [GIVEN] Item "PI" with a closed production BOM "B"
        CreateClosedProductionBOM(ProductionBOMHeader, ParentItem);
        // [GIVEN] Create a certified version of the BOM "B"
        // [GIVEN] Item "CI" is included in the certified version
        CreateProductionBOMVersionWithNewItem(VersionItem, ProductionBOMHeader, ProductionBOMVersion.Status::Certified);

        // [WHEN] Run where-used list for item "CI"
        OpenProdBOMWhereUsedPage(ProdBOMWhereUsed, VersionItem);

        // [THEN] Item "PI" shown in the report
        ProdBOMWhereUsed.First();
        ProdBOMWhereUsed."Item No.".AssertEquals(ParentItem."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhereUsedDoesNotShowBOMStructureForClosedVersionOfCertifiedBOM()
    var
        ParentItem: Record Item;
        VersionItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used";
    begin
        // [FEATURE] [Production BOM Version] [Where-Used]
        // [SCENARIO 382354] "Where-Used" report should not show BOM structure for an item included in a closed version of production BOM

        // [GIVEN] Item "PI" with a certified production BOM "B"
        CreateProductionItemSetup(ParentItem);
        ProductionBOMHeader.Get(ParentItem."Production BOM No.");

        // [GIVEN] Create and close a version of the BOM "B"
        // [GIVEN] Item "CI" is included in the closed version
        CreateProductionBOMVersionWithNewItem(VersionItem, ProductionBOMHeader, ProductionBOMVersion.Status::Closed);

        // [WHEN] Run where-used list for item "CI"
        OpenProdBOMWhereUsedPage(ProdBOMWhereUsed, VersionItem);

        // [THEN] Empty list opens
        ProdBOMWhereUsed.First();
        ProdBOMWhereUsed."Item No.".AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('PostProdJournalByPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure DimsLackingInProdOrderCompAreAddedToFlushedCompFromProdOrderLine()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        RoutingLink: Record "Routing Link";
        RoutingLink2: Record "Routing Link";
        DimensionValue: array[3] of Record "Dimension Value";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Flushing] [Dimension]
        // [SCENARIO 382397] Flushed consumption should have a dimension set which is a combination of dimension sets of Prod. Order Line and Prod. Order Component with a priority of Prod. Order Component's.
        Initialize();

        // [GIVEN] Global Dimension 1 has two values = "G1-1" and "G1-2".
        // [GIVEN] Global Dimension 2 has one value = "G2".
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[3], LibraryERM.GetGlobalDimensionCode(2));

        // [GIVEN] Production item "P", component item "C".
        // [GIVEN] Flushing Method for the component "C" is set to "Backward", so its consumption will be posted automatically on posting the output of "P".
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateRoutingLink(RoutingLink2);
        CompItem.Get(CreateProductionItemsSetupWithRoutingLinkCode(ProdItem, RoutingLink.Code, RoutingLink2.Code));

        // [GIVEN] Item "C" is in stock.
        CreateAndPostItemJournalLine(CompItem."No.");

        // [GIVEN] Released production order for "P".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Set both global dimension values on the prod. order line: "G1-1" and "G2".
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        ProdOrderLine.Validate("Shortcut Dimension 2 Code", DimensionValue[3].Code);
        ProdOrderLine.Modify(true);

        // [GIVEN] Set only global dimension 1 value "G1-2" on the prod. order component.
        FindProdOrderComponent(ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", CompItem."No.");
        ProdOrderComponent.Validate("Shortcut Dimension 1 Code", DimensionValue[2].Code);
        ProdOrderComponent.Modify(true);

        // [WHEN] Post the output of "P".
        PostProductionJournal(ProductionOrder);

        // [THEN] The consumption of "C" is posted.
        // [THEN] Consumption item entry has global dimension 1 value = "G1-2" and global dimension 2 value = "G2".
        VerifyDimensionsOnItemLedgerEntry(ProductionOrder."No.", CompItem."No.", DimensionValue[2], DimensionValue[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LongProductionOrderWithSendAheadCanBeRefreshed()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Send-Ahead Quantity]
        // [SCENARIO 201467] It should be possible to refresh a production order with a parallel routing using send-ahead quantity when total order execution time is greater than MAXINT ms

        // [GIVEN] Parallel routing "R" with 2 operations, both using send-ahead quantity, setup time in operations is 10000
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
        CreateRoutingLineOnNewWorkCenter(RoutingHeader, '100', 10000, 100, '200', '');
        CreateRoutingLineOnNewWorkCenter(RoutingHeader, '200', 10000, 200, '', '100');
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Item "I" with routing "R"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        // [GIVEN] Production order with item "I" as a source, "Quantity" = 10000
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.", 10000);

        // [WHEN] Refresh the production order
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Order is successfully refreshed
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField("Due Date", ProductionOrder."Due Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityConsumptionWithoutOutputFlushesComponentConsumption()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        ProductionOrder: Record "Production Order";
        RoutingLink: Record "Routing Link";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Flushing] [Routing Link]
        // [SCENARIO 215295] Production order components with "Forward" flushing method should be automatically consumed when capacity consumption is posted

        Initialize();

        // [GIVEN] Manufactured item "PI" with one component "CI" that has flushing method "Forward"
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(ComponentItem);
        UpdateFlushingMethodOnItem(ComponentItem, ComponentItem."Flushing Method"::Forward);
        LibraryInventory.PostPositiveAdjustment(ComponentItem, '', '', '', 1, WorkDate(), 0);

        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        // [GIVEN] Item "PI" has routing and a production BOM linked via a routing link
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenter."No.", RoutingLink.Code);
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Validate("Routing No.", RoutingHeader."No.");
        ParentItem.Modify(true);

        // [GIVEN] Create and refresh a production order for item "PI"
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", 1);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [WHEN] Post capacity consumption from the production order without any output
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 1, 0);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Consumption of component "CI" is posted
        VerifyItemLedgerEntryPosted(ProductionOrder."No.", ComponentItem."No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionQtyOfFlushedCompSetEqualToRemQtyWhenOutputFullyPosted()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Flushing]
        // [SCENARIO 256402] All remaining quantity of a prod. order component is flushed when you complete posting the output, and the calculated quantity to be flushed differs from the remaining quantity for less than the rounding precision.
        Initialize();

        // [GIVEN] Production item "P" with a component "C".
        // [GIVEN] In order to produce 1 kg of "P", it is required to consume 0.66666 kg of "C" (5-digit precision).
        // [GIVEN] Set "Rounding Precision" on the item "C" = 0.001 (3 digits).
        // [GIVEN] Item "C" is on stock.
        CreateProductionItemWithComponentAndRouting(ProdItem, CompItem, 0.66666, 0.001);
        MakeItemStock(CompItem."No.", LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Released production order for 100 kg of item "P".
        // [GIVEN] The component "C" is set up for backward flushing.
        CreateAndRefreshReleasedProdOrderWithFlushedComponent(ProductionOrder, ProdItem."No.", CompItem."No.", 100);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Post the output of "P". Quantity = 10 kg.
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 0, 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Post one more output. Quantity = 89.997 kg, thus total posted output quantity = 99.997 kg.
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 0, 89.997);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] The overall flushed quantity of the component item = 66.665 kg.
        // [THEN] That includes 10 * 0.66666 kg = 6.6666 kg -> rounded up to 6.667 kg according to the precision setting, and
        // [THEN] 89.997 * 0.66666 kg = 59.9974002 kg -> rounded first to default quantity precision of 0.001 and then to the rounding precision on the item card -> 59.998 kg.
        VerifyQuantityOnItemLedgerEntries(ItemLedgerEntry."Entry Type"::Consumption, CompItem."No.", -66.665);

        // [THEN] Remaining quantity to be flushed is equal to 0.002.
        CompItem.CalcFields("Qty. on Component Lines");
        CompItem.TestField("Qty. on Component Lines", 0.001);

        // [WHEN] Finish the output by posting remaining 0.003 kg of "P".
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 0, 0.003);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] The overall flushed quantity of "C" = 66.667 kg.
        // [THEN] That includes 66.66698 kg flushed earlier and the remaining quantity 0.00002 kg.
        // [THEN] The formula 0.003 * 0.66666 kg = 0.00199 kg -> rounded up to 0.002 kg, was not applied.
        VerifyQuantityOnItemLedgerEntries(ItemLedgerEntry."Entry Type"::Consumption, CompItem."No.", -66.666);

        // [THEN] All quantity is thus flushed.
        CompItem.CalcFields("Qty. on Component Lines");
        CompItem.TestField("Qty. on Component Lines", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionQtyOfFlushedCompCalcByActualOutputWhenCalcDiffGreaterThanPrecision()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Flushing]
        // [SCENARIO 256402] The program calculates the quantity to be flushed by multiplying "Quantity Per" by output quantity, even though the output is complete, in case the calculated quantity to be flushed differs much from the remaining quantity.
        Initialize();

        // [GIVEN] Production item "P" with a component "C".
        // [GIVEN] In order to produce 1 kg of "P", it is required to consume 0.66666 kg of "C" (7-digit precision).
        // [GIVEN] Set "Rounding Precision" on the item "C" = 0.00001 (5 digits).
        // [GIVEN] Item "C" is on stock.
        CreateProductionItemWithComponentAndRouting(ProdItem, CompItem, 0.66666, 0.00001);

        // [GIVEN] Released production order for 100 kg of item "P".
        // [GIVEN] The component "C" is set up for backward flushing.
        CreateAndRefreshReleasedProdOrderWithFlushedComponent(ProductionOrder, ProdItem."No.", CompItem."No.", 100);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        MakeItemStock(CompItem."No.", LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Post the output of "P". Quantity = 10 kg.
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 0, 10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Increase "Quantity per" on the component line from 0.66666 kg to 1 kg.
        // [GIVEN] "Remaining quantity" is therefore updated to 100 - 6.6666 = 93.3334 kg.
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.Validate("Quantity per", 1);
        ProdOrderComponent.Modify(true);

        // [WHEN] Finish the output by posting 90 kg of "P".
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 0, 90);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] The overall flushed quantity = 96.66667 kg.
        // [THEN] That includes 10 * 0.66666 kg = 6.6666 kg -> rounded up to 6.6666 kg according to the precision setting on the first output, and
        // [THEN] 90 * 1 kg = 90 kg flushed on the second output.
        VerifyQuantityOnItemLedgerEntries(ItemLedgerEntry."Entry Type"::Consumption, CompItem."No.", -96.6666);

        // [THEN] The component is not flushed in full, because the difference between calculated flushing (90 kg) and remaining quantity (93.3334) is greater than the rounding precision.
        CompItem.CalcFields("Qty. on Component Lines");
        CompItem.TestField("Qty. on Component Lines", 3.3334);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ConsumptionQtyOfFlushedCompNormalAfterOutputFullyPosted()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Flushing]
        // [SCENARIO 340342] Flushed consumption quantity is calculated straight on actual output in case of over-consumption.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Production item "P" with a component "C".
        // [GIVEN] In order to produce 1 kg of "P", it is required to consume 1 kg of "C".
        // [GIVEN] Set "Rounding Precision" on the item "C" = 2.
        // [GIVEN] Item "C" is on stock.
        CreateProductionItemWithComponentAndRouting(ProdItem, CompItem, 1, 2);
        MakeItemStock(CompItem."No.", LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Released production order for 10 kg of item "P".
        // [GIVEN] The component "C" is set up for backward flushing.
        CreateAndRefreshReleasedProdOrderWithFlushedComponent(ProductionOrder, ProdItem."No.", CompItem."No.", Qty);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Post the output for 10 kg. That flushes 20 kg of component "C".
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 0, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Revert posting the output. That doesn't cause any flushing.
        FindItemLedgerEntry(ItemLedgerEntry, ProdOrderLine."Prod. Order No.", ProdItem."No.", ItemLedgerEntry."Entry Type"::Output);
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 0, -Qty);
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Post the output for 10 kg again.
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, 0, 0, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] That flushes 20 kg again. The total flushed amount is 40 kg.
        VerifyQuantityOnItemLedgerEntries(ItemLedgerEntry."Entry Type"::Consumption, CompItem."No.", -2 * Round(Qty, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteQltyMeasureCodeWhenRtngExists()
    var
        RoutingHeader: Record "Routing Header";
        QualityMeasure: Record "Quality Measure";
    begin
        // [FEATURE] [Quality Measure]
        // [SCENARIO 201733] It must be impossible to delete Quality Measure if at least one "Routing Quality Measure"exists.

        Initialize();

        // [GIVEN] Create Routing and Quality Measure
        CreateRoutingSetupWithQltyMeasure(RoutingHeader, QualityMeasure);

        // [WHEN] Trying to delete Quality Measure
        asserterror QualityMeasure.Delete(true);

        // [THEN] Error message: "You cannot delete the Quality Measure because it is being used on one or more active Routings."
        Assert.ExpectedError(CannotDeleteRecActRoutingErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteQltyMeasureCodeWhenProdOrderRtngQltyMeasExists()
    var
        RoutingHeader: Record "Routing Header";
        QualityMeasure: Record "Quality Measure";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
    begin
        // [FEATURE] [Quality Measure]
        // [SCENARIO 201733] It must be impossible to delete Quality Measure if at least one "Prod. Order Rtng Qlty Meas." exists.

        Initialize();

        // [GIVEN] Create Routing and Quality Measure
        CreateRoutingSetupWithQltyMeasure(RoutingHeader, QualityMeasure);

        // [GIVEN] Create Item for Routing Header
        CreateItemForRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh Production Order
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", 1);

        // [WHEN] Trying to delete Quality Measure
        asserterror QualityMeasure.Delete(true);

        // [THEN] Error message: "You cannot delete the Quality Measure because it is being used on one or more active Production Orders."
        Assert.ExpectedError(CannotDeleteRecProdOrderErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateProdOrderWithQltyMeasures()
    var
        RoutingHeader: Record "Routing Header";
        QualityMeasure: Record "Quality Measure";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
    begin
        // [FEATURE] [Quality Measure]
        // [SCENARIO 201733] "Prod. Order Rtng Qlty Meas." must be created when Prod. Order is refreshed.

        Initialize();

        // [GIVEN] Creating Routing and Quality Measure
        CreateRoutingSetupWithQltyMeasure(RoutingHeader, QualityMeasure);

        // [GIVEN] Creating Item for Routing Header
        CreateItemForRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh Production Order
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", 1);

        // [WHEN] Trying to find Prod. Order Quality Measure line.
        ProdOrderRtngQltyMeas.SetRange("Prod. Order No.", ProductionOrder."No.");

        // [THEN] The record must exist.
        Assert.RecordIsNotEmpty(ProdOrderRtngQltyMeas);
    end;

    [Test]
    [HandlerFunctions('HyperlinkHandler')]
    [Scope('OnPrem')]
    procedure ChangeProdOrderStatusNoteTypeRecordLinkHyperlinkShownNewOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RecordLink: Record "Record Link";
        PageManagement: Codeunit "Page Management";
    begin
        // [FEATURE] [Record Link]
        // [SCENARIO 257841] When the status of a production order is changed, Note Type record links associated with this order should be updated to point to the new order

        Initialize();

        // [GIVEN] Planned production order "P"
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.", LibraryRandom.RandInt(100));

        // [GIVEN] Record link associated with the production order "P", notification is active
        LibraryUtility.CreateRecordLink(ProductionOrder, RecordLink.Type::Note);

        // [WHEN] Change the status of the order "P" from "Planned" to "Firm Planned"
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::"Firm Planned", WorkDate(), false);

        // [THEN] There is no record link pointing to the planned production order
        RecordLink.SetRange("Record ID", ProductionOrder.RecordId);
        Assert.RecordIsEmpty(RecordLink);

        FindProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.");

        // [THEN] There is a record link pointing to the firm planned production order
        RecordLink.SetRange("Record ID", ProductionOrder.RecordId);
        RecordLink.FindFirst();

        // [THEN] URL in the record link is set to open the page "Firm Planned Prod. Order"
        // [THEN] Notification is active in the record link
        LibraryVariableStorage.Enqueue(PageManagement.GetPageID(ProductionOrder));
        HyperLink(RecordLink.URL1);
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), MalformedRecLinkErr);
        Assert.IsTrue(RecordLink.Notify, MalformedRecLinkErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeProdOrderStatusAllNoteTypeRecordLinksUpdated()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RecordLink: Record "Record Link";
        I: Integer;
        NoOfLinks: Integer;
    begin
        // [FEATURE] [Record Link]
        // [SCENARIO 257841] If several Note Type record links are associated with a production order, all links are updated when the order status is changed

        Initialize();

        // [GIVEN] Firm planned production order "PO"
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(100));

        // [GIVEN] 3 record links associated with the production order "PO"
        NoOfLinks := 3;
        for I := 1 to NoOfLinks do
            LibraryUtility.CreateRecordLink(ProductionOrder, RecordLink.Type::Note);

        // [WHEN] Change status of the production order "PO" from "Firm Planned" to "Released"
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);

        // [THEN] There are no links pointing to the firm planned production order
        RecordLink.SetRange("Record ID", ProductionOrder.RecordId);
        Assert.RecordIsEmpty(RecordLink);

        // [THEN] There are 3 links pointing to the released production order
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.");
        RecordLink.SetRange("Record ID", ProductionOrder.RecordId);
        Assert.RecordCount(RecordLink, NoOfLinks);
    end;

    [Test]
    [HandlerFunctions('LotItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure AssignItemTrackingToNegativeConsumption()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
        LotNos: array[3] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Consumption] [Item Tracking]
        // [SCENARIO 283885] When a user calculates consumption based on actual output, which is zero, so the program suggests reverting excessive consumption, it takes item tracking for a new negative consumption journal line from the posted item entries.
        Initialize();

        // [GIVEN] Lot-tracked item "C", which is a production component of item "P".
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CompItem.Get(CreateProductionItemSetup(ProdItem));
        CompItem.Validate("Item Tracking Code", ItemTrackingCode.Code);
        CompItem.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        CompItem.Modify(true);

        // [GIVEN] Three lots "L1", "L2", "L3" of item "C" are in stock.
        for i := 1 to ArrayLen(LotNos) do begin
            CreateAndPostItemJournalLineWithTracking(CompItem."No.", LibraryRandom.RandIntInRange(100, 200));
            LotNos[i] := FindAssignedLotNo(CompItem."No.");
        end;

        // [GIVEN] Released production order for parent item "P".
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", LibraryRandom.RandInt(10));

        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Post component consumption:
        // [GIVEN] Lot "L1" +10 pcs, then -10 pcs. Overall consumption = 0 pcs.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", CompItem."No.", LotNos[1], Qty);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", CompItem."No.", LotNos[1], -Qty);

        // [GIVEN] Lot "L2" +10 pcs, then -10 pcs and after that again +10 pcs. Overall consumption = +10 pcs.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", CompItem."No.", LotNos[2], Qty);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", CompItem."No.", LotNos[2], -Qty);
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", CompItem."No.", LotNos[2], Qty);

        // [GIVEN] Lot "L3" +10 pcs. Overall consumption = +10 pcs.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", CompItem."No.", LotNos[3], Qty);

        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");

        // [WHEN] Calculate consumption based on actual output, which is 0.
        LibraryManufacturing.CalculateConsumptionForJournal(ProductionOrder, ProdOrderComponent, WorkDate(), true);

        // [THEN] Lot "L1" has not been excessively consumed, so it has not been included into the item tracking.
        ItemJournalLine.SetRange("Item No.", CompItem."No.");
        ItemJournalLine.FindFirst();
        VerifyItemTrackingOnItemJnlLine(ItemJournalLine, LotNos[1], 0);

        // [THEN] Lots "L2", "L3" have the excessive consumption of 10 pcs, so they have been included to the reserved consumption journal line. Quantity of each lot = -10 pcs.
        VerifyItemTrackingOnItemJnlLine(ItemJournalLine, LotNos[2], -Qty);
        VerifyItemTrackingOnItemJnlLine(ItemJournalLine, LotNos[3], -Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure TrackingSpecIsInitializedCorrectlyOnLookingUpLotNoOnCompPick()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        CompItem: array[2] of Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SCMProductionOrders: Codeunit "SCM Production Orders";
    begin
        // [FEATURE] [Warehouse Pick] [Item Tracking] [Prod. Order Component]
        // [SCENARIO 290787] Tracking Specification points to the right prod. order component line when you look up lot no. on warehouse pick for this component.
        Initialize();

        // [GIVEN] Lot-tracked items "C1" and "C2".
        // [GIVEN] Production item "P".
        CreateItemTrackingCodeWithLotWhseTracking(ItemTrackingCode);
        LibraryInventory.CreateTrackedItem(CompItem[1], '', '', ItemTrackingCode.Code);
        LibraryInventory.CreateTrackedItem(CompItem[2], '', '', ItemTrackingCode.Code);
        CreateItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");

        // [GIVEN] Production BOM for item "P" includes component items "C1", "C2".
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[1]."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[2]."No.", LibraryRandom.RandInt(10));
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        UpdateProductionBOMOnItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Item "C2" is in inventory at location with directed put-away and pick.
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(
          CompItem[2]."No.", LocationWhite.Code, LibraryRandom.RandIntInRange(100, 200), true);

        // [GIVEN] Released production order for "P".
        // [GIVEN] Refresh the production order. Two prod. order component lines are created - Line 10000 with "C1", Line 20000 with "C2".
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, ProdItem."No.", LocationWhite.Code);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem[2]."No.");

        // [GIVEN] Create warehouse pick for the components.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", CompItem[2]."No.");
        WarehouseActivityLine.FindFirst();

        // [GIVEN] Subscribe this codeunit instance to OnBeforeAssistEditTrackingNo event in Codeunit 6501.
        BindSubscription(SCMProductionOrders);

        // [WHEN] Look up "Lot No." field on the warehouse pick line for item "C2".
        WarehouseActivityLine.LookUpTrackingSummary(WarehouseActivityLine, true, -1, "Item Tracking Type"::"Lot No.");

        // [THEN] OnBeforeAssistEditTrackingNo event is raised and handled.
        // [THEN] Tracking Specification passed to the event subscriber points to prod. order component line for "C2".
        // The verification is done in CheckTrackingSpecOnBeforeAssistEditTrackingNoEvent.
    end;

    [Test]
    [HandlerFunctions('ProdOrderCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CapacityCostIsCalculatedOnFinishingProdOrderAfterPutaway()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Flushing] [Inventory Put-away]
        // [SCENARIO 296076] Run Time and capacity cost of output posted with inventory put-away functionality are calculated on flushing production order.
        Initialize();

        // [GIVEN] Location with required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Item "I" with routing.
        // [GIVEN] Unit cost in work center = 1.50 LCY/min, Setup Time on the routing line = 10 min, Run Time = 5 min, Flushing Method = Backward.
        CreateItemWithRoutingSetUpForBackwardFlushing(Item);

        // [GIVEN] Create and refresh released production order for 100 pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, Item."No.", Location.Code);

        // [GIVEN] Post the output using the inventory put-away.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        CreateAndPostInvtPutAwayFromProdOrder(ProductionOrder, ProdOrderRoutingLine);

        // [WHEN] Change status of the production order to "Finished".
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The resulting Run Time on capacity ledger entries = 100 * 5 min = 500 min.
        VerifyRunTimeOnCapacityLedgerEntries(
          ProductionOrder."No.", ProdOrderRoutingLine."Run Time" * ProductionOrder.Quantity);

        // [THEN] The resulting cost amount of the output is equal to 1.50 LCY * (10 min setup + 500 min run) = 765.00 LCY.
        VerifyCapacityAmountOnValueEntries(
          ProductionOrder."No.",
          (ProdOrderRoutingLine."Setup Time" + ProdOrderRoutingLine."Run Time" * ProductionOrder.Quantity) *
          ProdOrderRoutingLine."Unit Cost per");
    end;

    [Test]
    [HandlerFunctions('ProdOrderCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CapacityCostIsCalculatedWhenPostingMultipleRoutingLinesViaFlushing()
    var
        Location: Record Location;
        Item: Record Item;
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        i: Integer;
    begin
        // [FEATURE] [Flushing] [Inventory Put-away] [Routing]
        // [SCENARIO 296076] Run Time and capacity cost of output posted with inventory put-away functionality is calculated correctly on flushing production order with multiple routing lines.
        Initialize();

        // [GIVEN] Location with required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Routing with two lines:
        // [GIVEN] 1st line. Work Center = "PREPARE", Unit Cost = 1.50 LCY/min, Flushing Method = Backward, Setup Time = 10 min, Run Time = 5 min.
        // [GIVEN] 2nd line. Work Center = "EXECUTE", Unit Cost = 4.50 LCY/min, Flushing Method = Backward, Setup Time = 20 min, Run Time = 10 min.
        // [GIVEN] Assign the new routing to item "I".
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        for i := 1 to ArrayLen(WorkCenter) do begin
            LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter[i]);
            WorkCenter[i].Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
            WorkCenter[i].Validate("Flushing Method", WorkCenter[i]."Flushing Method"::Backward);
            WorkCenter[i].Modify(true);

            CreateWorkCenterRoutingLine(
              RoutingLine[i], RoutingHeader, WorkCenter[i]."No.", LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), 0, 0);
        end;
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        CreateItemForRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh released production order for 100 pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, Item."No.", Location.Code);

        // [GIVEN] Post the output using the inventory put-away.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        CreateAndPostInvtPutAwayFromProdOrder(ProductionOrder, ProdOrderRoutingLine);

        // [WHEN] Change status of the production order to "Finished".
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The resulting Run Time on capacity ledger entries = (5 min + 10 min) * 100 = 500 min + 1000 min = 1500 min.
        VerifyRunTimeOnCapacityLedgerEntries(
          ProductionOrder."No.",
          (RoutingLine[1]."Run Time" + RoutingLine[2]."Run Time") * ProductionOrder.Quantity);

        // [THEN] The resulting cost amount of the output is equal to 1.50 LCY * (10 min + 500 min) + 4.50 LCY * (20 min + 1000 min) = 765.00 LCY + 4590.00 LCY = 5355.00 LCY.
        VerifyCapacityAmountOnValueEntries(
          ProductionOrder."No.",
          (WorkCenter[1]."Unit Cost" * (RoutingLine[1]."Setup Time" + RoutingLine[1]."Run Time" * ProductionOrder.Quantity) +
           WorkCenter[2]."Unit Cost" * (RoutingLine[2]."Setup Time" + RoutingLine[2]."Run Time" * ProductionOrder.Quantity)));
    end;

    [Test]
    [HandlerFunctions('ProdOrderCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CapacityCostIsCalculatedWhenProdOrderPartiallyPutAwayAndPartiallyFlushed()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // [FEATURE] [Flushing] [Inventory Put-away]
        // [SCENARIO 296076] When an output is posted partially with inventory put-away and partially flushed on changing the production order's status to Finished, the run time and capacity cost are calculated for both iterations of output.
        Initialize();

        // [GIVEN] Location with required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Item "I" with routing.
        // [GIVEN] Unit cost in work center = 1.50 LCY/min, Setup Time on the routing line = 10 min, Run Time = 5 min, Flushing Method = Backward.
        CreateItemWithRoutingSetUpForBackwardFlushing(Item);

        // [GIVEN] Create and refresh released production order for 100 pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, Item."No.", Location.Code);

        // [GIVEN] Post the output using the inventory put-away.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        CreateAndPostInvtPutAwayFromProdOrder(ProductionOrder, ProdOrderRoutingLine);

        // [GIVEN] Increase the quantity to on the prod. order line from 100 pcs to 110 pcs.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.Validate(Quantity, ProdOrderLine.Quantity + LibraryRandom.RandInt(10));
        ProdOrderLine.Modify(true);

        // [WHEN] Change status of the production order to "Finished".
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The resulting Run Time on capacity ledger entries = 110 * 5 min = 550 min.
        VerifyRunTimeOnCapacityLedgerEntries(
          ProductionOrder."No.", ProdOrderRoutingLine."Run Time" * ProdOrderLine.Quantity);

        // [THEN] The resulting cost amount of the output is equal to 1.50 LCY * (10 min setup + 550 min run) = 840.00 LCY.
        VerifyCapacityAmountOnValueEntries(
          ProductionOrder."No.",
          (ProdOrderRoutingLine."Setup Time" + ProdOrderRoutingLine."Run Time" * ProdOrderLine.Quantity) *
          ProdOrderRoutingLine."Unit Cost per");
    end;

    [Test]
    [HandlerFunctions('ProdOrderCreatedMessageHandler')]
    [Scope('OnPrem')]
    procedure CapacityCostCalculationOnFlushingNotLastRoutingLine()
    var
        Location: Record Location;
        Item: Record Item;
        FlushedWorkCenter: Record "Work Center";
        ManualWorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: array[2] of Record "Routing Line";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // [FEATURE] [Flushing] [Inventory Put-away] [Routing]
        // [SCENARIO 310878] Proper calculation of capacity cost when backward flushing is carried out for a routing line which is not the last one in the routing.
        Initialize();

        // [GIVEN] Location with required put-away.
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        // [GIVEN] Routing with two lines:
        // [GIVEN] 1st line. Work Center = "AUTO", Unit Cost = 1.50 LCY/min, Flushing Method = Backward, Run Time = 2 min.
        // [GIVEN] 2nd line. Work Center = "MANUAL", Unit Cost = 0 LCY/min, Flushing Method = Manual, Run Time = 0 min.
        // [GIVEN] Assign the new routing to item "I".
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateWorkCenterWithCalendar(FlushedWorkCenter);
        FlushedWorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        FlushedWorkCenter.Validate("Flushing Method", FlushedWorkCenter."Flushing Method"::Backward);
        FlushedWorkCenter.Modify(true);
        CreateWorkCenterRoutingLine(RoutingLine[1], RoutingHeader, FlushedWorkCenter."No.", 0, LibraryRandom.RandInt(10), 0, 0);

        LibraryManufacturing.CreateWorkCenterWithCalendar(ManualWorkCenter);
        ManualWorkCenter.Validate("Flushing Method", ManualWorkCenter."Flushing Method"::Manual);
        ManualWorkCenter.Modify(true);
        CreateWorkCenterRoutingLine(RoutingLine[2], RoutingHeader, ManualWorkCenter."No.", 0, 0, 0, 0);

        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        CreateItemForRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh released production order for 10 pcs of item "I".
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, Item."No.", Location.Code);

        // [GIVEN] Post the output using the inventory put-away.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        CreateAndPostInvtPutAwayFromProdOrder(ProductionOrder, ProdOrderRoutingLine);

        // [WHEN] Change status of the production order to "Finished".
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The resulting Run Time on capacity ledger entries = 2 min * 10 = 20 min.
        VerifyRunTimeOnCapacityLedgerEntries(
          ProductionOrder."No.", RoutingLine[1]."Run Time" * ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RefreshProdOrderChildItemWithSKUDescription2()
    var
        ChildItem: Record Item;
        ParentItem: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SKULocationCode: Code[10];
    begin
        // [FEATURE] [Refresh Production Order] [SKU]
        // [SCENARIO 309997] "Description 2" of the descendant Item with defined SKU is copied to Production Order Line
        Initialize();

        // [GIVEN] Item "CHILD" with "Manufacturing Policy" = "Make-to-Order" and "Description 2" = "TEST"
        CreateItemWithMakeToOrderAndDescription2(ChildItem, LibraryUtility.GenerateGUID());

        // [GIVEN] SKU created for "CHILD" in Location "BLUE" with Replenishment System "Prod. Order"
        SKULocationCode := LocationBlue.Code;
        CreateStockkeepingUnit(SKULocationCode, ChildItem."No.", StockkeepingUnit."Replenishment System"::"Prod. Order");

        // [GIVEN] Item "PARENT" with Replenishment System "Prod. Order" and "CHILD" as a BOM Component
        CreateItemWithMakeToOrderAndDescription2(ParentItem, '');
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.", ChildItem."Base Unit of Measure");
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");

        // [WHEN] Create and Refresh Production Order for Item "PARENT" and Location "BLUE"
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, ParentItem."No.", SKULocationCode);

        // [THEN] "Description 2" = "TEST" in Production Order Line for Item "CHILD"
        ProdOrderLine.SetRange("Item No.", ChildItem."No.");
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.TestField("Description 2", ChildItem."Description 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderLineHasItemBaseUnitOfMeasure_ItemWithSKU()
    var
        Item: Record Item;
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemForProductionBOMLine: Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SKULocationCode: Code[10];
    begin
        // [FEATURE] [Item] [Item Unit of Measure] [SKU] [Production BOM] [Production Order] [Refresh Production Order]
        // [SCENARIO 448920] "Base Unit of Measure" from Item is used in Production Order Line with SKU set to use different Unit of Measure in "Production BOM No.".
        Initialize();

        // [GIVEN] Create Item "PARENT" with "Replenishment System" = "Prod. Order" and "Manufacturing Policy" = "Make-to-Stock".
        CreateItemWithMakeToStock(Item);

        // [GIVEN] Create 1st additional Item Unit of Measure for Item "PARENT".
        CreateItemUnitOfMeasure(ItemUnitOfMeasure[1], Item."No.");

        // [GIVEN] Create 2nd additional Item Unit of Measure for Item "PARENT".
        CreateItemUnitOfMeasure(ItemUnitOfMeasure[2], Item."No.");

        // [GIVEN] Item for "CHILD" with "Replenishment System" = "Purchase".
        CreateItem(ItemForProductionBOMLine, "Replenishment System"::Purchase);

        // [GIVEN] Create 1st Production BOM with 1st additional Item Unit of Measure from Item "PARENT".
        CreateAndCertifyProductionBOM(ProductionBOMHeader[1], ItemForProductionBOMLine."No.", ItemUnitOfMeasure[1].Code);

        // [GIVEN] Set 1t Production BOM to Item "PARENT".
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader[1]."No.");

        // [GIVEN] Create SKU for Item "PARENT" in Location "BLUE" with "Replenishment System" = "Prod. Order".
        SKULocationCode := LocationBlue.Code;
        CreateStockkeepingUnit(StockkeepingUnit, SKULocationCode, Item."No.", "Replenishment System"::"Prod. Order");

        // [GIVEN] Create 2nd Production BOM with 2nd additional Item Unit of Measure from Item "PARENT".
        CreateAndCertifyProductionBOM(ProductionBOMHeader[2], ItemForProductionBOMLine."No.", ItemUnitOfMeasure[2].Code);

        // [GIVEN] Set 2nd Production BOM to SKU.
        UpdateProductionBOMOnSKU(StockkeepingUnit, ProductionBOMHeader[2]."No.");

        // [WHEN] Create and Refresh Production Order for Item "PARENT" and Location "BLUE".
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, Item."No.", SKULocationCode);

        // [THEN] "Unit of Measure Code" = "Base Unit of Measure" of Item "PARENT".
        ProdOrderLine.SetRange("Item No.", Item."No.");
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeProdOrderStatusLinkTypeRecordLinksNotUpdated()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RecordLink: Record "Record Link";
        Index: Integer;
        NoOfLinkTypeLinks: Integer;
        RecordLinkURL1: array[2] of Text[2048];
    begin
        // [FEATURE] [Record Link]
        // [SCENARIO 311224] If several Link Type Record Links are associated with a Production Order, all links are updated when the order Status is changed
        Initialize();
        NoOfLinkTypeLinks := ArrayLen(RecordLinkURL1);

        // [GIVEN] Firm Planned Production Order
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(100));

        // [GIVEN] 2 Link Type Record Links for the Order
        for Index := 1 to NoOfLinkTypeLinks do begin
            RecordLink.Get(LibraryUtility.CreateRecordLink(ProductionOrder, RecordLink.Type::Link));
            RecordLinkURL1[Index] := RecordLink.URL1;
        end;

        // [GIVEN] Note Type Record Link for the Order
        LibraryUtility.CreateRecordLink(ProductionOrder, RecordLink.Type::Note);

        // [WHEN] Change Status of the Production Order to Released
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Released, WorkDate(), false);

        // [THEN] All 3 links point to Released Production Order
        // [THEN] Link Type Links URL1 is not changed
        FindProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.");
        RecordLink.SetRange("Record ID", ProductionOrder.RecordId);
        Assert.RecordCount(RecordLink, NoOfLinkTypeLinks + 1);

        RecordLink.FindSet();
        for Index := 1 to NoOfLinkTypeLinks do begin
            RecordLink.TestField(URL1, RecordLinkURL1[Index]);
            RecordLink.Next();
        end;

        RecordLink.TestField(Type, RecordLink.Type::Note);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PreliminaryRoundingBeforeApplyingRoundingPrecisionOnItem()
    var
        UOMMgt: Codeunit "Unit of Measure Management";
        Qty: Decimal;
    begin
        // [FEATURE] [Rounding] [UT]
        // [SCENARIO 333533] RoundToItemRndPrecision function first rounds quantity to standard 5-digit precision and then to the precision defined by the parameter.
        Initialize();

        Qty := 1.0000001;

        Assert.AreEqual(1, UOMMgt.RoundToItemRndPrecision(Qty, 1), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingPrecisionOfProdOrderComponentOnRefreshProdOrder()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Rounding] [Prod. Order Component]
        // [SCENARIO 333533] Rounding precision on item is applied after standard 5-digit rounding when prod. order component is created.
        Initialize();

        // [GIVEN] Component item "C" with rounding precision = 1.
        // [GIVEN] Manufacturing item "P".
        CreateItemWithRoundingPrecision(CompItem, 1);
        CreateItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");

        // [GIVEN] "Quantity per" = 1.0000001 (7 digits) on the production BOM line with component "C".
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1.0000001);
        UpdateProductionBOMOnItem(ProdItem, ProductionBOMHeader."No.");

        // [WHEN] Create and refresh production order for "P", quantity = 1.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", 1);

        // [THEN] "Expected Quantity" on prod. order component "C" is rounded to 1 (1.0000001 -> 1.00000 -> 1).
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");
        ProdOrderComponent.TestField("Expected Quantity", 1);
    end;

    [Test]
    [HandlerFunctions('PostProdJournalByPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure RoundingPrecisionOfProdOrderComponentOnFinishProdOrder()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Rounding] [Prod. Order Component] [Flushing]
        // [SCENARIO 333533] Rounding precision is applied after standard 5-digit rounding when consumption is flushed on finishing production order.
        Initialize();

        // [GIVEN] Component item "C" with rounding precision = 1 and set up for backward flushing.
        // [GIVEN] Post inventory for "C".
        CreateItemWithRoundingPrecision(CompItem, 1);
        UpdateFlushingMethodOnItem(CompItem, CompItem."Flushing Method"::Backward);
        CreateAndPostItemJournalLine(CompItem."No.");

        // [GIVEN] Manufacturing item "P".
        CreateItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);
        UpdateProductionBOMOnItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Released production order for "P", quantity = 1.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", 1);

        // [GIVEN] Post the output of "P".
        PostProductionJournal(ProductionOrder);

        // [GIVEN] Update quantity of component "C" to 1.0000001 (7 digits).
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");
        UpdateQtyOnProdOrderComponent(ProdOrderComponent, 1.0000001);

        // [WHEN] Finish the production order. That triggers automatic consumption of "C".
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Consumed quantity = 1.
        VerifyQuantityOnItemLedgerEntries(ItemLedgerEntry."Entry Type"::Consumption, CompItem."No.", -1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostProdJournalByPageHandler,ConfirmHandlerTRUE,MessageHandler')]
    [Scope('OnPrem')]
    procedure RoundingPrecisionOfProdOrderComponentOnPostOutputAndEnabledFlushing()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // [FEATURE] [Rounding] [Prod. Order Component] [Flushing]
        // [SCENARIO 333533] Rounding precision is applied after standard 5-digit rounding when consumption is flushed on posting output with routing link.
        Initialize();

        // [GIVEN] Component item "C" with rounding precision = 1 and set up for backward flushing.
        // [GIVEN] Post inventory for "C".
        CreateItemWithRoundingPrecision(CompItem, 1);
        UpdateFlushingMethodOnItem(CompItem, CompItem."Flushing Method"::Backward);
        CreateAndPostItemJournalLine(CompItem."No.");

        // [GIVEN] Manufacturing item "P".
        CreateItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");

        // [GIVEN] Create production BOM and routing line linked to each other via Routing Link.
        // [GIVEN] That will trigger flushing of component "C" the moment you post the output of "P".
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenter."No.", RoutingLink.Code);
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        CreateProductionBOMLineWithRoutingLinkCode(ProductionBOMHeader, CompItem."No.", RoutingLink.Code);
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        UpdateRoutingAndBOMOnItem(ProdItem, ProductionBOMHeader."No.", RoutingHeader."No.");

        // [GIVEN] Released production order for "P", quantity = 1.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", 1);

        // [GIVEN] Update quantity of component "C" to 1.0000001 (7 digits).
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");
        UpdateQtyOnProdOrderComponent(ProdOrderComponent, 1.0000001);

        // [WHEN] Post the output of "P". The consumption of "C" is automatically posted by this.
        PostProductionJournal(ProductionOrder);

        // [THEN] Consumed quantity = 1.
        VerifyQuantityOnItemLedgerEntries(ItemLedgerEntry."Entry Type"::Consumption, CompItem."No.", -1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalViewFlushedCompModalPageHandler')]
    [Scope('OnPrem')]
    procedure RoundingPrecisionOnProductionJournalLineForConsumption()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [FEATURE] [Rounding] [Production Journal] [Prod. Order Component]
        // [SCENARIO 333533] Quantity is rounded first to standard 5 digits and then to "Rounding Precision" on item card on production journal.
        Initialize();

        // [GIVEN] Component item "C" with rounding precision = 1.
        // [GIVEN] Manufacturing item "P".
        CreateItemWithRoundingPrecision(CompItem, 1);
        CreateItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);
        UpdateProductionBOMOnItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Released production order for "P", quantity = 1.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", 1);

        // [GIVEN] Update quantity of component "C" to 1.0000001 (7 digits).
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");
        UpdateQtyOnProdOrderComponent(ProdOrderComponent, 1.0000001);

        // [WHEN] Open production journal.
        LibraryVariableStorage.Enqueue(CompItem."No.");
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderComponent."Prod. Order Line No.");

        // [THEN] Quantity on the consumption line = 1.
        Assert.AreEqual(1, LibraryVariableStorage.DequeueDecimal(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingPrecisionOnPopulatingConsumptionJournalLine()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Rounding] [Consumption]
        // [SCENARIO 333533] Quantity is rounded first to standard 5 digits and then to "Rounding Precision" on item card on calculating consumption journal.
        Initialize();

        // [GIVEN] Component item "C" with rounding precision = 1.
        // [GIVEN] Manufacturing item "P".
        CreateItemWithRoundingPrecision(CompItem, 1);
        CreateItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1);
        UpdateProductionBOMOnItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Released production order for "P", quantity = 1.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", 1);

        // [GIVEN] Update quantity of component "C" to 1.0000001 (7 digits).
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");
        UpdateQtyOnProdOrderComponent(ProdOrderComponent, 1.0000001);

        // [WHEN] Calculate consumption in the journal.
        CreateConsumptionJournal(ProductionOrder."No.");

        // [THEN] Quantity on the consumption journal line = 1.
        ItemJournalLine.SetRange("Item No.", CompItem."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoundingPrecisionOnValidateExpectedQtyOnPlanningComponent()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
    begin
        // [FEATURE] [Rounding] [Planning Component] [UT]
        // [SCENARIO 333533] Quantity is rounded first to standard 5 digits and then to "Rounding Precision" on validating "Expected Quantity" on planning component.
        Initialize();

        CreateItemWithRoundingPrecision(Item, 1);

        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", Item."No.");

        PlanningComponent.Validate("Expected Quantity", 1.000001);

        PlanningComponent.TestField("Expected Quantity", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingEndingDateTimeShouldBeRecalculatedForProdOrderRoutingLinesWhenLotSizeChanges()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        TempOldProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
    begin
        // [FEATURE] [Planning] [Prod. Order Routing Line]
        Initialize();

        // [GIVEN] Create Item "I" with routing, having four lines:
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 5, 0, 0);
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 5, 0, 0);
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 5, 0, 0);
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 5, 0, 0);

        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);

        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        UpdateRoutingAndBOMOnItem(Item, '', RoutingHeader."No.");

        // [GIVEN] Create planned Production Order with item "I"
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, Item."No.", 10);

        // [WHEN] Refresh order forward.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, false, false);

        // [THEN] Corresponding data in "Prod. Order Routing Line" table contains 4 Lines;
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
        Assert.RecordCount(ProdOrderRoutingLine, 4);

        ProdOrderRoutingLine.FindSet();
        repeat
            TempOldProdOrderRoutingLine.Copy(ProdOrderRoutingLine);
            TempOldProdOrderRoutingLine.Insert();
        until ProdOrderRoutingLine.Next() = 0;

        // [WHEN] Changing the lot size from 1 to to 10 for line 2.
        ProdOrderRoutingLine.FindSet();
        ProdOrderRoutingLine.Next();
        ProdOrderRoutingLine.Validate("Lot Size", 10);

        TempOldProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter."No.");
        TempOldProdOrderRoutingLine.FindSet();
        ProdOrderRoutingLine.FindSet();

        // [THEN] First line is untouched.
        ProdOrderRoutingLine.TestField("Starting Date-Time", TempOldProdOrderRoutingLine."Starting Date-Time");
        ProdOrderRoutingLine.TestField("Ending Date-Time", TempOldProdOrderRoutingLine."Ending Date-Time");

        ProdOrderRoutingLine.Next();
        TempOldProdOrderRoutingLine.Next();

        // [THEN] Second line is ending earlier.
        ProdOrderRoutingLine.TestField("Starting Date-Time", TempOldProdOrderRoutingLine."Starting Date-Time");
        Assert.IsTrue(ProdOrderRoutingLine."Ending Date-Time" < TempOldProdOrderRoutingLine."Ending Date-Time",
            'Expected new ending date-time to be earlier than original.');

        TempOldProdOrderRoutingLine.Next();
        ProdOrderRoutingLine.Next();

        // [THEN] The rest should have the same time span but start earlier.
        repeat
            Assert.AreEqual(
                ProdOrderRoutingLine."Ending Date-Time" - ProdOrderRoutingLine."Starting Date-Time",
                TempOldProdOrderRoutingLine."Ending Date-Time" - TempOldProdOrderRoutingLine."Starting Date-Time",
                'Expected line to have similar length.'
            );

            Assert.IsTrue(ProdOrderRoutingLine."Starting Date-Time" < TempOldProdOrderRoutingLine."Starting Date-Time",
                'Expected new starting date-time to be earlier than original.');

            Assert.IsTrue(ProdOrderRoutingLine."Ending Date-Time" < TempOldProdOrderRoutingLine."Ending Date-Time",
                'Expected new ending date-time to be earlier than original.');

        until (TempOldProdOrderRoutingLine.Next() = 0) and (ProdOrderRoutingLine.Next() = 0);
    end;

    [Test]
    procedure CapacityCostQtyAndDirectCostOnBackwardFlushingAfterPostOutputWithRunTime()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        Qty: Decimal;
        RunTime: Decimal;
        UnitCost: Decimal;
    begin
        // [FEATURE] [Capacity] [Rounting] [Flushing]
        // [SCENARIO 387610] Calculate remaining capacity to post for backward flushing when the output is partially posted and had capacity.
        Initialize();
        Qty := 2 * LibraryRandom.RandIntInRange(10, 20);
        RunTime := 2 * LibraryRandom.RandIntInRange(100, 200);
        UnitCost := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Work Center, unit cost = 2.00
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Unit Cost", UnitCost);
        WorkCenter.Modify(true);

        // [GIVEN] Create a routing with the work center, set "Run Time" = 200.
        // [GIVEN] Create item with the routing.
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, RunTime, 0, 0);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        CreateItemForRouting(Item, RoutingHeader."No.");

        // [GIVEN] Create and refresh production order, quantity = 10.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Qty);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");

        // [GIVEN] Post output for 5 pcs, run time = 100.
        PostOutput(ProductionOrder."No.", Qty / 2, RunTime / 2);

        // [GIVEN] Set the prod. order routing line for backward flushing.
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.Validate("Flushing Method", ProdOrderRoutingLine."Flushing Method"::Backward);
        ProdOrderRoutingLine.Modify(true);

        // [WHEN] Finish the production order.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] The total run time posted is equal to 1100 = 100 [posted manually] + 5 * 200 [flushing]
        // [THEN] The total output quantity posted = 10.
        CapacityLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        CapacityLedgerEntry.CalcSums(Quantity, "Output Quantity");
        CapacityLedgerEntry.TestField(Quantity, RunTime / 2 + Qty / 2 * RunTime);
        CapacityLedgerEntry.TestField("Output Quantity", Qty);

        // [THEN] The total amount is equal to 2200 = 1100 [run time] * 2.00 [unit cost]
        VerifyCapacityAmountOnValueEntries(ProductionOrder."No.", CapacityLedgerEntry.Quantity * WorkCenter."Unit Cost");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewDemandForecastMatrixPageShouldNotEditable()
    var
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        DemandForecastCard: TestPage "Demand Forecast Card";
    begin
        // [SCENARIO 468058] New Demand forecast page is still editable after opening page in read-only mode.
        Initialize();

        // [GIVEN] Create Item, and a Demand Forecast
        LibraryInventory.CreateItem(Item);
        CreateDemandForecastCard(DemandForecastCard);

        // [WHEN] The items are filtered to the created item using Demand Forecast Matrix "Item No" column.
        DemandForecastCard.Matrix.First();
        DemandForecastCard.Matrix.Filter.SetFilter("No.", Item."No.");

        // [THEN] Field in the Subform Matrix should be editable
        Assert.IsTrue(DemandForecastCard.Matrix.Field1.Editable(), NonEditableErr);

        // [GIVEN] Get the Production Forecast Name Record and close the Demand Forecast Card page
        ProductionForecastName.Get(DemandForecastCard.Name.Value);
        DemandForecastCard.Close();

        // [WHEN] Open Demand Forecast Page in view only mode
        DemandForecastCard.OpenView();
        DemandForecastCard.GoToRecord(ProductionForecastName);

        // [WHEN] The items are filtered to the created item using Demand Forecast Matrix "Item No" column.
        DemandForecastCard.Matrix.First();
        DemandForecastCard.Matrix.Filter.SetFilter("No.", Item."No.");

        // [VERIFY] Verify: Field in the Subform Matrix should not be editable
        Assert.IsFalse(DemandForecastCard.Matrix.Field1.Editable(), EditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyProdOrderComponentWithVariantUpdatedCorrectly()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        ProdOrderLine: Record "Prod. Order Line";
        Qty: Decimal;
        ExpectedQty: Decimal;
    begin
        // [SCENARIO 478475] Released production Order, component with variant updated wrong.
        Initialize();

        // [GIVEN] Create Production and Component Item, and 2 different Variants for Component Item
        CompItem.Get(CreateProductionItemSetup(ProdItem));
        LibraryInventory.CreateItemVariant(ItemVariant, CompItem."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, CompItem."No.");
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Create and refresh Released production order for parent item
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItem."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Update Variant Code of automatically created Prod. Order Component
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.");
        UpdateVariantCodeOnProdOrderComponent(ProdOrderComponent, ItemVariant.Code);
        ExpectedQty := ProdOrderComponent."Remaining Quantity" + Qty;

        // [THEN] Create new Prod. Order Component for same Item with first Variant 
        CreateProdOrderComponentWithDifferentVariant(ProdOrderComponent, ItemVariant.Code);

        // [WHEN] Post component consumption with Variant
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        PostConsumption(ProductionOrder."No.", ProdOrderLine."Line No.", WorkDate() + 1, CompItem."No.", ItemVariant.Code, -Qty);

        // [VERIFY] Verify: Remaining Quantity for which Consumption has been posted
        FindProdOrderComponentWithVariantCode(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItem."No.", ItemVariant.Code);
        Assert.AreEqual(ExpectedQty, ProdOrderComponent."Remaining Quantity", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmQstHandlerTRUE')]
    [Scope('OnPrem')]
    procedure NoDateFormatErrorWhenDateFilterIsInvalid()
    var
        Item: Record Item;
        ProductionForecastName: Record "Production Forecast Name";
        DemandForecastCard: TestPage "Demand Forecast Card";
    begin
        // [SCENARIO 468058] No Date Format error on Demand Forecasting page when the region is changed
        Initialize();

        // [GIVEN] Create Item, and a Demand Forecast
        LibraryInventory.CreateItem(Item);
        CreateDemandForecastCard(DemandForecastCard);

        // [GIVEN] Get the Production Forecast Name Record and close the Demand Forecast Card page
        ProductionForecastName.Get(DemandForecastCard.Name.Value);
        DemandForecastCard.Close();

        // [GIVEN] Create  Date Filter format which is not supported in current localization
        ProductionForecastName."Date Filter" := InvalidDateFilterTxt;
        ProductionForecastName.Modify();

        // [GIVEN] Enqueue the confirmation message 
        LibraryVariableStorage.Enqueue(DateFilterErrMsg);

        // [WHEN] Run to check the date filter is valid or not.
        ProductionForecastName.CheckDateFilterIsValid();

        // [WHEN] Open Demand Forecast Page in view only mode
        DemandForecastCard.OpenView();
        DemandForecastCard.GoToRecord(ProductionForecastName);

        // [THEN] Verify the Date Filter is blank on the record.
        DemandForecastCard."Date Filter".AssertEquals('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderRoutingLineFlowFieldsFromCapacityLedgerEntry()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        RoutingNo, ProdOrderNo, OperationNo : Code[10];
        PostingTimes, I, RunTime, SetupTime, OutputQty, ScrapQty, RoutingRefNo, EntryNo : Integer;
    begin
        // [SCENARIO 554896] New flow fields in Production Order Routing Line table based on data from corresponding Capacity Ledger Entry table
        Initialize();

        OutputQty := LibraryRandom.RandInt(10);
        ScrapQty := LibraryRandom.RandInt(10);
        RunTime := LibraryRandom.RandInt(10);
        SetupTime := LibraryRandom.RandInt(10);

        RoutingNo := LibraryUtility.GenerateGUID();
        ProdOrderNo := LibraryUtility.GenerateGUID();
        OperationNo := LibraryUtility.GenerateGUID();
        RoutingRefNo := LibraryRandom.RandInt(10);

        CapacityLedgerEntry.SetCurrentKey("Entry No.");
        CapacityLedgerEntry.FindLast();
        EntryNo := CapacityLedgerEntry."Entry No.";

        // [GIVEN] Few CapacityLedgerEntry records for the same references
        PostingTimes := LibraryRandom.RandInt(5);
        for I := 1 to PostingTimes do begin
            CapacityLedgerEntry.Init();
            CapacityLedgerEntry."Entry No." := EntryNo + I;
            CapacityLedgerEntry."Order Type" := Enum::"Inventory Order Type"::Production;

            CapacityLedgerEntry."Routing No." := RoutingNo;
            CapacityLedgerEntry."Order No." := ProdOrderNo;
            CapacityLedgerEntry."Operation No." := OperationNo;
            CapacityLedgerEntry."Routing Reference No." := RoutingRefNo;
            CapacityLedgerEntry."Output Quantity" := OutputQty;
            CapacityLedgerEntry."Scrap Quantity" := ScrapQty;
            CapacityLedgerEntry."Run Time" := RunTime;
            CapacityLedgerEntry."Setup Time" := SetupTime;
            CapacityLedgerEntry.Insert(true);
        end;

        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine."Routing No." := RoutingNo;
        ProdOrderRoutingLine."Prod. Order No." := ProdOrderNo;
        ProdOrderRoutingLine."Operation No." := OperationNo;
        ProdOrderRoutingLine."Routing Reference No." := RoutingRefNo;
        ProdOrderRoutingLine.Insert(true);

        // [WHEN] Calculating the new flow fields
        ProdOrderRoutingLine.CalcFields("Posted Output Quantity");
        ProdOrderRoutingLine.CalcFields("Posted Scrap Quantity");
        ProdOrderRoutingLine.CalcFields("Posted Run Time");
        ProdOrderRoutingLine.CalcFields("Posted Setup Time");

        // [THEN] The values in the flow fields match the expected values
        Assert.AreEqual(ProdOrderRoutingLine."Posted Output Quantity", PostingTimes * OutputQty, '');
        Assert.AreEqual(ProdOrderRoutingLine."Posted Scrap Quantity", PostingTimes * ScrapQty, '');
        Assert.AreEqual(ProdOrderRoutingLine."Posted Run Time", PostingTimes * RunTime, '');
        Assert.AreEqual(ProdOrderRoutingLine."Posted Setup Time", PostingTimes * SetupTime, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE,ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure PrintLabelReportFromFinishedProductionOrder()
    var
        Item: Record Item;
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        OutputItemLabel: Report "Output Item Label";
        TempBlob: Codeunit "Temp Blob";
        OutputJournalsTestPage: TestPage "Output Journal";
        InStr: InStream;
        OutStr: OutStream;
        XMLDoc: XmlDocument;
        Qty: Integer;
        Content: Text;
        XmlNodeList, XMLNodeList2 : XmlNodeList;
        XMLNode: XMLNode;
        XMLElement: XMLElement;
        XmlAttribute: XmlAttribute;
    begin
        // [SCENARIO 555133] Item labels can be printed from a Finished Production Order, if the items are tracked
        Initialize();

        // [GIVEN] Tracked item
        LibraryItemTracking.CreateSerialItem(Item);

        // [GIVEN] Production order
        Qty := 1;//LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateProductionOrder(ProdOrder, Enum::"Production Order Status"::Released, Enum::"Prod. Order Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.CreateProdOrderLine(ProdOrderLine, ProdOrder.Status, ProdOrder."No.", Item."No.", '', '', ProdOrder.Quantity);

        // [GIVEN] Posted output item
        OutputJournalsTestPage.OpenEdit();
        OutputJournalsTestPage."Order No.".SetValue(ProdOrder."No.");
        OutputJournalsTestPage."Item No.".SetValue(Item."No.");
        OutputJournalsTestPage."Output Quantity".SetValue(Qty);
        OutputJournalsTestPage."Item Tracking Lines".Invoke();
        OutputJournalsTestPage.Post.Invoke();

        // [GIVEN] Finished production order
        ProdOrder.Validate(Status, Enum::"Production Order Status"::Finished);

        // [WHEN] Generating report for item labels
        ItemLedgerEntry.SetFilter("Order No.", ProdOrder."No.");
        OutputItemLabel.SetTableView(ItemLedgerEntry);
        OutStr := TempBlob.CreateOutStream();
        OutputItemLabel.SaveAs('', ReportFormat::Xml, OutStr);

        // [THEN] The report's dataset contains the expected information
        InStr := TempBlob.CreateInStream();
        XmlDocument.ReadFrom(Instr, XMLDoc);
        XMLDoc.SelectNodes('/ReportDataSet/DataItems/DataItem/Columns/Column', XmlNodeList);
        Assert.IsTrue(XmlNodeList.Count > 0, 'The report does not contain the expected data.');
        foreach XMLNode in XMLNodeList do begin
            XMLElement := XMLNode.AsXmlElement();
            XMLElement.Attributes().Get('name', XmlAttribute);
            Assert.IsTrue(XmlAttribute.Value in ['ItemNo', 'Description', 'BarCode', 'QRCode', 'BaseUnitofMeasure', 'VariantCode'], '');
            case XmlAttribute.Value of
                'ItemNo':
                    begin
                        XMLNodeList2 := XMLElement.GetDescendantNodes();
                        XMLNodeList2.Get(1, XMLNode);
                        XMLNode.WriteTo(Content);
                        Assert.AreEqual(Item."No.", Content, '');
                    end;
                'Description':
                    begin
                        XMLNodeList2 := XMLElement.GetDescendantNodes();
                        XMLNodeList2.Get(1, XMLNode);
                        XMLNode.WriteTo(Content);
                        Assert.AreEqual(Item.Description, Content, '');
                    end;
                'BarCode':
                    begin
                        XMLNodeList2 := XMLElement.GetDescendantNodes();
                        XMLNodeList2.Get(1, XMLNode);
                        XMLNode.WriteTo(Content);
                        Assert.IsTrue(StrLen(Content) > 0, '');
                    end;
                'QRCode':
                    begin
                        XMLNodeList2 := XMLElement.GetDescendantNodes();
                        XMLNodeList2.Get(1, XMLNode);
                        XMLNode.WriteTo(Content);
                        Assert.IsTrue(StrLen(Content) > 0, '');
                    end;
            end;
        end;
    end;

    [Test]
    [HandlerFunctions('SalesOrderPlanningModalPageHandler,CreateOrderFromSalesModalPageHandler,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure CreatingProductionOrderfromSalesOrder_SkipItemThatIsBlockedOrProductionBlockedOutput()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[4] of Record "Sales Line";
        ItemBlocked, ItemProductionBlockedOutput, ItemWithVariant : Record Item;
        ItemVariantBlocked, ItemVariantProductionBlockedOutput : Record "Item Variant";
        ProductionOrder: Record "Production Order";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Production Order] [Sales Order Planning ]
        // [SCENARIO 559297] Creating Orders from Sales with Order Type = "Project Order" skips items with Replenishment System = "Prod. Order" if Item / Item Variant is Blocked or Production Blocked = Output.
        Initialize();

        // [GIVEN] Create Items with Replenishment System = "Prod. Order".
        CreateItem(ItemBlocked, ItemBlocked."Replenishment System"::"Prod. Order");
        CreateItem(ItemProductionBlockedOutput, ItemProductionBlockedOutput."Replenishment System"::"Prod. Order");
        CreateItem(ItemWithVariant, ItemWithVariant."Replenishment System"::"Prod. Order");

        // [GIVEN] Create Item Variants.
        LibraryInventory.CreateVariant(ItemVariantBlocked, ItemWithVariant);
        LibraryInventory.CreateVariant(ItemVariantProductionBlockedOutput, ItemWithVariant);

        // [GIVEN] Create Sales Order with Items and Item Variants.
        CreateSalesOrder(SalesHeader, SalesLine[1], ItemBlocked."No.", LibraryRandom.RandDec(10, 2));

        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, ItemProductionBlockedOutput."No.", LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateSalesLine(SalesLine[3], SalesHeader, SalesLine[3].Type::Item, ItemWithVariant."No.", LibraryRandom.RandDec(10, 2));
        SalesLine[3].Validate("Variant Code", ItemVariantBlocked.Code);
        SalesLine[3].Modify(true);
        LibrarySales.CreateSalesLine(SalesLine[4], SalesHeader, SalesLine[4].Type::Item, ItemWithVariant."No.", LibraryRandom.RandDec(10, 2));
        SalesLine[4].Validate("Variant Code", ItemVariantProductionBlockedOutput.Code);
        SalesLine[4].Modify(true);

        // [GIVEN] Set Item / Item Variant as Blocked or Production Blocked = Output.
        ItemBlocked.Validate(Blocked, true);
        ItemBlocked.Modify(true);

        ItemProductionBlockedOutput.Validate("Production Blocked", ItemProductionBlockedOutput."Production Blocked"::Output);
        ItemProductionBlockedOutput.Modify(true);

        ItemVariantBlocked.Validate(Blocked, true);
        ItemVariantBlocked.Modify(true);

        ItemVariantProductionBlockedOutput.Validate("Production Blocked", ItemVariantProductionBlockedOutput."Production Blocked"::Output);
        ItemVariantProductionBlockedOutput.Modify(true);

        // [WHEN] Create Prod. Order from Sales Order Planning with Order Type = Project Order.
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);
        SalesOrder."Pla&nning".Invoke(); // Handled in SalesOrderPlanningModalPageHandler.

        // [THEN] Verify Prod. Order Line does not exists.
        ProductionOrder.SetCurrentKey("Source No.");
        ProductionOrder.SetRange("Source No.", SalesHeader."No.");
        Assert.RecordIsEmpty(ProductionOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOutputBlockedItemPreventsChangeStatusToReleased()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionBlockedOutputItemErr: Label 'You cannot produce %1 %2 because the %3 is %4 on the %1 card.', Comment = '%1 - Table Caption (Item), %2 - Item No., %3 - Field Caption, %4 - Field Value';
    begin
        // [Scenario 564294] Production Order with blocked output item cannot be changed to Released status
        Initialize();

        // Create Item
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");

        // Create Production Order
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", 1);

        // Change Item to have Production Blocked set to Output
        Item.Validate("Production Blocked", Item."Production Blocked"::Output);
        Item.Modify(true);

        // [WHEN] Try to change status of Production Order to Released
        asserterror LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, Enum::"Production Order Status"::Released, WorkDate(), false);

        // [THEN] Error about the item being blocked is shown
        Assert.ExpectedError(StrSubstNo(ProductionBlockedOutputItemErr, Item.TableCaption(), Item."No.", Item.FieldCaption("Production Blocked"), Item."Production Blocked"));
    end;

    [Test]
    [HandlerFunctions('ConfirmQstHandlerTRUE')]
    Procedure SkippingConsumptionMissingMessageWhenRoutingLinkCodesOnManuallyFlushedComponent()
    var
        ItemFinal: Record Item;
        ItemComp: Record Item;
        ProdBOMHeaderRec: Record "Production BOM Header";
        ProdBOMLineRec: Record "Production BOM Line";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RoutingLink: Record "Routing Link";
        WorkCenter: Record "Work Center";
        ProdOrderNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO 566586] In Production Order change status of Finish is skipping consumption is missing message when routing link codes on Manually flushed Component.
        Initialize();

        //[GIVEN] Create Item FG and Item Compponent.
        CreateFinalItem(ItemFinal);
        CreateCompItem(ItemComp);

        //[GIVEN] Create Production Bom with Routing Link Code
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeaderRec, ItemFinal."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeaderRec, ProdBOMLineRec, '', ProdBOMLineRec.Type::Item, ItemComp."No.", 1);
        ProdBOMLineRec.Validate("Routing Link Code", '100');
        ProdBOMLineRec.Modify(true);
        ProdBOMHeaderRec.Validate(Status, ProdBOMHeaderRec.Status::Certified);
        ProdBOMHeaderRec.Modify(true);

        // [GIVEN] Create Work Center with Calendar
        CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create Routing for Work Center
        RoutingNo := CreateRoutingWithWorkCenter(WorkCenter."No.", 10, 1, 100);

        // [GIVEN] Update Item with Production BOM and Routing No.
        ItemFinal.Validate("Production BOM No.", ProdBOMHeaderRec."No.");
        ItemFinal.Validate("Routing No.", RoutingNo);
        ItemFinal.Modify(true);

        // [GIVEN] Create Production Order
        ProdOrderNo := CreateProductionOrder(ProdOrderLine, RoutingNo, ItemFinal, 2);

        // [GIVEN] Create a Routing Link.
        LibraryManufacturing.CreateRoutingLink(RoutingLink);

        // [GIVEN] Create Prod. Order Routing Line with Routing Link Code.
        CreateProdOrderRoutingLineWithRoutingLinkCode(ProdOrderLine, WorkCenter, ProdOrderRoutingLine.Type::"Work Center", RoutingLink.Code, 1);

        // [GIVEN] Create Prod. Order Component with Routing Link Code.
        CreateProdOrderComponentWithRountingLinkCode(ProdOrderComponent, ProdOrderLine, RoutingLink.Code, 1, ItemComp);

        // [WHEN] Change status Finished
        LibraryVariableStorage.Enqueue(ProductionOrderFinishedStatusMsg);
        LibraryVariableStorage.Enqueue(true);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderNo);

        // [THEN] ProductionOrderFinishedStatusMsg is displayed in ManagedConfirmHandler.
    end;

    [Test]
    Procedure RoutingIsNotCorrectForMTOFinishedGoodItemOnProductionOrderWhenItIsPartOfFamily()
    var
        Family: Record Family;
        Item: Record Item;
        ItemFG: Record Item;
        ItemComp: Record Item;
        ProdBOMHeaderRec: Record "Production BOM Header";
        ProdBOMLineRec: Record "Production BOM Line";
        ProdBOMHeaderItem: Record "Production BOM Header";
        ProdBOMLineItem: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingHeaderFamily: Record "Routing Header";
        WorkCenter: Record "Work Center";
        FGRoutingNo: Code[20];
        CompRoutingNo: Code[20];
    begin
        // [SCENARIO 572309] Routing is not correct for MTO Finished Good item on Production Order when it is part of Family
        Initialize();

        // [GIVEN] Create Item FG and Item Component.
        LibraryInventory.CreateItem(ItemFG);
        ItemFG.Validate("Base Unit of Measure", 'PCS');
        ItemFG.Validate("Replenishment System", ItemFG."Replenishment System"::Purchase);
        ItemFG.Validate("Manufacturing Policy", ItemFG."Manufacturing Policy"::"Make-to-Order");
        ItemFG.Modify(true);
        LibraryInventory.CreateItem(ItemComp);
        ItemComp.Validate("Replenishment System", ItemComp."Replenishment System"::"Prod. Order");
        ItemComp.Validate("Manufacturing Policy", ItemComp."Manufacturing Policy"::"Make-to-Order");
        ItemComp.Modify(true);

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Production Bom For Component Item
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeaderRec, ItemComp."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeaderRec, ProdBOMLineRec, '', ProdBOMLineRec.Type::Item, ItemComp."No.", 1);
        ProdBOMHeaderRec.Validate(Status, ProdBOMHeaderRec.Status::Certified);
        ProdBOMHeaderRec.Modify(true);

        // [GIVEN] Create Production Bom For Item
        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeaderItem, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProdBOMHeaderItem, ProdBOMLineItem, '', ProdBOMLineItem.Type::Item, Item."No.", 1);
        ProdBOMHeaderItem.Validate(Status, ProdBOMHeaderItem.Status::Certified);
        ProdBOMHeaderItem.Modify(true);

        // [GIVEN] Create Work Center with Calendar And Routing For Work Centre
        CreateWorkCenterWithCalendar(WorkCenter);
        FGRoutingNo := CreateRoutingWithWorkCenter(WorkCenter."No.", 10, 1, 100);
        CompRoutingNo := CreateRoutingWithWorkCenter(WorkCenter."No.", 10, 1, 100);

        // [GIVEN] Update Item with Production BOM and Routing No.
        ItemFG.Validate("Production BOM No.", ProdBOMHeaderRec."No.");
        ItemFG.Validate("Routing No.", FGRoutingNo);
        ItemFG.Modify(true);
        ItemComp.Validate("Production BOM No.", ProdBOMHeaderItem."No.");
        ItemComp.Validate("Routing No.", CompRoutingNo);
        ItemComp.Modify(true);

        // [GIVEN] Create Family With Routing Setup
        CreateRoutingSetup(RoutingHeaderFamily, '', '');
        CreateFamily(Family, RoutingHeaderFamily."No.", ItemFG."No.");

        // [GIVEN] Create And Refresh Firm Planned Prod. Order
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Family, 3,
                  ProductionOrder."Source Type"::Family, ItemFG, RoutingHeaderFamily."No.");

        // [THEN] Check ProductionOrderRoutingLines having family Routing Lines
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::"Firm Planned");
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingHeaderFamily."No.");
        if ProdOrderRoutingLine.FindFirst() then
            Assert.AreEqual(RoutingHeaderFamily."No.", ProdOrderRoutingLine."Routing No.", '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Production Orders");
        LibraryVariableStorage.Clear();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Production Orders");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        ConsumptionJournalSetup();
        Commit();

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Production Orders");
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        // Create Blue Location.
        LibraryWarehouse.CreateLocation(LocationBlue);

        // Create White Location.
        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);

        // Create Green Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationGreen);
        LocationGreen.Validate("Require Put-away", true);
        LocationGreen.Validate("Require Pick", true);
        LocationGreen.Validate("Require Receive", true);
        LocationGreen.Validate("Require Shipment", true);
        LocationGreen.Validate("Prod. Output Whse. Handling", "Prod. Output Whse. Handling"::"Inventory Put-away");
        LocationGreen.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        LocationGreen.Modify(true);

        // Create Silver Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSilver);
        LocationSilver."Bin Mandatory" := true;  // Skip Validate to improve performance.
        LocationSilver.Modify(true);
    end;

    local procedure CreateLocationWithProductionAndPick(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Pick", true);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');

        Location.Validate("From-Production Bin Code", Bin.Code);
        Location.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        LibraryInventory.ConsumptionJournalSetup(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
    end;

    local procedure CreateItemTrackingCodeWithLotWhseTracking(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateTrackedItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; IncludeInventory: Boolean; ReorderQuantity: Decimal; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler.
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');  // Required for test when using Item Tracking.
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity);
        ItemJournalLine.Validate("Document No.", LibraryUtility.GenerateGUID());
        ItemJournalLine.Modify(true);
        ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking on Page Handler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, '', 0D);
    end;

    local procedure CreateSalesOrderWithLocation(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; BinCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine."Bin Code" := BinCode;
        SalesLine.Modify();
    end;

    local procedure CreateStockkeepingUnit(LocationCode: Code[10]; ItemNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System")
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10]; ItemNo: Code[20]; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        // Create and Refresh Released Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity);
    end;

    local procedure CreateAndRefreshSimulatedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        // Create and Refresh Simulated Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Simulated, SourceNo, Quantity);
    end;

    local procedure CreateAndRefreshFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        // Create and Refresh Firm Planned Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", SourceNo, Quantity);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshReleasedProdOrderWithFlushedComponent(var ProductionOrder: Record "Production Order"; ProdItemNo: Code[20]; CompItemNo: Code[20]; Qty: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ProdItemNo, Qty);
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItemNo);
        ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::Backward);
        ProdOrderComponent.Validate("Routing Link Code", ProdOrderRoutingLine."Routing Link Code");
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateAndPostConsumptionJournalWithItemTracking(ProdOrderNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Consumption, ItemNo, Qty);
        ItemJournalLine.Validate("Order No.", ProdOrderNo);
        ItemJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Set Quantity & Lot No.");
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        ItemJournalLine.OpenItemTrackingLines(false);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        OutputJournalExplodeRouting(ItemJournalLine, ProductionOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostInvtPutAwayFromProdOrder(ProductionOrder: Record "Production Order"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Output", ProductionOrder."No.", true, false, false);
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Prod. Order Line", ProductionOrder.Status.AsInteger(), ProductionOrder."No.",
          ProdOrderRoutingLine."Routing Reference No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
    end;

    local procedure CreateItemForRouting(var Item: Record Item; RoutingHeaderNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Routing No.", RoutingHeaderNo);
        Item.Modify(true);
    end;

    local procedure CreateProductionOrderOnLocationWithBin(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line")
    var
        Item: Record Item;
    begin
        CreateProductionItemsSetupWithRoutingLinkCode(Item, '', '');
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, Item."No.", LocationSilver.Code);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
    end;

    local procedure CreateOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; NewSetupTime: Decimal; NewRunTime: Decimal; NewOutputQty: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryManufacturing.CreateOutputJournalLine(ItemJournalBatch, ProdOrderLine, ProdOrderLine."Due Date", ProdOrderLine.Quantity, 300);
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        ItemJournalLine.Validate("Item No.");
        ItemJournalLine.Validate("Setup Time", NewSetupTime);
        ItemJournalLine.Validate("Run Time", NewRunTime);
        ItemJournalLine.Validate("Output Quantity", NewOutputQty);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateJournalLineLastOutput(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record "Prod. Order Line"; BinCode: Code[20])
    begin
        CreateOutputJournalLine(ItemJournalLine, ProdOrderLine, LibraryRandom.RandInt(100), 0, ProdOrderLine.Quantity);

        UpdateRoutingOperationOnOutputLine(ItemJournalLine, ProdOrderLine."Routing No.");

        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateRoutingLineOnNewWorkCenter(var RoutingHeader: Record "Routing Header"; OperationNo: Code[10]; SetupTime: Integer; SendAheadQty: Decimal; NextOperationNo: Code[30]; PrevOperationNo: Code[30])
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', WorkDate()), CalcDate('<2M>', WorkDate()));

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', OperationNo, RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Send-Ahead Quantity", SendAheadQty);
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Validate("Previous Operation No.", PrevOperationNo);
        RoutingLine.Modify(true);
    end;

    local procedure MakeItemStock(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(
          ItemJournalLine, ItemNo, '', '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateRoutingSetupWithQltyMeasure(var RoutingHeader: Record "Routing Header"; var QualityMeasure: Record "Quality Measure")
    var
        RoutingLine: Record "Routing Line";
        RoutingQualityMeasure: Record "Routing Quality Measure";
    begin
        CreateRoutingSetup(RoutingHeader, '', '');

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindFirst();
        LibraryManufacturing.CreateQualityMeasure(QualityMeasure);
        LibraryManufacturing.CreateRoutingQualityMeasureLine(RoutingQualityMeasure, RoutingLine, QualityMeasure);
    end;

    local procedure PostProductionJournal(var ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        LibraryVariableStorage.Enqueue(ProductionOrder."No."); // Enqueue value for PostProdJournalByPageHandler.
        LibraryVariableStorage.Enqueue(JournalLinePostedMsg); // Enqueue value for MessageHandler.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        FilterOnItemJournalLine(ItemJournalLine, JournalTemplateName, JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        FilterOnProdOrderComponent(ProdOrderComponent, Status, ProdOrderNo, ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProdOrderComponentItem(var Item: Record Item; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst();
        Item.Get(ProdOrderComponent."Item No.");
    end;

    local procedure FindProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FilterOnProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
    end;

    local procedure UpdateProductionBOMOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Get(Item."No.");  // Get updated instance of Item Record for avoid another user modified error.
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateProductionBOMOnSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; ProductionBOMNo: Code[20])
    begin
        StockkeepingUnit.Get(StockkeepingUnit."Location Code", StockkeepingUnit."Item No.", StockkeepingUnit."Variant Code");  // Get updated instance of Stockkeeping Unit Record for avoid another user modified error.
        StockkeepingUnit.Validate("Production BOM No.", ProductionBOMNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateProductionBOMAndRecertify(ProductionBOMNo: Code[20]; BaseUnitofMeasure: Code[10]; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader2: Record "Production BOM Header";
    begin
        // Create Child Production BOM with Status New and attached to Parent Production BOM and Recertify Parent BOM.
        ProductionBOMHeader.Get(ProductionBOMNo);
        CreateProductionBOM(ProductionBOMHeader2, ProductionBOMLine, BaseUnitofMeasure, ProductionBOMLine.Type::Item, ItemNo);
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", ProductionBOMHeader2."No.",
          LibraryRandom.RandInt(5));
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdateLocationCodeOnSalesLine(var SalesLine: Record "Sales Line"; LocationCode: Code[10])
    begin
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateProdBOMHeaderStatus(ProdBOMNo: Code[20]; ProdBOMHeaderStatus: Enum "BOM Status")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.Get(ProdBOMNo);
        ProductionBOMHeader.Validate(Status, ProdBOMHeaderStatus);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        CreateProductionBOM(ProductionBOMHeader, ProductionBOMLine, BaseUnitOfMeasure, ProductionBOMLine.Type::Item, ItemNo);
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; BaseUnitOfMeasure: Code[10]; Type: Enum "Production BOM Line Type"; No: Code[20])
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type, No, LibraryRandom.RandInt(5));
    end;

    local procedure ChangeStatusOfProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Status: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure ChangeStatusOfProductionRoutingHeader(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure AssingTrackingOnProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component")
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler.
        LibraryVariableStorage.Enqueue(AvailabilityWarningsMsg);  // Enqueue for Confirm Handler.
        ProdOrderComponent.OpenItemTrackingLines();
    end;

    local procedure SetLotNoOnProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component"; LotNo: Code[50])
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Set Lot No.");  // Enqueue for Page Handler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue('One or more lines have tracking specified, but Quantity (Base) is zero. If you continue, data on these lines will be lost.'); // Enque for Message Handler
        ProdOrderComponent.OpenItemTrackingLines();
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindSet();
    end;

    local procedure AcceptActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        repeat
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure FindReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; SourceType: Integer)
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure AcceptActionMessageAndCarryOutActionMessagePlan(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(ItemNo);
        SelectRequisitionLine(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; FromTime: Time; ToTime: Time)
    begin
        LibraryManufacturing.CreateWorkCenterCustomTime(WorkCenter, FromTime, ToTime);
    end;

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateDimensionValueForGlobalDimension(var DimensionValue: Record "Dimension Value")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateItemWithDimension(var Item: Record Item; var DimensionValue: Record "Dimension Value"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        CreateItem(Item, ReplenishmentSystem);

        // Update Dimension on Item.
        UpdateDimensionOnItem(Item, DimensionValue);
    end;

    local procedure CreateItemWithSKU(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateStockkeepingUnit(LocationBlue.Code, Item."No.", StockkeepingUnit."Replenishment System"::"Prod. Order");
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2));
        UpdateLocationCodeOnSalesLine(SalesLine, LocationBlue.Code);
        LibraryVariableStorage.Enqueue(FirmPlannedProdOrderCreatedTxt);  // Enqueue value for MessageHandler.
    end;

    local procedure CreateItemWithRouting(): Code[20]
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateAndUpdateRoutingSetup(RoutingHeader, RoutingLink.Code);
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithRoutingAndWaitTime(var Item: Record Item; var WaitTime: Decimal)
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        WaitTime := LibraryRandom.RandInt(10);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateWorkCenter(WorkCenter, 000000T, 160000T); // time values needed for test
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2D>', WorkDate()), CalcDate('<2D>', WorkDate()));
        CreateWorkCenterRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.", 0, 0, WaitTime, 0);
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        UpdateRoutingAndBOMOnItem(Item, '', RoutingHeader."No.");
    end;

    local procedure CreateItemWithRoutingSetUpForBackwardFlushing(var Item: Record Item)
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Modify(true);
        CreateWorkCenterRoutingLine(
          RoutingLine, RoutingHeader, WorkCenter."No.", LibraryRandom.RandInt(20), LibraryRandom.RandInt(20), 0, 0);
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        CreateItemForRouting(Item, RoutingHeader."No.");
    end;

    local procedure CreateItemWithMakeToOrderAndDescription2(var Item: Record Item; Description2: Code[50])
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Description 2", Description2);
        Item.Modify(true);
    end;

    local procedure CreateItemWithMakeToStock(var Item: Record Item)
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Modify(true);
    end;

    local procedure CreateItemWithRoundingPrecision(var Item: Record Item; RndPrecision: Decimal)
    begin
        CreateItem(Item, Item."Replenishment System"::Purchase);
        Item.Validate("Rounding Precision", RndPrecision);
        Item.Modify(true);
    end;

    local procedure FindProductionOrder(var ProductionOrder: Record "Production Order"; OrderStatus: Enum "Production Order Status"; ItemNo: Code[20])
    begin
        ProductionOrder.SetRange(Status, OrderStatus);
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.FindFirst();
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure UpdateBinCodeOnItemJournalLine(JnlTemplateName: Code[10]; JnlBatchName: Code[10]; BinCode: Code[20])
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        ItemJnlLine.SetRange("Journal Template Name", JnlTemplateName);
        ItemJnlLine.SetRange("Journal Batch Name", JnlBatchName);
        if ItemJnlLine.FindSet() then
            repeat
                ItemJnlLine.Validate("Bin Code", BinCode);
                ItemJnlLine.Modify(true);
            until ItemJnlLine.Next() = 0;
    end;

    local procedure UpdateDimensionOnItem(var Item: Record Item; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        CreateDimensionValueForGlobalDimension(DimensionValue);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Item, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure UpdateDimensionOnProductionOrderLine(var DimensionValue: Record "Dimension Value"; ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        DimensionSetID: Integer;
    begin
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        DimensionSetID := CreateDimensionWithDimensionSetID(DimensionValue, ProdOrderLine."Dimension Set ID");
        ProdOrderLine.Validate("Dimension Set ID", DimensionSetID);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateDimensionOnProdOrderComponent(var DimensionValue: Record "Dimension Value"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
        DimensionSetID: Integer;
    begin
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ItemNo);
        DimensionSetID := CreateDimensionWithDimensionSetID(DimensionValue, ProdOrderComponent."Dimension Set ID");
        ProdOrderComponent.Validate("Dimension Set ID", DimensionSetID);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateGlobalDimensionOnWorkCenter(var DimensionValue: Record "Dimension Value"; WorkCenter: Record "Work Center")
    begin
        CreateDimensionValueForGlobalDimension(DimensionValue);
        WorkCenter.Validate("Global Dimension 1 Code", DimensionValue.Code);
        WorkCenter.Modify(true);
    end;

    local procedure UpdateGlobalDimensionByProductionOrderLine(var DimensionValue: Record "Dimension Value"; ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateDimensionValueForGlobalDimension(DimensionValue);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateGlobalDimensionByShowDimensionsOnLine(var DimensionValue: Record "Dimension Value"; ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateDimensionValueForGlobalDimension(DimensionValue);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        ProdOrderLine.ShowDimensions();
    end;

    local procedure UpdateGlobalDimensionByProductionOrder(var DimensionValue: Record "Dimension Value"; ProductionOrder: Record "Production Order")
    begin
        CreateDimensionValueForGlobalDimension(DimensionValue);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        ProductionOrder.Modify(true);
    end;

    local procedure UpdateRoutingOperationOnOutputLine(var ItemJnlLine: Record "Item Journal Line"; RoutingNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.FindLast();

        ItemJnlLine.Validate(Type, RoutingLine.Type);
        ItemJnlLine.Validate("No.", RoutingLine."No.");
        ItemJnlLine.Validate("Operation No.", RoutingLine."Operation No.");
        ItemJnlLine.Modify(true);
    end;

    local procedure CreateProductionItemWithComponentAndRouting(var ProdItem: Record Item; var CompItem: Record Item; QtyPer: Decimal; RoundingPrecision: Decimal)
    var
        RoutingLink: Record "Routing Link";
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        CreateItem(ProdItem, ProdItem."Replenishment System"::"Prod. Order");
        CreateItem(CompItem, CompItem."Replenishment System"::Purchase);
        CompItem.Validate("Rounding Precision", RoundingPrecision);
        CompItem.Modify(true);

        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateAndUpdateRoutingSetup(RoutingHeader, RoutingLink.Code);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", QtyPer);
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        UpdateRoutingAndBOMOnItem(ProdItem, ProductionBOMHeader."No.", RoutingHeader."No.");
    end;

    local procedure CreateProductionItemWithDimensionSetup(var Item: Record Item; var Item2: Record Item; var DimensionValue: Record "Dimension Value"; var DimensionValue2: Record "Dimension Value")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithDimension(Item, DimensionValue, Item."Replenishment System"::"Prod. Order");
        CreateItemWithDimension(Item2, DimensionValue2, Item."Replenishment System"::Purchase);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Item."Base Unit of Measure");
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemAndReleasedProdOrderWithDimAndRouting(var ParentItem: Record Item; var ProductionOrder: Record "Production Order"; var ComponentItemNo: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        ComponentItemNo := CreateProductionItemsSetupWithRouting(ParentItem);
        UpdateDimensionOnItem(ParentItem, DimensionValue);
        CreateAndPostItemJournalLine(ComponentItemNo);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", LibraryRandom.RandDec(2, 2));
    end;

    local procedure CreateItemAndReleasedProdOrderWithDim(var ParentItem: Record Item; var ProductionOrder: Record "Production Order")
    var
        ComponentItem: Record Item;
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        CreateProductionItemWithDimensionSetup(ParentItem, ComponentItem, DimensionValue, DimensionValue2);
        CreateAndPostItemJournalLine(ComponentItem."No.");
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ParentItem."No.", LibraryRandom.RandDec(2, 2));
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, LibraryRandom.RandDec(10, 2) + 10);  // Using Large Random Value.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateConsumptionJournal(ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateAndPostProdJournalWithLocation(ItemNo: Code[20]; LocationCode: Code[10]; OutputQty: Decimal; SetupTime: Decimal): Code[20]
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateAndRefreshReleasedProductionOrderWithLocation(ProductionOrder, ItemNo, LocationCode);
        // Enqueue variables for PostUpdatedProdJournalPageHandler
        LibraryVariableStorage.Enqueue(OutputQty);
        LibraryVariableStorage.Enqueue(SetupTime);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
        exit(ProductionOrder."No.");
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; OrderNo: Code[20]; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", OrderNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ILEType: Enum "Item Ledger Document Type"; OrderNo: Code[20]; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", OrderNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ILEType);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
    end;

    local procedure CreateDimensionWithDimensionSetID(var DimensionValue: Record "Dimension Value"; DimensionSetID: Integer): Integer
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
        exit(LibraryDimension.CreateDimSet(DimensionSetEntry."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code));
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure DequeueText(): Text[1024]
    var
        ExpectedValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedValue);  // Dequeue Code or Text type variable.
        exit(Format(ExpectedValue));
    end;

    local procedure DequeueNumber(): Decimal
    var
        ExpectedValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedValue);  // Dequeue Integer or Decimal type variable.
        exit(ExpectedValue);
    end;

    local procedure CreateAndOpenReleasedProductionOrder(var ReleasedProductionOrder: TestPage "Released Production Order"; ItemNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ItemNo, LibraryRandom.RandDec(10, 2));
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrder."No.");
    end;

    local procedure PostOutput(ProductionOrderNo: Code[20]; OutputQty: Decimal; RunTime: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        OutputJournalExplodeRouting(ItemJournalLine, ProductionOrderNo);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Output Quantity", OutputQty);
        ItemJournalLine.Validate("Run Time", RunTime);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostConsumptionJournalLine(var ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; PostingDate: Date; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    begin
        MakeConsumptionJournalLine(ProdOrderLine, Item, PostingDate, LocationCode, BinCode, Qty);
        LibraryInventory.PostItemJournalBatch(ConsumptionItemJournalBatch);
    end;

    local procedure ReservationFromSalesOrder(SalesLine: Record "Sales Line"; TotalQuantity: Decimal; TotalReservedQuantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(false);  // Reserve From Current Line as False. Enqueue Value for Page Handler.
        ReservationFromSalesOrderCurrentLine(SalesLine, TotalQuantity, TotalReservedQuantity);
    end;

    local procedure ReservationFromSalesOrderCurrentLine(SalesLine: Record "Sales Line"; TotalQuantity: Decimal; TotalReservedQuantity: Decimal)
    begin
        // Enqueue Value for Page Handler for verification.
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);  // Qty To Reserve on Reservation Page.
        LibraryVariableStorage.Enqueue(0);  // Qty Reserved on Reservation Page.
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);  // Unreserved Quantity on Reservation Page.
        LibraryVariableStorage.Enqueue(TotalQuantity);  // Total Quantity on Reservation Page.
        LibraryVariableStorage.Enqueue(TotalReservedQuantity);  // Total Quantity and Total Reserved Quantity on Reservation Page.
        SalesLine.ShowReservation();  // Open Reservation Page on Page Handler.
    end;

    local procedure CreateProductionItemSetup(var Item: Record Item): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Item2: Record Item;
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItem(Item2, Item2."Replenishment System"::Purchase);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Item."Base Unit of Measure");
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");
        exit(Item2."No.");
    end;

    local procedure UpdateVariantCodeOnSalesLine(var SalesLine: Record "Sales Line"; VariantCode: Code[10])
    begin
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVariantCodeOnProdOrderLine(ProductionOrder: Record "Production Order"; VariantCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        ProdOrderLine.Validate("Variant Code", VariantCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateShipmentDateOnSalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateSalesOrderWithVariantCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity);
        UpdateVariantCodeOnSalesLine(SalesLine, VariantCode);
    end;

    local procedure OpenSalesOrderPlanning(No: Code[20])
    var
        SalesOrderPlanning: Page "Sales Order Planning";
    begin
        // Open Sales Order Planning page for required Sales Order.
        SalesOrderPlanning.SetSalesOrder(No);
        SalesOrderPlanning.RunModal();
    end;

    local procedure OutputJournalExplodeRouting(var ItemJournalLine: Record "Item Journal Line"; ProductionOrderNo: Code[20])
    var
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure UpdateFlushingMethodOnItem(var Item: Record Item; FlushingMethod: Enum "Flushing Method")
    begin
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure UpdateFlushingMethodOnProdOrderComponent(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        if ProdOrderComponent.FindSet() then
            repeat
                ProdOrderComponent.Validate("Flushing Method", ProdOrderComponent."Flushing Method"::Forward);
                ProdOrderComponent.Modify(true);
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure TrackingOnProdOrderComponent(ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue value for ItemTrackingMode On Page Handler - LotItemTrackingPageHandler.
        ProdOrderComponent.OpenItemTrackingLines();  // Open Page for Select Tracking Entries.
    end;

    local procedure AssignTrackingOnProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ProductionOrderNo: Code[20])
    begin
        FindProductionOrderLine(ProdOrderLine, Status, ProductionOrderNo);
        LibraryVariableStorage.Enqueue(true);  // Enqueue value AssignSerialNo as True for Page Handler - SerialItemTrackingPageHandler.
        ProdOrderLine.OpenItemTrackingLines();  // Open Page for Assign Tracking.
    end;

    local procedure CreateSalesOrderWithTrackedItemSetup(var SalesLine: Record "Sales Line")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        CreateTrackedItem(
          Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Lot-for-Lot", true, 0, ItemTrackingCode.Code);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(10));  // Using Quantity as Random integer for Serial No.
    end;

    local procedure CreateSalesOrderWithLotTrackedItemSetup(var SalesLine: Record "Sales Line")
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        CreateTrackedItem(
          Item, Item."Replenishment System"::"Prod. Order", Item."Reordering Policy"::"Fixed Reorder Qty.", true, 0, ItemTrackingCode.Code);

        LibraryVariableStorage.Enqueue(WillNotAffectExistingEntriesTxt);
        // for MessageHandler
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);

        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(10));  // Using Quantity as Random integer for Serial No.
    end;

    local procedure CreateClosedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ParentItem: Record Item)
    var
        ChildItem: Record Item;
    begin
        ChildItem.Get(CreateProductionItemSetup(ParentItem));
        ProductionBOMHeader.Get(ParentItem."Production BOM No.");
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Closed);
    end;

    local procedure CreateProductionBOMVersionWithNewItem(var Item: Record Item; ProductionBOMHeader: Record "Production BOM Header"; VersionStatus: Enum "BOM Status")
    begin
        LibraryInventory.CreateItem(Item);
        CreateProductionBOMVersionAndUpdateStatus(ProductionBOMHeader, Item."No.", VersionStatus);
    end;

    local procedure CreateProductionBOMVersionAndUpdateStatus(ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; ProdBOMVersionStatus: Enum "BOM Status"): Code[20]
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMHeader."No.", Format(LibraryRandom.RandInt(10)),
          ProductionBOMHeader."Unit of Measure Code");  // Use Random Version Code.
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code", ProductionBOMLine.Type::Item, ItemNo,
          LibraryRandom.RandDec(5, 2));
        ProductionBOMVersion.Validate(Status, ProdBOMVersionStatus);
        ProductionBOMVersion.Modify(true);
        exit(ProductionBOMVersion."Version Code");
    end;

    local procedure OpenProdBOMWhereUsedPage(var ProdBOMWhereUsed2: TestPage "Prod. BOM Where-Used"; Item: Record Item)
    var
        ProdBOMWhereUsed: Page "Prod. BOM Where-Used";
    begin
        // Open Production BOM Where Used page.
        ProdBOMWhereUsed2.Trap();
        ProdBOMWhereUsed.SetItem(Item, WorkDate());
        ProdBOMWhereUsed.Run();
    end;

    local procedure CreateAndRefreshReleasedProductionOrderWithLocation(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, SourceNo,
          LibraryRandom.RandDec(10, 2));
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateRelProdOrder(var ProductionOrder: Record "Production Order")
    begin
        ProductionOrder.Status := ProductionOrder.Status::Released;
        ProductionOrder."No." := LibraryUtility.GenerateGUID();
        ProductionOrder.Insert();
    end;

    local procedure CreateRelProdOrderWithDateTime(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; EndingDate: Date; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, 1);
        ProductionOrder.Validate("Ending Time", 000000T);
        ProductionOrder.Validate("Ending Date", EndingDate);
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
    end;

    local procedure CreateProdOrderComp(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; SuppliedByLineNo: Integer; CompletelyPicked: Boolean)
    begin
        ProdOrderComponent.Status := ProdOrderComponent.Status::Released;
        ProdOrderComponent."Prod. Order No." := ProdOrderNo;
        ProdOrderComponent."Completely Picked" := CompletelyPicked;
        ProdOrderComponent."Supplied-by Line No." := SuppliedByLineNo;
        ProdOrderComponent.Insert();
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header"; RoutingLinkCode: Code[10]; RoutingLinkCode2: Code[10])
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter, 080000T, 160000T);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandDec(100, 2));
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Machine Center", MachineCenter."No.", RoutingLinkCode);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenter."No.", RoutingLinkCode2);
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateAndUpdateRoutingSetup(var RoutingHeader: Record "Routing Header"; RoutingLinkCode: Code[10])
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter, 080000T, 160000T);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', WorkDate()), CalcDate('<2M>', WorkDate()));
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenter."No.", RoutingLinkCode);
        UpdateRoutingLineSetup(RoutingLine, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateTwoMachineCenters(var MachineCenter1: Record "Machine Center"; var MachineCenter2: Record "Machine Center")
    var
        WorkCenter: Record "Work Center";
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
    begin
        CreateWorkCenter(WorkCenter, 080000T, 160000T);
        LibraryManufacturing.CreateMachineCenter(MachineCenter1, WorkCenter."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter1, CalcDate('<-6M>', WorkDate()), CalcDate('<6M>', WorkDate()));
        LibraryManufacturing.CreateMachineCenter(MachineCenter2, WorkCenter."No.", LibraryRandom.RandInt(10));
        LibraryManufacturing.CalculateMachCenterCalendar(MachineCenter2, CalcDate('<-6M>', WorkDate()), CalcDate('<6M>', WorkDate()));
        LibraryManufacturing.CreateCapacityConstrainedResource(
          CapacityConstrainedResource, CapacityConstrainedResource."Capacity Type"::"Machine Center", MachineCenter2."No.");
        CapacityConstrainedResource.Validate("Critical Load %", LibraryRandom.RandDec(100, 2));
        CapacityConstrainedResource.Modify(true);
    end;

    local procedure CreateRoutingLineWithTimes(var RoutingHeader: Record "Routing Header"; MachineCenterNo: Code[20]; RunTime: Decimal; WaitTime: Decimal; SendAheadQty: Decimal)
    var
        RoutingLine: Record "Routing Line";
    begin
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Machine Center", MachineCenterNo, '');
        UpdateRoutingLine(RoutingLine, 0, RunTime, WaitTime, 0);
        RoutingLine.Validate("Send-Ahead Quantity", SendAheadQty);
        RoutingLine.Modify(true);
    end;

    local procedure CreateRoutingHeaderWithTwoLines(MachineCenterNo1: Code[20]; MachineCenterNo2: Code[20]; RunTime1: Decimal; RunTime2: Decimal; WaitTime1: Decimal; WaitTime2: Decimal; SendAheadQty1: Decimal; SendAheadQty2: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLineWithTimes(RoutingHeader, MachineCenterNo1, RunTime1, WaitTime1, SendAheadQty1);
        CreateRoutingLineWithTimes(RoutingHeader, MachineCenterNo2, RunTime2, WaitTime2, SendAheadQty2);
        ChangeStatusOfProductionRoutingHeader(RoutingHeader, RoutingHeader.Status::Certified);
        exit(RoutingHeader."No.");
    end;

    local procedure MakeConsumptionJournalLine(var ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; PostingDate: Date; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    begin
        LibraryManufacturing.CreateConsumptionJournalLine(
          ConsumptionItemJournalBatch, ProdOrderLine, Item, PostingDate, LocationCode, '', Qty, LibraryRandom.RandDec(1000, 2));
        UpdateBinCodeOnItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name, BinCode);
    end;

    local procedure UpdateRoutingLineSetup(var RoutingLine: Record "Routing Line"; SetupTime: Decimal; RunTime: Decimal)
    begin
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Modify(true);
    end;

    local procedure UpdateRoutingAndBOMOnItem(var Item: Record Item; ProdBOMHeaderNo: Code[20]; RoutingNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProdBOMHeaderNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure UpdateRoutingLine(var RoutingLine: Record "Routing Line"; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal)
    begin
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Wait Time", WaitTime);
        RoutingLine.Validate("Move Time", MoveTime);
        RoutingLine.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; Type: Enum "Capacity Type Routing"; No: Code[20]; RoutingLinkCode: Code[10])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, Type, No);
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Modify(true);
    end;

    local procedure CreateWorkCenterRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal)
    begin
        CreateRoutingLine(RoutingLine, RoutingHeader, RoutingLine.Type::"Work Center", WorkCenterNo, '');
        UpdateRoutingLine(RoutingLine, SetupTime, RunTime, WaitTime, MoveTime);
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

    local procedure FindProdOrderBySourceNo(var ProdOrder: Record "Production Order"; SalesLineDocumentNo: Code[20])
    begin
        ProdOrder.SetCurrentKey("Source No.");
        ProdOrder.SetRange("Source No.", SalesLineDocumentNo);
        ProdOrder.FindFirst();
    end;

    local procedure CreateProductionBOMLineWithRoutingLinkCode(ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);  // Quantity per as 1.
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOMWithRoutingLinkCode(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; ItemNo: Code[20]; RoutingLinkCode: Code[10]; RoutingLinkCode2: Code[10])
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        CreateProductionBOMLineWithRoutingLinkCode(ProductionBOMHeader, ItemNo, RoutingLinkCode);
        CreateProductionBOMLineWithRoutingLinkCode(ProductionBOMHeader, ItemNo, RoutingLinkCode2);
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateProductionItemsSetupWithRoutingLinkCode(var Item: Record Item; RoutingLinkCode: Code[10]; RoutingLinkCode2: Code[10]): Code[20]
    var
        Item2: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order");
        UpdateFlushingMethodOnItem(Item2, Item2."Flushing Method"::Backward);
        CreateRoutingSetup(RoutingHeader, RoutingLinkCode, RoutingLinkCode2);
        CreateAndCertifyProductionBOMWithRoutingLinkCode(
          ProductionBOMHeader, Item."Base Unit of Measure", Item2."No.", RoutingLinkCode, RoutingLinkCode2);
        UpdateRoutingAndBOMOnItem(Item, ProductionBOMHeader."No.", RoutingHeader."No.");
        exit(Item2."No.");
    end;

    local procedure CreateProductionItemsSetupWithRouting(var Item: Record Item): Code[20]
    var
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLink: Record "Routing Link";
    begin
        CreateItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItem(Item2, Item2."Replenishment System"::Purchase);
        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        CreateAndUpdateRoutingSetup(RoutingHeader, RoutingLink.Code);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item2."No.", Item2."Base Unit of Measure");
        UpdateRoutingAndBOMOnItem(Item, ProductionBOMHeader."No.", RoutingHeader."No.");
        exit(Item2."No.");
    end;

    local procedure FindProdOrderComponentForRoutingLinkCode(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    begin
        FilterOnProdOrderComponent(ProdOrderComponent, Status, ProdOrderNo, ItemNo);
        ProdOrderComponent.SetRange("Routing Link Code", RoutingLinkCode);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FilterOnItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateAndCertifyProductionBOMWithDiffUnitOfMeasureCode(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        CreateProductionBOM(ProductionBOMHeader, ProductionBOMLine, BaseUnitOfMeasure, ProductionBOMLine.Type::Item, ItemNo);
        ProductionBOMLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        ProductionBOMLine.Modify(true);
        ChangeStatusOfProductionBOM(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateAndPostPurchaseOrderWithItemTracking(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LibraryRandom.RandDec(10, 2) + 50);  // Using Large Quantity Value.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndUpdatePurchUnitOfMeasureOnItem(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure FindAssignedLotNo(ItemNo: Code[20]): Code[50]
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.FindLast();
        exit(ItemLedgEntry."Lot No.");
    end;

    local procedure SetupPostProductionJournal(ProductionOrder: Record "Production Order"; LineNo: Integer; LotNo: Code[50]; QuantityToPost: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Set Quantity & Lot No."); // Enqueued for ItemJournalLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QuantityToPost);
        ProductionJournalMgt.Handling(ProductionOrder, LineNo);
    end;

    local procedure UpdateTrackingCodeOnItem(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure UpdateItemTrackingOnProdOrderComponent(ProductionOrder: Record "Production Order"; CompItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", CompItemNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        ProdOrderComponent.OpenItemTrackingLines();
    end;

    local procedure UpdateItemTrackingOnProdOrderLine(ProductionOrder: Record "Production Order"; LotNo: Code[50])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Set Quantity & Lot No.");
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ProdOrderLine.Quantity);
        ProdOrderLine.OpenItemTrackingLines();
    end;

    local procedure UpdateQtyOnProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; NewQty: Decimal)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        ProdOrderComponent.Quantity := NewQty;
        ProdOrderComponent."Quantity (Base)" := UOMMgt.CalcBaseQty(NewQty, ProdOrderComponent."Qty. per Unit of Measure");
        ProdOrderComponent."Remaining Quantity" := NewQty;
        ProdOrderComponent."Remaining Qty. (Base)" := UOMMgt.CalcBaseQty(NewQty, ProdOrderComponent."Qty. per Unit of Measure");
        ProdOrderComponent.Modify(true);
    end;

    local procedure VerifyCapacityEntryPosted(ProdOrderNo: Code[20]; ItemNo: Code[20])
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        CapacityLedgerEntry.SetRange("Item No.", ItemNo);
        Assert.IsFalse(CapacityLedgerEntry.IsEmpty, StrSubstNo(LedgEntryNotPostedErr, CapacityLedgerEntry.TableCaption));
    end;

    local procedure VerifyRunTimeOnCapacityLedgerEntries(ProdOrderNo: Code[20]; RunTime: Decimal)
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        CapacityLedgerEntry.SetRange("Order Type", CapacityLedgerEntry."Order Type"::Production);
        CapacityLedgerEntry.SetRange("Order No.", ProdOrderNo);
        CapacityLedgerEntry.CalcSums("Run Time");
        CapacityLedgerEntry.TestField("Run Time", RunTime);
    end;

    local procedure VerifyTrackingOnRequisitionLine(ItemNo: Code[20]; LotNo: Variant; Quantity: Variant)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Verify Entries");  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Accept Action Message", false);
        RequisitionLine.FindFirst();
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue for Page Handler - LotItemTrackingPageHandler.
        RequisitionLine.OpenItemTrackingLines();
    end;

    local procedure VerifyItemTrackingOnItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Get Lot Quantity");
        LibraryVariableStorage.Enqueue(LotNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        Assert.AreEqual(Qty, LibraryVariableStorage.DequeueDecimal(), WrongLotQtyOnItemJnlErr);
    end;

    local procedure VerifyDimensionSetEntry(DimensionSetID: Integer; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.Get(DimensionSetID, DimensionCode);
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    local procedure VerifyDimensionOnProductionOrderLine(Status: Enum "Production Order Status"; ProductionOrderNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, Status, ProductionOrderNo);
        VerifyDimensionSetEntry(ProdOrderLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure VerifyDimensionOnProdOrderComponent(Status: Enum "Production Order Status"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; DimensionValue: Record "Dimension Value")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, Status, ProductionOrderNo, ItemNo);
        VerifyDimensionSetEntry(ProdOrderComponent."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure VerifyDimensionOnItemLedgerEntry(OrderNo: Code[20]; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; DimensionValue: Record "Dimension Value")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, OrderNo, ItemNo, EntryType);
        VerifyDimensionSetEntry(ItemLedgerEntry."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure VerifyDimensionsOnItemLedgerEntry(OrderNo: Code[20]; ItemNo: Code[20]; DimensionValue: Record "Dimension Value"; DimensionValue2: Record "Dimension Value")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, OrderNo, ItemNo, ItemLedgerEntry."Entry Type"::Consumption);
        VerifyDimensionSetEntry(ItemLedgerEntry."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        VerifyDimensionSetEntry(ItemLedgerEntry."Dimension Set ID", DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    local procedure VerifyDimensionsOnValueEntry(OrderNo: Code[20]; ItemNo: Code[20]; DimensionValue: Record "Dimension Value"; DimensionValue2: Record "Dimension Value")
    var
        ValueEntry: Record "Value Entry";
    begin
        FindValueEntry(ValueEntry, ValueEntry."Item Ledger Entry Type"::Consumption, OrderNo, ItemNo);
        VerifyDimensionSetEntry(ValueEntry."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        VerifyDimensionSetEntry(ValueEntry."Dimension Set ID", DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    local procedure VerifyDimensionsOnItemJournalLine(ItemNo: Code[20]; DimensionValue: Record "Dimension Value"; DimensionValue2: Record "Dimension Value")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FilterOnItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        VerifyDimensionSetEntry(ItemJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        VerifyDimensionSetEntry(ItemJournalLine."Dimension Set ID", DimensionValue2."Dimension Code", DimensionValue2.Code);
    end;

    local procedure VerifyItemLedgerEntryPosted(ProdOrderNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProdOrderNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        Assert.IsFalse(ItemLedgerEntry.IsEmpty, StrSubstNo(LedgEntryNotPostedErr, ItemLedgerEntry.TableCaption));
    end;

    local procedure VerifyTotalQuantityOnReservationPage(var Reservation: TestPage Reservation; SummaryType: Text[80])
    begin
        Reservation.FILTER.SetFilter("Summary Type", SummaryType);
        Reservation."Reserve from Current Line".Invoke();
        Reservation."Total Quantity".AssertEquals(DequeueNumber());
    end;

    local procedure VerifyQuantityOnReservationPage(Reservation: TestPage Reservation)
    begin
        Reservation.QtyToReserveBase.AssertEquals(DequeueNumber());
        Reservation.QtyReservedBase.AssertEquals(DequeueNumber());
        Reservation.UnreservedQuantity.AssertEquals(DequeueNumber());
    end;

    local procedure VerifyProductionOrderLine(Status: Enum "Production Order Status"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, Status, ProductionOrderNo);
        ProdOrderLine.TestField("Item No.", ItemNo);
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyProdOrderLineFromSalesLine(SalesLine: Record "Sales Line")
    var
        ProdOrder: Record "Production Order";
    begin
        FindProdOrderBySourceNo(ProdOrder, SalesLine."Document No.");
        VerifyProductionOrderLine(
          ProdOrder.Status, ProdOrder."No.", SalesLine."No.", SalesLine.Quantity, SalesLine."Location Code");
    end;

    local procedure VerifyProdOrderLineDoesNotExist(SalesLine: Record "Sales Line")
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProdOrderBySourceNo(ProdOrder, SalesLine."Document No.");
        asserterror FindProductionOrderLine(ProdOrderLine, ProdOrder.Status, ProdOrder."No.");
        Assert.ExpectedError(ProdOrderLineExistsErr);
    end;

    local procedure VerifyProdOrderLineBinCode(ExpectedBinCode: Code[20]; SalesLine: Record "Sales Line")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrder: Record "Production Order";
    begin
        ProdOrder.SetRange("Source No.", SalesLine."Document No.");
        ProdOrder.FindFirst();

        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine.FindFirst();

        Assert.AreEqual(ExpectedBinCode, ProdOrderLine."Bin Code", FromProductionBinCodeErr);
    end;

    local procedure VerifyProductionOrderRoutingLine(ProductionOrderNo: Code[20])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo);
        ProdOrderRoutingLine.TestField(
          "Expected Capacity Need", ProdOrderRoutingLine."Ending Date-Time" - ProdOrderRoutingLine."Starting Date-Time");
    end;

    local procedure VerifyProductionOrderRoutingLineTimes(ProductionOrderNo: Code[20]; StartingTime: Time; EndingTime: Time)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo);
        ProdOrderRoutingLine.TestField("Starting Time", StartingTime);
        ProdOrderRoutingLine.TestField("Ending Time", EndingTime);
    end;

    local procedure VerifyFirstProdOrderRoutingLineWaitTime(ProductionOrderNo: Code[20]; WaitTime: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProdOrderRoutingLine(ProdOrderRoutingLine, ProductionOrderNo);
        ProdOrderRoutingLine.TestField("Starting Date-Time", ProdOrderRoutingLine."Ending Date-Time" - WaitTime * 60 * 1000); // milliseconds to minutes
    end;

    local procedure VerifyLastProdOrderRoutingLineWaitTime(ProductionOrderNo: Code[20]; WaitTime: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.FindLast();
        ProdOrderRoutingLine.TestField("Starting Date-Time", ProdOrderRoutingLine."Ending Date-Time" - WaitTime * 60 * 1000); // milliseconds to minutes
    end;

    local procedure VerifyLinesCountOnProdBOMWhereUsedPage(ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used"; ExpectedLineCount: Integer)
    var
        ActualLineCount: Integer;
    begin
        if Format(ProdBOMWhereUsed."Item No.") <> '' then
            repeat
                ActualLineCount += 1;
            until not ProdBOMWhereUsed.Next();
        Assert.AreEqual(ExpectedLineCount, ActualLineCount, NumberOfLineEqualErr);
    end;

    local procedure VerifyProdBOMWhereUsedPageVersion(ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used"; ProdBOMVersionStatus: Enum "BOM Status"; ItemNo: Code[20]; ItemNo2: Code[20]; VersionCode: Code[20])
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        if ProdBOMVersionStatus = ProductionBOMVersion.Status::Certified then begin
            VerifyLinesCountOnProdBOMWhereUsedPage(ProdBOMWhereUsed, 2);  // No. of Line value required on Production BOM Where Used Page. 2 signifies there are two Item Hierarchy.
            ProdBOMWhereUsed.FindFirstField("Item No.", ItemNo);
            ProdBOMWhereUsed."Version Code".AssertEquals(VersionCode);
        end else begin
            VerifyLinesCountOnProdBOMWhereUsedPage(ProdBOMWhereUsed, 1);  // No. of Line value required on Production BOM Where Used Page. 1 signifies there is only one Item Hierachy because BOM Version status is closed for the second one.
            ProdBOMWhereUsed."Item No.".AssertEquals(ItemNo2);
        end;
    end;

    local procedure VerifyProdBOMWhereUsedPage(ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used"; ProdBOMHeaderStatus: Enum "BOM Status"; ItemNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        case ProdBOMHeaderStatus of
            ProductionBOMHeader.Status::Certified:
                begin
                    VerifyLinesCountOnProdBOMWhereUsedPage(ProdBOMWhereUsed, 1);
                    ProdBOMWhereUsed.FindFirstField("Item No.", ItemNo);
                end;
            ProductionBOMHeader.Status::Closed:
                VerifyLinesCountOnProdBOMWhereUsedPage(ProdBOMWhereUsed, 0);
        end;
    end;

    local procedure VerifyProdOrderComponent(Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponentForRoutingLinkCode(ProdOrderComponent, Status, ProdOrderNo, ItemNo, RoutingLinkCode);
        ProdOrderComponent.TestField("Remaining Quantity", ProdOrderComponent."Expected Quantity");
    end;

    local procedure VerifyProdOrderRoutingLine(ProdOrderNo: Code[20]; WaitTime: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status::Released);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderRoutingLine.FindLast();
        ProdOrderRoutingLine.TestField("Starting Date-Time", ProdOrderRoutingLine."Ending Date-Time" - WaitTime * 60 * 1000);
    end;

    local procedure VerifyOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; Type: Enum "Capacity Type Routing"; OutputQuantity: Decimal)
    begin
        ItemJournalLine.SetRange(Type, Type);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Output Quantity", OutputQuantity);
    end;

    local procedure VerifyDimensionOnOutputJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; DimensionValue: Record "Dimension Value")
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindSet();
        repeat
            VerifyDimensionSetEntry(ItemJournalLine."Dimension Set ID", DimensionValue."Dimension Code", DimensionValue.Code);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyQuantityOnItemLedgerEntries(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Qty: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.CalcSums(Quantity);
        ItemLedgerEntry.TestField(Quantity, Qty);
    end;

    local procedure VerifyReleasedProductionOrder(ProductionOrderNo: Code[20]; SourceNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
        ProductionOrder.TestField("Source No.", SourceNo);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.TestField(Binding, ReservationEntry.Binding::" ");
        until ReservationEntry.Next() = 0;
    end;

    local procedure VerifyProdOrderLineStartingDateTime(ProductionOrder: Record "Production Order"; ErrorMsg: Text)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(ProductionOrder."Due Date" - 2, DT2Date(ProdOrderLine."Starting Date-Time"), ErrorMsg);
    end;

    local procedure VerifyCapacityAmountOnValueEntries(ProdOrderNo: Code[20]; CostAmount: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Order Type", ValueEntry."Order Type"::Production);
        ValueEntry.SetRange("Order No.", ProdOrderNo);
        ValueEntry.CalcSums("Cost Amount (Actual)");
        Assert.AreNearlyEqual(CostAmount, ValueEntry."Cost Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(), '');
    end;

    local procedure UpdateVariantCodeOnProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ItemVariantCode: Code[10])
    begin
        ProdOrderComponent.Validate("Variant Code", ItemVariantCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateProdOrderComponentWithDifferentVariant(ProdOrderComponent: Record "Prod. Order Component"; ItemVariantCode: Code[10])
    var
        ProdOrderComponent2: Record "Prod. Order Component";
    begin
        ProdOrderComponent2.Init();
        ProdOrderComponent2.TransferFields(ProdOrderComponent);
        ProdOrderComponent2."Line No." := ProdOrderComponent."Line No." + 10000;
        ProdOrderComponent2.Validate("Variant Code", ItemVariantCode);
        ProdOrderComponent2.Insert(true);
    end;

    local procedure FindProdOrderComponentWithVariantCode(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20]; ItemVariantCode: Code[10])
    begin
        FilterOnProdOrderComponent(ProdOrderComponent, Status, ProdOrderNo, ItemNo);
        ProdOrderComponent.SetRange("Variant Code", ItemVariantCode);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure PostConsumption(ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; PostingDate: Date; ItemNo: Code[20]; ItemVariantCode: Code[10]; Qty: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJnlTemplate, ItemJnlTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJnlBatch, ItemJnlTemplate.Type, ItemJnlTemplate.Name);

        LibraryInventory.CreateItemJournalLine(
          ItemJnlLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJnlLine."Entry Type"::Consumption, ItemNo, Qty);
        ItemJnlLine.Validate("Variant Code", ItemVariantCode);
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrderNo);
        ItemJnlLine.Validate("Order Line No.", ProdOrderLineNo);
        ItemJnlLine.Validate("Posting Date", PostingDate);
        ItemJnlLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");
    end;

    local procedure CreateProductionOrder(var ProdOrderLine: Record "Prod. Order Line"; RoutingNo: Code[20]; ItemFinal: Record Item; Quantity: Decimal): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemFinal."No.", Quantity);
        ProdOrderLine.Status := ProdOrderLine.Status::Released;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Routing Reference No." := 10000;
        ProdOrderLine.Validate("Item No.", ItemFinal."No.");
        ProdOrderLine.Validate(Quantity, Quantity);
        ProdOrderLine."Routing No." := RoutingNo;
        ProdOrderLine.Insert(true);
        exit(ProductionOrder."No.");
    end;

    local procedure CreateProdOrderComponentWithRountingLinkCode(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; RoutingLinkCode: Code[10]; ComponentCount: Integer; ItemComp: Record Item)
    var
        i: Integer;
    begin
        for i := 1 to ComponentCount do begin
            ProdOrderComponent.Init();
            ProdOrderComponent.Validate(Status, ProdOrderLine.Status);
            ProdOrderComponent."Prod. Order No." := ProdOrderLine."Prod. Order No.";
            ProdOrderComponent."Prod. Order Line No." := ProdOrderLine."Line No.";
            ProdOrderComponent.Insert(true);

            ProdOrderComponent."Item No." := ItemComp."No.";
            ProdOrderComponent.Quantity := 1;
            ProdOrderComponent."Quantity per" := 1;
            ProdOrderComponent."Expected Quantity" := ProdOrderLine.Quantity;
            ProdOrderComponent."Quantity (Base)" := 1;
            ProdOrderComponent."Expected Qty. (Base)" := ProdOrderLine.Quantity;
            ProdOrderComponent."Remaining Quantity" := 1;
            ProdOrderComponent."Remaining Qty. (Base)" := 1;
            ProdOrderComponent."Routing Link Code" := RoutingLinkCode;
            ProdOrderComponent.Modify(true);
        end;
    end;

    local procedure CreateProdOrderRoutingLineWithRoutingLinkCode(ProdOrderLine: Record "Prod. Order Line"; WorkCenter: Record "Work Center"; CapacityType: Enum "Capacity Type"; RoutingLinkCode: Code[10]; RoutingLineCount: Integer)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        i: Integer;
    begin
        for i := 1 to RoutingLineCount do begin
            ProdOrderRoutingLine.Init();
            ProdOrderRoutingLine.Validate(Status, ProdOrderLine.Status);
            ProdOrderRoutingLine.Validate("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            ProdOrderRoutingLine.Validate("Routing No.", ProdOrderLine."Routing No.");
            ProdOrderRoutingLine.Validate("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            ProdOrderRoutingLine.Validate("Operation No.", Format(LibraryRandom.RandInt(100)));
            ProdOrderRoutingLine.Insert(true);

            ProdOrderRoutingLine.Validate(Type, CapacityType);
            ProdOrderRoutingLine.Validate("Work Center No.", WorkCenter."No.");
            ProdOrderRoutingLine.Validate("No.", WorkCenter."No.");
            ProdOrderRoutingLine."Flushing Method" := ProdOrderRoutingLine."Flushing Method"::Backward;
            ProdOrderRoutingLine."Setup Time" := LibraryRandom.RandInt(100);
            ProdOrderRoutingLine."Run Time" := LibraryRandom.RandInt(100);
            ProdOrderRoutingLine.Validate("Routing Link Code", RoutingLinkCode);
            ProdOrderRoutingLine.Modify(true);
        end;
    end;

    local procedure CreateRoutingWithWorkCenter(WorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; LotSize: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Lot Size", LotSize);
        RoutingLine.Validate("Routing Link Code", Format(100));
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateWorkCenterWithCalendar(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Direct Unit Cost", 50);
        WorkCenter.Validate("Unit of Measure Code", 'HOURS');
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate(Efficiency, 100);
        WorkCenter.Validate("Flushing Method", WorkCenter."Flushing Method"::Backward);
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', Today()), CalcDate('<1M>', Today()));
    end;

    local procedure CreateFinalItem(var ItemRec: Record Item)
    begin
        LibraryInventory.CreateItem(ItemRec);
        ItemRec.Validate("Base Unit of Measure", 'PCS');
        ItemRec.Validate("Replenishment System", ItemRec."Replenishment System"::"Prod. Order");
        ItemRec.Modify(true);
    end;

    local procedure CreateCompItem(var ItemRec: Record Item)
    begin
        LibraryInventory.CreateItem(ItemRec);
        ItemRec.Validate("Flushing Method", ItemRec."Flushing Method"::Manual);
        ItemRec.Validate("Replenishment System", ItemRec."Replenishment System"::Purchase);
        ItemRec.Modify(true);
    end;

    local procedure CreateFamily(var Family: Record Family; RoutingNo: Code[20]; ItemNo: Code[20])
    var
        FamilyLine: Record "Family Line";
    begin
        LibraryManufacturing.CreateFamily(Family);
        Family.Validate("Routing No.", RoutingNo);
        Family.Modify(true);
        LibraryManufacturing.CreateFamilyLine(FamilyLine, Family."No.", ItemNo, LibraryRandom.RandInt(5));
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; Family: Record Family; Quantity: Decimal; SourceType: Enum "Prod. Order Source Type"; FamilyItem: record Item; RoutingNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, SourceType, Family."No.", Quantity);
        ProductionOrder.Validate("Source Type", ProductionOrder."Source Type"::Family);
        ProductionOrder.Validate("Source No.", Family."No.");
        ProductionOrder.Modify(true);
        ProdOrderLine.Init();
        ProdOrderLine.Status := ProdOrderLine.Status::"Firm Planned";
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine.Insert(true);
        ProdOrderLine."Routing Reference No." := 10000;
        ProdOrderLine.Validate("Item No.", FamilyItem."No.");
        ProdOrderLine.Validate(Quantity, Quantity);
        ProdOrderLine."Routing No." := RoutingNo;
        ProdOrderLine.Modify();

        // [GIVEN] Create Work Center with Calendar
        CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create Prod. Order Routing Line with Routing Link Code.
        CreateProdOrderRoutingLineWithRoutingLinkCode(ProdOrderLine, WorkCenter, ProdOrderRoutingLine.Type::"Work Center", '100', 1);
        ProdOrderRoutingLine."Routing Reference No." := 10000;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnBeforeAssistEditTrackingNo', '', false, false)]
    local procedure CheckTrackingSpecOnBeforeAssistEditTrackingNoEvent(var TempTrackingSpecification: Record "Tracking Specification" temporary; var SearchForSupply: Boolean; CurrentSignFactor: Integer; LookupMode: Enum "Item Tracking Type"; MaxQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Get(
          TempTrackingSpecification."Source Subtype", TempTrackingSpecification."Source ID",
          TempTrackingSpecification."Source Prod. Order Line", TempTrackingSpecification."Source Ref. No.");
        ProdOrderComponent.TestField("Item No.", TempTrackingSpecification."Item No.");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure LotItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::"Verify Entries":
                begin
                    ItemTrackingLines."Lot No.".AssertEquals(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingMode::"Set Lot No.":
                ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
            ItemTrackingMode::"Set Quantity & Lot No.":
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingMode::"Get Lot Quantity":
                begin
                    ItemTrackingLines.FILTER.SetFilter("Lot No.", LibraryVariableStorage.DequeueText());
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Quantity (Base)".AsDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SerialItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        AssignSerialNo: Variant;
        AssignSerialNo2: Boolean;
        LineCount: Integer;
    begin
        LibraryVariableStorage.Dequeue(AssignSerialNo);
        AssignSerialNo2 := AssignSerialNo;  // Assign Variant to Boolean.

        if AssignSerialNo2 then
            ItemTrackingLines."Assign Serial No.".Invoke()
        else begin
            ItemTrackingLines.Last();
            repeat
                ItemTrackingLines."Quantity (Base)".AssertEquals(1);  // Using One for Serial No.
                ItemTrackingLines."Qty. to Handle (Base)".AssertEquals(1);  // Using One for Serial No.
                Assert.IsTrue(ItemTrackingLines."Serial No.".Value > ' ', SerialNoErr);
                LineCount += 1;
            until not ItemTrackingLines.Previous();
            Assert.AreEqual(DequeueNumber(), LineCount, NumberOfLineEqualErr);  // Verify Number of line - Tracking Line.
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        WhseItemTrackingLines.Quantity.SetValue(WhseItemTrackingLines.Quantity3.AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPlanningPageHandler(var OrderPlanning: TestPage "Order Planning")
    begin
        OrderPlanning.CalculatePlan.Invoke();
        OrderPlanning."Demand Order No.".AssertEquals(DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        VerifyQuantityOnReservationPage(Reservation);
        VerifyTotalQuantityOnReservationPage(Reservation, SummaryTypeItemLedgerEntryTxt);
        VerifyTotalQuantityOnReservationPage(Reservation, SummaryTypePurchaseLineOrderTxt);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationModalPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.CancelReservationCurrentLine.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationDetailPageHandler(var Reservation: TestPage Reservation)
    var
        ReserveFromCurrentLine: Variant;
        ReserveFromCurrentLine2: Boolean;
    begin
        LibraryVariableStorage.Dequeue(ReserveFromCurrentLine);
        ReserveFromCurrentLine2 := ReserveFromCurrentLine;  // Assign Variant to Boolean.
        if ReserveFromCurrentLine2 then
            Reservation."Reserve from Current Line".Invoke()
        else begin
            VerifyQuantityOnReservationPage(Reservation);
            Reservation."Total Quantity".AssertEquals(DequeueNumber());
            Reservation.TotalReservedQuantity.AssertEquals(DequeueNumber());
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningPageHandler(var SalesOrderPlanning: TestPage "Sales Order Planning")
    begin
        SalesOrderPlanning."Item No.".AssertEquals(DequeueText());
        SalesOrderPlanning.Available.AssertEquals(DequeueNumber());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateOrderFromSalesModalPageHandler(var CreateOrderFromSales: Page "Create Order From Sales"; var Response: Action)
    begin
        Response := ACTION::Yes;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        ItemJournalLine: Record "Item Journal Line";
        ConsumptionQuantity: Variant;
    begin
        ProductionJournal.FILTER.SetFilter("Entry Type", Format(ItemJournalLine."Entry Type"::Consumption));
        LibraryVariableStorage.Dequeue(ConsumptionQuantity);
        ProductionJournal.Quantity.AssertEquals(ConsumptionQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler2(var ProductionJournal: TestPage "Production Journal")
    var
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        ProductionJournal.FILTER.SetFilter("Entry Type", Format(ItemJournalLine."Entry Type"::Consumption));
        Quantity := LibraryVariableStorage.PeekDecimal(3); // third index variable
        ProductionJournal.ItemTrackingLines.Invoke();
        ProductionJournal.Quantity.SetValue(Quantity);
        LibraryVariableStorage.Enqueue(PostingQst); // Enqueued for ConfirmHandler
        LibraryVariableStorage.Enqueue(JournalPostedMsg); // Enqueued for MessageHandler
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProdJournalByPageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        ProductionOrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ProductionOrderNo);
        ProductionJournal.FILTER.SetFilter("Document No.", ProductionOrderNo);
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalViewFlushedCompModalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.FILTER.SetFilter("Item No.", LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(ProductionJournal.Quantity.AsDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        NewDimensionValueCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(NewDimensionValueCode);
        EditDimensionSetEntries.DimensionValueCode.SetValue(NewDimensionValueCode);
        EditDimensionSetEntries.OK().Invoke();
    end;

    [FilterPageHandler]
    [Scope('OnPrem')]
    procedure ItemFilterRequestPageHandler(var ItemRecordRef: RecordRef): Boolean
    var
        Item: Record Item;
    begin
        ItemRecordRef.GetTable(Item);
        Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        ItemRecordRef.SetView(Item.GetView());
        LibraryVariableStorage.Enqueue(ItemRecordRef.GetFilters);
        LibraryVariableStorage.Enqueue(ItemRecordRef.GetView());
        exit(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OnLookUpLocationPageHandler(var LocationList: TestPage "Location List")
    begin
        LocationList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        LocationList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OnLookUpVariantPageHandler(var ItemVariants: TestPage "Item Variants")
    begin
        ItemVariants.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        ItemVariants.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MatrixRowLimitMessageHandler(MatrixRowLimitMessage: Text[1024])
    begin
        Assert.IsSubstring(MatrixRowLimitMessage, MatrixRowLimitMsg);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(Message, ExpectedMessage), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmQstHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(AreSameMessages(Question, ExpectedMessage), Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostUpdatedProdJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        OutputQty: Variant;
        SetupTime: Variant;
    begin
        LibraryVariableStorage.Dequeue(OutputQty);
        LibraryVariableStorage.Dequeue(SetupTime);
        LibraryVariableStorage.Enqueue(JournalLinePostedMsg); // Required inside MessageHandler.
        ProductionJournal.First();
        ProductionJournal."Output Quantity".SetValue(OutputQty);
        ProductionJournal."Setup Time".SetValue(SetupTime);
        ProductionJournal.Post.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderCreatedMessageHandler(Message: Text[1024])
    begin
    end;

    [HyperlinkHandler]
    [Scope('OnPrem')]
    procedure HyperlinkHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(StrPos(Message, StrSubstNo('page=%1', LibraryVariableStorage.DequeueInteger())) > 0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.QtyToCreate.SetValue(1);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SalesOrderPlanningModalPageHandler(var SalesOrderPlanning: TestPage "Sales Order Planning")
    begin
        SalesOrderPlanning."&Create Prod. Order".Invoke();
    end;
}

