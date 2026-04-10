codeunit 137075 "SCM Planning Order Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [Order Tracking] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        LocationBlue: Record Location;
        LocationSilver: Record Location;
        LocationInTransit: Record Location;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        ItemFilterTok: Label '%1|%2', Locked = true;
        UnexpectedErrorMsg: Label 'Unexpected message';
        NoTrackingLinesErr: Label 'There are no order tracking entries for this line';
        ControlOptions: Option Purchase,Sale,Verification;
        ReqLineShouldNotExistErr: Label 'The requisition line for location %1 should not exist', Comment = '%1 = Location code';
        ReqLineShouldExistErr: Label 'The requisition line for location %1 should exist', Comment = '%1 = Location code';
        ReservedQuantityErr: Label 'Reserved Quantity should not be cleared';
        ItemTrackingDefinedErr: Label 'Item tracking is defined for item %1 in the Requisition Line', Comment = '%1 = Item No.';
        DialogErr: Label 'Dialog';
        OrderTrackingLineShouldExistErr: Label 'Order tracking line should exist';

    [Test]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanReleasedProductionLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [GIVEN] Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(Item, ChildItem, ChildItem."Replenishment System"::"Prod. Order");

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // [WHEN] Calculate Regenerative Change Plan for Planning Worksheet for Parent Item and Child Item.
        CalcRegenPlanForPlanWkshWithMultipleItems(Item."No.", ChildItem."No.", WorkDate(), GetRequiredDate(10, 30, WorkDate(), 1));

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        VerifyOrderTrackingOnRequisitionLine(Item."No.", 0, 0, ProductionOrder.Quantity, true);  // Untracked Quantity and total Quantity - 0.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanReleasedProdOutputJournalLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [GIVEN] Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(Item, ChildItem, ChildItem."Replenishment System"::"Prod. Order");

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create and Post Output Journal.
        CreateAndPostOutputJournal(ProductionOrder."No.");

        // [WHEN] Calculate Regenerative Plan for Planning Worksheet.
        CalcRegenPlanForPlanWkshWithMultipleItems(Item."No.", ChildItem."No.", WorkDate(), GetRequiredDate(10, 30, WorkDate(), 1));

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status::Released, ProductionOrder."No.", ChildItem."No.");
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        VerifyOrderTrackingOnRequisitionLine(
          ChildItem."No.", ProdOrderComponent."Expected Quantity", ProdOrderComponent."Expected Quantity", 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanPurchasePlanningFlexibilityNoneSalesLFLItem()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // [GIVEN] Create Lot for Lot Item.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);

        // [GIVEN] Create Purchase Order with Planning Flexibility - None.
        CreatePurchaseOrder(PurchaseLine, Item."No.", '', LibraryRandom.RandDec(10, 2));
        UpdatePurchaseLinePlanningFlexibilityNone(PurchaseLine);

        // [GIVEN] Create Sales Order.
        CreateSalesOrder(SalesLine, Item."No.", '', LibraryRandom.RandDecinRange(11, 20, 2));

        // [WHEN] Calculate Regenerative Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] Verify Untracked Quantity and Total Quantity on Requisition Line using Order Tracking.
        VerifyOrderTrackingOnRequisitionLine(Item."No.", 0, SalesLine.Quantity, 0, false);  // Untracked Quantity - 0.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcPlanReqWkshSKUSalesMaxQtyItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ItemVariant: Record "Item Variant";
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] Create Maximum Quantity Item. Create Stockkeeping Unit. Update Inventory With Location.
        Initialize();
        CreateStockkeepingUnitForMaximumQtyItem(Item, ItemVariant, LocationBlue.Code);
        UpdateInventoryWithLocation(Item."No.", LocationBlue.Code);

        // [GIVEN] Create Sales Order With non Warehouse Location. Post Sales Order for Ship.
        CreateSalesOrder(SalesLine, Item."No.", LocationBlue.Code);
        PostSalesDocumentAsShip(SalesLine);

        // [WHEN] Calculate Plan for Requisition Worksheet.
        StartDate := GetRequiredDate(10, 0, WorkDate(), -1);  // Start Date less than WORKDATE.
        EndDate := GetRequiredDate(10, 0, WorkDate(), 1);  // End Date more than WORKDATE.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, StartDate, EndDate);

        // [THEN] Verify Untracked Quantity, Total Quantity on Requisition Line using Order Tracking.
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        VerifyOrderTrackingOnRequisitionLine(Item."No.", Item."Maximum Inventory", Item."Maximum Inventory", 0, false);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanSalesUsingForecastLFLItem()
    var
        Item: Record Item;
        ProductionForecastEntry: Record "Production Forecast Entry";
        SalesLine: Record "Sales Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [GIVEN] Create Lot for Lot Item. Create Production Forecast.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate());

        // [GIVEN] Create Sales Order.
        CreateSalesOrder(SalesLine, Item."No.", '');

        // [WHEN] Calculate regenerative Plan for Planning Worksheet.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, Item."No.", Item."No.");

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        VerifyOrderTrackingOnRequisitionLine(
          Item."No.", ProductionForecastEntry."Forecast Quantity" - SalesLine.Quantity, ProductionForecastEntry."Forecast Quantity",
          -SalesLine.Quantity, true);
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcPlanWithMPSForecastAndProdOrderConsumpLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionOrder: Record "Production Order";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
        ForecastDate: Date;
    begin
        // [GIVEN] Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateInventorySetup(false);  // Combined MPS,MRP Calculation of Manufacturing Setup - FALSE.
        CreateLotForLotItemSetup(Item, ChildItem, ChildItem."Replenishment System"::Purchase);

        // [GIVEN] Create Production Forecast for parent item.
        ForecastDate := GetRequiredDate(10, 0, WorkDate(), 1);  // Forecast Date Relative to Workdate.
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", ForecastDate);

        // [GIVEN] Create Released Production Order of parent item. Create and Post Consumption Journal.
        UpdateInventoryWithLocation(ChildItem."No.", '');
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(5, 2));
        CreateAndPostConsumptionJournal(ProductionOrder."No.");

        // [WHEN] Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, Item."No.", ChildItem."No.");

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        VerifyOrderTrackingOnRequisitionLine(
          Item."No.", ProductionForecastEntry."Forecast Quantity" - ProductionOrder.Quantity,
          ProductionForecastEntry."Forecast Quantity" - ProductionOrder.Quantity, 0, false);

        // Teardown.
        UpdateInventorySetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanFirmPlannedProdTransferPlanningFlexibilityNoneLFLItem()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        ProductionOrder: Record "Production Order";
    begin
        // [GIVEN] Create Lot for Lot tem. Create Lot for Lot Item and Stockkeeping Unit setup.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItemSKUSetupWithTransfer(Item."No.", LocationSilver.Code, LocationBlue.Code);

        // [GIVEN] Create and Refresh Firm Planned Production Order. Create Transfer Order.
        CreateAndRefreshFirmPlannedProductionOrderWithLocation(
          ProductionOrder, Item."No.", LocationSilver.Code, LibraryRandom.RandDec(10, 2));
        CreateTransferOrder(TransferLine, Item."No.", LocationSilver.Code, LocationBlue.Code);
        UpdateTransferLinePlanningFlexibilityNone(TransferLine);  // Update Planning Flexibility on Transfer Line - None.

        // [WHEN] Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        VerifyOrderTrackingOnRequisitionLine(Item."No.", 0, TransferLine.Quantity, ProductionOrder.Quantity - TransferLine.Quantity, true);  // Untracked Quantity - 0.
    end;

    [Test]
    [HandlerFunctions('CalculatePlanPlanWkshRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanWithMPSForecastAndSalesLFLItem()
    var
        Item: Record Item;
        ProductionForecastEntry: Record "Production Forecast Entry";
        SalesLine: Record "Sales Line";
        PlanningWorksheet: TestPage "Planning Worksheet";
        OldCombinedMPSMRPCalculation: Boolean;
    begin
        // [GIVEN] Create Lot for Lot Item. Create Production Forecast.
        Initialize();
        OldCombinedMPSMRPCalculation := UpdateInventorySetup(false);  // Combined MPS,MRP Calculation of Manufacturing Setup - FALSE.
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateProductionForecastSetup(ProductionForecastEntry, Item."No.", WorkDate());

        // [GIVEN] Create Sales Order.
        CreateSalesOrder(SalesLine, Item."No.", '');

        // [WHEN] Calculate regenerative Plan with MPS - TRUE and MRP - FALSE for Planning Worksheet. Using Page Handler - CalculatePlanPlanWkshRequestPageHandler.
        CalcRegenPlanForPlanWkshPage(PlanningWorksheet, Item."No.", Item."No.");

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        VerifyOrderTrackingOnRequisitionLine(
          Item."No.", ProductionForecastEntry."Forecast Quantity" - SalesLine.Quantity, ProductionForecastEntry."Forecast Quantity",
          -SalesLine.Quantity, true);

        // Teardown.
        UpdateInventorySetup(OldCombinedMPSMRPCalculation);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanPlanningComponentWithSKUAndSalesLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [GIVEN] Create Lot for Lot Item Setup. Create Stockkeeping Unit setup for Child Item.
        Initialize();
        CreateLotForLotItemSetup(Item, ChildItem, ChildItem."Replenishment System"::Purchase);
        CreateItemSKUSetupWithTransfer(ChildItem."No.", LocationSilver.Code, LocationBlue.Code);

        // [GIVEN] Create Sales Order for Parent Item.
        CreateSalesOrder(SalesLine, Item."No.", '');

        // [WHEN] Calculate regenerative Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] Verify Untracked Quantity and Total Quantity on Planning Component using Order Tracking.
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        VerifyOrderTrackingForPlanningComponent(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ReserveFromCurrentLinePageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanPostPurchaseAndSalesReserveLFLItem()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // [GIVEN] Create Lot for Lot Item.
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);

        // [GIVEN] Create and Post Purchase Order.
        CreatePurchaseOrder(PurchaseLine, Item."No.", '', LibraryRandom.RandDec(10, 2));
        PostPurchaseDocument(PurchaseLine);

        // [GIVEN] Create and Reserve Sales Order.
        CreateSalesOrder(SalesLine, Item."No.", '', LibraryRandom.RandDecInRange(11, 20, 2));
        SalesLine.ShowReservation();  // Open Resrevation Page - ReservationFromCurrentLineHandler

        // [WHEN] Calculate regenerative Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        VerifyOrderTrackingOnRequisitionLine(
          Item."No.", 0, SalesLine.Quantity - PurchaseLine.Quantity, -(SalesLine.Quantity - PurchaseLine.Quantity), true);  // Untracked Quantity - 0.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckLotForLotItemPlanningWorksheetAction()
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [PlanningWorksheet] [Requisition Line] [Item] [Reordering Policy]
        // [SCENARIO 478131] Lot By Lot Item planing with specific quantity and date combination should lead to canceled status of 2 requisition lines.
        Initialize();

        // [GIVEN] Create Lot for Lot (Reordering Policy) Item and Stockkeeping Unit for Location Blue.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        Evaluate(Item."Dampener Period", '<CM+5D>');
        Evaluate(Item."Lot Accumulation Period", '<CM+5D>');
        Evaluate(Item."Rescheduling Period", '<7Y>');
        Item.Modify();
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationBlue.Code, Item."No.", '');

        // [GIVEN] Create Item Journal Line for Location Blue. and post it
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationBlue.Code, '', 3335);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Purchase Order with several purchase line with same item and different receipt date.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithSpecificReceiptDate(PurchaseHeader, Item."No.", LocationBlue.Code, 613, DMY2Date(25, 5, Date2DMY(WorkDate(), 3)));
        CreatePurchaseLineWithSpecificReceiptDate(PurchaseHeader, Item."No.", LocationBlue.Code, 1256, DMY2Date(30, 6, Date2DMY(WorkDate(), 3)));
        CreatePurchaseLineWithSpecificReceiptDate(PurchaseHeader, Item."No.", LocationBlue.Code, 1256, DMY2Date(14, 9, Date2DMY(WorkDate(), 3)));
        CreatePurchaseLineWithSpecificReceiptDate(PurchaseHeader, Item."No.", LocationBlue.Code, 1544, DMY2Date(14, 9, Date2DMY(WorkDate(), 3)));
        CreatePurchaseLineWithSpecificReceiptDate(PurchaseHeader, Item."No.", LocationBlue.Code, 1256, DMY2Date(29, 9, Date2DMY(WorkDate(), 3)));
        CreatePurchaseLineWithSpecificReceiptDate(PurchaseHeader, Item."No.", LocationBlue.Code, 1552, DMY2Date(29, 9, Date2DMY(WorkDate(), 3)));

        // [GIVEN] Create Sales Order with several lines with same item and different shipment date.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLineWithSpecificShipmentDate(SalesHeader, Item."No.", LocationBlue.Code, 1192, DMY2Date(6, 5, Date2DMY(WorkDate(), 3)));
        CreateSalesLineWithSpecificShipmentDate(SalesHeader, Item."No.", LocationBlue.Code, 1500, DMY2Date(28, 6, Date2DMY(WorkDate(), 3)));
        CreateSalesLineWithSpecificShipmentDate(SalesHeader, Item."No.", LocationBlue.Code, 1256, DMY2Date(14, 7, Date2DMY(WorkDate(), 3)));
        CreateSalesLineWithSpecificShipmentDate(SalesHeader, Item."No.", LocationBlue.Code, 1256, DMY2Date(14, 9, Date2DMY(WorkDate(), 3)));
        CreateSalesLineWithSpecificShipmentDate(SalesHeader, Item."No.", LocationBlue.Code, 1256, DMY2Date(16, 10, Date2DMY(WorkDate(), 3)));
        CreateSalesLineWithSpecificShipmentDate(SalesHeader, Item."No.", LocationBlue.Code, 1656, DMY2Date(15, 11, Date2DMY(WorkDate(), 3)));

        // [WHEN] Calculate regenerative Plan for Planning Worksheet.
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationBlue.Code);
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));

        // [THEN] Two purchase lines should be marked with Action Message = 'Cancel'
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.SetRange("Action Message", RequisitionLine."Action Message"::Cancel);
        Assert.AreEqual(2, RequisitionLine.Count, 'There is an issue with the values');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanReleasedProdAndNegativeOutputLFLItem()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [GIVEN] Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        Initialize();
        CreateLotForLotItemSetup(Item, ChildItem, ChildItem."Replenishment System"::"Prod. Order");

        // [GIVEN] Create and Refresh Released Production Order. Create and Post Output Journal.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));
        CreateAndPostOutputJournal(ProductionOrder."No.");

        // [GIVEN] Create and Post Output Journal again with negative Production Order Quantity.
        CreateAndPostOutputJournalWithAppliesToEntry(ProductionOrder."No.", Item."No.", -ProductionOrder.Quantity);

        // [WHEN] Calculate Regenerative Plan for Planning Worksheet.
        CalcRegenPlanForPlanWkshWithMultipleItems(Item."No.", ChildItem."No.", WorkDate(), GetRequiredDate(10, 30, WorkDate(), 1));

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status::Released, ProductionOrder."No.", ChildItem."No.");
        VerifyOrderTrackingOnRequisitionLine(
          ChildItem."No.", ProdOrderComponent."Expected Quantity", ProdOrderComponent."Expected Quantity", 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcRegenPlanForTransferAndOrderItem()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
    begin
        // [GIVEN] Create Order Item. Create Transfer Order.
        Initialize();
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::Purchase);
        CreateTransferOrder(TransferLine, Item."No.", LocationSilver.Code, LocationBlue.Code);

        // [WHEN] Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        VerifyOrderTrackingOnRequisitionLine(Item."No.", 0, 0, TransferLine.Quantity, true);  // Untracked Quantity and total Quantity - 0.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcPlanReqWkshForPostedSalesWithPartialQtyToShipMQItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Quantity: Decimal;
        StartDate: Date;
        EndDate: Date;
    begin
        // [GIVEN] Create Maximum Quantity Item.
        Initialize();
        CreateMaximumQtyItem(Item, LibraryRandom.RandDec(50, 2) + 200);  // Large Quantity required for Maximum Inventory.

        // [GIVEN] Create and Post Sales Order With Quantity to Ship less than Sales Line Quantity.
        CreateAndPostSalesOrderWithPartialQtyToShip(SalesLine, Item."No.");

        // [WHEN] Calculate Plan for Requisition Worksheet.
        StartDate := GetRequiredDate(10, 0, WorkDate(), -1);  // Start Date less than WORKDATE.
        EndDate := GetRequiredDate(10, 0, WorkDate(), 1);  // End Date more than WORKDATE.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, StartDate, EndDate);

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        Quantity := SalesLine.Quantity - SalesLine."Qty. to Ship";
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        VerifyOrderTrackingOnRequisitionLineWithDueDate(
          Item."No.", SelectDateWithSafetyLeadTime(StartDate, -1), SalesLine."Qty. to Ship", SalesLine."Qty. to Ship", 0, false);
        VerifyOrderTrackingOnRequisitionLineWithDueDate(
          Item."No.", SelectDateWithSafetyLeadTime(StartDate, 1), Item."Maximum Inventory" - Quantity, Item."Maximum Inventory", -Quantity,
          true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForCalcPlanReqWkshForPostedSalesWithPartialQtyToShipFRQItem()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Quantity: Decimal;
        EndDate: Date;
    begin
        // [GIVEN] Create Fixed Reorder Quantity Item.
        Initialize();
        CreateFRQItem(Item);

        // [GIVEN] Create and Post Sales Order With Quantity to Ship less than Sales Line Quantity.
        CreateAndPostSalesOrderWithPartialQtyToShip(SalesLine, Item."No.");

        // [WHEN] Calculate Plan for Requisition Worksheet.
        EndDate := GetRequiredDate(10, 0, WorkDate(), 1);  // End Date more than WORKDATE.
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), EndDate);

        // [THEN] Verify Untracked Quantity, Total Quantity and Quantity on Requisition Line using Order Tracking.
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);  // Required inside MessageHandler.
        Quantity := SalesLine.Quantity - SalesLine."Qty. to Ship";
        VerifyOrderTrackingOnRequisitionLineWithDueDate(
          Item."No.", SelectDateWithSafetyLeadTime(WorkDate(), -1), SalesLine."Qty. to Ship", SalesLine."Qty. to Ship", 0, false);
        VerifyOrderTrackingOnRequisitionLineWithDueDate(
          Item."No.", SelectDateWithSafetyLeadTime(WorkDate(), 1), Item."Reorder Point", Item."Reorder Point", 0, false);
        VerifyOrderTrackingOnRequisitionLineWithDueDate(
          Item."No.", WorkDate(), Item."Safety Stock Quantity", Quantity + Item."Safety Stock Quantity", -Quantity, true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQtyToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure CalculatePlanDoesNotRemoveItemTrackingSpecialOrders()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SerialNo: Variant;
    begin
        // [SCENARIO Sicily 6770] Item Tracking on a Special Order (Sales Order) should not disappear if Calculate Plan is executed on the Req. Worksheet

        Initialize();
        // [GIVEN] prepare an item with item tracking (SN), reordering policy = lot-for-lot and 'Include Inventory' = Yes
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(10, 2));
        Item.Validate("Include Inventory", true);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
        LibraryItemTracking.AddSerialNoTrackingInfo(Item);

        // [GIVEN] Create a Sales Order (Special order)
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateSpecialOrder(SalesHeader, SalesLine, Item, Location.Code, '', 1,// Qty 1
          WorkDate(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] Create a purchase order to supply Item for the previous Sales Order
        CreatePurchaseOrderForCustomer(PurchaseHeader, PurchaseLine, Item, Location.Code, '', 1,// Qty 1
          WorkDate(), LibraryRandom.RandDec(5, 2), SalesHeader."Sell-to Customer No.");

        // [GIVEN] From Item tracking lines (Purchase Order), add a SN to the item, then post receipt
        LibraryVariableStorage.Enqueue(ControlOptions::Purchase);
        PurchaseLine.OpenItemTrackingLines();
        LibraryVariableStorage.Dequeue(SerialNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] From Item Tracking Lines (Sales Order), assign same SN to the item
        LibraryVariableStorage.Enqueue(ControlOptions::Sale);
        LibraryVariableStorage.Enqueue(SerialNo);
        SalesLine.OpenItemTrackingLines();

        // [WHEN] open the Requisition Worksheets and Calculate a Plan for the item
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, CalcDate('<-1M>', WorkDate()), CalcDate('<+1M>', WorkDate()));

        // [THEN] Review the Sales Order, open the Item Tracking and notice the Serial No. disappeared.
        LibraryVariableStorage.Enqueue(ControlOptions::Verification);
        LibraryVariableStorage.Enqueue(SerialNo);
        SalesLine.OpenItemTrackingLines();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForMultipleSKUWithTransferReplenishmentSystem()
    begin
        Initialize();
        CalcRegenPlanForSKUWithTransferReplenishmentSystem(true); // TRUE indicates creating 2 SKU
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanForSingleSKUWithTransferReplenishmentSystem()
    begin
        Initialize();
        CalcRegenPlanForSKUWithTransferReplenishmentSystem(false); // FALSE indicates creating 1 SKU
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanWithCancelRequsitionLineForTransferOrder()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO] No requisition line should be generated when calculating plan in Planning Worksheet with a filter on a transfer-from location after planning without location filter

        // [GIVEN] Create Lot for Lot item. Create a Transfer Order from Location Blue to Silver.
        // [GIVEN] Calculate Plan for Planning Worksheet without Location filter. A Cancel Req. Line for the transfer order will be generated
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateTransferOrder(TransferLine, Item."No.", LocationBlue.Code, LocationSilver.Code);
        CalculateRegenPlanForPlanningWorksheet(Item);
        FilterRequisitionLine(RequisitionLine, Item."No.", LocationSilver.Code);
        Assert.IsFalse(RequisitionLine.IsEmpty, StrSubstNo(ReqLineShouldExistErr, LocationSilver.Code)); // Check Req. Line for Location Silver exists

        // [WHEN] Calculate Plan for Planning Worksheet for Location Blue
        Item.SetRange("Location Filter", LocationBlue.Code);
        CalculateRegenPlanForPlanningWorksheet(Item);

        // [THEN] No Requisition Line for Location Blue should be generated.
        FilterRequisitionLine(RequisitionLine, Item."No.", LocationBlue.Code);
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(ReqLineShouldNotExistErr, LocationBlue.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcPlanReqWkshWithMultipleWkshNameForTransferOrder()
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        // [SCENARIO] No requisition line should be generated when calculating plan in Requisition Worksheet with a filter on a transfer-from location after planning without location filter

        // [GIVEN] Create Lot for Lot item. Create a Transfer Order from Location Blue to Silver.
        // [GIVEN] Calculate Plan for Requisition Worksheet without Location filter. A Cancel Req. Line for the transfer order will be generated
        Initialize();
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase);
        CreateTransferOrder(TransferLine, Item."No.", LocationBlue.Code, LocationSilver.Code);
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate() + LibraryRandom.RandInt(20));
        Assert.IsTrue(
          FindRequisitionLine(RequisitionLine, RequisitionLine."Action Message"::Cancel, Item."No.", LocationSilver.Code),
          StrSubstNo(ReqLineShouldExistErr, LocationSilver.Code)); // Check Cancel Action Message Req. Line for Location Silver exists

        // [WHEN] Calculate Plan for Requisition Worksheet with new Req. Worksheet Name for Location Blue
        Item.SetRange("Location Filter", LocationBlue.Code); // Set Location filter as Blue
        CalculatePlanForRequisitionWorksheet(RequisitionWkshName, Item, WorkDate(), WorkDate() + LibraryRandom.RandInt(20));
        RequisitionLine.Reset();
        FilterRequisitionLine(RequisitionLine, Item."No.", LocationBlue.Code);

        // [THEN] No Requisition Line for Location Blue should be generated.
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(ReqLineShouldNotExistErr, LocationBlue.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcRegenPlanReleasedProductionOrderWithReservedComponent()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // [GIVEN] Create Lot for Lot Parent and Child Item. Create And Certify Production BOM.
        // [GIVEN] Create and Refresh Released Production Order.
        // [GIVEN] Calculate Regenerative Change Plan for Planning Worksheet for Child Item and Carry Out Action Message.
        Initialize();
        CreateOrderItemSetup(Item, ChildItem);
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", LibraryRandom.RandDec(10, 2));
        CalculateRegenPlanForPlanningWorksheet(ChildItem);
        AcceptAndCarryOutActionMessage(ChildItem."No.", '');

        // [WHEN] Calculate Regenerative Change Plan for Planning Worksheet for Parent Item and Child Item.
        CalcRegenPlanForPlanWkshWithMultipleItems(
          Item."No.", ChildItem."No.", WorkDate() - LibraryRandom.RandInt(10), GetRequiredDate(10, 30, WorkDate(), 1));

        // [THEN] Verify Reserved Quantity on Prod. Order Component Line.
        VerifyReservedQuantityOnProdOrderComponent(ProductionOrder."No.", ChildItem."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure WrongRequisitionLineValueNotCommitted()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 377478] Incorrect value is not committed to database when validating requisition line

        // [GIVEN] Create sales order with "Special Order" purchasing code and lot tracking
        LibraryItemTracking.CreateLotItem(Item);
        LibraryWarehouse.CreateLocation(Location);
        CreateSpecialOrder(SalesHeader, SalesLine, Item, Location.Code, '', 1, WorkDate(), LibraryRandom.RandDec(10, 2));

        LibraryVariableStorage.Enqueue(ControlOptions::Sale);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create requisition line via "Get Special Order" in Requisition Worksheet
        GetSpecialOrder(RequisitionLine, Item."No.");

        // [WHEN] Change quantity on requisition line
        RequisitionLine.SetCurrFieldNo(RequisitionLine.FieldNo(Quantity));
        RequisitionLine.Validate(Quantity, RequisitionLine.Quantity + LibraryRandom.RandInt(20));
        asserterror RequisitionLine.Modify(true);

        // [THEN] Error: Existing item tracking must be deleted before modifying requisition line
        Assert.ExpectedError(StrSubstNo(ItemTrackingDefinedErr, Item."No."));
        Assert.ExpectedErrorCode(DialogErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesLotNoModalPageHandler')]
    [Scope('OnPrem')]
    procedure ReqPlanSuggestsCancelExcessSupplyWithUnlimitedFlexibility()
    var
        ComponentItem: Record Item;
        ProdItem: Record Item;
        ProductionOrder: array[3] of Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
        ProdOrderComponent: Record "Prod. Order Component";
        LeadTimeManagement: Codeunit "Lead-Time Management";
    begin
        // [FEATURE] [Production]
        // [SCENARIO 272789] Requisition planning suggests to cancel excessive production order that has "Unlimited" planning flexibility when another order with flexibility "None" exists

        Initialize();

        // [GIVEN] Two items "PROD" and "COMP" with "Prod. Order" replenishment system and "Lot-for-Lot" reordering policy. "COMP" is a BOM component for "PROD" item
        CreateLotForLotItemSetup(ProdItem, ComponentItem, ComponentItem."Replenishment System"::"Prod. Order");
        // [GIVEN] "COMP" item is tracked by lot numbers
        LibraryItemTracking.AddLotNoTrackingInfo(ComponentItem);

        // [GIVEN] Poduction order "P1" for 100 pcs of item "PROD"
        CreateAndRefreshFirmPlannedProductionOrderWithDueDate(
          ProductionOrder[1], ProdItem."No.", LibraryRandom.RandIntInRange(50, 100),
          LeadTimeManagement.GetPlannedDueDate(ProdItem."No.", '', '', WorkDate(), '', "Requisition Ref. Order Type"::"Prod. Order"));
        ProdOrderComponent.SetRange("Item No.", ComponentItem."No.");
        ProdOrderComponent.FindFirst();

        // [GIVEN] Poduction order "P2" for 20 pcs of item "COMP" without lot tracking
        CreateAndRefreshFirmPlannedProductionOrderWithDueDate(
          ProductionOrder[2], ComponentItem."No.", ProdOrderComponent."Expected Quantity" / 2, ProductionOrder[1]."Starting Date");

        // [GIVEN] Poduction order "P3" for 100 pcs of item "COMP" with lot tracking. This order is sufficient to cover demand from the parent prod. order.
        CreateAndRefreshFirmPlannedProductionOrderWithDueDate(
          ProductionOrder[3], ComponentItem."No.", ProdOrderComponent."Expected Quantity", ProductionOrder[1]."Starting Date");

        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(ProdOrderComponent."Expected Quantity");
        ProdOrderLine.SetRange("Item No.", ComponentItem."No.");
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder[3]."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.OpenItemTrackingLines();

        // [WHEN] Calculate regenerative plan for the component item "COMP"
        CalculateRegenPlanForPlanningWorksheet(ComponentItem);

        // [THEN] Suggested action is to cancel the order "P2"
        SelectRequisitionLine(RequisitionLine, ComponentItem."No.");
        RequisitionLine.TestField("Ref. Order No.", ProductionOrder[2]."No.");
        RequisitionLine.TestField("Action Message", RequisitionLine."Action Message"::Cancel);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQtyToCreateWithLotNoPageHandler,OrderTrackingWithNoLinesModalPageHandler,MessageHandlerCheckWithPeek')]
    [Scope('OnPrem')]
    procedure OrderTrackingNoEntriesPostedSalesShipment()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ItemJournalLine: Record "Item Journal Line";
        PostedSalesShipment: TestPage "Posted Sales Shipment";
        SerialNo: Variant;
        PostedSalesShipmentNo: Code[20];
    begin
        // [SCENARIO 348770] Order Tracking page should show no entries for Posted Sales Shipment with Item tracking
        Initialize();
        MockReservationEntries();

        // [GIVEN] Item "I" with Serial No. Item tracking
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(10, 2));
        Item.Validate("Include Inventory", true);
        Item.Modify(true);
        LibraryItemTracking.AddSerialNoTrackingInfo(Item);
        LibraryItemTracking.AddLotNoTrackingInfo(Item);

        // [GIVEN] Create Positive Adjmt. Item Journal Line with Item "I"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        LibraryVariableStorage.Enqueue(ControlOptions::Purchase);
        CreateItemJournalLine(
          ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);  // Large Quantity required.
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] From Item tracking lines (Item Journal), add a SN to the item, then post journal line
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryVariableStorage.Dequeue(SerialNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create and ship Sales Order with item tracking for Item "I"
        CreateSpecialOrder(SalesHeader, SalesLine, Item, Location.Code, '', 1, WorkDate(), LibraryRandom.RandDec(10, 2));

        LibraryVariableStorage.Enqueue(ControlOptions::Sale);
        LibraryVariableStorage.Enqueue(SerialNo);
        SalesLine.OpenItemTrackingLines();
        PostedSalesShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesShipmentHeader.Get(PostedSalesShipmentNo);
        PostedSalesShipment.OpenView();
        PostedSalesShipment.GotoRecord(SalesShipmentHeader);
        PostedSalesShipment.SalesShipmLines.First();

        // [WHEN] Order tracking is invoked from Posted Sales Shipment
        LibraryVariableStorage.Enqueue(NoTrackingLinesErr);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(Item."No.");
        PostedSalesShipment.SalesShipmLines."Order Tra&cking".Invoke(); // Order Tracking action

        // [THEN] Order Tracking page is opened with no lines (checked in OrderTrackingWithNoLinesModalPageHandler handler)
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesModalPageHandler,EnterQtyToCreateWithLotNoPageHandler,OrderTrackingWithLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingEntriesExistPostedPurchReceipt()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        SerialNo: Variant;
        PostedPurchaseReceiptNo: Code[20];
    begin
        // [SCENARIO 348770] Order Tracking page should show correct entries for Posted Purchase Receipt with Item tracking
        Initialize();
        MockReservationEntries();

        // [GIVEN] Item "I" with Serial No. Item tracking
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryRandom.RandDec(10, 2));
        Item.Validate("Include Inventory", true);
        Item.Modify(true);
        LibraryItemTracking.AddSerialNoTrackingInfo(Item);
        LibraryItemTracking.AddLotNoTrackingInfo(Item);

        // [GIVEN] Create a purchase order with Item "I"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryPurchase.CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, Location.Code, '', 2, WorkDate(), LibraryRandom.RandDec(10, 2));

        // [GIVEN] From Item tracking lines (Purchase Order), add a SN to the item, then post receipt
        LibraryVariableStorage.Enqueue(ControlOptions::Purchase);
        PurchaseLine.OpenItemTrackingLines();
        LibraryVariableStorage.Dequeue(SerialNo);
        PostedPurchaseReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Order Tracking form is opened from posted Purchase Receipt
        PurchRcptHeader.Get(PostedPurchaseReceiptNo);
        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.GotoRecord(PurchRcptHeader);
        PostedPurchaseReceipt.PurchReceiptLines.First();
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(Item."No.");
        PostedPurchaseReceipt.PurchReceiptLines.OrderTracking.Invoke(); // Order Tracking action
        // [THEN] Order Tracking page is opened with 2 lines for Item "I" and quantity = 1(checked in OrderTrackingWithLinesModalPageHandler handler)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReqLineIsNotCreatedWhenCalcRegenPlanForCompItemPresentInRelProdOrder()
    var
        Item: array[4] of Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        productionBOMLine: array[3] of Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // [SCENARIO 563946] Requition Line is not created when Stan runs Calculate Regenerative 
        // Plan action for Component Item if the that Item is present in a Released Production Order 
        // with required Quantity in its Prod. Order Line.
        Initialize();

        // [GIVEN] Create four Items.
        CreateItem(Item[1]);
        CreateItem(Item[2]);
        CreateItem(Item[3]);
        CreateItem(Item[4]);

        // [GIVEN] Create a Production BOM for Item [2] and Item [3].
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[1], Item[2]."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader[1], ProductionBOMLine[1], '', ProductionBOMLine[1].Type::Item, Item[2]."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader[1], ProductionBOMLine[2], '', ProductionBOMLine[2].Type::Item, Item[3]."No.", LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Validate "Status" in Production BOM Header [1].
        ProductionBOMHeader[1].Validate("Status", ProductionBOMHeader[1].Status::Certified);
        ProductionBOMHeader[1].Modify(true);

        // [GIVEN] Create a Production BOM for Item [4].
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader[2], Item[4]."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader[2], ProductionBOMLine[3], '', ProductionBOMLine[3].Type::Item, Item[4]."No.", LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Validate "Status" in Production BOM Header [2].
        ProductionBOMHeader[2].Validate("Status", ProductionBOMHeader[2].Status::Certified);
        ProductionBOMHeader[2].Modify(true);

        // [GIVEN] Validate "Production BOM No." in Item [1].
        Item[1].Validate("Production BOM No.", ProductionBOMHeader[1]."No.");
        Item[1].Modify(true);

        // [GIVEN] Validate "Production BOM No." in Item [2].
        Item[2].Validate("Production BOM No.", ProductionBOMHeader[2]."No.");
        Item[2].Modify(true);

        // [GIVEN] Validate "Production BOM No." in Item [3].
        Item[3].Validate("Production BOM No.", ProductionBOMHeader[2]."No.");
        Item[3].Modify(true);

        // [GIVEN] Create and Refresh Released Production Order.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item[1]."No.", LibraryRandom.RandIntInRange(1, 1));

        // [GIVEN] Calculate Regenerative Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item[4]);

        // [WHEN] Find Requisition Line.
        RequisitionLine.SetRange("No.", Item[4]."No.");

        // [THEN] Requisition Line is not found.
        Assert.IsTrue(RequisitionLine.IsEmpty(), StrSubstNo(ReqLineShouldNotExistErr, ''));
    end;

    local procedure Initialize()
    var
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning Order Tracking");
        RequisitionLine.DeleteAll();
        ReservationEntry.DeleteAll();
        LibraryVariableStorage.Clear();

        LibraryApplicationArea.EnableEssentialSetup();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning Order Tracking");

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        ItemJournalSetup();
        OutputJournalSetup();
        ConsumptionJournalSetup();
        CreateLocationSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning Order Tracking");
    end;

    local procedure AcceptAndCarryOutActionMessage(No: Code[20]; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FilterRequisitionLine(RequisitionLine, No, LocationCode);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Validate("Posted Shipment Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Modify(true);
    end;

    local procedure OutputJournalSetup()
    begin
        OutputItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(OutputItemJournalTemplate, OutputItemJournalTemplate.Type::Output);

        OutputItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          OutputItemJournalBatch, OutputItemJournalTemplate.Type, OutputItemJournalTemplate.Name);
    end;

    local procedure CalcRegenPlanForSKUWithTransferReplenishmentSystem(MultipleSKU: Boolean)
    var
        Item: Record Item;
        TransferLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Lot for Lot item. Create Stockkeeping Unit:
        // "Location Code" = LocationBlue.Code, "Transfer-from Code" = LocationSilver.Code, "Replenishment System" = Transfer
        // If MultipleSKU is TRUE, then create another Stockkeeping Unit with "Location Code" = LocationSilver.Code
        // Create Sales Order for Item at Location Blue, create Transfser Order for Item from Location Blue to Silver
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateItemSKUSetup(Item."No.", LocationBlue.Code, LocationSilver.Code, MultipleSKU);
        CreateSalesOrder(SalesLine, Item."No.", LocationBlue.Code);
        CreateTransferOrder(TransferLine, Item."No.", LocationBlue.Code, LocationSilver.Code);

        // Exercise: Calculate Plan for Planning Worksheet.
        CalculateRegenPlanForPlanningWorksheet(Item);

        // Verify: 3 Requisition Lines for Item are generated.
        // Line 1: "Action Message" = New, Location = Blue, Quantity = SalesLine.Quantity
        // Line 2: "Action Message" = New, Location = Silver, Quantity = SalesLine.Quantity
        // Line 3: "Action Message" = Cancel, Location = Silver, "Orginal Quantity" = TransferLine.Quantity
        VerifyQuantityOnRequisitionLine(Item."No.", LocationBlue.Code, LocationSilver.Code, SalesLine.Quantity, TransferLine.Quantity);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        ConsumptionItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ConsumptionItemJournalTemplate, ConsumptionItemJournalTemplate.Type::Consumption);

        ConsumptionItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(
          ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type, ConsumptionItemJournalTemplate.Name);
    end;

    local procedure CreateLocationSetup()
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationBlue);   // Non - Warehouse Location.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationSilver);   // Non - Warehouse Location.
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
    end;

    local procedure CreateItem(var Item: Record Item; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        // Create Lot-for-Lot Item.
        CreateItem(Item, Item."Reordering Policy"::"Lot-for-Lot", ReplenishmentSystem);
        Item.Validate("Include Inventory", true);
        Item.Modify(true);
    end;

    local procedure CreateOrderItemSetup(var Item: Record Item; var ChildItem: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(Item, Item."Reordering Policy"::Order, Item."Replenishment System"::"Prod. Order");
        CreateItem(ChildItem, ChildItem."Reordering Policy"::Order, ChildItem."Replenishment System"::Purchase);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateMaximumQtyItem(var Item: Record Item; MaximumInventory: Decimal)
    begin
        // Create Maximum Quantity Item.
        CreateItem(Item, Item."Reordering Policy"::"Maximum Qty.", Item."Replenishment System"::Purchase);
        Item.Validate("Reorder Point", LibraryRandom.RandDec(10, 2) + 20);  // Large Random Value required for test.
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Minimum Order Quantity", LibraryRandom.RandDec(5, 2));  // Random Quantity less than Reorder Point Quantity.
        Item.Validate("Maximum Order Quantity", MaximumInventory + LibraryRandom.RandDec(100, 2));  // Random Quantity more than Maximum Inventory.
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItemSetup(var Item: Record Item; var ChildItem: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateLotForLotItem(Item, Item."Replenishment System"::"Prod. Order");
        CreateLotForLotItem(ChildItem, ReplenishmentSystem);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem);
        UpdateProductionBOMNoOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateFRQItem(var Item: Record Item)
    begin
        // Create Fixed Reorder Quantity Item.
        CreateItem(Item, Item."Reordering Policy"::"Fixed Reorder Qty.", Item."Replenishment System"::Purchase);
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandInt(10));
        Item.Validate("Reorder Point", LibraryRandom.RandInt(10) + 10);  // Reorder Point more than Safety Stock Quantity or Reorder Quantity.
        Item.Validate("Reorder Quantity", LibraryRandom.RandInt(5));
        Item.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandDec(5, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        CreateSalesOrder(SalesLine, ItemNo, LocationCode, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithSpecificShipmentDate(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithSpecificReceiptDate(PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Expected Receipt Date", ReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure CalcRegenPlanForPlanWkshWithMultipleItems(ItemNo: Code[20]; ItemNo2: Code[20]; StartDate: Date; EndDate: Date)
    var
        Item: Record Item;
    begin
        Item.SetFilter("No.", ItemFilterTok, ItemNo, ItemNo2);  // Filter Required for two Items.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, StartDate, EndDate);
    end;

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
    end;

    local procedure UpdateInventoryWithLocation(ItemNo: Code[20]; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(
          ItemJournalBatch, ItemJournalLine, ItemJournalLine."Entry Type"::Purchase, ItemNo, LibraryRandom.RandDec(10, 2) + 100);  // Large Quantity required.
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ProductionOrderNo);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExlpodeRouting(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournal(ItemJournalLine, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; ActionMessage: Enum "Action Message Type"; No: Code[20]; LocationCode: Code[10]): Boolean
    begin
        FilterRequisitionLine(RequisitionLine, No, LocationCode);
        RequisitionLine.SetRange("Action Message", ActionMessage);
        exit(RequisitionLine.FindFirst())
    end;

    local procedure FilterRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
    end;

    local procedure GetRequiredDate(Days: Integer; IncludeAdditionalPeriod: Integer; RelativeDate: Date; SignFactor: Integer) NewDate: Date
    begin
        // Calculating a New Date relative to WorkDate.
        NewDate :=
          CalcDate('<' + Format(SignFactor * LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>', RelativeDate);
    end;

    local procedure UpdatePurchaseLinePlanningFlexibilityNone(PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Planning Flexibility", PurchaseLine."Planning Flexibility"::None);
        PurchaseLine.Modify(true);
    end;

    local procedure AreSameMessages(Message: Text; Message2: Text): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure CalculatePlanForRequisitionWorksheet(var RequisitionWkshName: Record "Requisition Wksh. Name"; var Item: Record Item; StartDate: Date; EndDate: Date)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CalculatePlanForReqWksh(Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, StartDate, EndDate);
    end;

    local procedure CalculateRegenPlanForPlanningWorksheet(var Item: Record Item)
    var
        EndDate: Date;
    begin
        EndDate := GetRequiredDate(10, 30, WorkDate(), 1);  // End Date relative to Workdate.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), EndDate);
    end;

    local procedure UpdateInventorySetup(NewCombinedMPSMRPCalculation: Boolean) OldCombinedMPSMRPCalculation: Boolean
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        OldCombinedMPSMRPCalculation := InventorySetup."Combined MPS/MRP Calculation";
        InventorySetup.Validate("Combined MPS/MRP Calculation", NewCombinedMPSMRPCalculation);
        InventorySetup.Modify(true);
    end;

    local procedure CreateProductionForecastSetup(var ProductionForecastEntry: Record "Production Forecast Entry"; ItemNo: Code[20]; ForecastDate: Date)
    var
        ProductionForecastName: Record "Production Forecast Name";
    begin
        // Using Random Value and Dates based on WORKDATE.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryPlanning.SetDemandForecast(ProductionForecastName.Name);
        CreateAndUpdateProductionForecast(ProductionForecastEntry, ProductionForecastName.Name, ForecastDate, ItemNo);
    end;

    local procedure CreateAndUpdateProductionForecast(var ProductionForecastEntry: Record "Production Forecast Entry"; Name: Code[10]; Date: Date; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, Name, ItemNo, '', Date, false);  // Component Forecast - FALSE.
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", LibraryRandom.RandDec(10, 2) + 100);  // Large Random Quantity Required.
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CreateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CalcRegenPlanForPlanWkshPage(var PlanningWorksheet: TestPage "Planning Worksheet"; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Regenerative Planning using Page required where Forecast is used.
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue Item No for filtering - required in CalculatePlanPlanWkshRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemNo2);  // Enqueue Item No for filtering - required in CalculatePlanPlanWkshRequestPageHandler.
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::Planning);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        Commit();  // Required for Test.
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(RequisitionWkshName.Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure CreateStockkeepingUnitForMaximumQtyItem(var Item: Record Item; var ItemVariant: Record "Item Variant"; LocationCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        CreateMaximumQtyItem(Item, LibraryRandom.RandDec(50, 2) + 200);  // Large Quantity required for Maximum Inventory.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, Item."No.", ItemVariant.Code);
    end;

    local procedure CreateItemSKUSetupWithTransfer(ItemNo: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10])
    var
        ItemVariant: Record "Item Variant";
        StockkeepingUnit: Record "Stockkeeping Unit";
        StockkeepingUnit2: Record "Stockkeeping Unit";
    begin
        CreateItemVariantAndSKU(ItemVariant, StockkeepingUnit, LocationCode, ItemNo);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit2, LocationCode2, ItemNo, ItemVariant.Code);
        UpdateSKUReplenishmentSystem(StockkeepingUnit, StockkeepingUnit."Replenishment System"::Purchase);
        UpdateSKUReplenishmentSystem(StockkeepingUnit2, StockkeepingUnit2."Replenishment System"::Transfer);
        UpdateSKUTransferFromCode(StockkeepingUnit2, LocationCode, LocationCode2);
    end;

    local procedure CreateItemSKUSetup(ItemNo: Code[20]; LocationCode: Code[10]; TransferFromLocationCode: Code[10]; MultipleSKU: Boolean)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransferFromStockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, '');
        UpdateSKUTransferFromCode(StockkeepingUnit, TransferFromLocationCode, LocationCode);
        UpdateSKUReplenishmentSystem(StockkeepingUnit, StockkeepingUnit."Replenishment System"::Transfer);
        if MultipleSKU then
            LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(
              TransferFromStockkeepingUnit, TransferFromLocationCode, ItemNo, '');
    end;

    local procedure CreateAndRefreshFirmPlannedProductionOrderWithLocation(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshFirmPlannedProductionOrderWithDueDate(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Qty: Decimal; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, ItemNo, Qty);
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; TransferFrom: Code[10]; TransferTo: Code[10])
    var
        TransferHeader: Record "Transfer Header";
    begin
        SelectTransferRoute(TransferFrom, TransferTo);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, TransferFrom, TransferTo, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandDec(10, 2));
    end;

    local procedure GetSpecialOrder(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        RequisitionLine."Worksheet Template Name" := ReqWkshTemplate.Name;
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);

        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        RequisitionLine.FindFirst();
    end;

    local procedure UpdateTransferLinePlanningFlexibilityNone(TransferLine: Record "Transfer Line")
    begin
        TransferLine.Validate("Planning Flexibility", TransferLine."Planning Flexibility"::None);
        TransferLine.Modify(true);
    end;

    local procedure SelectPlanningComponent(var PlanningComponent: Record "Planning Component"; WorksheetTemplateName: Code[10]; WorksheetBatchName: Code[10])
    begin
        PlanningComponent.SetRange("Worksheet Template Name", WorksheetTemplateName);
        PlanningComponent.SetRange("Worksheet Batch Name", WorksheetBatchName);
        PlanningComponent.FindFirst();
    end;

    local procedure PostPurchaseDocument(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateOutputJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(
          ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, ItemNo, ProductionOrderNo);
    end;

    local procedure CreateAndPostOutputJournalWithAppliesToEntry(ProductionOrderNo: Code[20]; ItemNo: Code[20]; OutputQuantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        CreateOutputJournal(ItemJournalLine, ItemNo, ProductionOrderNo);
        ItemJournalLine.Validate("Output Quantity", OutputQuantity);
        ItemJournalLine.Validate("Applies-to Entry", ItemLedgerEntry."Entry No.");
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateItemVariantAndSKU(var ItemVariant: Record "Item Variant"; var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, ItemVariant.Code);
    end;

    local procedure UpdateSKUReplenishmentSystem(StockkeepingUnit: Record "Stockkeeping Unit"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdateSKUTransferFromCode(var StockkeepingUnit: Record "Stockkeeping Unit"; LocationCode: Code[10]; LocationCode2: Code[10])
    begin
        SelectTransferRoute(LocationCode, LocationCode2);
        StockkeepingUnit.Validate("Transfer-from Code", LocationCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure SelectTransferRoute(TransferFrom: Code[10]; TransferTo: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        TransferRoute.SetRange("Transfer-from Code", TransferFrom);
        TransferRoute.SetRange("Transfer-to Code", TransferTo);

        // If Transfer Not Found then Create it.
        if not TransferRoute.FindFirst() then
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
    end;

    local procedure UpdateQuantityToShipOnSalesLine(var SalesLine: Record "Sales Line"; QtytoShip: Decimal)
    begin
        SalesLine.Validate("Qty. to Ship", QtytoShip);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesOrderWithPartialQtyToShip(var SalesLine: Record "Sales Line"; ItemNo: Code[20])
    begin
        CreateSalesOrder(SalesLine, ItemNo, '');
        UpdateQuantityToShipOnSalesLine(SalesLine, SalesLine.Quantity - LibraryRandom.RandDec(5, 2));  // Quantity to Ship less than Sales Line Quantity.
        PostSalesDocumentAsShip(SalesLine);
    end;

    local procedure PostSalesDocumentAsShip(SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesLine."Document Type"::Order, SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure SelectDateWithSafetyLeadTime(DateValue: Date; SignFactor: Integer): Date
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // Add Safety lead time to the required date and return the Date value.
        InventorySetup.Get();
        if SignFactor < 0 then
            exit(CalcDate('<-' + Format(InventorySetup."Default Safety Lead Time") + '>', DateValue));
        exit(CalcDate('<' + Format(InventorySetup."Default Safety Lead Time") + '>', DateValue));
    end;

    local procedure VerifyOrderTrackingForPlanningComponent(ItemNo: Code[20])
    var
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
        OrderTracking2: Page "Order Tracking";
        OrderTracking: TestPage "Order Tracking";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        SelectPlanningComponent(PlanningComponent, RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name");
        OrderTracking.Trap();
        OrderTracking2.SetPlanningComponent(PlanningComponent);
        OrderTracking2.Run();
        OrderTracking."Untracked Quantity".AssertEquals(PlanningComponent."Expected Quantity");
        OrderTracking."Total Quantity".AssertEquals(PlanningComponent."Expected Quantity");
    end;

    local procedure VerifyOrderTrackingOnRequisitionLine(ItemNo: Code[20]; UntrackedQuantity: Decimal; TotalQuantity: Decimal; LineQuantity: Decimal; LineQty: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Verify required Quantity values - Untracked Qty,Total Qty and Qty.
        SelectRequisitionLine(RequisitionLine, ItemNo);
        VerifyOrderTracking(RequisitionLine, UntrackedQuantity, TotalQuantity, LineQuantity, LineQty);
    end;

    local procedure VerifyOrderTrackingOnRequisitionLineWithDueDate(ItemNo: Code[20]; DueDate: Date; UntrackedQuantity: Decimal; TotalQuantity: Decimal; LineQuantity: Decimal; LineQty: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Verify required Quantity values - Untracked Qty,Total Qty and Qty.
        RequisitionLine.SetRange("Due Date", DueDate);
        SelectRequisitionLine(RequisitionLine, ItemNo);
        VerifyOrderTracking(RequisitionLine, UntrackedQuantity, TotalQuantity, LineQuantity, LineQty);
    end;

    local procedure VerifyOrderTracking(RequisitionLine: Record "Requisition Line"; UntrackedQuantity: Decimal; TotalQuantity: Decimal; LineQuantity: Decimal; LineQty: Boolean)
    var
        OrderTracking2: Page "Order Tracking";
        OrderTracking: TestPage "Order Tracking";
    begin
        OrderTracking.Trap();
        OrderTracking2.SetReqLine(RequisitionLine);
        OrderTracking2.Run();
        OrderTracking."Untracked Quantity".AssertEquals(UntrackedQuantity);
        OrderTracking."Total Quantity".AssertEquals(TotalQuantity);
        if LineQty then
            OrderTracking.Quantity.AssertEquals(-LineQuantity);
    end;

    local procedure VerifyQuantityOnRequisitionLine(ItemNo: Code[20]; LocationCode: Code[10]; LocationCode2: Code[10]; SalesQuantity: Decimal; TransferQuantity: Decimal)
    begin
        VerifyReqLineQuantity(ItemNo, LocationCode, SalesQuantity);
        VerifyReqLineQuantity(ItemNo, LocationCode2, SalesQuantity);
        VerifyReqLineOriginalQuantity(ItemNo, LocationCode2, TransferQuantity);
    end;

    local procedure VerifyReqLineQuantity(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, RequisitionLine."Action Message"::New, ItemNo, LocationCode);
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReqLineOriginalQuantity(ItemNo: Code[20]; LocationCode: Code[10]; OriginalQuantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, RequisitionLine."Action Message"::Cancel, ItemNo, LocationCode);
        RequisitionLine.TestField("Original Quantity", OriginalQuantity);
    end;

    local procedure VerifyReservedQuantityOnProdOrderComponent(ProdOrderNo: Code[20]; ItemNo: Code[20])
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status::Released, ProdOrderNo, ItemNo);
        ProdOrderComponent.CalcFields("Reserved Quantity");
        Assert.AreEqual(ProdOrderComponent."Expected Quantity", ProdOrderComponent."Reserved Quantity", ReservedQuantityErr);
    end;

    local procedure CreateSpecialOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitPrice: Decimal)
    var
        Purchasing: Record Purchasing;
    begin
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, LocationCode, VariantCode, Qty, PostingDate, UnitPrice);
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);

        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    [Normal]
    local procedure CreatePurchaseOrderForCustomer(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; UnitPrice: Decimal; CustomerNo: Code[20])
    begin
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item, LocationCode, VariantCode, Qty, PostingDate, UnitPrice);
        PurchaseHeader.Validate("Sell-to Customer No.", CustomerNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure MockReservationEntries()
    var
        ReservationEntry: Record "Reservation Entry";
        ItemNo: Code[20];
        ReservationEntryNo: Integer;
    begin
        ItemNo := LibraryInventory.CreateItemNo();
        ReservationEntryNo := LibraryUtility.GetNewRecNo(ReservationEntry, ReservationEntry.FieldNo("Entry No."));
        InsertReservationEntry(ReservationEntryNo, ItemNo, 3, true);
        InsertReservationEntry(ReservationEntryNo, ItemNo, -3, false);
    end;

    local procedure InsertReservationEntry(ReservationEntryNo: Integer; ItemNo: Code[20]; Quantity: Integer; IsPositive: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.Init();
        ReservationEntry."Entry No." := ReservationEntryNo;
        ReservationEntry.Positive := IsPositive;
        ReservationEntry."Item No." := ItemNo;
        ReservationEntry.Quantity := Quantity;
        ReservationEntry."Quantity (Base)" := Quantity;
        ReservationEntry.Insert();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    var
        ItemNo: Variant;
        ItemNo2: Variant;
    begin
        // Calculate Regenerative Plan using page. Required where Forecast is used.
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ItemNo2);
        CalculatePlanPlanWksh.Item.SetFilter("No.", StrSubstNo(ItemFilterTok, ItemNo, ItemNo2));
        CalculatePlanPlanWksh.MPS.SetValue(true);
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(GetRequiredDate(10, 50, WorkDate(), 1));
        CalculatePlanPlanWksh.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReserveFromCurrentLinePageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMsg);
        Assert.IsTrue(AreSameMessages(Message, ExpectedMsg), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerCheckWithPeek(Message: Text[1024])
    var
        ExpectedMsg: Variant;
    begin
        ExpectedMsg := LibraryVariableStorage.PeekText(1);
        Assert.IsTrue(AreSameMessages(Message, LibraryVariableStorage.PeekText(1)), Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Control: Variant;
        SerialNo: Variant;
        OriginalSerialNo: Variant;
        Option: Option Purchase,Sale,Verification;
    begin
        LibraryVariableStorage.Dequeue(Control);
        Option := Control;
        case Option of
            ControlOptions::Purchase:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    SerialNo := ItemTrackingLines."Serial No.".Value();
                    LibraryVariableStorage.Enqueue(SerialNo);
                    ItemTrackingLines.OK().Invoke();
                end;
            ControlOptions::Sale:
                begin
                    LibraryVariableStorage.Dequeue(SerialNo);
                    ItemTrackingLines."Serial No.".SetValue(SerialNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
                    ItemTrackingLines.OK().Invoke();
                end;
            ControlOptions::Verification:
                begin
                    LibraryVariableStorage.Dequeue(OriginalSerialNo);
                    SerialNo := ItemTrackingLines."Serial No.".Value();
                    Assert.AreEqual(OriginalSerialNo, SerialNo, 'Serial no has been deleted');
                end;
            else
                Error(UnexpectedErrorMsg);
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesLotNoModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQtyToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQtyToCreateWithLotNoPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.CreateNewLotNo.SetValue(true);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingWithNoLinesModalPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        OrderTracking."Untracked Quantity".AssertEquals(LibraryVariableStorage.PeekDecimal(2)); // Untracked Quantity
        OrderTracking."Total Quantity".AssertEquals(LibraryVariableStorage.PeekDecimal(3)); // Quantity
        OrderTracking.CurrItemNo.AssertEquals(LibraryVariableStorage.PeekText(4));
        Assert.IsFalse(OrderTracking.First(), 'Order tracking line should not exist');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingWithLinesModalPageHandler(var OrderTracking: TestPage "Order Tracking")
    var
        ItemNo: Text;
    begin
        OrderTracking."Untracked Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal()); // Untracked Quantity
        OrderTracking."Total Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal()); // Quantity
        ItemNo := LibraryVariableStorage.DequeueText();
        // Check 2 lines in Order tracking page with Item "I" exist
        OrderTracking.CurrItemNo.AssertEquals(ItemNo);
        Assert.IsTrue(OrderTracking.First(), OrderTrackingLineShouldExistErr);
        OrderTracking."Item No.".AssertEquals(ItemNo);
        Assert.IsTrue(OrderTracking.Next(), OrderTrackingLineShouldExistErr);
        OrderTracking."Item No.".AssertEquals(ItemNo);
    end;
}

