codeunit 137271 "SCM Reservation IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reservation]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        isInitialized: Boolean;
        CancelReservationMsg: Label 'Cancel reservation of %1 of item number %2', Comment = '%1 = Quantity, %2 = Item No.';
        CustomerNoChangeMsg: Label 'Do you want to change ';
        OrderDeletionErr: Label 'Order must be deleted.';
        NothingToCreateErr: Label 'There is nothing to create.';
        PickCreatedMsg: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';
        PickActivityMsg: Label 'Pick activity no. %1 has been created.', Comment = '%1 = Document No.';
        TransferOrderDeletedMsg: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = '%1 = Document No.';
        OrderTrackingPolicyMsg: Label 'The change will not affect existing entries.';
        AvailabilityWarningMsg: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        ItemTrackingLotNoErr: Label 'Item Tracking Serial No.  Lot No. %1 for Item No. %2 Variant  cannot be fully applied.', Comment = '%1 = Lot No., %2 = Item No.';
        ReservationErr: Label 'There is nothing available to reserve.';
        ValidationErr: Label '%1 must be %2.', Comment = '%1:Field1,%2:Value1';
        ReservationDisruptedWarningMsg: Label 'One or more reservation entries exist for the item';
        TrackingOption: Option AssignSerialNo,AssignLotNo,SelectEntries,SetLotNo,SetSerialNo,AssignGivenLotNo,AssignLot,ManualSetLotNo,UpdateQuantityBase,ManualSetMultipleLots;
        ReservationOption: Option ReserveFromCurrentLine,VerifyQuantity;
        ItemsPickedMsg: Label 'The items have been picked';
        LotReservedForAnotherDocErr: Label 'Lot No. %1 is not available on inventory or it has already been reserved for another document.', Comment = '%1: Field("Lot No.")';
        ReserveMustNotBeNeverErr: Label 'Reserve must not be Never';
        ReserveMustBeNeverErr: Label 'Non-inventory and service items must have the reserve type Never';

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithUpdateLocationCodeOnSalesLine()
    var
        Location: Record Location;
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Error while updating Location Code on Sales Line after Reservation.

        // [GIVEN] Create and post Purchase Order, create Sales Order and reserve Quantity.
        Initialize();
        ReservationOnSalesLine(SalesLine);

        // [WHEN] Update Location Code on Sales Line.
        asserterror SalesLine.Validate("Location Code", LibraryWarehouse.CreateLocation(Location));

        // [THEN] Error while updating Location Code.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithUpdateSellToCustomerNoOnSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Error while updating Sell To Customer No. on Sales Header after Reservation.

        // [GIVEN] Create and post Purchase Order, create Sales Order and reserve Quantity.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        ReservationOnSalesLine(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Enqueue for Confirm handler.
        LibraryVariableStorage.Enqueue(CustomerNoChangeMsg);
        LibraryVariableStorage.Enqueue(CustomerNoChangeMsg);
        LibraryVariableStorage.Enqueue('Do you want to continue');

        // [WHEN] Update Sell To Customer No on Sales Header.
        asserterror SalesHeader.Validate("Sell-to Customer No.", CreateCustomer());

        // [THEN] Error while updating Sell To Customer No.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Reserved Qty. (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerForReservation,ItemTrackingListPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyBeforeReservationWithSpecificSerialTrue()
    var
        SalesLine: Record "Sales Line";
        ConfirmOption: Option SerialSpecificTrue,SerialSpecificFalse;
    begin
        // [SCENARIO] Verify Qty. to Reserve, Total Reserved Qty and Total Qty. on Reservation page before Reservation with Specific Serial True.

        // [GIVEN] Create and post Purchase Order, create Sales Order.
        Initialize();
        SetupITEntriesForPurchAndSales(SalesLine, ConfirmOption::SerialSpecificTrue);
        LibraryVariableStorage.Enqueue(ReservationOption::VerifyQuantity);  // Enqueue value for ReservationPageHandler.
        EnqueueValuesForReservationPageHandler(1, 0, 1);  // 1 for Quantity as Serial Specific True.

        // [WHEN] Open Reservation page.
        SalesLine.ShowReservation();

        // [THEN] Verify various Quantities on Reservation page.Verification done in ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerForReservation,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyBeforeReservationWithSpecificSerialFalse()
    var
        SalesLine: Record "Sales Line";
        ConfirmOption: Option SerialSpecificTrue,SerialSpecificFalse;
    begin
        // [SCENARIO] Verify Qty. to Reserve, Total Reserved Qty and Total Qty. on Reservation page before Reservation with Specific Serial False.

        // [GIVEN] Create and post Purchase Order, create Sales Order.
        Initialize();
        SetupITEntriesForPurchAndSales(SalesLine, ConfirmOption::SerialSpecificFalse);  // Take random value for Quantity.
        LibraryVariableStorage.Enqueue(ReservationOption::VerifyQuantity);  // Enqueue value for ReservationPageHandler.
        EnqueueValuesForReservationPageHandler(SalesLine.Quantity, 0, SalesLine.Quantity);

        // [WHEN] Open Reservation page.
        SalesLine.ShowReservation();

        // [THEN] Verify various Quantities on Reservation page.Verification done in ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerForReservation,ItemTrackingListPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyAfterReservationWithSerialSpecificTrue()
    var
        SalesLine: Record "Sales Line";
        ConfirmOption: Option SerialSpecificTrue,SerialSpecificFalse;
    begin
        // [SCENARIO] Verify Qty. to Reserve, Total Reserved Qty and Total Qty. on Reservation page after Reservation with Specific Serial True.

        // [GIVEN] Create and post Purchase Order and Reserve Quantity on Sales Line.
        Initialize();
        SetupITEntriesForPurchAndSales(SalesLine, ConfirmOption::SerialSpecificTrue);
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.
        SalesLine.ShowReservation();
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue value for ConfirmHandlerForReservation.
        LibraryVariableStorage.Enqueue(ConfirmOption::SerialSpecificFalse);  // Enqueue value for ConfirmHandlerForReservation.
        LibraryVariableStorage.Enqueue(ReservationOption::VerifyQuantity);  // Enqueue value for ReservationPageHandler.
        EnqueueValuesForReservationPageHandler(SalesLine.Quantity, 1, SalesLine.Quantity);

        // [WHEN] Open Reservation page.
        SalesLine.ShowReservation();

        // [THEN] Verify various Quantities on Reservation page.Verification done in ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyAfterPostingItemJournalLineWithReservation()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Verify Qty. to Reserve, Total Reserved Qty and Total Qty. on Reservation page after posting Item Journal Line.

        // [GIVEN] Create and post Purchase Order, create Sales Order, create and post Item Journal Line.
        Initialize();
        CreateAndPostPurchaseOrder(PurchaseLine, CreateItem(Item."Replenishment System"::Purchase), '');
        CreateSalesDocument(SalesLine, PurchaseLine."No.", '', PurchaseLine.Quantity / 2);  // Take partial Quantity.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.
        SalesLine.ShowReservation();
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Negative Adjmt.", PurchaseLine."No.", SalesLine.Quantity - LibraryRandom.RandInt(10));  // Using Random value for Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(ReservationOption::VerifyQuantity);  // Enqueue value for ReservationPageHandler.
        EnqueueValuesForReservationPageHandler(SalesLine.Quantity, SalesLine.Quantity, PurchaseLine.Quantity - ItemJournalLine.Quantity);

        // [WHEN] Open Reservation page.
        SalesLine.ShowReservation();

        // [THEN] Verify various Quantities on Reservation page.Verification done in ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyAfterReservFromFirmPlannedProdOrderComponent()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Verify Qty. to Reserve, Total Reserved Qty and Total Qty. on Reservation page after Reservation from Firm Planned Production Order Component.
        ReservationFromProdOrderComponent(ProductionOrder.Status::"Firm Planned");
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QtyAfterReservFromReleasedProdOrderComponent()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [SCENARIO] Verify Qty. to Reserve, Total Reserved Qty and Total Qty. on Reservation page after Reservation from Released Production Order Component.
        ReservationFromProdOrderComponent(ProductionOrder.Status::Released);
    end;

    local procedure ReservationFromProdOrderComponent(Status: Enum "Production Order Status")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Production Order and reserve from Production Order Component.
        Initialize();
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        CreateProductionOrderAndReserveFromComponent(PurchaseLine, Status);
        LibraryVariableStorage.Enqueue(ReservationOption::VerifyQuantity);
        EnqueueValuesForReservationPageHandler(PurchaseLine.Quantity, PurchaseLine.Quantity, PurchaseLine.Quantity);

        // [WHEN] Open Reservation page.
        ReservationFromProductionOrderComponents(PurchaseLine."No.");

        // [THEN] Verify various Quantities on Reservation page.Verification done in ReservationPageHandler.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,InboundOutboundHandler')]
    [Scope('OnPrem')]
    procedure ReservedQuantityOnTransferLine()
    var
        Item: Record Item;
        Location: Record Location;
        TransferLine: Record "Transfer Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Reserved Quantity should be automatically adjusted on Transfer Line when Quantity is modified.

        // [GIVEN] Create and post Item Journal Line, Transfer Order.
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateItem(Item."Replenishment System"::Purchase),
          Location.Code, LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateAndPostTransferOrderWithReservation(TransferLine, ItemJournalLine."Item No.", Location.Code, ItemJournalLine.Quantity);

        // [WHEN] Modify Quantity on Transfer Line.
        TransferLine.Validate(Quantity, TransferLine."Quantity Shipped");
        TransferLine.Modify(true);

        // [THEN] Verify Reserved Quantity is updated automatically.
        TransferLine.CalcFields("Reserved Quantity Outbnd.");
        TransferLine.TestField("Reserved Quantity Outbnd.", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure VSTF6819()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemUnitOfMeasure1: Record "Item Unit of Measure";
        LotNo: Code[50];
        LotNo1: Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Item tracked by Lot No. with multiple units of measure can be reserved on sales order

        // [GIVEN] Create item with multiple UOM, add inventory.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 0.45);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure1, Item."No.", 10.8);

        LotNo := LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Lot No."), DATABASE::"Item Journal Line");
        PostItemJournalLineWithUOMAndLot(Item."No.", 4, ItemUnitOfMeasure, TrackingOption::AssignGivenLotNo, LotNo);
        PostItemJournalLineWithUOMAndLot(Item."No.", 4, ItemUnitOfMeasure, TrackingOption::AssignGivenLotNo, LotNo);
        PostItemJournalLineWithUOMAndLot(Item."No.", 10, ItemUnitOfMeasure1, TrackingOption::AssignGivenLotNo, LotNo);

        LotNo1 := LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Lot No."), DATABASE::"Item Journal Line");
        PostItemJournalLineWithUOMAndLot(Item."No.", 4, ItemUnitOfMeasure, TrackingOption::AssignGivenLotNo, LotNo1);
        PostItemJournalLineWithUOMAndLot(Item."No.", 4, ItemUnitOfMeasure, TrackingOption::AssignGivenLotNo, LotNo1);
        PostItemJournalLineWithUOMAndLot(Item."No.", 10, ItemUnitOfMeasure1, TrackingOption::AssignGivenLotNo, LotNo1);

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 10);
        SalesLine.Validate("Unit of Measure Code", ItemUnitOfMeasure1.Code);
        SalesLine.Modify(true);
        LibrarySales.AutoReserveSalesLine(SalesLine);

        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateTrackedSalesLine(SalesHeader, Item."No.", 4, ItemUnitOfMeasure.Code);
        CreateTrackedSalesLine(SalesHeader, Item."No.", 4, ItemUnitOfMeasure.Code);
        CreateTrackedSalesLine(SalesHeader, Item."No.", 10, ItemUnitOfMeasure1.Code);

        // [WHEN] Post sales order
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Reserved qty on first sales line.
        SalesLine.CalcFields("Reserved Quantity");
        Assert.AreEqual(SalesLine.Quantity, SalesLine."Reserved Quantity", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedQuantityOnSalesLineAfterUpdatingQuantity()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Reserved Quantity on Sales Line should be updated when Quantity is updated.

        // [GIVEN] Create Item, create and post Item Journal Line, create Sales Order.
        Initialize();
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateAndModifyItem(Item."Costing Method"::FIFO), '',
          LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateSalesDocument(SalesLine, ItemJournalLine."Item No.", '', ItemJournalLine.Quantity - 1);

        // [WHEN] Update Quantity on Sales Line.
        UpdateQuantityOnSalesLine(SalesLine."Document No.", ItemJournalLine.Quantity);

        // [THEN] Verify Reserved Quantity on Sales LIne.
        SalesLine.Find();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure ReservedQuantityOnSalesLineWithItemReference()
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemQuantity: Decimal;
    begin
        // [SCENARIO] Reference Quantity if Item Reference No. is set before Qunatity

        // [GIVEN] Setup Item and Create Item Reference
        Initialize();

        ItemQuantity := LibraryRandom.RandInt(5);
        CreateItemWithItemReference(Item, Item."Assembly Policy"::"Assemble-to-Order", ItemReference);

        // [WHEN] Update Quantity on Sales Line.
        CreateSalesDocumentWithItemReference(SalesLine, '', ItemQuantity, ItemReference);

        // [THEN] Verify Reserved Quantity on Sales LIne.
        Assert.AreEqual(
          ItemQuantity, SalesLine."Reserved Quantity", SalesLine.FieldCaption("Reserved Quantity"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservedQuantityOnSalesLineAfterUpdatingItemNo()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Quantity is automatically Reserved when Item No is updated on Sales Line.

        // [GIVEN] Create Item, create and post Item Journal Line, create Sales Order and cancel Reservation.
        Initialize();
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateAndModifyItem(Item."Costing Method"::FIFO), '',
          LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateSalesDocument(SalesLine, ItemJournalLine."Item No.", '', ItemJournalLine.Quantity - 1);
        UpdateQuantityOnSalesLine(SalesLine."Document No.", ItemJournalLine.Quantity);
        CancelReservationOnSalesOrder(SalesLine."No.");
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateAndModifyItem(Item."Costing Method"::FIFO), '',
          LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Update Item No. on Sales Line.
        SalesLine.Find();
        SalesLine.Validate("No.", ItemJournalLine."Item No.");
        SalesLine.Modify(true);

        // [THEN] Verify Quantity is automatically Reserved when Item No is updated.
        UpdateQuantityOnSalesLine(SalesLine."Document No.", ItemJournalLine.Quantity);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveTransferOrderAgainstSalesOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferRoute: Record "Transfer Route";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] No error message appears when Receive a Transfer Order with Item Tracking and Reordering Policy is Order for Item.

        // [GIVEN] Create Item, create Transfer Order using Planning Worksheet and Ship with Tracking.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        CreateAndModifyTransferRoute(TransferRoute);
        CreateAndModifyStockkeepingUnit(Item."No.", TransferRoute."Transfer-to Code", TransferRoute."Transfer-from Code");
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", TransferRoute."Transfer-from Code",
          LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateAndReleaseSalesOrder(Item."No.", TransferRoute."Transfer-to Code", ItemJournalLine.Quantity);
        CalculateNetChangePlanAndCarryOutActionMsg(Item);
        AssignTrackingAndShipTransferOrder(TransferHeader, TransferRoute."Transfer-from Code", TransferRoute."Transfer-to Code");

        // [WHEN] Receive Transfer Order.
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Transfer Order is deleted.
        Assert.IsFalse(TransferHeader.Get(TransferHeader."No."), OrderDeletionErr);
    end;

    [Test]
    [HandlerFunctions('ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure AutoReservOnSalesLineAfterExplodeBOM()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Item should be automatically reserved on Sales Line after exploding BOM.

        // [GIVEN] Create Item, create and post Item Journal Lne, create Sales Order.
        Initialize();
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", CreateAndModifyItem(Item."Costing Method"::FIFO), '',
          LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        CreateSalesDocument(SalesLine, CreateBOMComponent(ItemJournalLine."Item No."), '', ItemJournalLine.Quantity);

        // [WHEN] Explode BOM on Sales Line.
        CODEUNIT.Run(CODEUNIT::"Sales-Explode BOM", SalesLine);

        // [THEN] Reserved quantity is equal to sales line quantity
        SalesLine.SetRange("No.", ItemJournalLine."Item No.");
        SalesLine.FindFirst();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ExplodeBomHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingIsDeletedOnExplodedAssembledItem()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
    begin
        // [FEATURE] [Sales] [Explode BOM] [Item Tracking]
        // [SCENARIO 205830] Item tracking should be deleted on sales line with assembled item after Explode BOM action is run for it.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Lot-tracked assembled item "I".
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, LibraryInventory.CreateItemNo(), Item."No.", '', 0, LibraryRandom.RandInt(5), true);

        // [GIVEN] Item "I" is in stock.
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, Item."No.", TrackingOption::AssignLotNo, '', LibraryRandom.RandIntInRange(11, 20));

        // [GIVEN] Sales line for "I" with item tracking.
        CreateSalesOrderWithItemTracking(SalesLine, Item."No.", '', LibraryRandom.RandInt(10));

        // [WHEN] Explode BOM on the sales line.
        LibrarySales.ExplodeBOM(SalesLine);

        // [THEN] The sales line for the assembled item "I" is cleared.
        SalesLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(SalesLine);

        // [THEN] The item tracking is removed.
        ReservEntry.Init();
        ReservEntry.SetRange("Item No.", Item."No.");
        Assert.RecordIsEmpty(ReservEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostWhseRcptOnSalesRetOrder()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Put Away is registered successfully when using Put-away Unit Of Measure on Item.

        // [GIVEN] Create Item, create Location, post Warehouse Receipt on Sales Return Order.
        Initialize();
        Item.Get(CreateItem(Item."Replenishment System"::Purchase));
        ModifyUnitOfMeasureOnItem(Item);
        CreateWarehouseLocation(Location);
        PostWhseRcptAndCreateWhseShpt(SalesHeader, Item."No.", Location.Code);
        DocumentNo := PostSalesReturnOrderUsingCopyDocument(SalesHeader, Location.Code, Item."No.");

        // [WHEN] Register Put Away.
        RegisterWarehouseActivity(
          DocumentNo, WarehouseActivityHeader.Type::"Put-away", Location.Code, WarehouseActivityLine."Action Type"::Place);

        // [THEN] Put Away is registered successfully.
        VerifyRegisteredWhseActivity(WarehouseActivityHeader.Type::"Put-away", Location.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandlerForReservation,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPartialInvtPickOnProdOrder()
    var
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PostedInvtPickHeader: Record "Posted Invt. Pick Header";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Location on posted Inventory Pick should be equal to location in production order after posting partial Pick from Production Order.

        // [GIVEN] Create and post Item Journal LIne, create Production Order, Production Order Component with Item Tracking and Reservation.
        Initialize();
        CreateAndPostItemJournalLineWithIT(ItemJournalLine);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ItemJournalLine."Item No.", ItemJournalLine.Quantity,
          ItemJournalLine."Location Code");
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        CreateProdOrderComponentWithITAndReserv(
          ProductionOrder, ItemJournalLine."Item No.", ItemJournalLine."Location Code", TrackingOption::SelectEntries);
        LibraryVariableStorage.Enqueue(PickCreatedMsg);

        // [GIVEN] Create Inventory Pick, update Quantity To Handle on Warehouse Activity , post Inventory Activity partially.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);
        SetQtyToHandleWhseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", ItemJournalLine."Location Code",
          ProductionOrder."No.", WarehouseActivityLine."Action Type"::" ");
        WarehouseActivityHeader.SetRange(
          "No.",
          FindWarehouseActivityNo(
            WarehouseActivityLine, ProductionOrder."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick",
            ItemJournalLine."Location Code", WarehouseActivityLine."Action Type"::" "));
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [WHEN] Post Inventory Pick for remaining Quantity.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);

        // [THEN] Inventory Pick is posted from Production Order.
        PostedInvtPickHeader.SetRange("Source No.", ProductionOrder."No.");
        PostedInvtPickHeader.FindFirst();
        PostedInvtPickHeader.TestField("Location Code", ItemJournalLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvtPickFromProdOrderWithoutReserv()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Message 'Nothing To Create' when creating Inventory Pick from Production Order Without Reservation on Production Component.

        // [GIVEN] Create Item, create and refresh Production Order, create Production Order Component.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndPostPurchaseOrderWithIT(PurchaseLine, Item."No.", Location.Code);
        CreateAndRefreshProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, CreateItem(Item."Replenishment System"::"Prod. Order"),
          PurchaseLine.Quantity, Location.Code);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        CreateProdOrderComponent(ProdOrderComponent, ProductionOrder, Item."No.", Location.Code, LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(NothingToCreateErr);

        // [WHEN] Create Inventory Pick from Production Order.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Prod. Consumption", ProductionOrder."No.", false, true, false);

        // [THEN] Message 'Nothing To Create' when creating Inventory Pick from Production Order.Verification done in Message Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerForReservation,ReservationPageHandler,ItemTrackingListPageHandler,WhseSourceCreateDocumentReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPartialWhsePickOnProdOrder()
    var
        Item: Record Item;
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
        PickNo: Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Warehouse Pick should be registered after posting partial Pick from Production Order.

        // [GIVEN] Create Item, Location, crreate and post Warehouse Receipt.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        CreateWarehouseLocation(Location);
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        CreateAndPostWhseReceipt(PurchaseLine);
        RegisterWarehouseActivity(
          PurchaseLine."Document No.", WarehouseActivityHeader.Type::"Put-away", PurchaseLine."Location Code",
          WarehouseActivityLine."Action Type"::Place);

        // [GIVEN] Create and Refresh Production Order
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", PurchaseLine.Quantity, Location.Code);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");

        // [GIVEN] Create Production Component with Item Tracking and Reservation.
        CreateProdOrderComponentWithITAndReserv(ProductionOrder, Item."No.", Location.Code, TrackingOption::SetLotNo);
        WarehouseSetup.Get();
        PickNo := NoSeries.PeekNextNo(WarehouseSetup."Whse. Pick Nos.");
        LibraryVariableStorage.Enqueue(StrSubstNo(PickActivityMsg, PickNo));  // Enqueue for Message Handler.

        // [GIVEN] Create Warehouse Pick, update Quantity To Handle on Warehouse Activity , register Warehouse Pick partially.
        ProductionOrder.CreatePick(UserId, 0, false, false, false);  // SetBreakBulkFilter False,DoNotFillQtyToHandle False,PrintDocument False
        SetQtyToHandleWhseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, Location.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Take);
        SetQtyToHandleWhseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, Location.Code, ProductionOrder."No.",
          WarehouseActivityLine."Action Type"::Place);
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityHeader.Type::Pick, PurchaseLine."Location Code",
          WarehouseActivityLine."Action Type"::Take);

        // [WHEN] Post Warehouse Pick for remaining Quantity.
        RegisterWarehouseActivity(
          ProductionOrder."No.", WarehouseActivityHeader.Type::Pick, PurchaseLine."Location Code",
          WarehouseActivityLine."Action Type"::Take);

        // [THEN] Pick is registered successfully.
        VerifyRegisteredWhseActivity(WarehouseActivityHeader.Type::Pick, Location.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvPickOnTransferOrderWithIT()
    var
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [SCENARIO] Transfer Order deletion message after post Pick Away created from Transfer Order.

        // [GIVEN] Create Item Journal Line and Post, Transfer Order and Release, Create Pick and Post.
        Initialize();
        CreateAndPostItemJournalLineWithIT(ItemJournalLine);
        CreateAndReleaseTransferOrder(TransferLine, ItemJournalLine."Location Code", ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        LibraryVariableStorage.Enqueue(PickCreatedMsg);  // Enqueue for Message Handler.
        CreateAndPostWarehouseActivity(WarehouseActivityLine, TransferLine, false, true);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryVariableStorage.Enqueue(2);  // Enqueue option value for PostMenuHandler.
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeletedMsg, TransferHeader."No."));  // Enqueue for Message Handler.

        // [WHEN] Post Transfer Receipt.
        PostTransferReceipt(TransferLine."Document No.");

        // [THEN] Deletion message while Transfer Receipt by Message Handler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ILEAfterPostingSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Verify ILE After Posting Sales Order with Reservation and Item Tracking.

        // [GIVEN] Create Item and Create Sales Order with reserve the Quantity.
        Initialize();
        SetupforPostingDemand(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // [WHEN] Post Sales Order with Item Tracking.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Verify Item Ledger Entry.
        VerifyItemLedgerEntry(PostedDocumentNo, FindLotNoFromReservationEntry(SalesLine."No."), -1 * SalesLine.Quantity, SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveEntryAfterPostingSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Item should be reserved after posting Sales Order with Reservation and Item Tracking.

        // [GIVEN] Create Item with Item Tracking,Create and Post Item Journal Line,Create Sales Order with Resevation Order and Post Sales Order.
        Initialize();
        SetupforPostingDemand(SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // [WHEN] Post Sales Order with Item Tracking.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Verify Reservation Entry.
        VerifyReservationEntry(SalesLine."No.", SalesLine.Quantity, DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithSpecificReservationsLot()
    var
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Order Tracking]
        // [SCENARIO] Item should be reserved when Item Created with Order Tracking Policy and Create and Post Sales Order With Tracking and with Reservation.

        // [GIVEN] Create and Post Item Journal Line,Create Sale Order with Item Tracking.
        Initialize();
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, CreateItemWithOrderTrackingPolicy(), TrackingOption::AssignLotNo, '', LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        CreateSalesDocument(SalesLine, ItemJournalLine."Item No.", '', ItemJournalLine.Quantity / 2);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries); // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.

        // [WHEN] Reserve the quantity.
        SalesLine.ShowReservation();

        // [THEN] Verify Reservation Entry.
        VerifyReservationEntry(ItemJournalLine."Item No.", ItemJournalLine.Quantity / 2, DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithNonSpecificReservationsLot()
    var
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Order Tracking]
        // [SCENARIO] Item should be reserved when Item Created with Order Tracking Policy and Sales Order with Reservation.

        // [GIVEN] Create Item and Create and Post Item Journal Line.
        Initialize();
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, CreateItemWithOrderTrackingPolicy(), TrackingOption::AssignLotNo, '', LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        CreateSalesDocument(SalesLine, ItemJournalLine."Item No.", '', ItemJournalLine.Quantity / 2);
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.

        // [WHEN] Reserve the quantity.
        SalesLine.ShowReservation();

        // [THEN] Verify Reservation Entry.
        VerifyReservationEntry(ItemJournalLine."Item No.", ItemJournalLine.Quantity / 2, DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithShipmentAndSpecificReservationLot()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        ItemJournalLine: Record "Item Journal Line";
        PostedDocumentNo: Code[20];
        LotNo: Code[50];
    begin
        // [FEATURE] [Order Tracking]
        // [SCENARIO] Verify Item Ledger Entry when Item Created with Order Tracking Policy and Create and Post Sales Order with Item Tracking.

        // [GIVEN] Create Item and Create and Post Item Journal Line and Create Sales Order.
        Initialize();
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, CreateItemWithOrderTrackingPolicy(), TrackingOption::AssignLotNo, '', LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        CreateSalesOrderWithITAndReserve(SalesLine, ItemJournalLine."Item No.", '', ItemJournalLine.Quantity / 2);
        LotNo := FindLotNoFromReservationEntry(ItemJournalLine."Item No.");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // [WHEN] Post Sales Order.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Verify Item Ledger Entry.
        VerifyItemLedgerEntry(PostedDocumentNo, LotNo, -1 * SalesLine.Quantity, ItemJournalLine."Item No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithUpdateLotNoOnSalesOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Error Message After Creating Sales Order with Item Tracking.

        // [GIVEN] Create Item,Create and Post Item Jouurnal Line,Create Sales Order with Item Tracking.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, Item."No.", TrackingOption::AssignLotNo, '', LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        CreateSalesOrderWithITAndReserve(SalesLine, Item."No.", '', ItemJournalLine.Quantity / 2);
        CreateSalesDocument(SalesLine2, Item."No.", '', ItemJournalLine.Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SetLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        LibraryVariableStorage.Enqueue(AvailabilityWarningMsg);
        SalesLine2.OpenItemTrackingLines();
        SalesHeader.Get(SalesLine2."Document Type", SalesLine2."Document No.");

        // [WHEN] Reserve the quantity.
        LibraryVariableStorage.Enqueue(ReservationDisruptedWarningMsg);
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Verify Expected Error.
        LotNo := FindLotNo(Item."No.", '');
        Assert.ExpectedError(StrSubstNo(ItemTrackingLotNoErr, LotNo, Item."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservingNonSpecificITWithLotNo()
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Item should be reserved after Reserve quantity with Lot No.
        ReservingNonSpecificIT(LibraryUtility.GetGlobalNoSeriesCode(), '', false, true, TrackingOption::AssignLotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,EnterQuantitytoCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ReservingNonSpecificITWithSerialNo()
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Item should be reserved after Reserve quantity with Serial No.
        ReservingNonSpecificIT('', LibraryUtility.GetGlobalNoSeriesCode(), true, false, TrackingOption::AssignSerialNo);
    end;

    local procedure ReservingNonSpecificIT(SerialNos: Code[20]; LotNos: Code[20]; SNSpecific: Boolean; LNSpecific: Boolean; ItemTrackingOption: Option)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Tracked Item, Post Item Journal and create Sales Order with Reservation.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, SerialNos, LotNos, CreateItemTrackingCode(SNSpecific, LNSpecific));
        CreateAndPostItemJournalLineWithLot(ItemJournalLine, Item."No.", ItemTrackingOption, '', 2);  // Required at least 2 and avoid more than 2 Serial No.
        CreateSalesDocument(SalesLine, Item."No.", '', ItemJournalLine.Quantity / 2);  // Used blank for Location Code.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.
        SalesLine.ShowReservation();

        // Exercise.
        CreateSalesOrderWithITAndReserve(SalesLine2, Item."No.", '', ItemJournalLine.Quantity / 2);

        // [THEN] Verify Reservation Entry.
        VerifyReservationEntry(ItemJournalLine."Item No.", ItemJournalLine.Quantity / 2, DATABASE::"Item Ledger Entry", true);
        VerifyReservationEntry(ItemJournalLine."Item No.", -ItemJournalLine.Quantity / 2, DATABASE::"Sales Line", false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnReservingSpecificITWithLotNo()
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Error while reserving Sales Line against Full Reserved Item with Lot No.
        ReservingSpecificIT('', LibraryUtility.GetGlobalNoSeriesCode(), false, true, TrackingOption::AssignLotNo, TrackingOption::SetLotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler,EnterQuantitytoCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnReservingSpecificITWithSerialNo()
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Error while reserve Sales Line against Full Reserved Item with Serial No.
        ReservingSpecificIT(
          LibraryUtility.GetGlobalNoSeriesCode(), '', true, false, TrackingOption::AssignSerialNo, TrackingOption::SetSerialNo);
    end;

    local procedure ReservingSpecificIT(SerialNos: Code[20]; LotNos: Code[20]; SNSpecific: Boolean; LNSpecific: Boolean; ItemTrackingOption: Option; TrackingOption2: Option)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Tracked Item, Post Item Journal and create 2 Sales Order and Reserved with same Lot No/Serial No.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, CreateItemTrackingCode(SNSpecific, LNSpecific));
        CreateAndPostItemJournalLineWithLot(ItemJournalLine, Item."No.", ItemTrackingOption, '', 1);  // Required 1 due to avoid multiple Serial No.
        CreateSalesOrderWithITAndReserve(SalesLine, Item."No.", '', ItemJournalLine.Quantity);
        CreateSalesDocument(SalesLine2, Item."No.", '', ItemJournalLine.Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption2);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarningMsg);  // Enqueue value for ConfirmHandler.
        SalesLine2.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue value for ConfirmHandlerForReservation.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.

        // Exercise.
        asserterror SalesLine2.ShowReservation();

        // [THEN] Verify Error while Sales Line reserve.
        Assert.ExpectedError(ReservationErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure ReservingNonSpecificITWithWhseReceipt()
    var
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking] [Warehouse Receipt]
        // [SCENARIO] Item should be reserved after reserve Item with Lot on Sales Order which have been registered through WMS.

        // [GIVEN] Create Item, Location, create and post Warehouse Receipt.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        CreateWarehouseLocation(Location);
        CreatePurchaseOrder(PurchaseLine, Item."No.", Location.Code);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        CreateAndPostWhseReceipt(PurchaseLine);
        RegisterWarehouseActivity(
          PurchaseLine."Document No.", WarehouseActivityLine."Activity Type"::"Put-away", PurchaseLine."Location Code",
          WarehouseActivityLine."Action Type"::Place);

        // [GIVEN] Create Sales Order and Reserve.
        CreateSalesDocument(SalesLine, Item."No.", Location.Code, PurchaseLine.Quantity / 2);  // Required partial quantity.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.
        SalesLine.ShowReservation();

        // Exercise.
        CreateSalesOrderWithITAndReserve(SalesLine2, Item."No.", Location.Code, PurchaseLine.Quantity / 2);  // Required partial quantity.

        // [THEN] Verify Rerservation Entry after reserve Item with Lot on Sales Order.
        VerifyReservationEntry(SalesLine."No.", SalesLine.Quantity, DATABASE::"Item Ledger Entry", true);
        VerifyReservationEntry(SalesLine."No.", -SalesLine.Quantity, DATABASE::"Sales Line", false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservingPartlyReshuffleIT()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Reservation entry with Surplus status should be created after reserving non-specific on Sales Order.
        Initialize();
        Qty := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Create Tracked Item, Post Item Journal and create Sales Order and Reserved with Lot No.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, Item."No.", TrackingOption::AssignLotNo, '', Qty);
        LotNos[1] := FindLotNo(Item."No.", '');

        CreateSalesOrderWithITAndReserve(SalesLine, Item."No.", '', ItemJournalLine.Quantity / 2);  // Required partial quantity.

        // [GIVEN] another Sales Order with non-specific Reservation and Post Item Journal Line with more quantity and Lot No.
        CreateSalesDocument(SalesLine2, Item."No.", '', ItemJournalLine.Quantity / 2);  // Required partial quantity.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.
        SalesLine2.ShowReservation();
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, Item."No.", TrackingOption::AssignLotNo, '', Qty);
        LotNos[2] := FindLotNo(Item."No.", '');

        // Exercise.
        CreateSalesDocument(SalesLine, Item."No.", '', ItemJournalLine.Quantity);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNos[1], Qty / 2);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNos[2], Qty / 2);
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] Verify Reservation Entry with Surplus stauts.
        FindReservationEntry(ReservationEntry, SalesLine."No.", DATABASE::"Sales Line", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.TestField("Quantity (Base)", -SalesLine2.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithItemChargeAssignment()
    var
        Item: Record Item;
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CreditAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify General Ledger Entry With Posted Purchase Order With Item Charge Assignment.

        // [GIVEN] Create Purchase Order with Item Charge.
        Initialize();
        CreatePurchaseOrder(PurchaseLine, CreateAndModifyItem(Item."Costing Method"::Standard), '');  // Blank value for Location.
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        CreditAmount :=
          (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") +
          ((PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VATPostingSetup."VAT %") / 100;
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, LibraryInventory.CreateItemChargeNo(), '',
          LibraryRandom.RandInt(10), PurchaseLine.Type::"Charge (Item)");  // Using Random Quantity and Blank value for Location.
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        CreditAmount +=
          (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") +
          ((PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * VATPostingSetup."VAT %") / 100;
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.",
          PurchaseLine."No.");

        // [WHEN] Post Purchase order.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Verify General Ledger Entry.
        VerifyGeneralLedgerEntry(DocumentNo, CreditAmount);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTransferOrderForSalesReservationWithLot()
    var
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Item Tracking] [Transfer Order]
        // [SCENARIO] Item with lot tracking and 'Reserve' option 'Always' is automatically reserved on inventory after posting a transfer order
        Initialize();

        // [GIVEN] Create and post Item Journal Line. Create and release Transfer Order. Create Sales Order with automatic reservation, Quantity = 10
        CreateTrackedAndReservedTransferOrder(
          TransferLine, TrackingOption::AssignLotNo, '', LibraryUtility.GetGlobalNoSeriesCode(), LibraryRandom.RandIntInRange(10, 20));
        // [GIVEN] Post transfer shipment
        PostTransferOrderForSalesReservationWithIT(TransferLine, false, true);

        // [WHEN] Post Transfer Receipt.
        PostTransferReceipt(TransferLine."Document No.");

        // [THEN] Sales demand is reserved against Item Ledger Entry, reserved quantity = 10
        VerifyReservationEntry(TransferLine."Item No.", TransferLine.Quantity, DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,EnterQuantitytoCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostTransferOrderForSalesReservationWithSerial()
    var
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Item Tracking] [Transfer Order]
        // [SCENARIO] Item with serial no. tracking and 'Reserve' option 'Always' is automatically reserved on inventory after posting a transfer order

        Initialize();

        // [GIVEN] Create and post Item Journal Line. Create and release Transfer Order. Create Sales Order with automatic reservation, Quantity = 1
        CreateTrackedAndReservedTransferOrder(TransferLine, TrackingOption::AssignSerialNo, LibraryUtility.GetGlobalNoSeriesCode(), '', 1);
        // [GIVEN] Post transfer shipment
        PostTransferOrderForSalesReservationWithIT(TransferLine, true, false);

        // [WHEN] Post Transfer Receipt.
        PostTransferReceipt(TransferLine."Document No.");

        // [THEN] Sales demand is reserved against Item Ledger Entry, reserved quantity = 1
        VerifyReservationEntry(TransferLine."Item No.", TransferLine.Quantity, DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostTransferOrderForSalesReservationWithLotPartialPick()
    var
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Item Tracking] [Transfer Order]
        // [SCENARIO] Item with lot tracking and 'Reserve' option 'Always' is automatically reserved on inventory after partially posting a transfer order
        Initialize();

        // [GIVEN] Create and post Item Journal Line. Create and release Transfer Order. Create Sales Order with automatic reservation, Quantity = 10
        CreateTrackedAndReservedTransferOrder(
          TransferLine, TrackingOption::AssignLotNo, '', LibraryUtility.GetGlobalNoSeriesCode(), LibraryRandom.RandIntInRange(10, 20));
        // [GIVEN] Update Quanitty to Ship on transfer order, new quantity = 4
        TransferLine.Validate("Qty. to Ship", LibraryRandom.RandInt(TransferLine.Quantity - 1));
        TransferLine.Modify(true);
        // [GIVEN] Post transfer shipment
        PostTransferOrderForSalesReservationWithIT(TransferLine, false, true);

        // [WHEN] Post Transfer Receipt.
        PostTransferReceipt(TransferLine."Document No.");

        // [THEN] Sales demand reservation is split: 4 pcs are reserved against Item Ledger Entry, 6 - from Transfer Line
        TransferLine.Find();
        VerifyReservationEntry(TransferLine."Item No.", TransferLine."Quantity Received", DATABASE::"Item Ledger Entry", true);
        VerifyReservationEntry(TransferLine."Item No.", TransferLine."Qty. to Ship", DATABASE::"Transfer Line", true);
    end;

    local procedure PostTransferOrderForSalesReservationWithIT(TransferLine: Record "Transfer Line"; Serial: Boolean; Lot: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesOrderWithAutoReservation(
          SalesLine, TransferLine."Item No.", TransferLine."Transfer-to Code", TransferLine.Quantity);

        // Create and post Invt. Pick.
        LibraryVariableStorage.Enqueue(PickCreatedMsg); // Enqueue for MessageHandler.
        CreateAndPostWarehouseActivity(WarehouseActivityLine, TransferLine, Serial, Lot);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,InboundOutboundHandler2')]
    [Scope('OnPrem')]
    procedure ReserveInboundOnTransferOrder()
    var
        Item: Record Item;
        Location: Record Location;
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
    begin
        // [FEATURE] [Transfer Order]
        // [SCENARIO] Transfer Order cannot be Reserved Inbound when the Receipt Date is later than the Shipment Date on Sales Order.
        // Verify the value of Reserved Quantity Inbnd. is 0.

        // [GIVEN] Create Transfer Order and update the Receipt Date on Transfer Order later than WORKDATE.
        Initialize();
        CreateTransferOrder(
          TransferLine, LibraryWarehouse.CreateLocation(Location), LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        TransferLine.Validate("Receipt Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        TransferLine.Modify(true);

        // [GIVEN] Create Sales Order.
        CreateSalesDocument(
          SalesLine, Item."No.", TransferLine."Transfer-to Code", TransferLine.Quantity);

        // [WHEN] Reserve on Transfer Order.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine); // Enqueue value for ReservationPageHandler.
        asserterror TransferLine.ShowReservation();

        // [THEN] Reservation Inbound on Transfer Line cannot be reserved sucessfully.
        Assert.ExpectedError(ReservationErr);

        // [THEN] Reserved Quantity Inbound is 0.
        TransferLine.CalcFields("Reserved Quantity Inbnd.");
        TransferLine.TestField("Reserved Quantity Inbnd.", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler,ItemTrackingListPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure ReservedQuantityInPurchaseLineWithItemTrackingQtyDecreased()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        OriginalQty: Decimal;
        Qty: Decimal;
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Item is completely reserved in Purchase Line when increasing and then decreasing quantity in Item Tracking line.

        // [GIVEN] Create a Purchase Order and a Sales Order, assign the same Lot No in Item Tracking Lines for both orders
        Initialize();
        SetupITEntriesForPurchAndSalesWithSameLotNo(SalesLine, PurchaseLine, LotNo);

        // [GIVEN] Update Shipment Date, reserve the Sales Order with Purchase Order
        SalesLine.Validate("Shipment Date", CalcDate('<10D>', SalesLine."Shipment Date"));
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText()); // Enqueue value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine); // Enqueue value for ReservationPageHandler.
        SalesLine.ShowReservation();

        // [GIVEN] Increase Quantity in purchase line
        OriginalQty := PurchaseLine.Quantity;
        Qty := PurchaseLine.Quantity + LibraryRandom.RandInt(10);
        PurchaseLine.Validate(Quantity, Qty);
        PurchaseLine.Modify(true);

        // [GIVEN] Increase Quantity (Base) in purchase Item Tracking Lines
        UpdateQuantityBaseInPurchaseItemTrackingLines(PurchaseLine, Qty);

        // [WHEN] Change back Quantity (Base) in purchase Item Tracking Lines
        UpdateQuantityBaseInPurchaseItemTrackingLines(PurchaseLine, OriginalQty);

        // [THEN] Reserved Quantity is correct - it change back to the original quantity
        VerifyReservedQuantityInPurchaseLine(PurchaseLine, OriginalQty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ReservationPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandler,ItemTrackingListPageHandler')]
    [Scope('OnPrem')]
    procedure ItemReservedOnSalesLineWithOpenWhsePick()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Item Tracking] [Warehouse Pick]
        // [SCENARIO 374993] It should be possible to reserve a tracked item when there is a warehouse pick for this item

        Initialize();

        // [GIVEN] Item with serial no. tracking
        // [GIVEN] Create purchase order, assign serial no. and put away the item
        CreatePurchaseOrderWithItemTrackingOnWarehouseLocation(PurchaseLine, true, false, TrackingOption::AssignSerialNo);

        // [GIVEN] Create sales order, select serial no. and create a warehouse pick
        CreateSalesOrderWithTrackingAndCreatePick(PurchaseLine, SalesLine);

        // [WHEN] Reserve inventory stock for the sales order
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] Reservation entry is created
        VerifyReservationEntry(SalesLine."No.", 1, DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantitytoCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAutoReservedOnSalesOrderAfterPickRegistered()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Item Tracking] [Warehouse Pick]
        // [SCENARIO 375206] Item should be automatically reserved on a sales order line after registering a pick document for the order

        Initialize();

        // [GIVEN] Item with serial no. tracking
        // [GIVEN] Create purchase order, assign serial no. and put away the item
        CreatePurchaseOrderWithItemTrackingOnWarehouseLocation(PurchaseLine, true, false, TrackingOption::AssignSerialNo);

        // [GIVEN] Create sales order, select serial no. and create a warehouse pick
        CreateSalesOrderWithTrackingAndCreatePick(PurchaseLine, SalesLine);

        // [WHEN] Register Pick
        RegisterWarehouseActivity(
          SalesLine."Document No.", WhseActivityLine."Activity Type"::Pick,
          SalesLine."Location Code", WhseActivityLine."Action Type"::Place);

        // [THEN] Reservation entry is created
        VerifyReservationEntry(SalesLine."No.", 1, DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservationDeletedWhenWhseShipmentDeleted()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Item Tracking] [Warehouse Pick] [Warehouse Shipment]
        // [SCENARIO 377462] Reservation entry created implicitly by posting warehouse pick should be deleted when corresponding warehouse shipment is deleted

        Initialize();

        // [GIVEN] Item with lot no. tracking
        // [GIVEN] Create purchase order, assign lot no. and put away the item
        CreatePurchaseOrderWithItemTrackingOnWarehouseLocation(PurchaseLine, false, true, TrackingOption::AssignLotNo);

        // [GIVEN] Create sales order, create warehouse shipment without lot no., create a warehouse pick
        PostWhseRcptCreateSalesOrder(PurchaseLine, SalesLine);
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");

        // [GIVEN] Set lot no. on all pick lines
        SetLotNoOnWarehousePickLines(SalesLine);

        // [GIVEN] Register pick
        RegisterWarehouseActivity(
          SalesLine."Document No.", WarehouseActivityLine."Activity Type"::Pick,
          SalesLine."Location Code", WarehouseActivityLine."Action Type"::Place);

        // [WHEN] Delete warehouse shipment
        DeleteWarehouseShipment(SalesLine."Location Code");

        // [THEN] Reservation entry created by posting warehouse pick is deleted
        VerifyReservation(SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservationDeletedWhenWhseShipmentDeletedAfterSplitPlace()
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Item Tracking] [Warehouse Pick] [Warehouse Shipment]
        // [SCENARIO 377462] Reservation entry created implicitly by posting warehouse pick should be deleted when corresponding warehouse shipment is deleted when pick quantity is split in two parts

        Initialize();

        // [GIVEN] Item with lot no. tracking
        // [GIVEN] Create purchase order, assign lot no. and put away the item
        CreatePurchaseOrderWithItemTrackingOnWarehouseLocation(PurchaseLine, false, true, TrackingOption::AssignLotNo);

        // [GIVEN] Create sales order, create warehouse shipment without lot no., create a warehouse pick
        PostWhseRcptCreateSalesOrder(PurchaseLine, SalesLine);
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");

        // [GIVEN] Split "Place" action in warehouse pick in two parts
        FindWarehouseActivityNo(
          WarehouseActivityLine, SalesLine."Document No.", WarehouseActivityLine."Activity Type"::Pick, SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::Place);
        SplitWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine.Quantity / 2);

        // [GIVEN] Set lot no. on all pick lines
        SetLotNoOnWarehousePickLines(SalesLine);

        // [GIVEN] Register pick
        RegisterWarehouseActivity(
          SalesLine."Document No.", WarehouseActivityLine."Activity Type"::Pick,
          SalesLine."Location Code", WarehouseActivityLine."Action Type"::Place);

        // [WHEN] Delete warehouse shipment
        DeleteWarehouseShipment(SalesLine."Location Code");

        // [THEN] Reservation entry created by posting warehouse pick is deleted
        VerifyReservation(SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure TrackingInfoAddedByWhsePickDeletedWhenWhseShipmentDeleted()
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesLine: Record "Sales Line";
        I: Integer;
    begin
        // [FEATURE] [Item Tracking] [Warehouse Pick] [Warehouse Shipment]
        // [SCENARIO 377573] Tracking information in reservation entry added by posting warehouse pick should be deleted when warehouse shipment is deleted

        // [GIVEN] Item with lot no. tracking
        // [GIVEN] Create purchase order, Quantity = "X", assign lot no. = "L"
        Initialize();
        CreatePurchaseOrderWithItemTrackingOnWarehouseLocation(PurchaseLine, false, true, TrackingOption::AssignLotNo);

        // [GIVEN] Create warehouse receipt
        CreateWarehouseReceipt(PurchaseLine);

        // [GIVEN] Set "Qty. to Receive" = "X" / 2, post receipt
        FindWarehouseReceiptLine(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseLine."Document No.");
        WarehouseReceiptLine.Validate("Qty. to Receive", WarehouseReceiptLine.Quantity / 2);
        WarehouseReceiptLine.Modify(true);

        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseLine."Document No.");
        // [GIVEN] Post remaining receipt quantity
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseLine."Document No.");

        // [GIVEN] Register all put-aways
        for I := 1 to 2 do
            RegisterWarehouseActivity(
              PurchaseLine."Document No.", WarehouseActivityHeader.Type::"Put-away", PurchaseLine."Location Code",
              WarehouseActivityLine."Action Type"::Place);

        // [GIVEN] Create sales order and autoreserve all
        CreateSalesDocument(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        ReleaseSalesOrder(SalesLine."Document Type", SalesLine."Document No.");

        // [GIVEN] Create warehouse pick, assign lot no. = "L"
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");
        SetLotNoOnWarehousePickLines(SalesLine);

        // [GIVEN] Register warehouse pick
        RegisterWarehouseActivity(
          SalesLine."Document No.", WarehouseActivityLine."Activity Type"::Pick,
          SalesLine."Location Code", WarehouseActivityLine."Action Type"::Place);

        // [WHEN] Reopen and delete warehouse shipment
        DeleteWarehouseShipment(SalesLine."Location Code");

        // [THEN] Lot No. is removed from reservation entries
        VerifyBlankLotNoInReservationEntries(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LotItemAutoReservedOnSalesOrderAfterPickRegistered()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Item Tracking] [Warehouse Pick]
        // [SCENARIO 378608] Lot tracked Item should be automatically reserver on a sales order line after registering a pick document for the order

        Initialize();

        // [GIVEN] Item with Lot no. tracking
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        CreateWarehouseLocation(Location);

        // [GIVEN] Create purchase order, assign Lot no. and put away the item
        CreatePurchaseOrderWithItemTracking(
          PurchaseLine, Item."No.", Location.Code, TrackingOption::AssignLotNo);

        // [GIVEN] Create sales order, select Lot no. and create a warehouse pick
        CreateSalesOrderWithTrackingAndCreatePick(PurchaseLine, SalesLine);

        // [WHEN] Register Pick
        RegisterWarehouseActivity(
          SalesLine."Document No.", WhseActivityLine."Activity Type"::Pick,
          SalesLine."Location Code", WhseActivityLine."Action Type"::Place);

        // [THEN] Reservation entry is created
        VerifyReservationEntry(Item."No.", SalesLine.Quantity, DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LotItemAutoreservedAfterPartialPick()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [Warehouse] [Pick] [Item Tracking]
        // [SCENARIO 379746] Picked quantity sould be autoreserved on sales order when registering a partial pick with lot tracking
        Initialize();

        // [GIVEN] Item "I" with lot tracking
        // [GIVEN] Post inventory of 10 pcs of item "I"
        CreatePurchaseOrderWithItemTrackingOnWarehouseLocation(PurchaseLine, false, true, TrackingOption::AssignLotNo);
        // [GIVEN] Create sales order for 10 pcs of item "I" and create a warehouse pick
        CreateSalesOrderWithTrackingAndCreatePick(PurchaseLine, SalesLine);

        FindWarehouseActivityNo(
          WhseActivityLine, SalesLine."Document No.", WhseActivityLine."Activity Type"::Pick,
          SalesLine."Location Code", WhseActivityLine."Action Type"::Place);

        // [GIVEN] Set "Qty. to Handle" = 2 in pick
        WhseActivityLine.SetRange("Action Type");
        WhseActivityLine.FindSet();
        repeat
            WhseActivityLine.Validate("Qty. to Handle", WhseActivityLine."Qty. to Handle" / 4);
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;

        // [WHEN] Register pick
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // [THEN] 2 pcs of item "I" are reserved in sales order
        VerifyReservationEntry(SalesLine."No.", WhseActivityLine."Qty. to Handle", DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LotItemAutoreservedAfterSplitLineAndPick()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        WhseActivityLine: Record "Warehouse Activity Line";
        WhseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Warehouse] [Pick] [Item Tracking]
        // [SCENARIO 379746] Picked quantity should be autoreserved on sales order when pick line is split and registered
        Initialize();

        // [GIVEN] Item "I" with lot tracking
        // [GIVEN] Post inventory of 10 pcs of item "I"
        CreatePurchaseOrderWithItemTrackingOnWarehouseLocation(PurchaseLine, false, true, TrackingOption::AssignLotNo);

        // [GIVEN] Create sales order for 10 pcs of item "I" and create a warehouse pick
        CreateSalesOrderWithTrackingAndCreatePick(PurchaseLine, SalesLine);

        FindWarehouseActivityNo(
          WhseActivityLine, SalesLine."Document No.", WhseActivityLine."Activity Type"::Pick,
          SalesLine."Location Code", WhseActivityLine."Action Type"::Place);

        // [GIVEN] Split pick line. Line 1: quantity = 2, qty. to handle = 2, line 2: quantity = 8, qty. to handle = 0
        SplitWarehouseActivityLine(WhseActivityLine, WhseActivityLine."Qty. to Handle" / 4);

        // [WHEN] Register pick
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // [THEN] 2 pcs of item "I" are reserved in sales order
        VerifyReservationEntry(SalesLine."No.", WhseActivityLine."Qty. to Handle", DATABASE::"Item Ledger Entry", true);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ConfirmHandlerForReservation')]
    [Scope('OnPrem')]
    procedure LotSpecificReservationFromItemEntryWithTrackingAndSurplus()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        ConfirmOption: Option SerialSpecificTrue,SerialSpecificFalse;
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Calculate Regenerative Plan] [Lot-for-Lot] [Sales]
        // [SCENARIO 215656] When a user runs lot-specific reservation for sales line with assigned Lot No. in item tracking, the resulting reservation entries should contain that Lot No.
        Initialize();

        // [GIVEN] Lot-tracked item "I" with "lot-for-lot" reordering policy.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // [GIVEN] Update inventory of item "I". Lot No. = "L", Quantity = "Q".
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, Item."No.", TrackingOption::AssignLot, '', LibraryRandom.RandIntInRange(11, 20));
        LotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo));

        // [GIVEN] Sales Order for "I". Quantity = "q" < "Q".
        CreateSalesDocument(SalesLine, Item."No.", '', LibraryRandom.RandInt(10));

        // [GIVEN] Regenerative plan is calculated for "I". Item Tracking is established between item entry and sales order line.
        // [GIVEN] Additional reservation entry with Type = Surplus (Quantity = "Q" - "q") is created for excessive quantity in inventory.
        Item.SetRange("No.", Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [GIVEN] Set lot "L" in item tracking on the sales line.
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Reserve lot "L" for the sales line.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ConfirmOption::SerialSpecificTrue);
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] The reservation entries created for the sales line have Lot No. = "L".
        FindReservationEntry(
          ReservationEntry, Item."No.", DATABASE::"Sales Line", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, -SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservationEntriesAreDeletedOnSalesLineSetForSpecialOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Sales] [Special Order]
        // [SCENARIO 215902] Reservation entries should be deleted on Sales Line when it is set for Special Order.
        Initialize();

        // [GIVEN] Item with Lot-for-Lot reordering policy.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // [GIVEN] Purchase and Sales Order for the item.
        CreatePurchaseOrder(PurchaseLine, Item."No.", '');
        CreateSalesDocument(SalesLine, Item."No.", '', PurchaseLine.Quantity);

        // [GIVEN] Regenerative Plan is calculated for the item. Reservation entries representing order tracking between the sales and the purchase are created.
        Item.SetRange("No.", Item."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());
        FindReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line", ReservationEntry."Reservation Status"::Tracking);

        // [WHEN] Select Purchasing Code for Special Order on the sales line.
        LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);

        // [THEN] Reservation entries are deleted.
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DisruptedReservWarningNotRaisedWhenPostingPurchReturnDoesNotRuinOtherDocReserve()
    var
        Item: Record Item;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order]
        // [SCENARIO 216536] Return Purchase not affecting other document's reservation should be posted without asking a user to confirm possible disruption of reservation.
        Initialize();
        ExecuteConfirmHandler();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Item "I" with 2 * "X" pcs. in inventory.
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", 2 * Qty);

        // [GIVEN] Return Purchase Order "RO1" for "X" pcs of "I" is fully reserved from the inventory.
        CreatePurchaseReturnOrderWithReservedLine(PurchaseHeader[1], PurchaseLine[1], Item."No.", Qty);

        // [GIVEN] Return Purchase Order "RO2" for "X" pcs of "I" is fully reserved from the inventory.
        CreatePurchaseReturnOrderWithReservedLine(PurchaseHeader[2], PurchaseLine[2], Item."No.", Qty);

        // [WHEN] Post "RO2" with Ship option.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, false);

        // [THEN] No confirm message is raised during posting.

        // [THEN] "RO2" is shipped.
        PurchaseLine[2].Find();
        PurchaseLine[2].TestField("Return Qty. Shipped", Qty);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure DisruptedReservWarningNotRaisedWhenPostingPurchReturnRuinsOtherDocReserve()
    var
        Item: Record Item;
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order]
        // [SCENARIO 216536] Return Purchase that affects other document's reservation should not be posted if a user does not confirm possible disruption of reservation.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Item "I" with 2 * "X" pcs. in inventory.
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", 2 * Qty);

        // [GIVEN] Return Purchase Order "RO1" for "X" pcs of "I" is fully reserved from the inventory.
        CreatePurchaseReturnOrderWithReservedLine(PurchaseHeader[1], PurchaseLine[1], Item."No.", Qty);

        // [GIVEN] Return Purchase Order "RO2" for "X" + 1 pcs of "I" is partially reserved from the inventory. Reserved Qty. = "X". 1 pc is not reserved.
        CreatePurchaseReturnOrderWithReservedLine(PurchaseHeader[2], PurchaseLine[2], Item."No.", Qty + 1);

        // [WHEN] Post "RO2" with Ship option.
        Commit();
        LibraryVariableStorage.Enqueue(ReservationDisruptedWarningMsg);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, false);

        // [THEN] "RO2" is shipped.
        PurchaseLine[2].Find();
        PurchaseLine[2].TestField("Return Qty. Shipped", PurchaseLine[2].Quantity);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ItemTrackingListPageHandler,ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhsePickNotRegisteredWhenQtyInBinReservedForOtherDocument()
    var
        Item: Record Item;
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Pick] [Item Tracking]
        // [SCENARIO 215018] Warehouse pick cannot be registered when the lot is reserved for another shipment.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));

        // [GIVEN] Directed put-away and pick location, on which Always Create Pick Line is turned on.
        CreateWarehouseLocation(Location);
        Location.Validate("Always Create Pick Line", true);
        Location.Modify(true);

        // [GIVEN] "Q" pcs of the item tracked with lot no. "L" are placed into bin "B".
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", Qty, true);

        // [GIVEN] Sales order "SO1" for "Q" pcs of lot "L" is created and reserved from the inventory.
        CreateSalesOrderWithITAndReserve(SalesLine[1], Item."No.", Location.Code, Qty);
        SalesHeader[1].Get(SalesLine[1]."Document Type", SalesLine[1]."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader[1]);

        // [GIVEN] Another sales order "SO2" for same "Q" pcs of lot "L" is created.
        CreateSalesOrderWithManualSetLotNo(SalesLine[2], Item."No.", Location.Code, Qty, LotNo);
        SalesHeader[2].Get(SalesLine[2]."Document Type", SalesLine[2]."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader[2]);

        // [GIVEN] Warehouse shipment and pick is created for "SO2". Bin Code on the pick line is set to "B".
        CreatePick(Location.Code, SalesHeader[2]."No.");
        UpdateBinCodeOnWarehousePickLine(Location.Code, SalesHeader[2]."No.", Bin.Code);

        // [GIVEN] Warehouse shipment and pick is created for "SO1". Bin Code on the pick line is blank.
        CreatePick(Location.Code, SalesHeader[1]."No.");

        // [WHEN] Post the warehouse pick for "SO2".
        asserterror RegisterWarehouseActivity(
            SalesHeader[2]."No.", WarehouseActivityLine."Activity Type"::Pick, Location.Code,
            WarehouseActivityLine."Action Type"::Take);

        // [THEN] The error message arises, reading that the pick cannot be registered since the lot is reserved for another document.
        Assert.ExpectedError(StrSubstNo(LotReservedForAnotherDocErr, LotNo));
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityToReserveForPlanningComponentIsCalculatedBasedOnExpectedQuantity()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PlanningComponent: Record "Planning Component";
    begin
        // [FEATURE] [Planning Component]
        // [SCENARIO 223147] "Qty. to Reserve" for planning component should be equal to the "Expected Quantity" on Reservation page.
        Initialize();

        // [GIVEN] Purchased item "C".
        CompItem.Get(CreateItem(CompItem."Replenishment System"::Purchase));

        // [GIVEN] Production item "P". The production BOM includes "X" pcs of the component "C".
        // [GIVEN] The reordering policy of "P" is set to "Maximum Qty.", so it makes a demand for a production order.
        // [GIVEN] The demand of "P" is "Y" pcs, so the demand of the component "C" = "X" * "Y" pcs.
        ProdItem.Get(CreateItem(ProdItem."Replenishment System"::"Prod. Order"));
        ProdItem.Validate("Reordering Policy", ProdItem."Reordering Policy"::"Maximum Qty.");
        ProdItem.Validate("Maximum Inventory", LibraryRandom.RandInt(10));
        CreateAndCertifyProductionBOM(
          ProductionBOMHeader, CompItem."No.", CompItem."Base Unit of Measure", LibraryRandom.RandIntInRange(2, 10));
        UpdateProductionBOMOnItem(ProdItem, ProductionBOMHeader."No.");

        // [GIVEN] Regenerative plan is calculated in planning worksheet.
        ProdItem.SetRange("No.", ProdItem."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(ProdItem, WorkDate(), WorkDate());

        // [GIVEN] Item "C" is included in the list of planning components.
        PlanningComponent.SetRange("Item No.", CompItem."No.");
        PlanningComponent.FindFirst();

        // [WHEN] Show Reservation page for the planning component "C".
        LibraryVariableStorage.Enqueue(ReservationOption::VerifyQuantity);
        LibraryVariableStorage.Enqueue(PlanningComponent."Expected Quantity");
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(0);
        PlanningComponent.ShowReservation();

        // [THEN] "Qty. to Reserve" = "Expected Quantity" = "X" * "Y" on Reservation page.
        // Verification is done in ReservationPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationFromPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Sales]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation from a purchase line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Purchase order with two lines, each has its own lot no. ("L1" on the first line, "L2" on the second line).
        // [GIVEN] Quantity on each line = "Q".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty);
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            PurchaseLine.OpenItemTrackingLines();
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Sales order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L1" to the sales line.
        CreateSalesOrderWithManualSetLotNo(SalesLine, Item."No.", '', Qty, LotNo[1]);

        // [WHEN] Reserve the sales line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L1" are reserved from the purchase.
        ReservEntry.SetRange("Source Type", DATABASE::"Purchase Line");
        ReservEntry.SetRange("Lot No.", LotNo[1]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationFromSalesLine()
    var
        Item: Record Item;
        ReturnSalesHeader: Record "Sales Header";
        ReturnSalesLine: Record "Sales Line";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Sales] [Return Order] [Order]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation from a sales return line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Sales return order with two lines, each has its own lot no. ("L1" on the first line, "L2" on the second line).
        // [GIVEN] Quantity on each line = "Q".
        LibrarySales.CreateSalesHeader(ReturnSalesHeader, ReturnSalesHeader."Document Type"::"Return Order", '');
        for i := 1 to ArrayLen(LotNo) do begin
            LibrarySales.CreateSalesLine(ReturnSalesLine, ReturnSalesHeader, ReturnSalesLine.Type::Item, Item."No.", Qty);
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            ReturnSalesLine.OpenItemTrackingLines();
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Sales order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L1" to the sales line.
        CreateSalesOrderWithManualSetLotNo(SalesLine, Item."No.", '', Qty, LotNo[1]);

        // [WHEN] Reserve the sales line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L1" are reserved from the sales return.
        ReservEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservEntry.SetRange("Source ID", ReturnSalesHeader."No.");
        ReservEntry.SetRange("Lot No.", LotNo[1]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationFromTransferInbound()
    var
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ItemJournalLine: Record "Item Journal Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Transfer] [Sales]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation from an inbound transfer line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);

        // [GIVEN] Place two lots ("L1" and "L2") of the item in stock. Quantity of each lot = "Q".
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationFrom.Code, '', Qty);
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            ItemJournalLine.OpenItemTrackingLines(false);
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Transfer order with two lines, each has its own lot no. ("L1" on the first line, "L2" on the second line).
        // [GIVEN] Quantity on each line = "Q".
        // [GIVEN] Post the transfer shipment.
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
            LibraryVariableStorage.Enqueue(TrackingOption::ManualSetLotNo);
            LibraryVariableStorage.Enqueue(LotNo[i]);
            LibraryVariableStorage.Enqueue(Qty);
            TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        end;
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);

        // [GIVEN] Sales order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L1" to the sales line.
        CreateSalesOrderWithManualSetLotNo(SalesLine, Item."No.", LocationTo.Code, Qty, LotNo[1]);

        // [WHEN] Reserve the sales line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L1" are reserved from the inbound transfer.
        ReservEntry.SetRange("Source Type", DATABASE::"Transfer Line");
        ReservEntry.SetRange("Source Subtype", "Transfer Direction"::Inbound);
        ReservEntry.SetRange("Source ID", TransferHeader."No.");
        ReservEntry.SetRange("Lot No.", LotNo[1]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, Qty);
    end;


    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationFromProdOrderLine()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Production Order] [Sales]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation from a production order line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Two production orders, each has its own lot no. ("L1" on the first prod. order line, "L2" on the second line).
        // [GIVEN] Quantity on each production order = "Q".
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryManufacturing.CreateProductionOrder(
              ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.", Qty);
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

            ProdOrderLine.SetRange(Status, ProductionOrder.Status);
            ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderLine.FindFirst();
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            ProdOrderLine.OpenItemTrackingLines();
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Sales order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L1" to the sales line.
        CreateSalesOrderWithManualSetLotNo(SalesLine, Item."No.", '', Qty, LotNo[1]);

        // [WHEN] Reserve the sales line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L1" are reserved from the production order line.
        ReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Line");
        ReservEntry.SetRange("Lot No.", LotNo[1]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationFromAssemblyHeader()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Assembly] [Sales]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation from an assembly header.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Two assembly orders, each has its own lot no. ("L1" on the first assembly, "L2" on the second one).
        // [GIVEN] Quantity on each assembly order = "Q".
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), Item."No.", '', Qty, '');
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            AssemblyHeader.OpenItemTrackingLines();
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Sales order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L1" to the sales line.
        CreateSalesOrderWithManualSetLotNo(SalesLine, Item."No.", '', Qty, LotNo[1]);

        // [WHEN] Reserve the sales line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L1" are reserved from the assembly order.
        ReservEntry.SetRange("Source Type", DATABASE::"Assembly Header");
        ReservEntry.SetRange("Lot No.", LotNo[1]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationForTransferOutbound()
    var
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        PurchaseLine: Record "Purchase Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Transfer] [Purchase]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation for an outbound transfer line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Transfer order with two lines, each has its own lot no. ("L1" on the first line, "L2" on the second line).
        // [GIVEN] Quantity on each line = "Q".
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Qty);
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            LibraryVariableStorage.Enqueue(AvailabilityWarningMsg);
            TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Purchase order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L2" to the purchase line.
        CreatePurchaseOrderWithManualSetLotNo(PurchaseLine, Item."No.", LocationFrom.Code, Qty, LotNo[2]);

        // [WHEN] Reserve the purchase line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        PurchaseLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L2" are reserved to the outbound transfer.
        ReservEntry.SetRange("Source Type", DATABASE::"Transfer Line");
        ReservEntry.SetRange("Source Subtype", "Transfer Direction"::Outbound);
        ReservEntry.SetRange("Lot No.", LotNo[2]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationForProdOrderComponent()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseLine: Record "Purchase Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Prod. Order Component] [Purchase]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation for a production order component.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Production order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, LibraryInventory.CreateItemNo(), 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Two prod. order components, each tracked with its own lot no. (lot "L1" on the first component, lot "L2" on the second one).
        for i := 1 to ArrayLen(LotNo) do begin
            CreateProdOrderComponent(ProdOrderComponent, ProductionOrder, Item."No.", '', Qty);
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            LibraryVariableStorage.Enqueue(AvailabilityWarningMsg);
            ProdOrderComponent.OpenItemTrackingLines();
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Purchase order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L2" to the purchase line.
        CreatePurchaseOrderWithManualSetLotNo(PurchaseLine, Item."No.", '', Qty, LotNo[2]);

        // [WHEN] Reserve the purchase line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        PurchaseLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L2" are reserved to the production order component.
        ReservEntry.SetRange("Source Type", DATABASE::"Prod. Order Component");
        ReservEntry.SetRange("Lot No.", LotNo[2]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationForAssemblyLine()
    var
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        PurchaseLine: Record "Purchase Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Assembly] [Purchase]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation for an assembly line.
        Initialize();

        // [GIVEN] Lot-tracked item.
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Assembly order with two lines, each has its own lot no. ("L1" on the first line, "L2" on the second line).
        // [GIVEN] Quantity on each assembly line = "Q".
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), LibraryInventory.CreateItemNo(), '', Qty, '');
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryAssembly.CreateAssemblyLine(
              AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, Item."No.", Item."Base Unit of Measure", Qty, 1, '');
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            LibraryVariableStorage.Enqueue(AvailabilityWarningMsg);
            AssemblyLine.OpenItemTrackingLines();
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Purchase order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L2" to the purchase line.
        CreatePurchaseOrderWithManualSetLotNo(PurchaseLine, Item."No.", '', Qty, LotNo[2]);

        // [WHEN] Reserve the purchase line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        PurchaseLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L2" are reserved to the assembly line.
        ReservEntry.SetRange("Source Type", DATABASE::"Assembly Line");
        ReservEntry.SetRange("Lot No.", LotNo[2]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationForServiceLine()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        PurchaseLine: Record "Purchase Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Service Line] [Purchase]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation for a service line.
        Initialize();

        // [GIVEN] Lot-tracked item "I".
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        // [GIVEN] Two service orders, each has a service line with item "I".
        // [GIVEN] Assign lot no. to each of the service lines ("L1" on the service line in the first service order, "L2" on the service line in the second service order).
        // [GIVEN] Quantity on each service line = "Q".
        for i := 1 to ArrayLen(LotNo) do begin
            Clear(ServiceHeader);
            LibraryService.CreateServiceDocumentWithItemServiceLine(ServiceHeader, ServiceHeader."Document Type"::Order);
            LibraryService.CreateServiceLineWithQuantity(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.", Qty);
            LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
            LibraryVariableStorage.Enqueue(AvailabilityWarningMsg);
            ServiceLine.OpenItemTrackingLines();
            LotNo[i] := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LotNo[i]));
        end;

        // [GIVEN] Purchase order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L2" to the purchase line.
        CreatePurchaseOrderWithManualSetLotNo(PurchaseLine, Item."No.", '', Qty, LotNo[2]);

        // [WHEN] Reserve the purchase line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        PurchaseLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L2" are reserved to the service line.
        ReservEntry.SetRange("Source Type", DATABASE::"Service Line");
        ReservEntry.SetRange("Lot No.", LotNo[2]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, -Qty);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationFromMultiplePurchaseLineWithSameLotNo()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: array[2] of Code[20];
        Qty: Decimal;
        NoOfLots: Integer;
        i: Integer;
        j: Integer;
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Sales]
        // [SCENARIO 293255] The reservation engine considers specified lot no. when performing automatic reservation from several purchase lines.
        Initialize();

        // [GIVEN] Lot-tracked item "I".
        Qty := LibraryRandom.RandInt(10);
        LibraryItemTracking.CreateLotItem(Item);

        NoOfLots := ArrayLen(LotNo);
        for i := 1 to NoOfLots do
            LotNo[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Purchase order with two lines.
        // [GIVEN] Quantity on each line = 2 * "Q".
        // [GIVEN] Assign two lot nos. ("L1" and "L2") to each purchase line.
        // [GIVEN] Quantity of each lot = "Q".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        for i := 1 to ArrayLen(LotNo) do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Qty * NoOfLots);
            LibraryVariableStorage.Enqueue(TrackingOption::ManualSetMultipleLots);
            LibraryVariableStorage.Enqueue(NoOfLots);
            for j := 1 to ArrayLen(LotNo) do begin
                LibraryVariableStorage.Enqueue(LotNo[j]);
                LibraryVariableStorage.Enqueue(Qty);
            end;
            PurchaseLine.OpenItemTrackingLines();
        end;

        // [GIVEN] Sales order for "Q" pcs of the item.
        // [GIVEN] Assign lot no. "L1" to the sales line.
        CreateSalesOrderWithManualSetLotNo(SalesLine, Item."No.", '', Qty, LotNo[1]);

        // [WHEN] Reserve the sales line with specific lot no.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        SalesLine.ShowReservation();

        // [THEN] "Q" pcs of lot "L1" are reserved from the purchase order.
        ReservEntry.SetRange("Source Type", DATABASE::"Purchase Line");
        ReservEntry.SetRange("Lot No.", LotNo[1]);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, Qty * NoOfLots);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure LotSpecificAutoReservationFromPurchaseLineWithDifferentUoM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        ReservEntry: Record "Reservation Entry";
        LotNo: Code[50];
        Qty: Decimal;
        QtyPerUOM: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Purchase] [Sales] [Unit of Measure]
        // [SCENARIO 354060] The reservation engine considers specified lot no. and unit of measure when performing automatic reservation from a purchase line.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        QtyPerUOM := LibraryRandom.RandIntInRange(5, 10);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Lot-tracked item with base unit of measure "PCS" and alternate UoM "BOX". 1 "BOX" = 5 "PCS.
        LibraryItemTracking.CreateLotItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUOM);

        // [GIVEN] Set "Sales Unit of Measure" = "BOX" for the item.
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Sales order for 5 "BOX".
        // [GIVEN] Assign lot no. "L1" to the sales line.
        CreateSalesOrderWithManualSetLotNo(SalesLine, Item."No.", '', Qty, LotNo);

        // [GIVEN] Purchase order for 25 "PCS" (= 5 "BOX").
        // [GIVEN] Assign lot no. "L1" to the purchase line.
        CreatePurchaseOrderWithManualSetLotNo(PurchaseLine, Item."No.", '', Qty * QtyPerUOM, LotNo);

        // [WHEN] Reserve the purchase line with specific lot no. "L1".
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        PurchaseLine.ShowReservation();

        // [THEN] 25 pcs of lot "L1" are reserved from the purchase.
        ReservEntry.SetRange("Source Type", DATABASE::"Purchase Line");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange("Item No.", Item."No.");
        ReservEntry.SetRange("Lot No.", LotNo);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, Qty * QtyPerUOM);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostingInventoryPickAfterSplitAndAssignedLotAgainstReservation()
    var
        Location: Record Location;
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNos: array[2] of Code[20];
        Qty: Decimal;
        QtyToHandle: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item Tracking] [Inventory Pick]
        // [SCENARIO 310015] Posting inventory pick after splitting line and assigning lot no. when the source sales line has non-specific reservation.
        Initialize();

        Qty := LibraryRandom.RandIntInRange(50, 100);
        QtyToHandle := LibraryRandom.RandInt(10);

        // [GIVEN] Location with bin and required pick.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Lot-tracked item.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));

        // [GIVEN] Post two lots "L1", "L2" to the inventory. Quantity of each lot = 25.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin.Code, Qty);
        LibraryVariableStorage.Enqueue(TrackingOption::ManualSetMultipleLots);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));
        for i := 1 to ArrayLen(LotNos) do begin
            LotNos[i] := LibraryUtility.GenerateGUID();
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(Qty / ArrayLen(LotNos));
        end;
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create sales order for 50 pcs, reserve it from the inventory.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", Qty, Location.Code, WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create inventory pick.
        LibraryVariableStorage.Enqueue(PickCreatedMsg);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [GIVEN] Assign lot no. = "L2" on the pick line.
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Invt. Pick", Location.Code, SalesHeader."No.",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Lot No.", LotNos[2]);
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Set "Qty. to Handle" = 10 and split the line.
        SplitWarehouseActivityLine(WarehouseActivityLine, QtyToHandle);

        // [GIVEN] Delete the new pick line with quantity of 40 pcs.
        WarehouseActivityLine.Next();
        WarehouseActivityLine.Delete(true);
        NotificationLifecycleMgt.RecallAllNotifications();

        // [WHEN] Post the inventory pick.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::"Invt. Pick", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] 10 pcs on the sales order line has been shipped.
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", QtyToHandle);

        // [THEN] 15 pcs of lot "L2" remain reserved from the inventory to the sales line.
        ReservationEntry.SetSourceFilter(DATABASE::"Item Ledger Entry", 0, '', -1, true);
        ReservationEntry.SetRange("Lot No.", LotNos[2]);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Qty / 2 - QtyToHandle);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoReservationDisruptedOnPostingItemReclassJournal()
    var
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Reclassification] [Warehouse]
        // [SCENARIO 378280] Existing reservation is not disrupted and no warning is shown on posting item reclassification representing internal warehouse movement.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Location with two bins "B1" and "B2".
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        // [GIVEN] Post 10 pcs of an item to bin "B1".
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, Bin[1].Code, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create and reserve sales order for 10 pcs.
        CreateSalesOrderWithAutoReservation(SalesLine, Item."No.", Location.Code, Qty);

        // [GIVEN] Create item reclassification line to move 10 pcs from bin "B1" to bin "B2" within the same location.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Transfer);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer);
        ItemJournalLine.Validate("Item No.", Item."No.");
        ItemJournalLine.Validate("Location Code", Location.Code);
        ItemJournalLine.Validate("Bin Code", Bin[1].Code);
        ItemJournalLine.Validate("New Location Code", Location.Code);
        ItemJournalLine.Validate("New Bin Code", Bin[2].Code);
        ItemJournalLine.Validate(Quantity, Qty);
        ItemJournalLine.Modify(true);

        // [WHEN] Post the reclassification journal.
        LibraryVariableStorage.Enqueue(ReservationDisruptedWarningMsg);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] No confirmation message about reservation disruption is shown.
        Assert.AreEqual(ReservationDisruptedWarningMsg, LibraryVariableStorage.DequeueText(), '');

        // [THEN] The sales line remains reserved.
        SalesLine.Find();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField("Reserved Quantity", Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure SyncItemTrackingOnPartialPickWithReservedSalesLine()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        QtyOnHand: Decimal;
        QtyForSale: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Pick] [Sales]
        // [SCENARIO 381375] Synchronize item tracking from a partial warehouse pick to a sales line that has non-specific reservation.
        Initialize();
        QtyOnHand := LibraryRandom.RandIntInRange(50, 100);
        QtyForSale := LibraryRandom.RandIntInRange(10, 20);
        LotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Location set up for directed put-away and pick.
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);

        // [GIVEN] Lot-tracked item.
        // [GIVEN] Post 50 pcs to the inventory.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(QtyOnHand);
        LibraryWarehouse.UpdateInventoryInBinUsingWhseJournal(Bin, Item."No.", QtyOnHand, true);

        // [GIVEN] Sales order for 50 pcs but only 10 pcs are reserved from the inventory.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", QtyForSale, Location.Code, WorkDate());
        LibrarySales.AutoReserveSalesLine(SalesLine);
        SalesLine.Validate(Quantity, QtyOnHand);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create shipment and pick for the sales order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindLast();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Set lot no. = "L" and "Qty. to Handle" = 10 on the pick lines.
        UpdateLotAndQtyToHandleOnPickLine(WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, Item."No.", LotNo, QtyForSale);
        UpdateLotAndQtyToHandleOnPickLine(WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, Item."No.", LotNo, QtyForSale);

        // [WHEN] Register the warehouse pick.
        WarehouseActivityHeader.Get(WarehouseActivityHeader.Type::Pick, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] 10 pcs with lot "L" are reserved for the sales line.
        ReservationEntry.SetRange("Lot No.", LotNo);
        FindReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, -QtyForSale);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure EstablishingSpecificReservationForDocumentLineWithOrderTracking()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        Qty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Order Tracking] [Planning]
        // [SCENARIO 385519] Stan can establish a lot-specific reservation on sales line that is partially reserved from inventory and partially tracked from another supply.
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Lot-tracked item.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        // [GIVEN] Post 1 pc of the item to inventory. Assign lot "L".
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        PostItemJournalLineWithUOMAndLot(Item."No.", Qty, ItemUnitOfMeasure, TrackingOption::AssignGivenLotNo, LotNo);

        // [GIVEN] Create sales order for 2 pcs, auto reserve 1 pc, do not specify lot no.
        CreateSalesOrderWithAutoReservation(SalesLine, Item."No.", '', Qty);
        SalesLine.Validate(Quantity, 2 * Qty);
        SalesLine.Validate("Qty. to Ship", Qty);
        SalesLine.Modify(true);

        // [GIVEN] Purchase order for 1 pc.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', Item."No.", Qty, '', WorkDate());

        // [GIVEN] Calculate regenerative plan to establish order tracking between the purchase and the sales order.
        // [GIVEN] 1 pc on the sales line is now reserved from inventory and another 1 pc is tracked against the purchase.
        Item.SetRecFilter();
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate());

        // [WHEN] Open item tracking for the sales line and select lot no. "L".
        SalesLine.Find();
        LibraryVariableStorage.Enqueue(TrackingOption::AssignGivenLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        SalesLine.OpenItemTrackingLines();

        // [THEN] The reservation between the sales and inventory becomes lot-specific.
        FindReservationEntry(ReservationEntry, Item."No.", DATABASE::"Sales Line", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.TestField("Lot No.", LotNo);

        // [THEN] The sales order can be partially shipped.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure ItemTrackingOnSalesLineFromPickWithBreakbulk()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[50];
    begin
        // [FEATURE] [Item Tracking] [Pick] [Shipment] [Sales] [Breakbulk] [Unit of Measure]
        // [SCENARIO 388429] Item tracking is properly created from a pick with breakbulk lines.
        Initialize();

        // [GIVEN] Make sure warehouse shipment posting will be interrupted at the first error.
        WarehouseSetup.Get();
        WarehouseSetup.Validate(
          "Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify(true);

        // [GIVEN] Lot-tracked item with base unit of measure "PCS" and alternate unit of measure "BOX". 1 "BOX" = 100 "PCS"
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 100);

        // [GIVEN] Location with directed put-away and pick.
        CreateWarehouseLocation(Location);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);

        // [GIVEN] Create purchase order with two lines.
        // [GIVEN] 1st line: 5 "PCS", lot no. = "L1".
        // [GIVEN] 2nd line: 1 "BOX", lot no. = "L2".
        // [GIVEN] Release the order and post warehouse receipt.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithAlternateUOMAndLotTracking(PurchaseLine, LotNos[1], PurchaseHeader, Item."No.", Item."Base Unit of Measure", 5);
        CreatePurchaseLineWithAlternateUOMAndLotTracking(PurchaseLine, LotNos[2], PurchaseHeader, Item."No.", ItemUnitOfMeasure.Code, 1);
        CreateWarehouseReceipt(PurchaseLine);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");

        // [GIVEN] Open put-away and change the bin code where the lot "L2" is placed into.
        // [GIVEN] Register the put-away.
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Lot No.", LotNos[2]);
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", Location.Code, PurchaseHeader."No.",
          WarehouseActivityLine."Action Type"::Place);
        WarehouseActivityLine.Validate("Bin Code", Bin.Code);
        WarehouseActivityLine.Modify(true);
        RegisterWarehouseActivity(
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away", PurchaseHeader."Location Code",
          WarehouseActivityLine."Action Type"::Place);

        // [GIVEN] Sales order for 20 pcs.
        // [GIVEN] Release the order, create shipment and pick.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 20, Location.Code, WorkDate());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreatePick(Location.Code, SalesHeader."No.");

        // [GIVEN] Adjust the warehouse pick as follows:
        // [GIVEN] Pick 5 "PCS" of lot "L1", add lot "L2" to breakbulk lines, pick 10 "PCS" of lot "L2".
        WarehouseActivityLine.Reset();
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        ProcessNextWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, 5, 5, LotNos[1]);
        ProcessNextWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, 5, 5, LotNos[1]);
        ProcessNextWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, 1, 1, LotNos[2]);
        ProcessNextWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, 100, 100, LotNos[2]);
        ProcessNextWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Take, 15, 10, LotNos[2]);
        ProcessNextWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Action Type"::Place, 15, 10, LotNos[2]);

        // [WHEN] Register the pick.
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] The warehouse shipment can be posted.
        WarehouseShipmentHeader.Get(
          LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] The sales line is shipped for 15 "PCS".
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", 15);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    procedure PostingWhseShipmentAfterPartialPickWithZeroQtyToHandleLines()
    var
        WarehouseSetup: Record "Warehouse Setup";
        Location: Record Location;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNos: array[2] of Code[50];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Shipment] [Pick] [Item Tracking]
        // [SCENARIO 402334] Posting warehouse shipment after the pick is partially registered leaving some lots with "Qty. to Handle" = 0.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Make sure warehouse shipment posting will be interrupted at the first error.
        WarehouseSetup.Get();
        WarehouseSetup.Validate(
          "Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify(true);

        // [GIVEN] Location with directed put-away and pick.
        CreateWarehouseLocation(Location);

        // [GIVEN] Lot-tracked item.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));

        // [GIVEN] Purchase order with two items lines, each for 1 pc.
        // [GIVEN] Assign lots "L1" and "L2".
        // [GIVEN] Create and post warehouse receipt, register put-away.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithAlternateUOMAndLotTracking(
          PurchaseLine, LotNos[1], PurchaseHeader, Item."No.", Item."Base Unit of Measure", Qty);
        CreatePurchaseLineWithAlternateUOMAndLotTracking(
          PurchaseLine, LotNos[2], PurchaseHeader, Item."No.", Item."Base Unit of Measure", Qty);
        CreateWarehouseReceipt(PurchaseLine);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        RegisterWarehouseActivity(
          PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away", PurchaseHeader."Location Code",
          WarehouseActivityLine."Action Type"::Place);

        // [GIVEN] Sales order for 2 pcs.
        // [GIVEN] Select lots "L1" and "L2".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", 2 * Qty, Location.Code, WorkDate());
        LibraryVariableStorage.Enqueue(TrackingOption::ManualSetMultipleLots);
        LibraryVariableStorage.Enqueue(ArrayLen(LotNos));
        for i := 1 to ArrayLen(LotNos) do begin
            LibraryVariableStorage.Enqueue(LotNos[i]);
            LibraryVariableStorage.Enqueue(Qty);
        end;
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Release the sales order, create warehouse shipment and pick.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WarehouseShipmentHeader.Get(
          CreatePick(Location.Code, SalesHeader."No."));

        // [GIVEN] Set "Qty. to Handle" = 0 for lot "L1".
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Lot No.", LotNos[1]);
        WarehouseActivityLine.ModifyAll("Qty. to Handle", 0);
        WarehouseActivityLine.ModifyAll("Qty. to Handle (Base)", 0);

        // [WHEN] Partially register the pick (1 of 2 pcs).
        RegisterWarehouseActivity(
          SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick, SalesHeader."Location Code",
          WarehouseActivityLine."Action Type"::Place);

        // [THEN] The warehouse shipment for 1 pc can be successfully posted.
        WarehouseShipmentHeader.Find();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", Qty);

        // [THEN] The remaining 1 pc (lot "L1") can be picked and shipped.
        RegisterWarehouseActivity(
          SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick, SalesHeader."Location Code",
          WarehouseActivityLine."Action Type"::Place);
        WarehouseShipmentHeader.Find();
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
        SalesLine.Find();
        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CannotReserveProdOrderComponentForNonInventoryItem()
    var
        NonInventoryItem: Record Item;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [Non-Inventory Item] [Prod. Order Component]
        // [SCENARIO 426438] Non-inventory item cannot be reserved as prod. order component.
        Initialize();

        LibraryInventory.CreateNonInventoryTypeItem(NonInventoryItem);

        CreateAndPostPurchaseOrder(PurchaseLine, NonInventoryItem."No.", '');

        CreateAndCertifyProductionBOM(ProductionBOMHeader, PurchaseLine."No.", PurchaseLine."Unit of Measure Code", 1);
        Item.Get(CreateItem(Item."Replenishment System"::"Prod. Order"));
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");

        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item."No.", PurchaseLine.Quantity, '');

        asserterror ReservationFromProductionOrderComponents(PurchaseLine."No.");

        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(ReserveMustNotBeNeverErr);
    end;

    [Test]
    procedure CannotChangeReserveFieldOnSalesLineForServiceItem()
    var
        ServiceTypeItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Sales Order]
        // [SCENARIO 438168] You cannot change Reserve field on sales line for item of type = "Service".
        Initialize();

        LibraryInventory.CreateServiceTypeItem(ServiceTypeItem);
        CreateSalesDocument(SalesLine, ServiceTypeItem."No.", '', LibraryRandom.RandInt(10));

        asserterror SalesLine.Validate(Reserve, SalesLine.Reserve::Optional);

        Assert.ExpectedError(ReserveMustBeNeverErr);
    end;

    [Test]
    procedure CannotAutoReserveSalesLineForServiceItem()
    var
        ServiceTypeItem: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Non-Inventory Item] [Sales Order]
        // [SCENARIO 438168] You cannot auto reserve sales line for item of type = "Service".
        Initialize();

        LibraryInventory.CreateServiceTypeItem(ServiceTypeItem);
        CreateSalesDocument(SalesLine, ServiceTypeItem."No.", '', LibraryRandom.RandInt(10));

        asserterror LibrarySales.AutoReserveSalesLine(SalesLine);

        Assert.ExpectedError(ReserveMustBeNeverErr);
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Reservation IV");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Reservation IV");

        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        DisableAutomaticCostPosting();

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Warehouse Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Reservation IV");
    end;

    local procedure AssignTrackingAndShipTransferOrder(var TransferHeader: Record "Transfer Header"; TransferFromCode: Code[10]; TransferToCode: Code[10])
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Transfer-from Code", TransferFromCode);
        TransferLine.SetRange("Transfer-to Code", TransferToCode);
        TransferLine.FindFirst();
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    local procedure CalculateNetChangePlanAndCarryOutActionMsg(Item: Record Item)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcNetChangePlanForPlanWksh(Item, WorkDate(), WorkDate(), false);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CancelReservationOnSalesOrder(ItemNo: Code[20])
    var
        ReservationEntries: TestPage "Reservation Entries";
    begin
        LibraryVariableStorage.Enqueue(CancelReservationMsg);
        ReservationEntries.OpenEdit();
        ReservationEntries.FILTER.SetFilter("Item No.", ItemNo);
        ReservationEntries.CancelReservation.Invoke();
    end;

    local procedure CreateBOMComponent(ItemNo: Code[20]): Code[20]
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateBOMComponent(BOMComponent, Item."No.", BOMComponent.Type::Item, ItemNo, 1, '');
        exit(Item."No.");
    end;

    local procedure CreateItem(ReplenishmentSystem: Enum "Replenishment System"): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 1));  // Using Random value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithOrderTrackingPolicy(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateCustomer(): Code[20]
    begin
        exit(LibrarySales.CreateCustomerNo());
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QuantityPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndModifyItem(CostingMethod: Enum "Costing Method"): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem(Item."Replenishment System"::Purchase));
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Validate("Standard Cost", LibraryRandom.RandDec(100, 1));  // Using Random value for Standard Cost.
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 1));  // Using Random value for Last Direct Cost.
        Item.Validate("Costing Method", CostingMethod);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateAndModifyStockkeepingUnit(ItemNo: Code[20]; TransferToCode: Code[10]; TransferFromCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, TransferToCode, ItemNo, '');
        StockkeepingUnit.Validate("Replenishment System", StockkeepingUnit."Replenishment System"::Transfer);
        StockkeepingUnit.Validate("Reordering Policy", StockkeepingUnit."Reordering Policy"::Order);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, LocationCode);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode, LibraryRandom.RandInt(10), PurchaseLine.Type::Item);  // Using Random Quantity.
    end;

    local procedure CreateAndPostPurchaseOrderWithIT(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseOrderWithItemTracking(PurchaseLine, ItemNo, LocationCode, TrackingOption::AssignLotNo);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostTransferOrderWithReservation(var TransferLine: Record "Transfer Line"; ItemNo: Code[20]; LoactionCode: Code[10]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
    begin
        CreateTransferOrder(TransferLine, LoactionCode, ItemNo, Quantity);
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.
        TransferLine.ShowReservation();
        TransferLine.Validate("Qty. to Ship", TransferLine.Quantity / 2);  // Ship partial Quantity.
        TransferLine.Modify(true);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; TransferLine: Record "Transfer Line"; Serial: Boolean; Lot: Boolean)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Outbound Transfer", TransferLine."Document No.", false, true, false);
        FindAndUpdateWarehouseActivityLine(WarehouseActivityLine, TransferLine, Serial, Lot);
        WarehouseActivityLine.AutofillQtyToHandle(WarehouseActivityLine);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, true);
    end;

    local procedure CreateAndPostItemJournalLineWithIT(var ItemJournalLine: Record "Item Journal Line")
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Pick", true);
        Location.Validate("Prod. Consump. Whse. Handling", "Prod. Consump. Whse. Handling"::"Inventory Pick/Movement");
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, Item."No.", TrackingOption::AssignLotNo, Location.Code, LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
    end;

    local procedure CreateAndPostItemJournalLineWithLot(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ItemTrackingOption: Option; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LocationCode, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournalLineWithITAndReserve(var ItemJournalLine: Record "Item Journal Line"; SerialNos: Code[20]; LotNos: Code[20]; ItemTrackingOption: Option; Serial: Boolean; Lot: Boolean; Qty: Decimal)
    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
    begin
        LibraryInventory.CreateTrackedItem(Item, LotNos, SerialNos, CreateItemTrackingCode(Serial, Lot));
        ModifyReserveOptionOnItem(Item, Item.Reserve::Always);
        CreateLocationAndBin(Location, Bin);
        CreateAndPostItemJournalLineWithBin(ItemJournalLine, Item."No.", ItemTrackingOption, Location.Code, Bin.Code, Qty);
    end;

    local procedure CreateAndPostItemJournalLineWithBin(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; ItemTrackingOption: Option; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LocationCode, Quantity);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingOption); // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateLocationAndBin(var Location: Record Location; var Bin: Record Bin)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Pick", true);
        Location.Validate("Require Put-away", true);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode, Quantity, PurchaseLine.Type::Item);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrderWithLotItemTracking(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; var LotNo: Code[50])
    var
        DequeueVariable: Variant;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, ItemNo, LocationCode, Quantity, PurchaseLine.Type::Item);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLot); // Enqueue value for ItemTrackingLinesPageHandler.

        PurchaseLine.OpenItemTrackingLines();
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
    end;

    local procedure CreatePurchaseReturnOrderWithReservedLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order",
          LibraryPurchase.CreateVendorNo(), ItemNo, Qty, '', WorkDate());
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        PurchaseLine.ShowReservation();
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferLine: Record "Transfer Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
    begin
        CreateTransferOrder(TransferLine, LocationCode, ItemNo, Quantity);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20];
                                                                                                                Quantity: Decimal;
                                                                                                                LocationCode: Code[10])
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndReleaseSalesOrder(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, ItemNo, LocationCode, Quantity);
        ReleaseSalesOrder(SalesLine."Document Type", SalesLine."Document No.");
    end;

    local procedure CreateItemTrackingCode(SNSpecific: Boolean; LOTSpecific: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LOTSpecific);
        ItemTrackingCode.Validate("SN Warehouse Tracking", SNSpecific);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LOTSpecific);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreatePick(LocationCode: Code[10]; DocumentNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindLast();
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        exit(WarehouseShipmentHeader."No.");
    end;

    local procedure CreateProductionOrderAndReserveFromComponent(var PurchaseLine: Record "Purchase Line"; Status: Enum "Production Order Status")
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
    begin
        // Create and post Purchase Order.
        CreateAndPostPurchaseOrder(PurchaseLine, CreateItem(Item."Replenishment System"::Purchase), '');

        // Create Production BOM and update Production Item.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, PurchaseLine."No.", PurchaseLine."Unit of Measure Code", 1);
        Item.Get(CreateItem(Item."Replenishment System"::"Prod. Order"));
        UpdateProductionBOMOnItem(Item, ProductionBOMHeader."No.");

        // Create Production Order and reservation from Production Order Component.
        CreateAndRefreshProductionOrder(ProductionOrder, Status, Item."No.", PurchaseLine.Quantity, '');
        ReservationFromProductionOrderComponents(PurchaseLine."No.");
    end;

    local procedure CreateProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; QtyPer: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Validate("Quantity per", QtyPer);
        ProdOrderComponent.Validate("Location Code", LocationCode);
        ProdOrderComponent.Modify(true);
    end;

    local procedure CreateProdOrderComponentWithITAndReserv(ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; ItemTrackingOption: Option)
    var
        ProdOrderComponent: Record "Prod. Order Component";
        ConfirmOption: Option SerialSpecificTrue,SerialSpecificFalse;
    begin
        CreateProdOrderComponent(ProdOrderComponent, ProductionOrder, ItemNo, LocationCode, LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(ItemTrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        if ItemTrackingOption = TrackingOption::SetLotNo then
            LibraryVariableStorage.Enqueue(ProductionOrder.Quantity);  // Enqueue value for ItemTrackingLinesPageHandler.

        ProdOrderComponent.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue value for ConfirmHandlerForReservation.
        LibraryVariableStorage.Enqueue(ConfirmOption::SerialSpecificTrue);  // Enqueue value for ConfirmHandlerForReservation.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);
        ReservationFromProductionOrderComponents(ItemNo);
    end;

    local procedure CreatePurchaseOrderWithItemTracking(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; ItemTrackingOption: Option)
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, LocationCode);
        LibraryVariableStorage.Enqueue(ItemTrackingOption);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrderWithManualSetLotNo(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; LotNo: Code[50])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, '', ItemNo, Quantity, LocationCode, WorkDate() - 30);
        LibraryVariableStorage.Enqueue(TrackingOption::ManualSetLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(AvailabilityWarningMsg);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrderWithItemTrackingOnWarehouseLocation(var PurchaseLine: Record "Purchase Line"; SNSpecific: Boolean; LotSpecific: Boolean; ItemTrackingOption: Option)
    var
        Item: Record Item;
        Location: Record Location;
    begin
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(SNSpecific, LotSpecific));
        CreateWarehouseLocation(Location);
        CreatePurchaseOrderWithItemTracking(PurchaseLine, Item."No.", Location.Code, ItemTrackingOption);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Type: Enum "Purchase Line Type")
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Using Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineWithAlternateUOMAndLotTracking(var PurchaseLine: Record "Purchase Line"; var NewLotNo: Code[50]; PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Qty: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Qty);
        PurchaseLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
        PurchaseLine.OpenItemTrackingLines();
        NewLotNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(NewLotNo));
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithItemReference(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; ItemQuantity: Decimal; ItemReference: Record "Item Reference")
    begin
        CreateSalesDocument(SalesLine, ItemReference."Item No.", LocationCode, ItemQuantity);
        SalesLine.Validate("Item Reference No.", ItemReference."Reference No.");
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithAutoReservation(var SalesLine: Record "Sales Line"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);

        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CreateSalesOrderWithItemTracking(var SalesLine: Record "Sales Line"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateSalesDocument(SalesLine, No, LocationCode, Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());
    end;

    local procedure CreateSalesOrderWithManualSetLotNo(var SalesLine: Record "Sales Line"; No: Code[20]; LocationCode: Code[10]; Quantity: Decimal; LotNo: Code[50])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', No, Quantity, LocationCode, LibraryRandom.RandDate(30));

        LibraryVariableStorage.Enqueue(TrackingOption::ManualSetLotNo); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine."Quantity (Base)"); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarningMsg); // Enqueue value for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateSalesOrderWithTrackingAndCreatePick(var PurchaseLine: Record "Purchase Line"; var SalesLine: Record "Sales Line")
    begin
        PostWhseRcptCreateSalesOrder(PurchaseLine, SalesLine);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();
        CreatePick(SalesLine."Location Code", SalesLine."Document No.");
    end;

    local procedure CreateTrackedAndReservedTransferOrder(var TransferLine: Record "Transfer Line"; ItemTrackingOption: Option; SerialNos: Code[20]; LotNos: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateAndPostItemJournalLineWithITAndReserve(
          ItemJournalLine, SerialNos, LotNos, ItemTrackingOption, SerialNos <> '', LotNos <> '', Quantity);
        CreateAndReleaseTransferOrder(
          TransferLine, ItemJournalLine."Location Code", ItemJournalLine."Item No.", Quantity);
    end;

    [Normal]
    local procedure CreateTrackedSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Qty: Decimal; UnitOfMeasureCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SalesLine.Validate("Qty. to Ship", Qty / 2);
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries); // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateTransferOrder(var TransferLine: Record "Transfer Line"; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferHeader: Record "Transfer Header";
        LocationFrom: Record Location;
        LocationTo: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateInTransitLocation(LocationTo);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationCode, LocationFrom.Code, LocationTo.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
    end;

    local procedure CreateAndModifyTransferRoute(var TransferRoute: Record "Transfer Route")
    var
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationFrom);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationFrom.Code, LocationTo.Code);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        TransferRoute.Validate("In-Transit Code", LocationInTransit.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateAndPostWhseReceipt(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
    end;

    local procedure CreateWarehouseLocation(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        Location.Validate("Require Receive", true);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateWarehouseReceipt(PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure DeleteWarehouseShipment(LocationCode: Code[10])
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        LibraryVariableStorage.Enqueue(ItemsPickedMsg);
        WarehouseShipmentHeader.SetRange("Location Code", LocationCode);
        WarehouseShipmentHeader.FindFirst();
        LibraryWarehouse.ReopenWhseShipment(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Find();
        WarehouseShipmentHeader.Delete(true);
    end;

    local procedure DisableAutomaticCostPosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", false);
        InventorySetup.Modify(true);
    end;

    local procedure EnqueueValuesForReservationPageHandler(QtyToReserve: Decimal; TotalReservedQuantity: Decimal; TotalQuantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(QtyToReserve);
        LibraryVariableStorage.Enqueue(TotalReservedQuantity);
        LibraryVariableStorage.Enqueue(TotalQuantity);
    end;

    local procedure FindAndUpdateWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; TransferLine: Record "Transfer Line"; Serial: Boolean; Lot: Boolean)
    begin
        WarehouseActivityLine.SetRange("Location Code", TransferLine."Transfer-from Code");
        WarehouseActivityLine.FindFirst();
        if Lot then
            WarehouseActivityLine.Validate("Lot No.", FindLotNo(TransferLine."Item No.", TransferLine."Transfer-from Code"));
        if Serial then
            WarehouseActivityLine.Validate("Serial No.", FindSerialNo(TransferLine."Item No.", TransferLine."Transfer-from Code"));
        WarehouseActivityLine.Modify(true);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20])
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindLast();
    end;

    local procedure FindLotNo(ItemNo: Code[20]; LocationCode: Code[10]): Code[50]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
        exit(ItemLedgerEntry."Lot No.");
    end;

    local procedure FindSerialNo(ItemNo: Code[20]; LocationCode: Code[10]): Code[50]
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", ItemNo);
        exit(ItemLedgerEntry."Serial No.");
    end;

    local procedure FindLotNoFromReservationEntry(ItemNo: Code[20]): Code[50]
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationEntry(ReservationEntry, ItemNo, DATABASE::"Item Ledger Entry", ReservationEntry."Reservation Status"::Reservation);
        exit(ReservationEntry."Lot No.");
    end;

    local procedure FindReservationEntry(var ReservationEntry: Record "Reservation Entry"; ItemNo: Code[20]; SourceType: Integer; ReservationStatus: Enum "Reservation Status")
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.FindFirst();
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType, LocationCode, ActionType);
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type"): Code[20]
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
        exit(WarehouseActivityLine."No.");
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure ModifyUnitOfMeasureOnItem(Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 1);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Put-away Unit of Measure Code", Item."Base Unit of Measure");
        Item.Modify(true);
    end;

    local procedure ModifyReserveOptionOnItem(var Item: Record Item; Reserve: Enum "Reserve Method")
    begin
        Item.Validate(Reserve, Reserve);
        Item.Modify(true);
    end;

    [Normal]
    local procedure PostItemJournalLineWithUOMAndLot(ItemNo: Code[20]; Qty: Decimal; ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemTrackingOption: Option; LotNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, '', Qty);
        ItemJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingOption);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty * ItemUnitOfMeasure."Qty. per Unit of Measure");
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostSalesReturnOrderUsingCopyDocument(SalesHeader: Record "Sales Header"; LocationCode: Code[10]; ItemNo: Code[20]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, LocationCode);
        CreateAndPostWhseReceipt(PurchaseLine);
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", SalesInvoiceHeader."No.", true, false);  // Set TRUE for Include Header and FALSE for Recalculate Lines.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        PostWarehouseReceipt(WarehouseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.");
        exit(SalesHeader."No.");
    end;

    local procedure PostTransferReceipt(TransOrderNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
    begin
        TransferHeader.Get(TransOrderNo);
        LibraryInventory.PostTransferHeader(TransferHeader, false, true)
    end;

    local procedure PostWarehouseReceipt(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, SourceDocument, SourceNo);
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWhseRcptCreateSalesOrder(var PurchaseLine: Record "Purchase Line"; var SalesLine: Record "Sales Line")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
    begin
        CreateAndPostWhseReceipt(PurchaseLine);
        RegisterWarehouseActivity(
          PurchaseLine."Document No.", WarehouseActivityHeader.Type::"Put-away", PurchaseLine."Location Code",
          WarehouseActivityLine."Action Type"::Place);
        CreateSalesDocument(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure PostWhseRcptAndCreateWhseShpt(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        DocumentNo: Code[20];
    begin
        // Create and post Warehouse Receipt, create Sales Order and post Warehouse Shipment.
        CreatePurchaseOrder(PurchaseLine, ItemNo, LocationCode);
        PostWhseRcptCreateSalesOrder(PurchaseLine, SalesLine);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        DocumentNo := CreatePick(SalesLine."Location Code", SalesLine."Document No.");
        RegisterWarehouseActivity(
          SalesLine."Document No.", WarehouseActivityHeader.Type::Pick, SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::Place);
        WarehouseShipmentHeader.Get(DocumentNo);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);
    end;

    local procedure ProcessNextWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; Qty: Decimal; QtyToHandle: Decimal; LotNo: Code[50])
    begin
        WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField("Action Type", ActionType);
        WarehouseActivityLine.TestField(Quantity, Qty);

        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityHeader.SetRange(
          "No.", FindWarehouseActivityNo(WarehouseActivityLine, SourceNo, ActivityType, LocationCode, ActionType));
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SetupITEntriesForPurchAndSales(var SalesLine: Record "Sales Line"; ConfirmOption: Option)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCode(true, false));
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", Location.Code, LibraryRandom.RandInt(10));  // Take random for Quantity.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        CreateSalesOrderWithItemTracking(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(ConfirmOption);  // Enqueue value for ConfirmHandlerForReservation.
    end;

    local procedure SetupITEntriesForPurchAndSalesWithSameLotNo(var SalesLine: Record "Sales Line"; var PurchaseLine: Record "Purchase Line"; var LotNo: Code[50])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        CreatePurchaseOrderWithLotItemTracking(
          PurchaseHeader, PurchaseLine, Item."No.", Location.Code, LibraryRandom.RandInt(10), LotNo); // Take random for Quantity.
        CreateSalesOrderWithManualSetLotNo(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity, LotNo);
    end;

    local procedure ReleaseSalesOrder(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(DocumentType, DocumentNo);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure ReservationOnSalesLine(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndPostPurchaseOrder(PurchaseLine, CreateItem(Item."Replenishment System"::Purchase), Location.Code);
        CreateSalesDocument(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationFromCurrentLineHandler.
        SalesLine.ShowReservation();
    end;

    local procedure ReservationFromProductionOrderComponents(ItemNo: Code[20])
    var
        ProdOrderComponents: TestPage "Prod. Order Components";
    begin
        ProdOrderComponents.OpenView();
        ProdOrderComponents.FILTER.SetFilter("Item No.", ItemNo);
        ProdOrderComponents.Reserve.Invoke();
        ProdOrderComponents.Close();
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetLotNoOnWarehousePickLines(SalesLine: Record "Sales Line")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        TrackingSpecification: Record "Tracking Specification";
    begin
        TrackingSpecification.SetRange("Item No.", SalesLine."No.");
        TrackingSpecification.FindFirst();

        FindWarehouseActivityNo(
          WarehouseActivityLine, SalesLine."Document No.", WarehouseActivityLine."Activity Type"::Pick, SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::Place);

        WarehouseActivityLine.SetRange("Action Type");
        WarehouseActivityLine.FindSet(true);
        repeat
            WarehouseActivityLine.Validate("Lot No.", TrackingSpecification."Lot No.");
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure SetQtyToHandleWhseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ItemNo: Code[20]; ActionType: Enum "Warehouse Action Type")
    begin
        FindWhseActivityLine(WarehouseActivityLine, ActivityType, LocationCode, ItemNo, ActionType);
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity / 2);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure SetupforPostingDemand(var SalesLine2: Record "Sales Line")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true));
        CreateAndPostItemJournalLineWithLot(
          ItemJournalLine, Item."No.", TrackingOption::AssignLotNo, '', LibraryRandom.RandDec(10, 2));  // Use Random Value for Quantity.
        CreateSalesDocument(SalesLine, Item."No.", '', ItemJournalLine.Quantity / 2);
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.
        SalesLine.ShowReservation();
        CreateSalesDocument(SalesLine2, Item."No.", '', ItemJournalLine.Quantity / 2);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries); // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine2.OpenItemTrackingLines();
    end;

    local procedure SplitWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; NewQty: Decimal)
    begin
        WarehouseActivityLine.Validate("Qty. to Handle (Base)", NewQty);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);
    end;

    local procedure CreateItemWithItemReference(var Item: Record Item; AssemblyPolicy: Enum "Assembly Policy"; var ItemReference: Record "Item Reference")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Index: Integer;
    begin
        Item.Get(CreateAndModifyItem(Item."Costing Method"::Standard));
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", AssemblyPolicy);
        Item.Modify(true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5));
        for Index := 1 to LibraryRandom.RandIntInRange(3, 5) do
            CreateBOMComponent(Item."No.");

        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", ItemReference."Reference Type"::" ", '');
    end;

    local procedure CreateSalesOrderWithITAndReserve(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateSalesOrderWithItemTracking(SalesLine, ItemNo, LocationCode, Quantity);
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationPageHandler.
        SalesLine.ShowReservation();
    end;

    local procedure UpdateBinCodeOnWarehousePickLine(LocationCode: Code[10]; SourceNo: Code[20]; BinCode: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, LocationCode, SourceNo,
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateProductionBOMOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityOnSalesLine(DocumentNo: Code[20]; Quantity: Decimal)
    var
        SalesOrderSubform: TestPage "Sales Order Subform";
    begin
        SalesOrderSubform.OpenEdit();
        SalesOrderSubform.FILTER.SetFilter("Document No.", DocumentNo);
        SalesOrderSubform.Quantity.SetValue(Quantity);
        SalesOrderSubform.Close();
    end;

    local procedure UpdateQuantityBaseInPurchaseItemTrackingLines(var PurchaseLine: Record "Purchase Line"; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::UpdateQuantityBase); // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Qty); // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure UpdateLotAndQtyToHandleOnPickLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; LotNo: Code[50]; QtyToHandle: Decimal)
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Validate("Qty. to Handle", QtyToHandle);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure VerifyBlankLotNoInReservationEntries(SourceType: Integer; SourceSubtype: Option; SourceID: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", SourceSubtype);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetFilter("Lot No.", '<>%1', '');
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    local procedure VerifyGeneralLedgerEntry(DocumentNo: Code[20]; CreditAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        ActualAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter("Credit Amount", '<>%1', 0);
        GLEntry.FindSet();
        repeat
            ActualAmount += GLEntry."Credit Amount";
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(
          CreditAmount, ActualAmount, LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(ValidationErr, GLEntry."Credit Amount", CreditAmount));
    end;

    local procedure VerifyRegisteredWhseActivity(Type: Enum "Warehouse Activity Type"; LocationCode: Code[10])
    var
        RegisteredWhseActivityHdr: Record "Registered Whse. Activity Hdr.";
    begin
        RegisteredWhseActivityHdr.SetRange(Type, Type);
        RegisteredWhseActivityHdr.SetRange("Location Code", LocationCode);
        RegisteredWhseActivityHdr.FindFirst();
    end;

    local procedure VerifyReservation(ItemNo: Code[20])
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservationEntry: Record "Reservation Entry";
    begin
        TrackingSpecification.SetRange("Item No.", ItemNo);
        TrackingSpecification.FindFirst();

        ReservationEntry.Init();
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservationEntry.SetRange("Lot No.", '');
        Assert.RecordIsNotEmpty(ReservationEntry);

        ReservationEntry.SetRange("Lot No.", TrackingSpecification."Lot No.");
        Assert.RecordIsEmpty(ReservationEntry);

        ReservationEntry.SetRange("Source Type", DATABASE::"Item Ledger Entry");
        Assert.RecordIsNotEmpty(ReservationEntry);

        ReservationEntry.SetRange("Lot No.", '');
        Assert.RecordIsEmpty(ReservationEntry);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; Quantity: Decimal; SourceType: Integer; Positive: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        FindReservationEntry(ReservationEntry, ItemNo, SourceType, ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.TestField(Positive, Positive);
        ReservationEntry.TestField("Quantity (Base)", Quantity);
    end;

    local procedure VerifyReservedQuantityInPurchaseLine(PurchaseLine: Record "Purchase Line"; Qty: Decimal)
    begin
        PurchaseLine.CalcFields("Reserved Quantity");
        PurchaseLine.TestField("Reserved Quantity", Qty);
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; LotNo: Code[50]; Quantity: Decimal; ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Sale, ItemNo);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure ExecuteConfirmHandler()
    var
        ConfirmTxt: Text;
    begin
        ConfirmTxt := LibraryUtility.GenerateRandomText(30);
        LibraryVariableStorage.Enqueue(ConfirmTxt);
        if Confirm(ConfirmTxt) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForReservation(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
        OptionValue: Variant;
        ConfirmOption: Option;
        OptionString: Option SerialSpecificTrue,SerialSpecificFalse;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        ConfirmOption := OptionValue;  // To convert Variant into Option.
        case ConfirmOption of
            OptionString::SerialSpecificTrue:
                Reply := true;
            OptionString::SerialSpecificFalse:
                Reply := false;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantitytoCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure InboundOutboundHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;  // 1 for Outbound Reservation.
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure InboundOutboundHandler2(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2; // 2 for Inbound Reservation.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionValue: Variant;
        Quantity: Variant;
        LotNo: Variant;
        NoOfLots: Integer;
        i: Integer;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            TrackingOption::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingOption::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingOption::SetLotNo:
                begin
                    ItemTrackingLines."Lot No.".AssistEdit();
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            TrackingOption::SetSerialNo:
                begin
                    ItemTrackingLines."Serial No.".AssistEdit();
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            TrackingOption::AssignGivenLotNo:
                begin
                    LibraryVariableStorage.Dequeue(LotNo);
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            TrackingOption::AssignLot:
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
                end;
            TrackingOption::ManualSetLotNo:
                begin
                    LibraryVariableStorage.Dequeue(LotNo);
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            TrackingOption::UpdateQuantityBase:
                begin
                    LibraryVariableStorage.Dequeue(Quantity);
                    ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                end;
            TrackingOption::ManualSetMultipleLots:
                begin
                    NoOfLots := LibraryVariableStorage.DequeueInteger();
                    for i := 1 to NoOfLots do begin
                        LibraryVariableStorage.Dequeue(LotNo);
                        LibraryVariableStorage.Dequeue(Quantity);
                        ItemTrackingLines."Lot No.".SetValue(LotNo);
                        ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
                        ItemTrackingLines.Next();
                    end;
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
    procedure ItemTrackingListPageHandler(var ItemTrackingList: TestPage "Item Tracking List")
    begin
        ItemTrackingList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        OptionValue: Variant;
        QtyToReserve: Variant;
        TotalReservedQuantity: Variant;
        TotalQuantity: Variant;
        OptionString: Option ReserveFromCurrentLine,VerifyQuantity;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        ReservationOption := OptionValue;  // To convert Variant into Option.
        case ReservationOption of
            OptionString::ReserveFromCurrentLine:
                Reservation."Reserve from Current Line".Invoke();
            OptionString::VerifyQuantity:
                begin
                    LibraryVariableStorage.Dequeue(QtyToReserve);
                    LibraryVariableStorage.Dequeue(TotalReservedQuantity);
                    LibraryVariableStorage.Dequeue(TotalQuantity);
                    Reservation.QtyToReserveBase.AssertEquals(QtyToReserve);
                    Reservation.TotalReservedQuantity.AssertEquals(TotalReservedQuantity);
                    Reservation."Total Quantity".AssertEquals(TotalQuantity);
                end;
        end;
        Reservation.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ExplodeBomHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        // Take 1 for "Retrieve dimensions from components".
        Choice := 1;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseSourceCreateDocumentReportHandler(var WhseSourceCreateDocument: TestRequestPage "Whse.-Source - Create Document")
    begin
        WhseSourceCreateDocument.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;
}

