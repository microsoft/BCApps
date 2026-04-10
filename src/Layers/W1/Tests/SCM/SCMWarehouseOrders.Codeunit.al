codeunit 137161 "SCM Warehouse Orders"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Warehouse]
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ReclassItemJournalTemplate: Record "Item Journal Template";
        ReclassItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LocationBlue: Record Location;
        LocationGreen: Record Location;
        LocationSilver: Record Location;
        LocationYellow: Record Location;
        LocationOrange: Record Location;
        LocationWhite: Record Location;
        LocationInTransit: Record Location;
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        CrossDockWarehouseEntryErr: Label 'Cross Dock Warehouse Entry must not exist.';
        DateCompressConfirmMsg: Label 'This batch job deletes entries. We recommend that you create a backup of the database before you run the batch job.\\Do you want to continue?';
        EmailBlankErr: Label 'Email must have a value in Contact: No.=%1', Locked = true;
        ExpectedWarehousePickErrMsg: Label 'This document cannot be shipped completely. Change the value in the Shipping Advice field to Partial.';
        InventoryPickExistsAndShippingAdviceCompleteErr: Label 'You cannot add an item line because an open inventory pick exists for the Sales Header and because Shipping Advice is Complete.';
        InventoryPickMsg: Label 'Number of Invt. Pick activities created';
        InventoryPutAwayMsg: Label 'Number of Invt. Put-away activities created';
        OutboundDocument: Option SalesOrder,OutboundTransfer;
        JournalLinesPostedMsg: Label 'The journal lines were successfully posted';
        PickActivityCreatedMsg: Label 'Pick activity no. ';
        QuantityMustBeSameErr: Label 'Quantity must be same.';
        QtyToCrossDockErr: Label '%1 must be correct.', Comment = '%1 = Quantity';
        ItemTrackingMode: Option AssignLotNo,SelectEntries,AssignSerialNo,UpdateQtyOnFirstLine,UpdateQtyOnLastLine,VerifyLot,AssignManualLotNo;
        isInitialized: Boolean;
        PostJournalLinesConfirmationQst: Label 'Do you want to post the journal lines';
        ReservationEntryForItemLedgerEntryErr: Label 'Reservation Entry for Item Ledger Entry must not exist.';
        ConfirmLinkToEmptyLineMsg: Label 'Usage will not be linked to the project planning line because the Line Type field is empty';
        WrongNoOfRecordsErr: Label 'The list must contain %1 records', Comment = '%1 = Record count';
        InsufficientQtyItemTrkgErr: Label 'Item tracking defined for source line %1 of %2 %3 amounts to more than the quantity you have entered.';
        DialogCodeErr: Label 'Dialog';
        QtyToHandleErr: Label '%1 must be %2 in %3', Comment = '%1 = Qty. to Handle, %2 = Quantity * Qty. per Unit of Measure, %3 = Whse. Worksheet Line';
        RoutingStatusFieldErr: Label 'Routing Status must not be %1 in Prod. Order Routing Line Status=''%2'',Prod. Order No.=''%3'',Routing Reference No.=''%4'',Routing No.=''%5'',Operation No.=''%6''';

    [Test]
    [HandlerFunctions('PartialReservationPageHandler,HandlePickSelectionPage')]
    [Scope('OnPrem')]
    procedure PartialPickWorksheetLineRemainsQtyOutstandingInthePickWorksheetAfterPickCreationWhenQtyOnILEIsEnough()
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LocationCode: Code[10];
        QtyResvdOnILE: Decimal;
        QtyOnInventory: Decimal;
        QtyOnPO: Decimal;
    begin
        // [FEATURE] [Pick Worksheet]
        // [SCENARIO 361128] Partial Pick Worksheet Line remains in the Pick Worksheet after Pick creation when Qty on ILE is enough
        Initialize();

        QtyOnPO := LibraryRandom.RandDec(100, 2);
        QtyResvdOnILE := LibraryRandom.RandDec(100, 2);
        QtyOnInventory := QtyOnPO + QtyResvdOnILE + LibraryRandom.RandDecInRange(100, 200, 2);

        // [GIVEN] Sales Order for Item with Qty = "Q"
        // [GIVEN] Item with Inventory "X", where "X" > "Q"
        // [GIVEN] Purchase Order for Item with Qty = "Y", where "Y" < "Q"
        // [GIVEN] Reserve Purchase Order completely against Sales Order ("Y").
        // [GIVEN] Release Sales Order, Create Warehouse Shipment, Release Warehouse Shipment
        // [GIVEN] Create Pick Worksheet Line for Warehouse Shipment.
        CreatePartialPick(WhseWorksheetName, WhseWorksheetLine, LocationCode, QtyOnPO, QtyResvdOnILE, QtyOnInventory);

        // [WHEN] Create Pick
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          LocationCode, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);

        // [THEN] Pick Worksheet Line for Item remains with Qty Outstanding = "Y"
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode);
        Assert.AreEqual(QtyOnPO, WhseWorksheetLine."Qty. Outstanding", QuantityMustBeSameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayAfterCalculateCrossDockOnWarehouseReceiptWithMultipleItems()
    begin
        // [FEATURE] [Cross-Docking]
        // [SCENARIO 295183] Test the Warehouse Entry for Cross Dock Quantity with Purchase Order created with multiple lines and Sales Order created with single Line.

        Initialize();

        // [GIVEN] Create Warehouse Receipt from Purchase Order. Create and Release Sales Order.
        CalculateCrossDockOnWarehouseReceiptAndRegisterPutAwayWithMultipleItems(true);  // Register Put Away as TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure CalculatePlanOnRequisitionWorksheetWithMultiplePurchaseOrders()
    begin
        // [FEATURE] [Requisition Worksheet]
        // [SCENARIO 268394] Test the Reservation Entry after Calculate Plan on Requisition Worksheet with Sales Order and Multiple Purchase Order.

        Initialize();
        CalculatePlanOnRequisitionWorksheetAndRegisterWarehouseActivity(false, false, false);  // Register Put Away, Register Pick And Post Shipment, Sales Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromSalesOrderWithShippingAdviceCompleteError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Inventory Pick] [Shipping Advice] [Sales]
        // [SCENARIO 239181] Test the error message Inventory Pick Exists and Shipping Advice Complete after creating Inventory Pick from Sales Order and Adding New Line to Sales Order.

        // [GIVEN] Create and Post Item journal Line. Create and Release Sales Order with Shipping Advice as Complete. Create Inventory Pick from Sales Order. Reopen Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationBlue.Code, '');
        CreateAndReleaseSalesDocumentWithShippingAdviceAsComplete(
          SalesHeader, SalesHeader."Document Type"::Order, Item."No.", Quantity, LocationBlue.Code);
        LibraryVariableStorage.Enqueue(InventoryPickMsg);  // Enqueue for MessageHandler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true);  // Taking True for Pick.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Adding New Line to the Sales Order.
        asserterror CreateSalesLine(SalesHeader, SalesLine, Item."No.", Quantity, LocationBlue.Code);

        // [THEN] Verify error message.
        Assert.ExpectedError(InventoryPickExistsAndShippingAdviceCompleteErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPutAwayFromSalesReturnOrderWithShippingAdviceCompleteError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Inventory Put-Away] [Shipping Advice] [Sales Return]
        // [SCENARIO 239181] Test the error message Inventory Pick Exists and Shipping Advice Complete after creating Inventory Put Away from Sales Return Order and Adding New Line to Sales Order.

        // [GIVEN] Create and Release Sales Return Order with Shipping Advice as Complete. Create Inventory Put Away from Sales Return Order. Reopen Sales Return Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesDocumentWithShippingAdviceAsComplete(
          SalesHeader, SalesHeader."Document Type"::"Return Order", Item."No.", LibraryRandom.RandDec(10, 2), LocationBlue.Code);
        LibraryVariableStorage.Enqueue(InventoryPutAwayMsg);  // Enqueue for MessageHandler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Return Order", SalesHeader."No.", true, false);  // Taking True for Put Away.
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // [WHEN] Adding New Line to the Sales Return Order.
        asserterror CreateSalesLine(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), LocationBlue.Code);

        // [THEN] Verify error message.
        Assert.ExpectedError(InventoryPickExistsAndShippingAdviceCompleteErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentWithBlankLocation()
    begin
        // [FEATURE] [Pick] [Warehouse Shipment]
        // [SCENARIO 250682] Test the Warehouse Activity Line after creating Pick with Blank Location.

        Initialize();
        RegisterPickAndPostWarehouseShipmentWithBlankLocation(false);  // Post Shipment as FALSE.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentWithBlankLocation()
    begin
        // [FEATURE] [Pick] [Warehouse Shipment]
        // [SCENARIO 250682] Test the Item Ledger Entry after Registering Pick and Posting Warehouse Shipment with Blank Location.

        Initialize();
        RegisterPickAndPostWarehouseShipmentWithBlankLocation(true);  // Post Shipment as TRUE.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,MessageHandler,WhseSourceCreateDocumentHandler')]
    [Scope('OnPrem')]
    procedure CreateAndRegisterPickFromInternalPickWithMultipleUnitOfMeasureAndLot()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        LotNo: Code[50];
        LotNo2: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Internal Pick] [Item Tracking]
        // [SCENARIO 239391] Test to register Pick from Warehouse Internal Pick with multiple Unit of Measures and Lot No.

        // [GIVEN] Create Item with Lot specific tracking. Update Inventory using Warehouse Journal. Create Pick from Warehouse Internal Pick.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // True for Lot.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5) + 1);
        FindPickBin(Bin, LocationWhite.Code);
        LotNo := UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item, Bin, Quantity, Item."Base Unit of Measure");
        LotNo2 := UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item, Bin, Quantity, ItemUnitOfMeasure.Code);
        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreatePickFromWarehouseInternalPickWithMultipleLines(
          WhseInternalPickHeader, Bin, Item, Quantity, ItemUnitOfMeasure.Code, LotNo, LotNo2);

        // [WHEN] Register pick
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] Verify quantity and lot no. on registered pick
        VerifyRegisteredWarehousePickLine(WhseInternalPickHeader."No.", Item."No.", Quantity, Item."Base Unit of Measure", LotNo);
        VerifyRegisteredWarehousePickLine(WhseInternalPickHeader."No.", Item."No.", Quantity, ItemUnitOfMeasure.Code, LotNo2);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,ProductionJournalHandler,ItemTrackingSummaryPageHandler,DateCompressWarehouseEntriesHandler,MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RunDateCompressWhseEntriesAfterPostProductionJournalWithLotNo()
    var
        Bin: Record Bin;
        ParentItem: Record Item;
        ChildItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionOrder: Record "Production Order";
        Vendor: Record Vendor;
        WarehouseEntry: Record "Warehouse Entry";
        SaveWorkDate: Date;
        LotNo: Code[50];
        Quantity: Decimal;
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Manufacturing] [Date Compress Whse. Entries] [Item Tracking]
        // [SCENARIO 268655] Test to run Date Compress Warehouse Entries batch report after Post Production Journal from Released Production Order with Lot No.

        // [GIVEN] Create Item with Production BOM. Create and post Purchase Order as Receive for Child Item with Lot No. Create and refresh Released Production Order. Post the Production Journal.
        Initialize();
        LibraryFiscalYear.CreateClosedAccountingPeriods();
        SaveWorkDate := WorkDate();
        WorkDate(LibraryFiscalYear.GetFirstPostingDate(true));
        QuantityPer := LibraryRandom.RandInt(10);
        Quantity := Quantity + LibraryRandom.RandInt(10);  // Greater value required for Quantity.
        CreateItemWithProductionBOM(ParentItem, ChildItem, QuantityPer);
        LibraryWarehouse.CreateBin(Bin, LocationYellow.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryPurchase.CreateVendor(Vendor);
        LotNo :=
          CreateAndPostPurchaseOrderWithLotItemTracking(
            PurchaseHeader, Vendor."No.", ChildItem."No.", Quantity * QuantityPer, LocationYellow.Code, Bin.Code);
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", Quantity, LocationYellow.Code, Bin.Code);
        PostProductionJournal(ProductionOrder);
        WorkDate(SaveWorkDate);

        // [WHEN] Run "Date Compress Whse. Entries" report
        LibraryVariableStorage.Enqueue(DateCompressConfirmMsg);  // Enqueue for ConfirmHandler.
        LibraryWarehouse.RunDateCompressWhseEntries(ChildItem."No.");

        // Verify.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", ChildItem."No.", LocationYellow.Code, Bin.Code, Quantity * QuantityPer, LotNo);  // Value required for verification.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", ChildItem."No.", LocationYellow.Code, Bin.Code, -Quantity * QuantityPer, LotNo);  // Value required for verification.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWarehousePutAwayAfterCalculatePlanWithMultiplePurchaseOrders()
    begin
        // [FEATURE] [Reservation] [Requisition Worksheet] [Put-Away]
        // [SCENARIO 268394] Test the Reservation Entry after Calculate Plan on Requisition Worksheet and Register Put Away with Sales Order and Multiple Purchase Order.

        Initialize();
        CalculatePlanOnRequisitionWorksheetAndRegisterWarehouseActivity(true, false, false);  // Register Pick And Post Shipment, Sales Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWarehousePickAndPostWarehouseShipmentAfterCalculatePlanWithMultiplePurchaseOrders()
    begin
        // [FEATURE] [Reservation] [Requisition Worksheet] [Pick]
        // [SCENARIO 268394] Test the Reservation Entry after Calculate Plan on Requisition Worksheet, Register Pick and Post Warehouse Shipment with Sales Order and Multiple Purchase Order.

        Initialize();
        CalculatePlanOnRequisitionWorksheetAndRegisterWarehouseActivity(true, true, false);  // Sales Order as FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWarehousePickAndPostWarehouseShipmentOfRemainingQuantity()
    begin
        // [FEATURE] [Requisition Worksheet] [Put-Away]
        // [SCENARIO 268394] Test the Item Ledger Entry after Calculate Plan on Requisition Worksheet, Register Put Away, Register Pick and Post Warehouse Shipment. And Sales Order created of Remaining Quantity.

        Initialize();
        CalculatePlanOnRequisitionWorksheetAndRegisterWarehouseActivity(true, true, true);  // Register Put Away, Register Pick And Post Shipment, Sales Order as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickFromPickWorksheetForMultipleItemsWithGetWarehouseDocuments()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        SalesHeader2: Record "Sales Header";
        WarehouseShipmentHeader2: Record "Warehouse Shipment Header";
        WarehouseEntry: Record "Warehouse Entry";
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Pick] [Pick Worksheet]
        // [SCENARIO 286062] Test the Warehouse Entry after Creating Pick from Pick Worksheet with multiple Item and Get Warehouse Documents.

        // Setup: Create Multiple Items. Create and Release Warehouse Shipment for both Items.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        FindPickBin(Bin, LocationWhite.Code);
        CreateAndReleaseWarehouseShipmentFromSalesOrder(SalesHeader, WarehouseShipmentHeader, Item, Bin, Quantity);
        CreateAndReleaseWarehouseShipmentFromSalesOrder(SalesHeader2, WarehouseShipmentHeader2, Item2, Bin, Quantity);

        // Exercise.
        CreateAndRegisterPickUsingPickWorksheet(
          LocationWhite.Code, WarehouseShipmentHeader."No.", WarehouseShipmentHeader2."No.", Item."No.", Item2."No.", SalesHeader."No.");

        // Verify.
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::Movement, Item."No.", LocationWhite.Code, Bin.Code, -Quantity, '');
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::Movement, Item."No.", LocationWhite.Code, LocationWhite."Shipment Bin Code", Quantity, '');
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::Movement, Item2."No.", LocationWhite.Code, Bin.Code, -Quantity, '');
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::Movement, Item2."No.", LocationWhite.Code, LocationWhite."Shipment Bin Code", Quantity, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetAfterRegisterPutAwayWithReservation()
    begin
        // [FEATURE] [Pick Worksheet] [Pick] [Reservation]
        // [SCENARIO 264160] Test the Available Quantity to Pick on Pick Worksheet Line after Register Put Away with Item as Reserve Always.

        Initialize();
        AvailableQuantityToPickOnPickWorksheetAfterRegisterPutAwayAndPick(false);  // Register Pick From Warehouse Shipment as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetAfterRegisterPickWithReservation()
    begin
        // [FEATURE] [Pick Worksheet] [Reservation]
        // [SCENARIO 264160] Test the Available Quantity to Pick on Pick Worksheet Line after Register Put Away and Pick with Item as Reserve Always.

        Initialize();
        AvailableQuantityToPickOnPickWorksheetAfterRegisterPutAwayAndPick(true);  // Register Pick From Warehouse Shipment as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetBeforeRegisterPutAwayWithReservation()
    begin
        // [FEATURE] [Pick Worksheet] [Reservation]
        // [SCENARIO 264160] Test the Available Quantity to Pick on Pick Worksheet Line before Register Put Away with Item as Reserve Always.

        Initialize();
        AvailableQuantityToPickOnPickWorksheetBeforeRegisterPutAwayAndAfterRegisterPick(false);  // Register Pick From Warehouse Shipment as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetBeforeRegisterPutAwayAndAfterRegisterPickWithReservation()
    begin
        // [FEATURE] [Pick Worksheet] [Reservation]
        // [SCENARIO 264160] Test the Available Quantity to Pick on Pick Worksheet Line before Register Put Away and after Register Pick with Item as Reserve Always.

        Initialize();
        AvailableQuantityToPickOnPickWorksheetBeforeRegisterPutAwayAndAfterRegisterPick(true);  // Register Pick From Warehouse Shipment as TRUE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetAfterRegisterPartialPutAwayWithReservation()
    begin
        // [FEATURE] [Pick Worksheet] [Pick] [Reservation]
        // [SCENARIO 264160] Test the Available Quantity to Pick on Pick Worksheet Line after Partially Register Put Away with Item as Reserve Always.

        Initialize();
        AvailableQuantityToPickOnPickWorksheetAfterRegisterPartialPutAwayAndRegisterPick();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure RegisterWarehouseJournalLineWithLotAndMultipleBins()
    begin
        // [FEATURE] [Pick Worksheet] [Put-Away] [Pick] [Item Tracking]
        // [SCENARIO 244866] Test and verify Warehouse entries after register Warehouse Journal line with Lot and multiple Bins.

        Initialize();
        PostWarehouseShipmentAfterRegisterPickFromSalesOrderWithLotAndMultipleBins(false, false, false);  // CalculateWhseAdjustment, RegisterPick and PostWhseShipment as FALSE.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure CalculateWhseAdjustmentAndPostItemJournalLineWithLotAndMultipleBins()
    begin
        // [FEATURE] [Warehouse Journal] [Bin] [Item Tracking]
        // [SCENARIO 244866] Test and verify Warehouse entries after post Warehouse Journal line with Lot and multiple Bins.

        Initialize();
        PostWarehouseShipmentAfterRegisterPickFromSalesOrderWithLotAndMultipleBins(true, false, false);  // CalculateWhseAdjustment as TRUE. RegisterPick and PostWhseShipment as FALSE.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure CreateAndRegisterPickFromSalesOrderWithLotAndMultipleBins()
    begin
        // [FEATURE] [Warehouse Journal] [Bin] [Item Tracking]
        // [SCENARIO 244866] Test and verify Warehouse entries after register Pick from Sales Order with Lot and multiple Bins.

        Initialize();
        PostWarehouseShipmentAfterRegisterPickFromSalesOrderWithLotAndMultipleBins(true, true, false);  // CalculateWhseAdjustment and RegisterPick as TRUE. PostWhseShipment as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockingWithReleasedProductionOrder()
    var
        Item: Record Item;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
        Quantity: Decimal;
    begin
        // [FEATURE] [Cross-Docking] [Manufacturing] [Requisition Worksheet]
        // [SCENARIO 143086] Test and verify Cross Docking with Released Production Order.

        // Setup: Create Item with Order Reorder Policy and Production BOM. Create and refresh Production Order. Create Warehouse Receipt from Purchase Order Suggested By Requisition Worksheet.
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, false, true, true, true, true);
        UpdateUseCrossDockingOnLocation(Location, true);
        Quantity := CreateItemWithOrderReorderPolicyAndProductionBOM(Item, ComponentItem);
        CreateAndRefreshProductionOrder(ProductionOrder, Item."No.", Quantity, Location.Code, '');
        CreateWhseReceiptFromPurchOrderSuggestedByReqWksh(PurchaseHeader, ComponentItem);

        // Exercise.
        CalculateCrossDock(PurchaseHeader."No.", ComponentItem."No.");

        // Verify.
        VerifyWarehouseCrossDockOpportunity(ProductionOrder."No.", ComponentItem."No.", Quantity * Quantity);  // Value required for Reserved Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostItemReclassificationJournalWithUpdatedDescription()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        Quantity: Decimal;
        Description: Text[50];
    begin
        // [FEATURE] [Item Reclassification] [Bin]
        // [SCENARIO 259156] Test to verify Description gets updated on Warehouse Entry after post Item Reclassification Journal.

        // Setup: Create Bin for two Silver Locations. Create and post Item Journal line.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin2, LocationYellow.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateItemWithVendorNoAndReorderingPolicy(Item, '', Item."Reordering Policy"::" ");
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationYellow.Code, Bin2.Code);

        // Exercise.
        Description := CreateAndPostItemReclassificationJournalLine(Bin2, Bin, Item."No.", Quantity);

        // Verify.
        VerifyDescriptionOnWarehouseEntry(Item."No.", Description);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithJobAndJobTask()
    var
        Item: Record Item;
        Bin: Record Bin;
        JobTask: Record "Job Task";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Job] [Bin]
        // [SCENARIO 251093] Test the Item Ledger Entry and Warehouse Entry after Post Purchase Order as Receive and Invoice with Job.

        // [GIVEN] Create Bin. Create Job with Job Task. Create Purchase Order. Update Bin Code, Job No. and Job Task No. on Purchase Line.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateJobWithJobTask(JobTask);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, '', Item."No.", LibraryRandom.RandDec(10, 2), LocationSilver.Code, false);
        UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(PurchaseLine, JobTask, Bin.Code);
        LibraryVariableStorage.Enqueue(ConfirmLinkToEmptyLineMsg);

        // [WHEN] Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // [THEN] Verify Item Ledger Entry and Warehouse Entry.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, Item."No.", PurchaseLine.Quantity, LocationSilver.Code, JobTask."Job No.",
          JobTask."Job Task No.");
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::"Negative Adjmt.", Item."No.", -PurchaseLine.Quantity, LocationSilver.Code, JobTask."Job No.",
          JobTask."Job Task No.");
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", LocationSilver.Code, Bin.Code, PurchaseLine.Quantity, '');
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", Item."No.", LocationSilver.Code, Bin.Code, -PurchaseLine.Quantity, '');
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentOfSalesOrderWithLotAndMultipleBins()
    begin
        // [FEATURE] [Warehouse Shipment] [Item Tracking] [Bin]
        // [SCENARIO 244866] Test and verify Warehouse entries after post Warehouse Shipment with Lot and multiple Bins.

        Initialize();
        PostWarehouseShipmentAfterRegisterPickFromSalesOrderWithLotAndMultipleBins(true, true, true);  // CalculateWhseAdjustment, RegisterPick and PostWhseShipment as TRUE.
    end;

    local procedure PostWarehouseShipmentAfterRegisterPickFromSalesOrderWithLotAndMultipleBins(CalculateWhseAdjustment: Boolean; RegisterPick: Boolean; PostWhseShipment: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LotNo: Code[50];
        ItemTrackingMode: Option AssignLotNo,SelectLotNo;
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Item with Lot specific Tracking. Create and register Warehouse Journal line with Lot No.
        Quantity := LibraryRandom.RandDec(10, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);  // Greater value required for Quantity.
        LotNo := CreateItemAndRegisterWarehouseJournalLineWithItemTracking(Bin, Item, Quantity, LocationWhite.Code);
        LibraryWarehouse.CreateBin(Bin2, LocationWhite.Code, LibraryUtility.GenerateGUID(), Bin."Zone Code", Bin."Bin Type Code");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectLotNo);  // Enqueue for WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for WhseItemTrackingLinesHandler.

        // Exercise.
        CreateAndRegisterWarehouseJournalLine(Bin2, Item, Quantity2, Item."Base Unit of Measure", true);  // TRUE for Tracking.

        // Verify.
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", LocationWhite.Code, Bin.Code, Quantity, LotNo);
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", Item."No.", LocationWhite.Code, LocationWhite."Adjustment Bin Code", -Quantity,
          LotNo);
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", LocationWhite.Code, Bin2.Code, Quantity2, LotNo);
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Negative Adjmt.", Item."No.", LocationWhite.Code, LocationWhite."Adjustment Bin Code", -Quantity2,
          LotNo);

        if CalculateWhseAdjustment then begin
            // Exercise.
            CalculateWarehouseAdjustmentAndPostItemJournalLine(Item);

            // Verify.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", LocationWhite.Code, LocationWhite."Adjustment Bin Code",
              Quantity + Quantity2, LotNo);  // Value required for verification.
        end;

        if RegisterPick then begin
            // Exercise.
            CreateAndRegisterPickFromSalesOrderWithLotItemTracking(SalesHeader, Item."No.", Quantity + Quantity2, LocationWhite.Code);  // Value required for test.

            // Verify.
            VerifyWarehouseEntry(WarehouseEntry."Entry Type"::Movement, Item."No.", LocationWhite.Code, Bin.Code, -Quantity, LotNo);
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Item."No.", LocationWhite.Code, LocationWhite."Shipment Bin Code", Quantity, LotNo);
            VerifyWarehouseEntry(WarehouseEntry."Entry Type"::Movement, Item."No.", LocationWhite.Code, Bin2.Code, -Quantity2, LotNo);
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Item."No.", LocationWhite.Code, LocationWhite."Shipment Bin Code", Quantity2, LotNo);
        end;

        if PostWhseShipment then begin
            // Exercise.
            GetWarehouseShipmentHeader(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
            PostWarehouseShipment(
              WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Quantity + Quantity2, true); // Value required for test.

            // Verify.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Negative Adjmt.", Item."No.", LocationWhite.Code, LocationWhite."Shipment Bin Code",
              -(Quantity + Quantity2), LotNo);  // Value required for verification.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePartialRegisteredWarehousePickAfterPostWarehouseShipment()
    begin
        // [FEATURE] [Pick] [Reservation]
        // [SCENARIO 287748] Test and verify deletion of Pick after posting Warehouse Shipment of registered pick with partial quantity.

        Initialize();
        PostWhseShipmentOfSalesOrderWithReservationAfterDeletePickOfAnotherSalesOrder(false);  // SalesOrderWithReservation as FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentFromSalesOrderWithReservationAfterDeletePick()
    begin
        // [FEATURE] [Warehouse Shipment] [Reservation]
        // [SCENARIO 287748] Test and verify posting Warehouse Shipment of Sales Order with Reservation after deleting Pick of Sales Order without Reservation.

        Initialize();
        PostWhseShipmentOfSalesOrderWithReservationAfterDeletePickOfAnotherSalesOrder(true);  // SalesOrderWithReservation as TRUE.
    end;

    [HandlerFunctions('ReservationPageHandler')]
    local procedure PostWhseShipmentOfSalesOrderWithReservationAfterDeletePickOfAnotherSalesOrder(SalesOrderWithReservation: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // Update Inventory using Warehouse Journal. Post Warehouse Shipment after register Partial Pick from Sales Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        FindPickBin(Bin, LocationWhite.Code);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, Quantity + Quantity, Item."Base Unit of Measure", false);  // Tracking as False. Value required for test.
        PostWarehouseShipmentAfterPartialRegisterPickFromSalesOrder(SalesHeader, Item."No.", Quantity, LocationWhite.Code);

        // Exercise.
        DeletePick(SalesHeader."No.");

        // Verify.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, Item."No.", -Quantity / 2, LocationWhite.Code, '', '');  // Value required for Partial Quantity.

        if SalesOrderWithReservation then begin
            // Exercise.
            CreatePickFromWarehouseShipmentUsingSalesOrder(
              SalesHeader2, SalesHeader."Sell-to Customer No.", Item."No.", Quantity, LocationWhite.Code, true);  // TRUE for Reserve.
            PostWarehouseShipmentAfterRegisterPick(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader2."No.", Quantity, true);

            // Verify.
            VerifyItemLedgerEntryForPostedDocument(
              ItemLedgerEntry."Document Type"::"Sales Shipment", ItemLedgerEntry."Entry Type"::Sale,
              GetSalesShipmentHeader(SalesHeader2."No."), Item."No.", 0, -Quantity);  // Value 0 required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickWithEmailOnCustomerAndContact()
    begin
        // [FEATURE] [Inventory Pick]
        // [SCENARIO 272554] Test and verify Item Ledger Entry after Posting Inventory Pick from Sales Order With Correspondence Type as Email on Contact.

        Initialize();
        CreateAndPostInventoryPickFromSOWithEmail(false, true);  // Show Error as False and Update Email as True.
    end;

    local procedure CreateAndPostInventoryPickFromSOWithEmail(ShowError: Boolean; UpdateEMail: Boolean)
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseRequest: Record "Warehouse Request";
        ItemLedgerEntry: Record "Item Ledger Entry";
        InventoryPick: TestPage "Inventory Pick";
        Quantity: Decimal;
    begin
        // Create Customer and Update Correspondence Type as Email on Customer Contact. Create and post Item Journal Line. Create and Release Sales Order. Create Inventory Pick. Auto Fill Quantity on Inventory Pick.
        Quantity := LibraryRandom.RandDec(10, 2);
        UpdateCorrespondenceTypeAsEMailOnCustomerContact(Customer, Contact);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationOrange.Code, '');
        CreateAndReleaseSalesOrder(SalesHeader, Customer."No.", Item."No.", Quantity, LocationOrange.Code);
        LibraryVariableStorage.Enqueue(InventoryPickMsg);  // Enqueue for MessageHandler.
        CreateInventoryActivity(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true);  // Taking True for Pick.

        if ShowError then begin
            // Exercise.
            OpenInventoryPickPageAndAutoFillQtyToHandle(InventoryPick, SalesHeader."No.");
            asserterror InventoryPick.PostAndPrint.Invoke();

            // Verify: Verify error message.
            Assert.ExpectedError(StrSubstNo(EmailBlankErr, Contact."No."));
        end;

        if UpdateEMail then begin
            // Exercise.
            Customer.Find();
            UpdateEMailOnCustomer(Customer);
            Contact.Find();
            UpdateEmailOnContact(Contact);
            PostInventoryPick(SalesHeader."No.", true);

            // Verify.
            VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Quantity, LocationOrange.Code, '', '');
            VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, Item."No.", -Quantity, LocationOrange.Code, '', '');
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickFromSalesOrderWithShippingAdviceCompleteError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Quantity: Decimal;
    begin
        // [FEATURE] [Pick] [Shipping Advice]
        // [SCENARIO 355218] Test the error message when trying to create partial Warehouse Pick having Shipping Advice Complete in Sales Order.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity, LocationBlue.Code, '');

        // Exercise.
        CreateAndReleaseSalesDocumentShippingAdviceCompletePartToShip(
          SalesHeader, SalesHeader."Document Type"::Order, Item."No.", Quantity, Quantity / 2, LocationBlue.Code);
        Commit();

        // Verify.
        asserterror SalesHeader.CreateInvtPutAwayPick();
        Assert.ExpectedError(ExpectedWarehousePickErrMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateCrossDockOnWarehouseReceiptForWarehouseShipmentUsingSalesOrder()
    begin
        // [FEATURE] [Cross-Docking] [Warehouse Receipt]
        // [SCENARIO 97173] "Calculate Cross-dock" is calculated correctly on Warehouse Receipt when Sales Order is partially shipped and the warehouse shipment was deleted.
        CalculateCrossDockOnWarehouseReceiptForDeletedWarehouseShipment(OutboundDocument::SalesOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculateCrossDockOnWarehouseReceiptForWarehouseShipmentUsingOutboundTransfer()
    begin
        // [FEATURE] [Cross-Docking] [Warehouse Receipt]
        // [SCENARIO 97173] "Calculate Cross-dock" is calculated correctly on Warehouse Receipt when Outbound Transfer is partially shipped and the warehouse shipment was deleted.
        CalculateCrossDockOnWarehouseReceiptForDeletedWarehouseShipment(OutboundDocument::OutboundTransfer);
    end;

    local procedure CalculateCrossDockOnWarehouseReceiptForDeletedWarehouseShipment(OutboundType: Option)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Item. Create and Register Put Away from Warehouse Receipt using Purchase Order.
        // Create another Warehouse Receipt using the 2nd Purchase Order.
        Initialize();
        LocationSetup();
        Quantity := LibraryRandom.RandInt(100);
        Quantity2 := Quantity + LibraryRandom.RandInt(100); // Large value Required for Sales Order and greater than 1st Purchase Order Quantity.
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", Quantity, LocationWhite.Code);
        CreateWarehouseReceiptFromPurchaseOrderWithMultipleItems(
          PurchaseHeader, PurchaseLine, Item."No.", Quantity2, LocationWhite.Code, Item."No.");

        // Create and Register Pick from Warehouse Shipment using Sales Order/ Outbound Transfer.
        case OutboundType of
            OutboundDocument::SalesOrder:
                DeleteWarehouseShipmentAfterPostAndRegisterPickUsingSalesOrder(Item."No.", Quantity2, LocationWhite.Code, Quantity, false); // Partial Ship, Invoice=FALSE.
            OutboundDocument::OutboundTransfer:
                DeleteWarehouseShipmentAfterPostAndRegisterPickUsingTransferOrder(
                  LocationWhite.Code, LocationBlue.Code, Item."No.", Quantity2, Quantity, false); // Partial Ship, Invoice=FALSE.
        end;

        // Exercise: Calculate Cross-Dock on Warehouse Receipt.
        CalculateCrossDock(PurchaseHeader."No.", Item."No.");

        // Verify: Verify Qty. to Cross-Dock is correct on Warehouse Receipt Line.
        VerifyQtyToCrossDockOnWarehouseReceiptLine(PurchaseHeader."No.", Item."No.", Quantity2 - Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcualteCrossDockOnWarehouseReceiptWithMultipleItems()
    begin
        // Setup.
        Initialize();
        CalculateCrossDockOnWarehouseReceiptAndRegisterPutAwayWithMultipleItems(false);  // Register Put Away as FALSE.
    end;

    [Test]
    [HandlerFunctions('HandlePickSelectionPage')]
    [Scope('OnPrem')]
    procedure VerifyPartialPickWithMultipleUOMs()
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        UOMCode: Code[10];
        ExpectedQty: Decimal;
    begin
        // [FEATURE] [Pick Worksheet] [Create Pick] [Breakbulk]
        // [SCENARIO 363148] Verify that "Qty. Outstanding" in a Warehouse Pick line is decreased by actually picked Quantity, when pick requires breakbulk.

        // [GIVEN] Item with two UOMs, "A" with QtyPerUOM = 1, is on stock, "B" with QtyPerOUM < 1, not on stock.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), Item."No.",
          LibraryRandom.RandIntInRange(100, 200), LocationWhite.Code, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWarehouseReceipt(PurchaseHeader);
        CreateAndRegisterPutAwayFromPurchaseOrder(PurchaseHeader."No.", Item."No.", LocationWhite.Code);
        UOMCode := AddItemUOM(Item."No.", LibraryRandom.RandDecInDecimalRange(0.1, 0.5, 1));

        // [GIVEN] Sales order with the item, with UOM "B". Stock is enough.
        ExpectedQty := 2 * LibraryRandom.RandIntInRange(5, 10);
        CreateReleasedSalesOrder(SalesHeader, Item."No.", UOMCode, ExpectedQty, LocationWhite.Code, false);

        // [GIVEN] Create Pick Worksheet line, related to Sales Order.
        CreatePartialPickForWhseShipment(
          SalesHeader, WhseWorksheetName, WhseWorksheetLine, LocationWhite.Code);
        // [GIVEN] Open Pick Worksheet, set partial Qty. to handle.
        WhseWorksheetLine.Validate("Qty. to Handle", WhseWorksheetLine."Qty. Outstanding" / 2);
        WhseWorksheetLine.Modify(true);
        ExpectedQty := WhseWorksheetLine."Qty. Outstanding" - WhseWorksheetLine."Qty. to Handle";
        // [WHEN] Create Pick from Worksheet.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          LocationWhite.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        // [THEN] Outstanding Quantity for the pick line is decreased by picked quantity.
        WhseWorksheetLine.Find();
        Assert.AreEqual(
          ExpectedQty, WhseWorksheetLine."Qty. Outstanding", StrSubstNo(QtyToCrossDockErr, WhseWorksheetLine.FieldCaption("Qty. Outstanding")));
    end;

    [Test]
    [HandlerFunctions('HandlePickSelectionPage')]
    [Scope('OnPrem')]
    procedure VerifyPickWithDifferentUOMs()
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        WarehouseEmployee: Record "Warehouse Employee";
        UOMCode: Code[10];
        QtyPerUOM: Decimal;
        QtyOnStock: Decimal;
        PrevAlwaysCreatePickLine: Boolean;
    begin
        // [FEATURE] [Pick Worksheet] [Create Pick] [Breakbulk]
        // [SCENARIO 363382] "Qty. Outstanding" in a Warehouse Pick line is decreased by actually picked Quantity, when pick requires breakbulk and taken UOM differs from pick line UOM.

        // [GIVEN] Item with two UOMs, "A" with QtyPerUOM = 1, is on stock of quantity X, "B" with QtyPerUOM = 10, not on stock.
        Initialize();

        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite); // Renew white location.

        LibraryInventory.CreateItem(Item);
        QtyPerUOM := LibraryRandom.RandIntInRange(10, 20);
        QtyOnStock := 2 * LibraryRandom.RandIntInRange(10, 50);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), Item."No.",
          QtyOnStock * QtyPerUOM, LocationWhite.Code, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWarehouseReceipt(PurchaseHeader);
        CreateAndRegisterPutAwayFromPurchaseOrder(PurchaseHeader."No.", Item."No.", LocationWhite.Code);
        UOMCode := AddItemUOM(Item."No.", QtyPerUOM);

        // [GIVEN] Sales order with the item, with UOM "B", sale quantity X.
        PrevAlwaysCreatePickLine := UpdateAlwaysCreatePickLine(LocationWhite.Code, true);
        CreateReleasedSalesOrder(SalesHeader, Item."No.", UOMCode, QtyOnStock, LocationWhite.Code, false);

        // [GIVEN] Create Pick Worksheet line, related to Sales Order.
        CreatePartialPickForWhseShipment(
          SalesHeader, WhseWorksheetName, WhseWorksheetLine, LocationWhite.Code);
        // [GIVEN] Open Pick Worksheet, set "Qty. to Handle" to (X / 2).
        WhseWorksheetLine.Validate("Qty. to Handle", QtyOnStock / 2);
        WhseWorksheetLine.Modify(true);
        // [WHEN] Create Pick from Worksheet.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          LocationWhite.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        // [THEN] "Qty. Outstanding" for the pick line is (X / 2).
        WhseWorksheetLine.Find();
        Assert.AreEqual(
          QtyOnStock / 2, WhseWorksheetLine."Qty. Outstanding", StrSubstNo(QtyToCrossDockErr, WhseWorksheetLine.FieldCaption("Qty. Outstanding")));

        // Teardown.
        UpdateAlwaysCreatePickLine(LocationWhite.Code, PrevAlwaysCreatePickLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckRefreshIsNotAllowedIfProdOrderHasReservedCompsWithCalcLinesAndCalcCompsSelected()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Order Tracking] [Manufacturing] [Reservation]
        // [SCENARIO 359388] Order Tracking Policy does Reschedule an existing replenishment instead of Cancel & New. CalcLines and CalcComps checkmarks are selected
        Initialize();

        // [GIVEN] Create Component Item, Parent Item, certified Production BOM assigned to Parent Item and Post Positive Adjustment On Component Item and Reserve Production Order Component
        CreateProdOrderWithReservedComponent(ProductionOrder);

        // [WHEN] Refresh Production Order with reserved components whenever CalcLines and CalcComps checkmarks are selected
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);

        // [THEN] Verify that it is not allowed to refresh Production Order with reserved components whenever CalcLines and CalcComps checkmarks are selected
        VerifyCalcReservedCompError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckRefreshIsNotAllowedIfProdOrderHasReservedCompsWithCalcCompsSelected()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Order Tracking] [Manufacturing] [Reservation]
        // [SCENARIO 359388] Order Tracking Policy does Reschedule an existing replenishment instead of Cancel & New. CalcComps checkmark is selected
        Initialize();

        // [GIVEN] Create Component Item, Parent Item, certified Production BOM assigned to Parent Item and Post Positive Adjustment On Component Item and Reserve Production Order Component
        CreateProdOrderWithReservedComponent(ProductionOrder);

        // [WHEN] Refresh Production Order with reserved components whenever CalcComps checkmark is selected
        asserterror LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, false, true, true, false);

        // [THEN] Verify that it is not allowed to refresh Production Order with reserved components whenever CalcComps checkmark is selected
        VerifyCalcReservedCompError();
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleOnPickWorksheetTakesIntoAccountMaxAvailToPickQtyForSelectedWhseDocLine()
    var
        Item: Record Item;
        WarehouseShipmentHeader: array[2] of Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        SalesOrderNo: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Pick Worksheet] [Reservation]
        // [SCENARIO 212730] "Qty. to Handle" on pick worksheet line generated with "Get Warehouse Documents" function should be populated with consideration of pick availability of a given shipment line.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Sales Order "S1" for "X" pcs of item is reserved from a new purchase order.
        // [GIVEN] Released Warehouse Shipment "WS1" is created from "S1".
        // [GIVEN] Sales Order "S2" for "X" pcs of item is supplied from inventory.
        // [GIVEN] Released Warehouse Shipment "WS2" is created from "S2".
        CreateAndReleaseTwoWhseShipmentsFromSalesOrdersReservedFromInvtAndPurchase(
          WarehouseShipmentHeader, SalesOrderNo, Item, LocationWhite.Code, Qty);

        // [WHEN] Run "Get Warehouse Documents" function in Pick Worksheet.
        GetWarehouseDocumentOnWarehouseWorksheetLine(
          WhseWorksheetName, LocationWhite.Code, WarehouseShipmentHeader[1]."No.", WarehouseShipmentHeader[2]."No.");

        // [THEN] "Qty. to Handle" = 0 on the pick worksheet line representing "WS1".
        VerifyQtyToHandleOnPickWorksheetLine(WhseWorksheetName, LocationWhite.Code, WarehouseShipmentHeader[1]."No.", 0);

        // [THEN] "Qty. to Handle" = "X" on the pick worksheet line representing "WS2".
        VerifyQtyToHandleOnPickWorksheetLine(WhseWorksheetName, LocationWhite.Code, WarehouseShipmentHeader[2]."No.", Qty);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleOnPickWorksheetConsiderReservForDocLineWithEnabledAlwaysCreatePickLine()
    var
        Item: Record Item;
        WarehouseShipmentHeader: array[2] of Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        SalesOrderNo: array[2] of Code[20];
        Qty: Decimal;
        PrevAlwaysCreatePickLine: Boolean;
    begin
        // [FEATURE] [Pick Worksheet] [Reservation]
        // [SCENARIO 225420] When "Always Create Pick Line" is enabled, "Qty. to Handle" on pick worksheet line is 0 for shipment line reserved from outstanding purchase.
        Initialize();

        Qty := LibraryRandom.RandIntInRange(20, 40);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] "Always Create Pick Line" is enabled at location.
        PrevAlwaysCreatePickLine := UpdateAlwaysCreatePickLine(LocationWhite.Code, true);

        // [GIVEN] Sales Order "S1" for "X" pcs of item is reserved from a new purchase order.
        // [GIVEN] Released Warehouse Shipment "WS1" is created from "S1".
        // [GIVEN] Sales Order "S2" for "X" pcs of item is supplied from inventory.
        // [GIVEN] Released Warehouse Shipment "WS2" is created from "S2".
        CreateAndReleaseTwoWhseShipmentsFromSalesOrdersReservedFromInvtAndPurchase(
          WarehouseShipmentHeader, SalesOrderNo, Item, LocationWhite.Code, Qty);

        // [WHEN] Run "Get Warehouse Documents" function in Pick Worksheet.
        GetWarehouseDocumentOnWarehouseWorksheetLine(
          WhseWorksheetName, LocationWhite.Code, WarehouseShipmentHeader[1]."No.", WarehouseShipmentHeader[2]."No.");

        // [THEN] "Qty. to Handle" = 0 on the pick worksheet line representing "WS1".
        VerifyQtyToHandleOnPickWorksheetLine(WhseWorksheetName, LocationWhite.Code, WarehouseShipmentHeader[1]."No.", 0);

        // [THEN] "Qty. to Handle" = "X" on the pick worksheet line representing "WS2".
        VerifyQtyToHandleOnPickWorksheetLine(WhseWorksheetName, LocationWhite.Code, WarehouseShipmentHeader[2]."No.", Qty);

        // Tear down.
        UpdateAlwaysCreatePickLine(LocationWhite.Code, PrevAlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickViaPickWorksheetWithEnabledAlwaysCreatePickLineHasPopulatedBinCodesOnLinesCanBePicked()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseShipmentHeader: array[2] of Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        SalesOrderNo: array[2] of Code[20];
        Qty: Decimal;
        PrevAlwaysCreatePickLine: Boolean;
    begin
        // [FEATURE] [Pick Worksheet] [Warehouse Pick] [Reservation]
        // [SCENARIO 225420] When "Always Create Pick Line" is enabled, Warehouse Pick created via Pick Worksheet has a bin code populated for a shipment that can be picked from inventory and blank bin code for a shipment reserved from outstanding purchase
        Initialize();

        Qty := 20;
        LibraryInventory.CreateItem(Item);

        // [GIVEN] "Always Create Pick Line" is enabled at location.
        PrevAlwaysCreatePickLine := UpdateAlwaysCreatePickLine(LocationWhite.Code, true);

        // [GIVEN] Sales Order "S1" for "X" pcs of item is reserved from a new purchase order.
        // [GIVEN] Released Warehouse Shipment "WS1" is created from "S1".
        // [GIVEN] Sales Order "S2" for "X" pcs of item is supplied from inventory.
        // [GIVEN] Released Warehouse Shipment "WS2" is created from "S2".
        CreateAndReleaseTwoWhseShipmentsFromSalesOrdersReservedFromInvtAndPurchase(
          WarehouseShipmentHeader, SalesOrderNo, Item, LocationWhite.Code, Qty);

        // [GIVEN] Pick Worksheet is populated with "Get Warehouse Documents" function.
        GetWarehouseDocumentOnWarehouseWorksheetLine(
          WhseWorksheetName, LocationWhite.Code, WarehouseShipmentHeader[1]."No.", WarehouseShipmentHeader[2]."No.");

        // [GIVEN] "Qty. to Handle" is updated on Whse. Shipment Line representing shipment "WS1".
        WhseWorksheetLine.SetFilter("Whse. Document No.", WarehouseShipmentHeader[1]."No.");
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationWhite.Code);
        WhseWorksheetLine.Validate("Qty. to Handle", Qty);
        WhseWorksheetLine.Modify(true);

        // [WHEN] Create Warehouse Pick from Pick Worksheet.
        CreatePickFromPickWorksheet(WhseWorksheetName, Item."No.", '''''');

        // [THEN] Bin Code is blank on the pick line for sales order "S1" reserved from outstanding purchase.
        VerifyBinCodeOnWhsePickLine(SalesOrderNo[1], '');

        // [THEN] Bin Code is populated on the pick line for sales order "S2".
        FindPickBin(Bin, LocationWhite.Code);
        VerifyBinCodeOnWhsePickLine(SalesOrderNo[2], Bin.Code);

        // Tear down.
        UpdateAlwaysCreatePickLine(LocationWhite.Code, PrevAlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyToHandleOnPickWorksheetIsZeroWhenAvailQtyToPickNegative()
    var
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Location: Record Location;
        QtyPurchased: Decimal;
        QtyPutaway: Decimal;
        QtyToPick: Decimal;
    begin
        // [FEATURE] [Pick Worksheet] [Reservation]
        // [SCENARIO 223551] When item's reserved quantity is greater than quantity located in pick bins, it's still possible to pick the available quantity.
        Initialize();
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(Location);

        LibraryInventory.CreateItem(Item);

        QtyPurchased := LibraryRandom.RandIntInRange(100, 200);
        QtyPutaway := LibraryRandom.RandIntInRange(20, 40);
        QtyToPick := LibraryRandom.RandInt(20);

        // [GIVEN] Posted purchase receipt for 200 pcs of item "I".
        // [GIVEN] Partially registered put-away for 40 pcs.
        CreateAndRegisterPartialPutAwayFromWarehouseReceiptUsingPurchaseOrder(
          Item."No.", QtyPurchased, Location.Code, QtyPutaway);

        // [GIVEN] Reserved sales order "SO1" for 60 pcs of "I" (more than has been put-away).
        // [GIVEN] Part of reserved inventory is now located in Receive zone.
        CreateReleasedSalesOrder(
          SalesHeader, Item."No.", Item."Base Unit of Measure", QtyPutaway + QtyToPick, Location.Code, true);

        // [GIVEN] Reserved sales order "SO2" with released warehouse shipment for 20 pcs of "I".
        CreateReleasedSalesOrder(
          SalesHeader, Item."No.", Item."Base Unit of Measure", QtyToPick, Location.Code, true);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Run "Get Warehouse Documents" function in Pick Worksheet. Select the warehouse shipment for "SO2".
        GetWarehouseDocumentOnWarehouseWorksheetLine(WhseWorksheetName, Location.Code, WarehouseShipmentHeader."No.", '''''');

        // [THEN] "Qty. to Handle" = 20 on the pick worksheet.
        VerifyQtyToHandleOnPickWorksheetLine(WhseWorksheetName, Location.Code, WarehouseShipmentHeader."No.", QtyToPick);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TrackingChangedToSurplusAfterPostingInvntoryPickTrackingEntryPointsToTransfer()
    var
        TransferRoute: Record "Transfer Route";
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        Bin: Record Bin;
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        Qty: Decimal;
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO] Reservation status should be changed from "Tracking" to "Surplus" on the supply side when the outbound entry is supplied from inventory, and tracking points to a transfer order.

        Initialize();

        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, LocationBlue.Code, LocationSilver.Code, LocationInTransit.Code, '', '');
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, '', '', '');
        // [GIVEN] Item "I" with lot tracking and lot warehouse tracking enabled
        CreateItemWithItemTrackingCode(Item, true, false, '', '');

        // [GIVEN] Stockkeeping unit for item "I" on "SILVER" location with replenishment as a transfer from the "BLUE" location
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationSilver.Code, Item."No.", '');
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::"Lot-for-Lot");
        SKU.Validate("Replenishment System", SKU."Replenishment System"::Transfer);
        SKU.Validate("Transfer-from Code", LocationBlue.Code);
        SKU.Modify(true);

        // [GIVEN] Stockkeeping unit for item "I" with purchase replenishment
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationBlue.Code, Item."No.", '');
        SKU.Validate("Reordering Policy", SKU."Reordering Policy"::"Lot-for-Lot");
        SKU.Validate("Replenishment System", SKU."Replenishment System"::Purchase);
        SKU.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        SKU.Modify(true);

        Qty := LibraryRandom.RandInt(100);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Sales order for item "I" on "SILVER" location. "Quantity" = 10.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", Qty, LocationSilver.Code, 0D);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Calulate requisition plan for "I" and carry out.
        // [GIVEN] This creates a purchase order on the "BLUE" location and a transfer order from "BLUE" to "SILVER", both having item tracking entries with undefined lot no.
        CalculateRegenPlanAndCarryOutActionMessage(Item, WorkDate(), WorkDate());

        // [GIVEN] Create stock of item "I" on both locations "BLUE" and "SILVER" with "Lot No." = "L".
        PostInventoryAdjustmentWithTracking(Item."No.", LocationSilver.Code, Bin.Code, Qty, LotNo);
        PostInventoryAdjustmentWithTracking(Item."No.", LocationBlue.Code, '', Qty, LotNo);

        // [GIVEN] Assign lot no. "L" to the transfer shipment and post shipment from the transfer order. Posting moves tracking info into tracking entries linked to the receipt side.
        TransferLine.SetRange("Item No.", Item."No.");
        TransferLine.FindLast();
        EnqueTrackingParameters(ItemTrackingMode::AssignManualLotNo, LotNo, Qty);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Create inventory pick from the sales order and set "Lot No." = "L".
        LibraryVariableStorage.Enqueue(InventoryPickMsg);
        LibraryWarehouse.CreateInvtPutPickMovement(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        UpdateLotNosOnInventoryPick(SalesHeader."No.", LotNo);

        // [WHEN] Post the inventory pick.
        PostInventoryPick(SalesHeader."No.", false);

        // [THEN] 10 pcs item "I" are tracked on the transfer order, "Lot No." = "L". Reservation status has been changed to "Surplus".
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Surplus, Item."No.", DATABASE::"Transfer Line", LocationSilver.Code, LotNo, Qty, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TrackingDeletedAfterPostingInvntoryPickTrackingEntryPointsToInventory()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseRequest: Record "Warehouse Request";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO] Reservation entry should be deleted when posting the inventory pick, and the tracking point to item ledger entry.

        Initialize();

        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, '', '', '');

        // [GIVEN] Item "I" with lot tracking and lot warehouse tracking enabled
        CreateItemWithItemTrackingCode(Item, true, false, '', '');
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Sales order for item "I" on "SILVER" location. "Quantity" = 10.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.",
          LibraryRandom.RandInt(100), LocationSilver.Code, 0D);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Calulate requisition plan for "I" and carry out.
        // [GIVEN] This creates a purchase order on the "SILVER" location with item tracking entries having undefined lot no.
        CalculateRegenPlanAndCarryOutActionMessage(Item, WorkDate(), WorkDate());

        // [GIVEN] Set "Lot No." = "L" on the purchase line and post purchase. Tracking entry receives "Lot No." = "L" and links the sales line with the item ledger entry.
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        UpdateBinCodeOnPurchaseLine(PurchaseLine, Bin.Code);

        EnqueTrackingParameters(ItemTrackingMode::AssignManualLotNo, LotNo, PurchaseLine.Quantity);
        PurchaseLine.OpenItemTrackingLines();

        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create inventory pick from the sales order and set "Lot No." = "L".
        LibraryVariableStorage.Enqueue(InventoryPickMsg);
        LibraryWarehouse.CreateInvtPutPickMovement(WarehouseRequest."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);
        UpdateLotNosOnInventoryPick(SalesHeader."No.", LotNo);

        // [WHEN] Post the inventory pick.
        PostInventoryPick(SalesHeader."No.", false);

        // [THEN] All tracking entries are deleted.
        ReservationEntry.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('CrossDockOpportunitiesPageHandler')]
    [Scope('OnPrem')]
    procedure CrossDocOpportunitiesListNotFilteredOnWhseReceiptLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WhseReceiptSubform: TestPage "Whse. Receipt Subform";
        Qty: Decimal;
    begin
        // [FEATURE] [Cross-Docking] [Warehouse] [Warehouse Receipt]
        // [SCENARIO 224091] Lookup action in the field "Qty. to Cross-Dock" of the page "Whse. Receipt Subform" should show all cross-dock opportunities related to the receipt, without a filter on line no.

        Initialize();

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location "L" with "Use Cross-Docking" option enabled
        // [GIVEN] Purchase order on the location "L". Order has 2 lines: first line for 10 pcs of item "I", second line - for 30 pcs.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        Qty := LibraryRandom.RandInt(20);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", Qty, LocationWhite.Code, false);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, Item."No.", Qty * 3, LocationWhite.Code, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Sales order on location "L". Two lines, both for 15 pcs of item "I".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", (Qty * 4) / 2, LocationWhite.Code);
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", (Qty * 4) / 2, LocationWhite.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse receipt from the purchase order and calculate cross-dock lines.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", Item."No.");
        LibraryWarehouse.CalculateCrossDockLines(
          WhseCrossDockOpportunity, '', WarehouseReceiptLine."No.", WarehouseReceiptLine."Location Code");

        // [WHEN] Select the first warehouse receipt line and invoke lookup on the "Qty. to Cross-Doc" field
        LibraryVariableStorage.Enqueue(2);
        WhseReceiptSubform.OpenView();
        WhseReceiptSubform.GotoRecord(WarehouseReceiptLine);
        WhseReceiptSubform."Qty. to Cross-Dock".Lookup();

        // [THEN] Page "Cross-Dock Opportunities" is displayed. The list contains two records.
        // Verified in CrossDockOpportunitiesPageHandler

        // [WHEN] Select the second warehouse receipt line and invoke lookup on the "Qty. to Cross-Doc" field
        LibraryVariableStorage.Enqueue(2);
        WarehouseReceiptLine.Next();
        WhseReceiptSubform.GotoRecord(WarehouseReceiptLine);
        WhseReceiptSubform."Qty. to Cross-Dock".Lookup();

        // [THEN] Page "Cross-Dock Opportunities" is displayed. The list contains two records.
        // Verified in CrossDockOpportunitiesPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockOpportunityForServiceLine()
    var
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        Qty: Decimal;
        ItemNo: Code[20];
    begin
        // [FEATURE] [Cross-Docking] [Service] [Warehouse Receipt]
        // [SCENARIO 231537] Cross-Dock calculation on warehouse receipt considers service lines with matching item, location and needed date.
        Initialize();

        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Item "I".
        ItemNo := LibraryInventory.CreateItemNo();

        // [GIVEN] Service Order.
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        // [GIVEN] Five service lines, quantity on each line = "Q":
        // [GIVEN] two lines with item "I", location = "White", and "Needed by Date" is within the cross-docking period;
        // [GIVEN] each of other three lines are either with another item, another location, or the date is outside the cross-docking period.
        CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceItemLine."Line No.", LibraryInventory.CreateItemNo(), LocationWhite.Code, WorkDate(), Qty); // item <> "I"
        CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceItemLine."Line No.", ItemNo, LocationWhite.Code, WorkDate(), Qty); // item = "I", location = "White", date in cross-docking period
        CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceItemLine."Line No.", ItemNo, LocationSilver.Code, WorkDate(), Qty); // location <> "White"
        CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceItemLine."Line No.", ItemNo, LocationWhite.Code, LibraryRandom.RandDate(10), Qty); // date outside the cross-docking period
        CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceItemLine."Line No.", ItemNo, LocationWhite.Code, WorkDate(), Qty); // item = "I", location = "White", date in cross-docking period

        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [GIVEN] Sales Order with item = "I", location = "White", receipt date = WorkDate(), quantity = "Q".
        CreateAndReleaseSalesOrder(SalesHeader, ServiceItem."Customer No.", ItemNo, Qty, LocationWhite.Code);

        // [GIVEN] Released Purchase Order with item = "I", location = "White", receipt date = WorkDate(), quantity is large enough to supply both the service and the sales orders.
        // [GIVEN] Warehouse receipt is created for the order.
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemNo,
          LibraryRandom.RandIntInRange(100, 200), LocationWhite.Code, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWarehouseReceipt(PurchaseHeader);

        // [WHEN] Calculate cross-dock on the receipt line.
        CalculateCrossDock(PurchaseHeader."No.", ItemNo);

        // [THEN] "Qty. to Cross-Dock" on the whse. receipt line is equal to 3 * "Q" (2 * "Q" for the service, "Q" for the sales).
        VerifyQtyToCrossDockOnWarehouseReceiptLine(PurchaseHeader."No.", ItemNo, 3 * Qty);

        // [THEN] Two Whse. Cross-Dock Opportunitity records are created for the service order.
        WhseCrossDockOpportunity.SetRange("To Source Document", WhseCrossDockOpportunity."To Source Document"::"Service Order");
        WhseCrossDockOpportunity.SetRange("To Source No.", ServiceHeader."No.");
        WhseCrossDockOpportunity.SetRange("Item No.", ItemNo);
        Assert.RecordCount(WhseCrossDockOpportunity, 2);

        // [THEN] "Qty. to Cross-Dock" for each Whse. Cross-Dock Opp. is equal to "Q".
        WhseCrossDockOpportunity.FindSet();
        repeat
            WhseCrossDockOpportunity.AutoFillQtyToCrossDock(WhseCrossDockOpportunity);
            WhseCrossDockOpportunity.Find();
            WhseCrossDockOpportunity.TestField("Qty. to Cross-Dock", Qty);
        until WhseCrossDockOpportunity.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CrossDockOpportunityForPartiallyPickedServiceLine()
    var
        Location: Record Location;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        ServLineQty: Decimal;
        AvailToPickQty: Decimal;
    begin
        // [FEATURE] [Cross-Docking] [Service] [Warehouse Receipt] [Pick]
        // [SCENARIO 231537] Quantity to cross-dock on warehouse receipt for service line is calculated only for the quantity that has not been picked.
        Initialize();

        ServLineQty := LibraryRandom.RandIntInRange(30, 60);
        AvailToPickQty := LibraryRandom.RandIntInRange(20, 40);
        ItemNo := LibraryInventory.CreateItemNo();

        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Posted purchase order with registered put-away for "q" pcs.
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(ItemNo, AvailToPickQty, Location.Code);

        // [GIVEN] Service order with two service lines, each for ("Q" / 2) pcs. Overall demand for the service order is "Q" > "q".
        LibraryService.CreateServiceItem(ServiceItem, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, ServiceItem."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItemLine."Line No.", ItemNo, Location.Code, WorkDate(), ServLineQty);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItemLine."Line No.", ItemNo, Location.Code, WorkDate(), ServLineQty);
        LibraryService.ReleaseServiceDocument(ServiceHeader);

        // [GIVEN] Warehouse shipment and pick for the service order. Picked quantity = "q". Quantity remaining to pick = "Q" - "q".
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Service Order", ServiceHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Service Order", ServiceHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Another purchase order with quantity large enough to supply the service order.
        // [GIVEN] Warehouse receipt is created for the order.
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemNo,
          LibraryRandom.RandIntInRange(200, 400), Location.Code, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWarehouseReceipt(PurchaseHeader);

        // [WHEN] Calculate quantity to cross-dock on the warehouse receipt.
        CalculateCrossDock(PurchaseHeader."No.", ItemNo);

        // [THEN] "Qty. to Cross-Dock" = quantity remaining to pick = "Q" - "q".
        VerifyQtyToCrossDockOnWarehouseReceiptLine(PurchaseHeader."No.", ItemNo, ServLineQty * 2 - AvailToPickQty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceItemsAreExcludedFromShippingAdviceCompleteCheck()
    var
        ServiceTypeItem: Record Item;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        CheckIsSuccessful: Boolean;
    begin
        // [FEATURE] [Sales] [Shipping Advice] [Item Type]
        // [SCENARIO 269062] Items with Type = Service do not interfere to the check of sales order with Shipping Advice = Complete.
        Initialize();

        // [GIVEN] Item "SI" with Type = Service, item "I" with Type = Inventory.
        LibraryInventory.CreateServiceTypeItem(ServiceTypeItem);
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Item "I" is in inventory on location "L".
        CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandIntInRange(50, 100), LocationBlue.Code, '');

        // [GIVEN] Sales order with "Shipping Advice" = Complete.
        // [GIVEN] The order has two lines -
        // [GIVEN] the first line is for item "SI" on blank location;
        // [GIVEN] the second line is for item "I" on location "L".
        CreateSalesHeaderWithShippingAdviceAsComplete(SalesHeader, SalesHeader."Document Type"::Order);
        CreateSalesLine(SalesHeader, SalesLine, ServiceTypeItem."No.", LibraryRandom.RandInt(10), '');
        CreateSalesLine(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandInt(10), LocationBlue.Code);

        // [WHEN] Invoke "CheckSalesHeader" function to verify shipping advice requirements.
        CheckIsSuccessful := not GetSourceDocOutbound.CheckSalesHeader(SalesHeader, false);

        // [THEN] The verification completes successfully.
        Assert.IsTrue(CheckIsSuccessful, 'Complete shipping advice check failed.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnShippingAdviceCompleteCheckIfLocationCodesAreDifferentOnInventoryItems()
    var
        ServiceTypeItem: Record Item;
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
        CheckIsSuccessful: Boolean;
    begin
        // [FEATURE] [Sales] [Shipping Advice] [Item Type]
        // [SCENARIO 269062] Complete shipping advice check fails if sales order has inventory-typed item lines with different location codes.
        Initialize();

        // [GIVEN] Item "SI" with Type = Service, items "I1", "I2" with Type = Inventory.
        // [GIVEN] Item "I1" is in inventory on location "L", item "I2" is in inventory on blank location.
        LibraryInventory.CreateServiceTypeItem(ServiceTypeItem);
        LibraryInventory.CreateItem(Item[1]);
        CreateAndPostItemJournalLine(Item[1]."No.", LibraryRandom.RandIntInRange(50, 100), LocationBlue.Code, '');
        LibraryInventory.CreateItem(Item[2]);
        CreateAndPostItemJournalLine(Item[2]."No.", LibraryRandom.RandIntInRange(50, 100), '', '');

        // [GIVEN] Sales order with "Shipping Advice" = Complete.
        // [GIVEN] The order has three lines -
        // [GIVEN] the first line is for item "SI" on blank location;
        // [GIVEN] the second line is for item "I1" on location "L";
        // [GIVEN] the third line is for item "I2" on blank location.
        // [GIVEN] Note that the location codes on the first and third items are same.
        CreateSalesHeaderWithShippingAdviceAsComplete(SalesHeader, SalesHeader."Document Type"::Order);
        CreateSalesLine(SalesHeader, SalesLine, ServiceTypeItem."No.", LibraryRandom.RandInt(10), '');
        CreateSalesLine(SalesHeader, SalesLine, Item[1]."No.", LibraryRandom.RandInt(10), LocationBlue.Code);
        CreateSalesLine(SalesHeader, SalesLine, Item[2]."No.", LibraryRandom.RandInt(10), '');

        // [WHEN] Invoke "CheckSalesHeader" function to verify shipping advice requirements.
        CheckIsSuccessful := not GetSourceDocOutbound.CheckSalesHeader(SalesHeader, false);

        // [THEN] The verification failed, as the inventory item lines "I1" and "I2" have different location codes.
        Assert.IsFalse(CheckIsSuccessful, 'Complete shipping advice check must fail.');
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure LotTrackingItemWithTwoSalesOrders()
    var
        Item: Record Item;
        BinWhite: Record Bin;
        Bin: array[4] of Record Bin;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        Quantity: array[4] of Decimal;
        LotNo: array[4] of Code[20];
        SalesQty1: Decimal;
        SalesQty2: Decimal;
        AdjmtQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Untracked Surplus]
        // [SCENARIO 286154] Posting warehouse entries for item with "Order Tracking Policy" = "Tracking Only" when residual surplus exists
        // [SCENARIO 286154] Quantity is adjusted from warehouse and item journals.
        Initialize();
        SkipManualReservation();

        // [GIVEN] Item with "Order Tracking Policy" = "Tracking Only"
        InitItemQuantityForResidualSales(Quantity, SalesQty1, SalesQty2);
        CreateItemWithItemTrackingCodeAndOrderTrackingForLot(Item);

        // [GIVEN] Posted warehouse and item entries for "Bin1"/"Lot1"/Quantity = 60
        // [GIVEN] Posted warehouse and item entries for "Bin2"/"Lot2"/Quantity = 120
        // [GIVEN] Posted warehouse and item entries for "Bin3"/"Lot3"/Quantity = 180
        // [GIVEN] Posted warehouse and item entries for "Bin4"/"Lot4"/Quantity = 180
        FindPickBin(BinWhite, LocationWhite.Code);
        for i := 1 to ArrayLen(Bin) do begin
            LibraryWarehouse.CreateBin(
              Bin[i], LocationWhite.Code, LibraryUtility.GenerateGUID(), BinWhite."Zone Code", BinWhite."Bin Type Code");
            LotNo[i] := UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item, Bin[i], Quantity[i], Item."Base Unit of Measure");
        end;

        // [GIVEN] Sales Order 1 with Quantity = 120 auto-reserved and relesed
        // [GIVEN] Reserved: "Lot1"/Quantity = 60; "Lot2"/Quantity = 60;
        CreateAndReleaseSalesOrderWithReserve(SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", SalesQty1, LocationWhite.Code);

        // [GIVEN] Sales Order 2 with Quantity = 800 auto-reserved and relesed
        // [GIVEN] Reserved: "Lot2"/Quantity = 60; "Lot3"/Quantity = 180; "Lot4"/Quantity = 180;  residual surplus = -380
        CreateAndReleaseSalesOrderWithReserve(SalesHeader2, LibrarySales.CreateCustomerNo(), Item."No.", SalesQty2, LocationWhite.Code);

        // [GIVEN] Registered warehouse pick and shipment for Sales Order 1 with "Lot4", Quantity = 120
        // [GIVEN] Reserved for Sales Order 2: "Lot1"/Quantity = 60; "Lot2"/Quantity = 120; "Lot3"/Quantity = 180; "Lot4"/Quantity = 60;  residual surplus = -380
        RegisterWarehousePickAndPostWarehouseShipment(SalesHeader, LotNo[4]);

        // [GIVEN] Register warehouse pick and shipment for Sales Order 2 with Quantity 400
        RegisterWarehousePickAndPostWarehouseShipmentSomeLines(SalesHeader2, Bin, LotNo);

        // [GIVEN] Sales Order 1 and Sales Order 2 are invoiced
        SalesHeader.Find();
        SalesHeader2.Find();
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        LibrarySales.PostSalesDocument(SalesHeader2, false, true);

        // [GIVEN] Residual surplus has Quantity = -380
        VerifyReservationEntriesResidualSurplus(
          Item."No.",
          Quantity[1] + Quantity[2] + Quantity[3] + Quantity[4] - SalesQty1 - SalesQty2);

        // [GIVEN] Additional warehouse adjustment is posted with Quantity = 100
        AdjmtQty := LibraryRandom.RandIntInRange(10, 20);
        LotNo[4] := UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item, Bin[4], AdjmtQty, Item."Base Unit of Measure");
        LibrarySales.ReopenSalesDocument(SalesHeader2);
        SalesLine2.SetRange("Document Type", SalesHeader2."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader2."No.");
        SalesLine2.FindFirst();
        LibrarySales.AutoReserveSalesLine(SalesLine2);
        LibrarySales.ReleaseSalesDocument(SalesHeader2);

        // [WHEN] Register warehouse pick and shipment for Sales Order 2 with quantity 100
        RegisterWarehousePickAndPostWarehouseShipment(SalesHeader2, LotNo[4]);

        // [THEN] Residual surplus has Quantity = -280
        VerifyReservationEntriesResidualSurplus(
          Item."No.",
          Quantity[1] + Quantity[2] + Quantity[3] + Quantity[4] + AdjmtQty - SalesQty1 - SalesQty2);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ProductionJournalOutputHandler,ItemTrackingPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LotTrackingItemWithTwoSalesOrdersFromProdOrder()
    var
        Item: Record Item;
        BinWhite: Record Bin;
        Bin: array[4] of Record Bin;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderLineList: TestPage "Prod. Order Line List";
        Quantity: array[4] of Decimal;
        LotNo: array[4] of Code[20];
        SalesQty1: Decimal;
        SalesQty2: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Untracked Surplus]
        // [SCENARIO 286154] Posting warehouse entries for item with "Order Tracking Policy" = "Tracking Only" when residual surplus exists
        // [SCENARIO 286154] Quantity is adjusted from warehouse and item journals and production order
        Initialize();
        SkipManualReservation();

        // [GIVEN] Item with "Order Tracking Policy" = "Tracking Only"
        InitItemQuantityForResidualSales(Quantity, SalesQty1, SalesQty2);
        CreateItemWithItemTrackingCodeAndOrderTrackingForLot(Item);

        // [GIVEN] Posted warehouse and item entries for "Bin1"/"Lot1"/Quantity = 60
        // [GIVEN] Posted warehouse and item entries for "Bin2"/"Lot2"/Quantity = 120
        // [GIVEN] Posted warehouse and item entries for "Bin3"/"Lot3"/Quantity = 180
        FindPickBin(BinWhite, LocationWhite.Code);
        for i := 1 to ArrayLen(Bin) - 1 do begin
            LibraryWarehouse.CreateBin(
              Bin[i], LocationWhite.Code, LibraryUtility.GenerateGUID(), BinWhite."Zone Code", BinWhite."Bin Type Code");
            LotNo[i] := UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item, Bin[i], Quantity[i], Item."Base Unit of Measure");
        end;
        // [GIVEN] "Lot4"/"Bin4" for Prod. Order created
        LibraryWarehouse.CreateBin(Bin[4], LocationWhite.Code, LibraryUtility.GenerateGUID(), BinWhite."Zone Code", BinWhite."Bin Type Code");
        LotNo[4] := LibraryUtility.GenerateGUID();

        // [GIVEN] Sales Order 1 with Quantity = 120 auto-reserved and relesed
        // [GIVEN] Reserved: "Lot1"/Quantity = 60; "Lot2"/Quantity = 60;
        CreateAndReleaseSalesOrderWithReserve(SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", SalesQty1, LocationWhite.Code);

        // [GIVEN] Posted production order for "Bin4"/"Lot4"/Quantity = 180
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Quantity[4]);
        ProductionOrder.Validate("Location Code", LocationWhite.Code);
        ProductionOrder.Validate("Bin Code", Bin[4].Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.CreateProdOrderLine(
          ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.", Item."No.", '', LocationWhite.Code, Quantity[4]);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
        ProdOrderLineList.OpenEdit();
        ProdOrderLineList.FILTER.SetFilter("Item No.", Item."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignManualLotNo);
        LibraryVariableStorage.Enqueue(LotNo[4]);
        LibraryVariableStorage.Enqueue(Quantity[4]);
        ProdOrderLineList.ShowTrackingLines.Invoke();
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Sales Order 2 with Quantity = 800 auto-reserved and relesed
        // [GIVEN] Reserved: "Lot2"/Quantity = 60; "Lot3"/Quantity = 180; "Lot4"/Quantity = 180;  residual surplus = -380
        CreateAndReleaseSalesOrderWithReserve(SalesHeader2, LibrarySales.CreateCustomerNo(), Item."No.", SalesQty2, LocationWhite.Code);

        // [GIVEN] Registered warehouse pick and shipment for Sales Order 1 with "Lot4", Quantity = 120
        // [GIVEN] Reserved for Sales Order 2: "Lot1"/Quantity = 60; "Lot2"/Quantity = 120; "Lot3"/Quantity = 180; "Lot4"/Quantity = 60;  residual surplus = -380
        RegisterWarehousePickAndPostWarehouseShipment(SalesHeader, LotNo[4]);

        // [GIVEN] Register warehouse pick and shipment for Sales Order 2 with Quantity 400
        RegisterWarehousePickAndPostWarehouseShipmentSomeLines(SalesHeader2, Bin, LotNo);

        // [WHEN] Sales Order 1 and Sales Order 2 are invoiced
        SalesHeader.Find();
        SalesHeader2.Find();
        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        LibrarySales.PostSalesDocument(SalesHeader2, false, true);

        // [THEN] Residual surplus has Quantity = -380
        VerifyReservationEntriesResidualSurplus(
          Item."No.",
          Quantity[1] + Quantity[2] + Quantity[3] + Quantity[4] - SalesQty1 - SalesQty2);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure LotTrackingItemWithPlanningWorksheet()
    var
        Item: Record Item;
        BinWhite: Record Bin;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
        SalesQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Untracked Surplus]
        // [SCENARIO 286154] Caculate and delete reqiusition line for item with "Order Tracking Policy" = "Tracking Only" when residual surplus exists
        Initialize();
        SkipManualReservation();

        // [GIVEN] Item with "Order Tracking Policy" = "Tracking Only"
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        SalesQty := Quantity + LibraryRandom.RandInt(100);
        CreateItemWithItemTrackingCodeAndOrderTrackingForLot(Item);

        // [GIVEN] Posted warehouse and item entries for "Bin1"/"Lot1"/Quantity = 60
        FindPickBin(BinWhite, LocationWhite.Code);
        LibraryWarehouse.CreateBin(
          Bin, LocationWhite.Code, LibraryUtility.GenerateGUID(), BinWhite."Zone Code", BinWhite."Bin Type Code");
        UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item, Bin, Quantity, Item."Base Unit of Measure");

        // [GIVEN] Sales Order with Quantity = 200 auto-reserved and relesed
        CreateAndReleaseSalesOrderWithReserve(SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", SalesQty, LocationWhite.Code);

        // [GIVEN] Calculate requisition plan for the item
        LibraryPlanning.CalcRequisitionPlanForReqWksh(Item, WorkDate(), WorkDate());
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();

        // [WHEN] Delete requisition line
        RequisitionLine.Delete(true);

        // [THEN] Residual surplus has Quantity = -140
        VerifyReservationEntriesResidualSurplus(Item."No.", Quantity - SalesQty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,WhseItemTrackingLinesHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ReservationEntryForLotAndOrderTrackedItemWhenCreatePickFromWhseShipment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BinWhite: Record Bin;
        Bin: Record Bin;
        Quantity: array[3] of Integer;
        LotNo: array[3] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Item Tracking] [Order Tracking]
        // [SCENARIO 299300] Reservation Entry has correct Qty. to Handle (Base) when Warehouse Pick is created for Item with Lot and Order tracking
        // [SCENARIO 299300] even if Stan has reset Item Tracking in Sales Order
        Initialize();
        Quantity[1] := LibraryRandom.RandInt(10);
        Quantity[2] := Quantity[1] + LibraryRandom.RandInt(10);
        Quantity[3] := Quantity[1] + Quantity[2] + LibraryRandom.RandInt(10);

        // [GIVEN] Item with Lot Tracking and Order Tracking Enabled
        CreateItemWithItemTrackingCodeAndOrderTrackingForLot(Item);

        // [GIVEN] Released Sales Order with 4 PCS of the Item
        CreateAndReleaseSalesOrder(SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", Quantity[3], LocationWhite.Code);

        // [GIVEN] Registered Warehouse Item Journal and posted Whse Adjustment for the Item with lots:
        // [GIVEN] Lot "L1" Qty = 2, Lot "L2" Qty = 3, Lot "L3" Qty = 4 (Reservation Entries for Lots "L1" and "L2" had Status updated to Tracking)
        FindPickBin(BinWhite, LocationWhite.Code);
        LibraryWarehouse.CreateBin(Bin, LocationWhite.Code, LibraryUtility.GenerateGUID(), BinWhite."Zone Code", BinWhite."Bin Type Code");
        for Index := 1 to ArrayLen(LotNo) do
            LotNo[Index] := UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item, Bin, Quantity[Index], Item."Base Unit of Measure");

        // [GIVEN] Stan set Item Tracking for Sales Order with Lot "L3" Qty = 4 (Reservation Entry for Lot "L3" created with Quantity = -4)
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        EnqueTrackingParameters(ItemTrackingMode::AssignManualLotNo, LotNo[3], Quantity[3]);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Stan cleared Item Tracking for Sales Order
        EnqueTrackingParameters(ItemTrackingMode::AssignManualLotNo, '', 0);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Stan set Item Tracking for Sales Order with Lot "L3" Qty = 4 (Two Reservation Entry for Lot "L3" created with total Quantity = -4)
        EnqueTrackingParameters(ItemTrackingMode::AssignManualLotNo, LotNo[3], Quantity[3]);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Created Warehouse Shipment from Sales Order
        CreateAndReleaseWhseShipment(SalesHeader);

        // [WHEN] Create Pick from Warehouse Shipment
        CreatePickUsingSalesOrder(SalesHeader."No.");

        // [THEN] Qty. to Handle (Base) = Qty. to Invoice (Base) = Quantity (Base) in each Reservation Entry for the Item and Lot "L3"
        VerifyReservationEntryQtyToHandleAndInvoiceForItemAndLot(Item."No.", LotNo[3]);

        // [THEN] Total Quantity in Positive Reservation Entries for Item and Lot "L3" equals to 4, total Quantity in Negative Reservation Entries equals to -4
        VerifyReservationEntryPositiveNegativeQtyForItemAndLot(Item."No.", LotNo[3], Quantity[3]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure ErrorWhenRegisterWhsePickWithWrongLotNo()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BinWhite: Record Bin;
        Bin: Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: array[2] of Integer;
        LotNo: array[2] of Code[20];
        Index: Integer;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO 303605] Error is displayed when trying to register Warehouse Pick with Lot No which doesn't match Source Lot No
        Initialize();
        Quantity[1] := LibraryRandom.RandInt(10);
        Quantity[2] := LibraryRandom.RandInt(10);

        // [GIVEN] Item with Lot Tracking Enabled
        CreateItemWithItemTrackingCodeAndOrderTrackingForLot(Item);

        // [GIVEN] Registered Warehouse Item Journal and posted Whse Adjustment for the Item with lots "L1" Qty = 4, Lot "L2" Qty = 3
        FindPickBin(BinWhite, LocationWhite.Code);
        LibraryWarehouse.CreateBin(Bin, LocationWhite.Code, LibraryUtility.GenerateGUID(), BinWhite."Zone Code", BinWhite."Bin Type Code");
        for Index := 1 to ArrayLen(LotNo) do
            LotNo[Index] := UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item, Bin, Quantity[Index], Item."Base Unit of Measure");

        // [GIVEN] Released Sales Order 1001 with 3 PCS of the Item (Sales Line had No. = 10000)
        CreateAndReleaseSalesOrder(SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", Quantity[2], LocationWhite.Code);

        // [GIVEN] Stan set Item Tracking for Sales Order with Lot "L2" Qty = 3
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        EnqueTrackingParameters(ItemTrackingMode::AssignManualLotNo, LotNo[2], Quantity[2]);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Created Warehouse Shipment from Sales Order
        CreateAndReleaseWhseShipment(SalesHeader);

        // [GIVEN] Created Pick from Warehouse Shipment
        CreatePickUsingSalesOrder(SalesHeader."No.");

        // [GIVEN] Modified Lot No = "L1" in both Warehouse Activity Lines
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo[1]);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Register Pick
        asserterror LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Error "Item Tracking defined for the Source Line 10000 of Sales Order 1001 accounts for more than the quantity you have entered."
        Assert.ExpectedError(
          StrSubstNo(InsufficientQtyItemTrkgErr, SalesLine."Line No.", WarehouseActivityLine."Source Document", SalesHeader."No."));
        Assert.ExpectedErrorCode(DialogCodeErr);
    end;

    [Test]
    [HandlerFunctions('CrossDockOpportunitiesPageHandler')]
    [Scope('OnPrem')]
    procedure LookingUpQtyToCrossDockShowsOpportunitiesFilteredByItem()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WhseReceiptSubform: TestPage "Whse. Receipt Subform";
        Qty: Decimal;
    begin
        // [FEATURE] [Cross-Docking] [Warehouse Receipt]
        // [SCENARIO 338228] Looking up "Qty. to Cross-Dock" on warehouse receipt line shows cross-dock opportunities filtered by item no.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Use location set up for directed put-away and pick.
        // [GIVEN] Items "A" and "B".
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Sales order with two item lines - "A" and "B".
        // [GIVEN] Release the sales order and create warehouse shipment.
        CreateSalesHeaderWithShipmentDate(SalesHeader, LibrarySales.CreateCustomerNo(), WorkDate());
        CreateSalesLine(SalesHeader, SalesLine, Item[1]."No.", Qty, LocationWhite.Code);
        CreateSalesLine(SalesHeader, SalesLine, Item[2]."No.", Qty, LocationWhite.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Purchase order with the same item lines as the sales order.
        // [GIVEN] Release the purchase order and create warehouse receipt.
        CreateWarehouseReceiptFromPurchaseOrderWithMultipleItems(
          PurchaseHeader, PurchaseLine, Item[1]."No.", Qty, LocationWhite.Code, Item[2]."No.");

        // [GIVEN] Calculate cross-dock opportunities on the warehouse receipt.
        FindWarehouseReceiptLine(WarehouseReceiptLine, PurchaseHeader."No.", Item[1]."No.");
        LibraryWarehouse.CalculateCrossDockLines(
          WhseCrossDockOpportunity, '', WarehouseReceiptLine."No.", WarehouseReceiptLine."Location Code");

        // [WHEN] Select warehouse receipt line for item "A" and invoke lookup on the "Qty. to Cross-Doc" field.
        LibraryVariableStorage.Enqueue(1);
        WhseReceiptSubform.OpenView();
        WhseReceiptSubform.FILTER.SetFilter("Item No.", Item[1]."No.");
        WhseReceiptSubform."Qty. to Cross-Dock".Lookup();

        // [THEN] Page "Cross-Dock Opportunities" is displayed. The list contains only one record.
        // Verified in CrossDockOpportunitiesPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickWorksheetAvailQtyToPickDedicatedBins()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // [FEATURE] [Pick Worksheet] [Dedicated Bin] [Put-away]
        // [SCENARIO 375084] Available Qty to Pick correctly accounts for quantity received not put-away that remains in a dedicated bin
        Initialize();

        // [GIVEN] Location with "Require Shipment", "Require Receive", "Require Pick", "Require Put-away" and "Bin Mandatory" and Bins "B1","B2"
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Bin "B1" set up as Dedicated and used on "Receipt Bin Code" for the Location
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Bin.Validate(Dedicated, true);
        Bin.Modify(true);
        Location.Validate("Receipt Bin Code", Bin.Code);
        Location.Modify(true);

        // [GIVEN] Item created with fixed default bin content for bin "B2" on the Location
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Fixed, true);
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Warehouse Receipt posted for Purchase Order with 17 PCS of Item
        // [GIVEN] Partial Put Away from Warehouse Receipt created and registered for 10 PCS of Item
        Quantity := LibraryRandom.RandInt(10);
        Quantity2 := LibraryRandom.RandIntInRange(Quantity, 2 * Quantity);
        CreateAndRegisterPartialPutAwayFromWarehouseReceiptUsingPurchaseOrder(
          Item."No.", 2 * Quantity + Quantity2, Location.Code, 2 * Quantity);  // Calculated Value Required.

        // [GIVEN] Warehouse Shipment for a Sales Order with 5 PCS of Item created and released
        CreateAndReleaseSalesOrder(SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", Quantity, Location.Code);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Get Warehouse Shipment on the Pick Worksheet
        GetWarehouseDocumentOnWarehouseWorksheetLine(WhseWorksheetName, Location.Code, WarehouseShipmentHeader."No.", '');

        // [THEN] Quantity = 5, AvailableQtyToPick = 10 on the Pick Worksheet line
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, 2 * Quantity, false);
    end;

    [Test]
    procedure AvailQtyToPickWithQtyReceivedNotPutawayFromDedicatedBin()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: array[3] of Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Pick] [Dedicated Bin] [Receive] [Put-away]
        // [SCENARIO 390083] A pick can be created from normal bin when not all quantity received to a dedicated bin has been put-away yet.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Location set up for required receive, shipment, pick, put-away.
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Bin "X" is dedicated and set up as a "Receipt Bin Code".
        // [GIVEN] Bin "Y" is set up as "Shipment Bin Code".
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Bin[1].Validate(Dedicated, true);
        Bin[1].Modify(true);
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Receipt Bin Code", Bin[1].Code);
        Location.Validate("Shipment Bin Code", Bin[2].Code);
        Location.Modify(true);

        // [GIVEN] Create Item and a default bin "Z" for it.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBin(Bin[3], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin[3].Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create and release purchase order for 65 pcs.
        // [GIVEN] Post warehouse receipt.
        // [GIVEN] Register put-away for 15 pcs. Now, 50 pcs are in the dedicated bin "X", 15 pcs are in normal bin "Z".
        CreateAndRegisterPartialPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", Qty * 5, Location.Code, Qty);

        // [GIVEN] Create and release sales order for 15 pcs.
        // [GIVEN] Create warehouse shipment.
        CreateAndReleaseSalesOrder(SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", Qty, Location.Code);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Create pick from the warehouse shipment in order to move 15 pcs from bin "Z" to bin "X".
        CreatePickUsingSalesOrder(SalesHeader."No.");

        // [THEN] The pick has been created and can be registered.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] The bin "Z" is now blank.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Bin Code", Bin[3].Code);
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", 0);
    end;

    [Test]
    procedure AvailQtyToPickOnPickWorksheetAfterItemReclassFromReceiveBin()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: array[2] of Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Pick Worksheet] [Item Reclassification] [Receive] [Put-away]
        // [SCENARIO 395134] Avail. Qty. to Pick on pick worksheet after the item has been received and moved from the receive bin before put-away.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Item and location.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create bin "B1" and set it as "Receipt Bin Code" at location.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Receipt Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Create bin "B2" and set it up as a default bin for the item.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, '', Bin[2].Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);

        // [GIVEN] Create purchase order for 20 pcs, post warehouse receipt and register put-away.
        // [GIVEN] 20 pcs are now in bin "B2".
        CreateAndRegisterPartialPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", Qty, Location.Code, Qty);

        // [GIVEN] Create purchase order for 20 pcs, post warehouse receipt and register put-away for 5 pcs.
        // [GIVEN] 15 pcs are now in bin "B1", 25 pcs in bin "B2"
        CreateAndRegisterPartialPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", Qty, Location.Code, Qty / 4);

        // [GIVEN] Post reclassification journal line to move 5 pcs from "B1" to "B2".
        // [GIVEN] 10 pcs are now in bin "B1", 30 pcs in bin "B2"
        CreateAndPostItemReclassificationJournalLine(Bin[1], Bin[2], Item."No.", Qty / 4);

        // [GIVEN] Sales order for 10 pcs. Release and create warehouse shipment.
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Qty / 2, Location.Code);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Open pick worksheet and pull the warehouse shipment.
        GetWarehouseDocumentOnWarehouseWorksheetLine(
          WhseWorksheetName, Location.Code, WarehouseShipmentHeader."No.", '''''');

        // [THEN] A pick worksheet line shows "Qty. Avail. to Pick" = 30.
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, Location.Code);
        Assert.AreEqual(Qty + Qty / 4 + Qty / 4, WhseWorksheetLine.AvailableQtyToPick(), '');
    end;

    [Test]
    procedure AvailQtyToPickInPickWorksheetHavingAnotherShipmentPicked()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: array[2] of Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Pick Worksheet] [Available Qty. to Pick] [Warehouse Shipment]
        // [SCENARIO 419227] Available Qty. to Pick in pick worksheet when there is another picked warehouse shipment exists for this item.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Item and location with required shipment and pick.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create bin "B1" and set it as "Shipment Bin Code" at location.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Create bin "B2" and post inventory adjustment of 20 pcs to it.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin[2].Code, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order "SO1" for 10 pcs. Release and create warehouse shipment.
        // [GIVEN] Create and register pick.
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Qty / 2, Location.Code);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(
            "Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", "Warehouse Activity Type"::Pick);

        // [GIVEN] Sales order "SO2" for 20 pcs. Release and create warehouse shipment.
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Qty, Location.Code);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Open pick worksheet and pull the warehouse shipment.
        GetWarehouseDocumentOnWarehouseWorksheetLine(
          WhseWorksheetName, Location.Code, WarehouseShipmentHeader."No.", '''''');

        // [THEN] A pick worksheet line shows "Qty. Avail. to Pick" = 10.
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, Location.Code);
        Assert.AreEqual(Qty / 2, WhseWorksheetLine.AvailableQtyToPick(), '');
    end;

    [Test]
    procedure S460314_AvailQtyToPickInPickWorksheetHavingAnotherShipmentPickedAndPartiallyShipped_WithDisabledDirectedPutAwayAndPick()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: array[2] of Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Qty: Decimal;
        QtyToShip: Decimal;
    begin
        // [FEATURE] [Pick Worksheet] [Available Qty. to Pick] [Warehouse Shipment] [Partial Shipment]
        // [SCENARIO 460314] Available Qty. to Pick in pick worksheet when there is another picked warehouse shipment exists for this item that is picked and partially shipped.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Item and location with required shipment and pick.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create bin "B1" and set it as "Shipment Bin Code" at location.
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("Shipment Bin Code", Bin[1].Code);
        Location.Modify(true);

        // [GIVEN] Create bin "B2" and post inventory adjustment of 20 pcs to it.
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin[2].Code, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Sales order "SO1" for 5 pcs. Release and create warehouse shipment.
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Qty / 4, Location.Code);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Create and register pick.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity("Warehouse Activity Source Document"::"Sales Order", SalesHeader."No.", "Warehouse Activity Type"::Pick);

        // [GIVEN] Ship and invoice 2 pcs.
        QtyToShip := LibraryRandom.RandIntInRange(2, 4);
        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetRange("Item No.", Item."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Qty. to Ship", QtyToShip);
        WarehouseShipmentLine.Modify(true);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);

        // [GIVEN] Sales order "SO2" for 20 pcs. Release and create warehouse shipment.
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Qty, Location.Code);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Open pick worksheet and pull the warehouse shipment.
        GetWarehouseDocumentOnWarehouseWorksheetLine(WhseWorksheetName, Location.Code, WarehouseShipmentHeader."No.", '''''');

        // [THEN] A pick worksheet line shows "Qty. Avail. to Pick" = 15.
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, Location.Code);
        Assert.AreEqual(Qty * 3 / 4, WhseWorksheetLine.AvailableQtyToPick(), '');
    end;

    [Test]
    procedure QtyToHandleAsPerUOMIsPopulatedInPickWorkSheetLine()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        UnitOfMeasure: array[2] of Record "Unit of Measure";
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
    begin
        // [SCENARIO 535725] When Purchase Order and Sales Order is received, put-away and shipped in different Unit of Measure Codes then Qty. to handle field in Pick Worksheet shows quanity based on Unit of Measure.
        Initialize();

        // [GIVEN] Create a Location.
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Create a Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create two Unit of Measure Codes.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[1]);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[2]);

        // [GIVEN] Create two Item Unit of Measures.
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[1], Item."No.", UnitOfMeasure[1].Code, LibraryRandom.RandInt(0));
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure[2], Item."No.", UnitOfMeasure[2].Code, LibraryRandom.RandIntInRange(20, 20));

        // [GIVEN] Validate Base Unit of Measure, Sales Unit of Measure and Purch. Unit of Measure in Item.
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure[1].Code);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure[2].Code);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure[1].Code);
        Item.Modify(true);

        // [GIVEN] Generate and save Quantity in a Variable.
        Quantity := LibraryRandom.RandIntInRange(16, 16);

        // [GIVEN] Create and Register Put-Away from Warehouse Receipt using Purchase Order.
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", Quantity, Location.Code);

        // [GIVEN] Create and Release Sales Order.
        CreateAndReleaseSalesOrder(SalesHeader, LibrarySales.CreateCustomerNo(), Item."No.", LibraryRandom.RandIntInRange(25, 25), Location.Code);

        // [GIVEN] Create and Release Warehouse Shipment.
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Get Warehouse Document on Whse. Worksheet Line.
        GetWarehouseDocumentOnWarehouseWorksheetLine(WhseWorksheetName, Location.Code, WarehouseShipmentHeader."No.", '');

        // [WHEN] Find Whse. Worksheet Line.
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, Location.Code);

        // [THEN] Qty. to Handle in Whse. WorksheetLine must be equal to Quantity / Qty. per Unit of Measure of Item Unit of Measure 2.
        Assert.AreEqual(
            Quantity / ItemUnitOfMeasure[2]."Qty. per Unit of Measure",
            WhseWorksheetLine."Qty. to Handle",
            StrSubstNo(
                QtyToHandleErr,
                WhseWorksheetLine.FieldCaption("Qty. to Handle"),
                Quantity / ItemUnitOfMeasure[2]."Qty. per Unit of Measure",
                WhseWorksheetLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure NoInProdOrderRoutingLineGivesErrorWhenSetToBlankIfRoutingStatusIsFinished()
    var
        CompItem, ProdItem : Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO 575724] "No." field in Prod. Order Routing Line gives error 
        // when it is set to blank if "Routing Status" is Finished.
        Initialize();

        // [GIVEN] Create a Component Item.
        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create a Work Center.
        CreateWorkCenter(WorkCenter);

        // [GIVEN] Create and Certify Routing.
        CreateAndCertifyRouting(RoutingHeader, WorkCenter);

        // [GIVEN] Create and Certify Production BOM.
        CreateAndCertifyProductionBOM(ProductionBOMLine, CompItem, LibraryRandom.RandIntInRange(10, 10));

        // [GIVEN] Create a Production Item and Validate "Routing No." and "Production BOM No.".
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Routing No.", RoutingHeader."No.");
        ProdItem.Validate("Production BOM No.", ProductionBOMLine."Production BOM No.");
        ProdItem.Modify(true);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProdItem."No.", LibraryRandom.RandIntInRange(50, 50), '', '');

        // [GIVEN] Find Prod. Order Routing Line.
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] Validate "Routing Status" in Prod. Order Routing Line.
        ProdOrderRoutingLine.Validate("Routing Status", ProdOrderRoutingLine."Routing Status"::Finished);
        ProdOrderRoutingLine.Modify(true);

        // [WHEN] Validate "No." in Prod. Order Routing Line.
        asserterror ProdOrderRoutingLine.Validate("No.", '');

        // [THEN] "Routing Status" field error is thrown.
        Assert.ExpectedError(
            StrSubstNo(
                RoutingStatusFieldErr,
                ProdOrderRoutingLine."Routing Status",
                ProdOrderRoutingLine.Status,
                ProdOrderRoutingLine."Prod. Order No.",
                ProdOrderRoutingLine."Routing Reference No.",
                ProdOrderRoutingLine."Routing No.",
                ProdOrderRoutingLine."Operation No."));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse Orders");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse Orders");

        LibraryERMCountryData.CreateVATData();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);
        ItemJournalSetup(ReclassItemJournalTemplate, ReclassItemJournalBatch, ReclassItemJournalTemplate.Type::Transfer);
        LocationSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Warehouse Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse Orders");
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate2: Record "Item Journal Template"; var ItemJournalBatch2: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate2, ItemJournalTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch2, ItemJournalTemplate2.Type, ItemJournalTemplate2.Name);
    end;

    local procedure LocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);
        LibraryWarehouse.CreateLocationWMS(LocationBlue, false, true, true, false, false);  // Location Blue with Require Put-Away and Require Pick.
        LibraryWarehouse.CreateLocationWMS(LocationSilver, true, true, true, false, false);  // Location Silver with Require Put-away, Require Pick and Bin Mandatory.
        LibraryWarehouse.CreateLocationWMS(LocationYellow, true, false, false, false, false);  // Location Yellow with Bin Mandatory.
        LibraryWarehouse.CreateLocationWMS(LocationGreen, false, true, true, true, true);  // Location Green with Require Put-Away, Require Pick, Require Receive and Require Shipment.
        LibraryWarehouse.CreateLocationWMS(LocationOrange, false, false, true, false, false);  // Location Orange with Require Pick.
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
    end;

    local procedure AddItemUOM(ItemNo: Code[20]; QtyPerUOM: Decimal): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, QtyPerUOM);
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure AvailableQuantityToPickOnPickWorksheetAfterRegisterPartialPutAwayAndRegisterPick()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Quantity: Decimal;
        Quantity2: Decimal;
        Quantity3: Decimal;
    begin
        // create and register Partial Put Away from Warehouse Receipt using Purchase Order.
        Quantity := LibraryRandom.RandInt(100);
        Quantity2 := Quantity + LibraryRandom.RandInt(100);
        Quantity3 := (Quantity + Quantity2) * 2;  // Large value Required for Purchase Order and greater than Sales Order Quantity.
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPartialPutAwayFromWarehouseReceiptUsingPurchaseOrder(
          Item."No.", Quantity3, LocationGreen.Code, Quantity + Quantity2);  // Calculated Value Required.

        // Exercise.
        CreatePickWorksheetLineUsingSalesOrderWithMultipleLinesAndReservation(
          SalesHeader, WhseWorksheetName, Item."No.", Quantity, LocationGreen.Code, Quantity2);

        // Verify.
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, Quantity, false);  // Use MoveNext as FALSE and Calculated Value Required.
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity2, Quantity2, true);  // Use MoveNext as TRUE and Calculated Value Required.
    end;

    local procedure AvailableQuantityToPickOnPickWorksheetAfterRegisterPutAwayAndPick(RegisterPickFromWarehouseShipment: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Quantity: Decimal;
        Quantity2: Decimal;
        Quantity3: Decimal;
    begin
        // create and Register Put Away from Warehouse Receipt using Sales Order.
        Quantity := LibraryRandom.RandInt(100);
        Quantity2 := Quantity + LibraryRandom.RandInt(100);
        Quantity3 := (Quantity + Quantity2) * 2;  // Large value Required for Purchase Order and greater than Sales Order Quantity.
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(Item."No.", Quantity3, LocationGreen.Code);

        // Exercise.
        CreatePickWorksheetLineUsingSalesOrderWithMultipleLinesAndReservation(
          SalesHeader, WhseWorksheetName, Item."No.", Quantity, LocationGreen.Code, Quantity2);

        // Verify.
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, Quantity3 - Quantity2, false);  // Use MoveNext as FALSE and Calculated Value Required.
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity2, Quantity3 - Quantity, true);  // Use MoveNext as TRUE and Calculated Value Required.

        if RegisterPickFromWarehouseShipment then begin
            // Exercise.
            CreateAndRegisterPickFromWarehouseShipmentUsingSalesOrder(
              SalesHeader."Sell-to Customer No.", Item."No.", Quantity3 - Quantity2 - Quantity, LocationGreen.Code);  // Calculated Value Required.

            // Verify.
            VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, Quantity, false);  // Use MoveNext as FALSE.
            VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity2, Quantity2, true);  // Use MoveNext as TRUE.
        end;
    end;

    local procedure AvailableQuantityToPickOnPickWorksheetBeforeRegisterPutAwayAndAfterRegisterPick(RegisterPickFromWarehouseShipment: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Quantity: Decimal;
        Quantity2: Decimal;
        Quantity3: Decimal;
    begin
        // Create and Post Warehouse Receipt from Purchase Order.
        Quantity := LibraryRandom.RandInt(100);
        Quantity2 := Quantity + LibraryRandom.RandInt(100);
        Quantity3 := (Quantity + Quantity2) * 2;  // Large value Required for Purchase Order and greater than Sales Order Quantity.
        LibraryInventory.CreateItem(Item);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, Item."No.", Quantity3, LocationGreen.Code);

        // Exercise.
        CreatePickWorksheetLineUsingSalesOrderWithMultipleLinesAndReservation(
          SalesHeader, WhseWorksheetName, Item."No.", Quantity, LocationGreen.Code, Quantity2);

        // Verify.
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, Quantity, false);  // Use MoveNext as FALSE.
        VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity2, Quantity2, true);  // Use MoveNext as TRUE.

        if RegisterPickFromWarehouseShipment then begin
            // Exercise.
            CreateAndRegisterPickFromWarehouseShipmentUsingSalesOrder(
              SalesHeader."Sell-to Customer No.", Item."No.", Quantity3 - Quantity2 - Quantity, LocationGreen.Code);  // Calculated Value Required.

            // Verify.
            VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity, Quantity3 - Quantity2, false);  // Use MoveNext as FALSE and Calculated Value Required.
            VerifyPickWorksheetLine(WhseWorksheetName, Item."No.", Quantity2, Quantity3 - Quantity, true);  // Use MoveNext as TRUE and Calculated Value Required.
        end;
    end;

    local procedure CalculateCrossDock(SourceNo: Code[20]; ItemNo: Code[20])
    var
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, ItemNo);
        LibraryWarehouse.CalculateCrossDockLines(
          WhseCrossDockOpportunity, '', WarehouseReceiptLine."No.", WarehouseReceiptLine."Location Code");
    end;

    local procedure CalculateCrossDockOnWarehouseReceiptAndRegisterPutAwayWithMultipleItems(RegisterPutAway: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CreateWarehouseReceiptFromPurchaseOrderWithMultipleItems(
          PurchaseHeader, PurchaseLine, Item."No.", Quantity, LocationWhite.Code, Item2."No.");
        CreateAndReleaseSalesOrder(SalesHeader, '', Item2."No.", Quantity, LocationWhite.Code);

        // Exercise: Calculate Cross Dock.
        CalculateCrossDock(PurchaseHeader."No.", Item2."No.");

        // Verify: Verify Warehouse Receipt Line.
        VerifyWarehouseReceiptLine(PurchaseHeader."No.", Item."No.", Quantity, 0, LocationWhite.Code);  // Value required for test.
        VerifyWarehouseReceiptLine(PurchaseHeader."No.", Item2."No.", Quantity, Quantity, LocationWhite.Code);

        if RegisterPutAway then begin
            // Exercise: Post Warehouse Receipt and Register Put away.
            PostWarehouseReceipt(PurchaseHeader."No.", Item2."No.");
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");

            // Verify: Verify Warehouse Entry.
            FilterCrossDockWarehouseEntry(WarehouseEntry, LocationWhite, PurchaseHeader."No.", Item."No.");
            Assert.IsTrue(WarehouseEntry.IsEmpty, CrossDockWarehouseEntryErr);
            VerifyCrossDockWarehouseEntry(PurchaseHeader."No.", LocationWhite, Item2."No.", Quantity);
        end;
    end;

    local procedure CalculatePlanOnRequisitionWorksheetAndRegisterWarehouseActivity(RegisterPutAway: Boolean; RegisterPickAndPostShipment: Boolean; SalesOrder: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ShipmentDate: Date;
        LotNo: Code[50];
        LotNo2: Code[20];
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Lot for Lot Item. Create Sales Order and Update Shipment Date. Create Multiple Purchase Orders with Lot Item Tracking and Update Planning Flexibility on Purchase Line.
        Quantity := 200;  // Large value Required.
        Quantity2 := 300;  // Large value Required.
        CreateLotForLotItem(Item);
        ShipmentDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        CreateAndReleaseSalesOrderWithShipmentDate(
          SalesHeader, SalesLine, '', ShipmentDate, Item."No.", Quantity + (Quantity2 / 2), LocationWhite.Code);  // Calculated Value Required.
        LotNo :=
          CreateAndReleasePurchaseOrderWithLotTrackingAndNonePlanningFlexibility(
            PurchaseHeader, PurchaseLine, '', Item."No.", Quantity, LocationWhite.Code);
        LotNo2 :=
          CreateAndReleasePurchaseOrderWithLotTrackingAndNonePlanningFlexibility(
            PurchaseHeader2, PurchaseLine2, PurchaseHeader."Buy-from Vendor No.", Item."No.",
            Quantity2 + 100, LocationWhite.Code);

        // Exercise: Calculate Plan for Requisition Worksheet.
        LibraryPlanning.CalcRequisitionPlanForReqWksh(Item, WorkDate(), ShipmentDate);

        // Verify: Verify Reservation Entry.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Tracking, Item."No.", DATABASE::"Sales Line", LocationWhite.Code, '',
          -PurchaseLine.Quantity, false);  // Use MoveNext as FALSE.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Tracking, Item."No.", DATABASE::"Sales Line", LocationWhite.Code, '',
          PurchaseLine.Quantity - SalesLine.Quantity, true);  // Use MoveNext as TRUE and Calculated Value Required.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Tracking, Item."No.", DATABASE::"Purchase Line", LocationWhite.Code, LotNo,
          PurchaseLine.Quantity, false);  // Use MoveNext as FALSE.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Tracking, Item."No.", DATABASE::"Purchase Line", LocationWhite.Code, LotNo2,
          SalesLine.Quantity - PurchaseLine.Quantity, true);  // Use MoveNext as TRUE and Calculated Value Required.
        VerifyReservationEntry(
          ReservationEntry."Reservation Status"::Surplus, Item."No.", DATABASE::"Purchase Line", LocationWhite.Code, LotNo2,
          PurchaseLine2.Quantity - (SalesLine.Quantity - PurchaseLine.Quantity), false);  // Use MoveNext as FALSE Calculated Value Required.

        if RegisterPutAway then begin
            // Exercise: Register Put away.
            PostWarehouseReceiptAndRegisterPutAway(PurchaseHeader2, Item."No.");

            // Verify: Verify Reservation Entry.
            VerifyReservationEntry(
              ReservationEntry."Reservation Status"::Tracking, Item."No.", DATABASE::"Item Ledger Entry", LocationWhite.Code, LotNo2,
              SalesLine.Quantity - PurchaseLine.Quantity, false);  // Use MoveNext as FALSE and Calculated Value Required.
        end;

        if RegisterPickAndPostShipment then begin
            // Exercise: Register Pick and Post Warehouse Shipment.
            RegisterWarehousePickAndPostWarehouseShipment(SalesHeader, LotNo2);

            // Verify: Verify Reservation Entry.
            FilterReservationEntry(
              ReservationEntry, ReservationEntry."Reservation Status"::Tracking, Item."No.", DATABASE::"Item Ledger Entry",
              LocationWhite.Code);
            Assert.IsTrue(ReservationEntry.IsEmpty, ReservationEntryForItemLedgerEntryErr);
        end;

        if SalesOrder then begin
            // Exercise: Create and Release Sales Order with Remaining Quantity. Register Pick and Post Warehouse Shipment.
            CreateAndReleaseSalesOrderWithShipmentDate(
              SalesHeader2, SalesLine2, SalesHeader."Sell-to Customer No.", WorkDate(), Item."No.",
              PurchaseLine2.Quantity - (SalesLine.Quantity - PurchaseLine.Quantity), LocationWhite.Code);  // Calculated Value Required.
            RegisterWarehousePickAndPostWarehouseShipment(SalesHeader2, LotNo2);

            // Verify: Item Ledger Entry.
            VerifyItemLedgerEntryForLot(ItemLedgerEntry."Entry Type"::Sale, Item."No.", LotNo2, -SalesLine.Quantity, false);  // Use MoveNext as FALSE.
            VerifyItemLedgerEntryForLot(
              ItemLedgerEntry."Entry Type"::Sale, Item."No.", LotNo2, SalesLine.Quantity - PurchaseLine2.Quantity, true);  // Use MoveNext as TRUE and Calculated Value Required.
        end;
    end;

    local procedure CalculateRegenPlanAndCarryOutActionMessage(var Item: Record Item; FromDate: Date; ToDate: Date)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, FromDate, ToDate);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.ModifyAll("Accept Action Message", true);
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CalculateWarehouseAdjustmentAndPostItemJournalLine(var Item: Record Item)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndCertifyBOM(var ProductionBOMHeader: Record "Production BOM Header"; UnitOfMeasureCode: Code[10]; ItemNo: Code[20]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo, Quantity);
        UpdateLocationAndBinOnItemJournalLine(ItemJournalLine, LocationCode, BinCode);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseOrderWithLotItemTracking(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20]) LotNo: Code[50]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingPageHandler.
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, VendorNo, ItemNo, Quantity, LocationCode, true);  // Value required for the test. TRUE for Tracking.
        LotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));
        UpdateBinCodeOnPurchaseLine(PurchaseLine, BinCode);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as RECEIVE.
    end;

    local procedure CreateAndPostItemReclassificationJournalLine(Bin: Record Bin; Bin2: Record Bin; ItemNo: Code[20]; Quantity: Decimal): Code[10]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ReclassItemJournalTemplate, ReclassItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ReclassItemJournalTemplate.Name, ReclassItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemNo,
          Quantity);
        UpdateLocationAndBinOnItemJournalLine(ItemJournalLine, Bin."Location Code", Bin.Code);
        ItemJournalLine.Validate("New Location Code", Bin2."Location Code");
        ItemJournalLine.Validate("New Bin Code", Bin2.Code);
        ItemJournalLine.Validate(Description, LibraryUtility.GenerateGUID());
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ReclassItemJournalTemplate.Name, ReclassItemJournalBatch.Name);
        exit(ItemJournalLine.Description);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Vendor."No.", ItemNo, Quantity, LocationCode, false);  // Item Tracking as FALSE.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWarehouseReceipt(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.", ItemNo);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        LibraryManufacturing: Codeunit "Library - Manufacturing";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);

        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
    end;

    local procedure CreateAndRegisterPartialPutAwayFromWarehouseReceiptUsingPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; QuantityToHandle: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, ItemNo, Quantity, LocationCode);
        UpdateQuantityToHandleOnPutAwayLine(PurchaseHeader."No.", QuantityToHandle);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndRegisterPutAwayFromPurchaseOrder(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        PostWarehouseReceipt(SourceNo, ItemNo);
        FindPickBin(Bin, LocationCode);
        UpdateBinCodeOnPutAwayLine(Bin, SourceNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo, WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, ItemNo, Quantity, LocationCode);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndRegisterPickFromWarehouseShipmentUsingSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreatePickFromWarehouseShipmentUsingSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, true);  // Reserve as TRUE.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPickUsingPickWorksheet(LocationCode: Code[10]; WarehouseShipmentHeaderNo: Code[20]; WarehouseShipmentHeaderNo2: Code[20]; ItemNo: Code[20]; ItemNo2: Code[20]; SourceNo: Code[20])
    var
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        GetWarehouseDocumentOnWarehouseWorksheetLine(
          WhseWorksheetName, LocationCode, WarehouseShipmentHeaderNo, WarehouseShipmentHeaderNo2);
        CreatePickFromPickWorksheet(WhseWorksheetName, ItemNo, ItemNo2);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SourceNo, WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPickFromSalesOrderWithLotItemTracking(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        Customer: Record Customer;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateSalesOrderWithItemTracking(SalesHeader, Customer."No.", ItemNo, Quantity, LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipment(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndReleasePurchaseOrderWithLotTrackingAndNonePlanningFlexibility(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]) LotNo: Code[50]
    var
        ItemTrackingMode: Option AssignLotNo,SelectEntries,AssignSerialNo,UpdateQtyOnFirstLine,UpdateQtyOnLastLine;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for ItemTrackingPageHandler.
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, true);  // Use Tracking as TRUE.
        UpdatePlanningFlexibilityOnPurchaseLine(PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));
    end;

    local procedure CreateAndReleaseSalesOrderWithMultipleLinesAndReservation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Quantity2: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, '', ItemNo, Quantity, LocationCode, true);  // Reserve as TRUE.
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity2, LocationCode);
        SalesLine.AutoReserve();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndRegisterWarehouseJournalLine(Bin: Record Bin; Item: Record Item; Quantity: Decimal; UnitOfMeasureCode: Code[10]; ItemTracking: Boolean)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Modify(true);
        if ItemTracking then
            WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
    end;

    local procedure CreateAndReleaseSalesDocumentWithShippingAdviceAsComplete(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateAndReleaseSalesDocumentShippingAdviceCompletePartToShip(SalesHeader, DocumentType, ItemNo, Quantity, Quantity, LocationCode);
    end;

    local procedure CreateAndReleaseSalesDocumentShippingAdviceCompletePartToShip(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeaderWithShippingAdviceAsComplete(SalesHeader, DocumentType);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, false);  // Reserve as FALSE.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithReserve(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, true);  // Reserve as TRUE.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrderWithShipmentDate(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ShipmentDate: Date; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        CreateSalesHeaderWithShipmentDate(SalesHeader, CustomerNo, ShipmentDate);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateWarehouseShipment(SalesHeader);
        GetWarehouseShipmentHeader(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromSalesOrder(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var Item: Record Item; var Bin: Record Bin; Quantity: Decimal)
    begin
        UpdateInventoryUsingWarehouseJournal(Bin, Item, Quantity, Item."Base Unit of Measure", false);  // Use Tracking as FALSE.
        CreateAndReleaseSalesOrder(SalesHeader, '', Item."No.", Quantity, Bin."Location Code");
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
    end;

    local procedure CreateAndReleaseTwoWhseShipmentsFromSalesOrdersReservedFromInvtAndPurchase(var WarehouseShipmentHeader: array[2] of Record "Warehouse Shipment Header"; var SalesOrderNo: array[2] of Code[20]; Item: Record Item; LocationCode: Code[10]; Qty: Decimal)
    var
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), Item."No.", Qty, LocationCode, false);
        CreateReleasedSalesOrder(SalesHeader, Item."No.", Item."Base Unit of Measure", Qty, LocationCode, true);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader[1], SalesHeader);
        SalesOrderNo[1] := SalesHeader."No.";

        FindPickBin(Bin, LocationCode);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, Qty, Item."Base Unit of Measure", false);
        CreateReleasedSalesOrder(SalesHeader, Item."No.", Item."Base Unit of Measure", Qty, LocationCode, false);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader[2], SalesHeader);
        SalesOrderNo[2] := SalesHeader."No.";
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateInventory(var ItemNo: Code[20]; LocationCode: Code[10]; QtyOnInventory: Decimal)
    var
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
    begin
        ItemNo := LibraryInventory.CreateItem(Item);
        Location.Get(LocationCode);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        LibraryInventory.PostPositiveAdjustment(
          Item, LocationCode, '', Bin.Code, QtyOnInventory, WorkDate(), LibraryRandom.RandDec(9, 2));
    end;

    local procedure CreateInventoryActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; PutAway: Boolean; Pick: Boolean)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange("Source Document", SourceDocument);
        WarehouseRequest.SetRange("Source No.", SourceNo);
        WarehouseRequest.FindFirst();
        LibraryWarehouse.CreateInvtPutAwayPick(WarehouseRequest, PutAway, Pick, false);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Lot: Boolean; Serial: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; Lot: Boolean; Serial: Boolean; LotNos: Code[20]; SerialNos: Code[20])
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, Lot, Serial);
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithItemTrackingCodeAndOrderTrackingForLot(var Item: Record Item)
    begin
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');
        Item."Order Tracking Policy" := Item."Order Tracking Policy"::"Tracking Only";
        Item."Reordering Policy" := Item."Reordering Policy"::"Lot-for-Lot";
        Item.Modify();
    end;

    local procedure CreateItemWithOrderReorderPolicyAndProductionBOM(var Item: Record Item; var ComponentItem: Record Item) Quantity: Decimal
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithVendorNoAndReorderingPolicy(Item, '', Item."Reordering Policy"::Order);
        CreateItemWithVendorNoAndReorderingPolicy(ComponentItem, LibraryPurchase.CreateVendorNo(), ComponentItem."Reordering Policy"::Order);
        Quantity := LibraryRandom.RandInt(100);
        CreateAndCertifyBOM(ProductionBOMHeader, Item."Base Unit of Measure", ComponentItem."No.", Quantity);
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithProductionBOM(var ParentItem: Record Item; var ChildItem: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithVendorNoAndReorderingPolicy(ParentItem, '', ParentItem."Reordering Policy"::" ");
        UpdateReplenishmentSystemAsProdOrderOnItem(ParentItem);
        CreateItemWithItemTrackingCode(ChildItem, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // True for Lot.
        CreateAndCertifyBOM(ProductionBOMHeader, ChildItem."Base Unit of Measure", ChildItem."No.", QuantityPer);
        UpdateProductionBOMOnItem(ParentItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithVendorNoAndReorderingPolicy(var Item: Record Item; VendorNo: Code[20]; ReorderingPolicy: Enum "Reordering Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateJobWithJobTask(var JobTask: Record "Job Task")
    var
        Job: Record Job;
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item)
    begin
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // True for Lot.
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate(Reserve, Item.Reserve::Never);
        Item.Modify(true);
    end;

    local procedure CreatePartialPick(var WhseWorksheetName: Record "Whse. Worksheet Name"; var WhseWorksheetLine: Record "Whse. Worksheet Line"; var LocationCode: Code[10]; QtyOnPO: Decimal; QtyResvdOnILE: Decimal; QtyOnInventory: Decimal)
    var
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        ItemNo: Code[20];
    begin
        // Item with Inventory "X"
        LocationCode := LibraryService.CreateDefaultYellowLocation(Location);
        CreateInventory(ItemNo, LocationCode, QtyOnInventory);
        Item.Get(ItemNo);

        // Purchase Order for Item with Qty = "Y"
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemNo, QtyOnPO, LocationCode, false);

        // Sales Order for Item with Partial Reserved Qty = "Q", where "Q" = "X" + "Y"
        // Released Warehouse Shipment
        // Pick Worksheet Line for Item
        CreateReleasedSalesOrder(SalesHeader, ItemNo, Item."Base Unit of Measure", QtyResvdOnILE + QtyOnPO, LocationCode, true);
        CreatePartialPickForWhseShipment(SalesHeader, WhseWorksheetName, WhseWorksheetLine, LocationCode);
    end;

    local procedure CreatePartialPickForWhseShipment(SalesHeader: Record "Sales Header"; var WhseWorksheetName: Record "Whse. Worksheet Name"; var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10])
    begin
        CreateAndReleaseWhseShipment(SalesHeader);
        GetWhseDocument(WhseWorksheetName, LocationCode);
        FindWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode);
    end;

    local procedure CreatePickUsingSalesOrder(SalesHeaderNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeaderNo);
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        GetWarehouseShipmentHeader(WarehouseShipmentHeader, SourceDocument, SourceNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePickFromPickWorksheet(WhseWorksheetName: Record "Whse. Worksheet Name"; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, WhseWorksheetName."Location Code", ItemNo, ItemNo2);
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, 0, WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, WhseWorksheetName."Location Code", '',
          0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);  // Taking 0 for Line No, MaxNoOfSourceDoc and SortPick.
    end;

    local procedure CreatePickFromWarehouseInternalPickWithMultipleLines(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; Bin: Record Bin; Item: Record Item; Quantity: Decimal; UnitOfMeasureCode: Code[10]; LotNo: Code[50]; LotNo2: Code[20])
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        WhseInternalPickRelease: Codeunit "Whse. Internal Pick Release";
    begin
        CreateWarehouseInternalPickHeader(WhseInternalPickHeader, Bin."Location Code", Bin.Code);
        CreateWarehouseInternalPickLine(WhseInternalPickHeader, Item."No.", Quantity, Item."Base Unit of Measure", LotNo);
        CreateWarehouseInternalPickLine(WhseInternalPickHeader, Item."No.", Quantity, UnitOfMeasureCode, LotNo2);
        WhseInternalPickRelease.Release(WhseInternalPickHeader);
        LibraryVariableStorage.Enqueue(PickActivityCreatedMsg);  // Enqueue for MessageHandler.
        WhseInternalPickLine.SetRange("No.", WhseInternalPickHeader."No.");
        WhseInternalPickLine.CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);
    end;

    local procedure CreatePickFromWarehouseShipment(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreateAndReleaseSalesOrder(SalesHeader, '', ItemNo, Quantity, '');
        GetSourceDocumentOnWarehouseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePickFromWarehouseShipmentUsingSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, Reserve);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWarehouseShipment(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure CreatePickFromWarehouseShipmentUsingTransferOrder(FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal): Code[20]
    var
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleaseTransferOrder(TransferHeader, FromLocationCode, ToLocationCode, ItemNo, Quantity);
        CreateWarehouseShipmentFromTransferOrder(TransferHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
        exit(TransferHeader."No.");
    end;

    local procedure CreatePickWorksheetLineUsingSalesOrderWithMultipleLinesAndReservation(var SalesHeader: Record "Sales Header"; var WhseWorksheetName: Record "Whse. Worksheet Name"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Quantity2: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateAndReleaseSalesOrderWithMultipleLinesAndReservation(SalesHeader, ItemNo, Quantity, LocationCode, Quantity2);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
        GetWarehouseDocumentOnWarehouseWorksheetLine(WhseWorksheetName, LocationCode, WarehouseShipmentHeader."No.", '');
    end;

    local procedure CreateProdOrderWithBOMAndPostAdjmt(var ProductionOrder: Record "Production Order")
    var
        ParentItem: Record Item;
        CompItem: Record Item;
        Qty: Decimal;
    begin
        Qty := CreateItemWithOrderReorderPolicyAndProductionBOM(ParentItem, CompItem);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ParentItem."No.", Qty);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
        LibraryInventory.PostPositiveAdjustment(
          CompItem, '', '', '', LibraryRandom.RandDec(10, 2), WorkDate(), LibraryPatterns.RandCost(CompItem));
    end;

    local procedure CreateProdOrderWithReservedComponent(var ProductionOrder: Record "Production Order")
    begin
        CreateProdOrderWithBOMAndPostAdjmt(ProductionOrder);
        ReserveProdOrderComp(ProductionOrder."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UseTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        if UseTracking then
            PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemTracking: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, ItemTracking);
    end;

    local procedure CreatePurchaseOrderWithMultipleItems(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemNo2: Code[20]; UseTracking: Boolean)
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LibraryPurchase.CreateVendorNo(), ItemNo, Quantity, LocationCode, false);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine2, ItemNo2, Quantity, LocationCode, UseTracking);
    end;

    local procedure CreateReleasedSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; UOMCode: Code[10]; Quantity: Decimal; LocationCode: Code[10]; DoReserve: Boolean)
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Validate("Shipment Date", WorkDate() + LibraryRandom.RandInt(5));
        SalesLine.Modify();
        if DoReserve then
            SalesLine.ShowReservation();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateSalesHeaderWithShippingAdviceAsComplete(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Shipping Advice", SalesHeader."Shipping Advice"::Complete);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesHeaderWithShipmentDate(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(50));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; Reserve: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        if Reserve then
            SalesLine.AutoReserve();
    end;

    local procedure CreateSalesOrderWithItemTracking(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, CustomerNo, ItemNo, Quantity, LocationCode, false);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::Order, SalesHeader."No.");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingPageHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemLineNo: Integer; ItemNo: Code[20]; LocationCode: Code[10]; NeededByDate: Date; Qty: Decimal)
    begin
        LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, Qty);
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate("Needed by Date", NeededByDate);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Modify(true);
    end;

    local procedure CreateItemAndRegisterWarehouseJournalLineWithItemTracking(var Bin: Record Bin; var Item: Record Item; Quantity: Decimal; LocationCode: Code[10]) LotNo: Code[50]
    var
        DequeueVariable: Variant;
        ItemTrackingMode: Option AssignLotNo,SelectLotNo;
    begin
        CreateItemWithItemTrackingCode(Item, true, false, LibraryUtility.GetGlobalNoSeriesCode(), '');  // TRUE for Lot.
        FindPickBin(Bin, LocationCode);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for WhseItemTrackingLinesHandler.
        CreateAndRegisterWarehouseJournalLine(Bin, Item, Quantity, Item."Base Unit of Measure", true);  // TRUE for Tracking.
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
    end;

    local procedure CreateWarehouseInternalPickHeader(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, LocationCode);
        WhseInternalPickHeader.Validate("To Zone Code", '');
        WhseInternalPickHeader.Validate("To Bin Code", BinCode);
        WhseInternalPickHeader.Modify(true);
    end;

    local procedure CreateWarehouseInternalPickLine(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; LotNo: Code[50])
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        ItemTrackingMode: Option AssignLotNo,SelectLotNo;
    begin
        LibraryWarehouse.CreateWhseInternalPickLine(WhseInternalPickHeader, WhseInternalPickLine, ItemNo, Quantity);
        WhseInternalPickLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WhseInternalPickLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectLotNo);  // Enqueue for WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(LotNo);  // Enqueue for WhseItemTrackingLinesHandler.
        WhseInternalPickLine.OpenItemTrackingLines();
    end;

    local procedure CreateWarehouseReceipt(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseReceiptFromPurchaseOrderWithMultipleItems(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ItemNo2: Code[20])
    begin
        CreatePurchaseOrderWithMultipleItems(PurchaseHeader, PurchaseLine, ItemNo, Quantity, LocationCode, ItemNo2, false);  // Use Tracking as FALSE.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWarehouseReceipt(PurchaseHeader);
    end;

    local procedure CreateWarehouseShipment(var SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateAndReleaseWhseShipment(SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        GetWarehouseShipmentHeader(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateWarehouseShipmentFromTransferOrder(var TransferHeader: Record "Transfer Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
    end;

    local procedure CreateWhseReceiptFromPurchOrderSuggestedByReqWksh(var PurchaseHeader: Record "Purchase Header"; Item: Record Item)
    var
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcRequisitionPlanForReqWkshAndGetLines(RequisitionLine, Item, WorkDate(), WorkDate());
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        FindPurchaseLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreateWarehouseReceipt(PurchaseHeader);
    end;

    local procedure DeletePick(SourceNo: Code[20])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure DeleteWarehouseShipment(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        GetWarehouseShipmentHeader(WarehouseShipmentHeader, SourceDocument, SourceNo);
        LibraryWarehouse.ReopenWhseShipment(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Get(WarehouseShipmentHeader."No.");
        WarehouseShipmentHeader.Delete(true);
    end;

    local procedure DeleteWarehouseShipmentAfterPostAndRegisterPickUsingSalesOrder(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; QtyToShip: Decimal; Invoice: Boolean)
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreatePickFromWarehouseShipmentUsingSalesOrder(
          SalesHeader, '', ItemNo, Quantity, LocationCode, false); // Reserve as FALSE.
        PostWarehouseShipmentAfterRegisterPick(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", QtyToShip, Invoice);
        DeleteWarehouseShipment(WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
    end;

    local procedure DeleteWarehouseShipmentAfterPostAndRegisterPickUsingTransferOrder(FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; QtyToShip: Decimal; Invoice: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TransferHeaderNo: Code[20];
    begin
        TransferHeaderNo := CreatePickFromWarehouseShipmentUsingTransferOrder(FromLocationCode, ToLocationCode, ItemNo, Quantity);
        PostWarehouseShipmentAfterRegisterPick(
          WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeaderNo, QtyToShip, Invoice);
        DeleteWarehouseShipment(WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeaderNo);
    end;

    local procedure EnqueTrackingParameters(TrackingMode: Option; ItemTrackingNo: Code[20]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(TrackingMode);
        LibraryVariableStorage.Enqueue(ItemTrackingNo);
        LibraryVariableStorage.Enqueue(Qty);
    end;

    local procedure FindContactBusinessRelation(var ContactBusinessRelation: Record "Contact Business Relation"; CustomerNo: Code[20])
    begin
        ContactBusinessRelation.SetRange("No.", CustomerNo);
        ContactBusinessRelation.FindFirst();
    end;

    local procedure FilterCrossDockWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; Location: Record Location; SourceNo: Code[20]; ItemNo: Code[20])
    var
        Bin: Record Bin;
    begin
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"P. Order");
        WarehouseEntry.SetRange("Source No.", SourceNo);
        WarehouseEntry.SetRange("Location Code", Bin."Location Code");
        WarehouseEntry.SetRange("Zone Code", Bin."Zone Code");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        FilterWarehouseEntry(WarehouseEntry, WarehouseEntry."Entry Type"::Movement, ItemNo);
    end;

    local procedure FilterReservationEntry(var ReservationEntry: Record "Reservation Entry"; ReservationStatus: Enum "Reservation Status"; ItemNo: Code[20]; SourceType: Integer; LocationCode: Code[10])
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Location Code", LocationCode);
    end;

    local procedure FilterWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; ItemNo: Code[20])
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
    end;

    local procedure FilterWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
    end;

    local procedure FindItemLedgerEntryWithDocumentNo(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
    end;

    local procedure FindPickBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindPickZone(Zone, LocationCode);
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));  // Find Random Bin.
    end;

    local procedure FindPickZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));  // TRUE for Put-away and Pick.
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceNo: Code[20]; ItemNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.SetRange("Item No.", ItemNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        FilterWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode);
        WhseWorksheetLine.SetFilter("Item No.", ItemNo + '|' + ItemNo2);
        WhseWorksheetLine.FindSet();
    end;

    local procedure FindWhseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    begin
        FilterWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode);
        WhseWorksheetLine.FindSet();
    end;

    local procedure GetSalesShipmentHeader(OrderNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure GetSourceDocumentOnWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, '');
    end;

    local procedure GetWarehouseDocumentOnWarehouseWorksheetLine(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; DocumentNo: Code[20]; DocumentNo2: Code[20])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
        if DocumentNo <> '' then
            WhsePickRequest.SetFilter("Document No.", '%1|%2', DocumentNo, DocumentNo2);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, LocationCode);
    end;

    local procedure GetWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure GetWhseDocument(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        WhseWorksheetTemplate.SetRange(Type, WhseWorksheetTemplate.Type::Pick);
        WhseWorksheetTemplate.FindFirst();
        LibraryWarehouse.CreateWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);

        GetSourceDocOutbound.GetSingleWhsePickDoc(WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name, LocationCode);
    end;

    local procedure InitItemQuantityForResidualSales(var Quantity: array[4] of Decimal; var SalesQty1: Decimal; var SalesQty2: Decimal)
    begin
        Quantity[1] := 60;
        Quantity[2] := 120;
        Quantity[3] := 180;
        Quantity[4] := 180;
        SalesQty1 := Quantity[1] + Quantity[2] / 2;
        SalesQty2 := Quantity[1] + Quantity[2] + Quantity[3] + Quantity[4] + 10;
    end;

    local procedure OpenInventoryPickPageAndAutoFillQtyToHandle(var InventoryPick: TestPage "Inventory Pick"; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order",
          SourceNo, WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        InventoryPick.OpenEdit();
        InventoryPick.FILTER.SetFilter("No.", WarehouseActivityHeader."No.");
        InventoryPick.AutofillQtyToHandle.Invoke();
    end;

    local procedure PostInventoryAdjustmentWithTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        EnqueTrackingParameters(ItemTrackingMode::AssignManualLotNo, LotNo, Qty);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostInventoryPick(SourceNo: Code[20]; ToInvoice: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order",
          SourceNo, WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, ToInvoice);
    end;

    local procedure PostProductionJournal(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ItemTrackingMode: Option AssignLotNo,SelectEntries,AssignSerialNo,UpdateQtyOnFirstLine,UpdateQtyOnLastLine;
    begin
        FindProductionOrderLine(ProdOrderLine, ProductionOrder);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);  // Enqueue for ItemTrackingPageHandler.
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure PostWarehouseReceipt(SourceNo: Code[20]; ItemNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, ItemNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseReceiptAndRegisterPutAway(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateWarehouseReceipt(PurchaseHeader);
        PostWarehouseReceipt(PurchaseHeader."No.", ItemNo);
        FindPickBin(Bin, LocationWhite.Code);
        UpdateBinCodeOnPutAwayLine(Bin, PurchaseHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", WarehouseActivityHeader.Type::"Put-away");
    end;

    local procedure PostWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; QuantityToShip: Decimal; Invoice: Boolean)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, SourceDocument, SourceNo);
        WarehouseShipmentLine.Validate("Qty. to Ship", QuantityToShip);
        WarehouseShipmentLine.Modify(true);
        UpdateExternalDocumentNoOnWarehouseShipmentHeader(WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, Invoice);
    end;

    local procedure PostWarehouseShipmentAfterRegisterPick(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; Quantity: Decimal; Invoice: Boolean)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        RegisterWarehouseActivity(
          SourceDocument, SourceNo, WarehouseActivityLine."Activity Type"::Pick);
        GetWarehouseShipmentHeader(WarehouseShipmentHeader, SourceDocument, SourceNo);
        PostWarehouseShipment(WarehouseShipmentHeader, SourceDocument, SourceNo, Quantity, Invoice);
    end;

    local procedure PostWarehouseShipmentAfterPartialRegisterPickFromSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        Customer: Record Customer;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        CreatePickFromWarehouseShipmentUsingSalesOrder(SalesHeader, Customer."No.", ItemNo, Quantity, LocationCode, false);
        UpdateQuantityToHandleOnWarehousePickLines(SalesHeader."No.", Quantity / 2);  // Value required for Partial Quantity.
        PostWarehouseShipmentAfterRegisterPick(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", Quantity / 2, true); // Value required for Partial Quantity.
    end;

    local procedure RegisterPickAndPostWarehouseShipmentWithBlankLocation(PostShipment: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // Update Require Shipment and Require Pick on Warehouse Setup. Create and Post Item Journal.
        UpdateRequireShipmentOnWarehouseSetup(true);
        UpdateRequirePickOnWarehouseSetup(true);
        Quantity := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '', '');

        // Exercise: Create Pick from Warehouse Shipment.
        CreatePickFromWarehouseShipment(SalesHeader, WarehouseShipmentHeader, Item."No.", Quantity);

        // Verify: Verify Warehouse Activity Line.
        VerifyWarehousePickLine(SalesHeader."No.", Item."No.", '', Quantity);

        if PostShipment then begin
            // Exercise: Register Pick and Post Warehouse Shipment.
            RegisterWarehouseActivity(
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Invoice as FALSE.

            // Verify: Verify Item Ledger Entry.
            VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Purchase, Item."No.", Quantity, '', '', '');
            VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, Item."No.", -Quantity, '', '', '');
        end;
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWarehousePickAndPostWarehouseShipment(var SalesHeader: Record "Sales Header"; LotNo: Code[50])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateWarehouseShipment(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        UpdateLotNoAndQuantityToHandleOnWarehousePickLines(SalesHeader."No.", WarehouseActivityLine."Action Type"::Take, LotNo);
        UpdateLotNoAndQuantityToHandleOnWarehousePickLines(SalesHeader."No.", WarehouseActivityLine."Action Type"::Place, LotNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Invoice as FALSE.
    end;

    local procedure RegisterWarehousePickAndPostWarehouseShipmentSomeLines(var SalesHeader: Record "Sales Header"; var Bin: array[4] of Record Bin; LotNo: array[4] of Code[20])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        i: Integer;
    begin
        CreateWarehouseShipment(SalesHeader);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");

        for i := ArrayLen(LotNo) downto 1 do
            UpdateLotNoAndQuantityToHandleOnWarehousePickLinesForBin(
              SalesHeader."No.", WarehouseActivityLine."Action Type"::Take, LotNo[i], Bin[i].Code);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", WarehouseActivityHeader.Type::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure ReserveProdOrderComp(ProdOrderNo: Code[20])
    var
        ProdOrderComp: Record "Prod. Order Component";
        ReservationManagement: Codeunit "Reservation Management";
        FullReservation: Boolean;
        Qty: Decimal;
    begin
        Qty := LibraryRandom.RandDec(10, 2);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComp.FindFirst();
        ReservationManagement.SetReservSource(ProdOrderComp);
        ReservationManagement.AutoReserve(FullReservation, '', ProdOrderComp."Due Date", Qty, Qty);
    end;

    local procedure SkipManualReservation()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Skip Manual Reservation", true);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateAlwaysCreatePickLine(LocationCode: Code[10]; SetAlwaysCreatePickLine: Boolean) PrevAlwaysCreatePickLine: Boolean
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        PrevAlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", SetAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateBinCodeJobNoAndJobTaskNoOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; JobTask: Record "Job Task"; BinCode: Code[20])
    begin
        if BinCode <> '' then
            PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Validate("Job No.", JobTask."Job No.");
        PurchaseLine.Validate("Job Task No.", JobTask."Job Task No.");
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateBinCodeOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; BinCode: Code[20])
    begin
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateBinCodeOnPutAwayLine(Bin: Record Bin; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        WarehouseActivityLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateCorrespondenceTypeAsEMailOnCustomerContact(var Customer: Record Customer; var Contact: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibrarySales.CreateCustomer(Customer);
        FindContactBusinessRelation(ContactBusinessRelation, Customer."No.");
        Contact.Get(ContactBusinessRelation."Contact No.");
        Contact.Validate("Correspondence Type", Contact."Correspondence Type"::Email);
        Contact.Modify(true);
    end;

    local procedure UpdateEMailOnCustomer(Customer: Record Customer)
    begin
        Customer.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Customer.Modify(true);
    end;

    local procedure UpdateEmailOnContact(Contact: Record Contact)
    begin
        Contact.Validate("E-Mail", LibraryUtility.GenerateRandomEmail());
        Contact.Modify(true);
    end;

    local procedure UpdateExternalDocumentNoOnWarehouseShipmentHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseShipmentHeader.Find();
        WarehouseShipmentHeader.Validate("External Document No.", LibraryUtility.GenerateGUID());
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure UpdateLotNosOnInventoryPick(SalesOrderNo: Code[20]; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order",
          SalesOrderNo, WarehouseActivityLine."Activity Type"::"Invt. Pick");
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateInventoryUsingWarehouseJournal(Bin: Record Bin; Item: Record Item; Quantity: Decimal; UnitOfMeasureCode: Code[10]; ItemTracking: Boolean)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Bin."Location Code", WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateAndRegisterWarehouseJournalLine(Bin, Item, Quantity, UnitOfMeasureCode, ItemTracking);
        CalculateWarehouseAdjustmentAndPostItemJournalLine(Item);
    end;

    local procedure UpdateInventoryUsingWarehouseJournalWithLotItemTracking(Item: Record Item; Bin: Record Bin; Quantity: Decimal; UnitOfMeasureCode: Code[10]) LotNo: Code[50]
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignLotNo);  // Enqueue for WhseItemTrackingLinesHandler.
        UpdateInventoryUsingWarehouseJournal(Bin, Item, Quantity, UnitOfMeasureCode, true);  // Use Tracking as True.
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
    end;

    local procedure UpdateLocationAndBinOnItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateLotNoAndQuantityToHandleOnWarehousePickLines(SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        UpdateLotNoAndQtyToHandleOnWhsePickLines(WarehouseActivityLine, SourceNo, ActionType, LotNo);
    end;

    local procedure UpdateLotNoAndQuantityToHandleOnWarehousePickLinesForBin(SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; LotNo: Code[50]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Bin Code", BinCode);
        UpdateLotNoAndQtyToHandleOnWhsePickLines(WarehouseActivityLine, SourceNo, ActionType, LotNo);
        WarehouseActivityLine.SetRange("Action Type");
        WarehouseActivityLine.SetRange("Bin Code");
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure UpdateLotNoAndQtyToHandleOnWhsePickLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; LotNo: Code[50])
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
    end;

    local procedure UpdatePlanningFlexibilityOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Validate("Planning Flexibility", PurchaseLine."Planning Flexibility"::None);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateProductionBOMOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityToHandleOnPutAwayLine(SourceNo: Code[20]; QuantityToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateQuantityToHandleOnWarehousePickLines(SourceNo: Code[20]; QuantityToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.ModifyAll("Qty. to Handle", QuantityToHandle);
        WarehouseActivityLine.ModifyAll("Qty. to Handle (Base)", QuantityToHandle);
    end;

    local procedure UpdateReplenishmentSystemAsProdOrderOnItem(var Item: Record Item)
    begin
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
    end;

    local procedure UpdateRequirePickOnWarehouseSetup(NewRequirePick: Boolean)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Require Pick", NewRequirePick);
        WarehouseSetup.Modify(true);
    end;

    local procedure UpdateRequireShipmentOnWarehouseSetup(NewRequireShipment: Boolean)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        WarehouseSetup.Validate("Require Shipment", NewRequireShipment);
        WarehouseSetup.Modify(true);
    end;

    local procedure UpdateUseCrossDockingOnLocation(var Location: Record Location; NewUseCrossDocking: Boolean) OldUseCrossDocking: Boolean
    begin
        OldUseCrossDocking := Location."Use Cross-Docking";
        Location.Validate("Use Cross-Docking", NewUseCrossDocking);
        Location.Modify(true);
    end;

    local procedure VerifyCalcReservedCompError()
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        Assert.ExpectedTestFieldError(ProdOrderComp.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    local procedure VerifyCrossDockWarehouseEntry(SourceNo: Code[20]; Location: Record Location; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FilterCrossDockWarehouseEntry(WarehouseEntry, Location, SourceNo, ItemNo);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyDescriptionOnWarehouseEntry(ItemNo: Code[20]; Description: Text[50])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FilterWarehouseEntry(WarehouseEntry, WarehouseEntry."Entry Type"::Movement, ItemNo);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Description, Description);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; JobNo: Code[20]; JobTaskNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Location Code", LocationCode);
        ItemLedgerEntry.TestField("Job No.", JobNo);
        ItemLedgerEntry.TestField("Job Task No.", JobTaskNo);
    end;

    local procedure VerifyItemLedgerEntryForLot(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal; MoveNext: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        if MoveNext then
            ItemLedgerEntry.Next();
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, Quantity)
    end;

    local procedure VerifyItemLedgerEntryForPostedDocument(DocumentType: Enum "Item Ledger Document Type"; EntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; ItemNo: Code[20]; RemainingQuantity: Decimal; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        FindItemLedgerEntryWithDocumentNo(ItemLedgerEntry, EntryType, DocumentNo, ItemNo);
        ItemLedgerEntry.TestField("Remaining Quantity", RemainingQuantity);
        ItemLedgerEntry.TestField(Quantity, Quantity)
    end;

    local procedure VerifyPickWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; ItemNo: Code[20]; Quantity: Decimal; AvailableQtyToPick: Decimal; MoveNext: Boolean)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, WhseWorksheetName."Location Code", ItemNo, ItemNo);
        if MoveNext then
            WhseWorksheetLine.Next();
        WhseWorksheetLine.TestField(Quantity, Quantity);
        Assert.AreEqual(AvailableQtyToPick, WhseWorksheetLine.AvailableQtyToPick(), QuantityMustBeSameErr);
    end;

    local procedure VerifyQtyToHandleOnPickWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10]; WhseDocumentNo: Code[20]; ExpectedQtyToHandle: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FilterWhseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, LocationCode);
        WhseWorksheetLine.SetFilter("Whse. Document No.", WhseDocumentNo);
        WhseWorksheetLine.FindFirst();
        WhseWorksheetLine.TestField("Qty. to Handle", ExpectedQtyToHandle);
    end;

    local procedure VerifyQtyToCrossDockOnWarehouseReceiptLine(SourceNo: Code[20]; ItemNo: Code[20]; QtyToCrossDock: Decimal)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, ItemNo);
        Assert.AreEqual(
          QtyToCrossDock, WarehouseReceiptLine."Qty. to Cross-Dock",
          StrSubstNo(QtyToCrossDockErr, WarehouseReceiptLine.FieldCaption("Qty. to Cross-Dock")));
    end;

    local procedure VerifyRegisteredWarehousePickLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitOfMeasureCode: Code[10]; LotNo: Code[50])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", RegisteredWhseActivityLine."Source Document");
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityLine."Activity Type"::Pick);
        RegisteredWhseActivityLine.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        RegisteredWhseActivityLine.FindFirst();
        RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        RegisteredWhseActivityLine.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyReservationEntry(ReservationStatus: Enum "Reservation Status"; ItemNo: Code[20]; SourceType: Integer; LocationCode: Code[10]; LotNo: Code[50]; Quantity: Decimal; MoveNext: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FilterReservationEntry(ReservationEntry, ReservationStatus, ItemNo, SourceType, LocationCode);
        ReservationEntry.FindSet();
        if MoveNext then
            ReservationEntry.Next();
        ReservationEntry.TestField("Lot No.", LotNo);
        ReservationEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationEntriesResidualSurplus(ItemNo: Code[20]; ExpectedQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Untracked Surplus", true);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, ExpectedQty);
    end;

    local procedure VerifyReservationEntryQtyToHandleAndInvoiceForItemAndLot(ItemNo: Code[20]; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.TestField("Qty. to Handle (Base)", ReservationEntry."Quantity (Base)");
            ReservationEntry.TestField("Qty. to Invoice (Base)", ReservationEntry."Quantity (Base)");
        until ReservationEntry.Next() = 0;
    end;

    local procedure VerifyReservationEntryPositiveNegativeQtyForItemAndLot(ItemNo: Code[20]; LotNo: Code[50]; Qty: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange(Positive, true);
        ReservationEntry.CalcSums("Quantity (Base)");
        ReservationEntry.TestField("Quantity (Base)", Qty);
        ReservationEntry.SetRange(Positive, false);
        ReservationEntry.CalcSums("Quantity (Base)");
        ReservationEntry.TestField("Quantity (Base)", -Qty);
    end;

    local procedure VerifyWarehouseCrossDockOpportunity(ToSourceNo: Code[20]; ItemNo: Code[20]; ReservedQuantity: Decimal)
    var
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
    begin
        WhseCrossDockOpportunity.SetRange("To Source Document", WhseCrossDockOpportunity."To Source Document"::"Prod. Order Comp.");
        WhseCrossDockOpportunity.SetRange("To Source No.", ToSourceNo);
        WhseCrossDockOpportunity.SetRange("Item No.", ItemNo);
        WhseCrossDockOpportunity.FindFirst();
        WhseCrossDockOpportunity.CalcFields("Reserved Quantity");
        WhseCrossDockOpportunity.TestField("Reserved Quantity", ReservedQuantity);
    end;

    local procedure VerifyWarehouseEntry(EntryType: Option; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; LotNo: Code[50])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FilterWarehouseEntry(WarehouseEntry, EntryType, ItemNo);
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.SetRange(Quantity, Quantity);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField("Location Code", LocationCode);
        WarehouseEntry.TestField("Lot No.", LotNo);
    end;

    local procedure VerifyWarehouseReceiptLine(SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QtyToCrossDock: Decimal; LocationCode: Code[10])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceNo, ItemNo);
        WarehouseReceiptLine.TestField(Quantity, Quantity);
        WarehouseReceiptLine.TestField("Qty. to Cross-Dock", QtyToCrossDock);
        WarehouseReceiptLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyWarehousePickLine(SourceNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField("Location Code", LocationCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyBinCodeOnWhsePickLine(SalesOrderNo: Code[20]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesOrderNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.TestField("Bin Code", BinCode);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        WorkCenter.Validate(Capacity, LibraryRandom.RandIntInRange(3, 3));
        WorkCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        WorkCenter.Modify(true);
    end;

    local procedure CreateAndCertifyRouting(var RoutingHeader: Record "Routing Header"; WorkCenter: Record "Work Center")
    var
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandIntInRange(10, 10)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandIntInRange(10, 10));
        RoutingLine.Validate("Run Time", LibraryRandom.RandIntInRange(10, 10));
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMLine: Record "Production BOM Line"; Item: Record Item; Qty: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", Qty);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(ConfirmMessage, LocalMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DateCompressWarehouseEntriesHandler(var DateCompressWhseEntries: TestRequestPage "Date Compress Whse. Entries")
    var
        DateComprRegister: Record "Date Compr. Register";
        DateCompression: Codeunit "Date Compression";
    begin
        DateCompressWhseEntries.StartingDate.SetValue(Format(LibraryFiscalYear.GetFirstPostingDate(true)));
        DateCompressWhseEntries.EndingDate.SetValue(DateCompression.CalcMaxEndDate());
        DateCompressWhseEntries.PeriodLength.SetValue(DateComprRegister."Period Length"::Year);
        DateCompressWhseEntries.SerialNo.SetValue(false);
        DateCompressWhseEntries.LotNo.SetValue(true);
        DateCompressWhseEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure HandlePickSelectionPage(var PickSelectionTestPage: TestPage "Pick Selection")
    begin
        PickSelectionTestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingMode := LibraryVariableStorage.DequeueInteger();
        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            ItemTrackingMode::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::AssignSerialNo:
                begin
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    ItemTrackingLines.First();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Serial No.".Value);
                end;
            ItemTrackingMode::AssignManualLotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PartialReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Reservation.Last();
        Reservation."Reserve from Current Line".Invoke();
        Reservation.First();
        Reservation."Auto Reserve".Invoke();
        Reservation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.FILTER.SetFilter("Entry Type", ProductionJournal."Entry Type".GetOption(6));  // Value 6 is used for Consumption.
        ProductionJournal.ItemTrackingLines.Invoke();
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg);  // Enqueue for MessageHandler.
        ProductionJournal.Post.Invoke();
        ProductionJournal.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalOutputHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.FILTER.SetFilter("Entry Type", ProductionJournal."Entry Type".GetOption(7));  // Output.
        LibraryVariableStorage.Enqueue(PostJournalLinesConfirmationQst);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg);  // Enqueue for MessageHandler.
        ProductionJournal.Post.Invoke();
        ProductionJournal.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        DequeueVariable: Variant;
        TrackingQuantity: Decimal;
        ItemTrackingMode: Option AssignLotNo,SelectLotNo;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ItemTrackingMode := DequeueVariable;
        TrackingQuantity := WhseItemTrackingLines.Quantity3.AsDecimal();
        case ItemTrackingMode of
            ItemTrackingMode::AssignLotNo:
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    WhseItemTrackingLines.Quantity.SetValue(TrackingQuantity);
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Lot No.".Value);
                end;
            ItemTrackingMode::SelectLotNo:
                begin
                    LibraryVariableStorage.Dequeue(DequeueVariable);
                    WhseItemTrackingLines."Lot No.".SetValue(DequeueVariable);
                    WhseItemTrackingLines.Quantity.SetValue(TrackingQuantity);
                end;
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CrossDockOpportunitiesPageHandler(var CrossDockOpportunities: TestPage "Cross-Dock Opportunities")
    var
        RecCount: Integer;
        ExpectedRecCount: Integer;
    begin
        ExpectedRecCount := LibraryVariableStorage.DequeueInteger();
        if CrossDockOpportunities.First() then begin
            RecCount := 1;
            while CrossDockOpportunities.Next() do
                RecCount += 1;
        end;

        Assert.AreEqual(ExpectedRecCount, RecCount, StrSubstNo(WrongNoOfRecordsErr, ExpectedRecCount));
    end;
}

