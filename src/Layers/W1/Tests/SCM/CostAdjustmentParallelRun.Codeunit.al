codeunit 137103 "Cost Adjustment Parallel Run"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Cost Adjustment] [SCM] [Concurrent Posting]
        Initialized := false;
    end;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Initialized: Boolean;

    local procedure Initialize()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        SequenceNoMgt.ClearState();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Cost Adjustment Parallel Run");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Cost Adjustment Parallel Run");

        LibrarySetupStorage.SaveInventorySetup();

        Initialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Cost Adjustment Parallel Run");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ItemJournalPost_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        ItemJournalline: Record "Item Journal Line";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(2), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(3), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(4), 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create item journal lines for the second and fourth item.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalline, ItemNos.Get(2), '', '', -10);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalline, ItemNos.Get(4), '', '', -10);

        SequenceNoMgt.ClearState();

        // [WHEN] Post the item journal order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryInventory.PostItemJournalLine(ItemJournalline."Journal Template Name", ItemJournalline."Journal Batch Name");

        // [THEN] Automatic Cost Adjustment has been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ItemJournalPost_DifferentLowLevelCodes()
    var
        Item: Record Item;
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 3 items with low-level codes 1, 2, 3.
        // [GIVEN] Post an inventory adjustment for each item.
        CreateItem(Item, Item."Costing Method"::FIFO, 1);
        ItemNos.Add(Item."No.");
        CreateItem(Item, Item."Costing Method"::FIFO, 2);
        ItemNos.Add(Item."No.");
        CreateItem(Item, Item."Costing Method"::FIFO, 3);
        ItemNos.Add(Item."No.");

        PostItemJournalLine(ItemNos.Get(1), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(2), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(3), 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Post item journal line for the second item (with low-level code 2).
        BindSubscription(this);
        PostItemJournalLine(ItemNos.Get(2), -10, 0.0, WorkDate());

        // [THEN] Automatic Cost Adjustment has been run for the second item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure SalesPost_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(2), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(3), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(4), 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create a sales order with 2 lines for the first and third item.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNos.Get(1), 10);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNos.Get(3), 10);

        // [WHEN] Post the sales order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PurchasePost_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(2), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(3), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(4), 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create a purchase order with 2 lines for the first and third item.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNos.Get(1), 10);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNos.Get(3), 10);

        // [WHEN] Post the purchase order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AssemblyPost_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        ParentItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(2), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(3), 10, 10.0, WorkDate());
        PostItemJournalLine(ItemNos.Get(4), 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create a parent item for the assembly order
        LibraryInventory.CreateItem(ParentItem);

        // [GIVEN] Create an assembly order with the first and third items as components
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), ParentItem."No.", '', 1, '');
        Item.Get(ItemNos.Get(1));
        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", 2, 1, '');
        Item.Get(ItemNos.Get(3));
        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", 2, 1, '');

        // [WHEN] Post the assembly order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] Automatic Cost Adjustment has been run for the first and third component items and the parent item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);
        ParentItem.Get(ParentItem."No.");
        ParentItem.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure InvtDocReceipt_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create a location needed for the inventory document
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), Location.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(2), Location.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(3), Location.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(4), Location.Code, 10, 10.0, WorkDate(), 0);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create an inventory document receipt with the first and third items
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Receipt, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader, InvtDocumentLine, ItemNos.Get(1), 10.0, 5);
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader, InvtDocumentLine, ItemNos.Get(3), 10.0, 5);

        // [WHEN] Post the inventory document receipt with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure InvtDocShipment_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        InvtDocumentHeader: Record "Invt. Document Header";
        InvtDocumentLine: Record "Invt. Document Line";
        Location: Record Location;
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create a location needed for the inventory document
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), Location.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(2), Location.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(3), Location.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(4), Location.Code, 10, 10.0, WorkDate(), 0);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create an inventory document shipment with the first and third items
        LibraryInventory.CreateInvtDocument(InvtDocumentHeader, InvtDocumentHeader."Document Type"::Shipment, Location.Code);
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader, InvtDocumentLine, ItemNos.Get(1), 0.0, 5);
        LibraryInventory.CreateInvtDocumentLine(
            InvtDocumentHeader, InvtDocumentLine, ItemNos.Get(3), 0.0, 5);

        // [WHEN] Post the inventory document shipment with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryInventory.PostInvtDocument(InvtDocumentHeader);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TransferShipment_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create locations needed for transfer
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), FromLocation.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(2), FromLocation.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(3), FromLocation.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(4), FromLocation.Code, 10, 10.0, WorkDate(), 0);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create a transfer order with the first and third items
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNos.Get(1), 5);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNos.Get(3), 5);

        // [WHEN] Post the transfer shipment with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TransferReceipt_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        ItemNos: List of [Code[20]];
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create locations needed for transfer
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());
        ItemNos.Add(LibraryInventory.CreateItemNo());

        PostItemJournalLine(ItemNos.Get(1), FromLocation.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(2), FromLocation.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(3), FromLocation.Code, 10, 10.0, WorkDate(), 0);
        PostItemJournalLine(ItemNos.Get(4), FromLocation.Code, 10, 10.0, WorkDate(), 0);

        // [GIVEN] Create a transfer order with the first and third items and post the shipment
        LibraryInventory.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNos.Get(1), 5);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, ItemNos.Get(3), 5);
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Post the transfer receipt with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        TransferHeader.Get(TransferHeader."No.");
        LibraryInventory.PostTransferHeader(TransferHeader, false, true);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure UndoPurchaseReceipt_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemNos: List of [Code[20]];
        i: Integer;
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        for i := 1 to 4 do
            ItemNos.Add(LibraryInventory.CreateItemNo());

        // [GIVEN] Create and post purchase receipt for all items.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        for i := 1 to 4 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNos.Get(i), 5);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Find receipt lines for the first and third item
        PurchRcptLine.SetFilter("No.", '%1|%2', ItemNos.Get(1), ItemNos.Get(3));

        // [WHEN] Undo the purchase receipt with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure UndoReturnShipment_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNos: List of [Code[20]];
        i: Integer;
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        for i := 1 to 4 do
            ItemNos.Add(LibraryInventory.CreateItemNo());

        // [GIVEN] Create and post purchase receipts for all items
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        for i := 1 to 4 do
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNos.Get(i), 5);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create and post return orders for all items
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", '');
        for i := 1 to 4 do begin
            ItemLedgerEntry.SetRange("Item No.", ItemNos.Get(i));
            ItemLedgerEntry.FindLast();
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNos.Get(i), 5);
            PurchaseLine.Validate("Appl.-to Item Entry", ItemLedgerEntry."Entry No.");
            PurchaseLine.Modify(true);
        end;
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Find return shipment line for the first and third items
        ReturnShipmentLine.SetFilter("No.", '%1|%2', ItemNos.Get(1), ItemNos.Get(3));

        // [WHEN] Undo the return shipment with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure UndoReturnReceipt_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemNos: List of [Code[20]];
        i: Integer;
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        for i := 1 to 4 do
            ItemNos.Add(LibraryInventory.CreateItemNo());

        for i := 1 to 4 do
            PostItemJournalLine(ItemNos.Get(i), 10, 10.0, WorkDate());

        // [GIVEN] Create and post sales for all items
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        for i := 1 to 4 do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNos.Get(i), 5);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create and post return orders for all items
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        for i := 1 to 4 do begin
            ItemLedgerEntry.SetRange("Item No.", ItemNos.Get(i));
            ItemLedgerEntry.FindLast();
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNos.Get(i), 5);
            SalesLine.Validate("Appl.-from Item Entry", ItemLedgerEntry."Entry No.");
            SalesLine.Modify(true);
        end;
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Find return receipt line for the first and third items
        ReturnReceiptLine.SetFilter("No.", '%1|%2', ItemNos.Get(1), ItemNos.Get(3));

        // [WHEN] Undo the return receipt with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    procedure UndoSalesShipment_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        ItemNos: List of [Code[20]];
        i: Integer;
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 4 items and post an inventory adjustment for each item.
        for i := 1 to 4 do
            ItemNos.Add(LibraryInventory.CreateItemNo());

        for i := 1 to 4 do
            PostItemJournalLine(ItemNos.Get(i), 10, 10.0, WorkDate());

        // [GIVEN] Create and post sales shipments for all items.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        for i := 1 to 4 do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNos.Get(i), 5);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Find sales shipment line for the first and third items
        SalesShipmentLine.SetFilter("No.", '%1|%2', ItemNos.Get(1), ItemNos.Get(3));

        // [WHEN] Undo the sales shipment with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // [THEN] Automatic Cost Adjustment has been run for the first and third item.
        Item.Get(ItemNos.Get(1));
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ItemNos.Get(3));
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second and fourth item.
        Item.Get(ItemNos.Get(2));
        Item.TestField("Cost is Adjusted", false);
        Item.Get(ItemNos.Get(4));
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AssemblyPost_ComponentAdjustedButNotAssemblyItem()
    var
        AssemblyItem1, AssemblyItem2 : Record Item;
        ComponentItem1, ComponentItem2 : Record Item;
        AssemblyHeader1, AssemblyHeader2 : Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 2 assembly items and 2 component items
        LibraryInventory.CreateItem(AssemblyItem1);
        AssemblyItem1.Validate("Replenishment System", AssemblyItem1."Replenishment System"::Assembly);
        AssemblyItem1.Modify(true);
        LibraryInventory.CreateItem(ComponentItem1);

        LibraryInventory.CreateItem(AssemblyItem2);
        AssemblyItem2.Validate("Replenishment System", AssemblyItem2."Replenishment System"::Assembly);
        AssemblyItem2.Modify(true);
        LibraryInventory.CreateItem(ComponentItem2);

        // [GIVEN] Post inventory for all items
        PostItemJournalLine(AssemblyItem1."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(ComponentItem1."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(AssemblyItem2."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(ComponentItem2."No.", 10, 10.0, WorkDate());

        // [GIVEN] Post assembly orders for both pairs
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader1, WorkDate(), AssemblyItem1."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader1, AssemblyLine, "BOM Component Type"::Item, ComponentItem1."No.", ComponentItem1."Base Unit of Measure", 1, 1, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader1, '');

        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader2, WorkDate(), AssemblyItem2."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader2, AssemblyLine, "BOM Component Type"::Item, ComponentItem2."No.", ComponentItem2."Base Unit of Measure", 1, 1, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader2, '');

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Create and post another assembly order for the first pair
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader1, WorkDate(), AssemblyItem1."No.", '', 1, '');
        LibraryAssembly.CreateAssemblyLine(
            AssemblyHeader1, AssemblyLine, "BOM Component Type"::Item, ComponentItem1."No.", ComponentItem1."Base Unit of Measure", 1, 1, '');

        BindSubscription(this);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader1, '');

        // [THEN] Component item is adjusted, but assembly item is not adjusted yet
        ComponentItem1.Get(ComponentItem1."No.");
        ComponentItem1.TestField("Cost is Adjusted", true);
        AssemblyItem1.Get(AssemblyItem1."No.");
        AssemblyItem1.TestField("Cost is Adjusted", false);

        // [THEN] Second pair items are not adjusted
        ComponentItem2.Get(ComponentItem2."No.");
        ComponentItem2.TestField("Cost is Adjusted", false);
        AssemblyItem2.Get(AssemblyItem2."No.");
        AssemblyItem2.TestField("Cost is Adjusted", false);

        // [WHEN] Post anything for the assembly item
        PostItemJournalLine(AssemblyItem1."No.", 1, 10.0, WorkDate());

        // [THEN] Assembly item is now adjusted
        AssemblyItem1.Get(AssemblyItem1."No.");
        AssemblyItem1.TestField("Cost is Adjusted", true);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure AssembleToOrder_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        AssemblyItem, ComponentItem, ThirdItem : Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create assemble-to-order assembly item, component item, and third item
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", AssemblyItem."Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Modify(true);

        LibraryInventory.CreateItem(ComponentItem);
        LibraryInventory.CreateItem(ThirdItem);

        // [GIVEN] Create BOM component for assembly item
        LibraryAssembly.CreateAssemblyListComponent(
            BOMComponent.Type::Item, ComponentItem."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type", 1, true);

        // [GIVEN] Post inventory for all items
        PostItemJournalLine(AssemblyItem."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(ComponentItem."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(ThirdItem."No.", 10, 10.0, WorkDate());

        // [GIVEN] Create and post sales order for assembly item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AssemblyItem."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Create and post another sales order for assembly item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AssemblyItem."No.", 1);

        BindSubscription(this);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Assembly item and component are adjusted
        AssemblyItem.Get(AssemblyItem."No.");
        AssemblyItem.TestField("Cost is Adjusted", true);
        ComponentItem.Get(ComponentItem."No.");
        ComponentItem.TestField("Cost is Adjusted", true);

        // [THEN] Third item is not adjusted
        ThirdItem.Get(ThirdItem."No.");
        ThirdItem.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure PartialAssemblyPost_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        AssemblyItem, ComponentItem : Record Item;
        AssemblyHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create assembly item and component item
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Modify(true);

        LibraryInventory.CreateItem(ComponentItem);

        // [GIVEN] Create BOM component for assembly item
        LibraryAssembly.CreateAssemblyListComponent(
            BOMComponent.Type::Item, ComponentItem."No.", AssemblyItem."No.", '', BOMComponent."Resource Usage Type", 1, true);

        // [GIVEN] Post inventory for both items
        PostItemJournalLine(AssemblyItem."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(ComponentItem."No.", 10, 10.0, WorkDate());

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [GIVEN] Create assembly order for 5 pieces
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), AssemblyItem."No.", '', 5, '');

        // [WHEN] Partially post assembly order (3 pieces)
        AssemblyHeader.Validate("Quantity to Assemble", 3);
        AssemblyHeader.Modify(true);

        BindSubscription(this);
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] Both items are adjusted
        AssemblyItem.Get(AssemblyItem."No.");
        AssemblyItem.TestField("Cost is Adjusted", true);
        ComponentItem.Get(ComponentItem."No.");
        ComponentItem.TestField("Cost is Adjusted", true);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure ProductionPost_OnlyProcessPostedItemsInAutomaticCostAdjustment()
    var
        Item: Record Item;
        ProdItem1, ProdItem2 : Record Item;
        CompItem1, CompItem2 : Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 2 production items and 2 component items
        LibraryInventory.CreateItem(ProdItem1);
        ProdItem1.Validate("Replenishment System", ProdItem1."Replenishment System"::"Prod. Order");
        ProdItem1.Modify(true);

        LibraryInventory.CreateItem(ProdItem2);
        ProdItem2.Validate("Replenishment System", ProdItem2."Replenishment System"::"Prod. Order");
        ProdItem2.Modify(true);

        LibraryInventory.CreateItem(CompItem1);
        LibraryInventory.CreateItem(CompItem2);

        // [GIVEN] Create production BOM for first production item with first component
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem1."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem1."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        ProdItem1.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem1.Modify(true);

        // [GIVEN] Post inventory for all items
        PostItemJournalLine(ProdItem1."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(ProdItem2."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(CompItem1."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(CompItem2."No.", 10, 10.0, WorkDate());

        // [GIVEN] Create and refresh production order for first pair, post production journal.
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem1."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Finish the production order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Automatic Cost Adjustment has been run for the first production item and first component.
        Item.Get(ProdItem1."No.");
        Item.TestField("Cost is Adjusted", true);
        Item.Get(CompItem1."No.");
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second production item and second component.
        Item.Get(ProdItem2."No.");
        Item.TestField("Cost is Adjusted", false);
        Item.Get(CompItem2."No.");
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure ProductionPost_ComponentAdjustedButNotProductionItem()
    var
        Item: Record Item;
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionOrder1, ProductionOrder2 : Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create production item and component item
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Modify(true);

        LibraryInventory.CreateItem(CompItem);

        // [GIVEN] Create production BOMs for each production item with respective component
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, CompItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Post inventory for all items
        PostItemJournalLine(ProdItem."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(CompItem."No.", 10, 10.0, WorkDate());

        // [GIVEN] Create and refresh two production orders, post production journals
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder1, ProductionOrder1.Status::Released, ProductionOrder1."Source Type"::Item, ProdItem."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder1, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine, ProductionOrder1);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder1, ProdOrderLine."Line No.");

        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder2, ProductionOrder2.Status::Released, ProductionOrder2."Source Type"::Item, ProdItem."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder2, false, true, true, true, false);
        FindProdOrderLine(ProdOrderLine, ProductionOrder2);
        LibraryManufacturing.OpenProductionJournal(ProductionOrder2, ProdOrderLine."Line No.");

        // [GIVEN] Finish first production order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder1."No.");

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Finish second production order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder2."No.");

        // [THEN] Component item is adjusted, but production item is not adjusted yet
        Item.Get(CompItem."No.");
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ProdItem."No.");
        Item.TestField("Cost is Adjusted", false);

        // [THEN] Post anything for the production item
        PostItemJournalLine(ProdItem."No.", 1, 10.0, WorkDate());

        // [THEN] Production item is now adjusted
        Item.Get(ProdItem."No.");
        Item.TestField("Cost is Adjusted", true);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure ProductionPost_MultipleProductionItemsAllPosted()
    var
        Item: Record Item;
        ProdItem1, ProdItem2 : Record Item;
        CompItem1, CompItem2 : Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader1, ProductionBOMHeader2 : Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 2 production items and 2 component items
        LibraryInventory.CreateItem(ProdItem1);
        ProdItem1.Validate("Replenishment System", ProdItem1."Replenishment System"::"Prod. Order");
        ProdItem1.Modify(true);

        LibraryInventory.CreateItem(ProdItem2);
        ProdItem2.Validate("Replenishment System", ProdItem2."Replenishment System"::"Prod. Order");
        ProdItem2.Modify(true);

        LibraryInventory.CreateItem(CompItem1);
        LibraryInventory.CreateItem(CompItem2);

        // [GIVEN] Create production BOMs where each production item has both components
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader1, CompItem1."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader1, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem1."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader1, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem2."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader1, ProductionBOMHeader1.Status::Certified);
        ProdItem1.Validate("Production BOM No.", ProductionBOMHeader1."No.");
        ProdItem1.Modify(true);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader2, CompItem1."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader2, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem1."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader2, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem2."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader2, ProductionBOMHeader2.Status::Certified);
        ProdItem2.Validate("Production BOM No.", ProductionBOMHeader2."No.");
        ProdItem2.Modify(true);

        // [GIVEN] Post inventory for all items
        PostItemJournalLine(ProdItem1."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(ProdItem2."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(CompItem1."No.", 20, 10.0, WorkDate());
        PostItemJournalLine(CompItem2."No.", 20, 10.0, WorkDate());

        // [GIVEN] Create and refresh production order with two production order lines
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem1."No.", 1);
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine, ProductionOrder.Status::Released, ProductionOrder."No.", ProdItem1."No.", '', '', 1);
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine, ProductionOrder.Status::Released, ProductionOrder."No.", ProdItem2."No.", '', '', 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [GIVEN] Post production journal for each line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindSet();
        repeat
            LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
        until ProdOrderLine.Next() = 0;

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Finish the production order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Automatic Cost Adjustment has been run for all items.
        Item.Get(ProdItem1."No.");
        Item.TestField("Cost is Adjusted", true);
        Item.Get(ProdItem2."No.");
        Item.TestField("Cost is Adjusted", true);
        Item.Get(CompItem1."No.");
        Item.TestField("Cost is Adjusted", true);
        Item.Get(CompItem2."No.");
        Item.TestField("Cost is Adjusted", true);

        UnbindSubscription(this);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalModalPageHandler,ConfirmHandler,MessageHandler')]
    procedure ProductionPost_MultipleProductionItemsPartiallyPosted()
    var
        Item: Record Item;
        ProdItem1, ProdItem2 : Record Item;
        CompItem1, CompItem2 : Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader1, ProductionBOMHeader2 : Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        Initialize();

        // [GIVEN] Automatic Cost Adjustment is set to Never.
        SetAutomaticCostAdjustment(false);

        // [GIVEN] Create 2 production items and 2 component items
        LibraryInventory.CreateItem(ProdItem1);
        ProdItem1.Validate("Replenishment System", ProdItem1."Replenishment System"::"Prod. Order");
        ProdItem1.Modify(true);

        LibraryInventory.CreateItem(ProdItem2);
        ProdItem2.Validate("Replenishment System", ProdItem2."Replenishment System"::"Prod. Order");
        ProdItem2.Modify(true);

        LibraryInventory.CreateItem(CompItem1);
        LibraryInventory.CreateItem(CompItem2);

        // [GIVEN] Create production BOMs where each production item has both components
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader1, CompItem1."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader1, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem1."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader1, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem2."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader1, ProductionBOMHeader1.Status::Certified);
        ProdItem1.Validate("Production BOM No.", ProductionBOMHeader1."No.");
        ProdItem1.Modify(true);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader2, CompItem1."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader2, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem1."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader2, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem2."No.", 1);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader2, ProductionBOMHeader2.Status::Certified);
        ProdItem2.Validate("Production BOM No.", ProductionBOMHeader2."No.");
        ProdItem2.Modify(true);

        // [GIVEN] Post inventory for all items
        PostItemJournalLine(ProdItem1."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(ProdItem2."No.", 10, 10.0, WorkDate());
        PostItemJournalLine(CompItem1."No.", 20, 10.0, WorkDate());
        PostItemJournalLine(CompItem2."No.", 20, 10.0, WorkDate());

        // [GIVEN] Create and refresh production order with two production order lines
        LibraryManufacturing.CreateProductionOrder(
            ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem1."No.", 1);
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine, ProductionOrder.Status::Released, ProductionOrder."No.", ProdItem1."No.", '', '', 1);
        LibraryManufacturing.CreateProdOrderLine(
            ProdOrderLine, ProductionOrder.Status::Released, ProductionOrder."No.", ProdItem2."No.", '', '', 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, false, true, true, false);

        // [GIVEN] Post production journal only for the first production order line
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange("Item No.", ProdItem1."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");

        // [GIVEN] Set Automatic Cost Adjustment to Always.
        SetAutomaticCostAdjustment(true);

        // [WHEN] Finish the production order with enabled Concurrent Inventory Posting feature.
        BindSubscription(this);
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Automatic Cost Adjustment has been run for the posted production item and both components.
        Item.Get(ProdItem1."No.");
        Item.TestField("Cost is Adjusted", true);
        Item.Get(CompItem1."No.");
        Item.TestField("Cost is Adjusted", true);
        Item.Get(CompItem2."No.");
        Item.TestField("Cost is Adjusted", true);

        // [THEN] Automatic Cost Adjustment has not been run for the second production item.
        Item.Get(ProdItem2."No.");
        Item.TestField("Cost is Adjusted", false);

        UnbindSubscription(this);
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; LowLevelCode: Integer)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Unit Cost", 10);
        Item.Validate("Last Direct Cost", 10);
        Item.Validate("Low-Level Code", LowLevelCode);
        Item.Modify(true);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date)
    begin
        PostItemJournalLine(ItemNo, '', Quantity, UnitAmount, PostingDate, 0);
    end;

    local procedure PostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; UnitAmount: Decimal; PostingDate: Date; AppliesToEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, '', Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Validate("Posting Date", PostingDate);
        ItemJournalLine."Applies-to Entry" := AppliesToEntryNo;
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SetAutomaticCostAdjustment(IsAutomatic: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        if IsAutomatic then
            InventorySetup.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Always)
        else
            InventorySetup.Validate("Automatic Cost Adjustment", InventorySetup."Automatic Cost Adjustment"::Never);
        InventorySetup.Modify(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Key Management", OnAfterIsConcurrentInventoryPostingEnabled, '', false, false)]
    local procedure EnableConcurrentInventoryPosting(var ConcurrentInventoryPosting: Boolean)
    begin
        ConcurrentInventoryPosting := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    procedure ProductionJournalModalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;
}