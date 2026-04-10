codeunit 137294 "SCM Inventory Miscellaneous II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM]
        isInitialized := false;
    end;

    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        RegisterJournalLine: Label 'Do you want to register the journal lines?';
        RegisterJournalLineMessage: Label 'The journal lines were successfully registered.You are now';
        UpdatePhysicalInventoryError: Label 'You cannot change the Qty. (Phys. Inventory) because this item journal line is created from warehouse entries';
        isInitialized: Boolean;
        WhseItemLineRegister: Label 'Do you want to register the journal lines?';
        WhseItemLineRegistered: Label 'The journal lines were successfully registered.';
        CostMustBeSame: Label 'Cost must be Equal.';
        FirmPlannedProdMessage: Label 'Firm Planned Prod. Order';
        CreatePutAwayMessage: Label 'There is nothing to create.';
        ShippingAdviceCnfMsg: Label 'Do you want to change %1 in all related records in warehouse accordingly?';
        PickActivityMessage: Label 'Pick activity no. %1 has been created.';
        WhseShipmentErrorMessage: Label 'The warehouse shipment was not created because the Shipping Advice field is set to Complete';
        AvailabilityWarning: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        WhseRegisterLotError: Label 'Lot No. %1 is not available on inventory or it has already been reserved for another document.';
        MovmntActivityCreatedMessage: Label 'Movement activity no. %1 has been created.';
        WhseMovmntRegisterError: Label 'Quantity (Base) available must not be less than';
        AutoFillQtyMessage: Label 'Quantity available to pick is not enough to fill in all the lines.';
        InvPickCreatedMessage: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';
        NoOfPicksCreatedMsg: Label 'Number of Invt. Pick activities created';
        WhseHandlingRequiredErr: Label 'Warehouse handling is required';
        InventoryMovementIsNotRegisteredErr: Label 'Inventory Movement is not registered.';
        InventoryPickNotFoundErr: Label 'Warehouse Activity Header not found for Production Order Components.';
        PickQtyToHandleErr: Label 'Quantity to Handle on Warehouse Activity Line must be equal to %1.', Comment = '%1 = Expected quantity';
        InsufficientQtyErr: Label 'You have insufficient quantity of Item %1 on inventory.', Comment = '%1 = Item No.';

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryJournalWithNonWMSLocation()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Item can be adjusted through Physical Inventory Journal with Non-Warehouse Location.

        // Setup: Create Physical Inventory Journal and Calculate Inventory.
        Initialize();
        CalculateInventoryOnPhysInventoryJournal(ItemJournalLine);

        // Exercise: Update Quantity(Phys. Inventory) on Physical Inventory Journal.
        FindAndUpdateItemJournalLine(ItemJournalLine);

        // Verify: Verify Quantity on Physical Inventory Journal.
        ItemJournalLine.TestField(Quantity, ItemJournalLine."Qty. (Phys. Inventory)" - ItemJournalLine."Qty. (Calculated)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPhysInventoryJournalWithNonWMSLocation()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Physical Inventory Ledger after updating Qty(Physical Inventory) on Physical Inventory Journal with Non-Warehouse Location.

        // Setup: Create Physical Inventory Journal, Calculate Inventory and update Quantity(Phys. Inventory).
        Initialize();
        CalculateInventoryOnPhysInventoryJournal(ItemJournalLine);
        FindAndUpdateItemJournalLine(ItemJournalLine);

        // Exercise: Post Phys Inventory Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Quantity on Physical Inventory Ledger.
        VerifyPhysInventoryLedger(ItemJournalLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhsePhysInventoryJournalWithWMSLocation()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Verify Item can be adjusted through Warehouse Physical Inventory Journal with Warehouse Location.

        // Setup: Create Warehouse Physical Inventory Journal and Calculate Inventory.
        Initialize();
        CreateWarehouseLocation(Location);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ");
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        CalculateInventoryOnWhsePhysInventoryJournal(WarehouseJournalLine, PurchaseLine, Location.Code);

        // Exercise: Update Quantity(Phys. Inventory) on Warehouse Physical Inventory Journal.
        FindAndUpdateWarehouseJournalLine(WarehouseJournalLine);

        // Verify: Verify Quantity on Warehouse Physical Inventory Journal.
        WarehouseJournalLine.TestField(
          Quantity, WarehouseJournalLine."Qty. (Phys. Inventory)" - WarehouseJournalLine."Qty. (Calculated)");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PhysInventoryQuantityErrorWithWMSLocation()
    var
        Item: Record Item;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Error when Item is to be adjusted through Physical Inventory Journal with Warehouse Location.

        // Setup: Create Physical Inventory Journal With Warehouse Location.
        Initialize();
        LibraryVariableStorage.Enqueue(RegisterJournalLine);
        LibraryVariableStorage.Enqueue(RegisterJournalLineMessage);
        CreateWarehouseLocation(Location);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ");
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        CreatePhysInventoryJournalWithWMSLocation(ItemJournalLine, PurchaseLine, Location.Code);

        // Exercise: Update Quantity(Phys. Inventory) on Physical Inventory Journal.
        asserterror OpenPhysInventoryJournalToUpdateQuantity(ItemJournalLine."Journal Batch Name");

        // Verify: Verify Error when Item with Warehouse Location is to be adjusted through Phys Inventory Journal.
        Assert.ExpectedError(UpdatePhysicalInventoryError);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPhysInventoryJournalWithWMSLocation()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Physical Inventory Ledger after posting Physical Inventory Journal with Warehouse Location.

        // Setup: Create Physical Inventory Journal With Warehouse Location.
        Initialize();
        LibraryVariableStorage.Enqueue(RegisterJournalLine);
        LibraryVariableStorage.Enqueue(RegisterJournalLineMessage);
        CreateWarehouseLocation(Location);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ");
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        CreatePhysInventoryJournalWithWMSLocation(ItemJournalLine, PurchaseLine, Location.Code);

        // Exercise: Post Physical Inventory Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Quantity on Physical Inventory Ledger.
        VerifyPhysInventoryLedger(ItemJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PlanningLinesForSalesOrder()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Planning Lines generated through Calculate Regenerative Plan after creating Sales Order for Production Item with Warehouse Location.

        // Setup.
        Initialize();
        SetupForPlanningWorksheet(SalesLine);
        Item.Get(SalesLine."No.");

        // Exercise: Calculate Regenerative Plan.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));  // Dates based on WORKDATE.

        // Verify: Verify Calculated Planning Lines.
        VerifyRequisitionLine(
          SalesLine."No.", SalesLine."Location Code", SalesLine.Quantity, RequisitionLine."Action Message"::New, true,
          RequisitionLine."Ref. Order Status"::Planned);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PickForProductionOrder()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Verify Pick can be created from Production Order.

        // Setup: Create Released Production Order through Planning Worksheet.
        Initialize();
        SetupForPlanningWorksheet(SalesLine);
        Item.Get(SalesLine."No.");
        FindProductionBOMLine(ProductionBOMLine, Item."Production BOM No.");
        CalcRegenPlanAndCarryOutActionMsg(Item, SalesLine."Location Code");
        FindProductionOrderLine(ProdOrderLine, ProdOrderLine.Status::"Firm Planned", SalesLine."No.", SalesLine."Location Code");
        LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProdOrderLine."Prod. Order No.");
        FindProductionOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, SalesLine."No.", SalesLine."Location Code");
        ProductionOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        ProductionOrder.SetHideValidationDialog(true);

        // Exercise: Create Pick from Released Production Order.
        ProductionOrder.CreatePick(UserId, ProductionOrder.Status::Released.AsInteger(), false, false, false);  // False is for SetBreakBulkFilter, DoNotFillQtyToHandle, PrintDocument Booleans.

        // Verify: Verify Pick is created from Production Order.
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Prod. Order Component", ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField("Item No.", ProductionBOMLine."No.");
        WarehouseActivityLine.TestField(Quantity, SalesLine.Quantity);
        WarehouseActivityLine.TestField("Location Code", SalesLine."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLinesForReleasedProductionOrder()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Verify Planning Lines generated through Calculate Regenerative Plan after creating Released Production Order.

        // Setup: Create Production Item. Create Released Production Order.
        Initialize();
        CreateProductionItem(Item);
        FindProductionBOMLine(ProductionBOMLine, Item."Production BOM No.");
        CreateAndRefreshProductionOrder(ProductionBOMLine."No.");
        Item.Get(ProductionBOMLine."No.");

        // Exercise.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));  // Dates based on WORKDATE.

        // Verify: Verify Calculated Planning Lines.
        VerifyRequisitionLine(
          ProductionBOMLine."No.", '', 0, RequisitionLine."Action Message"::Cancel, false, RequisitionLine."Ref. Order Status"::Released);
    end;

    [Test]
    [HandlerFunctions('CreateOrderFromSalesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure UnitCostOnSalesOrderUsingProdOrderAndReservation()
    var
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine: Record "Sales Line";
        ProdOrderNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify Unit Cost on Sales Line using Production Order and Reservation.

        // Setup : Update Sales and Receivables Setup, post Item Journal Line, create Sales Order and create Production Order with another Sales Order.
        Initialize();
        LibraryVariableStorage.Enqueue(FirmPlannedProdMessage);
        SalesReceivablesSetup.Get();
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning", false);
        ItemNo := CreateItemWithRoutingAndBOM();
        PostItemJournalLine(ItemNo, LibraryRandom.RandInt(100), '');  // Using Random value for Quantity.

        // Create Sales Order and Auto Reserve.
        CreateSalesOrderUsingItemInventory(SalesHeader, ItemNo);
        AutoReserveSalesLine(SalesHeader);
        CreateSalesOrderUsingItemInventory(SalesHeader, ItemNo);
        LibraryManufacturing.CreateProdOrderUsingPlanning(ProductionOrder, ProductionOrder.Status::"Firm Planned", SalesHeader."No.", ItemNo);

        // Exercise: Change Status to Released from Firm Planned using Update Unit Cost as TRUE.
        ProdOrderNo :=
          LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");

        // Verify : Verify Unit Cost on Sales Line.
        FindSalesLine(SalesLine, SalesHeader);
        VerifyProdComponentUnitCost(ProductionOrder.Status::Released, ProdOrderNo, SalesLine."Unit Cost");

        // Tear down.
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Credit Warnings", SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustmentUsingProdOrderConsumptionAndOutput()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ProdOrderNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify Cost Amount Actual in Item Ledger Entry after Adjustment.

        // Setup : Update Sales and Receivables Setup, create Production Order post Item Journal Line.
        Initialize();
        SalesReceivablesSetup.Get();
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Credit Warnings"::"No Warning", false);
        ItemNo := CreateItemWithRoutingAndBOM();
        ProdOrderNo := CreateAndRefreshProductionOrder(ItemNo);

        // Create Consumption Journal, Delete Released production Order line and Post Consumption Journal.
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, '', ItemJournalBatch."Template Type"::Consumption, ProdOrderNo);
        DeleteProdOrderLine(ProdOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Create and Post Output Journal.
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, ItemNo, ItemJournalBatch."Template Type"::Output, ProdOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProdOrderNo);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');

        // Verify : Verify Cost Amount Actual in Item Ledger Entry after Adjustment.
        VerifyUnitCostOnItemAfterAdjustment(ProdOrderNo, ItemNo);

        // Tear down.
        UpdateSalesReceivableSetup(SalesReceivablesSetup."Credit Warnings", SalesReceivablesSetup."Stockout Warning");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CreateInvPickFromSalesOrder()
    var
        SalesLine: Record "Sales Line";
        Location: Record Location;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // Verify message during used option Create Inv. Pick/Put Away on Sales Order.

        // Setup: Create Warehouse Location, Sales Order and Release.
        Initialize();
        CreateWarehouseLocation(Location);
        SetupForCreatePickOnSalesDocument(SalesLine, Location.Code, "Sales Header Shipping Advice"::Complete, 2);
        LibraryVariableStorage.Enqueue(CreatePutAwayMessage);

        // Exercise: Check Inventory Pick Away on Sales Order.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", SalesLine."Document No.", true, false, false);

        // Verify: Verify message during used option Create Inv. Pick/Put Away on Sales Order. Verification done by Message Handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromSalesOrder()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Verify Warehouse Activity Line after create Pick from Whse. Shipment created from Sales Order.

        // Setup: Create Warehouse Location, Sales Order and Release.
        Initialize();
        CreateWarehouseLocation(Location);
        SetupForCreatePickOnSalesDocument(SalesLine, Location.Code, "Sales Header Shipping Advice"::Partial, 1);

        // Exercise.
        CreatePick(WarehouseShipmentHeader, Location.Code, SalesLine."Document No.");

        // Verify: Verify Warehouse Activity Line.
        VerifyWhseActivityLine(SalesLine, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnCreationOfPickForOutStockItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Location: Record Location;
    begin
        // Verify error while creating Whse. Shipment from Sales Order for non stock Item.

        // Setup: Create Warehouse Location, create and Release Sales Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ");
        CreateWarehouseLocation(Location);
        LibraryVariableStorage.Enqueue(ShippingAdviceCnfMsg);  // Enqueue for Message Handler.
        CreateSalesOrderWithShippingAdvice(SalesHeader, Location.Code, SalesHeader."Shipping Advice"::Complete, Item."No.", 1);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise.
        asserterror LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Verify error while creating Whse. Shipment from Sales Order.
        Assert.ExpectedError(WhseShipmentErrorMessage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickForInStockItemOnSalesOrder()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Verify Warehouse Activity Line after create Pick from Whse. Shipment created from Sales Order which have 1 InStock Item and 1 OutStock Item with Partial Shipping Advice.

        // Setup: Create Warehouse Location, Sales Order and Release.
        Initialize();
        CreateWarehouseLocation(Location);
        SetupForCreatePickOnSalesDocument(SalesLine, Location.Code, "Sales Header Shipping Advice"::Partial, 3);

        // Exercise.
        CreatePick(WarehouseShipmentHeader, Location.Code, SalesLine."Document No.");

        // Verify: Verify Warehouse Activity Line.
        VerifyWhseActivityLine(SalesLine, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CreateWhseRcptAndCalcPhysInvWithIT()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // Verify Warehouse Entry with Item Tracking.

        // Setup: Create Location, create and release Purchase Order with Item Tracking and create Warehouse Receipt.
        Initialize();
        CreateWarehouseLocation(Location);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, CreateAndModifyTrackedItem(0), Location.Code);  // 0 used for update Expiration Date.
        LibraryVariableStorage.Enqueue(RegisterJournalLine);
        LibraryVariableStorage.Enqueue(RegisterJournalLineMessage);
        Quantity := CreatePhysInventoryJournalWithWMSLocation(ItemJournalLine, PurchaseLine, Location.Code);

        // Exercise: Post Physical Inventory Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Verify Warehouse Entry with Item Tracking.
        VerifyWarehouseEntries(
          ItemJournalLine."Item No.", ItemJournalLine."Location Code", '', Quantity, WarehouseEntry."Entry Type"::"Positive Adjmt.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedQuantityInSalesOrder()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Location2: Record Location;
        Location3: Record Location;
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        DocumentNo: Code[20];
    begin
        // Verify Reserve Quantity in Sales Order after Positive Adjustment,Transfer order,Nagative Adjustment on Item.

        // Setup : Create Location,Create Item,Positive Adjustment,Transfer order,Nagative Adjustment on Created Item.
        Initialize();
        CreateLocationWithMultipleBin(Location, Bin, Bin2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(
          ItemJournalLine, Item."No.", Location.Code, Bin.Code, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryRandom.RandDecInDecimalRange(100, 150, 2));  // Large Quantity required for test.
        DocumentNo := ItemJournalLine."Document No.";
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location2);
        LibraryWarehouse.CreateInTransitLocation(Location3);
        CreateTransferOrderAndPick(TransferLine, Bin2.Code, Location.Code, Location2.Code, Location3.Code, Item."No.");
        CreateAndPostItemJournalLine(
          ItemJournalLine, Item."No.", Location.Code, Bin.Code, ItemJournalLine."Entry Type"::"Negative Adjmt.",
          LibraryRandom.RandDecInDecimalRange(50, 100, 2) - TransferLine.Quantity);

        // Excercise : Create Sales Order,Reserve Quantity As Auto Reserve.
        CreateSalesOrder(SalesLine, Location.Code, Item."No.", LibraryRandom.RandDec(10, 2));  // Using Random value for Sales Line Quantity.
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // Verify : Verify Reserve Quantity with Item Ledger Entry.
        VerifyReserveQuantity(
          Item."No.", DocumentNo, ItemJournalLine."Location Code", ItemJournalLine."Entry Type"::"Positive Adjmt.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PickCreationMessageFromWhseShipment()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Verify Message while pick created from Warehouse Shipment Header.

        // Setup: Create Put-away, Warehouse Receipt and Released Sales Order.
        Initialize();
        SetupForWarehousePickPutAway(SalesHeader);

        // Exercise.
        CreatePick(WarehouseShipmentHeader, SalesHeader."Location Code", SalesHeader."No.");

        // Verify: Verify pick creation message. Done by MessageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickWithIT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Verify Warehouse Activity Line after pick created from Warehouse Shipment Header.

        // Setup: Setup. Create Put-away, Warehouse Receipt and Released Sales Order.
        Initialize();
        SetupForWarehousePickPutAway(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader);

        // Exercise.
        CreatePick(WarehouseShipmentHeader, SalesHeader."Location Code", SalesHeader."No.");

        // Verify: Verify Warehouse Activity Line
        VerifyWhseActivityLine(SalesLine, SalesLine.Quantity / 2);  // verify Quantity on single Lot.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,PickSelectionPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ShowWarehouseShipementFromPickWorksheet()
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Verify Get Warehouse Shipment form Pick Worksheet.

        // Setup: Create Put-away, Warehouse Receipt, Released Sales Order and Released Warehouse Shipment.
        Initialize();
        SetupForWarehousePickPutAway(SalesHeader);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader."No.", SalesHeader."Location Code");

        // Exercise.
        GetWarehouseDocumentFromPickWorksheet(WarehouseShipmentHeader);

        // Verify: Verify Get Warehouse Document from Pick Worksheet. Done by PickSelctionPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,PickSelectionPageHandler,CreatePickPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure CreatePickFromPickWorksheetWithIT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Warehouse Activity Line after Pick creation form Pick Worksheet.

        // Setup: Create Put-away, Warehouse Receipt, Released Sales Order and Released Warehouse Shipment.
        Initialize();
        SetupForCreatePickFromPickWorksheet(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader);

        // Exercise:
        CreatePickFromPickWkshPage(SalesHeader."Location Code");

        // Verify: Verify Warehouse Activity Line after Pick creation form Pick Worksheet.
        VerifyWhseActivityLine(SalesLine, SalesLine.Quantity / 2);  // verify Quantity on single Lot.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,PickSelectionPageHandler,CreatePickPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WhseShipmentAfterPickCreatedFromPickWkshtWithIT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentNo: Code[20];
    begin
        // Verify Warehouse Entriy create from Warehouse Shipment after Pick creation form Pick Worksheet.

        // Setup: Create Put-away, Warehouse Receipt, Released Sales Order and Released Warehouse Shipment.
        Initialize();
        WarehouseShipmentNo := SetupForCreatePickFromPickWorksheet(SalesHeader);
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        CreatePickFromPickWkshPage(SalesHeader."Location Code");
        RegisterWarehouseActivity(DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        FindSalesLine(SalesLine, SalesHeader);

        // Exercise:
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify Warehouse Entry after Pick Created From Pick Worksheet With Item Tracking.
        VerifyWarehouseEntries(
          SalesLine."No.", SalesLine."Location Code", FindPostedWareHouseShipmentNo(WarehouseShipmentHeader."No."),
          -SalesLine.Quantity / 2, WarehouseEntry."Entry Type"::"Negative Adjmt.");  // verify Quantity on single Lot.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnWhseRegisterForExceededQuantitytWithIT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LotNo: Variant;
        TrackingOption: Option SelectEntries,SetValues,AssignLotNo;
    begin
        // Verify Error while Warehouse Register with exceeded Quantity and new Lot No.

        // Setup: Create Put-away, Warehouse Receipt, Released Sales Order.
        Initialize();
        SetupForWarehousePickPutAway(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader);

        // Add one more Sales Line with new Lot No. and extra Quantity.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandInt(5));  // Using Random value for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarning);  // Enqueue value for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Dequeue(LotNo);  // Dequeue value for ItemTrackingLinesPageHandler.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Create Pick from Warehouse Shipment
        CreatePick(WarehouseShipmentHeader, SalesHeader."Location Code", SalesHeader."No.");

        // Exercise:
        asserterror RegisterWarehouseActivity(DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Verify: Verify Error while Warehouse Register with exceeded Quanaity.
        Assert.ExpectedError(StrSubstNo(WhseRegisterLotError, LotNo));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterAndPostWhseShipmentWithIT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        EntryType: Option "Negative Adjmt.","Positive Adjmt.",Movement;
    begin
        // Verify Warehouse Entry with Item Tracking after posting Warehouse Shipment.

        // Setup: Create Put-away, Warehouse Receipt and Released Sales Order.
        Initialize();
        SetupForWarehousePickPutAway(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader);

        // Create Pick from Warehouse Shipment and Register.
        CreatePick(WarehouseShipmentHeader, SalesHeader."Location Code", SalesHeader."No.");
        RegisterWarehouseActivity(DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify Warehouse Entry with Item Tracking.
        VerifyWarehouseEntries(
          SalesLine."No.", SalesLine."Location Code", FindPostedWareHouseShipmentNo(WarehouseShipmentHeader."No."),
          -SalesLine.Quantity / 2, EntryType::"Negative Adjmt.");  // verify Quantity on single Lot.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,CreateWhseMovementPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseMovementWithIT()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PurchaseLine: Record "Purchase Line";
        EntryType: Option "Negative Adjmt.","Positive Adjmt.",Movement;
    begin
        // Verify Warehouse Entry after Register Warehouse Movement with Item Tracking.

        // Setup: Create Warehouse Receipt, Movement Worksheet Line, Assign Item Tracking to Movement Line and create Movement from Worksheet
        Initialize();
        CreateWhseReceiptAndMovementWorksheetLine(PurchaseLine);
        AssignItemTrackingInMovementWksht(PurchaseLine."No.");
        CreateMovementFromWorksheet(WarehouseActivityHeader);

        // Exercise.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // Verify: Verify Warehouse Entry after Register Warehouse Movement with Item Tracking.
        VerifyWarehouseEntries(
          PurchaseLine."No.", PurchaseLine."Location Code", FindPostedWarehouseReceiptNo(PurchaseLine."Location Code"),
          -PurchaseLine.Quantity / 2, EntryType::Movement);  // verify Quantity on single Lot.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CreateWhseMovementPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseMovemenErrortWithoutIT()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Error while Register Warehouse Movement without Item Tracking, Quantity received from Warehouse Purch. Receipt with Item Tracking.

        // Setup: Create Warehouse Receipt, Movement Worksheet Line, and create Movement from Worksheet
        Initialize();
        CreateWhseReceiptAndMovementWorksheetLine(PurchaseLine);
        CreateMovementFromWorksheet(WarehouseActivityHeader);

        // Exercise.
        asserterror LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // Verify: Verify Error while Warehouse Movement Register without Item Tracking.
        Assert.ExpectedError(WhseMovmntRegisterError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler,WhseItemTrackingLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SuggestItemForAdjustmentBin()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Verify Warehouse Entry after Pick Created From Warehouse Shipment With Item Tracking after Register and Post Item Journal with IT.

        // Setup.
        Initialize();
        CreateWarehouseLocation(Location);

        // Create Register Warehouse Receipt, Register Item Journal.
        CreateWhseReceiptAndRegister(PurchaseLine, Location.Code);
        CreateAndRegisterWhseJournalLine(PurchaseLine, Location.Code, Location."Receipt Bin Code");

        // Create Pick from Warehouse Shipment and Post Item Journal.
        CreatePickAndRegisterWhseShipment(WarehouseShipmentHeader, PurchaseLine."No.", Location.Code, PurchaseLine.Quantity / 2);  // For Single Lot.
        CalcWhseAdjustmentAndPostItemJournalLine(PurchaseLine."No.");

        // Exercise.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Verify: Verify Warehouse Entry after Pick Created From Warehouse Shipment With Item Tracking.
        VerifyWarehouseEntries(
          PurchaseLine."No.", PurchaseLine."Location Code", FindPostedWareHouseShipmentNo(WarehouseShipmentHeader."No."),
          -PurchaseLine.Quantity / 2, WarehouseEntry."Entry Type"::"Negative Adjmt.");  // verify Quantity on single Lot.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvPickAfterPurchaseReceipt()
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify: Verify Item Ledger Entry after posting Inventory Pick.

        // Setup: Create Location, create Purchase Order and Post, create Sales Order and create Inv. Pick.
        Initialize();
        CreateLocation(Location, false, false);
        CreateAndPostPurchaseOrder(PurchaseLine, Location.Code);
        CreateAndReleaseSaleslOrderWithIT(SalesHeader, Location.Code, PurchaseLine."No.", PurchaseLine.Quantity);
        CreateInvPickAndPost(WarehouseActivityHeader, SalesHeader);

        // Exercise.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // Verify: Item Ledger Entry after posting Inventory Pick.
        VerifyItemLedgerEntry(ItemLedgerEntry, Location.Code, PurchaseLine."No.", -PurchaseLine.Quantity / 2)
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure InvPickUpdatesPostingDateInSalesDoc() //Test
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [Scenario] Verify Posting Date on Sales Doc gets updated when Inventory Pick posting date is updates.

        // [GIVEN] Setup: Create Location, create Sales Order, release, set Posting Date and create Inv. Pick.
        Initialize();

        // [GIVEN] Create and Release Sales Order with a Posting Date
        CreateReleasedItemSalesOrderFromLocation(SalesHeader);
        SalesHeader.Validate("Posting Date", CalcDate('<CD+20D>', WorkDate()));
        SalesHeader.Modify();

        Commit();

        // [GIVEN] Create Inventory Pick From Sales Order
        CreateInventoryPickFromSalesHeader(SalesHeader);

        // [GIVEN] Change the Posting Date on the Inventory Pick.
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.TestField("Destination Type", WarehouseActivityLine."Destination Type"::Customer);

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Validate("Posting Date", WorkDate());
        WarehouseActivityHeader.Modify();
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity - 1);
        WarehouseActivityLine.Modify();

        // [WHEN] Inventory Pick is posted
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] Posting date is updated on the sales document.
        SalesHeader.Find();
        SalesHeader.TestField("Posting Date", WorkDate());
    end;

    [Test]
    procedure InvPickUpdatesPostingDateInServiceDoc()
    var
        ServiceHeader: Record "Service Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        LocationCode: Code[10];
    begin
        // [Scenario] Verify Posting Date on Service Doc gets updated when Pick posting date is updates.
        // [GIVEN] Setup: Create Location, create Service Order, release, set Posting Date and create and post Shipment and Pick
        Initialize();

        // [GIVEN] Create and Release Service Order with a Posting Date
        LocationCode := CreateReleasedItemServiceOrderFromLocation(ServiceHeader);
        ServiceHeader.Validate("Posting Date", CalcDate('<CD+20D>', WorkDate()));
        ServiceHeader.Modify();

        Commit();

        // [GIVEN] Create Warehouse Shipment From Service Order
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
        FindWhseShipmentHeader(WhseShipmentHeader, LocationCode, Enum::"Warehouse Activity Source Document"::"Service Order", ServiceHeader."No.");

        // [GIVEN] Create a warehouse pick from the shipment
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);

        // [GIVEN] Change the Posting Date on the Inventory Pick.
        FindWarehouseActivityLine(
          WarehouseActivityLine, Database::"Service Line", ServiceHeader."No.", WarehouseActivityLine."Activity Type"::"Pick");
        WarehouseActivityLine.TestField("Destination Type", WarehouseActivityLine."Destination Type"::Customer);

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Validate("Posting Date", WorkDate());
        WarehouseActivityHeader.Modify();
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity - 1);
        WarehouseActivityLine.Modify();

        // [GIVEN] Pick is registered
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post Warehouse Shipment
        LibraryWarehouse.PostWhseShipment(WhseShipmentHeader, false);

        // [THEN] Posting date is updated on the service document
        ServiceHeader.Find();
        ServiceHeader.TestField("Posting Date", WorkDate());
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure TFS356264_ItemPickedAccordingToFEFO()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        LotNos: array[2] of Code[20];
        QtyToSell: Decimal;
        LotQty: Decimal;
    begin
        GenerateRandomLotQuantities(LotQty, QtyToSell);

        CreateFEFOLocation(Location, false);
        CreateSalesOrderBreakInTwoLots(SalesHeader, LotNos, Location.Code, '', LotQty, QtyToSell);

        Commit();
        CreateInventoryPickFromSalesHeader(SalesHeader);
        VerifyInventoryPickLines(SalesHeader."No.", LotNos, QtyToSell - LotQty, LotQty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure TFS356264_ItemPickedAccordingToFEFOWithReservation()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        LotNos: array[2] of Code[20];
        QtyToSell: Decimal;
        LotQty: Decimal;
    begin
        GenerateRandomLotQuantities(LotQty, QtyToSell);

        CreateFEFOLocation(Location, false);
        CreateSalesOrderBreakInTwoLots(SalesHeader, LotNos, Location.Code, '', LotQty, QtyToSell - LotQty);
        AutoReserveSalesLine(SalesHeader);

        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesHeader.Find();
        UpdateSalesOrderQuantity(SalesHeader."No.", QtyToSell);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        Commit();
        CreateInventoryPickFromSalesHeader(SalesHeader);
        // Second lot is completely picked, quantity to pick from the first lot = Lot Quantity - Reserved Quantity
        // Known Issue: Need to update test results
        // VerifyInventoryPickLines(SalesHeader."No.", LotNos, 2 * LotQty - QtyToSell, LotQty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure TFS356264_ItemPickedAccordingToFEFOWithBinMandatory()
    var
        Location: Record Location;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        LotNos: array[2] of Code[20];
        QtyToSell: Decimal;
        LotQty: Decimal;
    begin
        GenerateRandomLotQuantities(LotQty, QtyToSell);

        CreateFEFOLocation(Location, true);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');

        CreateSalesOrderBreakInTwoLots(SalesHeader, LotNos, Location.Code, Bin.Code, LotQty, QtyToSell);

        Commit();
        CreateInventoryPickFromSalesHeader(SalesHeader);
        VerifyInventoryPickLines(SalesHeader."No.", LotNos, QtyToSell - LotQty, LotQty);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure DestinationForInventoryPickFromSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Inventory Pick] [Sales Order]
        // [SCENARIO 381306] "Destination Type" and "Destination No." fields of "Warehouse Activity Line" table must be filled for Inventory Pick from Sales Order.
        Initialize();

        // [GIVEN] Released Sales Order
        CreateReleasedItemSalesOrderFromLocation(SalesHeader);

        Commit();

        // [WHEN] Create Inventory Pick From Sales Order
        CreateInventoryPickFromSalesHeader(SalesHeader);

        // [THEN] "Warehouse Activity Line"."Destination Type" is equal to "Destination Type"::Customer
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.TestField("Destination Type", WarehouseActivityLine."Destination Type"::Customer);

        // [THEN] "Warehouse Activity Line"."Destination No." is equal to "Sell-to Customer No." of Sales Order
        WarehouseActivityLine.TestField("Destination No.", SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure DestinationForInventoryPickFromPurchaseReturnOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Inventory Pick] [Purchase Return Order]
        // [SCENARIO 381306] "Destination Type" and "Destination No." fields of "Warehouse Activity Line" table must be filled for Inventory Pick from Purchase Return Order.
        Initialize();

        // [GIVEN] Released Purchase Return Order
        CreateReleasedItemPurchaseReturnOrderFromLocation(PurchaseHeader);

        Commit();

        // [WHEN] Create Inventory Pick From Purchase Return Order
        CreateInventoryPickFromPurchaseHeader(PurchaseHeader);

        // [THEN] "Warehouse Activity Line"."Destination Type" is equal to "Destination Type"::Vendor
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Purchase Line", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.TestField("Destination Type", WarehouseActivityLine."Destination Type"::Vendor);

        // [THEN] "Warehouse Activity Line"."Destination No." is equal to "Buy-from Vendor No." of Purchase Order
        WarehouseActivityLine.TestField("Destination No.", PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure DestinationForInventoryPickFromTransfer()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Inventory Pick] [Transfer]
        // [SCENARIO 381306] "Destination Type" and "Destination No." fields of "Warehouse Activity Line" table must be filled for Inventory Pick from Transfer.
        Initialize();

        // [GIVEN] Released Transfer
        CreateReleasedItemTransferOrderFromLocationToSomeNewLocation(TransferHeader);

        Commit();

        // [WHEN] Create Inventory Pick From Transfer
        CreateInventoryPickFromTransferHeader(TransferHeader);

        // [THEN] "Warehouse Activity Line"."Destination Type" is equal to "Destination Type"::Location
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Transfer Line", TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.TestField("Destination Type", WarehouseActivityLine."Destination Type"::Location);

        // [THEN] "Warehouse Activity Line"."Destination No." is equal to "Transfer-to Code" of Transfer
        WarehouseActivityLine.TestField("Destination No.", TransferHeader."Transfer-to Code");
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure DestinationForInventoryMovementFromAssemblyOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Inventory Movement] [Assembly Order]
        // [SCENARIO 381306] "Destination Type" and "Destination No." fields of "Warehouse Activity Line" table must be filled for Inventory Movement from Assembly Order.
        Initialize();

        // [GIVEN] Released Assembly Order
        CreateReleasedAssemblyOrder(AssemblyHeader);

        // [WHEN] Create Inventory Movement From Assembly Order
        LibraryAssembly.CreateInvtMovement(AssemblyHeader."No.", false, false, true);

        // [THEN] "Warehouse Activity Line"."Destination Type" is equal to "Destination Type"::Item
        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Assembly Line", AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        WarehouseActivityLine.TestField("Destination Type", WarehouseActivityLine."Destination Type"::Item);

        // [THEN] "Warehouse Activity Line"."Destination No." is equal to "Item No." of Assembly Order
        WarehouseActivityLine.TestField("Destination No.", AssemblyHeader."Item No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWhenInvPickExists()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Order] [Inventory Pick]
        // [SCENARIO 267783] Sales Order posting trial must lead to an error if at least one Inventory Pick exists for the Sales Order

        Initialize();

        // [GIVEN] Create and release Sales Order
        CreateReleasedItemSalesOrderFromLocation(SalesHeader);

        Commit();

        // [GIVEN] Create Inventory Pick for Sales Order
        CreateInventoryPickFromSalesHeader(SalesHeader);

        // [WHEN] Attempting to post the Sales Header as Shipment
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Catch an expected error
        Assert.ExpectedError(WhseHandlingRequiredErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePutawayReportHandler')]
    [Scope('OnPrem')]
    procedure PostSalesReturnWhenInvPutAwayExists()
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales Return Order] [Inventory Put-away]
        // [SCENARIO 267783] Sales Return Order posting trial must lead to an error if at least one Inventory Put-away exists for the Sales Order

        Initialize();

        // [GIVEN] Create and release Sales Return Order
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order",
          LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo(),
          LibraryRandom.RandInt(10), Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        Commit();

        // [GIVEN] Create Inventory Put-away for Sales Return Order
        CreateInventoryPickFromSalesHeader(SalesHeader);

        // [WHEN] Attempting to post the Sales Return Header as Receipt
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Catch an expected error
        Assert.ExpectedError(WhseHandlingRequiredErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePutawayReportHandler')]
    [Scope('OnPrem')]
    procedure PostPurchOrderWhenInvPutAwayExists()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // [FEATURE] [Purchase Order] [Inventory Put-away]
        // [SCENARIO 267783] Purchase Order posting trial must lead to an error if at least one Inventory Put-away exists for the Purchase Order

        Initialize();

        // [GIVEN] Create and release Purchase Order
        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);
        CreatePurchaseOrder(PurchaseLine, LibraryInventory.CreateItemNo(), Location.Code);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        Commit();

        // [GIVEN] Create an Inventory Put-away for the Purchase Order
        CreateInventoryPickFromPurchaseHeader(PurchaseHeader);

        // [WHEN] Attempting to post the Purchase Order as Receipt
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Catch an expected error
        Assert.ExpectedError(WhseHandlingRequiredErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,CreatePickReportHandler')]
    [Scope('OnPrem')]
    procedure PostPurchReturnWhenInvPickExists()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase Return Order] [Inventory Pick]
        // [SCENARIO 267783] Purchase Return Order posting trial must lead to an error if at least one Inventory Pick exists for the Purchase Return Order

        Initialize();

        // [GIVEN] Create and release Purchase Return Order
        CreateReleasedItemPurchaseReturnOrderFromLocation(PurchaseHeader);

        Commit();

        // [GIVEN] Create Inventory Pick for Purchse Return Order
        CreateInventoryPickFromPurchaseHeader(PurchaseHeader);

        // [WHEN] Attempting to post the Purchase Return Header as Shipment
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Catch an expected error
        Assert.ExpectedError(WhseHandlingRequiredErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesDequeuePageHandler,DummyMessageHandler,CreateWhseMovementPageHandler')]
    [Scope('OnPrem')]
    procedure CreateWhseMvmtMultipleLots()
    var
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        LotNo: array[2] of Code[20];
        Quantity: array[2] of Decimal;
        I: Integer;
    begin
        // [FEATURE] [Item Tracking] [Movement] [Create Movement] [Lot No.]
        // [SCENARIO 338913] Create Movement respects Item Tracking information for multiple source movement worksheet lines for the same item
        Initialize();

        // [GIVEN] Bin for Location "WHITE"
        WhiteLocationSetup(Bin);

        // [GIVEN] Item with lot tracking
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode());

        // [GIVEN] Warehouse Item Journal Line 10000 with Quantity = 6 and Item Tracking Line for Lot No. "L01"
        // [GIVEN] Warehouse Item Journal Line 20000 with Quantity = 3 and Item Tracking Line for Lot No. "L02"
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        for I := 1 to ArrayLen(LotNo) do begin
            Quantity[I] := LibraryRandom.RandDec(10, 0);
            LotNo[I] := LibraryUtility.GenerateGUID();
            CreateWarehouseJournalLineWithItemTracking(WarehouseJournalLine, WarehouseJournalBatch, Bin, Item."No.", Quantity[I], LotNo[I]);
        end;

        // [GIVEN] Warehouse Item Journal Lines registered
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);

        // [GIVEN] Item Journal Line created with Calculate Warehouse Adjustment for the Item, Posted
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Movement Worksheet Line 10000 for Quantity = 6, Item Tracked with "Lot No." = "L01"
        // [GIVEN] Movement Worksheet Line 20000 for Quantity = 3, Item Tracked with "Lot No." = "L02"
        CreateWhseWorksheetName(WhseWorksheetName, Bin."Location Code");
        for I := 1 to ArrayLen(Quantity) do begin
            CreateWhseWorksheetLine(
              WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Item."No.", Bin."Location Code",
              Quantity[I]);

            LibraryVariableStorage.Enqueue(LotNo[I]);
            LibraryVariableStorage.Enqueue(Quantity[I]);
            WhseWorksheetLine.OpenItemTrackingLines();
        end;

        // [WHEN] Run Create Movement for Movement Worksheet Lines
        Commit();
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] 2 Movement Lines (Take/Place) created with Quantity = 6 and "Lot No." = "L01"
        // [THEN] 2 Movement Lines (Take/Place) created with Quantity = 3 and "Lot No." = "L02"
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetFilter(
          "Action Type", '%1|%2', WarehouseActivityLine."Action Type"::Place, WarehouseActivityLine."Action Type"::Take);
        Assert.RecordCount(WarehouseActivityLine, ArrayLen(LotNo) * 2);
        for I := 1 to ArrayLen(Quantity) do
            VerifyWhseActivityLineWithLotNo(WarehouseActivityLine, Quantity[I], LotNo[I]);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesDequeuePageHandler,DummyMessageHandler,CreateWhseMovementPageHandler')]
    [Scope('OnPrem')]
    procedure CreateWhseMvmtMultipleLinesSameLots()
    var
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        LotNo: Code[50];
        Quantity: array[2] of Decimal;
        TotalQuantity: Integer;
        I: Integer;
    begin
        // [FEATURE] [Item Tracking] [Movement] [Create Movement] [Lot No.]
        // [SCENARIO 338913] Create Movement summarizes Item Tracking quantities for multiple source movement worksheet lines for the same item and same "Lot No."
        Initialize();

        // [GIVEN] Bin for Location "WHITE"
        WhiteLocationSetup(Bin);

        // [GIVEN] Item with lot tracking
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode());

        // [GIVEN] Warehouse Item Journal Line 10000 with Quantity = 6 and Item Tracking Line for Lot No. "L01"
        // [GIVEN] Warehouse Item Journal Line 20000 with Quantity = 3 and Item Tracking Line for Lot No. "L01"
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        LotNo := LibraryUtility.GenerateGUID();
        for I := 1 to ArrayLen(Quantity) do begin
            Quantity[I] := LibraryRandom.RandDec(10, 0);
            CreateWarehouseJournalLineWithItemTracking(WarehouseJournalLine, WarehouseJournalBatch, Bin, Item."No.", Quantity[I], LotNo);
            TotalQuantity += Quantity[I];
        end;

        // [GIVEN] Warehouse Item Journal Lines registered
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);

        // [GIVEN] Item Journal Line created with Calculate Warehouse Adjustment for the Item, Posted
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Movement Worksheet Line 10000 for Quantity = 6, Item Tracked with "Lot No." = "L01"
        // [GIVEN] Movement Worksheet Line 20000 for Quantity = 3, Item Tracked with "Lot No." = "L01"
        CreateWhseWorksheetName(WhseWorksheetName, Bin."Location Code");
        for I := 1 to ArrayLen(Quantity) do begin
            CreateWhseWorksheetLine(
              WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Item."No.", Bin."Location Code",
              Quantity[I]);

            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(Quantity[I]);
            WhseWorksheetLine.OpenItemTrackingLines();
        end;

        // [WHEN] Run Create Movement for Movement Worksheet Lines
        Commit();
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [THEN] 2 Movement Lines (Take/Place) created with Quantity = 9 and "Lot No." = "L01"
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetFilter(
          "Action Type", '%1|%2', WarehouseActivityLine."Action Type"::Place, WarehouseActivityLine."Action Type"::Take);
        Assert.RecordCount(WarehouseActivityLine, 2);
        VerifyWhseActivityLineWithLotNo(WarehouseActivityLine, TotalQuantity, LotNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure TestChangingTypeInReleasedSalesErrorsOut()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineCreated: Record "Sales Line";
        Item: Record Item;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create sales order with a line of Type "Item"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(''));
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLineCreated, SalesHeader, SalesLineCreated.Type::Item, Item."No.", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()),
          3);  // Use Random days to calculate Shipment Date.

        // [GIVEN] Release sales
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.Modify();

        // [WHEN] Change sales line Type to Comment
        SalesLine.Get(SalesLineCreated."Document Type", SalesLineCreated."Document No.", SalesLineCreated."Line No.");
        asserterror SalesLine.Validate(Type, SalesLine.Type::" ");

        // [THEN] Error is raised
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;


    [Test]
    procedure TestChangingTypeInReleasedPurchaseErrorsOut()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLineCreated: Record "Purchase Line";
        Item: Record Item;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create purchase order with a line of Type "Item"
        LibraryPurchase.CreatePurchaseOrder(PurchHeader);
        LibraryPurchase.CreatePurchaseLine(PurchLineCreated, PurchHeader, PurchLineCreated.Type::Item, Item."No.", 4);

        // [GIVEN] Release purchase
        LibraryPurchase.ReleasePurchaseDocument(PurchHeader);
        PurchHeader.Modify();

        // [WHEN] Change purch line Type to Comment
        Clear(PurchLine);
        PurchLine.Get(PurchLineCreated."Document Type", PurchLineCreated."Document No.", PurchLineCreated."Line No.");
        asserterror PurchLine.Validate(Type, PurchLine.Type::" ");

        // [THEN] Error is raised
        Assert.ExpectedTestFieldError(PurchHeader.FieldCaption(Status), Format(PurchHeader.Status::Open));
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPutawayForPurchaseOrderWithAdditionalFilters()
    var
        Location: Record Location;
        Item: array[3] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReceiptDate: array[3] of Date;
        i: Integer;
    begin
        // [FEATURE] [Inventory Put-away] [Partial] [Purchase Order]
        // [SCENARIO 315268] Partial creation of inventory put-away for purchase order.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, '', Location.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            ReceiptDate[i] := WorkDate() + 30 * i;
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item[i]."No.", ReceiptDate[i]);
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Receipt Date Filter", ReceiptDate[2]);

        Commit();
        PurchaseHeader.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Purchase Line", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPutawayForSalesReturnOrderWithAdditionalFilters()
    var
        Location: Record Location;
        Item: array[3] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ShipmentDate: array[3] of Date;
        i: Integer;
    begin
        // [FEATURE] [Inventory Put-away] [Partial] [Sales Return Order]
        // [SCENARIO 315268] Partial creation of inventory put-away for sales return order.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        LibrarySales.CreateSalesReturnOrderWithLocation(SalesHeader, '', Location.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            ShipmentDate[i] := WorkDate() + 30 * i;
            CreateSalesLine(SalesLine, SalesHeader, Item[i]."No.", ShipmentDate[i]);
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Receipt Date Filter", ShipmentDate[2]);

        Commit();
        SalesHeader.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPutawayForTransferReceiptWithAdditionalFilters()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: array[3] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReceiptDate: array[3] of Date;
        i: Integer;
    begin
        // [FEATURE] [Inventory Put-away] [Partial] [Transfer Order]
        // [SCENARIO 315268] Partial creation of inventory put-away for transfer order.
        Initialize();

        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        LocationTo.Validate("Require Put-away", true);
        LocationTo.Validate("Always Create Put-away Line", true);
        LocationTo.Modify(true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateAndPostItemJournalLine(
              ItemJournalLine, Item[i]."No.", LocationFrom.Code, '', ItemJournalLine."Entry Type"::"Positive Adjmt.",
              LibraryRandom.RandIntInRange(20, 40));
            ReceiptDate[i] := WorkDate() + 30 * i;
            CreateTransferLine(TransferLine, TransferHeader, Item[i]."No.", Workdate(), ReceiptDate[i]);
        end;
        LibraryInventory.ReleaseTransferOrder(TransferHeader);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Receipt Date Filter", ReceiptDate[2]);

        Commit();
        TransferHeader.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Transfer Line", TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPutawayForProductionOrderWithAdditionalFilters()
    var
        Location: Record Location;
        Item: array[3] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: array[3] of Record "Prod. Order Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        // [FEATURE] [Inventory Put-away] [Partial] [Production Order]
        // [SCENARIO 315268] Partial creation of inventory put-away for production order.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, true, false, false, false);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateProdOrderLine(ProdOrderLine[i], ProductionOrder, Item[i]."No.");
        end;
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Receipt Date Filter", ProdOrderLine[2]."Due Date");
        WarehouseSourceFilter.SetFilter("Prod. Order No.", ProductionOrder."No.");
        WarehouseSourceFilter.SetRange("Prod. Order Line No. Filter", FORMAT(ProdOrderLine[2]."Line No."));

        Commit();
        ProductionOrder.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Prod. Order Line", ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInvtPutawayRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPutawayForNegativeProdOrderCompWithAdditionalFilters()
    var
        Location: Record Location;
        Item: array[3] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReceiptDate: array[3] of Date;
        i: Integer;
    begin
        // [FEATURE] [Inventory Put-away] [Partial] [Prod. Order Component]
        // [SCENARIO 315268] Partial creation of inventory put-away for negative prod. order component.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, false, false);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."Source No.", Location.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            ReceiptDate[i] := WorkDate() + 30 * i;
            CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item[i]."No.", -LibraryRandom.RandInt(10), ReceiptDate[i]);
        end;
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Receipt Date Filter", ReceiptDate[2]);
        WarehouseSourceFilter.SetFilter("Prod. Order No.", ProductionOrder."No.");
        WarehouseSourceFilter.SetRange("Prod. Order Line No. Filter", FORMAT(ProdOrderLine."Line No."));

        Commit();
        ProductionOrder.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Prod. Order Component", ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInvtPickRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPickForSalesOrderWithAdditionalFilters()
    var
        Location: Record Location;
        Item: array[3] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ShipmentDate: array[3] of Date;
        i: Integer;
    begin
        // [FEATURE] [Inventory Pick] [Partial] [Sales Order]
        // [SCENARIO 315268] Partial creation of inventory pick for sales order.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        LibrarySales.CreateSalesOrderWithLocation(SalesHeader, '', Location.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateAndPostItemJournalLine(
              ItemJournalLine, Item[i]."No.", Location.Code, '', ItemJournalLine."Entry Type"::"Positive Adjmt.",
              LibraryRandom.RandIntInRange(20, 40));
            ShipmentDate[i] := WorkDate() + 30 * i;
            CreateSalesLine(SalesLine, SalesHeader, Item[i]."No.", ShipmentDate[i]);
        end;
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Shipment Date Filter", ShipmentDate[2]);

        Commit();
        SalesHeader.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    procedure WarehouseRequestsForProductionOrder()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        WarehouseRequest: Record "Warehouse Request";
    begin
        // [FEATURE] [Inventory Pick] [Warehouse Request] [Production Order]
        Initialize();

        // [GIVEN] Item with production BOM
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Validate("Production BOM No.", LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, LibraryInventory.CreateItemNo(), LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10)));
        Item.Modify(true);

        // [GIVEN] Create location with picking and put-away enabled and manufacturing internal pick/put-away
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, false, false);

        // [GIVEN] Create production order for Item and Location
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [WHEN] refresh production order
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);

        // [THEN] Warehouse Request for Production Order created
        WarehouseRequest.SetRange("Source Type", Database::"Prod. Order Line", Database::"Prod. Order Component");
        WarehouseRequest.SetRange("Source No.", ProductionOrder."No.");
        Assert.AreEqual(2, WarehouseRequest.Count(), 'Warehouse Request for Production Order not created.');

        // [WHEN] delete production order
        ProductionOrder.Delete(true);

        // [THEN] Warehouse Request for Production Order deleted
        Assert.AreEqual(0, WarehouseRequest.Count(), 'Warehouse Request for Production Order not deleted.');
    end;

    [Test]
    procedure WhsePickRequestsForProductionOrder()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        // [FEATURE] [Inventory Pick] [Warehouse Request] [Production Order]
        Initialize();

        // [GIVEN] Item with production BOM
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Stock");
        Item.Validate("Production BOM No.", LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, LibraryInventory.CreateItemNo(), LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10)));
        Item.Modify(true);

        // [GIVEN] Create location with picking and put-away enabled and manufacturing pick/put-away
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);

        // [GIVEN] Create production order for Item and Location
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          Item."No.", LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);

        // [WHEN] refresh production order
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, true);

        // [THEN] Warehouse Request for Production Order created
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Production);
        WhsePickRequest.SetRange("Document No.", ProductionOrder."No.");
        Assert.AreEqual(1, WhsePickRequest.Count(), 'Warehouse Pick Request for Production Order not created.');

        // [WHEN] delete production order
        ProductionOrder.Delete(true);

        // [THEN] Warehouse Request for Production Order deleted
        Assert.AreEqual(0, WhsePickRequest.Count(), 'Warehouse Pick Request for Production Order not deleted.');
    end;

    [Test]
    [HandlerFunctions('CreateInvtPickRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPickForPurchaseReturnOrderWithAdditionalFilters()
    var
        Location: Record Location;
        Item: array[3] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ShipmentDate: array[3] of Date;
        i: Integer;
    begin
        // [FEATURE] [Inventory Pick] [Partial] [Purchase Return Order]
        // [SCENARIO 315268] Partial creation of inventory pick for purchase return order.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, false, true, false, false);

        LibraryPurchase.CreatePurchaseReturnOrderWithLocation(PurchaseHeader, '', Location.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateAndPostItemJournalLine(
              ItemJournalLine, Item[i]."No.", Location.Code, '', ItemJournalLine."Entry Type"::"Positive Adjmt.",
              LibraryRandom.RandIntInRange(20, 40));
            ShipmentDate[i] := WorkDate() + 30 * i;
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item[i]."No.", ShipmentDate[i]);
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Shipment Date Filter", ShipmentDate[2]);

        Commit();
        PurchaseHeader.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Purchase Line", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInvtPickRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPickForTransferShipmentWithAdditionalFilters()
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        Item: array[3] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ShipmentDate: array[3] of Date;
        i: Integer;
    begin
        //avs
        // [FEATURE] [Inventory Pick] [Partial] [Transfer Order]
        // [SCENARIO 315268] Partial creation of inventory pick for transfer order.
        Initialize();

        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        LocationFrom.Validate("Require Pick", true);
        LocationFrom.Modify(true);

        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateAndPostItemJournalLine(
              ItemJournalLine, Item[i]."No.", LocationFrom.Code, '', ItemJournalLine."Entry Type"::"Positive Adjmt.",
              LibraryRandom.RandIntInRange(20, 40));
            ShipmentDate[i] := WorkDate() + 30 * i;
            CreateTransferLine(TransferLine, TransferHeader, Item[i]."No.", ShipmentDate[i], ShipmentDate[i]);
        end;
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Shipment Date Filter", ShipmentDate[2]);

        Commit();
        TransferHeader.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Transfer Line", TransferHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInvtPickRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPickForProdOrderCompWithAdditionalFilters()
    var
        Location: Record Location;
        Item: array[3] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ShipmentDate: array[3] of Date;
        i: Integer;
    begin
        // [FEATURE] [Inventory Pick] [Partial] [Prod. Order Component]
        // [SCENARIO 315268] Partial creation of inventory pick for prod. order component.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, false, false);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."Source No.", Location.Code);
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateAndPostItemJournalLine(
              ItemJournalLine, Item[i]."No.", Location.Code, '', ItemJournalLine."Entry Type"::"Positive Adjmt.",
              LibraryRandom.RandIntInRange(20, 40));
            ShipmentDate[i] := WorkDate() + 30 * i;
            CreateProdOrderComponent(ProdOrderComponent, ProdOrderLine, Item[i]."No.", LibraryRandom.RandInt(10), ShipmentDate[i]);
        end;
        LibraryManufacturing.CreateInboundWhseReqFromProdOrder(ProductionOrder);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Shipment Date Filter", ShipmentDate[2]);
        WarehouseSourceFilter.SetRange("Prod. Order No.", ProductionOrder."No.");
        WarehouseSourceFilter.SetRange("Prod. Order Line No. Filter", FORMAT(ProdOrderLine."Line No."));

        Commit();
        ProductionOrder.CreateInvtPutAwayPick();

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Prod. Order Component", ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        Assert.RecordCount(WarehouseActivityLine, 1);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [HandlerFunctions('CreateInvtMvmtRequestPageHandler,DummyMessageHandler')]
    procedure InventoryPickForAssemblyLineWithAdditionalFilters()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: array[3] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ShipmentDate: array[3] of Date;
        DummyInt: Integer;
        i: Integer;
    begin
        // [FEATURE] [Inventory Pick] [Partial] [Assembly]
        // [SCENARIO 315268] Partial creation of inventory pick for assembly line.
        Initialize();

        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("To-Assembly Bin Code", Bin.Code);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, LibraryRandom.RandDateFromInRange(WorkDate(), 150, 200), LibraryInventory.CreateItemNo(), Location.Code,
          LibraryRandom.RandInt(10), '');
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            CreateAndPostItemJournalLine(
              ItemJournalLine, Item[i]."No.", Location.Code, Bin.Code, ItemJournalLine."Entry Type"::"Positive Adjmt.",
              LibraryRandom.RandIntInRange(20, 40));
            ShipmentDate[i] := WorkDate() + 30 * i;
            LibraryAssembly.CreateAssemblyLine(
              AssemblyHeader, AssemblyLine, AssemblyLine.Type::Item, Item[i]."No.", Item[i]."Base Unit of Measure", 1, 1, '');
            AssemblyLine.Validate("Due Date", ShipmentDate[i]);
            AssemblyLine.Modify(true);
        end;
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        WarehouseSourceFilter.SetFilter("Item No. Filter", '%1..%2', Item[1]."No.", Item[2]."No.");
        WarehouseSourceFilter.SetRange("Shipment Date Filter", ShipmentDate[2]);

        Commit();
        AssemblyHeader.CreateInvtMovement(false, false, false, DummyInt, DummyInt);

        FindWarehouseActivityLine(
          WarehouseActivityLine, DATABASE::"Assembly Line", AssemblyHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Movement");
        Assert.RecordCount(WarehouseActivityLine, 2);
        WarehouseActivityLine.TestField("Item No.", Item[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickQuantityBaseInBinContentsIsFilteredByUoM_WhenDirectedPutAwayAndPickIsEnabled()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        BinContents: TestPage "Bin Contents";
        QtyPerUoM: Decimal;
        InputQtyBaseUoM: Decimal;
        InputQtyOtherUoM: Decimal;
        OutputQtyBaseUoM: Decimal;
        OutputQtyOtherUoM: Decimal;
    begin
        // [FEATURE] [Warehouse Adjustment] [Sales Order] [Warehouse Shipment] [Warehouse Pick] [Warehouse Activity Line] [Bin Contents]
        // [SCENARIO 448078] Item is created and put on Inventory and Warehouse in two Units of Measure. Then Warehouse Pick is created with two lines for the same Item and the same Location Bin but with different Units of Measure.
        // [SCENARIO 448078] "Pick Quantity (Base)" in Bin Contents page is filtered by UOM of "Warehouse Active Line" when "Directed Put-Away and Pick" = true.
        Initialize();
        ResetWarehouseEmployeeDefaultLocation();

        QtyPerUoM := LibraryRandom.RandIntInRange(25, 30);
        InputQtyBaseUoM := LibraryRandom.RandIntInRange(16, 20);
        InputQtyOtherUoM := LibraryRandom.RandIntInRange(11, 15);
        OutputQtyBaseUoM := LibraryRandom.RandIntInRange(6, 10);
        OutputQtyOtherUoM := LibraryRandom.RandIntInRange(2, 5);

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create additional "Unit of Measure" for Item with "Qty. per Unit of Measure" = QtyPerUoM.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUoM);

        // [GIVEN] Create Location with "Directed Put-away and Pick".
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Assign Warehouse Emplooyee for Location.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Find Bin for stocking.
        FindBin(Bin, Location.Code, true);

        // [GIVEN] Create Positive Adjustment Warehouse Journal Line for Item in "Base Unit of Measure" for Quantity = InputQtyBaseUoM.
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, "Warehouse Journal Template Type"::Item, Bin."Location Code");
        CreateWarehouseJournalLine(WarehouseJournalLine, WarehouseJournalBatch, Bin, Item."No.", Item."Base Unit of Measure", InputQtyBaseUoM);

        // [GIVEN] Create Positive Adjustment Warehouse Journal Line for Item in additional "Unit of Measure" for Quantity = InputQtyOtherUoM.
        CreateWarehouseJournalLine(WarehouseJournalLine, WarehouseJournalBatch, Bin, Item."No.", ItemUnitOfMeasure.Code, InputQtyOtherUoM);

        // [GIVEN] Register Warehouse Journal.
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);

        // [GIVEN] Calculate and Post Warehouse Adjustment.
        LibraryWarehouse.PostWhseAdjustment(Item);

        // [GIVEN] Create Sales Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create Sales Order Line for Item in "Base Unit of Measure" for Quantity = OutputQtyBaseUoM.
        LibrarySales.CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::Item, Item."No.", OutputQtyBaseUoM);
        SalesLine[1].Validate("Location Code", Location.Code);
        SalesLine[1].Modify(true);

        // [GIVEN] Create Sales Order Line for Item in additional "Unit of Measure" for Quantity = OutputQtyOtherUoM.
        LibrarySales.CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item."No.", OutputQtyOtherUoM);
        SalesLine[2].Validate("Location Code", Location.Code);
        SalesLine[2].Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        SalesLine[2].Validate(Quantity, OutputQtyOtherUoM);
        SalesLine[2].Modify(true);

        // [GIVEN] Release Sales Order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create Warehouse Shipment for Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));

        // [GIVEN] Create Pick for Warehouse Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [WHEN] Open Bin Contents page and set Location Filter.
        BinContents.OpenView();
        BinContents.LocationCode.SetValue(Location.Code);

        // [THEN] Check Item/Bin quantites for "Base Unit of Measure".
        BinContents.GoToKey(Location.Code, Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContents."CalcQtyUOM".AssertEquals(InputQtyBaseUoM);
        BinContents."Quantity (Base)".AssertEquals(InputQtyBaseUoM);
        BinContents."Pick Quantity (Base)".AssertEquals(OutputQtyBaseUoM);

        // [THEN] Check Item/Bin quantites for additional "Unit of Measure".
        BinContents.GoToKey(Location.Code, Bin.Code, Item."No.", '', ItemUnitOfMeasure.Code);
        BinContents."CalcQtyUOM".AssertEquals(InputQtyOtherUoM);
        BinContents."Quantity (Base)".AssertEquals(InputQtyOtherUoM * QtyPerUoM);
        BinContents."Pick Quantity (Base)".AssertEquals(OutputQtyOtherUoM * QtyPerUoM);

        BinContents.Close();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesDequeuePageHandler,WhseItemTrackingLinesDequeuePageHandler,ConfirmHandlerTrue,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure InvntoryMovementRegisterfromShipBin()
    var
        Item: Record Item;
        Bin: array[2] of Record Bin;
        Location: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        RegisteredInvMovementHdr: Record "Registered Invt. Movement Hdr.";
        LotNo: Code[10];
        WsheActivityheaderNo: Code[20];
        Qty: Integer;
    begin
        // [SCENARIO 558944] When registering Inventory Movement with Lot Number from Ship bin error ""Lot No. xxx is not available on inventory or it has already been reserved for another document." should not occure.
        // Inventory Movement should be registered.
        Initialize();

        // [GIVEN] Create a Location with two Bins. And assign first Bin to "Shipment Bin Code" of the Location.
        CreateWshLoctionWithShipBin(Location, Bin);

        // [GIVEN] Create an Item with Lot.
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Set Qty and LotNo.
        Qty := LibraryRandom.RandInt(100);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Create a Positive Adjustment Item Journal in Location using Bin[1] and Quantity = Qty.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin[1].Code, Qty);

        // [GIVEN] Enqueue LotNo and Qty.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);

        // [GIVEN] Open the Item Tracking Lines page and assign the LotNo and Qty through "ItemTrackingLinesDequeuePageHandler".
        ItemJournalLine.OpenItemTrackingLines(false);

        // [GIVEN] Post the Item Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create a Movement Worksheet.
        CreateWhseWorksheetName(WhseWorksheetName, Location.code);
        CreateWhseWorksheetLineWithToBinCode(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, Item."No.", Location.Code,
          Qty, Bin[2].Code);

        // [GIVEN] Autofill the "Qty. to Handle".
        WhseWorksheetLine.AutofillQtyToHandle(WhseWorksheetLine);

        // [GIVEN] Enque the LotNo and Qty.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);

        // [GIVEN] Update the Quantity and "Lot No." in Wsh. Item Tracking Lines pages through the" WhseItemTrackingLinesDequeuePageHandler".
        WhseWorksheetLine.OpenItemTrackingLines();

        // [GIVEN] Create the Inventory Movement from Movement Worksheet.
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        // [GIVEN] Get the Warehouse Activity Header (Inventory Movement Header). 
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        WsheActivityheaderNo := WarehouseActivityHeader."No.";

        // [GIVEN] Autofill the "Qty. to Handle".
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [WHEN] Registering Inv. Movement.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Verify Inventory Movement is registered.
        RegisteredInvMovementHdr.SetRange("Invt. Movement No.", WsheActivityheaderNo);
        Assert.IsTrue(RegisteredInvMovementHdr.Count > 0, InventoryMovementIsNotRegisteredErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,ReservationPageHandler,PickSelectionPageHandlerSingleDoc,CreatePickPageHandlerForPerWhsDoc')]
    [Scope('OnPrem')]
    procedure NoErrorOfAvailabilityWhenCreatePickFromPickWorkSheetForProductionOrder()
    var
        Bin, Bin2, Bin3 : Record Bin;
        CompItem, ProdItem : Record Item;
        Location: Record Location;
        ProductionOrder: array[2] of Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        WarehouseEmployee: Record "Warehouse Employee";
        WareHouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [SCENARIO 575862] No availability error when creating pick from pick worksheet with location setup Bin mandatory and the item reserved on the related production order
        Initialize();

        // [GIVEN] Reset Warehouse Employee Default Location.
        ResetWarehouseEmployeeDefaultLocation();

        // [GIVEN] Create Location with WMS enabled Bin mandatory
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        // [GIVEN] Create Warehouse Employee for Location.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create Bins for Location.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, '', '');
        LibraryWarehouse.CreateBin(Bin2, Location.Code, Bin2.Code, '', '');
        LibraryWarehouse.CreateBin(Bin3, Location.Code, Bin3.Code, '', '');

        // [GIVEN] Set "Prod. Consump. Whse. Handling" = "Warehouse Pick (mandatory)" and assign Bins to "To-Production Bin Code" and "From-Production Bin Code".
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Validate("To-Production Bin Code", Bin.Code);
        Location.Validate("From-Production Bin Code", Bin2.Code);
        Location.Modify(true);

        // [GIVEN] Create Component Item with "Replenishment System" = "Purchase" and "Flushing Method" = "Manual".
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::Purchase);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::Manual);
        CompItem.Modify();

        // [GIVEN] Create Production BOM for Component Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Stock");
        ProdItem.Validate("Flushing Method", ProdItem."Flushing Method"::Manual);
        ProdItem.Validate("Production BOM No.", LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1));
        ProdItem.Modify();

        // [GIVEN] Create Inventory for Component Item.
        CreateInventory(CompItem, 3, Location.Code, Bin3.Code, 0);

        // [GIVEN] Create first Production Orders for Production Item of quantity 2
        LibraryManufacturing.CreateProductionOrder(
           ProductionOrder[1], ProductionOrder[1].Status::Released, ProductionOrder[1]."Source Type"::Item, ProdItem."No.", 2);
        ProductionOrder[1].Validate("Location Code", Location.Code);
        ProductionOrder[1].Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[1], false, true, true, true, false);

        // [GIVEN] Reserve Component Item on Production Order 1
        ReserveQuantityOnComponent(CompItem."No.", ProductionOrder[1]."No.");

        // [GIVEN] Create second Production Order for Production Item of quantity 1
        LibraryManufacturing.CreateProductionOrder(
           ProductionOrder[2], ProductionOrder[2].Status::Released, ProductionOrder[2]."Source Type"::Item, ProdItem."No.", 1);
        ProductionOrder[2].Validate("Location Code", Location.Code);
        ProductionOrder[2].Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[2], false, true, true, true, false);

        // [GIVEN] Reserve Component Item on Production Order 2
        ReserveQuantityOnComponent(CompItem."No.", ProductionOrder[2]."No.");

        // [WHEN] Create Pick Worksheet for Production Order Components.
        GetWarehouseDocumentFromPickWorksheet(ProductionOrder);

        // [THEN] Verify Warehouse Activity Header for Production Order Components.
        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WareHouseActivityHeader.FindSet();
        Assert.IsTrue(WareHouseActivityHeader.Count = 2, InventoryPickNotFoundErr);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler,ConfirmHandlerTrue,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure TestWarehousePickCreationForProductionOrder()
    var
        Bin, Bin2, Bin3 : Record Bin;
        CompItem, ProdItem : Record Item;
        Location: Record Location;
        ProductionOrder: array[2] of Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        WarehouseEmployee: Record "Warehouse Employee";
        Quantity: Integer;
    begin
        // [SCENARIO 580550] Warehouse pick is created for a production order,when enough items are available and some Quantity of this item is moved to a dedicated BIN
        Initialize();

        // [GIVEN] Reset Warehouse Employee Default Location.
        ResetWarehouseEmployeeDefaultLocation();

        // [GIVEN] Create Location with WMS enabled Bin mandatory
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);

        // [GIVEN] Set "Prod. Consump. Whse. Handling" = "Warehouse Pick (mandatory)" and assign Bins to "To-Production Bin Code" and "From-Production Bin Code".
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Validate("Default Bin Selection", Location."Default Bin Selection"::"Fixed Bin");
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee for Location.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create three Bins for Location.
        CreateBin(Location.Code, Bin, true);
        CreateBin(Location.Code, Bin2, false);
        CreateBin(Location.Code, Bin3, true);

        // [GIVEN] Create Component Item with "Replenishment System" = "Purchase" and "Flushing Method" = "Manual".
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create three Bin Content for Component Item.   
        CreateBinContent(Location.Code, Bin.Code, CompItem, true, true, true);
        CreateBinContent(Location.Code, Bin2.Code, CompItem, false, false, false);
        CreateBinContent(Location.Code, Bin3.Code, CompItem, false, false, true);

        // [GIVEN] Create Production BOM for Component Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Stock");
        ProdItem.Validate("Production BOM No.", LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1));
        ProdItem.Modify();

        // [GIVEN] Create Inventory for Component Item.
        Quantity := LibraryRandom.RandIntInRange(1000, 1000);
        CreateInventory(CompItem, Quantity, Location.Code, Bin2.Code, LibraryRandom.RandInt(100));

        // [GIVEN] Create two Production Orders for Production Item
        CreateMultipleReleasedProdOrderAndReserveQtyOnComp(ProductionOrder, Location.Code, ProdItem."No.", CompItem."No.", Quantity / 2);

        // [WHEN] Create Inventory movement for half of the quantity to dedicated bin
        CreateAndRegisterInventoryMovement(Location.Code, Bin2, Bin3, CompItem."No.", Quantity / 2);

        // [WHEN] Create Warehouse Pick for one of the Production Order
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder[2]);

        // [THEN] Verify Warehouse Pick Line
        VerifyWhseActivityLine(CompItem."No.", Location.Code, Quantity / 2);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ConsumptionDoesNotConsumeOtherReserveQuantity()
    var

        CompItem, CompItem2, ProdItem : Record Item;
        Location: Record Location;
        ProductionOrder: array[2] of Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderLine: Record "Prod. Order Line";
        Quantity: Decimal;
        ErrorMessage: Text;
    begin
        // [SCENARIO 581222] Insufficient quantity error when consuming reserved quantity on production order
        Initialize();

        // [GIVEN] Create Location with inventory posting setup.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Set random Quantity between 1 and 100.
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Create Component Item1 with "Replenishment System" = "Purchase" and "Flushing Method" = "Manual".
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::Purchase);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::Manual);
        CompItem.Modify();

        // [GIVEN] Create Component Item2 with "Replenishment System" = "Purchase" and "Flushing Method" = "Manual".
        LibraryInventory.CreateItem(CompItem2);
        CompItem2.Validate("Replenishment System", CompItem2."Replenishment System"::Purchase);
        CompItem2.Validate("Flushing Method", CompItem2."Flushing Method"::Manual);
        CompItem2.Validate("Base Unit of Measure", CompItem."Base Unit of Measure");
        CompItem2.Modify();

        // [GIVEN] Create Production BOM for Component Item1 and Item2.
        CreateAndCertifyProductionBOMOfTwoComponents(ProductionBOMHeader, CompItem."Base Unit of Measure", CompItem."No.", CompItem2."No.");

        // [GIVEN] Create Production BOM for Component Items.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Stock");
        ProdItem.Validate("Flushing Method", ProdItem."Flushing Method"::Manual);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify();

        // [GIVEN] Create Inventory for Component Items.
        CreateInventory(CompItem, Quantity, Location.Code, '', 0);
        CreateInventory(CompItem2, Quantity, Location.Code, '', 0);

        // [GIVEN] Create first Production Orders for Production Item of quantity = Total Inventory
        LibraryManufacturing.CreateProductionOrder(
           ProductionOrder[1], ProductionOrder[1].Status::Released, ProductionOrder[1]."Source Type"::Item, ProdItem."No.", Quantity);
        ProductionOrder[1].Validate("Location Code", Location.Code);
        ProductionOrder[1].Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[1], false, true, true, true, false);

        // [GIVEN] Reserve Component Item on Production Order one
        ReserveQuantityOnComponent(CompItem."No.", ProductionOrder[1]."No.");
        ReserveQuantityOnComponent(CompItem2."No.", ProductionOrder[1]."No.");

        // [GIVEN] Create second Production Order for Production Item of same quantity.
        LibraryManufacturing.CreateProductionOrder(
           ProductionOrder[2], ProductionOrder[2].Status::Released, ProductionOrder[2]."Source Type"::Item, ProdItem."No.", Quantity);
        ProductionOrder[2].Validate("Location Code", Location.Code);
        ProductionOrder[2].Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder[2], false, true, true, true, false);

        // [WHEN] Try to consume Component Item1 on Production Order 2
        ProdOrderLine.SetRange(Status, ProductionOrder[2].Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder[2]."No.");
        ProdOrderLine.FindFirst();
        asserterror LibraryManufacturing.POSTConsumption(ProdOrderLine, CompItem, Location.Code, '', Quantity, WorkDate(), CompItem."Unit Cost");
        ErrorMessage := GetLastErrorText();

        // [THEN] Verify Insufficient Quantity error.
        Assert.Equal(StrSubstNo(InsufficientQtyErr, CompItem."No."), ErrorMessage);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Miscellaneous II");
        LibraryVariableStorage.Clear();
        Clear(WarehouseSourceFilter);

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Miscellaneous II");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Miscellaneous II");
    end;

    local procedure AddInventoryForBOM(ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        // Update Production BOM Inventory.
        PostItemJournalLine(ItemNo, LibraryRandom.RandDec(100, 2) + 100, '');  // Adding 100 to take larger value.
        PostItemJournalLine(ItemNo2, LibraryRandom.RandDec(100, 2) + 100, '');  // Adding 100 to take larger value.
    end;

    local procedure AssignItemTrackingInMovementWksht(ItemNo: Code[20])
    var
        MovementWorksheet: TestPage "Movement Worksheet";
    begin
        MovementWorksheet.OpenEdit();
        MovementWorksheet.FILTER.SetFilter("Item No.", ItemNo);
        Commit();  // Commit required.
        MovementWorksheet.ItemTrackingLines.Invoke();
    end;

    local procedure AssignLotNoWithExpirationDate(var ItemJournalLine: Record "Item Journal Line"; ExpirationDate: Date): Code[20]
    var
        LotNo: Variant;
        TrackingOption: Option SelectEntries,SetValues,AssignLotNo;
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryVariableStorage.Dequeue(LotNo);
        UpdateExpirationDateOnReservEntry(ItemJournalLine, ExpirationDate);

        exit(LotNo);
    end;

    local procedure AutoReserveSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CalculateInventoryOnPhysInventoryJournal(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Item, Location, create and Post Purchase Order and Item Journal Line and Calculate Inventory on Physical Inventory Journal.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ");
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateAndPostItemJournalLine(
          ItemJournalLine, PurchaseLine."No.", Location.Code, '', ItemJournalLine."Entry Type"::"Negative Adjmt.",
          LibraryRandom.RandInt(10));  // Use Random for Quantity.
        RunCalculateInventoryReport(ItemJournalLine, PurchaseLine."No.");
    end;

    local procedure CalculateInventoryOnWhsePhysInventoryJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Post Warehouse Receipt and Calculate Inventory on Warehouse Physical Inventory Journal.
        CreateAndPostWarehouseReceiptFromPO(PurchaseLine);
        RegisterWarehouseActivity(
          DATABASE::"Purchase Line", PurchaseLine."Document No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CalculateWhseInventory(WarehouseJournalLine, PurchaseLine."No.", LocationCode);
    end;

    local procedure CalculateWhseInventory(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(
            WarehouseJournalBatch, WarehouseJournalTemplate.Type::"Physical Inventory", LocationCode);
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseCalculateInventory(WarehouseJournalLine, BinContent, WorkDate(), LibraryUtility.GenerateGUID(), false);  // False for Item not on Inventory.
    end;

    local procedure CalcRegenPlanAndCarryOutActionMsg(Item: Record Item; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));  // Dates based on WORKDATE.
        FindRequisitionLine(RequisitionLine, Item."No.", LocationCode);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CalcWhseAdjustmentAndPostItemJournalLine(ItemNo: Code[20])
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        Item.Get(ItemNo);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; No: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, No, 1);  // Use blank value for Version Code and 1 for Quantity per.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, CreateAndModifyTrackedItem(LibraryRandom.RandInt(10)), LocationCode);  // Random Integer Required.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure CreateAndPostWarehouseReceiptFromPO(PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndRefreshProductionOrder(ItemNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        exit(ProductionOrder."No.");
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        TrackingOption: Option SelectEntries,SetValues;
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, LocationCode);
        LibraryVariableStorage.Enqueue(TrackingOption::SetValues);  // Enqueue ItemTrackingPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesLine, LocationCode, ItemNo, Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSaleslOrderWithIT(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        TrackingOption: Option SelectEntries,SetValues,AssignLotNo;
    begin
        // Create Sales Order, Assign Item Tracking and Release.
        CreateSalesOrderWithShippingAdvice(SalesHeader, LocationCode, SalesHeader."Shipping Advice"::Partial, ItemNo, Quantity);
        FindSalesLine(SalesLine, SalesHeader);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue ItemTrackingPageHandler.
        SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; DocumentNo: Code[20]; LocationCode: Code[10])
    begin
        CreateWarehouseShipment(WarehouseShipmentHeader, DocumentNo, LocationCode);
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndModifyTrackedItem(NoOfDays: Integer): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode());
        Evaluate(Item."Expiration Calculation", '<' + Format(NoOfDays) + 'D>');
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(LocationCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateInventoryPickFromSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        LibraryVariableStorage.Enqueue(NoOfPicksCreatedMsg);
        SalesHeader.CreateInvtPutAwayPick();
    end;

    local procedure CreateInventoryPickFromPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryVariableStorage.Enqueue(NoOfPicksCreatedMsg);
        PurchaseHeader.CreateInvtPutAwayPick();
    end;

    local procedure CreateInventoryPickFromTransferHeader(var TransferHeader: Record "Transfer Header")
    begin
        LibraryVariableStorage.Enqueue(NoOfPicksCreatedMsg);
        TransferHeader.CreateInvtPutAwayPick();
    end;

    local procedure CreateInvPickAndPost(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRequest: Record "Warehouse Request";
    begin
        LibraryVariableStorage.Enqueue(InvPickCreatedMessage);
        LibraryWarehouse.CreateInvtPutPickMovement(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        FindWarehouseActivityNo(WarehouseActivityLine, DATABASE::"Sales Line", SalesHeader."No.", SalesHeader."Location Code");
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::"Invt. Pick", WarehouseActivityLine."No.");
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalLineWithBin(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCodeLotSpecific(ItemTrackingCode);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemTrackingCodeLotSpecific(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemTrackingWithExpirLot(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCodeLotSpecific(ItemTrackingCode);
        ItemTrackingCode.Validate("Use Expiration Dates", true);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", true);
        ItemTrackingCode.Modify(true);

        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithLotTracking(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", CreateItemTrackingWithExpirLot());
        Item.Validate("Lot Nos.", LibraryERM.CreateNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithRoutingAndBOM(): Code[20]
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        BOMNo: Code[20];
        ItemNo: array[2] of Code[20];
    begin
        CreateProdBOMSetup(ItemNo, BOMNo);
        CreateRoutingSetup(RoutingHeader, Item."Flushing Method");
        CreateManufacturingItem(
          Item, Item."Costing Method"::FIFO, RoutingHeader."No.", BOMNo, Item."Manufacturing Policy"::"Make-to-Order",
          Item."Reordering Policy", Item."Replenishment System"::"Prod. Order");
        AddInventoryForBOM(ItemNo[1], ItemNo[2]);
        exit(Item."No.");
    end;

    local procedure CreateLocation(var Location: Record Location; BinMandatory: Boolean; RequireShipment: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", BinMandatory);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Modify(true);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateFEFOLocation(var Location: Record Location; BinMandatory: Boolean)
    begin
        CreateLocation(Location, BinMandatory, false);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);
    end;

    local procedure CreateLocationWithMultipleBin(var Location: Record Location; var Bin: Record Bin; var Bin2: Record Bin)
    begin
        CreateLocation(Location, true, true);
        LibraryWarehouse.CreateBin(Bin, Location.Code,
          CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        LibraryWarehouse.CreateBin(Bin2, Location.Code,
          CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(10, 1));  // Random values used are important for test.
    end;

    local procedure CreateMovementFromWorksheet(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WarehouseSetup: Record "Warehouse Setup";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        MovementNo: Code[20];
    begin
        Commit();  // Commit required.
        WarehouseSetup.Get();
        MovementNo := FindNos(WarehouseSetup."Whse. Movement Nos.");
        LibraryVariableStorage.Enqueue(StrSubstNo(MovmntActivityCreatedMessage, MovementNo));  // Enqueue value for MessageHandler.
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Movement, MovementNo);
        LibraryVariableStorage.Enqueue(AutoFillQtyMessage);  // Enqueue value for MessageHandler.
    end;

    local procedure CreateManufacturingItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; RoutingNo: Code[20]; ProductionBOMNo: Code[20]; ManufacturingPolicy: Enum "Manufacturing Policy"; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System")
    begin
        // Random values used are not important for test.
        LibraryManufacturing.CreateItemManufacturing(
          Item, CostingMethod, LibraryRandom.RandDec(50, 2) + LibraryRandom.RandDec(10, 2), ReorderingPolicy,
          Item."Flushing Method", RoutingNo, ProductionBOMNo);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreatePhysInventoryJournalWithWMSLocation(var ItemJournalLine: Record "Item Journal Line"; PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]): Decimal
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Calculate Inventory on Warehouse Physical Inventory Journal and update Quantity.
        CalculateInventoryOnWhsePhysInventoryJournal(WarehouseJournalLine, PurchaseLine, LocationCode);
        FindAndUpdateWarehouseJournalLine(WarehouseJournalLine);

        // Register Warehouse Line and Calculate Warehouse Adjustment.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          false);  // false for Batch Job.
        Item.Get(WarehouseJournalLine."Item No.");
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // Calculate Inventory on Phys Inventory Journal.
        RunCalculateInventoryReport(ItemJournalLine, Item."No.");
        FindItemJournalLine(ItemJournalLine);
        exit(WarehouseJournalLine.Quantity);
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; DocumentNo: Code[20])
    begin
        CreateWarehouseShipment(WarehouseShipmentHeader, DocumentNo, LocationCode);
        LibraryVariableStorage.Enqueue(PickActivityMessage);  // Enqueue for Message Handler.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePickAndRegisterWhseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleaseSaleslOrderWithIT(SalesHeader, LocationCode, ItemNo, Quantity);
        CreatePick(WarehouseShipmentHeader, SalesHeader."Location Code", SalesHeader."No.");
        RegisterWarehouseActivity(DATABASE::"Sales Line", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreatePickFromPickWkshPage(LocationCode: Code[10])
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        PickWorksheet.OpenEdit();
        PickWorksheet.FILTER.SetFilter("Location Code", LocationCode);
        PickWorksheet.CreatePick.Invoke();
        PickWorksheet.OK().Invoke();
    end;

    local procedure CreateProdBOMSetup(var ItemNo: array[2] of Code[20]; var ProdBOMNo: Code[20])
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateManufacturingItem(
          Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Order", Item."Reordering Policy",
          Item."Replenishment System"::"Prod. Order");
        ItemNo[1] := Item."No.";
        CreateManufacturingItem(
          Item, Item."Costing Method"::FIFO, '', '', Item."Manufacturing Policy"::"Make-to-Stock", Item."Reordering Policy",
          Item."Replenishment System");
        ItemNo[2] := Item."No.";
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, ItemNo[1], ItemNo[2], 1); // Value important for Test.
        ProdBOMNo := ProductionBOMHeader."No.";
    end;

    local procedure CreateProductionItem(var ParentItem: Record Item)
    var
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Reordering Policy"::"Lot-for-Lot");
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Reordering Policy"::"Lot-for-Lot");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ParentItem."Base Unit of Measure", ChildItem."No.");
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(20));  // Use Random for Quantity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; ReceiptDate: Date)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Planned Receipt Date", ReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateTransferLine(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; ShipmentDate: Date; ReceiptDate: Date)
    begin
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, LibraryRandom.RandInt(10));
        TransferLine.Validate("Shipment Date", ShipmentDate);
        TransferLine.Validate("Receipt Date", ReceiptDate);
        TransferLine.Modify(true);
    end;

    local procedure CreateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", ItemNo, '', ProductionOrder."Location Code", LibraryRandom.RandInt(10));
    end;

    local procedure CreateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; QtyPer: Decimal; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Due Date", DueDate);
        ProdOrderComponent.Validate("Quantity per", QtyPer);
        ProdOrderComponent.Validate("Location Code", ProdOrderLine."Location Code");
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; No: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(LocationCode));
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, No, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()),
          Quantity);  // Use Random days to calculate Shipment Date.
    end;

    local procedure CreateSalesOrderUsingItemInventory(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        Item.Get(ItemNo);
        Item.CalcFields(Inventory);
        CreateSalesOrder(SalesLine, '', ItemNo, Item.Inventory);
        SalesHeader.Get(SalesLine."Document Type"::Order, SalesLine."Document No.");
    end;

    local procedure CreateSalesOrderWithShippingAdvice(var SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ShippingAdvice: Enum "Sales Header Shipping Advice"; No: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(LocationCode));
        SalesHeader.Validate("Shipping Advice", ShippingAdvice);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header"; FlushingMethod: Enum "Flushing Method")
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        CreateWorkCenter(WorkCenter, FlushingMethod);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; WorkCenterNo: Code[20])
    begin
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenterNo,
          CopyStr(
            LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"), 1,
            MaxStrLen(RoutingLine."Operation No.")),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));  // Random is used, values not important for test.
    end;

    local procedure CreateSalesOrderBreakInTwoLots(var SalesHeader: Record "Sales Header"; var LotNos: array[2] of Code[20]; LocationCode: Code[10]; BinCode: Code[20]; LotQty: Decimal; QtyToSell: Decimal)
    var
        Item: Record Item;
    begin
        CreateItemWithLotTracking(Item);
        LotNos[1] := PostItemJournalLineFEFO(Item."No.", LocationCode, BinCode, LotQty, CalcDate('<2D>', WorkDate()));
        LotNos[2] := PostItemJournalLineFEFO(Item."No.", LocationCode, BinCode, LotQty, CalcDate('<1D>', WorkDate()));
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", LocationCode, QtyToSell);
    end;

    local procedure CreateTransferOrderAndPick(var TransferLine: Record "Transfer Line"; BinCode: Code[20]; "Code": Code[10]; Code2: Code[10]; Code3: Code[10]; No: Code[20])
    var
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Code, Code2, Code3);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, No, LibraryRandom.RandDec(10, 2));  // Using Random value for Transfer Line Quantity.
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        WarehouseShipmentLine.SetRange("Source No.", TransferHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Bin Code", BinCode);
        WarehouseShipmentLine.Modify(true);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreateWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        // Use Random value for Quantity.
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
    end;

    local procedure CreateWarehouseJournalLineWithItemTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo,
          Quantity);

        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();
    end;

    local procedure CreateAndRegisterWhseJournalLine(PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; BinCode: Code[20])
    var
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        Bin.Get(LocationCode, BinCode);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, PurchaseLine."No.", PurchaseLine.Quantity / 2);  // For Single Lot.
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(WhseItemLineRegister);  // Enqueue value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(WhseItemLineRegistered);  // Enqueue value for MessageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationCode, false);
    end;

    local procedure CreateWarehouseLocation(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        Location.Validate("Require Receive", true);
        Location.Validate("Always Create Pick Line", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateWhseReceiptAndRegister(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Purchase Order, Warehouse Receipt, Post and Register Put-away.
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, CreateAndModifyTrackedItem(LibraryRandom.RandInt(10)), LocationCode);   // Random Integer used for update Expiration Date.
        CreateAndPostWarehouseReceiptFromPO(PurchaseLine);
        RegisterWarehouseActivity(DATABASE::"Purchase Line", PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; DocumentNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentHeader(WarehouseShipmentHeader, LocationCode);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center"; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Modify(true);
    end;

    local procedure CreateWhseReceiptAndMovementWorksheetLine(var PurchaseLine: Record "Purchase Line")
    var
        Location: Record Location;
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        CreateWarehouseLocation(Location);
        CreateWhseReceiptAndRegister(PurchaseLine, Location.Code);
        CreateWhseWorksheetName(WhseWorksheetName, Location.Code);
        WhseWorksheetLine.DeleteAll();
        CreateWhseWorksheetLine(
          WhseWorksheetLine, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, PurchaseLine."No.", Location.Code,
          PurchaseLine.Quantity / 2);
        WhseWorksheetLine.AutofillQtyToHandle(WhseWorksheetLine);
    end;

    local procedure CreateWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WorksheetTemplateName: Code[10]; Name: Code[10]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WorksheetTemplateName, Name, LocationCode, WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet");
        WhseWorksheetLine.Validate("Item No.", ItemNo);
        WhseWorksheetLine.Validate("From Bin Code", FindBinContent(LocationCode, ItemNo));
        WhseWorksheetLine.Validate("To Bin Code", FindBin(LocationCode, true));
        WhseWorksheetLine.Validate(Quantity, Quantity);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure CreateWhseWorksheetName(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Movement);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
    end;

    local procedure DeleteProdOrderLine(ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindLast();
        ProdOrderLine.Delete(true);
    end;

    local procedure FindAndUpdateItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        FindItemJournalLine(ItemJournalLine);
        ItemJournalLine.Validate(
          "Qty. (Phys. Inventory)", ItemJournalLine."Qty. (Phys. Inventory)" + LibraryRandom.RandDec(10, 2));  // Use Random for updating Quantity(Phys. Inventory).
        ItemJournalLine.Modify(true);
    end;

    local procedure FindAndUpdateWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalLine."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalLine."Journal Batch Name");
        WarehouseJournalLine.SetRange("Location Code", WarehouseJournalLine."Location Code");
        WarehouseJournalLine.FindFirst();
        WarehouseJournalLine.Validate(
          "Qty. (Phys. Inventory)", WarehouseJournalLine."Qty. (Phys. Inventory)" + LibraryRandom.RandDec(10, 2));  // Use Random for Quantity.
        WarehouseJournalLine.Modify(true);
    end;

    local procedure FindBin(LocationCode: Code[10]; Ship: Boolean): Code[20]
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Bin Type Code", FindBinType(Ship));
        Bin.FindFirst();
        exit(Bin.Code);
    end;

    local procedure FindBinContent(LocationCode: Code[10]; ItemNo: Code[20]): Code[10]
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        exit(BinContent."Bin Code");
    end;

    local procedure FindBinType(Ship: Boolean): Code[10]
    var
        BinType: Record "Bin Type";
    begin
        BinType.SetRange(Ship, Ship);
        BinType.FindFirst();
        exit(BinType.Code);
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.FindFirst();
    end;

    local procedure FindNos(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    local procedure FindProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.SetRange("Location Code", LocationCode);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
    end;

    local procedure FindPostedWarehouseReceiptNo(LocationCode: Code[10]): Code[20]
    var
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
    begin
        PostedWhseReceiptHeader.SetRange("Location Code", LocationCode);
        PostedWhseReceiptHeader.FindFirst();
        exit(PostedWhseReceiptHeader."No.");
    end;

    local procedure FindPostedWareHouseShipmentNo(WarehouseShipmentNo: Code[20]): Code[20]
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", WarehouseShipmentNo);
        PostedWhseShipmentHeader.FindFirst();
        exit(PostedWhseShipmentHeader."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindLast();  // Using Findlast to take value from last line of Activity Type.
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document")
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
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

    local procedure GenerateRandomLotQuantities(var LotQty: Decimal; var QtyToSell: Decimal)
    begin
        Initialize();

        LotQty := LibraryRandom.RandIntInRange(50, 100);
        QtyToSell := LotQty + LibraryRandom.RandIntInRange(20, 40);
    end;

    local procedure GetWarehouseDocumentFromPickWorksheet(WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        LibraryVariableStorage.Enqueue(WarehouseShipmentHeader."No.");  // Enqueue for PickSelectionPageHandler.
        LibraryVariableStorage.Enqueue(WarehouseShipmentHeader."Location Code");  // Enqueue PickSelectionPageHandler.
        PickWorksheet.OpenEdit();
        PickWorksheet."Get Warehouse Documents".Invoke();
        PickWorksheet.OK().Invoke();
    end;

    local procedure OpenPhysInventoryJournalToUpdateQuantity(JournalBatchName: Code[10])
    var
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
    begin
        Commit();  // Commit required.
        PhysInventoryJournal.OpenEdit();
        PhysInventoryJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        PhysInventoryJournal."Qty. (Phys. Inventory)".SetValue(LibraryRandom.RandDec(10, 2));  // Use Random to update Quantity.
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, LocationCode);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostItemJournalLineFEFO(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; ExpirationDate: Date): Code[20]
    var
        ItemJournalLine: Record "Item Journal Line";
        LotNo: Code[50];
    begin
        CreateItemJournalLineWithBin(ItemJournalLine, ItemNo, Quantity, LocationCode, BinCode);
        LotNo := AssignLotNoWithExpirationDate(ItemJournalLine, ExpirationDate);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        exit(LotNo);
    end;

    local procedure RegisterWarehouseActivity(SourceType: Integer; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceType, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RunCalculateInventoryReport(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::"Phys. Inventory");
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), true, false);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, Type);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetupForCreatePickFromPickWorksheet(var SalesHeader: Record "Sales Header"): Code[20]
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseSetup: Record "Warehouse Setup";
    begin
        SetupForWarehousePickPutAway(SalesHeader);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader."No.", SalesHeader."Location Code");

        // Create Pick Worksheet Line through Get Warehouse Document Action.
        GetWarehouseDocumentFromPickWorksheet(WarehouseShipmentHeader);
        Commit();  // Commit required.
        WarehouseSetup.Get();
        LibraryVariableStorage.Enqueue(StrSubstNo(PickActivityMessage, FindNos(WarehouseSetup."Whse. Pick Nos.")));  // Enqueue for Message Handler.
        exit(WarehouseShipmentHeader."No.");
    end;

    local procedure SetupForCreatePickOnSalesDocument(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ShippingAdvice: Enum "Sales Header Shipping Advice"; NoOfLines: Integer)
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        "Count": Integer;
        Quantity: Decimal;
    begin
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::" ");
        Quantity := LibraryRandom.RandInt(2);  // Use Random to update Quantity.

        // Post Item Journal and Creation of Released Sales Orders.
        PostItemJournalLine(Item."No.", LibraryRandom.RandInt(10), LocationCode);
        CreateSalesOrderWithShippingAdvice(SalesHeader, LocationCode, ShippingAdvice, Item."No.", Quantity);
        for Count := 2 to NoOfLines do begin
            CreateItem(Item2, Item2."Replenishment System"::Purchase, Item2."Reordering Policy"::" ");
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item2."No.", Quantity);
        end;

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader);
    end;

    local procedure SetupForPlanningWorksheet(var SalesLine: Record "Sales Line")
    var
        Bin: Record Bin;
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Create Production Item. Create and register Warehouse Journal Line. Create and post Item journal Line for child Item after Calculating Whse. Adjustment. Create Sales Order.
        // Enqueue value for message handler.
        LibraryVariableStorage.Enqueue(WhseItemLineRegister);
        LibraryVariableStorage.Enqueue(WhseItemLineRegistered);

        WhiteLocationSetup(Bin);
        CreateProductionItem(Item);
        FindProductionBOMLine(ProductionBOMLine, Item."Production BOM No.");
        UpdateInventoryFromWarehouseJournal(WarehouseJournalLine, Bin, ProductionBOMLine."No.");

        CreateSalesOrder(SalesLine, Bin."Location Code", Item."No.", WarehouseJournalLine.Quantity - 1);  // Take less Quantity for Sales Order.
    end;

    local procedure SetupForWarehousePickPutAway(var SalesHeader: Record "Sales Header")
    var
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        CreateWarehouseLocation(Location);
        CreateWhseReceiptAndRegister(PurchaseLine, Location.Code);
        CreateAndReleaseSaleslOrderWithIT(SalesHeader, Location.Code, PurchaseLine."No.", PurchaseLine.Quantity);
    end;

    local procedure UpdateExpirationDateOnReservEntry(ItemJournalLine: Record "Item Journal Line"; ExpirationDate: Date)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        ReservEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
        ReservEntry.SetRange("Source ID", ItemJournalLine."Journal Template Name");
        ReservEntry.SetRange("Source Batch Name", ItemJournalLine."Journal Batch Name");
        ReservEntry.SetRange("Source Ref. No.", ItemJournalLine."Line No.");
        ReservEntry.FindFirst();
        ReservEntry.Validate("Expiration Date", ExpirationDate);
        ReservEntry.Modify(true);
    end;

    local procedure UpdateInventoryFromWarehouseJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; ItemNo: Code[20])
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, ItemNo, 1 + LibraryRandom.RandInt(10));  // Used Random Integer Value, should be more than 1.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          false);  // false for Batch Job.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateSalesReceivableSetup(CreditWarnings: Option; StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure WhiteLocationSetup(var Bin: Record Bin)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);  // Use 1 for No. of Bins per Zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, FindPickZone(Location.Code), 1);  // 1 is for Bin Index.
    end;

    local procedure CreateItemInventoryAtLocation(var ItemNo: Code[20]; var LocationCode: Code[10]; var Quantity: Decimal; BinMandatory: Boolean; RequireShipment: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
    begin
        CreateLocation(Location, BinMandatory, RequireShipment);
        LocationCode := Location.Code;
        ItemNo := LibraryInventory.CreateItemNo();
        Quantity := LibraryRandom.RandIntInRange(3, 10);
        CreateItemJournalLineWithBin(ItemJournalLine, ItemNo, Quantity, LocationCode, '');
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateReleasedItemSalesOrderFromLocation(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        CreateItemInventoryAtLocation(ItemNo, LocationCode, Quantity, false, false);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), ItemNo,
          Quantity, LocationCode, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateReleasedItemPurchaseReturnOrderFromLocation(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        CreateItemInventoryAtLocation(ItemNo, LocationCode, Quantity, false, false);
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo(), ItemNo,
          Quantity, LocationCode, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateReleasedItemTransferOrderFromLocationToSomeNewLocation(var TransferHeader: Record "Transfer Header")
    var
        ToLocation: Record Location;
        TransitLocation: Record Location;
        TransferRoute: Record "Transfer Route";
        TransferLine: Record "Transfer Line";
        ItemNo: Code[20];
        FromLocationCode: Code[10];
        Quantity: Decimal;
    begin
        CreateItemInventoryAtLocation(ItemNo, FromLocationCode, Quantity, false, false);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryInventory.CreateTransferRoute(TransferRoute, FromLocationCode, ToLocation.Code);
        TransferRoute.Validate("In-Transit Code", TransitLocation.Code);
        TransferRoute.Modify(true);

        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocation.Code, TransitLocation.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateReleasedAssemblyOrder(var AssemblyHeader: Record "Assembly Header")
    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        Location: Record Location;
        BinCodes: array[2] of Code[20];
    begin
        CreateLocation(Location, true, false);
        Location."Asm. Consump. Whse. Handling" := Enum::"Asm. Consump. Whse. Handling"::"Inventory Movement";
        Location.Modify(true);
        SetupBinsForLocation(Location.Code, BinCodes);
        SetupToAssemblyBin(Location.Code, BinCodes[2]);

        LibrarySales.SetStockoutWarning(false);
        LibraryAssembly.CreateAssemblyOrder(AssemblyHeader, WorkDate(), Location.Code, LibraryRandom.RandIntInRange(1, 3));
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, AssemblyHeader."Location Code", BinCodes[1]);
        LibraryAssembly.PrepareOrderPosting(AssemblyHeader, TempAssemblyLine, 100, 100, true, WorkDate());
        CODEUNIT.Run(CODEUNIT::"Release Assembly Document", AssemblyHeader);
    end;

    local procedure SetupBinsForLocation(LocationCode: Code[10]; var BinCodes: array[2] of Code[20])
    var
        Bin: Record Bin;
        Counter: Integer;
    begin
        for Counter := 1 to ArrayLen(BinCodes) do begin
            BinCodes[Counter] := LibraryUtility.GenerateGUID();
            LibraryWarehouse.CreateBin(Bin, LocationCode, BinCodes[Counter], '', '');
        end;
    end;

    local procedure SetupToAssemblyBin(LocationCode: Code[10]; BinCode: Code[20])
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location.Validate("To-Assembly Bin Code", BinCode);
        Location.Modify(true);
    end;

    local procedure VerifyItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPhysInventoryLedger(ItemJournalLine: Record "Item Journal Line")
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        PhysInventoryLedgerEntry.SetRange("Document No.", ItemJournalLine."Document No.");
        PhysInventoryLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        PhysInventoryLedgerEntry.FindFirst();
        PhysInventoryLedgerEntry.TestField(Quantity, ItemJournalLine.Quantity);
    end;

    local procedure VerifyRequisitionLine(No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ActionMessage: Enum "Action Message Type"; AcceptActionMessage: Boolean; RefOrderStatus: Enum "Requisition Ref. Order Type")
    var
        RequisitionLine: Record "Requisition Line";
    begin
        FindRequisitionLine(RequisitionLine, No, LocationCode);
        RequisitionLine.TestField("Action Message", ActionMessage);
        RequisitionLine.TestField("Accept Action Message", AcceptActionMessage);
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        RequisitionLine.TestField("Ref. Order Status", RefOrderStatus);
        RequisitionLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReserveQuantity(ItemNo: Code[20]; DocumentNo: Code[20]; LocationCode: Code[10]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Posting Date", WorkDate());
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Reserved Quantity");
        ItemLedgerEntry.TestField("Reserved Quantity", Quantity);
    end;

    local procedure VerifyProdComponentUnitCost(Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; UnitCost: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ComponentCost: Decimal;
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindSet();
        repeat
            ComponentCost += ProdOrderComponent."Unit Cost";
        until ProdOrderComponent.Next() = 0;
        Assert.AreNearlyEqual(UnitCost, ComponentCost, LibraryERM.GetAmountRoundingPrecision(), CostMustBeSame);
    end;

    local procedure VerifyUnitCostOnItemAfterAdjustment(ProdOrderNo: Code[20]; ItemNo: Code[20])
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        TotalCost: Decimal;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", ProdOrderNo);
        ItemLedgerEntry.FindSet();
        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            TotalQuantity += ItemLedgerEntry.Quantity;
            TotalCost += ItemLedgerEntry."Cost Amount (Actual)";
        until ItemLedgerEntry.Next() = 0;

        Item.Get(ItemNo);
        Assert.AreNearlyEqual(Item."Unit Cost", TotalCost / TotalQuantity, LibraryERM.GetAmountRoundingPrecision(), CostMustBeSame);
    end;

    local procedure VerifyWarehouseEntries(ItemNo: Code[20]; LocationCode: Code[10]; WhseDocumentNo: Code[20]; Quantity: Decimal; EntryType: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Whse. Document No.", WhseDocumentNo);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, Quantity);
        WarehouseEntry.TestField("Qty. (Base)", Quantity);
    end;

    local procedure VerifyWhseActivityLine(SalesLine: Record "Sales Line"; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, DATABASE::"Sales Line", SalesLine."Document No.", SalesLine."Location Code");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Item No.", SalesLine."No.");
        WarehouseActivityLine.TestField(Quantity, Quantity);
        WarehouseActivityLine.TestField("Qty. to Handle", Quantity);
    end;

    local procedure VerifyWhseActivityLineWithLotNo(WarehouseActivityLine: Record "Warehouse Activity Line"; Quantity: Decimal; LotNo: Code[50])
    begin
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.SetRange(Quantity, Quantity);
        Assert.RecordCount(WarehouseActivityLine, 2);
    end;

    local procedure ResetWarehouseEmployeeDefaultLocation()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange("User ID", UserId());
        WarehouseEmployee.SetRange(Default, true);
        WarehouseEmployee.ModifyAll(Default, false);
    end;

    local procedure CreateWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch"; Bin: Record Bin; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; NewQuantity: Decimal)
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, NewQuantity);

        if WarehouseJournalLine."Unit of Measure Code" <> UnitOfMeasureCode then begin
            WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
            WarehouseJournalLine.Validate(Quantity, NewQuantity);
            WarehouseJournalLine.Modify(true);
        end;
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10]; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, Pick));
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 1);  // Use 1 for Bin Index.
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure CreateReleasedItemServiceOrderFromLocation(var ServiceHeader: Record "Service Header") LocationCode: Code[10];
    var
        ItemNo: Code[20];
        Quantity: Decimal;
        ServiceItemLineNo: Integer;
    begin
        CreateItemInventoryAtLocation(ItemNo, LocationCode, Quantity, false, true);
        ServiceItemLineNo := CreateServiceOrder(ServiceHeader);
        AddItemServiceLinesToOrder(ServiceHeader, ServiceItemLineNo, ItemNo, Quantity, LocationCode);
        LibraryService.ReleaseServiceDocument(ServiceHeader);
    end;

    local procedure AddItemServiceLinesToOrder(var ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer; ItemNo: Code[20]; ItemQuantity: Integer; LocationCode: Code[10]): Integer
    var
        ServiceLine: Record "Service Line";
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        UpdateServiceLine(ServiceLine, ServiceItemLineNo, ItemQuantity);
        ServiceLine.SetHideReplacementDialog(true);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify();
        exit(ServiceLine."Line No.");
    end;

    local procedure UpdateServiceLine(var ServiceLine: Record "Service Line"; ServiceItemLineNo: Integer; ItemQuantity: Integer)
    begin
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, ItemQuantity);  // Use Random to select Random Quantity.
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"): Integer
    var
        Customer: Record Customer;
        ServiceItemLine: Record "Service Item Line";
        ServiceItem: Record "Service Item";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        UpdateAccountsInCustPostingGroup(ServiceItem."Customer No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        exit(ServiceItemLine."Line No.");
    end;

    local procedure UpdateAccountsInCustPostingGroup(CustNo: Code[20])
    var
        Customer: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustNo);
        CustPostingGroup.Get(Customer."Customer Posting Group");
        if CustPostingGroup."Payment Disc. Debit Acc." = '' then
            CustPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo());
        if CustPostingGroup."Payment Disc. Credit Acc." = '' then
            CustPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo());
        CustPostingGroup.Modify(true);
    end;

    local procedure FindWhseShipmentHeader(
        var WhseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; SourceDocType: Enum "Warehouse Activity Source Document";
        SourceDocNo: Code[20])
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WhseShipmentLine.SetRange("Location Code", LocationCode);
        WhseShipmentLine.SetRange("Source Document", SourceDocType);
        WhseShipmentLine.SetRange("Source No.", SourceDocNo);
        WhseShipmentLine.FindFirst();
        WhseShipmentHeader.Get(WhseShipmentLine."No.");
    end;

    local procedure CreateWshLoctionWithShipBin(var Location: Record Location; var Bin: array[2] of Record Bin)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.validate("Shipment Bin Code", Bin[1].Code);
        Location.Modify(true);
    end;

    local procedure CreateWhseWorksheetLineWithToBinCode(
        var WhseWorksheetLine: Record "Whse. Worksheet Line";
        WorksheetTemplateName: Code[10];
        Name: Code[10];
        ItemNo: Code[20];
        LocationCode: Code[10];
        Quantity: Decimal;
        ToBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseWorksheetLine(
          WhseWorksheetLine, WorksheetTemplateName, Name, LocationCode, WhseWorksheetLine."Whse. Document Type"::"Whse. Mov.-Worksheet");
        WhseWorksheetLine.Validate("Item No.", ItemNo);
        WhseWorksheetLine.Validate("From Bin Code", FindBinContent(LocationCode, ItemNo));
        WhseWorksheetLine.Validate("To Bin Code", ToBinCode);
        WhseWorksheetLine.Validate(Quantity, Quantity);
        WhseWorksheetLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateOrderFromSalesPageHandler(var CreateOrderFromSales: Page "Create Order From Sales"; var Response: Action)
    begin
        Response := ACTION::Yes;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateWhseMovementPageHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickPageHandler(var CreatePick: TestRequestPage "Create Pick")
    begin
        CreatePick.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionValue: Variant;
        TrackingQuantity: Decimal;
        TrackingOption: Option;
        OptionString: Option SelectEntries,SetValues,AssignLotNo;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            OptionString::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            OptionString::SetValues:
                begin
                    TrackingQuantity := ItemTrackingLines.Quantity3.AsDecimal();
                    ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity / 2);  // Using half value to assign the Quantity equally in both the ITem Tracking Line.
                    ItemTrackingLines.Next();
                    ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity / 2);  // Using half value to assign the Quantity equally in both the ITem Tracking Line.
                end;
            OptionString::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandler(var PickSelection: TestPage "Pick Selection")
    var
        DocumentNo: Variant;
        LocationCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);  // Dequeue Variable.
        LibraryVariableStorage.Dequeue(LocationCode);  // Dequeue Variable.
        PickSelection."Document No.".AssertEquals(DocumentNo);
        PickSelection."Location Code".AssertEquals(LocationCode);
        PickSelection.OK().Invoke();
    end;

    local procedure UpdateSalesOrderQuantity(SalesOrderNo: Code[20]; NewQuantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesOrderNo);
        SalesLine.FindFirst();
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".AssistEdit();
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesDequeuePageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickReportHandler(var CreatePickReqPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreatePickReqPage.CInvtPick.SetValue(true);
        CreatePickReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePutawayReportHandler(var CreatePickReqPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreatePickReqPage.CreateInventorytPutAway.SetValue(true);
        CreatePickReqPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPutawayRequestPageHandler(var CreateInvtPutawayPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPutawayPage.CreateInventorytPutAway.SetValue(true);
        CreateInvtPutawayPage."Warehouse Source Filter".SetFilter(
          "Item No. Filter", WarehouseSourceFilter.GetFilter("Item No. Filter"));
        CreateInvtPutawayPage."Warehouse Source Filter".SetFilter(
          "Receipt Date Filter", WarehouseSourceFilter.GetFilter("Receipt Date Filter"));
        CreateInvtPutawayPage."Warehouse Source Filter".SetFilter(
          "Prod. Order No.", WarehouseSourceFilter.GetFilter("Prod. Order No."));
        CreateInvtPutawayPage."Warehouse Source Filter".SetFilter(
          "Prod. Order Line No. Filter", WarehouseSourceFilter.GetFilter("Prod. Order Line No. Filter"));
        CreateInvtPutawayPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtPickRequestPageHandler(var CreateInvtPickPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtPickPage.CInvtPick.SetValue(true);
        CreateInvtPickPage."Warehouse Source Filter".SetFilter(
          "Item No. Filter", WarehouseSourceFilter.GetFilter("Item No. Filter"));
        CreateInvtPickPage."Warehouse Source Filter".SetFilter(
          "Shipment Date Filter", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        CreateInvtPickPage."Warehouse Source Filter".SetFilter(
          "Prod. Order No.", WarehouseSourceFilter.GetFilter("Prod. Order No."));
        CreateInvtPickPage."Warehouse Source Filter".SetFilter(
          "Prod. Order Line No. Filter", WarehouseSourceFilter.GetFilter("Prod. Order Line No. Filter"));
        CreateInvtPickPage."Warehouse Source Filter".SetFilter("Job No.", WarehouseSourceFilter.GetFilter("Job No."));
        CreateInvtPickPage."Warehouse Source Filter".SetFilter(
          "Job Task No. Filter", WarehouseSourceFilter.GetFilter("Job Task No. Filter"));
        CreateInvtPickPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CreateInvtMvmtRequestPageHandler(var CreateInvtMvmtPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreateInvtMvmtPage.CInvtPick.SetValue(false);
        CreateInvtMvmtPage.CInvtMvmt.SetValue(true);
        CreateInvtMvmtPage."Warehouse Source Filter".SetFilter(
          "Item No. Filter", WarehouseSourceFilter.GetFilter("Item No. Filter"));
        CreateInvtMvmtPage."Warehouse Source Filter".SetFilter(
          "Shipment Date Filter", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        CreateInvtMvmtPage.OK().Invoke();
    end;

    local procedure VerifyInventoryPickLine(SalesOrderNo: Code[20]; LotNo: Code[50]; PickQty: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesOrderNo);
        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Pick");
        WhseActivityLine.SetRange("Source Type", DATABASE::"Sales Line");
        WhseActivityLine.SetRange("Source Subtype", WhseActivityLine."Source Subtype"::"1");
        WhseActivityLine.SetRange("Source No.", SalesOrderNo);
        WhseActivityLine.SetRange("Lot No.", LotNo);
        WhseActivityLine.SetRange("Destination Type", WhseActivityLine."Destination Type"::Customer);
        WhseActivityLine.SetRange("Destination No.", SalesHeader."Sell-to Customer No.");
        WhseActivityLine.FindFirst();

        Assert.AreEqual(WhseActivityLine.Quantity, PickQty, '');
    end;

    local procedure VerifyInventoryPickLines(SalesOrderNo: Code[20]; LotNos: array[2] of Code[20]; Lot1Qty: Decimal; Lot2Qty: Decimal)
    begin
        VerifyInventoryPickLine(SalesOrderNo, LotNos[1], Lot1Qty);
        VerifyInventoryPickLine(SalesOrderNo, LotNos[2], Lot2Qty);
    end;

    local procedure GetWarehouseDocumentFromPickWorksheet(ProductionOrder: array[2] of Record "Production Order")
    var
        PickWorksheet: TestPage "Pick Worksheet";
    begin
        LibraryVariableStorage.Enqueue(ProductionOrder[1]."No.");  // Enqueue for PickSelectionPageHandler.
        LibraryVariableStorage.Enqueue(ProductionOrder[1]."Location Code");  // Enqueue PickSelectionPageHandler.
        PickWorksheet.OpenEdit();
        PickWorksheet."Get Warehouse Documents".Invoke();

        LibraryVariableStorage.Enqueue(ProductionOrder[2]."No.");  // Enqueue for PickSelectionPageHandler.
        LibraryVariableStorage.Enqueue(ProductionOrder[2]."Location Code");  // Enqueue PickSelectionPageHandler.
        PickWorksheet."Get Warehouse Documents".Invoke();
        Commit();

        PickWorksheet.CreatePick.Invoke();
        PickWorksheet.OK().Invoke();
    end;

    local procedure ReserveQuantityOnComponent(ItemNo: code[20]; ProdOrderno: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenEdit();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        ProdOrderComponents.FILTER.SetFilter("Prod. Order No.", ProdOrderno);
        ProdOrderComponents.Reserve.Invoke();
        ProdOrderComponents.Close();
    end;

    local procedure CreateInventory(Item: Record Item; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20]; UnitAmount: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);

        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, Item, LocationCode, '', WorkDate(),
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, UnitAmount);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify();

        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateBin(LocationCode: Code[10]; var Bin: Record Bin; Dedicated: Boolean)
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, Bin.Code, '', '');

        if Dedicated then begin
            Bin.Validate("Dedicated", Dedicated);
            Bin.Modify(true);
        end;
    end;

    local procedure CreateBinContent(LocationCode: Code[10]; BinCode: Code[20]; var Item: Record "Item"; Fixed: Boolean; Default: Boolean; Dedicated: Boolean)
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Fixed, Fixed);
        BinContent.Validate(Default, Default);
        BinContent.Validate(Dedicated, Dedicated);
        BinContent.Modify(true);
    end;

    local procedure CreateMultipleReleasedProdOrderAndReserveQtyonComp(var ProductionOrder: array[2] of Record "Production Order"; LocationCode: Code[10]; ProdItemNo: Code[20]; CompItemNo: Code[20]; Quantity: Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ProductionOrder) do begin
            LibraryManufacturing.CreateProductionOrder(
                ProductionOrder[i], ProductionOrder[i].Status::Released, ProductionOrder[i]."Source Type"::Item, ProdItemNo, Quantity);
            ProductionOrder[i].Validate("Location Code", LocationCode);
            ProductionOrder[i].Modify(true);
            LibraryManufacturing.RefreshProdOrder(ProductionOrder[i], false, true, true, true, false);

            ReserveQuantityOnComponent(CompItemNo, ProductionOrder[i]."No.");
        end;
    end;

    local procedure CreateAndRegisterInventoryMovement(LocationCode: Code[10]; FromBin: Record Bin; ToBin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, FromBin, ToBin, ItemNo, '', Quantity);
        WhseWorksheetLine.MovementCreate(WhseWorksheetLine);

        WhseActivityLine.SetRange("Activity Type", WhseActivityLine."Activity Type"::"Invt. Movement");
        WhseActivityLine.SetRange("Item No.", ItemNo);
        WhseActivityLine.SetRange("Location Code", LocationCode);
        WhseActivityLine.FindSet();

        WhseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        WhseActivityLine.AutofillQtyToHandle(WhseActivityLine);
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);
    end;

    local procedure VerifyWhseActivityLine(ItemNo: Code[20]; LocationCode: Code[10]; ExpectedQtyToHandle: Decimal)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.SetRange("Item No.", ItemNo);
        WhseActivityLine.SetRange("Location Code", LocationCode);
        WhseActivityLine.FindSet();
        repeat
            Assert.IsTrue(ExpectedQtyToHandle = WhseActivityLine."Qty. to Handle", StrSubstNo(PickQtyToHandleErr, ExpectedQtyToHandle));
        until WhseActivityLine.Next() = 0;
    end;

    local procedure CreateAndCertifyProductionBOMOfTwoComponents(
        var ProductionBOMHeader: Record "Production BOM Header";
        BaseUnitOfMeasure: Code[10];
        CompItem: Code[20];
        CompItem2: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem, 1);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem2, 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesDequeuePageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickPageHandlerForPerWhsDoc(var CreatePick: TestRequestPage "Create Pick")
    begin
        CreatePick.PerWhseDoc.SetValue(true);
        CreatePick.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PickSelectionPageHandlerSingleDoc(var PickSelection: TestPage "Pick Selection")
    var
        DocumentNo: Variant;
        LocationCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);  // Dequeue Variable.
        LibraryVariableStorage.Dequeue(LocationCode);  // Dequeue Variable.
        PickSelection.Filter.SetFilter("Document No.", DocumentNo);
        PickSelection."Document No.".AssertEquals(DocumentNo);
        PickSelection."Location Code".AssertEquals(LocationCode);
        PickSelection.OK().Invoke();
    end;
}

