codeunit 137406 "SCM Item Reservation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reservation] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryPostInventoryToGL: Codeunit "Library - Post Inventory To GL";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        AppliesToEntryMustBeBlankErr: Label 'Applies-to Entry must not be filled out when reservations exist in Item Ledger Entry Entry No.=''%1''.';
        ReservationDoesNotExistErr: Label 'Reservation does not exist for Item %1.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableItemLedgEntriesHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderItemReservationWithApplyToItemEntry()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        EntryNo: Integer;
    begin
        // [FEATURE] [Cost Application]
        // [SCENARIO] Test Item Reservation functionality for Sales Order with Apply To Item Entry.

        // [GIVEN] Create and post Item Journal Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.", LibraryRandom.RandDec(100, 2));  // Use Random Quantity because value is not important.

        // [WHEN] Create and post Sales Order with Apply To Item Entry.
        EntryNo := FindItemLedgerEntryNo(ItemJournalLine."Item No.", ItemJournalLine."Document No.");
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        asserterror CreateAndPostSalesOrderWithItemReservation(ItemJournalLine, EntryNo);

        // [THEN] Verify Applies-to Entry must not filled error message.
        Assert.ExpectedError(StrSubstNo(AppliesToEntryMustBeBlankErr, EntryNo + 1));
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableItemLedgEntriesHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderItemReservationWithoutApplyToItemEntry()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Cost Application]
        // [SCENARIO] Test Item Reservation functionality for Sales Order without Apply To Item Entry.

        // [GIVEN] Create and post Item Journal Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.", LibraryRandom.RandDec(100, 2));  // Use Random Quantity because value is not important.

        // [WHEN] Create and post Sales Order without Apply To Item Entry.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        DocumentNo := CreateAndPostSalesOrderWithItemReservation(ItemJournalLine, 0);  // Use 0 for blank Entry No.

        // [THEN] Verify Item Ledger Entry after posting Sales Order.
        VerifyItemLedgerEntry(DocumentNo, ItemJournalLine."Item No.", -ItemJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableItemLedgEntriesHandler,StatisticsMessageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderWithItemReservation()
    var
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrderNo: Code[20];
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Production]
        // [SCENARIO] Test Item Reservation functionality for Production Order.

        // [GIVEN] Create Manufacturing Item. Create and post Item Journal Line. Create and refresh Production Order. Calculate and post Consumption.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);  // Use Random Quantity because value is not important.
        ItemNo := CreateManufacturingItem(ProductionBOMLine);
        CreateAndPostItemJournalLine(ItemJournalLine, ProductionBOMLine."No.", Quantity * ProductionBOMLine."Quantity per");
        ProductionOrderNo := CreateAndRefreshProductionOrder(ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ShowReservation(ProductionBOMLine."No.");
        CalculateAndPostConsumption(ProductionOrderNo);

        // [WHEN] Run Adjust Cost Item Entries and Post Inventory Cost to General Ledger.
        LibraryCosting.AdjustCostItemEntries(ItemNo, '');
        LibraryPostInventoryToGL.PostInvtCostToGL(false, WorkDate(), '');

        // [THEN] Verify G/L Entry.
        VerifyGLEntry(ProductionOrderNo, -Quantity * ProductionBOMLine."Quantity per" * ItemJournalLine."Unit Amount");
    end;

    [Test]
    [HandlerFunctions('ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderWithItemReservation()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service]
        // [SCENARIO]Test Item Reservation functionality for Service Order.

        // [GIVEN] Create and post Purchase Order for new Item. Create a Service Order for the same Item.
        Initialize();
        CreateAndPostPurchaseOrder(PurchaseLine);
        CreateServiceOrder(ServiceHeader, ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(ServiceLine.Quantity);  // Quantity is made Global as it is used in Handler.

        // [WHEN] Open Reservation page and Reserve from Current Line using ReservationFromCurrentLine Handler.
        ServiceLine.ShowReservation();

        // [THEN] Total Reserved Quantity is equal to the Quantity in the Service Line.
        // Verification is done in Handler.
    end;

    [Test]
    [HandlerFunctions('ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure ServiceOrderPostWithItemReservation()
    var
        PurchaseLine: Record "Purchase Line";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service]
        // [SCENARIO] Test posting of Service Order with Item Reservation functionality.

        // [GIVEN] Create and post Purchase Order for new Item. Create a Service Order for the same Item. Open Reservation page and Reserve from Current Line.
        Initialize();
        CreateAndPostPurchaseOrder(PurchaseLine);
        CreateServiceOrder(ServiceHeader, ServiceLine, PurchaseLine."No.", PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(ServiceLine.Quantity);  // Quantity is made Global as it is used in Handler.
        ServiceLine.ShowReservation();

        // [WHEN] Post the Service Order as Ship and Invoice.
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Service Order gets posted successfully with Item Reservation.
        VerifyPostedServiceOrder(ServiceHeader, ServiceLine);
    end;

    [Test]
    [HandlerFunctions('ReservationInSalesOrderFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithItemReservation()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // [FEATURE] [Pick]
        // [SCENATIO] Validate Warehouse Activity Line with Item reservation functionality in Sales Order.

        // [GIVEN] Create and Register Warehouse Journal Line and Create and Release Purchase Order and Sales Order. Reserve Sales Order.
        Initialize();
        CreateAndUpdateLocation(Location);
        CreateAndRegisterWarehouseJournalLine(WarehouseJournalLine, Location.Code);
        CalculateAndPostWarehouseAdjustment(WarehouseJournalLine."Item No.");
        CreateAndReleasePurchaseOrder(PurchaseLine, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code");
        CreateAndReleaseSalesOrderWithReservation(
          SalesLine, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code",
          WarehouseJournalLine.Quantity + PurchaseLine.Quantity, PurchaseLine."Expected Receipt Date");

        // [WHEN] Create Pick.
        CreatePick(WarehouseJournalLine."Location Code", SalesLine."Document No.");

        // [THEN] Verify Warehouse Activity Line.
        VerifyWarehouseActivityLine(SalesLine."Document No.", WarehouseJournalLine."Item No.", WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReservationInSalesOrderFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure WareHouseShipmentLineAfterRegisterPick()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // [FEATURE] [Pick]
        // [SCENARIO] Validate Warehouse Shipment Line after register Pick.

        // [GIVEN] Create and Register Warehouse Journal Line and Create and Release Purchase Order and Sales Order. Reserve Sales Order.
        Initialize();
        CreateAndUpdateLocation(Location);
        CreateAndRegisterWarehouseJournalLine(WarehouseJournalLine, Location.Code);
        CalculateAndPostWarehouseAdjustment(WarehouseJournalLine."Item No.");
        CreateAndReleasePurchaseOrder(PurchaseLine, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code");
        CreateAndReleaseSalesOrderWithReservation(
          SalesLine, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code",
          WarehouseJournalLine.Quantity + PurchaseLine.Quantity, PurchaseLine."Expected Receipt Date");
        CreatePick(WarehouseJournalLine."Location Code", SalesLine."Document No.");

        // [WHEN] Register Pick.
        RegisterPick(WarehouseJournalLine."Location Code");

        // [THEN] Verify Warehouse Shipment Line.
        VerifyWareHouseShipmentLine(
          WarehouseJournalLine."Item No.", SalesLine."Document No.", WarehouseJournalLine.Quantity, PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandlerForLot,ConfirmYesHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure CalculatePlanningForLotItemWithReservation()
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO] Check calculate plan for lot item on Requisition Worksheet is working fine with reservation.
        PlanningForItemWithReservation(LibraryUtility.GetGlobalNoSeriesCode());
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure CalculatePlanningWithoutLotItemWithReservation()
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO] Check calculate plan for item withOut lot on Requisition Worksheet is working fine with reservation.
        PlanningForItemWithReservation(''); // Without Lot No.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteToOrderAssemblyOrderWithReservation()
    var
        SalesHeader: Record "Sales Header";
        ComponentItem: Record Item;
    begin
        // [FEATURE] [Assembly]
        // [SCENARIO 109055] Reservation entries are created for component items with Reservation = Always when Sales Order is created from Sales Quote with Assembly Order

        // [GIVEN] Sales Quote with assembled item, component "?" has "Reserved" = "Always"
        Initialize();
        CreateItemAutoReserved(ComponentItem);
        CreateSalesQuoteWithItem(SalesHeader, CreateAssembledItem(ComponentItem));

        // [WHEN] Creating Sales Order from Sales Quote
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // [THEN] Child Assembly Order has reservations for component "C"
        VerifyReservationExists(ComponentItem."No.");
    end;

    local procedure PlanningForItemWithReservation(LotNos: Code[20])
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO] Purchase order created from requisition plan should be posted

        // [GIVEN] Create Item with "Safety Stock Quantity" & "ReOrdering Policy" .Creating Purchase Order , Post Postive adjustment &
        // Creation of Sales Order and reserve the Quantity
        Initialize();
        CreateItemWithLotAndTracking(Item, LotNos);
        CreatePurchaseOrderWithItemTracking(Item."No.", LotNos, PurchaseLine);
        PostItemPositiveAdjmt(Item."No.", LotNos, ItemJournalLine);
        CreateSalesOrderAndReserve(Item."No.", PurchaseLine.Quantity + ItemJournalLine.Quantity - LibraryRandom.RandDec(10, 2));
        CalculatePlanningFromReqWorkSheet(Item);

        // [WHEN] Create and post Purchase order from requisition line.
        SelectAndCarryOutActionMsg(Item."No.", PurchaseLine."Buy-from Vendor No.");
        DocumentNo := PostPurchaseOrder(PurchaseLine."Buy-from Vendor No.");

        // [THEN] Verifying that Purchase order has been posted successfully.
        PurchInvHeader.Get(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableProdOrderLineReservePageHandler,StrMenuHandler')]
    [Scope('OnPrem')]
    procedure DemandTransferSupplyProdOrderReserveFromDemand()
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        ProductionOrder: Record "Production Order";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        Qty: Decimal;
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Transfer] [Production]
        // [SCENARIO] Item can be reserved from "Available - Prod. Order Lines" page when demand is Transfer Order, and supply - Production Order

        Qty := LibraryRandom.RandDec(1000, 2);
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        CreateTrasferOrder(TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", Qty);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        ProductionOrder.Validate("Location Code", FromLocation.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        LibraryVariableStorage.Enqueue(Qty);
        TransferLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableProdOrderLineCancelReservationPageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure DemandSaleSupplyProdOrderReserveCancelReservation()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Qty: Decimal;
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Production]
        // [SCENARIO] Reservation should be cancelled from "Available - Prod. Order Lines" page when "Cancel Reservation" action is executed

        Qty := LibraryRandom.RandDec(1000, 2);
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesLine, Item."No.", Qty);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableProdOrderLineDrillDownQtyPageHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSaleSupplyProdOrderReserveDrillDownReservedQty()
    var
        SalesLine: Record "Sales Line";
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Qty: Decimal;
    begin
        // [FEATURE] [Available - Prod. Order Lines] [Production]
        // [SCENARIO] Drill down in "Current Reserved Quantity" field, page "Available - Prod. Order Lines" should show total reserved quantity

        Qty := LibraryRandom.RandDec(1000, 2);
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesLine, Item."No.", Qty);

        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableItemLedgEntriesDrillDownHandler,ReservationEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure DemandSaleSupplyItemLedgEntryReserveDrillDownReservedQty()
    var
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // [FEATURE] [Available - Item Ledg. Entries]
        // [SCENARIO] Drill down in "Current Reserved Quantity" field, page "Available - Item Ledg. Entries" should show total reserved quantity

        LibraryInventory.CreateItem(Item);
        PostItemPositiveAdjmt(Item."No.", '', ItemJournalLine);
        CreateSalesOrder(SalesLine, Item."No.", ItemJournalLine.Quantity);

        LibrarySales.AutoReserveSalesLine(SalesLine);

        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableItemLedgEntriesCancelReservationHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure DemandSaleSupplyItemLedgEntryReserveCancelReservation()
    var
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // [FEATURE] [Available - Item Ledg. Entries]
        // [SCENARIO] Reservation should be cancelled from "Available - Item Ledg. Entries" page when "Cancel Reservation" action is executed

        LibraryInventory.CreateItem(Item);
        PostItemPositiveAdjmt(Item."No.", '', ItemJournalLine);
        CreateSalesOrder(SalesLine, Item."No.", ItemJournalLine.Quantity);

        LibrarySales.AutoReserveSalesLine(SalesLine);

        SalesLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('ReservationHandler,AvailableItemLedgEntriesHandler')]
    [Scope('OnPrem')]
    procedure DemandPurchaseReturnSupplyItemLedgerReserveFromDemand()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // [FEATURE] [Available - Item Ledg. Entries]
        // [SCENARIO] Item can be reserved from "Available - Item Ledg. Entries" page when demand is Purchase Return Order, and supply - Inventory

        LibraryInventory.CreateItem(Item);
        PostItemPositiveAdjmt(Item."No.", '', ItemJournalLine);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", '', Item."No.");

        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
        PurchaseLine.ShowReservation();
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ReservationHandler,AvailableItemLedgEntriesHandler')]
    [Scope('OnPrem')]
    procedure DemandTransferSupplyItemLedgEntryReserveFromDemand()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Available - Item Ledg. Entries]
        // [SCENARIO] Item can be reserved from "Available - Item Ledg. Entries" page when demand is Transfer Order, and supply - Inventory

        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);

        Qty := LibraryRandom.RandDec(1000, 2);
        CreateAndPostItemJournalLineOnLocation(ItemJournalLine, Item."No.", Qty, FromLocation.Code);
        CreateTrasferOrder(TransferLine, FromLocation.Code, ToLocation.Code, Item."No.", Qty);

        LibraryVariableStorage.Enqueue(Qty);
        TransferLine.ShowReservation();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Item Reservation");
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Item Reservation");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Item Reservation");
    end;

    local procedure CalculateAndPostConsumption(ProductionOrderNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Consumption);
        LibraryManufacturing.CalculateConsumption(ProductionOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CalculateAndPostWarehouseAdjustment(ItemNo: Code[20]): Code[10]
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalBatch.Name);
    end;

    local procedure CalculatePlanningFromReqWorkSheet(Item: Record Item)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate);
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        LibraryPlanning.CalculatePlanForReqWksh(
          Item, ReqWkshTemplate.Name, RequisitionWkshName.Name, WorkDate(),
          CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(3)), WorkDate()));
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateAndPostItemJournalLineOnLocation(ItemJournalLine, ItemNo, Quantity, '');
    end;

    local procedure CreateAndPostItemJournalLineOnLocation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandInt(5));  // Use Random Unit Amount because value is not important.
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostSalesOrderWithItemReservation(ItemJournalLine: Record "Item Journal Line"; ApplyToItemEntry: Integer): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesLine, ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesLine.Validate("Appl.-to Item Entry", ApplyToItemEntry);
        SalesLine.Modify(true);
        SalesLine.ShowReservation();
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, false));
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));  // Use random Quantity.
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));  // Post Purchase Order as Receive.
    end;

    local procedure CreateAndRefreshProductionOrder(ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        exit(ProductionOrder."No.");
    end;

    local procedure CreateAndRegisterWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10])
    var
        Item: Record Item;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Bin: Record Bin;
    begin
        LibraryInventory.CreateItem(Item);
        FindBin(Bin, LocationCode);
        LibraryWarehouse.CreateWarehouseJournalBatch(
            WarehouseJournalBatch, "Warehouse Journal Template Type"::Item, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name",
          WarehouseJournalBatch.Name, LocationCode, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
          Item."No.", LibraryRandom.RandInt(100));
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LocationCode, ItemNo);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ShipmentDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesLine, SalesHeader, ItemNo, LocationCode, '', Quantity);
        SalesLine.Validate("Shipment Date", CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', ShipmentDate));
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.ShowReservation();
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location)
    begin
        CreateFullWarehouseSetup(Location);
        Location.Validate("Require Receive", true);
        Location.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        SelectItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandInt(5));  // Use Random Unit Amount because value is not important.
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateManufacturingItem(var ProductionBOMLine: Record "Production BOM Line"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Production BOM No.", CreateAndCertifyProductionBOM(ProductionBOMLine, Item."Base Unit of Measure"));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAssembledItem(ComponentItem: Record Item): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);
        AddComponentToAssemblyList(ComponentItem."No.", Item."No.", ComponentItem."Base Unit of Measure", 1);
        exit(Item."No.");
    end;

    local procedure CreateItemAutoReserved(var Item: Record Item)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        Clear(Item);
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
        PostItemPositiveAdjmt(Item."No.", '', ItemJournalLine);
    end;

    local procedure AddComponentToAssemblyList(ComponentNo: Code[20]; ParentItemNo: Code[20]; UOM: Code[10]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateBOMComponent(BOMComponent, ParentItemNo, BOMComponent.Type::Item, ComponentNo, QuantityPer, UOM);
    end;

    local procedure CreatePick(LocationCode: Code[10]; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        // Create Purchase Order with One Item Line. Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        UpdateLocationOnPurchaseLine(PurchaseLine, LocationCode);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMLine: Record "Production BOM Line"; UnitOfMeasureCode: Code[10]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Qty: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateSalesQuoteWithItem(var SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(1, 5, 2));
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CreateCustomer());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure CreateTrasferOrder(var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Qty: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        InTransitLocation: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Qty);
    end;

    local procedure CreateItemWithLotAndTracking(var Item: Record Item; LotNos: Code[20])
    var
        ItemCategory: Record "Item Category";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCategory(ItemCategory);
        Item.Validate("Item Category Code", ItemCategory.Code);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Include Inventory", true);
        Item.Validate("Safety Stock Quantity", LibraryRandom.RandDecInRange(25, 30, 2));
        Item.Validate("Item Tracking Code", CreateItemTrackingCodeWithLot());
        Item.Validate("Lot Nos.", LotNos);
        Item.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithItemTracking(ItemNo: Code[20]; LotNos: Code[20]; var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(90, 100, 2));
        if LotNos <> '' then
            PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderAndReserve(ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesLine, ItemNo, Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.Validate("Shipment Date", CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate()));
        SalesHeader.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure PostItemPositiveAdjmt(ItemNo: Code[20]; LotNos: Code[20]; var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemNo, LibraryRandom.RandDecInRange(10, 15, 2));
        if LotNos <> '' then
            ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PostPurchaseOrder(VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure SelectAndCarryOutActionMsg(ItemNo: Code[20]; VendorNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.FindFirst();
        RequisitionLine.ModifyAll("Vendor No.", VendorNo, true);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template")
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        BinType: Record "Bin Type";
        Zone: Record Zone;
    begin
        FindBinType(BinType);
        FindZone(Zone, LocationCode, BinType.Code);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.SetRange("Adjustment Bin", false);
        Bin.FindFirst();
    end;

    local procedure FindBinType(var BinType: Record "Bin Type")
    begin
        BinType.SetRange("Put Away", true);
        BinType.SetRange(Pick, true);
        BinType.FindFirst();
    end;

    local procedure FindItemLedgerEntryNo(ItemNo: Code[20]; DocumentNo: Code[20]): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[20])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure CreateItemTrackingCodeWithLot(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        ItemTrackingCode.Validate("Lot Sales Inbound Tracking", true);
        ItemTrackingCode.Validate("Lot Sales Outbound Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure RegisterPick(LocationCode: Code[10])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        WarehouseActivityHeader.SetRange("Location Code", LocationCode);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure ShowReservation(ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.ShowReservation();
    end;

    local procedure UpdateLocationOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    begin
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Item No.", ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedServiceOrder(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("Customer No.", ServiceHeader."Customer No.");
        ServiceInvoiceLine.SetRange("Document No.", ServiceInvoiceHeader."No.");
        ServiceInvoiceLine.FindFirst();
        ServiceInvoiceLine.TestField("No.", ServiceLine."No.");
        ServiceInvoiceLine.TestField(Quantity, ServiceLine.Quantity);
    end;

    local procedure VerifyWarehouseActivityLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.TestField("Item No.", ItemNo);
            WarehouseActivityLine.TestField(Quantity, Quantity);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyWareHouseShipmentLine(ItemNo: Code[20]; SourceNo: Code[20]; Quantity: Decimal; PurchaseQuantity: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.SetRange("Item No.", ItemNo);
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.TestField(Quantity, Quantity + PurchaseQuantity);
        WarehouseShipmentLine.TestField("Qty. to Ship", Quantity);
        WarehouseShipmentLine.TestField("Qty. Outstanding (Base)", Quantity + PurchaseQuantity);
    end;

    local procedure VerifyReservationExists(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        Assert.IsFalse(ReservationEntry.IsEmpty, StrSubstNo(ReservationDoesNotExistErr, ItemNo));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.AvailableToReserve.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.TotalReservedQuantity.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationInSalesOrderFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.First();
        Reservation."Reserve from Current Line".Invoke();
        Reservation.Last();
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableItemLedgEntriesHandler(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    begin
        AvailableItemLedgEntries.Reserve.Invoke();
        AvailableItemLedgEntries."Reserved Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableItemLedgEntriesDrillDownHandler(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    begin
        AvailableItemLedgEntries.ReservedQuantity.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableItemLedgEntriesCancelReservationHandler(var AvailableItemLedgEntries: TestPage "Available - Item Ledg. Entries")
    begin
        AvailableItemLedgEntries.CancelReservation.Invoke();
        AvailableItemLedgEntries."Reserved Quantity".AssertEquals(0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderLineReservePageHandler(var AvailableProdOrderLines: TestPage "Available - Prod. Order Lines")
    begin
        AvailableProdOrderLines.Reserve.Invoke();
        AvailableProdOrderLines."Reserved Qty. (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderLineCancelReservationPageHandler(var AvailableProdOrderLines: TestPage "Available - Prod. Order Lines")
    begin
        AvailableProdOrderLines.CancelReservation.Invoke();
        AvailableProdOrderLines."Reserved Qty. (Base)".AssertEquals(0);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AvailableProdOrderLineDrillDownQtyPageHandler(var AvailableProdOrderLines: TestPage "Available - Prod. Order Lines")
    begin
        AvailableProdOrderLines.ReservedQuantity.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandlerForLot(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.First();
        Reservation."Auto Reserve".Invoke();
        Reservation.First();
        Reservation.CancelReservationCurrentLine.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationEntriesPageHandler(var ReservationEntries: TestPage "Reservation Entries")
    begin
        ReservationEntries.First();
        ReservationEntries."Quantity (Base)".AssertEquals(LibraryVariableStorage.DequeueDecimal());
        ReservationEntries.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure StatisticsMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(ValueEntriesWerePostedTxt, Message);
    end;
}

