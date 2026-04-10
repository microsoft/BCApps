codeunit 137066 "SCM Order Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order Tracking] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LocationOrange: Record Location;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        TrackingMessage: Label 'The change will not affect existing entries';
        NoTrackingLines: Label 'There are no order tracking entries for this line';
        WarehouseReceiveMessage: Label 'Warehouse Receive is required for this line.';

    [Test]
    [HandlerFunctions('OrderTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnReleasedProdOrder()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Production BOM and create Production Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithProductionBOMSetup(Item, Item2, Item3, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        CreateAndRefreshReleasedProdOrder(ProductionOrder, Item."No.", WorkDate(), Quantity);
        SelectProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status, Item."No.");

        // Enqueue value for message handler and OrderTrackingPageHandler.
        LibraryVariableStorage.Enqueue(NoTrackingLines);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Quantity);

        // Exercise & Verify: Open and verify Order Tracking from Production Order. Verification is inside test page handler - OrderTrackingPageHandler.
        OpenOrderTrackingForProduction(ProdOrderLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnReleasedProdOrderWithRequisitionLine()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Production BOM and create two Production Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithProductionBOMSetup(Item, Item2, Item3, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        CreateAndRefreshReleasedProdOrder(ProductionOrder, Item2."No.", WorkDate(), Quantity);
        CreateAndRefreshReleasedProdOrder(ProductionOrder2, Item."No.", GetRequiredDate(5, 10, WorkDate()), Quantity);  // Due Date based on Work Date.

        // Create Requisition line for Child Item.
        CreateRequisitionLine(Item3."No.", Quantity);

        // Exercise & Verify: Select Production Order component. Enqueue values. Open and verify Order Tracking from Production Order Component.
        // Verification is inside test page handler - OrderTrackingDetailsPageHandler.
        OrderTrackingForProdOrderComponent(ProductionOrder2."No.", Item2."No.", Quantity);  // Order Tracking for Released Production Order.
        OrderTrackingForProdOrderComponent(ProductionOrder2."No.", Item3."No.", Quantity);  // Order Tracking for Requisition Line.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnProdOrderComponentWithVariant()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponent(true);  // Component with variant as True.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnProdOrderComponentWithoutVariant()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponent(false);  // Component with variant as False.
    end;

    local procedure OrderTrackingOnProdOrderComponent(ComponentWithVariant: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // Create Item with Production BOM, create Purchase Order with variant and Released Production Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithProductionBOMSetup(Item, Item2, Item3, Item."Order Tracking Policy"::"Tracking Only");
        LibraryInventory.CreateItemVariant(ItemVariant, Item2."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item3."No.");
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item2."No.", ItemVariant.Code, Quantity);
        CreatePurchaseLineWithVariantCode(PurchaseHeader, PurchaseLine, Item3."No.", ItemVariant2.Code, Quantity);
        CreateAndRefreshReleasedProdOrder(ProductionOrder, Item."No.", GetRequiredDate(5, 10, WorkDate()), Quantity);  // Due Date based on Work Date.
        UpdateVariantCodeOnProdOrderComponent(ProductionOrder."No.", Item2."No.", ItemVariant.Code);

        // Exercise & Verify: Open and verify Order Tracking from Production Order Component.Verification is inside test page handler.
        if ComponentWithVariant then
            // Open page handler - OrderTrackingDetailsPageHandler.
            OrderTrackingForProdOrderComponent(ProductionOrder."No.", Item2."No.", PurchaseLine.Quantity)
        else begin
            SelectProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", Item3."No.");
            LibraryVariableStorage.Enqueue(NoTrackingLines);  // Enqueue value for message handler.
            LibraryVariableStorage.Enqueue(ProdOrderComponent."Expected Quantity");  // Enqueue value for page handler.
            LibraryVariableStorage.Enqueue(ProdOrderComponent."Expected Quantity");  // Enqueue value for page handler.
            OpenOrderTrackingForProdOrderComponent(ProdOrderComponent);  // Open page handler - OrderTrackingPageHandler.
        end;
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnSalesOrderWithPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, Create Purchase Order and Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking Only", '');
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", '', Quantity);
        UpdateExpectedReceiptDateOnPurchaseLine(
          PurchaseLine, CalcDate('<-' + Format(LibraryRandom.RandInt(5) + 10) + 'D>', WorkDate()));  // Expected Receipt Date based on Work Date.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);

        // Enqueue value for page handler.
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity - Quantity);
        LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);

        // Exercise & Verify: Open and verify Order Tracking from Sales Order. Verification is inside test page handler - OrderTrackingDetailsPageHandler.
        OpenOrderTrackingForSales(SalesLine);  // Open page handler - OrderTrackingDetailsPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnSalesOrderWithPositiveAdjmtWithoutPosting()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnSalesOrderWithPositiveAdjmt(false);  // Post Item Journal as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnSalesOrderWithPositiveAdjmtWithPosting()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnSalesOrderWithPositiveAdjmt(true);  // Post Item Journal as True.
    end;

    local procedure OrderTrackingOnSalesOrderWithPositiveAdjmt(PostItemJournal: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Create Item, Item Journal line and Sales Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking Only", '');
        CreateAndPostItemJournal(Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Quantity, PostItemJournal);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);

        // Enqueue value for Page handler.
        if PostItemJournal then begin
            LibraryVariableStorage.Enqueue(SalesLine.Quantity);
            LibraryVariableStorage.Enqueue(SalesLine.Quantity - Quantity);
            LibraryVariableStorage.Enqueue(Quantity);
        end else begin
            LibraryVariableStorage.Enqueue(NoTrackingLines);
            LibraryVariableStorage.Enqueue(SalesLine.Quantity);
            LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        end;

        // Exercise & Verify: Open and verify Order Tracking from Sales Order. Verification is inside test page handler - OrderTrackingPageHandler  /  OrderTrackingDetailsPageHandler.
        OpenOrderTrackingForSales(SalesLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnPurchaseWithLocation()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponentAndPurchaseWithLocation(true);  // Order Tracking On Purchase as TRUE.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnProdOrderComponentWithLocation()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponentAndPurchaseWithLocation(false);  // Order Tracking On Purchase as FALSE.
    end;

    local procedure OrderTrackingOnProdOrderComponentAndPurchaseWithLocation(OrderTrackingOnPurchase: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        Quantity: Decimal;
    begin
        // Create Item with Production BOM, create Purchase Order with Location and Bin Code and Released Production Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithProductionBOMSetup(Item, Item2, Item3, Item."Order Tracking Policy"::"Tracking Only");
        FindBin(Bin, LocationOrange.Code);
        CreatePurchaseOrderWithLocationAndVariant(PurchaseHeader, PurchaseLine, Item2."No.", Quantity, '', LocationOrange.Code, Bin.Code);  // Variant Code as Blank.
        CreatePurchaseLineWithLocationAndVariant(PurchaseHeader, PurchaseLine2, Item3."No.", Quantity, '', LocationOrange.Code, Bin.Code);  // Variant Code as Blank.
        CreateAndRefreshReleasedProdOrder(ProductionOrder, Item."No.", GetRequiredDate(5, 10, WorkDate()), Quantity);
        UpdateLocationAndVariantOnProdOrderComponent(ProductionOrder."No.", Item2."No.", '', LocationOrange.Code, Bin.Code);
        UpdateLocationAndVariantOnProdOrderComponent(ProductionOrder."No.", Item3."No.", '', LocationOrange.Code, Bin.Code);

        // Exercise & Verify: Open and verify Order Tracking from Production Order Component.Verification is inside test page handler - OrderTrackingDetailsPageHandler.
        if OrderTrackingOnPurchase then begin
            LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
            LibraryVariableStorage.Enqueue(PurchaseLine.Quantity - Quantity);
            LibraryVariableStorage.Enqueue(-PurchaseLine.Quantity);
            OpenOrderTrackingForPurchase(PurchaseLine);  // Open page handler - OrderTrackingDetailsPageHandler.
        end else
            OrderTrackingForProdOrderComponent(ProductionOrder."No.", Item2."No.", PurchaseLine.Quantity);  // Open page handler OrderTrackingDetailsPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnSalesWithVariant()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ItemVariant: Record "Item Variant";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item with Production BOM, create Item Variants, create Released Production Order with Variant and Sales Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItemWithProductionBOMSetup(Item, Item2, Item3, Item."Order Tracking Policy"::"Tracking Only");
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateAndRefreshReleasedProdOrder(ProductionOrder, Item."No.", GetRequiredDate(5, 10, WorkDate()), Quantity);
        UpdateVariantCodeOnProdOrder(ProdOrderLine, ProductionOrder."No.", Item."No.", ItemVariant.Code);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity);
        UpdateVariantCodeOnSalesOrder(SalesLine, ItemVariant.Code);

        // Enqueue value for Page handler.
        LibraryVariableStorage.Enqueue(NoTrackingLines);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);

        // Exercise & Verify: Open and verify Order Tracking from Sales Order. Verification is inside test page handler - OrderTrackingPageHandler.
        OpenOrderTrackingForSales(SalesLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnProdOrderComponentWithLocationAndWithoutVariant()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponentForVariantAndLocation(true, false);  // Prod Order Without Variant as TRUE, Update Variant as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnProdOrderComponentWithVariantAndLocation()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponentForVariantAndLocation(false, false);  // Prod Order Without Variant as False, Update Variant as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnProdOrderComponentWithUpdatedVariant()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponentForVariantAndLocation(false, true);  // Prod Order Without Variant as False, Update Variant as True.
    end;

    local procedure OrderTrackingOnProdOrderComponentForVariantAndLocation(ProdOrderWithoutVariant: Boolean; UpdateVariant: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Bin: Record Bin;
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Create Item with Production BOM, create Purchase Order with Location and Bin Code and Released Production Order.
        CreateItemWithProductionBOMSetup(Item, Item2, Item3, Item."Order Tracking Policy"::"Tracking Only");
        LibraryInventory.CreateItemVariant(ItemVariant, Item2."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item3."No.");
        FindBin(Bin, LocationOrange.Code);

        CreatePurchaseOrderWithTwoLinesAndLocation(
          PurchaseHeader, Bin, Item2."No.", Item3."No.", ItemVariant.Code, LocationOrange.Code, LibraryRandom.RandDec(10, 2));
        FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.", Item2."No.");
        CreateAndRefreshReleasedProdOrder(ProductionOrder, Item."No.", GetRequiredDate(5, 10, WorkDate()), PurchaseLine.Quantity);
        UpdateLocationAndVariantOnProdOrderComponent(ProductionOrder."No.", Item2."No.", ItemVariant.Code, LocationOrange.Code, Bin.Code);
        UpdateLocationAndVariantOnProdOrderComponent(ProductionOrder."No.", Item3."No.", ItemVariant2.Code, LocationOrange.Code, Bin.Code);

        // Exercise & Verify: Open and verify Order Tracking from Production Order Component.
        // Verification is inside test page handler - OrderTrackingDetailsPageHandler.
        // Verify Order Tracking on Production Order Component without Variant.
        if ProdOrderWithoutVariant then begin
            SelectProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", Item3."No.");
            LibraryVariableStorage.Enqueue(NoTrackingLines);
            LibraryVariableStorage.Enqueue(ProdOrderComponent."Expected Quantity");
            LibraryVariableStorage.Enqueue(ProdOrderComponent."Expected Quantity");
            OpenOrderTrackingForProdOrderComponent(ProdOrderComponent);  // Open page handler - OrderTrackingPageHandler.
        end else
            // Verify Order Tracking on Production Order Component after updating variant on Purchase Line.
            if UpdateVariant then begin
                FindPurchaseOrderLine(PurchaseLine, PurchaseHeader."No.", Item3."No.");
                UpdateVariantCodeOnPurchaseLine(PurchaseLine, ItemVariant2.Code);
                OrderTrackingForProdOrderComponent(ProductionOrder."No.", Item3."No.", PurchaseLine.Quantity);  // Open page handler OrderTrackingDetailsPageHandler.
            end else
                // Verify Order Tracking on Production Order Component with Variant.
                OrderTrackingForProdOrderComponent(ProductionOrder."No.", Item2."No.", PurchaseLine.Quantity) // Open page handler OrderTrackingDetailsPageHandler.
    end;

    [Test]
    [HandlerFunctions('OrderTrackingMultipleLinePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnProdOrderComponentAndItemLedgerEntry()
    var
        ItemPurch: Record Item;
        ChildItemMfg: Record Item;
        ParentItemMfg: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        OutputItemLedgEntryNo: array[2] of Integer;
        Quantity: array[4] of Decimal;
    begin
        // [FEATURE] [Production] [Prod. Order Component]
        // [SCENARIO 381248] Order Tracking called from Prod. Order Component should show output Item Entries to which the consumption of the Component will be applied.
        Initialize();
        Quantity[1] := 3; // values are picked for the clear perception of the test
        Quantity[2] := 5;
        Quantity[3] := 5;
        Quantity[4] := 1;

        // [GIVEN] Purchased Item "I1".
        CreateItem(
          ItemPurch, ItemPurch."Replenishment System"::Purchase, ItemPurch."Order Tracking Policy"::"Tracking & Action Msg.", '');

        // [GIVEN] Manufacturing Item "I2" with BOM component "I1".
        CreateItemManufacturing(ChildItemMfg, ItemPurch."No.");

        // [GIVEN] Manufacturing Item "I3" with BOM component "I2".
        CreateItemManufacturing(ParentItemMfg, ChildItemMfg."No.");

        // [GIVEN] Released Production Order for "I2".
        // [GIVEN] Two output lines of "I2" with quantities "Q1" and "Q2" are posted (i.e. "Q1" = 3 pcs; "Q2" = 5 pcs).
        CreateAndRefreshReleasedProdOrder(ProductionOrder, ChildItemMfg."No.", WorkDate(), Quantity[1] + Quantity[2]);
        OutputItemLedgEntryNo[1] := PostOutput(ProductionOrder, Quantity[1]);
        OutputItemLedgEntryNo[2] := PostOutput(ProductionOrder, Quantity[2]);

        // [GIVEN] Part of each output of "I2" is consumed in another Production Order. Consumption quantity = "Q4" (i.e. "Q4" = 1).
        CreateAndRefreshReleasedProdOrder(ProductionOrder, ParentItemMfg."No.", WorkDate(), 2 * Quantity[4]);
        PostConsumption(ProductionOrder, Quantity[4], OutputItemLedgEntryNo[1]);
        PostConsumption(ProductionOrder, Quantity[4], OutputItemLedgEntryNo[2]);

        // [GIVEN] Released Production Order "PO" for "I3". Quantity = "Q3" (i.e. "Q3" = 5 pcs).
        CreateAndRefreshReleasedProdOrder(ProductionOrder, ParentItemMfg."No.", WorkDate(), Quantity[3]);

        // [WHEN] Show Order Tracking for the Prod. Order Component "I2" in "PO".
        SelectProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItemMfg."No.");
        LibraryVariableStorage.Enqueue(Quantity[3]); // quantity to be tracked ("Q3" = 5 pcs)
        LibraryVariableStorage.Enqueue(0); // untracked quantity
        LibraryVariableStorage.Enqueue(Quantity[2] - Quantity[4]); // quantity to be applied to the second output ("Q2" - "Q4" = 4 pcs).
        LibraryVariableStorage.Enqueue(Quantity[3] - (Quantity[2] - Quantity[4])); // quantity to be applied to the first output ("Q3" - ("Q2" - "Q4") = 1 pc).
        OpenOrderTrackingForProdOrderComponent(ProdOrderComponent);

        // [THEN] Order Tracking show two output Item Entries with planned applied quantities (4 pcs & 1 pc).
        // Verification is done in OrderTrackingMultipleLinePageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnFirmPlannedProdOrder()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnReleasedProdOrderAndFirmPlannedProdOrder(true);  // Firm Planned Prod Order Tracking as True.
    end;

    [Test]
    [HandlerFunctions('OrderTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnReleasedProdOrderForFirmPlannedProdOrder()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnReleasedProdOrderAndFirmPlannedProdOrder(false);  // Firm Planned Prod Order Tracking as False.
    end;

    local procedure OrderTrackingOnReleasedProdOrderAndFirmPlannedProdOrder(FirmPlannedProdOrderTracking: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionOrder3: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Create Item with Production BOM and create Firm Planned and Released Production Order.
        CreateItemWithProductionBOMSetup(Item, Item2, Item3, Item."Order Tracking Policy"::"Tracking Only");
        CreateAndRefreshFirmPlannedProdOrder(ProductionOrder, Item2."No.", WorkDate(), LibraryRandom.RandDec(10, 2) + 100);  // Using Large Value for Quantity.
        CreateAndRefreshFirmPlannedProdOrder(ProductionOrder2, Item2."No.", WorkDate(), LibraryRandom.RandDec(10, 2) + 50);  // Using Large Value for Quantity.
        CreateAndRefreshReleasedProdOrder(
          ProductionOrder3, Item."No.", GetRequiredDate(5, 10, WorkDate()), LibraryRandom.RandDec(10, 2) + 10);  // Using Large Value for Quantity.

        if FirmPlannedProdOrderTracking then begin
            SelectProdOrderComponent(ProdOrderComponent, ProductionOrder3."No.", Item2."No.");
            // Enqueue value for Page handler.
            LibraryVariableStorage.Enqueue(ProductionOrder2.Quantity);
            LibraryVariableStorage.Enqueue(ProductionOrder2.Quantity - ProdOrderComponent."Expected Quantity");
            LibraryVariableStorage.Enqueue(-ProdOrderComponent."Expected Quantity");
            SelectProdOrderLine(ProdOrderLine, ProductionOrder2."No.", ProductionOrder2.Status, Item2."No.");
        end else begin
            // Enqueue value for Page handler.
            LibraryVariableStorage.Enqueue(NoTrackingLines);
            LibraryVariableStorage.Enqueue(ProductionOrder3.Quantity);
            LibraryVariableStorage.Enqueue(ProductionOrder3.Quantity);
            SelectProdOrderLine(ProdOrderLine, ProductionOrder3."No.", ProductionOrder3.Status, Item."No.");
        end;

        // Exercise & Verify: Open and verify Order Tracking from Production Order Line. Verification is inside test page handler - OrderTrackingPageHandler  /  OrderTrackingDetailsPageHandler.
        OpenOrderTrackingForProduction(ProdOrderLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnProdOrderComponentForPurchaseOrder()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponentAndSalesOrder(false);  // Sales Order Tracking as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingMultipleLinePageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnSalesOrderForPurchaseOrderAndProdOrder()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnProdOrderComponentAndSalesOrder(true);  // Sales Order Tracking as True.
    end;

    local procedure OrderTrackingOnProdOrderComponentAndSalesOrder(SalesOrderTracking: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequiredDate: Date;
    begin
        // Create Item with Production BOM, create Released Production Order and Purchase Order.
        RequiredDate := GetRequiredDate(5, 5, WorkDate());  // Calculate Required Date based on Workdate.
        CreateItemWithProductionBOMSetup(Item, Item2, Item3, Item."Order Tracking Policy"::"Tracking Only");
        CreateAndRefreshReleasedProdOrder(ProductionOrder, Item2."No.", WorkDate(), LibraryRandom.RandDec(10, 2));

        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10);  // Using Large Value for Quantity.
        UpdateExpectedReceiptDateOnPurchaseLine(PurchaseLine, RequiredDate);  // Expected Receipt Date based on Work Date.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateAndRefreshReleasedProdOrder(ProductionOrder2, Item."No.", RequiredDate, PurchaseLine.Quantity + 50);  // Production Quantity Greater than Purchase Line Quantity.

        if SalesOrderTracking then begin
            CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ProductionOrder2.Quantity);  // Sales Order Quantity equal to Production Order Quantity.
            UpdateShipmentDateOnSalesLine(SalesLine, RequiredDate);
        end;

        // Exercise & Verify: Open and verify Order Tracking from Sales Order and Production Order Component.
        // Verification is inside test page handler - OrderTrackingDetailsPageHandler and OrderTrackingMultipleLinePageHandler.
        if SalesOrderTracking then begin
            // Enqueue value for page handler.
            LibraryVariableStorage.Enqueue(SalesLine.Quantity);
            LibraryVariableStorage.Enqueue(0);
            LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);
            LibraryVariableStorage.Enqueue(SalesLine.Quantity - PurchaseLine.Quantity);
            OpenOrderTrackingForSales(SalesLine) // Open page handler - OrderTrackingDetailsPageHandler.
        end else
            OrderTrackingForProdOrderComponent(ProductionOrder2."No.", Item2."No.", ProductionOrder.Quantity) // Open page handler - OrderTrackingMultipleLinePageHandler.
    end;

    [Test]
    [HandlerFunctions('OrderTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnPurchaseOrderForNegativeAdjustment()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item, Create and Post Item Journal with Negative Adjustment and create Purchase Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking Only", '');
        CreateAndPostItemJournal(Item."No.", ItemJournalLine."Entry Type"::"Negative Adjmt.", Quantity, true);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", '', Quantity);
        UpdateExpectedReceiptDateOnPurchaseLine(PurchaseLine, GetRequiredDate(5, 5, WorkDate()));  // Expected Receipt Date based on Work Date.

        // Exercise & Verify: Open and verify Order Tracking from Purchase Order. Verification is inside test page handler - OrderTrackingDetailsPageHandler.
        // Enqueue value for page handler.
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(Quantity);
        OpenOrderTrackingForPurchase(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('OrderTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnSalesOrderForSalesCreditMemoWithoutPosting()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnSalesOrderForSalesCreditMemo(false);  // Post Credit Memo as False.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingDetailsPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingOnSalesOrderForSalesCreditMemoWithPosting()
    begin
        // Setup.
        Initialize();
        OrderTrackingOnSalesOrderForSalesCreditMemo(true);  // Post Credit Memo as True.
    end;

    local procedure OrderTrackingOnSalesOrderForSalesCreditMemo(PostCreditMemo: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesLine2: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Create Item, Create Sales Credit Memo and Sales Order.
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking Only", '');
        CreateSalesCreditMemo(SalesHeader, SalesLine, Item."No.", Quantity);
        if PostCreditMemo then
            LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateSalesOrder(SalesHeader2, SalesLine2, Item."No.", Quantity);

        // Exercise & Verify: Open and verify Order Tracking from Sales Order. Verification is inside test page handler - OrderTrackingDetailsPageHandler ,OrderTrackingPageHandler.
        // Enqueue value for page handler.
        if PostCreditMemo then begin
            LibraryVariableStorage.Enqueue(Quantity);
            LibraryVariableStorage.Enqueue(0);  // Untracked Quantity - zero, for Posted Credit Memo.
        end else begin
            LibraryVariableStorage.Enqueue(NoTrackingLines);
            LibraryVariableStorage.Enqueue(Quantity);
        end;
        LibraryVariableStorage.Enqueue(Quantity);
        OpenOrderTrackingForSales(SalesLine2);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure OrderTrackingNotChangeStatusInReservationEntryWhenSpecialOrderInSalesLine()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 318713] When Purchase is created with same Item and same Qty as Sales and Receipt Date is earlier than Shipment Date
        // [SCENARIO 318713] and Special Order is used in Sales, then Order Tracking doesn't update status to Tracking in Reservation Entry
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Item had Order Tracking enabled
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Sales Order with 10 PCS of the Item and Shipment Date = 28/1/2021
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", Qty,
          Location.Code, WorkDate());

        // [GIVEN] Set Special Order Purchasing Code in the Sales Line
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(false, true));
        SalesLine.Modify(true);

        // [GIVEN] Purchase Order with 10 PCS of the Item
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), Item."No.", Qty,
          Location.Code, WorkDate());

        // [WHEN] Validate Expected Receipt Date = 1/1/2021 in the Purchase Line
        PurchaseLine.Validate("Expected Receipt Date", CalcDate('<-CM>', WorkDate()));

        // [THEN] Surplus Reservation Entry for the Sales Line with Shipment Date = 28/1/2021
        VerifyReservationEntryStatusQtyShipAndRcptDates(
          DATABASE::"Sales Line", Item."No.", DummyReservationEntry."Reservation Status"::Surplus, -Qty, WorkDate(), 0D);

        // [THEN] Surplus Reservation Entry for the Purchase Line with Expected Receipt Date = 1/1/2021 and <blank> Shipment Date
        VerifyReservationEntryStatusQtyShipAndRcptDates(
          DATABASE::"Purchase Line", Item."No.", DummyReservationEntry."Reservation Status"::Surplus, Qty, 0D, CalcDate('<-CM>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure OrderTrackingNotChangeStatusInReservationEntryWhenDropShipmentInSalesLine()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        DummyReservationEntry: Record "Reservation Entry";
        Qty: Integer;
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 318713] When Purchase is created with same Item and same Qty as Sales and Receipt Date is earlier than Shipment Date
        // [SCENARIO 318713] and Drop Shipment is used in Sales, then Order Tracking doesn't update status to Tracking in Reservation Entry
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Item had Order Tracking enabled
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Sales Order with 10 PCS of the Item and Shipment Date = 28/1/2021
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", Qty,
          Location.Code, WorkDate());

        // [GIVEN] Set Drop Shipment Purchasing Code in the Sales Line
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));
        SalesLine.Modify(true);

        // [GIVEN] Purchase Order with 10 PCS of the Item
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo(), Item."No.", Qty,
          Location.Code, WorkDate());

        // [WHEN] Validate Expected Receipt Date = 1/1/2021 in the Purchase Line
        PurchaseLine.Validate("Expected Receipt Date", CalcDate('<-CM>', WorkDate()));

        // [THEN] Surplus Reservation Entry for the Sales Line with Shipment Date = 28/1/2021
        VerifyReservationEntryStatusQtyShipAndRcptDates(
          DATABASE::"Sales Line", Item."No.", DummyReservationEntry."Reservation Status"::Surplus, -Qty, WorkDate(), 0D);

        // [THEN] Surplus Reservation Entry for the Purchase Line with Expected Receipt Date = 1/1/2021 and <blank> Shipment Date
        VerifyReservationEntryStatusQtyShipAndRcptDates(
          DATABASE::"Purchase Line", Item."No.", DummyReservationEntry."Reservation Status"::Surplus, Qty, 0D, CalcDate('<-CM>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple,SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingNotChangeStatusInReservationEntryWhenSpecialOrderInPurchLine()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Qty: Integer;
        QtyPurchSurplus: Integer;
    begin
        // [FEATURE] [Special Order]
        // [SCENARIO 330077] Second Sales Order is not tracked to special order Purchase with same Item
        Initialize();
        Qty := LibraryRandom.RandIntInRange(2, 10);

        // [GIVEN] Item had Order Tracking enabled
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Sales Order and Purchase Order with 10 PCS of the Item linked as Special Order (Pair of Surplus Entries with 10 PCS)
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", Qty,
          Location.Code, WorkDate());
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(false, true));
        SalesLine.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Modify(true);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryPurchase.GetSpecialOrder(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        ReservationEntry.SetSourceFilter(DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", -1, false);
        ReservationEntry.FindFirst();
        QtyPurchSurplus := ReservationEntry.Quantity;

        // [GIVEN] 2nd Sales Order with the same Item
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 0,
          Location.Code, WorkDate());

        // [WHEN] Validate Quantity = 1 in 2nd Sales Order Line
        SalesLine.Validate(Quantity, Qty - 1);

        // [THEN] Surplus Reservation Entry with 1 PCS for the second Sales Order Line
        ReservationEntry.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", -1, false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, -SalesLine.Quantity);
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.TestField("Expected Receipt Date", 0D);

        // [THEN] Surplus Reservation Entry for Purchase Order still has 10 PCS
        VerifyReservationEntryStatusQtyShipAndRcptDates(
          DATABASE::"Purchase Line", Item."No.", ReservationEntry."Reservation Status"::Surplus, QtyPurchSurplus, 0D,
          PurchaseLine."Expected Receipt Date");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandlerSimple,SalesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingNotChangeStatusInReservationEntryWhenDropShipmentInPurchLine()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        Qty: Integer;
        QtyPurchSurplus: Integer;
    begin
        // [FEATURE] [Drop Shipment]
        // [SCENARIO 330077] Second Sales Order is not tracked to drop shipment Purchase with same Item
        Initialize();
        Qty := LibraryRandom.RandIntInRange(2, 10);

        // [GIVEN] Item had Order Tracking enabled
        LibraryInventory.CreateItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // [GIVEN] Sales Order and Purchase Order with 10 PCS of the Item linked as Drop Shipment (Pair of Surplus Entries with 10 PCS)
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", Qty,
          Location.Code, WorkDate());
        SalesLine.Validate("Purchasing Code", CreatePurchasingCode(true, false));
        SalesLine.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Modify(true);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryPurchase.GetDropShipment(PurchaseHeader);
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        ReservationEntry.SetSourceFilter(DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", -1, false);
        ReservationEntry.FindFirst();
        QtyPurchSurplus := ReservationEntry.Quantity;

        // [GIVEN] 2nd Sales Order with the same Item
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", 0,
          Location.Code, WorkDate());

        // [WHEN] Validate Quantity = 1 in 2nd Sales Order Line
        SalesLine.Validate(Quantity, Qty - 1);

        // [THEN] Surplus Reservation Entry with 1 PCS for the second Sales Order Line
        ReservationEntry.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", -1, false);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, -SalesLine.Quantity);
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.TestField("Expected Receipt Date", 0D);

        // [THEN] Surplus Reservation Entry for Purchase Order still has 10 PCS
        VerifyReservationEntryStatusQtyShipAndRcptDates(
          DATABASE::"Purchase Line", Item."No.", ReservationEntry."Reservation Status"::Surplus, QtyPurchSurplus, 0D,
          PurchaseLine."Expected Receipt Date");
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Order Tracking");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Order Tracking");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        ItemJournalSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Order Tracking");
    end;

    local procedure NoSeriesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure ItemJournalSetup()
    begin
        Clear(ItemJournalTemplate);
        ItemJournalTemplate.Init();
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        ItemJournalTemplate.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate.Modify(true);

        Clear(ItemJournalBatch);
        ItemJournalBatch.Init();
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        CreateAndUpdateLocation(LocationOrange);  // Location Orange.
        LibraryWarehouse.CreateNumberOfBins(LocationOrange.Code, '', '', 2, false);  // Value required.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, false);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Put-away", true);
        Location.Validate("Always Create Put-away Line", true);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Receive", true);
        Location.Validate("Require Shipment", true);
        Location."Bin Mandatory" := true;
        Location.Modify(true);
    end;

    local procedure CreateItemWithProductionBOMSetup(var Item: Record Item; var Item2: Record Item; var Item3: Record Item; OrderTrackingPolicy: Enum "Order Tracking Policy")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Items.
        CreateItem(Item2, Item."Replenishment System"::Purchase, OrderTrackingPolicy, '');
        CreateItem(Item3, Item."Replenishment System"::Purchase, OrderTrackingPolicy, '');

        // Create Production BOM with two Component.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, Item2."No.", Item3."No.", 1);

        // Create Production Item.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", OrderTrackingPolicy, ProductionBOMHeader."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; OrderTrackingPolicy: Enum "Order Tracking Policy"; ProductionBOMNo: Code[20])
    begin
        // Random value for Unit Cost.
        LibraryVariableStorage.Enqueue(TrackingMessage);  // Enqueue value for message handler.
        LibraryManufacturing.CreateItemManufacturing(
          Item, Item."Costing Method"::FIFO, LibraryRandom.RandDec(50, 2), Item."Reordering Policy", Item."Flushing Method", '',
          ProductionBOMNo);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateItemManufacturing(var Item: Record Item; ComponentItemNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ComponentItemNo, 1);
        CreateItem(
          Item, Item."Replenishment System"::"Prod. Order", Item."Order Tracking Policy"::"Tracking & Action Msg.",
          ProductionBOMHeader."No.");
    end;

    local procedure CreateAndRefreshReleasedProdOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; DueDate: Date; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        UpdateDueDateOnReleasedProdOrder(ProductionOrder."No.", DueDate);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshFirmPlannedProdOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; DueDate: Date; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        UpdateDueDateOnFirmPlannedProdOrder(ProductionOrder."No.", DueDate);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreatePurchasingCode(DropShipment: Boolean; SpecialOrder: Boolean): Code[10]
    var
        Purchasing: Record Purchasing;
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", DropShipment);
        Purchasing.Validate("Special Order", SpecialOrder);
        Purchasing.Modify(true);
        exit(Purchasing.Code);
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.FindFirst();
    end;

    local procedure FindPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure UpdateDueDateOnReleasedProdOrder(No: Code[20]; DueDate: Date)
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", No);
        ReleasedProductionOrder."Due Date".SetValue(DueDate);
    end;

    local procedure UpdateDueDateOnFirmPlannedProdOrder(No: Code[20]; DueDate: Date)
    var
        FirmPlannedProdOrder: TestPage "Firm Planned Prod. Order";
    begin
        FirmPlannedProdOrder.OpenEdit();
        FirmPlannedProdOrder.FILTER.SetFilter("No.", No);
        FirmPlannedProdOrder."Due Date".SetValue(DueDate);
    end;

    local procedure OpenOrderTrackingForProduction(ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.ShowOrderTracking();
    end;

    local procedure OpenOrderTrackingForProdOrderComponent(ProdOrderComponent: Record "Prod. Order Component")
    begin
        ProdOrderComponent.ShowOrderTracking();
    end;

    local procedure OpenOrderTrackingForSales(SalesLine: Record "Sales Line")
    begin
        SalesLine.ShowOrderTracking();
    end;

    local procedure OpenOrderTrackingForPurchase(PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.ShowOrderTracking();
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; Status: Enum "Production Order Status"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure SelectProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Released);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindLast();
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        RequisitionWkshName.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateRequisitionLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Validate("Due Date", WorkDate());
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Modify(true);
    end;

    local procedure OrderTrackingForProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SelectProdOrderComponent(ProdOrderComponent, ProductionOrderNo, ItemNo);

        // Enqueue value for page handler.
        LibraryVariableStorage.Enqueue(ProdOrderComponent."Expected Quantity");
        LibraryVariableStorage.Enqueue(ProdOrderComponent."Expected Quantity" - Quantity);
        LibraryVariableStorage.Enqueue(Quantity);
        OpenOrderTrackingForProdOrderComponent(ProdOrderComponent);  // Open page handler - OrderTrackingPageHandler.
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        CreatePurchaseLineWithVariantCode(PurchaseHeader, PurchaseLine, ItemNo, VariantCode, Quantity);
    end;

    local procedure CreatePurchaseOrderWithLocationAndVariant(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLineWithLocationAndVariant(PurchaseHeader, PurchaseLine, ItemNo, Quantity, VariantCode, LocationCode, BinCode);
    end;

    local procedure CreatePurchaseLineWithVariantCode(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithLocationAndVariant(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Validate("Location Code", LocationCode);
        LibraryVariableStorage.Enqueue(WarehouseReceiveMessage);  // Enqueue value for Message Handler.
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        // Create Sales Order.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo, Quantity);
    end;

    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        // Create Sales Credit Memo.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", ItemNo, Quantity);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
    end;

    local procedure PostConsumption(ProductionOrder: Record "Production Order"; ConsumptionQty: Decimal; AppliedToEntryNo: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        LibraryManufacturing.CalculateConsumptionForJournal(ProductionOrder, ProdOrderComponent, WorkDate(), false);

        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate(Quantity, ConsumptionQty);
        ItemJournalLine.Validate("Applies-to Entry", AppliedToEntryNo);
        ItemJournalLine.Modify(true);
        LibraryManufacturing.PostConsumptionJournal();
    end;

    local procedure PostOutput(ProductionOrder: Record "Production Order"; OutputQty: Decimal): Integer
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryManufacturing.OutputJournalExplodeRouting(ProductionOrder);

        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrder."No.");
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Output);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Output Quantity", OutputQty);
        ItemJournalLine.Modify(true);
        LibraryManufacturing.PostOutputJournal();

        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.SetRange("Order Type", ItemLedgerEntry."Order Type"::Production);
        ItemLedgerEntry.SetRange("Order No.", ProductionOrder."No.");
        ItemLedgerEntry.FindLast();
        exit(ItemLedgerEntry."Entry No.");
    end;

    local procedure UpdateVariantCodeOnProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SelectProdOrderComponent(ProdOrderComponent, ProductionOrderNo, ItemNo);
        ProdOrderComponent.Validate("Variant Code", VariantCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateVariantCodeOnProdOrder(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        SelectProdOrderLine(ProdOrderLine, ProductionOrderNo, ProdOrderLine.Status::Released, ItemNo);
        ProdOrderLine.Validate("Variant Code", VariantCode);
        ProdOrderLine.Modify(true);
    end;

    local procedure UpdateVariantCodeOnSalesOrder(var SalesLine: Record "Sales Line"; VariantCode: Code[10])
    begin
        SalesLine.Validate("Variant Code", VariantCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVariantCodeOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; VariantCode: Code[10])
    begin
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateLocationAndVariantOnProdOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SelectProdOrderComponent(ProdOrderComponent, ProductionOrderNo, ItemNo);
        ProdOrderComponent.Validate("Variant Code", VariantCode);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Bin Code", BinCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateExpectedReceiptDateOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; ExpectedReceiptDate: Date)
    begin
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateShipmentDateOnSalesLine(var SalesLine: Record "Sales Line"; ShipmentDate: Date)
    begin
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure GetRequiredDate(Days: Integer; IncludeAdditionalPeriod: Integer; RelativeDate: Date): Date
    begin
        // Calculating a New Date relative to WorkDate.
        exit(CalcDate('<' + Format(LibraryRandom.RandInt(Days) + IncludeAdditionalPeriod) + 'D>', RelativeDate));
    end;

    local procedure CreateAndPostItemJournal(ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; Quantity: Decimal; PostJournal: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        if PostJournal then
            LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreatePurchaseOrderWithTwoLinesAndLocation(var PurchaseHeader: Record "Purchase Header"; Bin: Record Bin; ItemNo: Code[20]; ItemNo2: Code[20]; ItemVariantCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrderWithLocationAndVariant(PurchaseHeader, PurchaseLine, ItemNo, Quantity, ItemVariantCode, LocationCode, Bin.Code);
        Bin.Next();
        CreatePurchaseLineWithLocationAndVariant(PurchaseHeader, PurchaseLine, ItemNo2, Quantity, '', LocationCode, Bin.Code);  // Variant Code as Blank.
    end;

    local procedure VerifyOrderTracking(var OrderTracking: TestPage "Order Tracking")
    var
        UntrackedQuantity: Variant;
        TotalQuantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(TotalQuantity);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(UntrackedQuantity);  // Dequeue variable.
        OrderTracking."Total Quantity".AssertEquals(TotalQuantity);
        OrderTracking."Untracked Quantity".AssertEquals(UntrackedQuantity);
    end;

    local procedure VerifyQuantityOnOrderTracking(var OrderTracking: TestPage "Order Tracking")
    var
        Quantity: Variant;
        LineQuantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        LineQuantity := Quantity;  // Assign Variant to Decimal.
        OrderTracking.Quantity.AssertEquals(-LineQuantity);
    end;

    local procedure VerifyReservationEntryStatusQtyShipAndRcptDates(SourceType: Integer; ItemNo: Code[20]; ReservationStatus: Enum "Reservation Status"; Qty: Decimal; ShipmentDate: Date; ExpectedReceiptDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Reservation Status", ReservationStatus);
        ReservationEntry.TestField(Quantity, Qty);
        ReservationEntry.TestField("Shipment Date", ShipmentDate);
        ReservationEntry.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        QueuedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(QueuedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Message, QueuedMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        // Verify required Quantity values - Total Quantity and Untracked Quantity.
        VerifyOrderTracking(OrderTracking);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingDetailsPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        // Verify required Quantity values - Total Quantity, Untracked Qty and Quantity.
        VerifyOrderTracking(OrderTracking);
        VerifyQuantityOnOrderTracking(OrderTracking);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingMultipleLinePageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        // Verify required Quantity values - Total Quantity, Untracked Qty and Quantity.
        VerifyOrderTracking(OrderTracking);
        VerifyQuantityOnOrderTracking(OrderTracking);
        OrderTracking.Next();
        VerifyQuantityOnOrderTracking(OrderTracking);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SalesList.OK().Invoke();
    end;
}

