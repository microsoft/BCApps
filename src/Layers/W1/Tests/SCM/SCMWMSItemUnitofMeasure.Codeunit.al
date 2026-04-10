codeunit 137423 "SCM WMS Item Unit of Measure"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Warehouse] [Unit of Measure]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Initialized: Boolean;
        CannotModifyUOMErr: Label 'You cannot modify';
        ItemTrackingOption: Option AssignLotNo,AssignManualLotNo,AssignMultipleLotNos,AssignSerialNo,AssignManualSN,AssignMultipleSN;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_2()
    begin
        // Test that is possible to post whse transaction which have BaseUOM < PurchUOM < SalesUOM < Put-awayUOM in location WHITE
        B46666(3, 5, 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_3()
    begin
        // Test that is possible to post whse transaction which have BaseUOM < PurchUOM < Put-awayUOM < SalesUOM in location WHITE
        B46666(3, 7, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_4()
    begin
        // Test that is possible to post whse transaction which have BaseUOM < SalesUOM < PurchUOM < Put-awayUOM in location WHITE
        B46666(5, 3, 7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_5()
    begin
        // Test that is possible to post whse transaction which have BaseUOM < Put-awayUOM < PurchUOM < SalesUOM in location WHITE
        B46666(5, 7, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_6()
    begin
        // Test that is possible to post whse transaction which have BaseUOM < SalesUOM < Put-awayUOM < PurchUOM in location WHITE
        B46666(7, 3, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_7()
    begin
        // Test that is possible to post whse transaction which have BaseUOM < Put-awayUOM < SalesUOM < PurchUOM in location WHITE
        B46666(7, 5, 3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_8()
    begin
        // Test that is possible to post whse transaction which have PurchUOM < SalesUOM < Put-awayUOM < BaseUOM in location WHITE
        B46666(0.3, 0.5, 0.7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_9()
    begin
        // Test that is possible to post whse transaction which have PurchUOM < Put-awayUOM < SalesUOM < BaseUOM in location WHITE
        B46666(0.3, 0.7, 0.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_10()
    begin
        // Test that is possible to post whse transaction which have SalesUOM < PurchUOM < Put-awayUOM < BaseUOM in location WHITE
        B46666(0.5, 0.3, 0.7);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_11()
    begin
        // Test that is possible to post whse transaction which have Put-awayUOM < PurchUOM < SalesUOM < BaseUOM in location WHITE
        B46666(0.5, 0.7, 0.3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_12()
    begin
        // Test that is possible to post whse transaction which have SalesUOM < Put-awayUOM < PurchUOM < BaseUOM in location WHITE
        B46666(0.7, 0.3, 0.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_13()
    begin
        // Test that is possible to post whse transaction which have SalesUOM < Put-awayUOM < PurchUOM < BaseUOM in location WHITE
        B46666(0.7, 0.5, 0.3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_14()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        I: Integer;
    begin
        // [FEATURE] [Pick] [Breakbulk]
        // [SCENARIO] Breakbulks should not result in rounding residuals

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        // 1. Create an item with multiple UOMs for receiving, ship, and put-away
        CreateItemWithPurchSaleAndPutAwayUnitOfMeasure(Item, '', 3.33333, 7);

        // 2. Create Purchase Order for component item and receive into white location
        CreateAndPostPurchReceiptPutAway(Item."No.", 2, 0.5, Location.Code);

        // Exercise
        // 3. Create Sales Order for the item and post as shipped through white location
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineWithUnitOfMeasure(SalesLine, SalesHeader, Item."No.", 0.00002, Location.Code, Item."Base Unit of Measure");

        for I := 1 to 4 do
            CreateSalesLine(SalesLine, SalesHeader, Item."No.", 0.25, Location.Code);

        CreateWhseShipmentAndPickFromSalesOrder(SalesHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0.00002, 0.00004, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Put-away Unit of Measure Code", 3.33334, 0, 3.33334);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 3.33332, 6.66664, 0);
        VerifyInvtQty(Item."No.", 3.33334);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B46666_15()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        I: Integer;
    begin
        // [FEATURE] [Pick] [Breakbulk]
        // [SCENARIO] Breakbulks should not result in rounding residuals

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateItemWithPurchSaleAndPutAwayUnitOfMeasure(Item, '', 3.33333, 7);

        CreateAndPostPurchReceiptPutAway(Item."No.", 2, 0.5, Location.Code);

        // Exercise
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for I := 1 to 4 do
            CreateSalesLine(SalesLine, SalesHeader, Item."No.", 0.25, Location.Code);

        CreateSalesLineWithUnitOfMeasure(SalesLine, SalesHeader, Item."No.", 0.00002, Location.Code, Item."Base Unit of Measure");

        PostWarehouseShipmentAndPick(SalesHeader);

        VerifyWhseAndInvtIsZero(Item."No.");
    end;

    local procedure B46666(PurchQtyPerUOMRatio: Decimal; PutAwayQtyPerUOMRatio: Decimal; SalesQtyPerUOMRatio: Decimal)
    var
        Item: Record Item;
        ParentItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        ProductionOrder: Record "Production Order";
        Location: Record Location;
        CurrLine: Integer;
    begin
        // This test creates an item with multiple UOMs, then purchases, sell, consumes it through location WHITE and finally verifies
        // no quantity remains in both item ledger and warehouse entries.

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", PurchQtyPerUOMRatio));
        Item.Validate("Sales Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", SalesQtyPerUOMRatio));
        Item.Validate("Put-away Unit of Measure Code", CreateItemUnitOfMeasureCode(Item."No.", PutAwayQtyPerUOMRatio));

        Item.Validate("Rounding Precision", 0.00001);
        Item.Modify(true);

        CreateAndPostPurchReceiptPutAway(Item."No.", 13, PutAwayQtyPerUOMRatio * SalesQtyPerUOMRatio * 11 * 2, Location.Code);

        // Exercise
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for CurrLine := 1 to 10 do
            CreateSalesLine(SalesLine, SalesHeader, Item."No.", PurchQtyPerUOMRatio * PutAwayQtyPerUOMRatio * 13, Location.Code);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        CreateItemWithProductionBOM(ParentItem, Item."No.", 11 * 13 * SalesQtyPerUOMRatio * PurchQtyPerUOMRatio * PutAwayQtyPerUOMRatio);

        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", 1, Location.Code);
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        FindWhseActivity(
          WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, DATABASE::"Prod. Order Component",
          ProductionOrder.Status.AsInteger(), ProductionOrder."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        PostProdOrderConsumption(ProductionOrder."No.");

        // Post Pick of Sales Order.
        PostPickFromSalesLine(SalesLine);
        PostWhseShptFromSalesLine(SalesLine);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", PurchQtyPerUOMRatio * PutAwayQtyPerUOMRatio * 13, Location.Code);

        PostWarehouseShipmentAndPick(SalesHeader);

        // Verify
        VerifyWhseAndInvtIsZero(Item."No.");
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B25525_2()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // [FEATURE] [Pick] [Item Tracking]
        // [SCENARIO] Pick correctly when using Multiple UOM with Item Tracking with item tracking

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateItemWithPurchSaleAndPutAwayUnitOfMeasure(Item, CreateItemTrackingCode(), 54, 0);

        CreateAndPostWhseJnlB25525(
          Item,
          Location.Code,
          CalcDate('<2M>', WorkDate()),
          CalcDate('<3M>', WorkDate()),
          WorkDate(),
          CalcDate('<3M>', WorkDate()),
          WorkDate());

        // Exercise
        CreateAndPostSalesB25525(Item."No.", Location.Code, SalesLine);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 29, 0, 32);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 79, 108, 108);
        VerifyInvtQty(Item."No.", 140);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B25525_3()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // [FEATURE] [Pick] [FEFO] [Item Tracking]
        // [SCENARIO] Pick correctly when using Multiple UOM with Item Tracking with Pick according to FEFO

        // Setup
        Initialize();

        UpdateItemInventoryOnWMSLocationSplitByLotNo(Item, Location, true, 54);

        // Exercise
        CreateAndPostSalesB25525(Item."No.", Location.Code, SalesLine);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 29, 0, 32);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 79, 108, 108);
        VerifyInvtQty(Item."No.", 140);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B25525_4()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // [FEATURE] [Pick] [Item Tracking]
        // [SCENARIO] Pick correctly when using Multiple UOM with Item Tracking with item tracking

        // Setup
        Initialize();

        UpdateItemInventoryOnWMSLocationSplitByLotNo(Item, Location, false, 54);

        // Exercise
        CreateAndPostSalesB25525(Item."No.", Location.Code, SalesLine);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 29, 0, 32);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 79, 108, 108);
        VerifyInvtQty(Item."No.", 140);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B25525_5()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // [FEATURE] [Pick] [Item Tracking]
        // [SCENARIO] Pick correctly when using Multiple UOM without item tracking

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 54));
        Item.Validate("Sales Unit of Measure", Item."Purch. Unit of Measure");
        Item.Modify(true);

        CreateAndPostWhseJnlB25525_NoTracking(Item, Location.Code);

        // Exercise
        CreateAndPostSalesB25525(Item."No.", Location.Code, SalesLine);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 32);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 108, 108, 108);
        VerifyInvtQty(Item."No.", 140);

        PostPickFromSalesLine(SalesLine);
        PostWhseShptFromSalesLine(SalesLine);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 0.5, Location.Code);
        CreateSalesLineWithUnitOfMeasure(SalesLine, SalesHeader, Item."No.", 5, Location.Code, Item."Base Unit of Measure");

        PostWarehouseShipmentAndPick(SalesHeader);
        VerifyWhseAndInvtIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B25525_6()
    var
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Zone: Record Zone;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // [FEATURE] [Pick]
        // [SCENARIO] Pick correctly when using Multiple UOM

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.FindZone(Zone, Location.Code, FindPutPickBinType(), false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', Zone.Code, Zone."Bin Type Code");
        LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, Item."No.", 100, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', Zone.Code, Zone."Bin Type Code");
        LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, Item."No.", 111, false);

        // Exercise
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 112, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        asserterror LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        Assert.ExpectedError('Nothing to handle');

        LibraryWarehouse.PostWhseAdjustment(Item);

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        PostPickFromSalesLine(SalesLine);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 99);
        VerifyInvtQty(Item."No.", 99);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B25525()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // [FEATURE] [Pick] [FEFO] [Item Tracking]
        // [SCENARIO] Pick correctly when using Multiple UOM with Item Tracking with Pick according to FEFO

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, true);

        CreateItemWithPurchSaleAndPutAwayUnitOfMeasure(Item, CreateItemTrackingCode(), 54, 0);

        CreateAndPostWhseJnlB25525(
          Item,
          Location.Code,
          CalcDate('<2M>', WorkDate()),
          CalcDate('<3M>', WorkDate()),
          WorkDate(),
          CalcDate('<3M>', WorkDate()),
          WorkDate());

        // Exercise
        CreateAndPostSalesB25525(Item."No.", Location.Code, SalesLine);

        VerifyWhseBinQty(Item."No.", Location.Code, '', '', 0, 0, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 29, 0, 32);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 79, 108, 108);
        VerifyInvtQty(Item."No.", 140);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B47195()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        // [FEATURE] [Breakbulk] [Item Tracking]
        // [SCENARIO] Breakbulk conversions should not cause rounding residuals when lot tracking is used

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, false, false);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        Item.Validate("Put-away Unit of Measure Code", CreateItemUnitOfMeasureCode(Item."No.", 324));
        Item.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithLotTracking(PurchaseLine, PurchaseHeader, Item."No.", 348, Location.Code, 'LOT1');
        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);

        // Exercise
        CreateLotTrackedSalesOrder(SalesHeader, Item."No.", 348, 'LOT1', Location.Code);
        CreateWhseShipmentAndPickFromSalesOrder(SalesHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 348, 696, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Put-away Unit of Measure Code", 348, 0, 348);
        VerifyInvtQty(Item."No.", 348);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B26054()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // [FEATURE] [Breakbulk]
        // [SCENARIO] Breakbulk conversions should not cause rounding residuals without item tracking

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 6));
        Item.Modify(true);

        // Exercise
        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(Item."No.", Location.Code, 11, false);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 2, Location.Code);
        CreateWhseShipmentAndPickFromSalesOrder(SalesHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 11, 0, 11);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Sales Unit of Measure", 0, 11, 0);
        VerifyInvtQty(Item."No.", 11);

        // Tear down
        SalesLine.Find();
        PostPickFromSalesLine(SalesLine);
        PostWhseShptFromSalesLine(SalesLine);

        VerifyWhseAndInvtIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B27157()
    var
        Bin: Record Bin;
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJnlLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
    begin
        // [FEATURE] [Production] [Consumption]
        // [SCENARIO] It should be possible to consume an item in SILVER when UOM <> BaseUOM

        // Setup
        Initialize();
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);

        LibraryInventory.CreateItem(ChildItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ChildItem."No.", 2);

        CreateItemWithProductionBOM(ParentItem, ChildItem."No.", 1);

        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');

        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJnlLine, ChildItem."No.", Location.Code, Bin.Code, 10);
        ItemJnlLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemJnlLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJnlLine."Journal Template Name", ItemJnlLine."Journal Batch Name");

        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", 1, '');
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        LibraryManufacturing.CreateConsumptionJournalLine(ItemJournalBatch, ProdOrderLine, ChildItem, WorkDate(), Location.Code, '', 1, 0);
        ItemJnlLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJnlLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJnlLine.FindFirst();
        ItemJnlLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemJnlLine.Validate("Bin Code", Bin.Code);
        ItemJnlLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);

        // Exercise
        VerifyWhseUOMQty(ChildItem."No.", Location.Code, ChildItem."Base Unit of Measure", 0, 0, 18);
        VerifyWhseUOMQty(ChildItem."No.", Location.Code, ItemUnitOfMeasure.Code, 0, 0, 0);
        VerifyInvtQty(ChildItem."No.", 18);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B27378()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        WhseJnlLine: Record "Warehouse Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        LotNos: array[2] of Code[20];
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO] Warehouse Physical Inventory should not cause rounding residuals

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, true, false);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 30));
        Item.Modify(true);

        LotNos[1] := LibraryUtility.GenerateGUID();
        LotNos[2] := LibraryUtility.GenerateGUID();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", 1, Location.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignMultipleLotNos);
        LibraryVariableStorage.Enqueue(2);
        LibraryVariableStorage.Enqueue(LotNos[1]);
        LibraryVariableStorage.Enqueue(10);
        LibraryVariableStorage.Enqueue(LotNos[2]);
        LibraryVariableStorage.Enqueue(20);
        PurchaseLine.OpenItemTrackingLines();

        SetExpirationDateOnReservationEntry(Item."No.", LotNos[1], WorkDate());
        SetExpirationDateOnReservationEntry(Item."No.", LotNos[2], CalcDate('<+1M>', WorkDate()));

        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);

        // Exercise
        CalculateWhseInventory(WhseJnlLine, Item."No.", Location.Code);
        UpdatePhysInventoryQtyOnWhseJournalLine(
          WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", Location.Code, LotNos[1], 0.2);
        UpdatePhysInventoryQtyOnWhseJournalLine(
          WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", Location.Code, LotNos[2], 0.8);
        LibraryWarehouse.PostWhseJournalLine(
          WhseJnlLine."Journal Template Name", WhseJnlLine."Journal Batch Name", WhseJnlLine."Location Code");

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 0, 0, 30);
        VerifyInvtQty(Item."No.", 30);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B27689()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
    begin
        // [FEATURE] [Warehouse Adjustment] [Item Tracking]
        // [SCENARIO] Warehouse Adjustments should be calculated correctly when using multipleUOM and Item Tracking

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, true);

        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, true, true);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 30));
        Item.Validate("Sales Unit of Measure", Item."Purch. Unit of Measure");
        Item.Modify(true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, '', FindLocationPickZone(Location.Code), FindPutPickBinType());

        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);
        CreateWhseJournalLineWithLotTracking(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin, Item."No.", Item."Purch. Unit of Measure", 5,
          LibraryUtility.GenerateGUID(), CalcDate('<2M>', WorkDate()));

        LibraryWarehouse.PostWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code);

        // Exercise
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 0, 0, 150);
        VerifyInvtQty(Item."No.", 150);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure B29180()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        Location: Record Location;
        I: Integer;
        LotNo: Code[50];
    begin
        // [FEATURE] [Pick]
        // [SCENARIO] Picks should not cause rounding residuals

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, false, false);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 3.33333));
        Item.Validate("Sales Unit of Measure", Item."Purch. Unit of Measure");
        Item.Modify(true);

        LotNo := LibraryUtility.GenerateGUID();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithLotTracking(PurchaseLine, PurchaseHeader, Item."No.", 1, Location.Code, LotNo);
        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);

        // Exercise
        for I := 1 to 2 do begin
            CreateLotTrackedSalesOrder(SalesHeader, Item."No.", 0.5, LotNo, Location.Code);
            PostWarehouseShipmentAndPick(SalesHeader);
        end;

        VerifyWhseAndInvtIsZero(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B29236()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Location: Record Location;
    begin
        // [FEATURE] [Put-Away] [Sales Return]
        // [SCENARIO] It should be possible to post a put-away for a Sales return order

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 20));
        Item.Validate("Sales Unit of Measure", Item."Base Unit of Measure");
        Item.Validate("Put-away Unit of Measure Code", Item."Base Unit of Measure");
        Item.Modify(true);

        CreateAndPostPurchReceiptPutAway(Item."No.", 1, 1, Location.Code);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 20);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 0, 0, 0);
        VerifyInvtQty(Item."No.", 20);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 20, Location.Code);
        PostWarehouseShipmentAndPick(SalesHeader);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), Item."No.", 6,
          Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
              DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Exercise
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 20, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));

        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        FindWhseActivity(
          WarehouseActivityHeader, WarehouseActivityHeader.Type::"Put-away",
          DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 120, 240, 20);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 120, 0, 120);
        VerifyInvtQty(Item."No.", 140);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B29247()
    var
        Item: Record Item;
        BinContent: Record "Bin Content";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Location: Record Location;
    begin
        // [FEATURE] [Pick]
        // [SCENARIO] Quantity (Base) in warehouse activity lines should be recorded correctly

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);
        CreateAndPostPurchReceiptPutAway(Item."No.", 1, 147, Location.Code);

        BinContent.SetRange("Item No.", Item."No.");
        BinContent.FindFirst();
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Min. Qty.", 96);
        BinContent.Validate("Max. Qty.", 192);
        BinContent.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 24, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 24, 24, 147);
        VerifyInvtQty(Item."No.", 147);

        // Exercise
        CreateAndPostPurchReceiptPutAway(Item."No.", 1, 24, Location.Code);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 24, 24, 171);
        VerifyInvtQty(Item."No.", 171);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B29363()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
    begin
        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateLotTrackedItemWithPurchUnitOfMeasure(Item, 10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithLotTracking(PurchaseLine, PurchaseHeader, Item."No.", 2, Location.Code, LibraryUtility.GenerateGUID());
        CreatePurchaseLineWithLotTracking(PurchaseLine, PurchaseHeader, Item."No.", 4, Location.Code, LibraryUtility.GenerateGUID());
        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);

        // Exercise
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 55, Location.Code);
        CreateWhseShipmentAndPickFromSalesOrder(SalesHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 55, 115, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 60, 0, 60);
        VerifyInvtQty(Item."No.", 60);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MsgHandler')]
    [Scope('OnPrem')]
    procedure B29379()
    var
        Item: Record Item;
        WhseActivLine: Record "Warehouse Activity Line";
        Bin: array[2] of Record Bin;
        Zone: Record Zone;
        BinContent: Record "Bin Content";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        Location: Record Location;
    begin
        // [FEATURE] [Warehouse Movement]
        // [SCENARIO] The Create movement function should create a Warehouse Movement document with the correct Quantities

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateLotTrackedItemWithPurchUnitOfMeasure(Item, 10);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithLotTracking(PurchaseLine, PurchaseHeader, Item."No.", 10, Location.Code, LibraryUtility.GenerateGUID());
        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);

        // Exercise
        LibraryWarehouse.FindZone(Zone, Location.Code, FindPutPickBinType(), false);
        LibraryWarehouse.FindBin(Bin[1], Location.Code, Zone.Code, 1);
        LibraryWarehouse.FindBin(Bin[2], Location.Code, Zone.Code, 2);
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin[2], Bin[1], Item."No.", '', 0);
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::MovementWorksheet);
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetLine.Name, Location.Code, "Whse. Activity Sorting Method"::None, false, false);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 100, 100, 100);
        VerifyInvtQty(Item."No.", 100);

        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::"Movement Worksheet");
        WhseActivLine.SetRange("Item No.", Item."No.");
        WhseActivLine.Find('-');
        Assert.AreEqual(10, WhseActivLine.Quantity, '');
        Assert.AreEqual(100, WhseActivLine."Qty. (Base)", '');

        Bin[1].SetRange("Location Code", Location.Code);
        Bin[1].SetRange("Zone Code", WhseActivLine."Zone Code");
        Bin[1].SetFilter(Code, '<>%1', WhseActivLine."Bin Code");
        Bin[1].FindFirst();

        WhseActivLine.Next();
        Assert.AreEqual(10, WhseActivLine.Quantity, '');
        Assert.AreEqual(100, WhseActivLine."Qty. (Base)", '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B31141()
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
    begin
        // [FEATURE] [Pick] [Breakbulk] [Item Tracking]
        // [SCENARIO] It should be possible to create breakbulk picks for lot-tracked items with multiple UOMs.

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, false, false);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 15);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLineWithLotTracking(PurchaseLine, PurchaseHeader, Item."No.", 6, Location.Code, '0001');

        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", 1, Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        PurchaseLine.Modify(true);
        EnqueueLotTrackingParameters('0002', PurchaseLine."Quantity (Base)");
        PurchaseLine.OpenItemTrackingLines();

        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 6);
        VerifyWhseUOMQty(Item."No.", Location.Code, ItemUnitOfMeasure.Code, 0, 0, 15);
        VerifyInvtQty(Item."No.", 21);

        // Exercise
        CreateLotTrackedSalesOrder(SalesHeader, Item."No.", 4, '0002', Location.Code);
        CreateWhseShipmentAndPickFromSalesOrder(SalesHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 4, 19, 6);
        VerifyWhseUOMQty(Item."No.", Location.Code, ItemUnitOfMeasure.Code, 15, 0, 15);
        VerifyInvtQty(Item."No.", 21);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B47530_1()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Pick] [Breakbulk]
        // [SCENARIO] It should be possible to register a pick, even when breakbulk lines are displayed

        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, false, false);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 10);

        B47530(Item, ItemUnitOfMeasure.Code, 50, 50, 50, 0, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B47530_2()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Pick] [Breakbulk]
        // [SCENARIO] It should be possible to register a pick, even when breakbulk lines are displayed

        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, false, false);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 10);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        B47530(Item, ItemUnitOfMeasure.Code, 5, 50, 0, 0, 50);
    end;

    local procedure B47530(Item: Record Item; ItemUoMCode: Code[10]; SalesQty: Decimal; ExpectedQtyToTakeBaseUoM: Decimal; ExpectedQtyToPlaceBaseUoM: Decimal; ExpectedQtyToTakeAltUoM: Decimal; ExpectedQtyToPlaceAltUoM: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        CurrLineNo: Integer;
    begin
        // It should be possible to register a pick, even when breakbulk lines are displayed

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        for CurrLineNo := 1 to 10 do
            CreatePurchaseLineWithLotTracking(PurchaseLine, PurchaseHeader, Item."No.", 10, Location.Code, LibraryUtility.GenerateGUID());

        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);

        // Exercise
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", SalesQty, Location.Code);

        CreateWhseShipmentAndPickFromSalesOrder(SalesHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", ExpectedQtyToTakeBaseUoM, ExpectedQtyToPlaceBaseUoM, 100);
        VerifyWhseUOMQty(Item."No.", Location.Code, ItemUoMCode, ExpectedQtyToTakeAltUoM, ExpectedQtyToPlaceAltUoM, 0);
        VerifyInvtQty(Item."No.", 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B30870()
    var
        CompItem: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
    begin
        // [FEATURE] [Consumption Journal] [Pick]
        // [SCENARIO] It should be possible to change the quantity on consumption journal to <= the quantity of the pick/picked created.

        // Setup
        Initialize();

        CreateFullWMSLocation(Location, false);
        LibraryInventory.CreateItem(CompItem);

        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(CompItem."No.", Location.Code, 50, false);

        CreateItemWithProductionBOM(ParentItem, CompItem."No.", 10);
        CreateProductionOrderAndPickComponents(ProductionOrder, ParentItem."No.", 5, Location.Code, 25);
        CalculateProdOrderConsumption(ItemJnlLine, ProductionOrder."No.");

        // Exercise
        Assert.AreEqual(ItemJnlLine.Quantity, 25, 'Calc Consumption Quantity computed should be no more than that picked');

        asserterror ItemJnlLine.Validate(Quantity, 26);
        AssertRunTime(Format(26 - 25), 'Changing the Quantity computed should be no more than that picked');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B30870_3()
    var
        CompItem: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ItemJnlLine: Record "Item Journal Line";
        Location: Record Location;
    begin
        // [FEATURE] [Manufacturing] [Consumption Journal] [Pick]
        // [SCENARIO] It should be possible to change the quantity on consumption journal to <= the quantity of the pick/picked created.

        // Setup
        Initialize();

        CreateFullWMSLocation(Location, false);
        LibraryInventory.CreateItem(CompItem);

        LibraryWarehouse.UpdateInventoryOnLocationWithDirectedPutAwayAndPick(CompItem."No.", Location.Code, 50, false);

        CreateItemWithProductionBOM(ParentItem, CompItem."No.", 10);
        CreateProductionOrderAndPickComponents(ProductionOrder, ParentItem."No.", 5, Location.Code, 25);
        FindProdOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");

        CreateConsumptionJournalLine(ItemJnlLine, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", CompItem."No.");

        Assert.AreEqual(ItemJnlLine.Quantity, 0, 'Manual entry Consumption should have Qty = 0');

        asserterror ItemJnlLine.Validate(Quantity, 26);

        AssertRunTime(Format(26 - 25), 'Changing the Quantity computed should be no more than that picked');

        ItemJnlLine.Validate(Quantity, 2);
        Assert.AreEqual(ItemJnlLine.Quantity, 2, 'Calc Consumption Quantity computed should be no more than that picked');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure B27337()
    var
        Item: Record Item;
        WhseWkshLine: Record "Whse. Worksheet Line";
        BinContent: Record "Bin Content";
        Bin: array[2] of Record Bin;
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
    begin
        // [FEATURE] [Bin Content] [Warehouse Movement]
        // [SCENARIO] Bin contents should be created when a warehouse movement is posted

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', FindLocationPickZone(Location.Code), FindPutPickBinType());
        Bin[2].Validate("Bin Ranking", 10000);
        Bin[2].Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 10);

        CreateAndPostPurchReceiptPutAway(Item."No.", 1, 10, Location.Code);
        Item.Find();
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
        CreateAndPostPurchReceiptPutAway(Item."No.", 1, 1, Location.Code);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 10);
        VerifyWhseUOMQty(Item."No.", Location.Code, ItemUnitOfMeasure.Code, 0, 0, 10);
        VerifyInvtQty(Item."No.", 20);

        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        Assert.IsTrue(BinContent.FindFirst(), 'Bin Content exists');

        BinContent.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
        Assert.IsTrue(BinContent.FindFirst(), 'Bin Content exists');

        // Exercise
        Bin[1].Get(BinContent."Location Code", BinContent."Bin Code");
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWkshLine, Bin[1], Bin[2], Item."No.", '', 10);
        LibraryWarehouse.CreateWhseMovement(WhseWkshLine.Name, WhseWkshLine."Location Code", "Whse. Activity Sorting Method"::None, false, false);

        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 10);
        VerifyWhseUOMQty(Item."No.", Location.Code, ItemUnitOfMeasure.Code, 0, 0, 10);
        VerifyInvtQty(Item."No.", 20);

        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Item No.", Item."No.");
        BinContent.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        BinContent.SetRange("Bin Code", Bin[2].Code);
        Assert.IsTrue(BinContent.FindFirst(), 'Bin Content exists');

        BinContent.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
        Assert.IsTrue(BinContent.FindFirst(), 'Bin Content exists');
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure B52620()
    var
        Item: Record Item;
        WhseActivLine: Record "Warehouse Activity Line";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        BinContent: Record "Bin Content";
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Location: Record Location;
    begin
        // [FEATURE] [Pick]
        // [SCENARIO] When a Bin contains the same item stored in several units of measure, the picking suggested might have a wrong quantity

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Purch. Unit of Measure", Item."Base Unit of Measure");
        Item.Validate("Put-away Unit of Measure Code", CreateItemUnitOfMeasureCode(Item."No.", 75));
        Item.Modify(true);

        LibraryWarehouse.CreateBin(
          Bin, Location.Code, '', FindLocationPickZone(Location.Code), FindPutPickBinType());

        BinContent.Init();
        BinContent.Validate("Location Code", Location.Code);
        BinContent.Validate("Zone Code", FindLocationPickZone(BinContent."Location Code"));
        BinContent.Validate("Bin Code", Bin.Code);
        BinContent.Validate("Item No.", Item."No.");
        BinContent.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        BinContent.Validate("Bin Type Code", FindPutPickBinType());
        BinContent.Validate("Bin Ranking", 10000);
        BinContent.Validate("Min. Qty.", 101);
        BinContent.Validate("Max. Qty.", 225);
        BinContent.Validate(Fixed, true);
        BinContent.Insert(true);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), Item."No.", 152,
          Location.Code, WorkDate());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
              DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        // [WHEN] Now put multiple UOMs of the same Item in same Bin
        WhseActivLine.SetRange("Item No.", Item."No.");
        WhseActivLine.FindLast();
        WhseActivLine.Validate("Qty. to Handle", 1);
        WhseActivLine.Modify(true);

        TempWhseActivLine := WhseActivLine;
        WhseActivLine.SplitLine(WhseActivLine);
        WhseActivLine.FindLast();
        WhseActivLine.Validate("Zone Code", TempWhseActivLine."Zone Code");
        WhseActivLine.Validate("Bin Code", TempWhseActivLine."Bin Code");
        WhseActivLine.Modify(true);

        TempWhseActivLine := WhseActivLine;
        TempWhseActivLine."Unit of Measure Code" := Item."Base Unit of Measure";
        TempWhseActivLine."Qty. per Unit of Measure" := 1;
        TempWhseActivLine.Validate(Quantity, TempWhseActivLine."Qty. (Base)");
        WhseActivLine.ChangeUOMCode(WhseActivLine, TempWhseActivLine);
        WhseActivLine.Validate("Qty. to Handle", 3);
        WhseActivLine.Modify(true);

        TempWhseActivLine := WhseActivLine;
        WhseActivLine.SplitLine(WhseActivLine);
        WhseActivLine.FindLast();
        WhseActivLine.Validate("Zone Code", FindLocationPickZone(WhseActivLine."Location Code"));
        WhseActivLine.Validate("Bin Code", Bin.Code);
        WhseActivLine.Validate("Qty. to Handle", 74);
        WhseActivLine.Modify(true);

        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, Location.Code);

        WarehouseActivityHeader.Get(WhseActivLine."Activity Type", WhseActivLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        BinContent.SetRange("Item No.", Item."No.");
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, Location.Code, true, true, false);
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetName.Name, Location.Code, "Whse. Activity Sorting Method"::None, false, false);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 78, 153, 77);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Put-away Unit of Measure Code", 75, 0, 75);
        VerifyInvtQty(Item."No.", 152);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B41438()
    var
        Item: Record Item;
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
        I: Integer;
    begin
        // [FEATURE] [Put-Away] [Item Tracking]
        // [SCENARIO] It should be possibe to create put-aways as long the BaseQuantity is an integers for items with Item Tracking

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        CreateSNSpecificItemTrackingCode(ItemTrackingCode, false, false, false);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 6));
        Item.Validate("Sales Unit of Measure", Item."Base Unit of Measure");
        Item.Validate("Put-away Unit of Measure Code", Item."Purch. Unit of Measure");
        Item.Modify(true);

        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorNo(), Item."No.", 3.5, Location.Code, 0D);
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignMultipleSN);
        LibraryVariableStorage.Enqueue(PurchaseLine."Quantity (Base)");
        for I := 1 to PurchaseLine."Quantity (Base)" do
            LibraryVariableStorage.Enqueue(Format(I));
        PurchaseLine.OpenItemTrackingLines();
        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);

        ItemLedgEntry.SetRange("Item No.", Item."No.");
        ItemLedgEntry.SetFilter(Quantity, '<>1');
        Assert.RecordIsEmpty(ItemLedgEntry);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 0, 0, 21);
        VerifyInvtQty(Item."No.", 21);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item."No.", 1, Location.Code);
        PurchaseLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PurchaseLine.Validate("Qty. to Receive", 0.5);
        PurchaseLine.Validate("Qty. to Invoice", 0.5);
        PurchaseLine.Modify(true);

        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignManualSN);
        LibraryVariableStorage.Enqueue('0001');
        PurchaseLine.OpenItemTrackingLines();

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Purch. Unit of Measure", 0, 0, 21);
        VerifyInvtQty(Item."No.", 21);

        WhseRcptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
              DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));

        WhseRcptLine.SetRange("No.", WhseRcptHeader."No.");
        WhseRcptLine.FindFirst();
        asserterror WhseRcptLine.Validate("Qty. to Receive", 0.5);
        AssertRunTime('integer', 'It should not be possible to receive ratios of items that are serial nos. tracked');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B41269()
    var
        Item: Record Item;
        WhseShptHeader: Record "Warehouse Shipment Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        // [FEATURE] [Breakbulk]
        // [SCENARIO] It should be possible to Breakbulk from smaller UOM to Larger

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 12));
        Item.Modify(true);

        CreateAndPostPurchReceiptPutAway(Item."No.", 1, 12, Location.Code);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 1, Location.Code, 0D);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShptHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.ReleaseWarehouseShipment(WhseShptHeader);

        WhsePickRequest.Get(
          WhsePickRequest."Document Type"::Shipment, 0, WhseShptHeader."No.", Location.Code);

        LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWorksheetLine, WhsePickRequest, WhseWorksheetName.Name);
        WhseWorksheetLine.FindFirst();
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", WhseWorksheetLine.Name,
          Location.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
        PostPickFromSalesLine(SalesLine);

        // Exercise
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Sales Unit of Measure", 0, 0, 12);
        VerifyInvtQty(Item."No.", 12);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure B41289()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Location: Record Location;
    begin
        // [FEATURE] [Pick] [Breakbulk]
        // [SCENARIO] It should be possible to Breakbulk Pick from Smaller to Larger UOM's

        // Setup
        Initialize();
        CreateFullWMSLocation(Location, false);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 3));
        Item.Modify(true);

        CreateAndPostPurchReceiptPutAway(Item."No.", 1, 2, Location.Code);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 1, Location.Code);
        CreateSalesLine(SalesLine, SalesHeader, Item."No.", 1, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        PostPickFromSalesLine(SalesLine);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        VerifyWhseAndInvtIsZero(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B42422()
    var
        Item: Record Item;
        Bin: Record Bin;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TrackingSpecification: Record "Tracking Specification";
        Location: Record Location;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] It should be possible to receive an item even when other open orders for the same Item exist that use serial nos.

        // Setup
        Initialize();

        CreateSNSpecificItemTrackingCode(ItemTrackingCode, false, false, false);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');

        TrackingSpecification.SetRange("Item No.", Item."No.");
        Assert.AreEqual(TrackingSpecification.Count, 0, '');

        // Exercise
        CreateAndReceivePurchaseOrderWithSNTracking(PurchaseHeader, Item."No.", Location.Code, Bin.Code, 'T1');
        Assert.AreEqual(TrackingSpecification.Count, 1, '');
        CreateAndReceivePurchaseOrderWithSNTracking(PurchaseHeader, Item."No.", Location.Code, Bin.Code, 'T2');
        Assert.AreEqual(TrackingSpecification.Count, 2, '');

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        Assert.AreEqual(TrackingSpecification.Count, 1, '');

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 1, Location.Code, WorkDate());
        SalesLine.Validate("Bin Code", Bin.Code);
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignManualSN);
        LibraryVariableStorage.Enqueue('T1');
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        Assert.AreEqual(TrackingSpecification.Count, 2, '');

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.", Item."No.", 1,
          Location.Code, WorkDate());
        SalesLine.Validate("Bin Code", Bin.Code);
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignManualSN);
        LibraryVariableStorage.Enqueue('T2');
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        Assert.AreEqual(TrackingSpecification.Count, 3, '');

        LibrarySales.PostSalesDocument(SalesHeader, false, true);
        Assert.AreEqual(TrackingSpecification.Count, 2, '');

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 0);
        VerifyInvtQty(Item."No.", 0);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure B327742()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        UOMCodes: array[2] of Code[10];
        LotNo: Code[50];
    begin
        // [FEATURE] [Warehouse Adjustment] [Item Tracking]
        // [SCENARIO 327742] Warehouse Adjustments should be calculated correctly when using multipleUOM and Item Tracking

        // Setup
        Initialize();

        CreateFullWMSLocation(Location, true);
        Location.Validate("Always Create Pick Line", true);
        Location.Modify(true);

        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, false, false);

        LibraryInventory.CreateItem(Item);
        Item.Validate("Sales Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", 0.1));
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
        UOMCodes[1] := CreateItemUnitOfMeasureCode(Item."No.", 0.4);
        UOMCodes[2] := CreateItemUnitOfMeasureCode(Item."No.", 8);

        LibraryWarehouse.CreateBin(Bin, Location.Code, '', FindLocationPickZone(Location.Code), FindPutPickBinType());

        LotNo := LibraryUtility.GenerateGUID();
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, WarehouseJournalTemplate.Name, Location.Code);

        CreateWhseJournalLineWithLotTracking(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin, Item."No.",
          Item."Sales Unit of Measure", 616, LotNo, 0D);
        CreateWhseJournalLineWithLotTracking(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin, Item."No.", UOMCodes[2], 11, LotNo, 0D);
        CreateWhseJournalLineWithLotTracking(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin, Item."No.", UOMCodes[1], 38, LotNo, 0D);
        LibraryWarehouse.PostWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code);

        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Base Unit of Measure", 0, 0, 0);
        VerifyWhseUOMQty(Item."No.", Location.Code, UOMCodes[1], 0, 0, 0.4 * 38);
        VerifyWhseUOMQty(Item."No.", Location.Code, Item."Sales Unit of Measure", 0, 0, 0.1 * 616);
        VerifyWhseUOMQty(Item."No.", Location.Code, UOMCodes[2], 0, 0, 8 * 11);
        VerifyInvtQty(Item."No.", 164.8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfOnStockWithWarehouseEntry()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if residual Qty with Warehouse Entry exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        CreateWarehouseEntry(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfOutstandingQtyPurch()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if Outstanding Qty in Purchase Line exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        MockPurchaseLine(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfOutstandingQtySales()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if Outstanding Qty in Sales Line exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        MockSalesLine(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfOutstandingQtyTransfer()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT] [Transfer]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if Outstanding Qty in Transfer Line exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        CreateTransferLine(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfRemainingQtyProduction()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT] [Manufacturing] [Production Order]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if Remaining Qty in Production Order Line exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        CreateProductionOrderLine(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfRemainingQtyProdComponent()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT] [Manufacturing] [Production Order Component]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if Remaining Qty in Production Component exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        CreateProductionComponent(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfOutstandingQtyService()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if Outstanding Qty in Service Line exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        CreateServiceLine(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfRemainingQtyAssemblyHeader()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT] [Assembly]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if Remaining Qty in Assembly Header exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        CreateAssemblyHeader(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUOMChangesIfRemainingQtyAssemblyLine()
    var
        Item: Record Item;
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [UT] [Assembly]
        // [SCENARIO 215278] It should not be possible to change "Qty. per Unit of Measure" for Item Unit of Measure if Remaining Qty in Assembly Line exists.

        // Setup.
        UnitOfMeasureCode := PrepareQtyPerUOMChange(Item);
        CreateAssemblyLine(Item."No.", UnitOfMeasureCode);

        // Exercise.
        asserterror ChangeQtyPerUOM(Item."No.", UnitOfMeasureCode);

        // Verify.
        Assert.ExpectedError(CannotModifyUOMErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryQtyWhseJournalLineUpdatesQtyBase()
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Item: Record Item;
        Qty: Decimal;
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO] Changing the value of "Qty. (Phys. Inventory)" in warehouse journal line should update fields "Quantity" and "Quantity (Base)"

        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateFullWMSLocation(Location, false);

        // [GIVEN] Create a warehouse journal line in a physical inventory template
        CreateWarehouseJournalLinePhysInventory(WarehouseJournalLine, Location.Code, Item."No.", Item."Base Unit of Measure");

        // [WHEN] Set "Qty. (Phys. Inventory)" = 10
        Qty := LibraryRandom.RandDec(100, 2);
        WarehouseJournalLine.Validate("Qty. (Phys. Inventory)", Qty);

        // [THEN] "Quantity" and "Qty. (Base)" are both updated to 10
        WarehouseJournalLine.TestField(Quantity, Qty);
        WarehouseJournalLine.TestField("Qty. (Base)", Qty);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryQtyWhseJournalLineConsidersQtyCalculated()
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Item: Record Item;
        Qty: Decimal;
        QtyCalculated: Decimal;
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO] When updating the quantity for physical inventory in the wareheouse journal, "Qty. (Calculated)" shoud be considered

        Initialize();

        LibraryInventory.CreateItem(Item);
        CreateFullWMSLocation(Location, false);

        // [GIVEN] Create a warehouse journal line in a physical inventory template
        CreateWarehouseJournalLinePhysInventory(WarehouseJournalLine, Location.Code, Item."No.", Item."Base Unit of Measure");

        // [GIVEN] Set "Qty. (Calculated)" = 8
        Qty := LibraryRandom.RandDecInRange(150, 300, 2);
        QtyCalculated := LibraryRandom.RandDecInRange(50, 100, 2);
        WarehouseJournalLine.Validate("Qty. (Calculated)", QtyCalculated);
        WarehouseJournalLine.Validate("Qty. (Calculated) (Base)", QtyCalculated);

        // [WHEN] Set "Qty. (Phys. Inventory)" = 5
        WarehouseJournalLine.Validate("Qty. (Phys. Inventory)", Qty);

        // [THEN] "Quantity" = 5 - 8 = -3, "Qty. (Base)" = 5 - 8 = -3
        WarehouseJournalLine.TestField(Quantity, Qty - QtyCalculated);
        WarehouseJournalLine.TestField("Qty. (Base)", Qty - QtyCalculated);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryQtyAndQtyCalculatedMultipliedByQtyPerUOM()
    var
        Location: Record Location;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Qty: Decimal;
        QtyCalculated: Decimal;
    begin
        // [FEATURE] [Physical Inventory]
        // [SCENARIO] When updating the quantity for physical inventory in the wareheouse journal, all quantities should be counted in the unit of measure stated in the journal line

        Initialize();

        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(10, 20));

        CreateFullWMSLocation(Location, false);

        // [GIVEN] Create a warehouse journal line in a physical inventory template, "Qty. per unit of measure" = 3
        CreateWarehouseJournalLinePhysInventory(WarehouseJournalLine, Location.Code, Item."No.", ItemUnitOfMeasure.Code);

        // [GIVEN] Set "Qty. (Calculated)" = 8
        Qty := LibraryRandom.RandDecInRange(150, 300, 2);
        QtyCalculated := LibraryRandom.RandDecInRange(50, 100, 2);
        WarehouseJournalLine.Validate("Qty. (Calculated)", QtyCalculated);
        WarehouseJournalLine.Validate("Qty. (Calculated) (Base)", QtyCalculated * ItemUnitOfMeasure."Qty. per Unit of Measure");

        // [WHEN] Set "Qty. (Phys. Inventory)" = 5
        WarehouseJournalLine.Validate("Qty. (Phys. Inventory)", Qty);

        // [THEN] "Quantity" = (5 - 8) * 3 = -9, "Qty. (Base)" = (5 - 8) * 3 = -9
        WarehouseJournalLine.TestField(Quantity, Qty - QtyCalculated);
        WarehouseJournalLine.TestField("Qty. (Base)", (Qty - QtyCalculated) * ItemUnitOfMeasure."Qty. per Unit of Measure");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM WMS Item Unit of Measure");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM WMS Item Unit of Measure");

        LibraryPatterns.SetNoSeries();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM WMS Item Unit of Measure");
    end;

    local procedure CalculateProdOrderConsumption(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryManufacturing.CalculateConsumption(ProdOrderNo, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProdOrderNo);
        ItemJournalLine.FindSet();
    end;

    local procedure CalculateWhseInventory(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::"Physical Inventory");
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseCalculateInventory(WarehouseJournalLine, BinContent, WorkDate(), LibraryUtility.GenerateGUID(), false);  // False for Item not on Inventory.
    end;

    local procedure ChangeQtyPerUOM(ItemNo: Code[20]; UOMCode: Code[10])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.Get(ItemNo, UOMCode);
        ItemUnitOfMeasure.Validate("Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure" + LibraryRandom.RandInt(10));
        ItemUnitOfMeasure.Modify();
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithUnitOfMeasure(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; UOMCode: Code[10])
    begin
        CreateSalesLine(SalesLine, SalesHeader, ItemNo, Quantity, LocationCode);
        SalesLine.Validate("Unit of Measure Code", UOMCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostPurchReceiptPutAway(ItemNo: Code[20]; NoOfLines: Integer; QtyPerLine: Decimal; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CurrLine: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        for CurrLine := 1 to NoOfLines do
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, QtyPerLine, LocationCode);

        PostWhseReceiptAndPutAwayFromPurchOrder(PurchaseHeader);
    end;

    local procedure CreateAndPostWhseJnlB25525(Item: Record Item; LocationCode: Code[10]; ExpDate1: Date; ExpDate2: Date; ExpDate3: Date; ExpDate4: Date; ExpDate5: Date)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);

        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.DeleteAll();

        CreateWhseJournalLineWithLotTrackingOnNewBin(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Item."No.", Item."Purch. Unit of Measure",
          1, '0001', ExpDate1, LocationCode);

        CreateWhseJournalLineWithLotTrackingOnNewBin(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Item."No.", Item."Purch. Unit of Measure",
          1, '0003', ExpDate2, LocationCode);

        CreateWhseJournalLineWithLotTrackingOnNewBin(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Item."No.", Item."Base Unit of Measure",
          2, '0002', ExpDate3, LocationCode);

        CreateWhseJournalLineWithLotTrackingOnNewBin(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Item."No.", Item."Base Unit of Measure",
          3, '0006', ExpDate4, LocationCode);

        CreateWhseJournalLineWithLotTrackingOnNewBin(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Item."No.", Item."Base Unit of Measure",
          27, '0000', ExpDate5, LocationCode);

        LibraryWarehouse.PostWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, LocationCode);
        CreateAndPostWhseAdjmt(Item."No.");
    end;

    local procedure CreateAndPostWhseJnlB25525_NoTracking(Item: Record Item; LocationCode: Code[10])
    var
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);

        LibraryWarehouse.CreateBin(Bin, LocationCode, '', FindLocationPickZone(LocationCode), FindPutPickBinType());
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin."Location Code", Bin."Zone Code", Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        WarehouseJournalLine.Validate("Unit of Measure Code", Item."Purch. Unit of Measure");
        WarehouseJournalLine.Modify(true);

        LibraryWarehouse.CreateBin(Bin, LocationCode, '', FindLocationPickZone(LocationCode), FindPutPickBinType());
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin."Location Code", Bin."Zone Code", Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        WarehouseJournalLine.Validate("Unit of Measure Code", Item."Purch. Unit of Measure");
        WarehouseJournalLine.Modify(true);

        LibraryWarehouse.CreateBin(Bin, LocationCode, '', FindLocationPickZone(LocationCode), FindPutPickBinType());
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin."Location Code", Bin."Zone Code", Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 2);

        LibraryWarehouse.CreateBin(Bin, LocationCode, '', FindLocationPickZone(LocationCode), FindPutPickBinType());
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin."Location Code", Bin."Zone Code", Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 3);

        LibraryWarehouse.CreateBin(Bin, LocationCode, '', FindLocationPickZone(LocationCode), FindPutPickBinType());
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin."Location Code", Bin."Zone Code", Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 27);

        LibraryWarehouse.PostWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, LocationCode);
        CreateAndPostWhseAdjmt(Item."No.");
    end;

    local procedure CreateAndPostWhseAdjmt(ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateAndPostSalesB25525(ItemNo: Code[20]; LocationCode: Code[10]; var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), ItemNo, 2, LocationCode, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        FindWhseActivity(
          WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, DATABASE::"Sales Line",
          SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
    end;

    local procedure CreateAndReceivePurchaseOrderWithSNTracking(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; SerialNo: Code[50])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), ItemNo, 1,
          LocationCode, 0D);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignManualSN);
        LibraryVariableStorage.Enqueue(SerialNo);
        PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAssemblyHeader(ItemNo: Code[20]; UOMCode: Code[10])
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Quote;
        AssemblyHeader."No." := LibraryUtility.GenerateGUID();
        AssemblyHeader."Item No." := ItemNo;
        AssemblyHeader."Remaining Quantity" := LibraryRandom.RandIntInRange(10, 100);
        AssemblyHeader."Unit of Measure Code" := UOMCode;
        AssemblyHeader.Insert();
    end;

    local procedure CreateAssemblyLine(ItemNo: Code[20]; UOMCode: Code[10])
    var
        AssemblyLine: Record "Assembly Line";
    begin
        AssemblyLine.Init();
        AssemblyLine."Document Type" := AssemblyLine."Document Type"::Quote;
        AssemblyLine."Document No." := LibraryUtility.GenerateGUID();
        AssemblyLine."Line No." := 10000;
        AssemblyLine.Type := AssemblyLine.Type::Item;
        AssemblyLine."No." := ItemNo;
        AssemblyLine."Remaining Quantity" := LibraryRandom.RandIntInRange(10, 100);
        AssemblyLine."Unit of Measure Code" := UOMCode;
        AssemblyLine.Insert();
    end;

    local procedure CreateConsumptionJournalLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Consumption);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);

        ItemJournalLine.Init();
        ItemJournalLine."Line No." := ItemJournalLine."Line No." + 10000;
        ItemJournalLine.Validate("Journal Template Name", ItemJournalTemplate.Name);
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.Validate("Line No.", LibraryUtility.GetNewRecNo(ItemJournalLine, ItemJournalLine.FieldNo("Line No.")));

        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.Validate("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.Validate("Order No.", ProdOrderNo);
        ItemJournalLine.Validate("Order Line No.", ProdOrderLineNo);
        ItemJournalLine.Validate("Item No.", ItemNo);
        ItemJournalLine.Insert(true);
    end;

    local procedure CreateFullWMSLocation(var Location: Record Location; FEFO: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange(Default, true);
        WarehouseEmployee.DeleteAll();

        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        Location.Validate("Pick According to FEFO", FEFO);
        Location.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, true, true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemUnitOfMeasureCode(ItemNo: Code[20]; QtyPerUoM: Decimal): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, QtyPerUoM);
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure CreateItemWithProductionBOM(var ParentItem: Record Item; CompItemNo: Code[20]; QtyPerLine: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ParentItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItemNo, QtyPerLine);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateItemWithPurchSaleAndPutAwayUnitOfMeasure(var Item: Record Item; ItemTrackingCode: Code[10]; QtyPerPurchSaleUOM: Decimal; QtyPerPutAwayUOM: Decimal)
    begin
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", QtyPerPurchSaleUOM));
        Item.Validate("Sales Unit of Measure", Item."Purch. Unit of Measure");
        if QtyPerPutAwayUOM <> 0 then
            Item.Validate("Put-away Unit of Measure Code", CreateItemUnitOfMeasureCode(Item."No.", QtyPerPutAwayUOM));
        Item.Modify(true);
    end;

    local procedure CreateLotTrackedItemWithPurchUnitOfMeasure(var Item: Record Item; QtyPerUOM: Decimal)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateLotSpecificItemTrackingCode(ItemTrackingCode, true, false, false);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        Item.Validate("Purch. Unit of Measure", CreateItemUnitOfMeasureCode(Item."No.", QtyPerUOM));
        Item.Modify(true);
    end;

    local procedure CreateLotTrackedSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, ItemNo, Quantity, LocationCode);
        EnqueueLotTrackingParameters(LotNo, SalesLine."Quantity (Base)");
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateLotSpecificItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; LotWarehouseTracking: Boolean; StrictExpirationPosting: Boolean; ManExpirDateEntry: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotWarehouseTracking);
        ItemTrackingCode.Validate("Use Expiration Dates", StrictExpirationPosting or ManExpirDateEntry);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntry);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateSNSpecificItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; SNWarehouseTracking: Boolean; StrictExpirationPosting: Boolean; ManExpirDateEntry: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", SNWarehouseTracking);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntry);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreatePurchaseLineWithLotTracking(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; LotNo: Code[50])
    begin
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, Quantity, LocationCode);
        EnqueueLotTrackingParameters(LotNo, PurchaseLine."Quantity (Base)");
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateTransferLine(ItemNo: Code[20]; UOMCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.Init();
        TransferLine."Document No." := LibraryUtility.GenerateGUID();
        TransferLine."Line No." := 10000;
        TransferLine."Item No." := ItemNo;
        TransferLine."Outstanding Quantity" := LibraryRandom.RandIntInRange(10, 100);
        TransferLine."Unit of Measure Code" := UOMCode;
        TransferLine.Insert();
    end;

    local procedure CreateProductionOrderAndPickComponents(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; QtyToPick: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateAndRefreshProductionOrder(ProductionOrder, ItemNo, Quantity, LocationCode);
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        SetHandlingParametersOnWhseActivityLines(
          WarehouseActivityHeader.Type::Pick, DATABASE::"Prod. Order Component",
          ProductionOrder.Status.AsInteger(), ProductionOrder."No.", QtyToPick, '');

        FindWhseActivity(
          WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, DATABASE::"Prod. Order Component",
          ProductionOrder.Status.AsInteger(), ProductionOrder."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure CreateProductionOrderLine(ItemNo: Code[20]; UOMCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Init();
        ProdOrderLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderLine."Line No." := 10000;
        ProdOrderLine."Item No." := ItemNo;
        ProdOrderLine."Remaining Quantity" := LibraryRandom.RandIntInRange(10, 100);
        ProdOrderLine."Unit of Measure Code" := UOMCode;
        ProdOrderLine.Insert();
    end;

    local procedure CreateProductionComponent(ItemNo: Code[20]; UOMCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Init();
        ProdOrderComponent."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderComponent."Prod. Order Line No." := 10000;
        ProdOrderComponent."Line No." := 10000;
        ProdOrderComponent."Item No." := ItemNo;
        ProdOrderComponent."Remaining Quantity" := LibraryRandom.RandIntInRange(10, 100);
        ProdOrderComponent."Unit of Measure Code" := UOMCode;
        ProdOrderComponent.Insert();
    end;

    local procedure CreateServiceLine(ItemNo: Code[20]; UOMCode: Code[10])
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Init();
        ServiceLine."Document Type" := ServiceLine."Document Type"::Order;
        ServiceLine."Document No." := LibraryUtility.GenerateGUID();
        ServiceLine."Line No." := 10000;
        ServiceLine.Type := ServiceLine.Type::Item;
        ServiceLine."No." := ItemNo;
        ServiceLine."Outstanding Quantity" := LibraryRandom.RandIntInRange(10, 100);
        ServiceLine."Unit of Measure Code" := UOMCode;
        ServiceLine.Insert();
    end;

    local procedure CreateWarehouseJournalLinePhysInventory(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; ItemNo: Code[20]; ItemUnitOfMeasureCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::"Physical Inventory");
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, LocationCode, '', '',
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 0);
        WarehouseJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasureCode);
        WarehouseJournalLine.Validate("Phys. Inventory", true);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure CreateWhseJournalLineWithLotTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; WhseJnlTemplateName: Code[10]; WhseJnlBatchName: Code[10]; Bin: Record Bin; ItemNo: Code[20]; UoMCode: Code[10]; Quantity: Decimal; LotNo: Code[50]; ExpirationDate: Date)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WhseJnlTemplateName, WhseJnlBatchName, Bin."Location Code", Bin."Zone Code",
          Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);

        WarehouseJournalLine.Validate("Unit of Measure Code", UoMCode);
        WarehouseJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(WarehouseJournalLine."Qty. (Base)");
        WarehouseJournalLine.OpenItemTrackingLines();

        WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Warehouse Journal Line");
        WhseItemTrackingLine.SetRange("Source ID", WarehouseJournalLine."Journal Batch Name");
        WhseItemTrackingLine.SetRange("Source Batch Name", WarehouseJournalLine."Journal Template Name");
        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseJournalLine."Line No.");
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure CreateWhseJournalLineWithLotTrackingOnNewBin(var WarehouseJournalLine: Record "Warehouse Journal Line"; WhseJnlTemplateName: Code[10]; WhseJnlBatchName: Code[10]; ItemNo: Code[20]; UOMCode: Code[10]; Quantity: Decimal; LotNo: Code[50]; ExpirationDate: Date; LocationCode: Code[10])
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, '', FindLocationPickZone(LocationCode), FindPutPickBinType());
        CreateWhseJournalLineWithLotTracking(
          WarehouseJournalLine, WhseJnlTemplateName, WhseJnlBatchName, Bin, ItemNo, UOMCode, Quantity, LotNo, ExpirationDate);
    end;

    local procedure CreateWhseShipmentAndPickFromSalesOrder(var SalesHeader: Record "Sales Header"): Code[20]
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        exit(WarehouseShipmentHeader."No.");
    end;

    local procedure CreateWarehouseEntry(ItemNo: Code[20]; UOMCode: Code[10])
    var
        WarehouseEntry: Record "Warehouse Entry";
        EntryNo: Integer;
    begin
        WarehouseEntry.FindLast();
        EntryNo := WarehouseEntry."Entry No." + 1;
        WarehouseEntry.Init();
        WarehouseEntry."Entry No." := EntryNo;
        WarehouseEntry."Item No." := ItemNo;
        WarehouseEntry.Quantity := LibraryRandom.RandIntInRange(10, 100);
        WarehouseEntry.Validate("Unit of Measure Code", UOMCode);
        WarehouseEntry.Insert();
    end;

    local procedure EnqueueLotTrackingParameters(LotNo: Code[50]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingOption::AssignManualLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
    end;

    local procedure FindLocationPickZone(LocationCode: Code[10]): Code[10]
    var
        Zone: Record Zone;
    begin
        LibraryWarehouse.FindZone(Zone, LocationCode, FindPutPickBinType(), false);
        exit(Zone.Code);
    end;

    local procedure FindPutPickBinType(): Code[10]
    begin
        exit(LibraryWarehouse.SelectBinType(false, false, true, true));
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindWhseActivity(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ActivityType: Enum "Warehouse Activity Type"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLines(WarehouseActivityLine, ActivityType, SourceType, SourceSubtype, SourceNo);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindWhseActivityLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20])
    begin
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Source Type", SourceType);
        WarehouseActivityLine.SetRange("Source Subtype", SourceSubtype);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.FindSet();
    end;

    local procedure PostProdOrderConsumption(ProdOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CalculateProdOrderConsumption(ItemJournalLine, ProdOrderNo);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostPickFromSalesLine(SalesLine: Record "Sales Line")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWhseActivity(
          WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, DATABASE::"Sales Line",
          SalesLine."Document Type".AsInteger(), SalesLine."Document No.");

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PostWhseShptFromSalesLine(SalesLine: Record "Sales Line")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
              DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No."));

        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure MockPurchaseLine(ItemNo: Code[20]; UOMCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := ItemNo;
        PurchaseLine."Outstanding Quantity" := LibraryRandom.RandIntInRange(10, 100);
        PurchaseLine."Unit of Measure Code" := UOMCode;
        PurchaseLine.Insert();
    end;

    local procedure MockSalesLine(ItemNo: Code[20]; UOMCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesLine."Document Type"::Order;
        SalesLine."Document No." := LibraryUtility.GenerateGUID();
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := ItemNo;
        SalesLine."Outstanding Quantity" := LibraryRandom.RandIntInRange(10, 100);
        SalesLine."Unit of Measure Code" := UOMCode;
        SalesLine.Insert();
    end;

    local procedure PostWhseReceiptAndPutAwayFromPurchOrder(var PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptHeader.Get(
          LibraryWarehouse.FindWhseReceiptNoBySourceDoc(
              DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        FindWhseActivity(
          WarehouseActivityHeader, WarehouseActivityHeader.Type::"Put-away",
          DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure PostWarehouseShipmentAndPick(var SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseShipmentHeader.Get(CreateWhseShipmentAndPickFromSalesOrder(SalesHeader));
        FindWhseActivity(
          WarehouseActivityHeader, WarehouseActivityHeader.Type::Pick, DATABASE::"Sales Line",
          SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        WarehouseActivityLine.DeleteBinContent(enum::"Warehouse Action Type"::Take.AsInteger());
        WarehouseActivityLine.DeleteBinContent(enum::"Warehouse Action Type"::Place.AsInteger());
    end;

    local procedure PrepareQtyPerUOMChange(var Item: Record Item): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(10, 100));
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure SetExpirationDateOnReservationEntry(ItemNo: Code[20]; LotNo: Code[50]; NewExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.ModifyAll("Expiration Date", NewExpirationDate);
    end;

    local procedure SetHandlingParametersOnWhseActivityLines(ActivityType: Enum "Warehouse Activity Type"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; QtyToHandle: Decimal; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLines(WarehouseActivityLine, ActivityType, SourceType, SourceSubtype, SourceNo);
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateItemInventoryOnWMSLocationSplitByLotNo(var Item: Record Item; var Location: Record Location; IsFEFO: Boolean; QtyPerUOM: Decimal)
    begin
        CreateFullWMSLocation(Location, IsFEFO);
        CreateItemWithPurchSaleAndPutAwayUnitOfMeasure(Item, CreateItemTrackingCode(), QtyPerUOM, 0);
        CreateAndPostWhseJnlB25525(Item, Location.Code, WorkDate(), WorkDate(), WorkDate(), WorkDate(), WorkDate());
    end;

    local procedure UpdatePhysInventoryQtyOnWhseJournalLine(JnlTemplateName: Code[10]; JnlBatchName: Code[10]; LocationCode: Code[10]; LotNo: Code[50]; NewPhysInvQty: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine.SetRange("Journal Template Name", JnlTemplateName);
        WarehouseJournalLine.SetRange("Journal Batch Name", JnlBatchName);
        WarehouseJournalLine.SetRange("Location Code", LocationCode);
        WarehouseJournalLine.SetRange("Lot No.", LotNo);
        WarehouseJournalLine.FindFirst();
        WarehouseJournalLine.Validate("Qty. (Phys. Inventory)", NewPhysInvQty);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure VerifyWhseAndInvtIsZero(ItemNo: Code[20])
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
        DummyBinContent: Record "Bin Content";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.", "Entry Type");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.CalcSums(Quantity);
        ItemLedgEntry.TestField(Quantity, 0);

        WhseEntry.SetCurrentKey("Item No.");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.CalcSums("Qty. (Base)");
        WhseEntry.TestField("Qty. (Base)", 0);

        DummyBinContent.SetCurrentKey("Item No.");
        DummyBinContent.SetRange("Item No.", ItemNo);
        DummyBinContent.SetRange(Fixed, false);
        if DummyBinContent.FindFirst() then begin
            DummyBinContent.CalcFields(Quantity);
            Assert.AreEqual(0, DummyBinContent.Quantity, 'Quantity must be 0 for this bin content.');
        end;
    end;

    local procedure VerifyWhseUOMQty(ItemNo: Code[20]; LocationCode: Code[10]; UOMCode: Code[20]; QtyToTakeBase: Decimal; QtyToPlaceBase: Decimal; QtyOnWhseBase: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code", "Unit of Measure Code");
        WhseActivLine.SetRange("Item No.", ItemNo);
        WhseActivLine.SetRange("Location Code", LocationCode);
        WhseActivLine.SetRange("Unit of Measure Code", UOMCode);
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
        WhseActivLine.CalcSums("Qty. (Base)");
        WhseActivLine.TestField("Qty. (Base)", QtyToTakeBase);

        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        WhseActivLine.CalcSums("Qty. (Base)");
        WhseActivLine.TestField("Qty. (Base)", QtyToPlaceBase);

        WhseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code", "Unit of Measure Code");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Location Code", LocationCode);
        WhseEntry.SetRange("Unit of Measure Code", UOMCode);
        WhseEntry.CalcSums("Qty. (Base)");
        WhseEntry.TestField("Qty. (Base)", QtyOnWhseBase);
    end;

    local procedure VerifyWhseBinQty(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[20]; QtyToTakeBase: Decimal; QtyToPlaceBase: Decimal; QtyOnWhseBase: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code", "Unit of Measure Code");
        WhseActivLine.SetRange("Item No.", ItemNo);
        WhseActivLine.SetRange("Location Code", LocationCode);
        WhseActivLine.SetRange("Bin Code", BinCode);
        WhseActivLine.SetRange("Unit of Measure Code", UOMCode);
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
        WhseActivLine.CalcSums("Qty. (Base)");
        WhseActivLine.TestField("Qty. (Base)", QtyToTakeBase);

        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        WhseActivLine.CalcSums("Qty. (Base)");
        WhseActivLine.TestField("Qty. (Base)", QtyToPlaceBase);

        WhseEntry.SetCurrentKey("Item No.", "Location Code", "Variant Code", "Bin Type Code", "Unit of Measure Code");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.SetRange("Location Code", LocationCode);
        WhseEntry.SetRange("Unit of Measure Code", UOMCode);
        WhseEntry.CalcSums("Qty. (Base)");
        WhseEntry.TestField("Qty. (Base)", QtyOnWhseBase);
    end;

    local procedure VerifyInvtQty(ItemNo: Code[20]; ExpectedQty: Decimal)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
    begin
        ItemLedgEntry.SetCurrentKey("Item No.", "Entry Type");
        ItemLedgEntry.SetRange("Item No.", ItemNo);
        ItemLedgEntry.CalcSums(Quantity);
        ItemLedgEntry.TestField(Quantity, ExpectedQty);

        WhseEntry.SetCurrentKey("Item No.");
        WhseEntry.SetRange("Item No.", ItemNo);
        WhseEntry.CalcSums("Qty. (Base)");
        WhseEntry.TestField("Qty. (Base)", ExpectedQty);
    end;

    local procedure AssertRunTime(ExpectedErrorTextContains: Text[1024]; Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(GetLastErrorText, ExpectedErrorTextContains) > 0, Message);
        ClearLastError();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(msg: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        I: Integer;
        NoOfTrackingLines: Integer;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingOption::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingOption::AssignManualLotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            ItemTrackingOption::AssignMultipleLotNos:
                begin
                    NoOfTrackingLines := LibraryVariableStorage.DequeueInteger();
                    for I := 1 to NoOfTrackingLines do begin
                        ItemTrackingLines.New();
                        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    end;
                end;
            ItemTrackingOption::AssignManualSN:
                begin
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
                end;
            ItemTrackingOption::AssignMultipleSN:
                begin
                    NoOfTrackingLines := LibraryVariableStorage.DequeueInteger();
                    for I := 1 to NoOfTrackingLines do begin
                        ItemTrackingLines.New();
                        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                        ItemTrackingLines."Quantity (Base)".SetValue(1);
                    end;
                end;
        end;

        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

