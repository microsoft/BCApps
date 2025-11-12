codeunit 137065 "SCM Reservation II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reservation] [SCM]
        IsInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        LocationWhite: Record Location;
        ManufacturingSetup: Record "Manufacturing Setup";
        LocationGreen: Record Location;
        LocationSilver: Record Location;
        LocationYellow: Record Location;
        LocationRed: Record Location;
        LocationRed2: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        Counter: Integer;
        CancelReservationMsg: Label 'Do you want to cancel all reservations in the %1?';
        ChangeNotAffectedMsg: Label 'The change will not affect existing entries.';
        ConfirmCalculateLowLevelCodeQst: Label 'Calculate low-level code';
        PickActivitiesCreatedMsg: Label 'Number of Invt. Pick activities created';
        VersionCountErr: Label 'Version count must match.';
        VersionCodeErr: Label 'Version Code must match.';
        AutoReservationNotPossibleMsg: Label 'Full automatic Reservation is not possible.';
        ProductionOrderCreatedMsg: Label 'Released Prod. Order';
        JournalLinesPostedMsg: Label 'The journal lines were successfully posted.';
        PickErr: Label 'The Quantity is incorrect.';
        CostAmountActualInILEErr: Label 'Cost Amount (Actual) in Item Ledger Entry is not correct. Maximum is %1, minimum is %2  ';
        FinishOrderErr: Label 'You cannot finish production order no. %1 because there is an outstanding pick for one or more components.';
        ErrorWrongMsg: Label 'Error message must be same';
        NothingAvailableToReserveErr: Label 'There is nothing available to reserve.';
        DateConflictWithExistingReservationsErr: Label 'The change leads to a date conflict with existing reservations.';
        PostJnlLinesMsg: Label 'Do you want to post the journal lines';
        SuggestedBackGroundRunQst: Label 'Would you like to run the low-level code calculation as a background job?';
        ActionMessageEntryExistErr: Label 'Action Message Entry exist for item %1', Comment = '%1 = Item No.';
        QuantityErr: Label 'Quantity must be equal to %1', Comment = '%1 = Quantity';

    [Test]
    [HandlerFunctions('ProdOrderComponentsHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderComponentsPageWithLocation()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasedProductionOrder: TestPage "Released Production Order";
        ItemNo: Code[20];
        InitialInventory: Decimal;
    begin
        // Setup: Create parent and child Item, create Production BOM. Create and release Purchase Order. Create Released Production Order.
        Initialize();
        ItemNo := CreateItemsSetup(Item);
        InitialInventory := LibraryRandom.RandInt(100);
        LibraryVariableStorage.Enqueue(InitialInventory);  // Enqueue variable.
        LibraryVariableStorage.Enqueue(ItemNo);  // Enqueue variable.
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LocationGreen.Code, InitialInventory);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", InitialInventory, LocationGreen.Code, '');

        // Exercise: Open components on Released Production Order.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrder."No.");
        ReleasedProductionOrder.ProdOrderLines.Components.Invoke();

        // Verify: Verify the value on Prod. Order Components page in ProdOrderComponentsHandler handler.
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FullReservationOnReleasedProdOrderComponentsWithLocation()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: Code[20];
        PrevComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Item, create Production BOM. Create and release Purchase Order and post it, create Released Production Order.
        Initialize();
        PrevComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationGreen.Code);

        ItemNo := CreateItemsSetup(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LocationGreen.Code, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationGreen.Code, '');

        // Exercise: Reserve components on Released Production Order.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation();

        // Verify: Verify the values on Production Order Components.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Released, ItemNo, Quantity, '', Item."Flushing Method");

        // Teardown
        UpdateManufacturingSetupComponentsAtLocation(PrevComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnSalesOrderWithLocation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and release Purchase Order and post it, create a Sales Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationGreen.Code, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive only.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity, LocationGreen.Code);

        // Exercise: Reserve the Item on sales Order.
        SalesLine.ShowReservation();

        // Verify: Verify the reserved quantity on Sales Line.
        VerifyReservationQtyOnSalesLine(SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler,CancelReserveConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelReservationOnSalesOrderWithReleasedProdOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Item, create Production BOM. Create a Released Production Orders, Create Sales Order and reserve it.
        Initialize();
        CreateItemsSetup(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, '', '');
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity, '');
        SalesLine.ShowReservation();

        // Exercise: Cancel reservation on Sales Line.
        SalesLine.ShowReservation();

        // Verify: Verify the reserved quantity on Sales Line as zero after cancel reservation.
        VerifyReservationQtyOnSalesLine(SalesHeader."No.", 0);
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PartialDeleteWithMultipleReleasedProductionOrderReservation()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Item, create Production BOM. Create two Released Production Orders, Create Sales Order and reserve on it.
        Initialize();
        CreateItemsSetup(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationGreen.Code, '');
        CreateAndRefreshProdOrder(ProductionOrder2, ProductionOrder2.Status::Released, Item."No.", Quantity, LocationGreen.Code, '');
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity, LocationGreen.Code);
        SalesLine.ShowReservation();

        // Exercise: Delete first Production Order.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder.Delete(true);

        // Verify: Verify the reserved quantity on Sales Line after deletion of a single Production Order.
        VerifyReservationQtyOnSalesLine(SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnSalesOrderWithUpdatedReceiptDate()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item. Create and release Purchase Order and post it, create a Sales Order and reserve it.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", '', Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive only.
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", Quantity, '');
        SalesLine.ShowReservation();

        // Exercise: Update Expected Receipt Date and Reserve it again.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Expected Receipt Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        PurchaseLine.Modify(true);

        // Verify: Verify the reserved quantity on Sales Line.
        VerifyReservationQtyOnSalesLine(SalesHeader."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnFirmPlannedProdOrderComponentsWithLocation()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: Code[20];
        PrevComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Item, create Production BOM. Create and release Purchase Order and Post as Receive and Invoice. Create a Firm Planned Production Order.
        Initialize();
        PrevComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationGreen.Code);

        ItemNo := CreateItemsSetup(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LocationGreen.Code, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", Quantity, LocationGreen.Code, '');

        // Exercise: Reserve Components on Firm Planned Prod. Order.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation();

        // Verify: Verify the Reservation made on Firm Planned Prod. Order.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::"Firm Planned", ItemNo, Quantity, '', Item."Flushing Method");

        // Teardown
        UpdateManufacturingSetupComponentsAtLocation(PrevComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ComponentsReservationOnChangeFirmPlannedProdOrderToReleased()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: Code[20];
        ProdOrderNo: Code[20];
        PrevComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [Production]
        // [SCENARIO] Check reserved Quantity on production component after release Production Order (components reserved for Firm Planned Prod. Order).

        // [GIVEN] Create parent and child Item, create Production BOM. Create and release Purchase Order and post it. Create a Firm Planned Production Order and reserve its components.
        Initialize();
        PrevComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation('');

        ItemNo := CreateItemsSetup(Item);
        Quantity := LibraryRandom.RandInt(100);  // Large value required.
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, '', Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive only.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", Quantity, '', '');
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation();

        // [WHEN] Change Firm Planned Prod. Order to Released Prod. Order.
        ProdOrderNo :=
          LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status, ProductionOrder.Status::Released);

        // [THEN] Verify the Changed status with values on Released Prod. Order.
        VerifyProdOrderComponent(ProdOrderNo, ProductionOrder.Status::Released, ItemNo, Quantity, '', Item."Flushing Method");

        // Teardown
        UpdateManufacturingSetupComponentsAtLocation(PrevComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWarehouseJournalLineWithLotTracking()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Setup: Create Item With Item Tracking Code, Create Warehouse Journal line and assign Tracking on it.
        Initialize();
        Bin.Get(LocationWhite.Code, LocationWhite."To-Production Bin Code");
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode());
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2));
        LibraryVariableStorage.Enqueue(Format(WarehouseJournalLine.Quantity));
        LibraryVariableStorage.Enqueue(WarehouseJournalLine.Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();  // Assign Lot No through WhseItemTrackingPageHandler.

        // Exercise: Register the Warehouse Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        // Verify: Verify the Warehouse Entry for Registered Warehouse Journal Line.
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", WarehouseJournalLine.Quantity, Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,WhseItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalculateConsumptionWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and refresh a Released Production order.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemSetupWithLotTracking(Item, Item2);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Item2, Quantity);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationWhite.Code, '');

        // Exercise: Create Consumption Journal and calculate Consumption with Tracking.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", false);  // Post Consumption FALSE.

        // Verify: Verify the Item Journal Line.
        VerifyItemJournalLine(Item."No.", ItemJournalLine."Entry Type"::Consumption);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterAndPostItemsWithProductionBOMAndLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
        Bin: Record Bin;
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);  // Large Random Value required for Test.
        CreateItemSetupWithLotTracking(Item, Item2);
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");

        // Exercise: Update the Items Inventory through Warehouse Item Journal.
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Item2, Quantity);

        // Verify: Verify the Warehouse Entries and Item Ledger Entries for the posted Items.
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, Bin.Code);
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Item2."No.", Quantity, Bin.Code);
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, true);
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::"Positive Adjmt.", Item2."No.", Quantity, true);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickFromProductionOrderWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and refresh a Released Production order.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);  // Large Random Value required for Test.
        CreateItemSetupWithLotTracking(Item, Item2);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Item2, Quantity);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");

        // Exercise: Create Warehouse Pick from the Released Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // Verify: Verify the values on Warehouse Activity Lines.
        VerifyWarehouseActivityLine(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Item."No.", Quantity,
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Item."No.", Quantity,
          WarehouseActivityLine."Action Type"::Place);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWarehousePickFromProductionOrderWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Lot Tracking. Create and refresh a Released Production order.
        // Create a Pick from Production Order.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);  // Large Random Value required for Test.
        CreateItemSetupWithLotTracking(Item, Item2);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Item2, Quantity);
        CreateWarehousePickfromProductionOrderSetup(Item, Item2, ProductionOrder, Quantity);

        // Exercise: Register the Pick.
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // Verify: Verify the Registered Warehouse Activity Lines.
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", Item."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Take);
        VerifyRegisteredWhseActivityLine(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", Item."No.", Quantity,
          RegisteredWhseActivityLine."Action Type"::Place);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostConsumptionWithProductionOrderWithLotTracking()
    begin
        // Setup.
        Initialize();
        OutputQuantityWithProductionOrderAndLotTracking(false);  // Post Output Journal FALSE.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostOutputWithProductionOrderWithLotTracking()
    begin
        // Setup.
        Initialize();
        OutputQuantityWithProductionOrderAndLotTracking(true);  // Post Output Journal TRUE.
    end;

    local procedure OutputQuantityWithProductionOrderAndLotTracking(PostOutput: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        ComponentsAtLocation: Code[10];
    begin
        // Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Lot Tracking. Create and refresh a Released Production order.
        // Create a Pick from Production Order and register it. Create and post a Consumption Journal.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandInt(100); // Large value required.
        CreateItemSetupWithLotTracking(Item, Item2);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Item2, Quantity);
        CreateWarehousePickfromProductionOrderSetup(Item, Item2, ProductionOrder, Quantity);
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // Exercise: Create and post a Consumption Journal for the Production Order. Create and post a Output Journal for the Production Order.
        LibraryVariableStorage.Enqueue(Quantity);  // Enqueue variable.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", true);  // Post Consumption TRUE.
        if PostOutput then
            CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, Quantity);

        // Verify: Verify Item Ledger Entry.
        if PostOutput then
            // Verify the Output Posted for the Production Order in Item Ledger Entry.
            VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item2."No.", Quantity, true)
        else
            // Verify the Consumption posted for the Production Order in Item Ledger Entry.
            VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Consumption, Item."No.", -Quantity, true);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityReceiveFromOutputJournalWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Setup: Create parent and child Items in a Production BOM and certify it. Create and refresh Released Production Order.
        Initialize();
        Bin.Get(LocationWhite.Code, LocationWhite."Cross-Dock Bin Code");
        CreateItemSetupWithLotTracking(Item, Item2);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", LibraryRandom.RandDec(100, 2), LocationWhite.Code,
          LocationWhite."To-Production Bin Code");

        // Exercise: Create and Post Output journal with Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, ProductionOrder.Quantity);

        // Verify: Verify the Item Ledger Entry and Warehouse Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item2."No.", ProductionOrder.Quantity, true);
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", Item2."No.", ProductionOrder.Quantity, LocationWhite."To-Production Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMWithRoutingLink()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingLinkCode: Code[10];
    begin
        // Setup: Create a child Item and update Inventory.
        Initialize();
        CreateItemAndUpdateInventory(Item2, LibraryRandom.RandDec(100, 2));

        // Exercise: Create Production BOM, Parent item and update Routing Link Code on Child Item.
        RoutingLinkCode := CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, true);
        CreateProductionItem(Item, ProductionBOMHeader."No.");

        // Verify: Verify the updated Production BOM Line.
        SelectProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.");
        ProductionBOMLine.TestField("Routing Link Code", RoutingLinkCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMFlushingMethodOnComponentItem()
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create child Item and update Inventory. Create Production BOM and Parent item.
        Initialize();
        CreateItemAndUpdateInventory(Item2, LibraryRandom.RandDec(100, 2));  // Child Item.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item2."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", 1);  // Value important.
        CreateProductionItem(Item, ProductionBOMHeader."No.");  // Parent item with Production BOM No.

        // Exercise: Update Flushing Method On Child Item, after Production BOM No. updated on Parent Item. Certify Production BOM and create a Released Production Order.
        Item2.Find();
        UpdateFlushingMethodAndCertifyBOM(Item2, ProductionBOMHeader);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the updated Production Order Component.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Released, Item2."No.", 0, '', Item2."Flushing Method");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ReleasedProductionOrderWithChangedOrderTrackingPolicy()
    var
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Setup: Create child Item and update Inventory. Create Production BOM and Parent item.
        Initialize();
        CreateItemAndUpdateInventory(Item2, LibraryRandom.RandDec(100, 2));
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item2."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item2."No.", 1);  // Value important.
        CreateProductionItem(Item, ProductionBOMHeader."No.");

        // Exercise: Update Order Tracking Policy on child Item. Create and refresh Released Production Order.
        LibraryVariableStorage.Enqueue(ChangeNotAffectedMsg);  // Enqueue variable.
        Item2.Find();
        Item2.Validate("Order Tracking Policy", Item2."Order Tracking Policy"::"Tracking & Action Msg.");
        Item2.Modify(true);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the Change Order Tracking Policy message in MessageHandler Handler. Verify the updated Production BOM Line.
        VerifyProductionOrder(ProductionOrder."No.", '', ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProductionOrderWithRouting()
    begin
        // Setup.
        Initialize();
        OutputFromProductionOrderWithRoutingSetup(false);  // Post Output Journal FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostOutputFromReleasedProductionOrderWithRoutingSetup()
    begin
        // Setup.
        Initialize();
        OutputFromProductionOrderWithRoutingSetup(true);  // Post Output Journal TRUE.
    end;

    local procedure OutputFromProductionOrderWithRoutingSetup(PostOutput: Boolean)
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Create parent and child Item, create Production BOM. Create Routing Setup and update Routing on Item. Create and refresh a Released Production Order.
        CreateItemsSetup(Item);
        CreateRoutingAndUpdateItem(RoutingHeader, Item);

        // Exercise: Create and refresh a Released production Order. Create and post and Output Journal for the Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');
        if PostOutput then
            CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, ProductionOrder.Quantity);

        // Verify: Verify the Item Ledger Entry for the posted Output. Verify the updated Released production Order.
        if PostOutput then
            VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item."No.", ProductionOrder.Quantity, false)
        else
            VerifyProductionOrder(ProductionOrder."No.", RoutingHeader."No.", ProductionOrder.Quantity)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProductionOrderComponentWithRoutingSetup()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ItemNo: Code[20];
        RoutingLinkCode: Code[10];
    begin
        // Setup: Create parent and child Item, create Production BOM. Create Routing Setup and update Routing on Item. Create and refresh a Released Production Order.
        Initialize();
        ItemNo := CreateItemsSetup(Item);
        CreateRoutingAndUpdateItem(RoutingHeader, Item);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Exercise: Update Routing Link on Production Order Component
        RoutingLinkCode := UpdateRoutingLinkOnProdOrderComponent(ProductionOrder."No.");

        // Verify: Verify the updated Production Order Component.
        VerifyProdOrderComponent(ProductionOrder."No.", ProductionOrder.Status::Released, ItemNo, 0, RoutingLinkCode, Item."Flushing Method");
    end;

    [Test]
    [HandlerFunctions('LowLevelCodeConfirmHandler')]
    [Scope('OnPrem')]
    procedure LowLevelCodeOnProductionBOMWithoutActiveBOMVersion()
    var
        Item: Record Item;
        DynamicLowLevelCode: Boolean;
    begin
        // Setup: Create a Child Item and update Inventory, create a certified Production BOM, Parent Item and attach Production BOM.
        Initialize();
        DynamicLowLevelCode := UpdateManufacturingSetupDynamicLowLevelCode(false);  // Dynamic Low Level Code False.
        CreateItemsSetup(Item);

        // Exercise: Calculate Low Level code.
        LibraryPlanning.CalculateLowLevelCode();

        // Verify: Verify Low Level Code on Production BOM.
        VerifyLowLevelCodeOnProductionBOM(Item."Production BOM No.", 1);  // Value required. The Low Level Code in the Production BOM for the Child Item.

        // Tear Down: Restore original value of Dynamic Low Level Code.
        UpdateManufacturingSetupDynamicLowLevelCode(DynamicLowLevelCode);
    end;

    [Test]
    [HandlerFunctions('LowLevelCodeConfirmHandler')]
    [Scope('OnPrem')]
    procedure LowLevelCodeOnProductionBOMWithCertifiedBOMVersion()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        DynamicLowLevelCode: Boolean;
    begin
        // Setup: Create a Child Item and update Inventory, create a certified Production BOM, Parent Item and attach Production BOM.
        Initialize();
        DynamicLowLevelCode := UpdateManufacturingSetupDynamicLowLevelCode(false);  // Dynamic Low Level Code False.
        CreateItemsSetup(Item);

        // Exercise: Create certified Production BOM Version. Calculate Low Level code.
        CreateProductionBOMVersion(Item."Production BOM No.", Item."Base Unit of Measure", ProductionBOMVersion.Status::Certified);
        LibraryPlanning.CalculateLowLevelCode();

        // Verify: Verify Low Level Code on Production BOM.
        VerifyLowLevelCodeOnProductionBOM(Item."Production BOM No.", 1);  // Value required. The Low Level Code in the Production BOM for the Child Item.

        // Tear Down: Restore original value of Dynamic Low Level Code.
        UpdateManufacturingSetupDynamicLowLevelCode(DynamicLowLevelCode);
    end;

    [Test]
    [HandlerFunctions('LowLevelCodeConfirmHandler')]
    [Scope('OnPrem')]
    procedure LowLevelCodeOnProductionBOMWithClosedBOMVersion()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        DynamicLowLevelCode: Boolean;
    begin
        // Setup: Create a Child Item and update Inventory, create a certified Production BOM, Parent Item and attach Production BOM.
        Initialize();
        DynamicLowLevelCode := UpdateManufacturingSetupDynamicLowLevelCode(false);  // Dynamic Low Level Code False.
        CreateItemsSetup(Item);

        // Exercise: Create closed Production BOM Version. Calculate Low Level code.
        CreateProductionBOMVersion(Item."Production BOM No.", Item."Base Unit of Measure", ProductionBOMVersion.Status::Closed);
        LibraryPlanning.CalculateLowLevelCode();

        // Verify: Verify Low Level Code on Production BOM.
        VerifyLowLevelCodeOnProductionBOM(Item."Production BOM No.", 1);  // Value required. The Low Level Code in the Production BOM for the Child Item.

        // Tear Down: Restore original value of Dynamic Low Level Code.
        UpdateManufacturingSetupDynamicLowLevelCode(DynamicLowLevelCode);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnReleasedProductionOrderWithCertifiedBOM()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        ReleasedProductionOrder: TestPage "Released Production Order";
        Quantity: Decimal;
    begin
        // Setup: Find Bin at Location, Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and refresh a Released Production order.
        Initialize();
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemSetupWithLotTracking(Item, Item2);

        // Update Inventory for parent and child Item on Silver Location.
        CreateAndPostItemJournalLine(Item."No.", Quantity, Bin.Code, LocationSilver.Code, true);  // Using Tracking TRUE.
        CreateAndPostItemJournalLine(Item2."No.", Quantity, Bin.Code, LocationSilver.Code, true);  // Using Tracking TRUE.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationSilver.Code, Bin.Code);

        // Exercise: Open Item Tracking page from Released Production Order.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrder."No.");
        ReleasedProductionOrder.ProdOrderLines.ItemTrackingLines.Invoke();

        // Verify: Verify the Released Production Order after opening Item Tracking Line successfully from it.
        VerifyProductionOrder(ProductionOrder."No.", '', ProductionOrder.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InventoryPickFromReleasedProductionOrderWithLotTracking()
    begin
        // Setup.
        Initialize();
        WhseActivityFromReleasedProductionOrderWithLotTracking(false);  // Post Inventory Pick FALSE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostInventoryPickFromReleasedProductionOrderWithLotTracking()
    begin
        // Setup.
        Initialize();
        WhseActivityFromReleasedProductionOrderWithLotTracking(true);  // Post Inventory Pick TRUE.
    end;

    local procedure WhseActivityFromReleasedProductionOrderWithLotTracking(PostInventoryPick: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and refresh a Released Production Order.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationSilver.Code);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandDec(100, 2);  // Large Random Value required for Test.
        CreateItemSetupWithLotTracking(Item, Item2);

        // Update Inventory For parent and child Items at Silver Location.
        CreateAndPostItemJournalLine(Item."No.", Quantity, Bin.Code, LocationSilver.Code, true);  // Using Tracking TRUE.
        CreateAndPostItemJournalLine(Item2."No.", Quantity, Bin.Code, LocationSilver.Code, true);  // Using Tracking TRUE.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationSilver.Code, Bin.Code);

        // Exercise: Create Inventory Pick from the Released Production Order.
        LibraryVariableStorage.Enqueue(PickActivitiesCreatedMsg);  // Enqueue variable required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
        if PostInventoryPick then begin
            // Auto fill Quantity To Handle for whole Quantity. Update Lot No on Whse Activity Line and post Inventory Pick.
            WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
            UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
              Item."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, WarehouseActivityLine."Qty. to Handle");
            FindWarehouseActivityHeader(
              WarehouseActivityHeader, ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption",
              WarehouseActivityLine."Action Type"::Take);
            LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Invoice False.
        end;

        if PostInventoryPick then
            // Verify: Verify that Inventory Pick posted successfully.
            VerifyPostedInventoryPickLine(ProductionOrder."No.", Item."No.", Bin.Code, Quantity, LocationSilver.Code)
        else
            // Verify that Inventory Pick created successfully.
            VerifyWarehouseActivityLine(
            ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Item."No.", Quantity,
            WarehouseActivityLine."Action Type"::Take);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMLineWithNewUnitOfMeasure()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Setup: Create Item and Item Unit Of Measure and update Inventory.
        Initialize();
        CreateItemUnitOfMeasureSetup(Item, ItemUnitOfMeasure);
        CreateAndPostItemJournalLine(Item."No.", LibraryRandom.RandDec(100, 2), '', '', false);  // Using Tracking FALSE.

        // Exercise: Create Production BOM.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // Verify: Verify that Unit Of Measure Code updated on Item is also updated on Production BOM Line.
        SelectProductionBOMLine(ProductionBOMLine, ProductionBOMHeader."No.");
        ProductionBOMLine.TestField("Unit of Measure Code", ItemUnitOfMeasure.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMLowLevelCodeWithCertifiedBOMVersion()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Setup: Create a Child Item and update Inventory, create a certified Production BOM, Parent Item and attach Production BOM.
        Initialize();
        CreateItemsSetup(Item);

        // Exercise: Create certified Production BOM Version.
        CreateProductionBOMVersion(Item."Production BOM No.", Item."Base Unit of Measure", ProductionBOMVersion.Status::Certified);

        // Verify: Verify Low Level Code on Production BOM is same after adding Certified BOM version to it.
        VerifyLowLevelCodeOnProductionBOM(Item."Production BOM No.", 1);  // Value required. The Low Level Code in the Production BOM for the Parent Item.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderComponentsWithRoutingLinkCode()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLinkCode: Code[10];
    begin
        // Setup: Create child Item, create certified Production BOM, creat parent Item and attach Production BOM. Create Routing Setup and update Routing Link Code on Item.
        Initialize();
        CreateItemAndUpdateInventory(Item2, LibraryRandom.RandDec(100, 2));
        RoutingLinkCode := CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, true);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        CreateRoutingAndUpdateItem(RoutingHeader, Item);
        UpdateRoutingLine(RoutingHeader, RoutingLinkCode);

        // Exercise: Create and refresh a Firm Planned Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify Routing Link Code updated on Routing Line is updated on Production BOM Components of Firm Planned Production Order.
        VerifyProdOrderComponent(
          ProductionOrder."No.", ProductionOrder.Status::"Firm Planned", Item2."No.", 0, RoutingLinkCode, Item."Flushing Method");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutputJournalPostingForNegativeOutput()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Decimal;
    begin
        // Setup: Create child Item, create certified Production BOM, parent Item and attach Production BOM. Create Routing Setup and update Routing Link Code on Item.
        Initialize();
        CreateItemsSetup(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateRoutingAndUpdateItem(RoutingHeader, Item);

        // Exercise: Create and refresh a Released production Order. Create and post and Output Journal for the Production Order with negative Quantity.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, '', '');
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", false, -Quantity);

        // Verify: Verify the Item Ledger Entry for the posted negative Output from Output Journal for Released Production Order.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item."No.", -ProductionOrder.Quantity, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostPerOnProductionOrderWithRouting()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLineUnitCostPer: Decimal;
    begin
        // Setup: Create parent and child Items, create Production BOM, attach Production BOM to parent Item and certify it. Create Routing Setup and update Routing on parent Item.
        Initialize();
        CreateItemsSetup(Item);
        RoutingLineUnitCostPer := CreateRoutingAndUpdateItem(RoutingHeader, Item);

        // Exercise: Create and refresh a Released Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify that Unit Cost Per is populated successfully on Routing Line.
        VerifyProductionOrderRoutingLine(ProductionOrder."No.", RoutingLineUnitCostPer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitCostPerOnProductionOrderWithRoutingAndRegenerativePlan()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrderLine: Record "Prod. Order Line";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLineUnitCostPer: Decimal;
    begin
        // Setup: Create Parent and child Items, create certified Production BOM attach Production BOM to parent Item,update Item for Planning. Create Routing Setup and update Routing on parent Item. Create a Sales Order.
        Initialize();
        UpdateItemPlanningParameters(Item);
        RoutingLineUnitCostPer := CreateRoutingAndUpdateItem(RoutingHeader, Item);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(10, 2) + 1000, '');

        // Exercise: Calculate Regenerative Plan through Planning Worksheet on WORKDATE. Accept and carry out Action Message.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        AcceptAndCarryOutActionMessage(Item."No.");

        // Verify: Verify the Unit Cost Per on Routing Line calculated correctly through Calculate Regenerative Plan.
        FindProductionOrderLine(ProdOrderLine, Item."No.");
        VerifyProductionOrderRoutingLine(ProdOrderLine."Prod. Order No.", RoutingLineUnitCostPer);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderChangedRoutingNoWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        Quantity: Decimal;
    begin
        // Setup: Create parent and child Items with Tracking in a Production BOM and certify it. Create Routing and update Routing on parent Item. Update Inventory for Items with Tracking on a Location. Create and refresh a Released Production Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemSetupWithLotTracking(Item, Item2);
        CreateRoutingAndUpdateItem(RoutingHeader, Item2);
        CreateAndPostItemJournalLine(Item."No.", Quantity, '', LocationGreen.Code, true);  // Using Tracking TRUE.
        CreateAndPostItemJournalLine(Item2."No.", Quantity, '', LocationGreen.Code, true);  // Using Tracking TRUE.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationGreen.Code, '');

        // Exercise: Update Routing No to blank on Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrder."No.");
        ProductionOrder.Validate("Routing No.", '');
        ProductionOrder.Modify(true);

        // Verify: Verify that Routing No is not blank on Production Order routing Line.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePutAwayWithProductionBOMAndLotTracking()
    begin
        // Setup.
        Initialize();
        WarehouseActivityWithProductionBOMAndLotTracking(true, false, false);  // Create Warehouse Put Away TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisteredWhsePutAwayWithProductionBOMAndLotTracking()
    begin
        // Setup.
        Initialize();
        WarehouseActivityWithProductionBOMAndLotTracking(false, true, false);  // Register Warehouse Put Away TRUE.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePickWithProductionBOMAndLotTracking()
    begin
        // Setup.
        Initialize();
        WarehouseActivityWithProductionBOMAndLotTracking(false, true, true);  // Register Warehouse Put Away and create Warehouse Pick TRUE.
    end;

    local procedure WarehouseActivityWithProductionBOMAndLotTracking(PostWarehouseReceipt: Boolean; RegisterPutAway: Boolean; CreatePick: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PurchaseLine: Record "Purchase Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        PrevComponentsAtLocation: Code[10];
    begin
        // Update Manufacturing Components at Location. Create parent and child Items with Tracking in a Production BOM and certify it. Create and release Purchase Order and assign Lot Tracking to it. Create Whse Receipt from it.
        PrevComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationYellow.Code);
        Quantity := LibraryRandom.RandInt(100);
        CreateItemSetupWithLotTracking(Item, Item2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", LocationYellow.Code, Quantity);
        PurchaseLine.OpenItemTrackingLines();  // Invokes ItemTrackingPageHandler.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptNo(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");

        // Exercise: Post Warehouse Receipt.
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Register the Put Away created.
        if RegisterPutAway then begin
            FindWarehouseActivityLine(
              WarehouseActivityLine, PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order",
              WarehouseActivityLine."Action Type");
            RegisterWarehouseActivity(
              PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order", WarehouseActivityLine."Action Type");
        end;
        // Create and refresh a Released Production Order and create Pick from it.
        if CreatePick then begin
            CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationYellow.Code, '');
            LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        end;

        // Verify: Verify the posted Wraehouse Receipt.
        if PostWarehouseReceipt then
            VerifyWarehouseActivityLine(
              PurchaseHeader."No.", WarehouseActivityLine."Source Document"::"Purchase Order", Item."No.", Quantity,
              WarehouseActivityLine."Action Type")
        // Verify the Registered Put Away.
        else
            if RegisterPutAway and not CreatePick then
                VerifyRegisteredWhseActivityLine(
                  RegisteredWhseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."No.", Quantity,
                  RegisteredWhseActivityLine."Action Type")
            else
                // Verify the Pick created from Released Production Order.
                VerifyWarehouseActivityLine(
              ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Item."No.", Quantity,
              WarehouseActivityLine."Action Type");

        // Teardown.
        UpdateManufacturingSetupComponentsAtLocation(PrevComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionJournalFromProdOrderWithBinAndLocation()
    var
        Item: Record Item;
        Item2: Record Item;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Find Bin at Location, Create parent and child Items in a Production BOM and certify it. Update Inventory for parent and child Items at Location.
        Initialize();
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        CreateItemsSetupWithLocationAndBin(Item, Item2, LibraryRandom.RandDec(100, 2), LocationRed.Code, Bin.Code);

        // Exercise: Create and refresh a Released Production order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), LocationRed.Code, Bin.Code);

        // Verify: Verify that Production Journal page is opened successfully from Production Order and Verify Item No on Production Journal page.
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue variable required inside ProductionJournalPageHandler.
        OpenProductionJournal(ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler')]
    [Scope('OnPrem')]
    procedure ProdJournalFromProductionOrderWithChangedBinAndLocationOnComponent()
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // Setup: Find Bins at Locations, Create parent and child Items in a Production BOM and certify it. Update Inventory for parent and child Items at Location. Create and refresh a Released Production order.
        Initialize();
        LibraryWarehouse.FindBin(Bin, LocationRed.Code, '', 1);  // Find Bin of Index 1.
        LibraryWarehouse.FindBin(Bin2, LocationRed2.Code, '', 1);  // Find Bin of Index 1.
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemsSetupWithLocationAndBin(Item, Item2, Quantity, LocationRed.Code, Bin.Code);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationRed.Code, Bin.Code);

        // Create a new Production Order Component at different Location and Bin.
        LibraryInventory.CreateItem(Item3);
        CreateAndPostItemJournalLine(Item3."No.", Quantity, Bin2.Code, LocationRed2.Code, false);  // Using Tracking TRUE.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        CreateAndUpdateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder."No.", Item3."No.", ProdOrderComponent."Quantity per",
          ProdOrderComponent."Prod. Order Line No.", LocationRed2.Code);

        // Exercise: Open Production Journal Page from Released Production Order.
        LibraryVariableStorage.Enqueue(Item3."No.");  // Enqueue variable for Page Handler - ProductionJournalHandler.
        OpenProductionJournal(ProductionOrder."No.");

        // Verify: Verify that Production Journal Page opens successfully after updating Component with different Location through ProductionOrderPageHandler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedProductionOrderWithLocation()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: Code[20];
    begin
        // Setup: Create parent and child Items and update their Inventory. Create Production BOM and certify it.
        Initialize();
        ItemNo := CreateItemsSetup(Item);

        // Exercise: Create and refresh Planned Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ItemNo, LibraryRandom.RandDec(100, 2), LocationGreen.Code, '');

        // Verify: Verify that Planned Production Order Line is updated with Location Code.
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField("Location Code", LocationGreen.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedProductionOrderComponentWithRoutingLinkCode()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingLinkCode: Code[10];
    begin
        // Setup: Create child Item, create certified Production BOM, creat parent Item and attach Production BOM. Create Routing Setup and update Routing Link Code on Item.
        Initialize();
        CreateItemAndUpdateInventory(Item2, LibraryRandom.RandDec(100, 2));
        RoutingLinkCode := CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, true);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        CreateRoutingAndUpdateItem(RoutingHeader, Item);
        UpdateRoutingLine(RoutingHeader, RoutingLinkCode);

        // Exercise: Create and refresh a Planned Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Planned, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify Routing Link Code updated on Routing Line is updated on Production BOM Components of Planned Production Order.
        VerifyProdOrderComponent(
          ProductionOrder."No.", ProductionOrder.Status::Planned, Item2."No.", 0, RoutingLinkCode, Item."Flushing Method");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplanProductionOrderWithRouting()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        RoutingHeader: Record "Routing Header";
        Direction: Option Forward,Backward;
        CalcMethod: Option "All Levels";
    begin
        // Setup: Create parent and child Item, create Production BOM. Create Routing Setup and update Routing on Item. Update Routing for Send Ahead Quantity. Create and refresh a Released Production Order.
        Initialize();
        CreateItemsSetup(Item);
        CreateRoutingAndUpdateItem(RoutingHeader, Item);
        UpdateRoutingLine(RoutingHeader, '');
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Exercise: Replan Production Order.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"All Levels");

        // Verify: Verify that Send Ahead Quantity exist after Replan Production Order.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProductionOrder."No.");
        ProdOrderRoutingLine.TestField("Send-Ahead Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedQuantityBaseOnProductionOrderComponent()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        ProdOrderComponent: Record "Prod. Order Component";
        RoutingLinkCode: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create child Item, create certified Production BOM, creat parent Item and attach Production BOM. Create Routing Setup and update Routing Link Code on Item.
        Initialize();
        CreateItemAndUpdateInventory(Item2, LibraryRandom.RandDec(100, 2));
        Quantity := LibraryRandom.RandInt(100);
        RoutingLinkCode := CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, true);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        CreateRoutingAndUpdateItem(RoutingHeader, Item);
        UpdateRoutingLine(RoutingHeader, RoutingLinkCode);

        // Exercise: Create and refresh a Released Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, '', '');

        // Verify: Verify the Expected Qty (Base) is populated correctly on Production Order Component.
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.TestField("Expected Qty. (Base)", Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RoutingOnPlannedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
    begin
        // Setup: Create parent and child Item, create Production BOM. Create Routing setup and update Routing on Item.
        Initialize();
        CreateItemsSetup(Item);
        CreateRoutingAndUpdateItem(RoutingHeader, Item);

        // Exercise: Create and refresh a Planned Production Order.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Planned, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify the Routing updated on Planned Production Order.
        ProductionOrder.Get(ProductionOrder.Status::Planned, ProductionOrder."No.");
        ProductionOrder.TestField("Routing No.", RoutingHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMMatrixPerVersionWithCopyBOM()
    begin
        // Verify the Production BOM Matrix Per Version with Copy BOM.
        // Setup.
        Initialize();
        ProductionBOMMatrixWithCopyBOM(false);  // Multiple BOM Versions -FALSE.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionBOMMatrixPerVersionWithCopyBOMAndMultipleBOMVersions()
    begin
        // Verify the Production BOM Matrix Per Version with Copy BOM with multiple BOM Versions.
        // Setup.
        Initialize();
        ProductionBOMMatrixWithCopyBOM(true);  // Multiple BOM Versions -TRUE.
    end;

    local procedure ProductionBOMMatrixWithCopyBOM(MultipleBOMVersions: Boolean)
    var
        Item: Record Item;
        VersionCode: array[4] of Text[80];
        VersionCount: Integer;
    begin
        // Create Production Item, attach Production BOM to it. Create Production BOM version with Copy BOM.
        CreateItemsSetup(Item);
        CreateProductionBOMVersionWithCopyBOM(Item."Production BOM No.");
        if MultipleBOMVersions then
            CreateProductionBOMVersionWithCopyBOM(Item."Production BOM No.");

        // Exercise: Generate matrix data to match the BOM Version created.
        VersionCount := GenerateMatrixDataForBOMVersion(VersionCode, Item."Production BOM No.");

        // Verify: Verify BOM Matrix Column Count and Column with source Production BOM Version.
        VerifyMatrixBOMVersion(Item."Production BOM No.", VersionCode, VersionCount);
    end;

    [Test]
    [HandlerFunctions('ProductionBOMListHandler')]
    [Scope('OnPrem')]
    procedure ProductionBOMMatrixPerVersionWithCopyVersion()
    begin
        // Verify the Production BOM Matrix Per Version with Copy Version.
        // Setup.
        Initialize();
        ProductionBOMMatrixWithCopyVersion(false);  // Multiple BOM Versions -FALSE.
    end;

    [Test]
    [HandlerFunctions('ProductionBOMListHandler')]
    [Scope('OnPrem')]
    procedure ProductionBOMMatrixPerVersionWithCopyVersionAndMultipleBOMVersions()
    begin
        // Verify the Production BOM Matrix Per Version with Copy Version and multiple BOM Versions.
        // Setup.
        Initialize();
        ProductionBOMMatrixWithCopyVersion(true);  // Multiple BOM Versions -TRUE.
    end;

    local procedure ProductionBOMMatrixWithCopyVersion(MultipleBOMVersions: Boolean)
    var
        Item: Record Item;
        VersionCode: array[4] of Text[80];
        VersionCount: Integer;
    begin
        // Create Production Item, attach Production BOM to it. Create Production BOM version with Copy Version.
        CreateItemsSetup(Item);
        CreateBOMVersionWithCopyVersion(Item);
        if MultipleBOMVersions then
            CreateBOMVersionWithCopyVersion(Item);

        // Exercise: Generate matrix data to match the BOM Version created.
        VersionCount := GenerateMatrixDataForBOMVersion(VersionCode, Item."Production BOM No.");

        // Verify: Verify BOM Matrix Column Count and Column with source Production BOM Version.
        VerifyMatrixBOMVersion(Item."Production BOM No.", VersionCode, VersionCount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithSurplusQuantityFromRegenerativePlanWithProductionBOM()
    begin
        // Verify that correct Surplus Quantity is populated on Purchase Order with Calculate Regenerative Plan from Requisition Worksheet.
        // Setup.
        Initialize();
        OrderWithSurplusQuantityFromRegenerativePlanWithProductionBOM("Replenishment System"::Purchase);  // Replenishment System -Purchase.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderWithSurplusQuantityFromRegenerativePlanWithProductionBOM()
    begin
        // Verify that correct Surplus Quantity is populated on Production Order with Calculate Regenerative Plan from Requisition Worksheet.
        // Setup.
        Initialize();
        OrderWithSurplusQuantityFromRegenerativePlanWithProductionBOM("Replenishment System"::"Prod. Order");  // Replenishment System -Prod. Order.
    end;

    local procedure OrderWithSurplusQuantityFromRegenerativePlanWithProductionBOM(ReplenishmentSystem: Enum "Replenishment System")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        SurplusQuantity: Decimal;
    begin
        // Create parent and child Items, create certified Production BOM, attach Production BOM to parent Item, update Item for Planning with safety Stock and Replenishment System. Create a Sales Order.
        SurplusQuantity := LibraryRandom.RandDec(100, 2);
        CreateItemWithPlanningParametersAndProductionBOM(Item, ReplenishmentSystem, SurplusQuantity);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(100, 2), '');

        // Exercise: Calculate Regenerative Plan through Planning Worksheet on WORKDATE. Accept and carry out Action Message.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        AcceptAndCarryOutActionMessage(Item."No.");

        // Verify: Verify that Production / Purchase Order Line created with Surplus Quantity in addition to the Quantity.
        if ReplenishmentSystem = ReplenishmentSystem::"Prod. Order" then
            VerifyProductionOrderLine(Item."No.", SalesLine.Quantity + SurplusQuantity)
        else
            VerifyPurchaseLine(Item."No.", SalesLine.Quantity + SurplusQuantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProductionOrderWithNewProductionItemOnProductionBOM()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
    begin
        // Setup: Create Item hierarchy with two Production BOMs and certify Production BOM.
        Initialize();
        CreateItemHierarchy(Item, Item2);

        // Exercise: Create a Released Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandDec(100, 2), '', '');

        // Verify: Verify that correct Item and Quantity is populated on Production Order Line.
        VerifyProductionOrderLine(Item."No.", ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineWithNewProductionItemOnProductionBOM()
    var
        Item: Record Item;
        Item2: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Setup: Create Item hierarchy with two Production BOMs and certify Production BOM. Update Reordering Policy on updated BOM Item. Create a Sales Order.
        Initialize();
        CreateItemHierarchy(Item, Item2);
        UpdateLotForLotReorderingPolicyOnItem(Item);
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", LibraryRandom.RandDec(100, 2), '');

        // Exercise: Calculate Regenerative Plan through Planning Worksheet on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify the Quantity and Due Date on Requisition Line for correct Parent Item.
        SelectRequisitionLine(RequisitionLine, Item."No.");
        RequisitionLine.TestField(Quantity, SalesLine.Quantity);
        RequisitionLine.TestField("Due Date", SalesLine."Shipment Date");
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ReservationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ReservationOnSalesOrderWithLotTracking()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking.
        Initialize();
        CreateItemSetupWithLotTracking(Item, Item2);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item, Item2, LibraryRandom.RandDec(100, 2));

        // Exercise: Create and release a Sales Order with reservation.
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item2."No.", LibraryRandom.RandDecInRange(101, 200, 2), LocationWhite.Code);  // Quantity value required for Full Auto Reservation and Warehouse Shipment.

        // Verify: Verify the Shipment Date and Location Code in Reservation Entry for Sales Order. Verify the Automatic Reservation message in MessageHandler.
        VerifyReservationEntry(Item2."No.", LocationWhite.Code, SalesHeader."Shipment Date");
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ReservationHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PickFromProductionOrderWithLotTrackingAndReservation()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and release a Sales Order with reservation. Create Warehouse Shipment.
        // Create Production Order from Sales Order.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemsAndWarehouseShipmentWithReservationAndTrackingSetup(Item, Item2, SalesHeader, LocationWhite, Quantity);
        CreateProductionOrderFromSalesOrder(ProductionOrder, SalesHeader);

        // Exercise: Create Warehouse Pick from the Released Production Order.
        CreatePickFromProductionOrder(ProductionOrder, Item2."No.");

        // Verify: Verify that Pick is created successfully from Production Order with Lot Tracking with Reservation.
        VerifyWarehouseActivityLine(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Item."No.", Quantity,
          WarehouseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", Item."No.", Quantity,
          WarehouseActivityLine."Action Type"::Place);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,ReservationHandler,ItemTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure OutPutFromProductionOrderWithLotTrackingAndReservation()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ComponentsAtLocation: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Update Components at a Location. Create parent and child Items with Tracking in a Production BOM and certify it. Update Inventory for Items with Tracking. Create and release a Sales Order with reservation. Create Warehouse Shipment.
        // Create Production Order from Sales Order. Create a Warehouse Pick from Production Order.
        Initialize();
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateItemsAndWarehouseShipmentWithReservationAndTrackingSetup(Item, Item2, SalesHeader, LocationWhite, Quantity);
        CreateProductionOrderFromSalesOrder(ProductionOrder, SalesHeader);
        CreatePickFromProductionOrder(ProductionOrder, Item2."No.");

        // Exercise: Post Output Journal with Lot Tracking.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, Quantity);

        // Verify: Verify the Quantity and Tracking in Item Ledger Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item2."No.", Quantity, true);  // Lot Tracking -TRUE.

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('SerialItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostOutputFromProductionOrderWithSerialTracking()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        Item2: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Setup: Create parent and child Items with Serial Tracking, Create Production BOM and certify it. Update Inventory of the parent Item. Create and refresh a Released Production Order.
        Initialize();
        CreateItemSetupWithSerialTracking(Item, Item2);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(10), '', '');

        // Exercise: Create and post and Output Journal for the Production Order.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, ProductionOrder.Quantity);

        // Verify: Verify the Quantity and Serial Tracking in Item Ledger Entry for the posted Output.
        VerifySerialTrackingAndQuantityInItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, Item."No.", 1);  // Serial Tracked Quantity.
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,ConfirmHandler,ProductionJournalPostingMessageHandler')]
    [Scope('OnPrem')]
    procedure ConsumptionQuantityInMultiLevelProduction()
    var
        ProductionBOMHeader: array[4] of Record "Production BOM Header";
        Item: array[3] of Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ProdOrderLine: Record "Prod. Order Line";
        ItemNo: array[7] of Code[20];
        CompItemNo1: array[4] of Code[20];
        CompItemNo2: array[4] of Code[20];
        Quantity: Integer;
        i: Integer;
        ConsumptionQty: array[4] of Integer;
        OutputQty: array[4] of Integer;
    begin
        // Setup: Update Components at a Location.
        Initialize();
        UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);

        // Create a Item with multiple level Production BOM:
        // Item1(Item2(Item4(Item6, Item7), Item5)), Item3(Item6, Item7))
        CreateItems(ItemNo);
        CompItemNo1[1] := ItemNo[2];
        CompItemNo2[1] := ItemNo[3];
        CompItemNo1[2] := ItemNo[4];
        CompItemNo2[2] := ItemNo[5];
        CompItemNo1[3] := ItemNo[6];
        CompItemNo2[3] := ItemNo[7];
        CompItemNo1[4] := ItemNo[6];
        CompItemNo2[4] := ItemNo[7];
        Quantity := LibraryRandom.RandInt(5);
        for i := 1 to 4 do begin
            LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader[i], CompItemNo1[i], CompItemNo2[i], Quantity);
            UpdateItemProdBOM(ItemNo[i], ProductionBOMHeader[i]."No.");
        end;

        // Update Inventory in Warehouse Item Journal and Item Journal.
        Item[1].Get(ItemNo[5]);
        Item[2].Get(ItemNo[6]);
        Item[3].Get(ItemNo[7]);
        UpdateInventoryInWhseItemJournal(LocationWhite.Code, Item, Power(Quantity, 4) + Power(Quantity, 3));

        // Create and Refresh Production Order, create and register Whse. Pick
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, ItemNo[1], Quantity, LocationWhite.Code, '');
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption",
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise: Post Production Journal lines in PostProductionJournalHandler.
        // Verify: Verify Consumption Qty and Output Qty in the Item Ledger Entries after post every production journal line.
        ConsumptionQty[4] := -Power(Quantity, 4);
        ConsumptionQty[3] := -Power(Quantity, 3);
        ConsumptionQty[2] := -Power(Quantity, 3);
        ConsumptionQty[1] := -Power(Quantity, 2);

        OutputQty[4] := Power(Quantity, 3);
        OutputQty[3] := Power(Quantity, 2);
        OutputQty[2] := Power(Quantity, 2);
        OutputQty[1] := Quantity;

        for i := 4 downto 1 do begin
            ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderLine.SetRange("Item No.", ItemNo[i]);
            ProdOrderLine.FindFirst();
            LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLine."Line No.");
            VerifyItemLedgerEntries(ItemNo[i], ConsumptionQty[i], OutputQty[i]);
        end;
    end;

    [Test]
    [HandlerFunctions('AssignOrEnterTrackingOnItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhsePickWithLotTrackingFromProductionOrder()
    begin
        Initialize();
        RegisterWhsePickWithTrackingFromProductionOrderByAddAndRemoveComponent(true); // Whse. Pick With Lot Tracking.
    end;

    [Test]
    [HandlerFunctions('AssignOrEnterTrackingOnItemTrackingPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhsePickWithSNTrackingFromProductionOrder()
    begin
        Initialize();
        RegisterWhsePickWithTrackingFromProductionOrderByAddAndRemoveComponent(false); // Whse. Pick With Serial Tracking.
    end;

    local procedure RegisterWhsePickWithTrackingFromProductionOrderByAddAndRemoveComponent(LotTracking: Boolean)
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ChildItem2: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        Bin2: Record Bin;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
        TrackingAction: Option AssignSerialNo,AssignLotNo,EnterValues;
    begin
        // Setup: Create parent and child Items with Lot Tracking in a Production BOM and certify it.
        CreateItemSetupWithLotTracking(ChildItem, ParentItem);

        // Create a new Production Order Component with Lot Tracking or Serial Tracking.
        if LotTracking then begin
            CreateItemWithItemTrackingCode(ChildItem2, CreateItemTrackingCode());
            TrackingAction := TrackingAction::AssignLotNo; // Setting tracking action on AssignOrEnterTrackingOnItemTrackingPageHandler for Item Journal Line.
            Quantity := LibraryRandom.RandInt(100);
        end else begin
            CreateItemWithItemTrackingCode(ChildItem2, CreateItemTrackingCodeForSerial());
            TrackingAction := TrackingAction::AssignSerialNo;// Setting tracking action on AssignOrEnterTrackingOnItemTrackingPageHandler for Item Journal Line.
            Quantity := 1; // The values of Quantity is important as the Quantity(Base) of Serial Tracking cannot more than 1.
        end;

        CreateLocationSetupWithBinsAndWhseEmployee(Location, true, true, true, true, true);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1); // Find Bin of Index 1.
        LibraryWarehouse.FindBin(Bin2, Location.Code, '', 2); // Find Bin of Index 2.

        // Post Item Journal with Location, Bin and Lot Tracking or Serial Tracking for the component.
        LibraryVariableStorage.Enqueue(TrackingAction); // Enqueue value for AssignOrEnterTrackingOnItemTrackingPageHandler.
        CreateAndPostItemJournalLine(ChildItem2."No.", Quantity, Bin.Code, Location.Code, true); // Using Tracking TRUE.

        // Create and refresh a Released Production order.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", Quantity, Location.Code, '');

        // Find Component. Add a new Component with Bin and Lot Tracking or Serial Tracking for the Production Order.
        AddProductionOrderComponentWithBin(ProdOrderComponent, ProductionOrder."No.", ChildItem2."No.", Location.Code, Bin2.Code);

        TrackingAction := TrackingAction::EnterValues;
        LibraryVariableStorage.Enqueue(TrackingAction); // Enqueue value for AssignOrEnterTrackingOnItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(Quantity); // Enqueue value for AssignOrEnterTrackingOnItemTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ChildItem2."No."); // Enqueue value for AssignOrEnterTrackingOnItemTrackingPageHandler.
        ProdOrderComponent.OpenItemTrackingLines();

        // Remove the original Component.
        RemoveProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");

        // Create Wharehouse Pick from the Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // Exercise and Verify: Register the Pick and verify no error pops up.
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler2')]
    [Scope('OnPrem')]
    procedure RegisterPickPartiallyWithSameLotNo()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        ChildItem: Record Item;
        Item2: Record Item;
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: array[3] of Decimal;
        SumQuantity: array[2] of Decimal;
        ActionType: Enum "Warehouse Action Type";
        i: Integer;
        PutAway: Boolean;
        Pick: Boolean;
    begin
        // Setup: Setup Location and Bin. Create Item With Item Tracking Code.
        Initialize();

        // Save them before updating for tearing down.
        LocationSilver.Get(LocationSilver.Code);
        PutAway := LocationSilver."Require Put-away";
        Pick := LocationSilver."Require Pick";

        UpdateLocation(LocationSilver, true, true, true, true, true);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1); // Find Bin of Index 1.
        LibraryWarehouse.FindBin(Bin2, LocationSilver.Code, '', 2); // Find Bin of Index 2.

        // Create three Items.
        CreateItemSetupWithLotTracking(ChildItem, Item);
        CreateItemWithItemTrackingCode(Item2, CreateItemTrackingCode());

        // Create Warehouse Journal Line and assign Tracking on it.
        Quantity[1] := LibraryRandom.RandIntInRange(100, 200);
        Quantity[2] := Quantity[1] - LibraryRandom.RandInt(40);
        Quantity[3] := LibraryRandom.RandInt(2);
        LibraryVariableStorage.Enqueue(Quantity[1]);
        CreateAndPostItemJournalLine(Item2."No.", Quantity[1], Bin.Code, LocationSilver.Code, true); // Using Tracking TRUE.

        // Create Released Production Order. Add component for the Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity[3], LocationSilver.Code, Bin.Code);
        CreateProdOrderComponent(ProductionOrder, Item2."No.", Quantity[1] / Quantity[3], LocationSilver.Code, Bin2.Code);

        // Create Warehouse Pick from the Released Production Order.
        CreatePickFromProductionOrder(ProductionOrder, Item."No.");

        // Exercise: Update Lot No. and Qty. To Handle on Warehouse Activity Line for partial registering.
        for ActionType := RegisteredWhseActivityLine."Action Type"::Take to RegisteredWhseActivityLine."Action Type"::Place do
            UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(Item2."No.", ProductionOrder."No.", ActionType, Quantity[2]);

        // Partial register pick.
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption",
          WarehouseActivityLine."Action Type"::Take);

        // Register the rest of pick.
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption",
          WarehouseActivityLine."Action Type"::Take);

        // Verify: Verify the Registered Warehouse Activity Lines and total quantity.
        for ActionType := RegisteredWhseActivityLine."Action Type"::Take to RegisteredWhseActivityLine."Action Type"::Place do
            for i := 1 to 2 do begin
                SumQuantity[i] :=
                  VerifyRegisteredWhseActivityLineAndCalcTotalQty(
                    RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", Item2."No.", ActionType);
                Assert.AreEqual(Quantity[1], SumQuantity[i], PickErr);
            end;

        // Tear Down.
        UpdateLocation(
          LocationSilver, PutAway, Pick, LocationSilver."Require Receive",
          LocationSilver."Require Shipment", LocationSilver."Bin Mandatory");
    end;

    [Test]
    [HandlerFunctions('CalculateStandardCostMenuHandler,AssignOrEnterTrackingOnItemTrackingPageHandler,ItemTrackingSummaryHandler,QuantityToCreatePageHandler,ConfirmHandler,AdjustCostItemEntriesHandler')]
    [Scope('OnPrem')]
    procedure CostAmountActualForOutputEntriesWithSerialNoTracking()
    var
        Item: Record Item;
        ChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        Quantity: Integer;
        TrackingAction: Option AssignSerialNo,AssignLotNo,EnterValues,SelectEntries;
    begin
        // [FEATURE] [Adjust Cost Item Entries] [Item Tracking]
        // [SCENARIO] Verify Cost Amount (Actual) in ILEs after: create and refresh Production Order, post Output Journal (with assigned Serial No.), then post Item Journal fpr Sale with Tracking, then finish Production Order and run Adjust Cost.

        Initialize();

        // [GIVEN] Create a Item with Production BOM and Routing.
        CreateItemWithProductionBOMAndRouting(Item, ChildItem, ProductionBOMHeader);

        // [GIVEN] Update Inventory for ChildItem by Item Journal
        Quantity := 17;  // 17 is very important for this case - also you can use other prime - make system to generate 17 item generate ledger entries and there is a rounding difference.
        CreateAndPostItemJournalLine(ChildItem."No.", Quantity, '', '', false);

        // [GIVEN] Create and Refresh Production Order, Post output journal
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, '', '');
        LibraryVariableStorage.Enqueue(TrackingAction::AssignSerialNo);  // Enqueue for AssignOrEnterTrackingOnItemTrackingPageHandler.
        CreateAndPostOutputJournalWithItemTracking(ProductionOrder."No.", true, ProductionOrder.Quantity);

        // [GIVEN] Post Item Journal for Sale
        LibraryVariableStorage.Enqueue(TrackingAction::SelectEntries);  // Enqueue for AssignOrEnterTrackingOnItemTrackingPageHandler.
        CreateAndPostItemJournalLineForSaleWithItemTracking(Item."No.", Quantity, LibraryRandom.RandInt(1000));

        // [GIVEN] Change Status to Finish
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [WHEN] Run Adjust Cost - Item Entries
        RunAdjustCostItemEntries(Item."No.");

        // [THEN] Cost Amount (Actual) in Item Ledger Entries are correct - the difference between maximum value and minimum must equal or less than 0.01
        VerifyItemLedgerEntriesForCostAmountActual(Item."No.");
    end;

#if not CLEAN26
    [Test]
    [Obsolete('Matrix per Version is removed', '26.0')]
    [HandlerFunctions('ProdBOMMatrixPerVersionHandler,ShowMatrixHandler')]
    [Scope('OnPrem')]
    procedure ShowMatrixWithMaxLengthOfDescription()
    var
        Item: Record Item;
        ProductionBOM: TestPage "Production BOM";
        ItemNo: Code[20];
    begin
        // Setup: Create parent and child Item, create Production BOM.
        Initialize();
        ItemNo := CreateItemsSetup(Item);
        LibraryVariableStorage.Enqueue(ItemNo); // Enqueue variable for ShowMatrixHandler.
        UpdateProductionBOMDescription(Item."Production BOM No."); // Required for test.

        // Exercise: Open Matrix per Version on Production BOM page.
        ProductionBOM.OpenEdit();
        ProductionBOM.FILTER.SetFilter("No.", Item."Production BOM No.");
        ProductionBOM."Ma&trix per Version".Invoke(); // To invoke ProdBOMMatrixPerVersionHandler.

        // Verify: Verify the Item No. through ShowMatrixHandler.
    end;
#endif

    [Test]
    [HandlerFunctions('WhereUsedHandler')]
    [Scope('OnPrem')]
    procedure WhereUsedWithMaxLengthOfDescription()
    var
        Item: Record Item;
        ProductionBOM: TestPage "Production BOM";
    begin
        // Setup: Create parent and child Item, create Production BOM.
        Initialize();
        CreateItemsSetup(Item);
        LibraryVariableStorage.Enqueue(Item."No."); // Enqueue variable for WhereUsedHandler.
        UpdateProductionBOMDescription(Item."Production BOM No."); // Required for test.

        // Exercise: Open Where-Used on Production BOM page.
        ProductionBOM.OpenEdit();
        ProductionBOM.FILTER.SetFilter("No.", Item."Production BOM No.");
        ProductionBOM."Where-used".Invoke(); // To invoke WhereUsedHandler.

        // Verify: Verify the Item No. through WhereUsedHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure FinishProdOrderBeforeInventoryPickPosted()
    var
        Item: Record Item;
        Location: Record Location;
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RoutingHeader: Record "Routing Header";
        ComponentsAtLocation: Code[10];
    begin
        // [FEATURE] [Production] [Warehouse]
        // [SCENARIO] Verify error on finishing Production Order having Inventory Pick for component.

        // [GIVEN] Create Location with "Require Pick"=TRUE. Update Components at a Location.
        Initialize();
        CreateLocationSetupWithBinsAndWhseEmployee(Location, false, true, false, false, false);
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(Location.Code);

        // [GIVEN] Parent and child Item, create Production BOM. Create Routing Setup and update Routing on Item.
        CreateItemsSetupWithRoutingAndBOM(Item, RoutingHeader, Location.Code, LibraryRandom.RandIntInRange(5, 10));

        // [GIVEN] Released Production order. Modify Routing Link Code of Components. Modify the Flushing Method as backward for routing line.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(5), Location.Code, '');

        UpdateRoutingLine(RoutingHeader, UpdateRoutingLinkOnProdOrderComponent(ProductionOrder."No."));
        UpdateProdOrderRoutingLine(
          ProdOrderRoutingLine, ProductionOrder."No.", ProdOrderRoutingLine."Flushing Method"::Backward);

        // [GIVEN] Create Inventory Pick from the Released Production Order.
        LibraryVariableStorage.Enqueue(PickActivitiesCreatedMsg); // Enqueue variable required inside MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [WHEN] Finish the Released Prod. Order.
        asserterror LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Verify the warning message through ConfirmHandlerForFinish.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(FinishOrderErr, ProductionOrder."No.")) > 0, ErrorWrongMsg);

        // Tear down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveFromCurrentLineTwiceOnSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Test to verify an error message pops up when clicking Reserve From Current Line
        // at the 2nd time when there is nothing availalbe to reserve.

        // Setup: Create Item. Add inventory for Item.
        Initialize();
        ItemJournalLine.DeleteAll();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandIntInRange(40, 50);
        Quantity2 := LibraryRandom.RandIntInRange(10, 20);
        UpdateInventoryUsingWhseJournal(LocationWhite, Item, Quantity);

        // Create 1st Sales Order. Create Pick from Sales Order.
        CreatePickFromSalesOrder(SalesHeader, Item."No.", Quantity2, LocationWhite.Code);

        // Create 2nd Sales Order. Create Pick from Sales Order. The Quantity should be greater than the available qty.
        // Reserve Item for 2nd Sales Order by clicking Reserve From Current Line in CancelReservationPageHandler.
        CreatePickFromSalesOrder(
          SalesHeader, Item."No.", Quantity - Quantity2 + LibraryRandom.RandInt(10), LocationWhite.Code);
        FindSalesLine(SalesLine, SalesHeader."No.", Item."No.");
        SalesLine.ShowReservation();

        // Exercise & Verify: Reserve the Item for 2nd Sales Order by clicking Reserve From Current Line again
        // in CancelReservationPageHandler. Verify the error message pops up when clicking
        // Reserve From Current Line at the 2nd time when there is nothing availalbe to reserve.
        // Clear Counter to click Reserve From Current Line again.
        Clear(Counter);
        asserterror SalesLine.ShowReservation();
        Assert.ExpectedError(NothingAvailableToReserveErr);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ChangeStartingDateInProdOrderRoutingLine()
    var
        SalesLine: Record "Sales Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderNo: Code[20];
    begin
        // Verify that error "date conflict with existing reservations" pops up when changing Starting Date in Prod. Order Routing line.

        // Setup: Create and refresh a Released production Order with Routing Line. Create Sales Order and reserve with Production Order
        Initialize();
        ProdOrderNo := ReserveSalesOrderWithProdOrder(SalesLine);

        // Exercise: Change Starting Date in Prod. Order Routing line
        // Verify: Verify the error pops up when changing leads to a date conflict with existing reservations.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo);
        asserterror ProdOrderRoutingLine.Validate("Starting Date", SalesLine."Shipment Date");
        Assert.ExpectedError(DateConflictWithExistingReservationsErr);
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ChangeSetupTimeInProdOrderRoutingLine()
    var
        SalesLine: Record "Sales Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderNo: Code[20];
    begin
        // Verify that error "date conflict with existing reservations" pops up when changing Setup Time in Prod. Order Routing line.

        // Setup: Create and refresh a Released production Order with Routing Line. Create Sales Order and reserve with Production Order
        Initialize();
        ProdOrderNo := ReserveSalesOrderWithProdOrder(SalesLine);

        // Exercise: Change Setup Time in Prod. Order Routing line
        // Verify: Verify the error pops up when changing leads to a date conflict with existing reservations.
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo);
        asserterror ProdOrderRoutingLine.Validate(
            "Setup Time", ProdOrderRoutingLine."Setup Time" * LibraryRandom.RandIntInRange(1000, 2000));
        Assert.ExpectedError(DateConflictWithExistingReservationsErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdOrderComponentForReleasedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        QtyPer: Integer;
    begin
        // Test to verify Quantity Per and Expected Quantity are correct on Prod. Order Component for Released Production Order.

        // Setup: Create parent and child Item, create Production BOM. Update UOM and Quantity Per on Production BOM.
        Initialize();
        QtyPer := LibraryRandom.RandIntInRange(80, 100);
        CreateItemsSetup(Item);
        UpdateItemProdBOMUOMAndQtyPer(Item, 2083, 2083 * QtyPer); // Values are important for reproducing the rounding issue.

        // Exercise: Create and refresh a Released Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), '', '');

        // Verify: Verify the Quantity Per and Expected Quantity on Production Order Component.
        // "Quantity Per" = 2083 * QtyPer(qty per in the production BOM) / 2083 (qty per of new Item uom) = QtyPer
        // "Expected Quantity" = QtyPer * ProductionOrder.Quantity
        VerifyQtyOnProdOrderComponent(ProductionOrder."No.", QtyPer, QtyPer * ProductionOrder.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningComponentForPlanningWorksheetLine()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ComponentItemNo: Code[20];
        QtyPer: Integer;
        SalesOrderQty: Integer;
    begin
        // Test to verify Quantity Per and Expected Quantity are correct on Planning Component for Planning Worksheet line.

        // Setup: Create parent with Planning Parameters and child Item, create Production BOM. Update UOM and Quantity Per on Production BOM.
        Initialize();
        QtyPer := LibraryRandom.RandIntInRange(80, 100);
        SalesOrderQty := LibraryRandom.RandInt(100);
        ComponentItemNo := UpdateItemPlanningParameters(Item);
        UpdateItemProdBOMUOMAndQtyPer(Item, 2083, 2083 * QtyPer); // Values are important for reproducing the rounding issue.

        // Create and release Sales Order.
        CreateAndReleaseSalesOrder(SalesHeader, Item."No.", SalesOrderQty, '');

        // Exercise: Calculate Regenerative Plan through Planning Worksheet on WORKDATE.
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // Verify: Verify the Quantity Per and Expected Quantity on Planning Component.
        // "Quantity Per" = 2083 * QtyPer(qty per in the production BOM) / 2083 (qty per of new Item uom) = QtyPer
        // "Expected Quantity" = QtyPer * SalesOrderQty(Qty of Sales Order)
        VerifyQtyOnPlanningComponent(ComponentItemNo, QtyPer, QtyPer * SalesOrderQty);
    end;

    [Test]
    [HandlerFunctions('CancelReservationPageHandler,PostProductionJournalHandler,ProdJnlPostConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckSelfReservedQty()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        Initialize();
        UpdateManufacturingSetupComponentsAtLocation(LocationGreen.Code);
        ItemNo := CreateItemsSetup(Item);
        Quantity := LibraryRandom.RandInt(100);

        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, LocationGreen.Code, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationGreen.Code, '');
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrder."No.");
        ProdOrderComponent.ShowReservation();

        // Verify that Production Journal is succesfully posted
        // Verify that there's no confirm negative adjustment warning in ProdJnlPostConfirmHandler confirm Handler
        LibraryVariableStorage.Enqueue(JournalLinesPostedMsg);
        OpenProductionJournal(ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ReservationHandler')]
    [Scope('OnPrem')]
    procedure ChangeBinCodeForPick()
    var
        Zone: Record Zone;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        WarehousePick: TestPage "Warehouse Pick";
        ItemNo: Code[20];
        WhseShipmentHeaderNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse] [Bin] [Reservation]
        // [SCENARIO 156554] Can change Bin code in Pick line, if Item is reserved and stock is available.

        // [GIVEN] Item on hand in two bins in Warehouse Location, each of Quantity "Q".
        Initialize();
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);

        ItemNo := LibraryInventory.CreateItemNo();
        Qty := LibraryRandom.RandDec(10, 2);

        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1); // Find first Bin
        AddWarehouseInventory(ItemNo, Qty, Bin);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 2); // Find second Bin
        AddWarehouseInventory(ItemNo, Qty, Bin);

        // [GIVEN] Create Sales Order of Quantity "Q", reserve.
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Qty, LocationWhite.Code);
        SalesLine.ShowReservation();

        // [GIVEN] Release Sales Order, create Warehouse Shipment, create Pick.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WhseShipmentHeaderNo :=
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
            DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WhseShipmentHeader.Get(WhseShipmentHeaderNo);
        LibraryWarehouse.CreateWhsePick(WhseShipmentHeader);
        // [GIVEN] Set "Qty. to Handle" to "Q".
        FindWarehouseActivityLine(
          WhseActivityLine, SalesHeader."No.", WhseActivityLine."Source Document"::"Sales Order", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.SetRange("Action Type");
        WhseActivityLine.ModifyAll("Qty. to Handle", Qty);
        // [WHEN] Try to change Bin Code.
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1);
        // Specific value
        FindWarehouseActivityHeader(
          WhseActivityHeader, SalesHeader."No.", WhseActivityLine."Source Document"::"Sales Order", WhseActivityLine."Action Type"::Take);
        Clear(WarehousePick);
        WarehousePick.OpenEdit();
        WarehousePick.GotoRecord(WhseActivityHeader);
        WarehousePick.WhseActivityLines."Bin Code".SetValue(Bin.Code);
        // [THEN] Bin code successfully changed.
        FindWarehouseActivityLine(
          WhseActivityLine, SalesHeader."No.", WhseActivityLine."Source Document"::"Sales Order", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedAndPickedComponentsConsideredInAvailableToPickCalculation()
    var
        ComponentItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        Zone: Record Zone;
        Bin: Record Bin;
        ProductionOrder: Record "Production Order";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        ProdOrderQty: array[2] of Decimal;
    begin
        // [FEATURE] [Warehouse] [Bin] [Production]
        // [SCENARIO 378145] Components reserved and picked for active production order should be considered when calculating quantity available to pick

        Initialize();

        // [GIVEN] Component item "CI"
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItem.Validate(Reserve, ComponentItem.Reserve::Always);
        ComponentItem.Modify(true);
        FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1);
        // [GIVEN] Location "L" with directed put-away and pick
        LibraryWarehouse.WarehouseJournalSetup(LocationWhite.Code, WarehouseJournalTemplate, WarehouseJournalBatch);

        // [GIVEN] Post positive adjustment of 100 pcs of item "CI" on location "L"
        ProdOrderQty[1] := LibraryRandom.RandIntInRange(50, 100);
        ProdOrderQty[2] := LibraryRandom.RandIntInRange(50, 100);
        AddWarehouseInventory(ComponentItem."No.", ProdOrderQty[1] + ProdOrderQty[2], Bin);

        // [GIVEN] Manufactured item "MI" with "CI" as a component
        CreateCertifiedProductionBOM(ProductionBOMHeader, ComponentItem, false);
        CreateProductionItem(ParentItem, ProductionBOMHeader."No.");

        // [GIVEN] Create production order "PO1" for 65 pcs of item "MI" and reserve component
        CreateProdOrderWithAutoreservedComponent(ProductionOrder, ParentItem."No.", ProdOrderQty[1], LocationWhite.Code);

        // [GIVEN] Create and register warehouse pick from production order "PO1"
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(
          ProductionOrder."No.", WhseActivityLine."Source Document"::"Prod. Consumption", WhseActivityLine."Action Type"::Take);

        // [GIVEN] Create production order "PO2" for 35 pcs of item "MI" and reserve component
        CreateProdOrderWithAutoreservedComponent(ProductionOrder, ParentItem."No.", ProdOrderQty[2], LocationWhite.Code);
        // [GIVEN] Create pick worksheet line from prod. order "PO2"
        CreatePickWorksheetLineFromProdOrder(WhseWorksheetLine, ProductionOrder.Status, ProductionOrder."No.", LocationWhite.Code);

        // [WHEN] Create warehouse pick from pick worksheet
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetLine."Worksheet Template Name", LocationWhite.Code,
          LocationWhite.Code, '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, true, false, false);

        // [THEN] Warehouse pick for 35 pcs of item "CI" successfully created
        VerifyWarehouseActivityLine(
          ProductionOrder."No.", WhseActivityLine."Source Document"::"Prod. Consumption",
          ComponentItem."No.", ProdOrderQty[2], WhseActivityLine."Action Type"::Take);
        VerifyWarehouseActivityLine(
          ProductionOrder."No.", WhseActivityLine."Source Document"::"Prod. Consumption",
          ComponentItem."No.", ProdOrderQty[2], WhseActivityLine."Action Type"::Place);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure QtyInMoveToBinShouldNotReduceQuantityAvailableToPick()
    var
        Item: Record Item;
        Location: Record Location;
        Zone: Record Zone;
        FromBin: Record Bin;
        ToBin: Record Bin;
        BinContent: Record "Bin Content";
        ReplenishQty: Decimal;
        LotNo: array[2] of Code[20];
    begin
        // [FEATURE] [Warehouse] [Bin] [Movement Worksheet] [FEFO]
        // [SCENARIO 308293] When creating a warehouse movement from movement worksheet, quantity available on bin being replenished should not be included in total available to pick

        Initialize();

        // [GIVEN] Item with lot no. tracking
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode());
        // [GIVEN] WMS location with FEFO pick
        CreateFEFOLocation(Location);

        // [GIVEN] Pick bin "B1" with "Minimum Qty."
        // [GIVEN] Pick bin "B2" without quantity setup
        ReplenishQty := LibraryRandom.RandIntInRange(50, 100);
        FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true));
        LibraryWarehouse.FindBin(ToBin, Location.Code, Zone.Code, 1);
        LibraryWarehouse.FindBin(FromBin, Location.Code, Zone.Code, 2);
        ToBin.Validate("Bin Ranking", FromBin."Bin Ranking" + 1);
        ToBin.Modify(true);
        CreateBinContent(BinContent, ToBin, Item, ReplenishQty, ReplenishQty * 3, ToBin."Bin Ranking");

        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);

        // [GIVEN] Post postive adjustment on "B2", expiration date = WorkDate(), quantity = "X", lot no. = "L1"
        PostWhsePositiveAdjmtWithLotExpirationDate(Location.Code, FromBin, Item."No.", ReplenishQty, LotNo[1], WorkDate());
        // [GIVEN] Post postive adjustment on "B2", expiration date = WorkDate() + 1, quantity = "X", lot no. = "L2"
        PostWhsePositiveAdjmtWithLotExpirationDate(Location.Code, FromBin, Item."No.", ReplenishQty, LotNo[2], WorkDate() + 1);
        // [GIVEN] Post postive adjustment on "B1", quantity is below minimum quantity for this bin
        PostWhsePositiveAdjmtWithLotExpirationDate(Location.Code, ToBin, Item."No.", ReplenishQty / 2, LotNo[1], WorkDate());

        CalculateAndPostWarehouseAdjustment(Item."No.");

        // [WHEN] Calculate and carry out replenishment for bin "B1"
        CalculateBinReplenishment(BinContent);

        // [THEN] Warehouse movement with 2 activities created. First line: quantity = "X", lot no. = "L1", second line: quantity = "X", lot no. = "L2"
        VerifyWarehouseActivityLineLot(Location.Code, Item."No.", LotNo[1], ReplenishQty);
        VerifyWarehouseActivityLineLot(Location.Code, Item."No.", LotNo[2], ReplenishQty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,WhseItemTrackingPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcConsumptionBatchJobDoesNotCreateItemTrackingOnZeroLine()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        Qty: Decimal;
    begin
        // [FEATURE] [Consumption] [Warehouse Pick] [Item Tracking]
        // [SCENARIO 361179] Calc. consumption batch job does not assign item tracking to zero lines.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked manufacturing item "PROD" and component "COMP".
        // [GIVEN] Post 10 pcs of item "COMP" to inventory.
        CreateItemSetupWithLotTracking(CompItem, ProdItem);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, CompItem, ProdItem, Qty);

        // [GIVEN] Production order for 20 pcs of item "PROD".
        // [GIVEN] Create and register warehouse pick for component "COMP".
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProdItem."No.", 2 * Qty, LocationWhite.Code, '');
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
          CompItem."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Place, Qty);
        UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
          CompItem."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Qty);
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // [GIVEN] Calculate and post consumption of picked quantity (10 pcs) in Consumption Journal.
        CreateAndPostConsumptionJournalWithItemTracking(ProductionOrder."No.", true);

        // [WHEN] Calculate consumption for not yet picked 10 pcs in Consumption Journal.
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrder."No.", ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);

        // [THEN] Zero consumption line with no item tracking has been created.
        ItemJournalLine.SetRange("Entry Type", ItemJournalLine."Entry Type"::Consumption);
        ItemJournalLine.SetRange("Item No.", CompItem."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, 0);

        ReservationEntry.SetRange("Source Batch Name", ConsumptionItemJournalBatch.Name);
        ReservationEntry.SetRange("Item No.", CompItem."No.");
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure NoInconsistencyErrorWhenPostPartialPickforProductionOrder()
    var
        Item: Record Item;
        CompItem: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ComponentsAtLocation: Code[10];
        PurchaseQuantity: Integer;
        Quantity: Integer;
    begin
        // [SCENARIO 542272] Stan Post the Warehouse Pick partial and than complete the warehouse pick without any failure
        Initialize();

        // [GIVEN] Set Location to WHITE
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);

        // [GIVEN] Set quantity and PurchaseQuantity
        PurchaseQuantity := LibraryRandom.RandInt(100);
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Create component items and produce item
        CreateItemSetupWithSameLotTracking(Item, CompItem);

        // [GIVEN] Update Inventory and assign tracking in whse item journal
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, CompItem[1], CompItem[2], PurchaseQuantity);

        // [GIVEN] Create and refresh Production Order
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", Quantity, LocationWhite.Code, LocationWhite."To-Production Bin Code");

        // [GIVEN] Create Warehouse pick
        CreateWarehousePickfromProductionOrderSetup(CompItem, ProductionOrder, Quantity / 2);

        // [GIVEN] Register the Warehouse pick with partial quantity
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // [GIVEN] Delete the Warehouse Pick
        DeleteOldWareHousePickandCreateNew(ProductionOrder);

        // [GIVEN] Again create the Warehouse Pick
        CreateWarehousePickfromProductionOrderSetup(CompItem, ProductionOrder, Quantity / 2);

        // [WHEN] Register the Warehouse Pick with rest of the quantity
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Take);

        // [THEN] Verify the Registered Whse Activity Lines created with correct details
        VerifyRegisteredWhseActivityLines(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", CompItem[1]."No.", Quantity / 2,
          RegisteredWhseActivityLine."Action Type"::Take);
        VerifyRegisteredWhseActivityLines(
          RegisteredWhseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.", CompItem[1]."No.", Quantity / 2,
          RegisteredWhseActivityLine."Action Type"::Place);

        // Tear Down.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    procedure RegisterWarehousePickUsingSplitLines()
    var
        Bin: Record Bin;
        BinType: Record "Bin Type";
        Item: array[2] of Record Item;
        ItemUnitOfMeasure: array[3] of Record "Item Unit of Measure";
        ProductionOrder: Record "Production Order";
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        BinCode: Code[20];
        Quantity: Decimal;
    begin
        // [SCENARIO 540303] Registering the pick using Split Lines in Warehouse Pick.
        Initialize();

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, false);

        // [GIVEN] Update Manufacturing Setup Components in Location.
        UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);

        // [GIVEN] Validate Put-away Worksheet and Prod. Output Whse. Handling in Location.
        LocationWhite.Validate("Use Put-away Worksheet", true);
        LocationWhite.Validate("Prod. Output Whse. Handling", LocationWhite."Prod. Output Whse. Handling"::"Warehouse Put-away");
        LocationWhite.Modify();

        // [GIVEN] Create a Zone.
        LibraryWarehouse.CreateZone(Zone, Zone.Code, LocationWhite.Code, '', '', '', 0, false);

        // [GIVEN] Find Bin Type of Pick.
        BinType.SetRange(Pick, true);
        BinType.FindFirst();

        // [GIVEN] Create Bin in a Location.
        LibraryWarehouse.CreateBin(Bin, LocationWhite.Code, Bin.Code, Zone.Code, BinType.Code);

        // [GIVEN] Store Quantity.
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Create an Item with setup.
        CreateItemSetupWithLotTracking(Item[1], Item[2]);

        // [GIVEN] Create Item Unit of Measure.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[1], Item[1]."No.", LibraryRandom.RandIntInRange(1, 1));
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[2], Item[1]."No.", LibraryRandom.RandIntInRange(100, 110));
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[3], Item[1]."No.", LibraryRandom.RandIntInRange(1000, 1010));

        // [GIVEN] Create Inventory and Register in Warehouse Item Journal.
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, Item[1], Item[2], Quantity);

        // [GIVEN] Create Warehouse Pick from Production Order.
        CreateWarehousePickfromProductionOrderSetup(Item[1], Item[2], ProductionOrder, Quantity);

        // [GIVEN] Find Warehouse Activity Line and store Bin Code.
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        WarehouseActivityLine.FindFirst();
        BinCode := WarehouseActivityLine."Bin Code";

        // [GIVEN] Validate Qty. to Handle in Warehouse Activity Line.
        WarehouseActivityLine.Validate("Qty. to Handle", Quantity - LibraryRandom.RandInt(2));
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Use Split Line in Warehouse Activity Line.
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);

        // [GIVEN] Find latest Warehouse Activity Line which has been split and Validate Bin Code.
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Item No.", Item[1]."No.");
        WarehouseActivityLine.FindLast();
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify();

        // [GIVEN] Find Warehouse Activity Header.
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.SetRange("Location Code", LocationWhite.Code);
        WarehouseActivityHeader.FindFirst();

        // [WHEN] Register Warehouse Activity.
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Posted Warehouse Activity Header is created.
        RegisteredWhseActivityHdr.SetRange("Whse. Activity No.", WarehouseActivityHeader."No.");
        RegisteredWhseActivityHdr.FindFirst();
        Assert.RecordIsNotEmpty(RegisteredWhseActivityHdr);
    end;

    [Test]
    [HandlerFunctions('CreatePickReportHandler,DummyMessageHandler,InvPostingSelectionHandler,GetActionMessageReportHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingAndItemTrackingShouldNotCreateWrongReservation()
    var
        Bin: array[2] of Record Bin;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Quantity: array[10] of Decimal;
        LotNo: array[2] of Code[20];
    begin
        // [SCENARIO 555810] Order Tracking and Item Tracking should not create bad Reservation Entry.
        Initialize();

        // [GIVEN] Create a Lot Tracked Item with "Order Tracking Policy" = "Tracking & Action Msg."
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);

        // [GIVEN] Create a Location and two Bins for the Location.
        CreateAndUpdateLocation(Location, false, true, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');

        // [GIVEN] Set Quantity and LotNo.
        Quantity[1] := 11;
        Quantity[2] := 4;

        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Create and post two Item Journal with different LotNo and Bin.
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        ItemJournalBatch.Modify(true);
        CreateAndPostItemJournalLineWithLot(Item."No.", Quantity[1], bin[1].Code, Location.Code, LotNo[1]);
        CreateAndPostItemJournalLineWithLot(Item."No.", Quantity[2], bin[2].Code, Location.Code, LotNo[2]);

        // [GIVEN] Create and release a Sales Order with Quantity = Quantity[1] + Quantity[2] = 15.
        CreateSalesOrder(SalesHeader[1], SalesLine[1], Item."No.", Quantity[1] + Quantity[2], Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [WHEN] Create and release another Sales Order with Quantity = 8.
        CreateSalesOrder(SalesHeader[2], SalesLine[2], Item."No.", 8, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);

        // [THEN] Verify second Sales Order has one Surplus Reservation Entry because of insufficient inventory.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[2]."No.", ReservationEntry."Reservation Status"::Surplus, -SalesLine[2]."Quantity (Base)");

        // [GIVEN] Create Inventory Pick from second Sales Order.
        Commit();
        SalesHeader[2].CreateInvtPutAwayPick();

        // [GIVEN] Split the Inventory Pick Line and assign LotNo[1] for both lines but maintain the different "Bin Code"
        // i.e. first line will have "Bin Code" = Bin[1].Code and second line will have "Bin Code" = Bin[2].Code
        SplitInventoryPickAndUpdateLotAndBin(SalesHeader[2]."No.", LotNo, Bin, true);

        // [WHEN] Posting the Inventory Pick.
        asserterror PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[2]);

        // [THEN] During the post the untracked surplus Reservation Entry will get delete and new Lot tracked Reservation with same "Quantity" will be created.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[2]."No.", ReservationEntry."Reservation Status"::Surplus, -SalesLine[2]."Quantity (Base)");

        // [WHEN] Posting the Inventory Pick after correcting the "Lot No." in Pick Line.
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[2]."No.", Bin[1].Code, LotNo[1]);
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[2]."No.", Bin[2].Code, LotNo[2]);
        PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[2]);

        // [THEN] There should be Surplus Reservation Entry of "Quantity (Base)" = -8 for first Sales Order as second sales order use 8 inventory out of 15.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[1]."No.", ReservationEntry."Reservation Status"::Surplus, -8);

        // [GIVEN] Modify the Quantity in first Sales Order to 7 and create the Inventory Pick.
        SalesLine[1].Validate(Quantity, 7);
        SalesLine[1].Modify(true);
        Commit();
        SalesHeader[1].CreateInvtPutAwayPick();

        // [GIVEN] Assign the correct "Lot No." to Inventory Pick Lines.
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", Bin[1].Code, LotNo[1]);
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", Bin[2].Code, LotNo[2]);

        // [WHEN] Post the Inventory Pick.
        PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[1]);

        // [THEN] Verify that there should not be any Action Message Entries for both Sales Orders.
        // And Planning Worksheet should not generate any entry on doing "Get Action Message".
        assert.IsFalse(ActionMessageExist(Item."No.", SalesHeader[1]."No."), StrSubstNo(ActionMessageEntryExistErr, Item."No."));
        assert.IsFalse(ActionMessageExist(Item."No.", SalesHeader[2]."No."), StrSubstNo(ActionMessageEntryExistErr, Item."No."));
        asserterror ExecuteGetActionMessageFromPlanningWorksheet(Item."No.");
    end;

    [Test]
    [HandlerFunctions('CreatePickReportHandler,DummyMessageHandler,InvPostingSelectionHandler,GetActionMessageReportHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingAndItemTrackingShouldNotCreateWrongReservation_V2()
    var
        Bin: array[2] of Record Bin;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Quantity: array[10] of Decimal;
        LotNo: array[2] of Code[20];
    begin
        // [SCENARIO 555810] Order Tracking and Item Tracking should not create bad Reservation Entry. 
        // Same as previous test except create a new Sales Line in first Sales Order instead of modifying its quantity to 7.
        Initialize();

        // [GIVEN] Create a Lot Tracked Item with "Order Tracking Policy" = "Tracking & Action Msg."
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);

        // [GIVEN] Create a Location and two Bins for the Location.
        CreateAndUpdateLocation(Location, false, true, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');

        // [GIVEN] Set quantity and LotNo.
        Quantity[1] := 11;
        Quantity[2] := 4;

        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Create and post two Item Journal with different LotNo and Bin.
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        ItemJournalBatch.Modify(true);
        CreateAndPostItemJournalLineWithLot(Item."No.", Quantity[1], bin[1].Code, Location.Code, LotNo[1]);
        CreateAndPostItemJournalLineWithLot(Item."No.", Quantity[2], bin[2].Code, Location.Code, LotNo[2]);

        // [GIVEN] Create a Sales Order with Quantity = Quantity[1] + Quantity[2] = 15.
        CreateSalesOrder(SalesHeader[1], SalesLine[1], Item."No.", Quantity[1] + Quantity[2], Location.Code);

        // [WHEN] Create and release another Sales Order with Quantity = 8.
        CreateSalesOrder(SalesHeader[2], SalesLine[2], Item."No.", 8, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);

        // [THEN] Verify SalesHeader[2] has one Surplus Reservation Entry because of insufficient inventory.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[2]."No.", ReservationEntry."Reservation Status"::Surplus, -SalesLine[2]."Quantity (Base)");

        // [GIVEN] Create Inventory Pick from the second Sales Order.
        Commit();
        SalesHeader[2].CreateInvtPutAwayPick();

        // [GIVEN] Split the Inventory Pick Line and assign LotNo[1] for both lines but maintain the different "Bin Code".
        SplitInventoryPickAndUpdateLotAndBin(SalesHeader[2]."No.", LotNo, Bin, true);

        // [WHEN] Posting the Inventory Pick
        asserterror PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[2]);

        // [THEN] During the post the untracked surplus Reservation Entry will get deleted and new Lot tracked Reservation with same "Quantity" will be created.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[2]."No.", ReservationEntry."Reservation Status"::Surplus, -SalesLine[2]."Quantity (Base)");

        // [WHEN] Posting the Inventory Pick after correcting the "Lot No." in Pick Lines.
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[2]."No.", Bin[1].Code, LotNo[1]);
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[2]."No.", Bin[2].Code, LotNo[2]);
        PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[2]);

        // [THEN] There should be Surplus Reservation Entry of "Quantity (Base)" = -8 for first Sales Order.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[1]."No.", ReservationEntry."Reservation Status"::Surplus, -8);

        // [GIVEN] Create new Sales Line with Quantity = 7 in first Sales Order and delete the first Sales Line.
        SalesLine[3] := SalesLine[1];
        SalesLine[3]."Line No." := SalesLine[1]."Line No." + 10000;
        SalesLine[3].Validate(Quantity, 7);
        SalesLine[3].Insert(true);
        SalesLine[1].Delete(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);
        Commit();

        // [GIVEN] Create Inventory Pick for the first Sales Order.
        SalesHeader[1].CreateInvtPutAwayPick();

        // [GIVEN] Assign the correct "Lot No." to Inventory Pick Lines.
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", Bin[1].Code, LotNo[1]);
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", Bin[2].Code, LotNo[2]);

        // [WHEN] Posting the Inventory Pick.
        PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[1]);

        // [THEN] Verify that there should not be any Action Message Entries for both Sales Orders.
        // And Planning Worksheet should not generate any entry on doing "Get Action Message".
        assert.IsFalse(ActionMessageExist(Item."No.", SalesHeader[1]."No."), StrSubstNo(ActionMessageEntryExistErr, Item."No."));
        assert.IsFalse(ActionMessageExist(Item."No.", SalesHeader[2]."No."), StrSubstNo(ActionMessageEntryExistErr, Item."No."));
        asserterror ExecuteGetActionMessageFromPlanningWorksheet(Item."No.");
    end;

    [Test]
    [HandlerFunctions('CreatePickReportHandler,DummyMessageHandler,InvPostingSelectionHandler,GetActionMessageReportHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingAndItemTrackingShouldNotCreateWrongReservation_V3()
    var
        Bin: array[2] of Record Bin;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[3] of Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Quantity: array[10] of Decimal;
        LotNo: array[2] of Code[20];
    begin
        // [SCENARIO 555810] Order Tracking and Item Tracking should not create bad Reservation Entry.
        // Same as previous test but this test does not produce any error on posting the Inventory Pick of second Sales Order. 
        Initialize();

        // [GIVEN] Create a Lot Tracked Item with "Order Tracking Policy" = "Tracking & Action Msg."
        LibraryItemTracking.CreateLotItem(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);

        // [GIVEN] Create a Location and two Bins for the Location.
        CreateAndUpdateLocation(Location, false, true, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');

        // [GIVEN] Set quantity and LotNo.
        Quantity[1] := 11;
        Quantity[2] := 4;

        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Create and post two Item Journal with different LotNo and Bin.
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        ItemJournalBatch.Modify(true);
        CreateAndPostItemJournalLineWithLot(Item."No.", Quantity[1], bin[1].Code, Location.Code, LotNo[1]);
        CreateAndPostItemJournalLineWithLot(Item."No.", Quantity[2], bin[2].Code, Location.Code, LotNo[2]);

        // [GIVEN] Create the first Sales Order with Quantity = 15.
        CreateSalesOrder(SalesHeader[1], SalesLine[1], Item."No.", Quantity[1] + Quantity[2], Location.Code);

        // [WHEN] Create and release another Sales Order with Quantity = 8.
        CreateSalesOrder(SalesHeader[2], SalesLine[2], Item."No.", 8, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);

        // [THEN] Verify SalesHeader[2] has one Surplus Reservation Entry because of insufficient inventory.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[2]."No.", ReservationEntry."Reservation Status"::Surplus, -SalesLine[2]."Quantity (Base)");

        // [GIVEN] Create Inventory Pick from second Sales Order.
        Commit();
        SalesHeader[2].CreateInvtPutAwayPick();

        // [GIVEN] Split the Inventory Pick Line and assign correct "Lot No." and "Bin Code" (Do not produce error on posting)
        SplitInventoryPickAndUpdateLotAndBin(SalesHeader[2]."No.", LotNo, Bin, false);

        // [WHEN] Posting the Inventory Pick.
        PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[2]);

        // [THEN] There should be Surplus Reservation Entry of "Quantity (Base)" = -8 for first Sales Order.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[1]."No.", ReservationEntry."Reservation Status"::Surplus, -8);

        // [GIVEN] Create new line with Quantity = 7 in first Sales Order and delete the existing line.
        SalesLine[3] := SalesLine[1];
        SalesLine[3]."Line No." := SalesLine[1]."Line No." + 10000;
        SalesLine[3].Validate(Quantity, 7);
        SalesLine[3].Insert(true);
        SalesLine[1].Delete(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);
        Commit();

        // [GIVEN] Create the inventory Pick for first Sales Order.
        SalesHeader[1].CreateInvtPutAwayPick();

        // [GIVEN] Assign the correct "Lot No." to Inventory Pick lines.
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", Bin[1].Code, LotNo[1]);
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", Bin[2].Code, LotNo[2]);

        // [WHEN] Post the Inventory Pick.
        PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[1]);

        // [THEN] Verify that there should not be any Action Message Entries for both Sales Orders.
        // And Planning Worksheet should not generate any entry on doing "Get Action Message".
        assert.IsFalse(ActionMessageExist(Item."No.", SalesHeader[1]."No."), StrSubstNo(ActionMessageEntryExistErr, Item."No."));
        assert.IsFalse(ActionMessageExist(Item."No.", SalesHeader[2]."No."), StrSubstNo(ActionMessageEntryExistErr, Item."No."));
        asserterror ExecuteGetActionMessageFromPlanningWorksheet(Item."No.");
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingPageHandler')]
    procedure NewLineOnProductionOrderComponentWhenWarehouseActivityLineExists()
    var
        Item: Record Item;
        CompItem: array[2] of Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: array[2] of Record "Prod. Order Component";
        ComponentsAtLocation: Code[10];
        PurchaseQuantity: Integer;
        Quantity: Integer;
    begin
        // [SCENARIO 557039] No error of Line No. must not be changed when a Warehouse Activity Line for this Prod. Order Component exists.
        Initialize();

        // [GIVEN] Set Location to WHITE.
        ComponentsAtLocation := UpdateManufacturingSetupComponentsAtLocation(LocationWhite.Code);

        // [GIVEN] Set quantity and PurchaseQuantity.
        PurchaseQuantity := LibraryRandom.RandInt(100);
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Create Component items and Produce item.
        CreateItemSetupWithSameLotTracking(Item, CompItem);

        // [GIVEN] Update Inventory and assign Tracking in Warehouse Item Journal.
        UpdateInventoryAndAssignTrackingInWhseItemJournal(LocationWhite, CompItem[1], CompItem[2], PurchaseQuantity);

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProdOrder(
            ProductionOrder,
            ProductionOrder.Status::Released,
            Item."No.",
            Quantity,
            LocationWhite.Code,
            LocationWhite."To-Production Bin Code");

        // [GIVEN] Create Warehouse Pick from Production Order.
        CreateWarehousePickfromProductionOrderSetup(CompItem, ProductionOrder, Quantity / 2);

        // [GIVEN] Find the last Production Order Component.
        ProdOrderComponent[1].SetRange(Status, ProdOrderComponent[1].Status::Released);
        ProdOrderComponent[1].SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent[1].FindLast();

        // [WHEN] Insert new line in Production Order Component.
        ProdOrderComponent[2].Init();
        ProdOrderComponent[2].Validate(Status, ProdOrderComponent[2].Status::Released);
        ProdOrderComponent[2].Validate("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent[2].Validate("Prod. Order Line No.", ProdOrderComponent[1]."Prod. Order Line No.");
        ProdOrderComponent[2].Validate("Line No.", ProdOrderComponent[1]."Line No." + LibraryRandom.RandInt(10000));
        ProdOrderComponent[2].Validate(ProdOrderComponent[2]."Item No.", Item."No.");
        ProdOrderComponent[2].Insert(true);

        // [THEN] New Production Order Component should be available.
        Assert.RecordIsNotEmpty(ProdOrderComponent[2]);

        // [THEN] Clear Manufacturing Setup Components At Location.
        UpdateManufacturingSetupComponentsAtLocation(ComponentsAtLocation);
    end;

    [Test]
    [HandlerFunctions('CreatePickReportHandler,DummyMessageHandler,InvPostingSelectionHandler,GetActionMessageReportHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingAndLotSpecificItemTrackingShouldNotDamageReservation()
    var
        Bin: array[2] of Record Bin;
        Item: Record Item;
        Location: Record Location;
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEmployee: Record "Warehouse Employee";
        Quantity: array[10] of Decimal;
        LotNo: array[2] of Code[20];
    begin
        // [SCENARIO 573919] Using Order Tracking Policy of Tracking & Action Message and Lot Specific Tracking can result in damaged Reservation Entries with Inventory Pick process - Follow up from Bug 555810
        Initialize();

        // [GIVEN] Create a Lot Tracked Item with "Order Tracking Policy" = "Tracking & Action Msg."
        CreateItemWithLotWarehouseTracking(Item);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);

        // [GIVEN] Create a Location with Require Receive = Yes, Require Pick = Yes along with Bin Mandatory = Yes and two Bins for the Location.
        CreateAndUpdateLocation(Location, false, true, true, false, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, Bin[1].Code, '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, Bin[2].Code, '', '');

        // [GIVEN] Set Quantity and LotNo.
        Quantity[1] := LibraryRandom.RandIntInRange(11, 11);
        Quantity[2] := LibraryRandom.RandIntInRange(4, 4);
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] Create and post two Item Journal with different LotNo and Bin where Item Tracking on Lines is enabled for the Batch
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        ItemJournalBatch.Modify(true);
        CreateAndPostItemJournalLineWithLot(Item."No.", Quantity[1], bin[1].Code, Location.Code, LotNo[1]);
        CreateAndPostItemJournalLineWithLot(Item."No.", Quantity[2], bin[2].Code, Location.Code, LotNo[2]);

        // [GIVEN] Create and release a Sales Order with Quantity = Quantity[1] + Quantity[2] = 15.
        CreateSalesOrder(SalesHeader[1], SalesLine[1], Item."No.", Quantity[1] + Quantity[2], Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [WHEN] Create and release another Sales Order with Quantity = 8.
        CreateSalesOrder(SalesHeader[2], SalesLine[2], Item."No.", 8, Location.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);

        // [THEN] Verify second Sales Order has one Surplus Reservation Entry because of insufficient inventory.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[2]."No.", ReservationEntry."Reservation Status"::Surplus, -SalesLine[2]."Quantity (Base)");

        // [GIVEN] Create Inventory Pick from second Sales Order.
        Commit();
        SalesHeader[2].CreateInvtPutAwayPick();

        // [GIVEN] Split the Inventory Pick Line and assign LotNo[1] for both lines but maintain the different "Bin Code"
        // i.e. first line will have "Bin Code" = Bin[1].Code and second line will have "Bin Code" = Bin[2].Code
        SplitInventoryPickAndUpdateLotAndBin(SalesHeader[2]."No.", LotNo, Bin, true);

        // [WHEN] Posting the Inventory Pick.
        asserterror PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[2]);

        // [THEN] During the post the untracked surplus Reservation Entry will get delete and new Lot tracked Reservation with same "Quantity" will be created.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[2]."No.", ReservationEntry."Reservation Status"::Surplus, -SalesLine[2]."Quantity (Base)");

        // [WHEN] Posting the Inventory Pick after correcting the "Lot No." in Pick Line.
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[2]."No.", Bin[1].Code, LotNo[1]);
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[2]."No.", Bin[2].Code, LotNo[2]);
        PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[2]);

        // [THEN] There should be Surplus Reservation Entry of "Quantity (Base)" = -8 for first Sales Order as second sales order use 8 inventory out of 15.
        VerifyReservationIsCorrect(Database::"Sales Line", SalesHeader[1]."No.", ReservationEntry."Reservation Status"::Surplus, -8);

        // [GIVEN] Modify the Quantity in first Sales Order to 7 and create the Inventory Pick.
        SalesLine[1].Validate(Quantity, 7);
        SalesLine[1].Modify(true);
        Commit();
        SalesHeader[1].CreateInvtPutAwayPick();

        // [GIVEN] Assign the correct "Lot No." to Inventory Pick Lines.
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", Bin[1].Code, LotNo[1]);
        UpdateWhseLotNoUsingSourceAndBin(WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader[1]."No.", Bin[2].Code, LotNo[2]);

        // [WHEN] Post the Inventory Pick.
        PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader[1]);

        // [THEN] Verify that there should not be any Action Message Entries for both Sales Orders.
        // And Planning Worksheet should not generate any entry on doing "Get Action Message".
        assert.IsFalse(ActionMessageExist(Item."No.", SalesHeader[1]."No."), StrSubstNo(ActionMessageEntryExistErr, Item."No."));
        assert.IsFalse(ActionMessageExist(Item."No.", SalesHeader[2]."No."), StrSubstNo(ActionMessageEntryExistErr, Item."No."));
        asserterror ExecuteGetActionMessageFromPlanningWorksheet(Item."No.");

        // [THEN] Verify that there is no surplus reservation entry in the system for any Sales Orders
        VerifyThereIsNoDamagedReservationEntryForSurplus(Database::"Sales Line", SalesHeader[1]."No.", ReservationEntry."Reservation Status"::Surplus);
        VerifyThereIsNoDamagedReservationEntryForSurplus(Database::"Sales Line", SalesHeader[2]."No.", ReservationEntry."Reservation Status"::Surplus);//, -SalesLine[2]."Quantity (Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehousePickUpdateQuantityInOrder()
    var
        Bin: array[8] of Record Bin;
        CompItem, ProdItem : Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProductionBOMHeader: Record "Production BOM Header";
        WarehouseEmployee: Record "Warehouse Employee";
        Quantity: Decimal;
        UpdatedQuantity: Decimal;
    begin
        // [SCENARIO 581104] Manually change quantity of "Take Line" in Warehouse Pick changes the quantity of the correct "Place Lines"
        Initialize();

        // [GIVEN] Set Quantity and UpdatedQuantity.
        Quantity := LibraryRandom.RandIntInRange(900, 1000);
        UpdatedQuantity := LibraryRandom.RandIntInRange(400, 500);

        // [GIVEN] Reset Warehouse Employee Default Location.
        ResetWarehouseEmployeeDefaultLocation();

        // [GIVEN] Create Location with WMS enabled Bin mandatory
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);

        // [GIVEN] Create Warehouse Employee for Location.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);

        // [GIVEN] Create Bins for Location.
        CreateBin(Bin, Location.Code);

        // [GIVEN] Set "Prod. Consump. Whse. Handling" = "Warehouse Pick (mandatory)" and assign Bins to "To-Production Bin Code" and "From-Production Bin Code".
        Location.Validate("Prod. Consump. Whse. Handling", Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)");
        Location.Validate("To-Production Bin Code", Bin[1].Code);
        Location.Validate("From-Production Bin Code", Bin[2].Code);
        Location.Validate("Open Shop Floor Bin Code", Bin[3].Code);
        Location.Modify(true);

        // [GIVEN] Create Component Item with "Replenishment System" = "Purchase" and "Flushing Method" = "Manual".
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::Purchase);
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::"Pick + Manual");
        CompItem.Validate("Allow Whse. Overpick", true);
        CompItem.Modify();

        // [GIVEN] Create Production BOM for Component Item.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Stock");
        ProdItem.Validate("Flushing Method", ProdItem."Flushing Method"::Manual);
        ProdItem.Validate("Production BOM No.", LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, CompItem."No.", 1));
        ProdItem.Modify();

        // [GIVEN] Create Inventory for Component Item for five different Bins.
        CreateInventoryWithBin(CompItem, Quantity, Location.Code, Bin[4].Code, 0);
        CreateInventoryWithBin(CompItem, Quantity, Location.Code, Bin[5].Code, 0);
        CreateInventoryWithBin(CompItem, Quantity, Location.Code, Bin[6].Code, 0);
        CreateInventoryWithBin(CompItem, Quantity, Location.Code, Bin[7].Code, 0);
        CreateInventoryWithBin(CompItem, Quantity, Location.Code, Bin[8].Code, 0);

        // [GIVEN] Create Production Orders for Production Item of quantity Quantity * 5.
        LibraryManufacturing.CreateProductionOrder(
           ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", Quantity * 5);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Create Warehouse Pick from Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [WHEN] Update quantity in Warehouse Pick Lines.
        UpdateQuantityWarehousePickFromPage(ProductionOrder."No.", Location.Code, UpdatedQuantity);

        // [THEN] Verify that the Warehouse Activity Lines are updated correctly.
        VerifyWareHouseActivityLinesForQuantity(ProductionOrder."No.", Location, Quantity, UpdatedQuantity);
    end;

    local procedure Initialize()
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Reservation II");
        Clear(Counter);
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Reservation II");

        AllProfile.SetRange("Profile ID", 'ORDER PROCESSOR');
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup();
        OutputJournalSetup();
        ConsumptionJournalSetup();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveInventorySetup();
        LibrarySetupStorage.SaveManufacturingSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Reservation II");
    end;

    local procedure CalculateAndPostWarehouseAdjustment(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        Item.SetRange("No.", ItemNo);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');  // Value required to avoid the Document No mismatch.
    end;

    local procedure CalculateBinReplenishment(BinContent: Record "Bin Content")
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, BinContent."Location Code");
        LibraryWarehouse.CalculateBinReplenishment(BinContent, WhseWorksheetName, BinContent."Location Code", false, true, false);
        LibraryWarehouse.CreateWhseMovement(WhseWorksheetName.Name, BinContent."Location Code", "Whse. Activity Sorting Method"::None, false, false);
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateAndUpdateLocation(LocationGreen, false, false, false, false, false);  // Location Green.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);

        CreateAndUpdateLocation(LocationSilver, true, true, false, false, true);  // Location Silver.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        LibraryWarehouse.CreateFullWMSLocation(LocationWhite, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);

        CreateAndUpdateLocation(LocationRed, false, false, false, false, true);  // Location Red.
        LibraryWarehouse.CreateNumberOfBins(LocationRed.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        CreateAndUpdateLocation(LocationRed2, false, false, false, false, true);  // Location Red2.
        LibraryWarehouse.CreateNumberOfBins(LocationRed2.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value  required for Number of Bins.

        CreateAndUpdateLocation(LocationYellow, true, true, true, true, false);  // Location Yellow.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow.Code, false);
    end;

    local procedure CreateLocationSetupWithBinsAndWhseEmployee(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        CreateAndUpdateLocation(Location, RequirePutAway, RequirePick, RequireReceive, RequireShipment, BinMandatory); // Location require Putaway, Pick, Receive, ship and Bin Mandatory.
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', LibraryRandom.RandInt(3) + 2, false); // Value required for Number of Bins.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
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
        PurchasesPayablesSetup.Modify(true);

        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
    end;

    local procedure ItemJournalSetup()
    begin
        LibraryInventory.ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure OutputJournalSetup()
    begin
        LibraryInventory.OutputJournalSetup(OutputItemJournalTemplate, OutputItemJournalBatch);
    end;

    local procedure ConsumptionJournalSetup()
    begin
        LibraryInventory.ConsumptionJournalSetup(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
    end;

    local procedure AssignNoSeriesForItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure AcceptActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectRequisitionLine(RequisitionLine, ItemNo);
        RequisitionLine.Validate("Accept Action Message", true);
        RequisitionLine.Modify(true);
    end;

    local procedure AcceptAndCarryOutActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(ItemNo);
        SelectRequisitionLine(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure AutoReserveProdOrderComponent(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.AutoReserve();
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        UpdateLocation(Location, RequirePutAway, RequirePick, RequireReceive, RequireShipment, BinMandatory);
    end;

    local procedure CreateItemAndUpdateInventory(var Item: Record Item; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItem(Item);
        CreateItemJournalLine(ItemJournalLine, Item."No.", Quantity, '', '');
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
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

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, LocationCode, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; Item: Record Item; MinQty: Decimal; MaxQty: Decimal; BinRanking: Integer)
    begin
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Fixed, true);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Validate("Bin Ranking", BinRanking);
        BinContent.Modify(true);
    end;

    local procedure CreateFEFOLocation(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);
    end;

    local procedure CreateProdOrderWithAutoreservedComponent(var ProductionOrder: Record "Production Order"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, SourceNo, Quantity, LocationCode, '');
        FindProductionOrderLine(ProdOrderLine, SourceNo);
        AutoReserveProdOrderComponent(ProdOrderLine);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    begin
        Clear(SalesHeader);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, 0D);
    end;

    local procedure CreateItemsSetup(var Item: Record Item): Code[20]
    var
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        CreateItemAndUpdateInventory(Item2, LibraryRandom.RandDec(100, 2));

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, false);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        exit(Item2."No.");
    end;

    local procedure CreateItemsSetupWithRoutingAndBOM(var Item: Record Item; var RoutingHeader: Record "Routing Header"; LocationCode: Code[10]; Quantity: Decimal)
    var
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(Item2);
        CreateAndPostItemJournalLine(Item2."No.", Quantity, '', LocationCode, false); // Using Tracking FALSE

        // Create Production BOM, Parent item and Attach Production BOM.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, false);
        CreateProductionItem(Item, ProductionBOMHeader."No.");

        // Create Routing and attach Routing for Parent Item.
        CreateRoutingAndUpdateItem(RoutingHeader, Item);
    end;

    local procedure CreateCertifiedProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; UseRoutingLink: Boolean): Code[10]
    var
        ProductionBOMLine: Record "Production BOM Line";
        RoutingLink: Record "Routing Link";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", 1);  // Value important.
        if UseRoutingLink then begin
            RoutingLink.FindFirst();
            ProductionBOMLine.Validate("Routing Link Code", RoutingLink.Code);
            ProductionBOMLine.Modify(true);
        end;
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMLine."Routing Link Code");
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
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
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item, false);
        UpdateProductionBOMNoOnItem(Item2, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
    end;

    local procedure CreateItemWithProductionBOMAndRouting(var Item: Record Item; var ChildItem: Record Item; var ProductionBOMHeader: Record "Production BOM Header")
    var
        RoutingHeader: Record "Routing Header";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        CalcLevel: Option ,SingleLevel,MultiLevel;
    begin
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCodeForSerial());
        LibraryInventory.CreateItem(ChildItem);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", LibraryRandom.RandInt(10));
        CreateRouting(
          RoutingHeader, LibraryRandom.RandDec(50, 2), LibraryRandom.RandDec(50, 2),
          LibraryRandom.RandInt(10), LibraryRandom.RandInt(10));
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Indirect Cost %", LibraryRandom.RandInt(10));
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
        ChildItem.Validate("Unit Cost", LibraryRandom.RandDec(10000, 5));
        ChildItem.Modify(true);

        LibraryVariableStorage.Enqueue(CalcLevel::MultiLevel); // Enqueue for CalculateStandardCostMenuHandler, Calculate Standard Cost for All Level.
        CalculateStandardCost.CalcItem(Item."No.", false);
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

    local procedure CreateWarehousePickfromProductionOrderSetup(var Item: Record Item; var Item2: Record Item; var ProductionOrder: Record "Production Order"; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, Item2."No.", Quantity, LocationWhite.Code,
          LocationWhite."To-Production Bin Code");
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
          Item."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Place, Quantity);
        UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
          Item."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Quantity);
    end;

    local procedure CreateAndPostOutputJournalWithItemTracking(ProductionOrderNo: Code[20]; Tracking: Boolean; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateOutputJournalWithExlpodeRouting(ProductionOrderNo);
        SelectItemJournalLine(ItemJournalLine, OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
        if Tracking then
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        ItemJournalLine.Validate(Quantity, Quantity);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure CreateAndPostConsumptionJournalWithItemTracking(ProductionOrderNo: Code[20]; PostJournal: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        if PostJournal then
            LibraryInventory.PostItemJournalLine(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
    end;

    local procedure CreateOutputJournalWithExlpodeRouting(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
    end;

    local procedure CreatePickWorksheetLineFromProdOrder(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; LocationCode: Code[10])
    var
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        WhsePickRequest.Get(WhsePickRequest."Document Type"::Production, ProdOrderStatus, ProdOrderNo, LocationCode);
        LibraryWarehouse.GetWhseDocsPickWorksheet(WhseWorksheetLine, WhsePickRequest, LocationCode);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure CreateWarehouseJournalLine(var Item: array[3] of Record Item; Quantity: Decimal; Location: Record Location)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        i: Integer;
    begin
        FindBinForPickZone(Bin, LocationWhite.Code, true);
        LibraryVariableStorage.Enqueue(Quantity);

        for i := 1 to 3 do
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code,
              Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item[i]."No.", Quantity);
    end;

    local procedure CreateWarehouseJournalLineAndAssignTracking(var Item: Record Item; Quantity: Decimal; Location: Record Location)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
    begin
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryVariableStorage.Enqueue(Format(Quantity));
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code",
          Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();  // Assign Lot No through WhseItemTrackingPageHandler.
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
    end;

    local procedure CreateRouting(var RoutingHeader: Record "Routing Header"; DirectUnitCost: Decimal; OverheadRate: Decimal; SetupTime: Decimal; RunTime: Decimal)
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        OperationNo: Code[10];
    begin
        ManufacturingSetup.Get();

        CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Validate("Overhead Rate", OverheadRate);
        WorkCenter.Modify(true);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter."No.", OperationNo, SetupTime, RunTime);

        // Certify Routing after Routing lines creation.
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure CreateRoutingAndUpdateItem(var RoutingHeader: Record "Routing Header"; Item: Record Item): Decimal
    var
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        ManufacturingSetup.Get();

        CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");

        // Certify Routing after Routing lines creation.
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);
        exit(RoutingLine."Unit Cost per");
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random value used so that the Next Operation No is greater than the previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
    end;

    local procedure CreateProductionBOMVersion(ProductionBOMNo: Code[20]; BaseUnitOfMeasure: Code[10]; Status: Enum "BOM Status")
    var
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMNo, Format(LibraryRandom.RandInt(10)), BaseUnitOfMeasure);
        ProductionBOMVersion.Validate(Status, Status);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasureSetup(var Item: Record Item; var ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemNo, Quantity, BinCode, LocationCode);
        if Tracking then
            ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineForSaleWithItemTracking(ItemNo: Code[20]; Quantity: Decimal; UnitAmount: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::Sale, ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Amount", UnitAmount);
        ItemJournalLine.Modify(true);

        ItemJournalLine.OpenItemTrackingLines(false);  // Invokes ItemTrackingPageHandler.
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndUpdateProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrderNo: Code[20]; ItemNo: Code[20]; QuantityPer: Decimal; ProdOrderLineNo: Integer; LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProdOrderComponent.Status::Released, ProductionOrderNo, ProdOrderLineNo);
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QuantityPer);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateItemsSetupWithLocationAndBin(var Item: Record Item; var Item2: Record Item; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(Item2);
        CreateAndPostItemJournalLine(Item2."No.", Quantity, BinCode, LocationCode, false);  // Using Tracking TRUE.
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item2, false);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
        CreateAndPostItemJournalLine(Item."No.", Quantity, BinCode, LocationCode, false);  // Using Tracking TRUE.
    end;

    local procedure CreateItemWithPlanningParametersAndProductionBOM(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; SafetyStockQuantity: Decimal)
    begin
        CreateItemsSetup(Item);
        UpdateLotForLotReorderingPolicyOnItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Safety Stock Quantity", SafetyStockQuantity);
        Item.Modify(true);
    end;

    local procedure CreateProductionBOMVersionWithCopyBOM(ProductionBOMNo: Code[20]): Code[20]
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMNo, CopyStr(
            LibraryUtility.GenerateRandomCode(ProductionBOMVersion.FieldNo("Version Code"), DATABASE::"Production BOM Version"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Production BOM Version",
              ProductionBOMVersion.FieldNo("Version Code"))), ProductionBOMHeader."Unit of Measure Code");
        ProductionBOMCopy.CopyBOM(ProductionBOMNo, '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
        exit(ProductionBOMVersion."Version Code");
    end;

    local procedure CreateProductionBOMVersionWithCopyBOMVersion(ProductionBOMNo: Code[20])
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMNo, Format(LibraryRandom.RandInt(5)),
          ProductionBOMHeader."Unit of Measure Code");  // Use Random Version Code.
        ProductionBOMCopy.CopyFromVersion(ProductionBOMVersion);
    end;

    local procedure CreateBOMVersionWithCopyVersion(var Item: Record Item)
    var
        ProdBOMVersionCode: Code[20];
    begin
        ProdBOMVersionCode := CreateProductionBOMVersionWithCopyBOM(Item."Production BOM No.");
        LibraryVariableStorage.Enqueue(Item."Production BOM No.");  // Enqueue variable.
        LibraryVariableStorage.Enqueue(ProdBOMVersionCode);  // Enqueue variable.
        CreateProductionBOMVersionWithCopyBOMVersion(Item."Production BOM No.");
    end;

    local procedure CreateItemSetupWithSerialTracking(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCodeForSerial());
        CreateItemWithItemTrackingCode(Item2, CreateItemTrackingCodeForSerial());
        CreateCertifiedProductionBOM(ProductionBOMHeader, Item, false);
        UpdateProductionBOMNoOnItem(Item2, ProductionBOMHeader."No.");
    end;

    local procedure CreateItemTrackingCodeForSerial(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePickFromProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProductionOrder.Get(ProdOrderLine.Status::Released, ProdOrderLine."Prod. Order No.");

        // Create Warehouse Pick from the Released Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
    end;

    local procedure CreateAndReleaseSalesOrderWithReservation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryVariableStorage.Enqueue(AutoReservationNotPossibleMsg);  // Enqueue variable for reservation message in MessageHandler.
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        SalesLine.ShowReservation();  // Invokes ReservationHandler.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrder(SalesHeader, SalesLine, ItemNo, Quantity, LocationCode);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateWarehouseShipmentFromSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateProductionOrderFromSalesOrder(var ProductionOrder: Record "Production Order"; SalesHeader: Record "Sales Header")
    begin
        LibraryVariableStorage.Enqueue(ProductionOrderCreatedMsg);  // Enqueue variable for created Production Order message in MessageHandler.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(
            SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ItemOrder);
    end;

    local procedure CreateItemsAndWarehouseShipmentWithReservationAndTrackingSetup(var Item: Record Item; var Item2: Record Item; var SalesHeader: Record "Sales Header"; Location: Record Location; Quantity: Decimal)
    begin
        CreateItemSetupWithLotTracking(Item, Item2);
        UpdateInventoryAndAssignTrackingInWhseItemJournal(Location, Item, Item2, Quantity);
        CreateAndReleaseSalesOrderWithReservation(SalesHeader, Item2."No.", 2 * Quantity, Location.Code);  // Twice Quantity required for Full Auto Reservation and Warehouse Shipment.
        CreateWarehouseShipmentFromSalesOrder(SalesHeader);
    end;

    local procedure CreateItems(var ItemNo: array[7] of Code[20])
    var
        Item: Record Item;
        i: Integer;
    begin
        for i := 1 to 7 do begin
            LibraryInventory.CreateItem(Item);
            ItemNo[i] := Item."No.";
        end;
    end;

    local procedure CreateAndReleaseWhseShipmentFromSO(var SalesHeader: Record "Sales Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateWarehouseShipmentFromSalesOrder(SalesHeader);
        FindWarehouseShipmentLine(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateProdOrderComponent(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; QuantityPer: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        SelectProdOrderLine(ProdOrderLine, ProductionOrder."No.", ProductionOrder.Status);
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QuantityPer);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Validate("Bin Code", BinCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreatePickFromSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, ItemNo, Quantity, LocationCode);
        CreateAndReleaseWhseShipmentFromSO(SalesHeader, WarehouseShipmentHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure AddWarehouseInventory(ItemNo: Code[20]; Qty: Decimal; Bin: Record Bin)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code,
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, true);

        CalculateAndPostWarehouseAdjustment(ItemNo);
    end;

    local procedure FindProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure AddProductionOrderComponentWithBin(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        // Find Component. Create Component with Bin and Lot Tracking for the Production Order.
        FindProductionOrderComponent(ProdOrderComponent, ProdOrderNo);
        CreateAndUpdateProductionOrderComponent(
          ProdOrderComponent, ProdOrderNo, ItemNo, ProdOrderComponent."Quantity per",
          ProdOrderComponent."Prod. Order Line No.", LocationCode);
        ProdOrderComponent.Validate("Bin Code", BinCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure RemoveProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Delete(true);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindSet();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, SourceDocument, ActionType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
    end;

    local procedure FindWarehouseReceiptNo(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindProductionOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderRoutingLine.FindFirst();
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindBinForPickZone(var Bin: Record Bin; LocationCode: Code[10]; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, Pick));
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, LibraryRandom.RandInt(Bin.Count));
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindRegisteredWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindSet();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure GenerateMatrixDataForBOMVersion(var VersionCode: array[4] of Text[80]; ProductionBOMNo: Code[20]): Integer
    var
        ProductionBOMVersion: Record "Production BOM Version";
        MatrixManagement: Codeunit "Matrix Management";
        RecRef: RecordRef;
        SetWanted: Option Initial,Previous,Same,Next,PreviousColumn,NextColumn;
        CaptionRange: Text;
        FirstMatrixRecInSet: Text;
        ColumnCount: Integer;
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        RecRef.GetTable(ProductionBOMVersion);
        MatrixManagement.GenerateMatrixData(
          RecRef, SetWanted::Initial, ArrayLen(VersionCode), ProductionBOMVersion.FieldNo("Version Code"),
          FirstMatrixRecInSet, VersionCode, CaptionRange, ColumnCount);
        exit(ColumnCount);
    end;

    local procedure OpenProductionJournal(No: Code[20])
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", No);
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();
    end;

    local procedure PostWhsePositiveAdjmtWithLotExpirationDate(LocationCode: Code[10]; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal; LotNo: Code[50]; ExpirationDate: Date)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode,
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();

        SetExpirationDateOnItemTracking(WhseItemTrackingLine, WarehouseJournalLine, ExpirationDate);

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; SourceDocument: Enum "Warehouse Activity Source Document"; ActionType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, SourceNo, SourceDocument, ActionType);
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ReserveSalesOrderWithProdOrder(var SalesLine: Record "Sales Line"): Code[20]
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        RoutingHeader: Record "Routing Header";
    begin
        // Create and refresh a Released production Order with Routing Line
        CreateItemsSetup(Item);
        CreateRoutingAndUpdateItem(RoutingHeader, Item);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", LibraryRandom.RandInt(100), '', '');

        // Create Sales Order and reserve with Production Order
        CreateSalesOrder(SalesHeader, SalesLine, Item."No.", ProductionOrder.Quantity, '');
        SalesLine.ShowReservation(); // Invokes ReservationHandler

        exit(ProductionOrder."No.");
    end;

    local procedure RunAdjustCostItemEntries(ItemNoFilter: Text[250])
    var
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
    begin
        Clear(AdjustCostItemEntries);
        Commit();  // Commit required for batch job reports.
        AdjustCostItemEntries.InitializeRequest(ItemNoFilter, '');
        AdjustCostItemEntries.UseRequestPage(true);
        AdjustCostItemEntries.RunModal();
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
    end;

    local procedure SelectProductionBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderNo: Code[20]; Status: Enum "Production Order Status")
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.FindFirst();
    end;

    local procedure SetExpirationDateOnItemTracking(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WarehouseJournalLine: Record "Warehouse Journal Line"; ExpirationDate: Date)
    begin
        WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Warehouse Journal Line");
        WhseItemTrackingLine.SetRange("Source ID", WarehouseJournalLine."Journal Batch Name");
        WhseItemTrackingLine.SetRange("Location Code", WarehouseJournalLine."Location Code");
        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseJournalLine."Line No.");
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure UpdateInventoryInWhseItemJournal(LocationCode: Code[10]; var CompItem: array[3] of Record Item; Quantity: Decimal)
    var
        Item: Record Item;
    begin
        // Create and register the Warehouse Item Journal Lines.
        LibraryWarehouse.WarehouseJournalSetup(LocationCode, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateWarehouseJournalLine(CompItem, Quantity, LocationWhite);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);

        // Calculate Warehouse adjustment and post Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        Item.SetRange("No.", CompItem[1]."No.", CompItem[3]."No.");
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');  // Value required to avoid the Document No mismatch.
    end;

    local procedure UpdateInventoryAndAssignTrackingInWhseItemJournal(Location: Record Location; var Item: Record Item; var Item2: Record Item; Quantity: Decimal)
    begin
        // Assign Tracking and register the Warehouse Item Journal Lines.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateWarehouseJournalLineAndAssignTracking(Item, Quantity, LocationWhite);
        CreateWarehouseJournalLineAndAssignTracking(Item2, Quantity, LocationWhite);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // Calculate Warehouse adjustment and post Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        Item.SetRange("No.", Item."No.", Item2."No.");
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, '');  // Value required to avoid the Document No mismatch.
    end;

    local procedure UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(ItemNo: Code[20]; ProductionOrderNo: Code[20]; ActionType: Enum "Warehouse Action Type"; QtyToHandle: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
        FindWarehouseActivityLine(
          WarehouseActivityLine, ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", ActionType);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Lot No.", ItemLedgerEntry."Lot No.");
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
            ItemLedgerEntry.Next();
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateManufacturingSetupComponentsAtLocation(NewComponentsAtLocation: Code[10]) ComponentsAtLocation: Code[10]
    begin
        ManufacturingSetup.Get();
        ComponentsAtLocation := ManufacturingSetup."Components at Location";
        ManufacturingSetup.Validate("Components at Location", NewComponentsAtLocation);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateRoutingLinkOnProdOrderComponent(ProductionOrderNo: Code[20]): Code[10]
    var
        ProdOrderComponent: Record "Prod. Order Component";
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.FindFirst();
        FindProductionOrderComponent(ProdOrderComponent, ProductionOrderNo);
        ProdOrderComponent.Validate("Routing Link Code", RoutingLink.Code);
        ProdOrderComponent.Modify(true);
        exit(RoutingLink.Code);
    end;

    local procedure UpdateFlushingMethodAndCertifyBOM(var Item: Record Item; ProductionBOMHeader: Record "Production BOM Header")
    begin
        Item.Validate("Flushing Method", Item."Flushing Method"::Backward);
        Item.Modify(true);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateManufacturingSetupDynamicLowLevelCode(NewDynamicLowLevelCode: Boolean) DynamicLowLevelCode: Boolean
    begin
        ManufacturingSetup.Get();
        DynamicLowLevelCode := ManufacturingSetup."Dynamic Low-Level Code";
        ManufacturingSetup.Validate("Dynamic Low-Level Code", NewDynamicLowLevelCode);
        ManufacturingSetup.Modify(true);
    end;

    local procedure UpdateItemPlanningParameters(var Item: Record Item): Code[20]
    var
        ComponentItemNo: Code[20];
    begin
        ComponentItemNo := CreateItemsSetup(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        exit(ComponentItemNo);
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;

    local procedure UpdateRoutingLine(var RoutingHeader: Record "Routing Header"; RoutingLinkCode: Code[10])
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindFirst();
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::"Under Development");
        RoutingLine.Validate("Routing Link Code", RoutingLinkCode);
        RoutingLine.Validate("Send-Ahead Quantity", LibraryRandom.RandDec(10, 2));
        RoutingLine.Modify(true);
        UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
    end;

    local procedure UpdateProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderNo: Code[20]; FlushingMethod: Enum "Flushing Method")
    begin
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo);
        ProdOrderRoutingLine.Validate("Flushing Method", FlushingMethod);
        ProdOrderRoutingLine.Modify(true);
    end;

    local procedure UpdateProductionBOMStatus(Status: Enum "BOM Status"; ProductionBOMNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateProductionBOMDescription(ProductionBOMNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        ProductionBOMHeader.Validate(
          Description, PadStr(ProductionBOMHeader.Description, MaxStrLen(ProductionBOMHeader.Description), '0'));
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateItemOnProductionBOMLine(ProductionBOMNo: Code[20]; No: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        SelectProductionBOMLine(ProductionBOMLine, ProductionBOMNo);
        ProductionBOMLine.Validate("No.", No);
        ProductionBOMLine.Modify(true);
    end;

    local procedure UpdateItemProdBOMUOMAndQtyPer(Item: Record Item; QtyPerUnitOfMeasure: Decimal; QtyPer: Decimal)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUnitOfMeasure);
        UpdateProductionBOMStatus(ProductionBOMHeader.Status::"Under Development", Item."Production BOM No.");
        ProductionBOMHeader.Get(Item."Production BOM No.");
        ProductionBOMHeader.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProductionBOMHeader.Modify(true);
        UpdateQtyPerOnProductionBOM(Item."Production BOM No.", QtyPer);
        UpdateProductionBOMStatus(ProductionBOMHeader.Status::Certified, Item."Production BOM No.");
    end;

    local procedure UpdateLotForLotReorderingPolicyOnItem(var Item: Record Item)
    begin
        Item.Get(Item."No.");  // Used to avoid the update record error.
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);
    end;

    local procedure UpdateItemProdBOM(ItemNo: Code[20]; ProductionBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateLocation(var Location: Record Location; PutAway: Boolean; Pick: Boolean; Receive: Boolean; Shipment: Boolean; BinRequired: Boolean)
    begin
        Location.Validate("Require Receive", Receive);
        Location.Validate("Require Shipment", Shipment);
        Location.Validate("Require Put-away", PutAway);
        Location.Validate("Require Pick", Pick);

        if Pick then
            if Shipment then
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)"
            else
                Location."Prod. Consump. Whse. Handling" := Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement";
        if PutAway then
            Location."Prod. Output Whse. Handling" := Location."Prod. Output Whse. Handling"::"Inventory Put-away";

        Location."Bin Mandatory" := BinRequired;
        // Skip Validate to improve performance.
        Location.Modify(true);
    end;

    local procedure UpdateInventoryUsingWhseJournal(Location: Record Location; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, '',
          Location."Cross-Dock Bin Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, ''); // Value required to avoid the Document No mismatch.
    end;

    local procedure UpdateQtyPerOnProductionBOM(ProductionBOMNo: Code[20]; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        SelectProductionBOMLine(ProductionBOMLine, ProductionBOMNo);
        ProductionBOMLine.Validate("Quantity per", QtyPer);
        ProductionBOMLine.Modify(true);
    end;

    local procedure CreateItemHierarchy(var Item: Record Item; var Item2: Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Item Hierarchy.
        CreateItemsSetup(Item);
        CreateItemsSetup(Item2);
        UpdateProductionBOMStatus(ProductionBOMHeader.Status::"Under Development", Item2."Production BOM No.");
        UpdateItemOnProductionBOMLine(Item2."Production BOM No.", Item."No.");  // Update Production Item from Previous Production BOM.
        UpdateProductionBOMStatus(ProductionBOMHeader.Status::Certified, Item2."Production BOM No.");
    end;

    local procedure VerifyProdOrderComponent(ProdOrderNo: Code[20]; Status: Enum "Production Order Status"; ItemNo: Code[20]; ReservedQuantity: Decimal; RoutingLinkCode: Code[10]; FlushingMethod: Enum "Flushing Method")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField(Status, Status);
        ProdOrderComponent.TestField("Item No.", ItemNo);
        ProdOrderComponent.CalcFields("Reserved Quantity");
        ProdOrderComponent.TestField("Reserved Quantity", ReservedQuantity);
        ProdOrderComponent.TestField("Routing Link Code", RoutingLinkCode);
        ProdOrderComponent.TestField("Flushing Method", FlushingMethod);
    end;

    local procedure VerifyQtyOnProdOrderComponent(ProdOrderNo: Code[20]; QtyPer: Decimal; ExpectedQty: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst();
        Assert.AreEqual(QtyPer, ProdOrderComponent."Quantity per", ProdOrderComponent.FieldCaption("Quantity per"));
        Assert.AreEqual(ExpectedQty, ProdOrderComponent."Expected Quantity", ProdOrderComponent.FieldCaption("Expected Quantity"));
    end;

    local procedure VerifyQtyOnPlanningComponent(ItemNo: Code[20]; QtyPer: Decimal; ExpectedQty: Decimal)
    var
        PlanningComponent: Record "Planning Component";
    begin
        PlanningComponent.SetRange("Item No.", ItemNo);
        PlanningComponent.FindFirst();
        Assert.AreEqual(QtyPer, PlanningComponent."Quantity per", PlanningComponent.FieldCaption("Quantity per"));
        Assert.AreEqual(ExpectedQty, PlanningComponent."Expected Quantity", PlanningComponent.FieldCaption("Expected Quantity"));
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

    local procedure VerifyWarehouseActivityLineLot(LocationCode: Code[10]; ItemNo: Code[20]; LotNo: Code[50]; ExpectedQty: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        WarehouseActivityLine.FindSet();
        repeat
            Assert.AreEqual(ExpectedQty, WarehouseActivityLine.Quantity, PickErr);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure VerifyRegisteredWhseActivityLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; ActionType: Enum "Warehouse Action Type")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.FindSet();
        repeat
            RegisteredWhseActivityLine.TestField("Lot No.");
            RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
            RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        until RegisteredWhseActivityLine.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal; Tracking: Boolean)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        repeat
            ItemLedgerEntry.TestField(Quantity, Quantity);
            if Tracking then
                ItemLedgerEntry.TestField("Lot No.");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntries(SourceNo: Code[20]; Quantity1: Integer; Quantity2: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Source No.", SourceNo);

        ItemLedgerEntry.SetRange(Quantity, Quantity1);
        Assert.AreEqual(2, ItemLedgerEntry.Count(), 'Expected 2 entries with first Quantity');
        ItemLedgerEntry.SetRange(Quantity, Quantity2);
        Assert.AreEqual(1, ItemLedgerEntry.Count(), 'Expected 1 entry with second Quantity');
    end;

    local procedure VerifyItemLedgerEntriesForCostAmountActual(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        MaxValue: Decimal;
        MinValue: Decimal;
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.FindSet();

        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        MaxValue := ItemLedgerEntry."Cost Amount (Actual)";
        MinValue := ItemLedgerEntry."Cost Amount (Actual)";

        repeat
            ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
            if ItemLedgerEntry."Cost Amount (Actual)" > MaxValue then
                MaxValue := ItemLedgerEntry."Cost Amount (Actual)";
            if ItemLedgerEntry."Cost Amount (Actual)" < MinValue then
                MinValue := ItemLedgerEntry."Cost Amount (Actual)";
            Assert.AreNearlyEqual(MaxValue, MinValue, 0.01, StrSubstNo(CostAmountActualInILEErr, MaxValue, MinValue)); // The difference between MaxValue and MinValue should not be greater than 0.01.
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyWarehouseEntry(EntryType: Option; ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, Quantity);
        WarehouseEntry.TestField("Bin Code", BinCode);
        WarehouseEntry.TestField("Lot No.");
    end;

    local procedure VerifyItemJournalLine(ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Entry Type", EntryType);
    end;

    local procedure VerifyProductionOrder(No: Code[20]; RoutingNo: Code[20]; Quantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("No.", No);
        ProductionOrder.FindFirst();
        ProductionOrder.TestField("Routing No.", RoutingNo);
        ProductionOrder.TestField(Quantity, Quantity);
    end;

    local procedure VerifyLowLevelCodeOnProductionBOM(No: Code[20]; LowLevelCode: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.Get(No);
        ProductionBOMHeader.TestField("Low-Level Code", LowLevelCode);
    end;

    local procedure VerifyPostedInventoryPickLine(SourceNo: Code[20]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
    begin
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.FindFirst();
        PostedInvtPickLine.TestField("Item No.", ItemNo);
        PostedInvtPickLine.TestField("Bin Code", BinCode);
        PostedInvtPickLine.TestField(Quantity, Quantity);
        PostedInvtPickLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyProductionOrderRoutingLine(ProdOrderNo: Code[20]; UnitCostPer: Decimal)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        FindProductionOrderRoutingLine(ProdOrderRoutingLine, ProdOrderNo);
        ProdOrderRoutingLine.TestField("Unit Cost per", UnitCostPer);
    end;

    local procedure VerifyMatrixBOMVersion(ProductionBOMNo: Code[20]; VersionCode: array[4] of Text[80]; VersionCount: Integer)
    var
        ProductionBOMVersion: Record "Production BOM Version";
        LineCounter: Integer;
    begin
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMVersion.FindFirst();
        Assert.AreEqual(VersionCount, ProductionBOMVersion.Count, VersionCountErr);  // Verify the BOM Version count for Production BOM.
        for LineCounter := 1 to VersionCount do begin
            ProductionBOMVersion.SetRange("Version Code", VersionCode[VersionCount]);
            ProductionBOMVersion.FindFirst();
            Assert.AreEqual(VersionCode[VersionCount], ProductionBOMVersion."Version Code", VersionCodeErr);  // Verify the BOM Version Code for particular BOM Version per Item.
        end;
    end;

    local procedure VerifyPurchaseLine(No: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyProductionOrderLine(ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ItemNo);
        ProdOrderLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            ReservationEntry.TestField("Location Code", LocationCode);
            ReservationEntry.TestField("Shipment Date", ShipmentDate);
        until ReservationEntry.Next() = 0;
    end;

    local procedure VerifySerialTrackingAndQuantityInItemLedgerEntry(EntryType: Enum "Item Ledger Document Type"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, ItemNo);
        repeat
            ItemLedgerEntry.TestField(Quantity, Quantity);
            ItemLedgerEntry.TestField("Serial No.");
        until ItemLedgerEntry.Next() = 0;
    end;

    local procedure VerifyRegisteredWhseActivityLineAndCalcTotalQty(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; ActionType: Enum "Warehouse Action Type") SumQuantity: Decimal
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWhseActivityLine(RegisteredWhseActivityLine, SourceDocument, SourceNo, ActionType);
        repeat
            RegisteredWhseActivityLine.TestField("Lot No.");
            RegisteredWhseActivityLine.TestField("Item No.", ItemNo);
            SumQuantity += RegisteredWhseActivityLine.Quantity;
        until RegisteredWhseActivityLine.Next() = 0;
    end;

    local procedure AreSameMessages(Message: Text[1024]; Message2: Text[1024]): Boolean
    begin
        exit(StrPos(Message, Message2) > 0);
    end;

    local procedure CreateItemSetupWithSameLotTracking(var MainItem: Record Item; var CompItem: array[2] of Record Item)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ItemTrackingCode: Code[10];
    begin
        ItemTrackingCode := CreateItemTrackingCode();
        LibraryInventory.CreateItem(MainItem);
        CreateItemWithItemTrackingCode(CompItem[1], ItemTrackingCode);
        CreateItemWithItemTrackingCode(CompItem[2], ItemTrackingCode);

        CreateCertifiedProductionBOMwithComponentItem(ProductionBOMHeader, MainItem, CompItem);
        UpdateProductionBOMNoOnItem(MainItem, ProductionBOMHeader."No.");
    end;

    local procedure CreateCertifiedProductionBOMWithComponentItem(
        var ProductionBOMHeader: Record "Production BOM Header";
        MainItem: Record Item;
        CompItem: array[2] of Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, MainItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[1]."No.", LibraryRandom.RandInt(1));
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[1]."No.", LibraryRandom.RandInt(2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateWarehousePickfromProductionOrderSetup(var CompItem: array[2] of Record Item; var ProductionOrder: Record "Production Order"; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
          CompItem[1]."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Place, Quantity);
        UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
          CompItem[1]."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Quantity);
        UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
          CompItem[2]."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Place, Quantity);
        UpdateLotNoAndQtyToHandleOnWarehouseActivityLine(
          CompItem[2]."No.", ProductionOrder."No.", WarehouseActivityLine."Action Type"::Take, Quantity);
    end;

    local procedure DeleteOldWareHousePickandCreateNew(ProductionOrder: Record "Production Order")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        SourceDocument: Enum "Warehouse Activity Source Document";
        ActionType: Enum "Warehouse Action Type";
    begin
        FindWarehouseActivityHeader(WarehouseActivityHeader, ProductionOrder."No.", SourceDocument::"Prod. Consumption", ActionType::Place);
        WarehouseActivityHeader.Delete(true);
    end;

    local procedure VerifyRegisteredWhseActivityLines(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; ActionType: Enum "Warehouse Action Type")
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.FindSet();
        repeat
            RegisteredWhseActivityLine.TestField("Lot No.");
            RegisteredWhseActivityLine.TestField(Quantity, Quantity);
        until RegisteredWhseActivityLine.Next() = 0;
    end;

    local procedure CreateAndPostItemJournalLineWithLot(ItemNo: Code[20]; Quantity: Decimal; BinCode: Code[20]; LocationCode: Code[10]; LotNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
            ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Validate("Lot No.", LotNo);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure VerifyReservationIsCorrect(SourceType: Integer; SourceID: Code[20]; ReservationStatus: enum "Reservation Status"; ExpectedBaseQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        ReservationEntry.CalcSums("Quantity (Base)");
        Assert.AreEqual(ExpectedBaseQty, ReservationEntry."Quantity (Base)", PickErr);
    end;

    local procedure SplitInventoryPickAndUpdateLotAndBin(SalesOrderNo: Code[20]; LotNo: array[2] of Code[20]; Bin: array[2] of Record Bin; SameLotNoForBothLine: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        i: Integer;
    begin
        SplitInventoryPick(SalesOrderNo, 6);

        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Sales Order");
        WarehouseActivityLine.SetRange("Source No.", SalesOrderNo);
        if WarehouseActivityLine.FindSet() then
            repeat
                i += 1;
                if i = 1 then
                    WarehouseActivityLine.Validate("Bin Code", Bin[1].Code)
                else
                    WarehouseActivityLine.Validate("Bin Code", Bin[2].Code);

                if SameLotNoForBothLine then
                    WarehouseActivityLine.Validate("Lot No.", LotNo[1])
                else
                    if i = 1 then
                        WarehouseActivityLine.Validate("Lot No.", LotNo[1])
                    else
                        WarehouseActivityLine.Validate("Lot No.", LotNo[2]);
                WarehouseActivityLine.Modify(true);
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure SplitInventoryPick(SourceNo: Code[20]; QtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Sales Order");
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        if WarehouseActivityLine.FindFirst() then begin
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
            WarehouseActivityLine.Modify(true);
            WarehouseActivityLine.SplitLine(WarehouseActivityLine);
        end;
    end;

    local procedure PostInventoryPickWithSuppressCommitEnabledFromSales(SalesHeader: Record "Sales Header")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityHeader.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Sales Order");
        WarehouseActivityHeader.SetRange("Source No.", SalesHeader."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityLine."Source Document"::"Sales Order");
        WarehouseActivityLine.SetRange("Source No.", SalesHeader."No.");
        if WarehouseActivityLine.FindSet() then
            repeat
                Codeunit.Run(Codeunit::"Whse.-Act.-Post (Yes/No)", WarehouseActivityLine);
            until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateWhseLotNoUsingSourceAndBin(SourceDocument: enum "Warehouse Activity Source Document"; SourceNo: Code[20]; BinCode: Code[20]; NewLotNo: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Bin Code", BinCode);
        if WarehouseActivityLine.FindSet() then
            WarehouseActivityLine.ModifyAll("Lot No.", NewLotNo, true);
    end;

    local procedure ActionMessageExist(ItemNo: Code[20]; SourceID: Code[20]): Boolean
    var
        ActionMessageEntry: Record "Action Message Entry";
    begin
        ActionMessageEntry.SetRange("Item No.", ItemNo);
        ActionMessageEntry.SetRange("Source ID", SourceID);
        exit(not ActionMessageEntry.IsEmpty());
    end;

    local procedure ExecuteGetActionMessageFromPlanningWorksheet(ItemNo: Code[20])
    var
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        LibraryVariableStorage.Enqueue(ItemNo);
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet."Get &Action Messages".Invoke();
    end;

    local procedure CreateItemWithLotWarehouseTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateLotItem(Item);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode."Lot Warehouse Tracking" := true;
        ItemTrackingCode.Modify(true);
    end;

    local procedure VerifyThereIsNoDamagedReservationEntryForSurplus(SourceType: Integer; SourceID: Code[20]; ReservationStatus: enum "Reservation Status")//; ExpectedBaseQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        asserterror ReservationEntry.FindFirst();
    end;

    local procedure ResetWarehouseEmployeeDefaultLocation()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange("User ID", UserId());
        WarehouseEmployee.SetRange(Default, true);
        WarehouseEmployee.ModifyAll(Default, false);
    end;

    local procedure VerifyWareHouseActivityLinesForQuantity(ProductionOrderNo: Code[20]; Location: Record Location; Quantity: Decimal; UpdatedQuantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.SetRange("Bin Code", Location."To-Production Bin Code");
        WarehouseActivityLine.FindFirst();
        Assert.IsTrue(WarehouseActivityLine."Qty. (Base)" = Quantity, StrSubstNo(QuantityErr, Quantity));

        WarehouseActivityLine.Reset();
        FindWarehouseActivityLine(WarehouseActivityLine, ProductionOrderNo, WarehouseActivityLine."Source Document"::"Prod. Consumption", WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.SetRange("Bin Code", Location."To-Production Bin Code");
        WarehouseActivityLine.FindLast();
        Assert.IsTrue(WarehouseActivityLine."Qty. (Base)" = UpdatedQuantity, StrSubstNo(QuantityErr, UpdatedQuantity));
    end;

    local procedure UpdateQuantityWarehousePickFromPage(ProductionOrderNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehousePickPage: TestPage "Warehouse Pick";
    begin
        WarehouseActivityLine.SetRange("Source Document", WarehouseActivityHeader."Source Document"::"Prod. Consumption");
        WarehouseActivityLine.SetRange("Source No.", ProductionOrderNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        WarehousePickPage.OpenEdit();
        WarehousePickPage.GoToRecord(WarehouseActivityHeader);
        WarehousePickPage.WhseActivityLines.Last();
        WarehousePickPage.WhseActivityLines.Previous();
        WarehousePickPage.WhseActivityLines.Quantity.SetValue(Quantity);
    end;

    local procedure CreateInventoryWithBin(Item: Record Item; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20]; UnitAmount: Decimal)
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

    local procedure CreateBin(var Bin: array[8] of Record Bin; LocationCode: Code[10])
    var
        i: Integer;
    begin
        for i := 1 to arraylen(Bin) do
            LibraryWarehouse.CreateBin(Bin[i], LocationCode, Bin[i].Code, '', '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderComponentsHandler(var ProdOrderComponents: TestPage "Prod. Order Components")
    var
        ItemInventory: Variant;
        ItemNo: Variant;
    begin
        // Verifying the values on Prod. Order Components page.
        LibraryVariableStorage.Dequeue(ItemInventory);  // Dequeue variable.
        ProdOrderComponents."Expected Quantity".AssertEquals(ItemInventory);
        LibraryVariableStorage.Dequeue(ItemNo);  // Dequeue variable.
        ProdOrderComponents."Item No.".AssertEquals(ItemNo);
        ProdOrderComponents.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelReservationPageHandler(var Reservation: TestPage Reservation)
    begin
        Counter += 1;
        case Counter of
            1:
                Reservation."Reserve from Current Line".Invoke();
            2:
                Reservation.CancelReservationCurrentLine.Invoke();  // Cancel Reservation.
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CancelReserveConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(AreSameMessages(Question, CancelReservationMsg), Question);
        Reply := true;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStandardCostMenuHandler(Option: Text[1024]; var CalcLevel: Integer; Instruction: Text[1024])
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        CalcLevel := DequeueVariable;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();  // Assign Lot No.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler2(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(TrackingQuantity);
        ItemTrackingLines."Lot No.".SetValue(TrackingQuantity);
        ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AssignOrEnterTrackingOnItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Quantity: Variant;
        ItemNo: Variant;
        TrackingAction2: Variant;
        TrackingAction: Option AssignSerialNo,AssignLotNo,EnterValues,SelectEntries;
    begin
        Commit();
        LibraryVariableStorage.Dequeue(TrackingAction2);
        TrackingAction := TrackingAction2;
        case TrackingAction of
            TrackingAction::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingAction::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();  // Item Tracking Summary Page is handled in 'ItemTrackingSummaryPageHandler'.
            TrackingAction::EnterValues:
                begin
                    LibraryVariableStorage.Dequeue(Quantity);
                    LibraryVariableStorage.Dequeue(ItemNo);
                    FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
                    ItemTrackingLines."Serial No.".SetValue(ItemLedgerEntry."Serial No.");
                    ItemTrackingLines."Lot No.".SetValue(ItemLedgerEntry."Lot No.");
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesHandler(var AdjustCostItemEntries: TestRequestPage "Adjust Cost - Item Entries")
    begin
        AdjustCostItemEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingPageHandler(var WhseItemTrackingLine: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLine."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLine.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    var
        ItemNo: Variant;
    begin
        // Verifying the values on Production Journal page.
        LibraryVariableStorage.Dequeue(ItemNo);  // Dequeue variable.
        ProductionJournal.Next(); // To verify the next component updated.
        ProductionJournal."Item No.".AssertEquals(ItemNo);
        ProductionJournal.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SerialItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Serial No.".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(AreSameMessages(Message, ExpectedMessage), Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure LowLevelCodeConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        WrongConfirmErr: Label 'Wrong confirm: %1', Comment = '%1: Confirmation question';
    begin
        if AreSameMessages(Question, ConfirmCalculateLowLevelCodeQst) then begin
            Reply := true;
            exit;
        end;
        if AreSameMessages(Question, SuggestedBackGroundRunQst) then begin
            Reply := false;
            exit;
        end;
        Assert.Fail(StrSubstNo(WrongConfirmErr, Question));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionBOMListHandler(var ProdBOMVersionList: Page "Prod. BOM Version List"; var Response: Action)
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMNo: Variant;
        VersionCode: Variant;
    begin
        // Select source version from Production BOM Version List lookup page.
        LibraryVariableStorage.Dequeue(ProductionBOMNo);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(VersionCode);  // Dequeue variable.
        ProductionBOMVersion.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMVersion.SetRange("Version Code", VersionCode);
        ProductionBOMVersion.FindFirst();
        ProdBOMVersionList.SetTableView(ProductionBOMVersion);
        ProdBOMVersionList.SetRecord(ProductionBOMVersion);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Auto Reserve".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPostingMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, JournalLinesPostedMsg) > 0, Message);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ProdJnlPostConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(AreSameMessages(ConfirmMessage, PostJnlLinesMsg), ConfirmMessage);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdBOMMatrixPerVersionHandler(var ProdBOMMatrixPerVersion: TestPage "Prod. BOM Matrix per Version")
    begin
        ProdBOMMatrixPerVersion."&Show Matrix".Invoke(); // To invoke ShowMatrixHandler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ShowMatrixHandler(var ProdBOMMatPeVerMatrix: TestPage "Prod. BOM Mat. per Ver. Matrix")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ProdBOMMatPeVerMatrix."Item No.".AssertEquals(ItemNo);
        ProdBOMMatPeVerMatrix.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhereUsedHandler(var ProdBOMWhereUsed: TestPage "Prod. BOM Where-Used")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        ProdBOMWhereUsed."Item No.".AssertEquals(ItemNo);
        ProdBOMWhereUsed.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreatePickReportHandler(var CreatePickReqPage: TestRequestPage "Create Invt Put-away/Pick/Mvmt")
    begin
        CreatePickReqPage.CInvtPick.SetValue(true);
        CreatePickReqPage.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure InvPostingSelectionHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;
    end;

    [RequestPageHandler]
    procedure GetActionMessageReportHandler(var GetActionMessageReqPage: TestRequestPage "Get Action Messages")
    begin
        GetActionMessageReqPage.Item.SetFilter("No.", LibraryVariableStorage.DequeueText());
        GetActionMessageReqPage.OK().Invoke();
    end;
}
