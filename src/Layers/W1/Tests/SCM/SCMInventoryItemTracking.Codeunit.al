codeunit 137260 "SCM Inventory Item Tracking"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Tracking] [SCM]
        isInitialized := false;
    end;

    var
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
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        RegisterJournalLine: Label 'Do you want to register the journal lines?';
        RegisterWhseMessage: Label 'The journal lines were successfully registered.You are now';
        AvailabilityWarining: Label 'You do not have enough inventory to meet the demand for items in one or more lines';
        ITConfirmMessage: Label 'Item tracking is defined for item';
        DeletionMessage: Label 'Do you want to delete it anyway?';
        DeleteSalesLineWhseShptError: Label 'The Sales Line cannot be deleted when a related Warehouse Shipment Line exists.';
        ReservEntryError: Label 'There is no Reservation Entry within the filter.';
        RequisitionLineError: Label 'There is no Requisition Line within the filter.';
        CannotMatchItemTrackingErr: Label 'Cannot match item tracking.\Document No.: %1, Line No.: %2, Item: %3 %4', Comment = '%1 - source document no., %2 - source document line no., %3 - item no., %4 - item description';
        SerialNoError: Label 'You must assign a serial number for item %1.', Comment = '%1 - Item No.';
        VariantMessage: Label 'Variant  cannot be fully applied.';
        CancelReservMessage: Label 'Do you want to cancel all reservations in the';
        TrackingPolicyMessage: Label 'The change will not affect existing entries.';
        WhseShptError: Label 'There is no Warehouse Shipment Line within the filter.';
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries,AssignLot,AssignLotNos,SetQtyToInvoice,AssignManualSN;
        WhseShpmtWasNotPostedErr: Label 'Warehouse Shipment cannot be posted.';
        ProdOrderCreatedMsg: Label 'Released Prod. Order';
        PostJournalQst: Label 'Do you want to post the journal lines?';
        JournalPostedMsg: Label 'The journal lines were successfully posted.';
        CouldNotRegisterWhseActivityErr: Label 'Could not register Warehouse Activity.';
        OrderToOrderBindingOnSalesLineQst: Label 'Registering the pick will remove the existing order-to-order reservation for the sales order.\Do you want to continue?';
        ILELotNotMatchedErr: Label 'Item Ledger Entry Lot No. %1 should be equal to the first lot with FEFO.', Comment = '%1 - Lot No.';

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,RegisterWhseMessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ItemJournalWithItemTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseEmployee: Record "Warehouse Employee";
        ExpirationDate: Date;
    begin
        // Verify Expiration Date on Item Tracking Line on Item Journal.

        // Setup: Create Item with Lot Specific Item Tracking and create Location with Bin. Use Random value to set Expiration Date later than Workdate.
        Initialize();
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());  // Assign in global variable.
        LibraryVariableStorage.Enqueue(ExpirationDate);
        CreateItem(Item, CreateItemTrackingCode(true, true, true, false, true));
        CreateWhiteLocation(Bin, Item);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Bin."Location Code", true);

        // Create Whse. Item Journal with new Bin and assign Item Tracking with Expiration Date.
        LibraryWarehouse.CreateBin(Bin, Bin."Location Code", LibraryUtility.GenerateGUID(), Bin."Zone Code", Bin."Bin Type Code");
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.");
        WarehouseJournalLine.OpenItemTrackingLines();
        UpdateExpirationDateOnWhseItemTrackingLine(Bin."Location Code", Item."No.");
        LibraryVariableStorage.Enqueue(RegisterJournalLine);  // Enqueue value for ConfirmHandler.

        // Register Warehouse Item Journal.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", false);  // Use False for Use Batch.

        // Select Item Journal Batch.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);

        // Exercise: Calculate Whse. Adjustment.
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryVariableStorage.Enqueue(ExpirationDate);

        // Verify: Verify Item Tracking Lines for Expiration Date.
        VerifyExpirationDateForItemTracking(Bin."Location Code", Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LotTrackingOnSalesOrderWithBin()
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
        Quantity: Decimal;
        LotNo: Code[10];
    begin
        // Verify available Lot No. and Bin Content on Item Tracking Line for Sales Order with Bin.

        // Setup: Create Location with Bins. Use Random values for Quantity.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Using Random for Quantity.
        LotNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Item.FieldNo("Lot Nos."), DATABASE::Item), 1,
            LibraryUtility.GetFieldLength(DATABASE::Item, Item.FieldNo("Lot Nos.")));
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::VerifyLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(LotNo);
        CreateSilverLocation(Bin);
        LibraryWarehouse.CreateBin(Bin2, Bin."Location Code", LibraryUtility.GenerateGUID(), '', '');  // Use blank values for Unit Of Measure Code and Zone Code.
        CreateAndVerifyTrackingLinesForSales(Bin."Location Code", Bin.Code, Bin2.Code, Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure LotTrackingOnSalesOrderWithoutBin()
    var
        Bin: Record Bin;
        Item: Record Item;
        Quantity: Decimal;
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
        LotNo: Code[10];
    begin
        // Verify available Lot No. and Bin Content on Item Tracking Line for Sales Order without Bin.

        // Setup: Create Location with Bin. Use Random values for Quantity.
        Initialize();
        Quantity := 2 * LibraryRandom.RandInt(10);  // Assign in global variable. Multiply by 2 to avoide decimal values.
        LotNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(Item.FieldNo("Lot Nos."), DATABASE::Item), 1,
            LibraryUtility.GetFieldLength(DATABASE::Item, Item.FieldNo("Lot Nos.")));
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::VerifyLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(LotNo);
        CreateSilverLocation(Bin);
        CreateAndVerifyTrackingLinesForSales(Bin."Location Code", Bin.Code, Bin.Code, '');  // Use blank value for Bin Code for Sales.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure GetBinContentUsingTransferOrder()
    var
        Bin: Record Bin;
        Location: Record Location;
        TransferHeader: Record "Transfer Header";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Get Bin Content on Transfer Order after posting Purchase Order.

        // Setup: Create Item with Serial Specific Item Tracking and create Location with Bin, Create and Post Purchase Order, Create Transfer Order.
        Initialize();
        ItemNo := CreateSerialTrackedItem();
        CreateSilverLocation(Bin);
        LibraryWarehouse.CreateLocation(Location);
        Quantity := CreateAndPostPurchaseOrderWithBin(ItemNo, Bin.Code, Bin."Location Code", false);  // Use False for Invoice.
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Bin."Location Code", Location.Code, CreateTransitLocation());

        // Exercise: Get Bin Content on Transfer Order.
        LibraryWarehouse.GetBinContentTransferOrder(TransferHeader, Bin."Location Code", ItemNo, Bin.Code);

        // Verify: Verify Quantity after Get Bin Content on Transfer Order.
        VerifyQuantityOnTransferLine(TransferHeader."No.", ItemNo, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure RevaluationJournalWithSerialNo()
    var
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // Verify Revaluation Journal after posting Purchase Order with Item Tracking.

        // Setup: Create Item with Serial Specific Item Tracking and create Location with Bin. Create and Post Purchase Order.
        Initialize();
        ItemNo := CreateSerialTrackedItem();
        CreateSilverLocation(Bin);
        Quantity := CreateAndPostPurchaseOrderWithBin(ItemNo, Bin.Code, Bin."Location Code", true);  // Use True for Invoice.

        // Exercise: Create Item Journal Line for Revaluation and Calculate Inventory value.
        CreateItemJournalForRevaluation(ItemJournalLine, ItemNo);

        // Verify: Verify Quantity on Item Journal Line.
        FindItemJournalLine(ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MessageWithDeleteSalesLineIT()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Item Tracking Message using Sales Line, verification done in ConfirmHandler.

        // Setup: Create Item with Item Tracking Code, create Sales Order and assign Item Tracking.
        Initialize();

        // Exercise:
        DeleteSalesLineIT(SalesLine);

        // Verify: Verify Item Tracking Message using Sales Line, verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorForDeletedSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify error for Sales Line deletion.

        // Setup: Create Item with Item Tracking Code, create Sales Order and assign Item Tracking and delete Item Tracking Lines.
        Initialize();
        DeleteSalesLineIT(SalesLine);
        SalesLine.Delete(true);

        // Exercise: Get Sales Line.
        asserterror SalesLine.Get(SalesLine."Document Type"::Order, SalesLine."Document No.", SalesLine."Line No.");

        // Verify: Verify error for Sales Line deletion.
        Assert.ExpectedErrorCannotFind(Database::"Sales Line");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryErrorForDeletedSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify error for deleted Reservation Entry.

        // Setup: Create Item with Item Tracking Code, create Sales Order and assign Item Tracking and delete Item Tracking Lines and Sales Line.
        Initialize();
        DeleteSalesLineIT(SalesLine);
        SalesLine.Delete(true);

        // Exercise: Find Reservation Entry for Sales Line.
        asserterror FindReservEntry(SalesLine."Document No.");

        // Verify: Verify error for deleted Reservation Entry.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandlerForReservation')]
    [Scope('OnPrem')]
    procedure ConfirmErrorForDeletedSalesLine()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify error message while using False on Confirmation message.

        // Setup: Create Item with Item Tracking Code, create Sales Order and assign Item Tracking.
        Initialize();

        // Exercise:
        DeleteSalesLineITWithConfirmFalse(SalesLine);

        // Verify: Verify error message while using False on Confirmation message.
        Assert.ExpectedError(ITConfirmMessage);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandlerForReservation')]
    [Scope('OnPrem')]
    procedure ReservEntryForDeletedSalesLineITWithConfirmFalse()
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Verify Reservation Entry is showing the entry after getting an error.

        // Setup: Create Item with Item Tracking Code, create Sales Order and assign Item Tracking.
        Initialize();

        // Exercise:
        DeleteSalesLineITWithConfirmFalse(SalesLine);

        // Verify: Verify Reservation Entry is showing the entry after getting an error.
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Item No.", SalesLine."No.");
        ReservationEntry.TestField(Quantity, -1);  // Taking 1 because single Quantity is assigned while using Assign Serial No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandlerForReservation')]
    [Scope('OnPrem')]
    procedure PostErrorForDeleteSalesLineIT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify error message while posting Sales Order.

        // Setup: Create Item with Item Tracking Code, create Sales Order and assign Item Tracking.
        Initialize();
        DeleteSalesLineITWithConfirmFalse(SalesLine);
        SalesHeader.Get(SalesLine."Document Type"::Order, SalesLine."Document No.");

        // Exercise: Post Sales Order.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify error message while posting Sales Order.
        Assert.ExpectedError(VariantMessage);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,InvokeItemTrackingSummaryPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservErrorUsingDeleteSalesLineITWithCancelReserv()
    var
        DocumentNo: Code[20];
    begin
        // Verify Reservation Message after deleting Sales Line.

        // Setup: Delete Sales Line after assigning Item Tracking and performing Reservation.
        Initialize();
        DocumentNo := DeleteSalesLineITWithCancelReserv();

        // Exercise: Find Reservation Entry for Sales Line.
        asserterror FindReservEntry(DocumentNo);

        // Verify: Verify error for deleted Reservation Entry.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,InvokeItemTrackingSummaryPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MessageUsingDeleteSalesLineITWithCancelReserv()
    begin
        // Verify Item Tracking Message using Sales Line with Item Tracking and Reservation.

        // Setup: Delete Sales Line after assigning Item Tracking and performing Reservation.
        Initialize();

        // Exercise:
        DeleteSalesLineITWithCancelReserv();

        // Verify: Verify Item Tracking Message using Sales Line, verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,InvokeItemTrackingSummaryPageHandler,ReservationPageHandler,ItemTrackingListPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CancelReservMessageUsingSalesLineWithIT()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify QtyReserve and Cancel Reservation From Current Line message.

        // Setup: Delete Sales Line after assigning Item Tracking and performing Reservation.
        Initialize();
        CreateAndReservSalesLine(SalesLine);

        // Verify: Verify QtyReserve and Cancel Reservation From Current Line, verification done in ReservationPageHandler and ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,InvokeItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MessageUsingDeleteSalesLineWithOrderTracking()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Item Tracking Message using Sales Line with Order Tracking.

        // Setup: Delete Sales Line after assigning Item Tracking with Order Tracking.
        Initialize();

        // Exercise:
        CreatePOAndDeleteSalesLineWithOrderTracking(SalesLine);

        // Verify: Verify Item Tracking Message using Sales Line with Order Tracking, verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,InvokeItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ErrorUsingDeleteSalesLineWithOrderTracking()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify Reservation Message after deleting Sales Line using Order Tracking.

        // Setup: Delete Sales Line after assigning Item Tracking with Order Tracking.
        Initialize();
        CreatePOAndDeleteSalesLineWithOrderTracking(SalesLine);

        // Exercise: Find Reservation Entry for Sales Line.
        asserterror FindReservEntry(SalesLine."Document No.");

        // Verify: Verify Reservation Message after deleting Sales Line using Order Tracking.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,DummyConfirmHandler')]
    [Scope('OnPrem')]
    procedure FirstExpiringLotSuggestingAfterUndoWhseShipment()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ExpirationDate: Date;
        ShipmentBinCode: Code[10];
        LotNo: array[2] of Code[10];
        Quantity: Integer;
    begin
        // [FEATURE] [Undo Shipment] [FEFO] [Bin] [Item Reclassification Journal]
        // [SCENARIO 379434] System should suggest the first-expiring lot according to FEFO when it has been returned and placed back into pickable bins.
        Initialize();
        Quantity := LibraryRandom.RandInt(100);
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());

        // [GIVEN] Create Location with pick according to FEFO.
        CreateLocationWithPostingSetupAndPickAccordingTOFEFO(Location, ShipmentBinCode);

        // [GIVEN] Item with Lot No. tracking.
        LibraryInventory.CreateTrackedItem(Item, '', '', CreateItemTrackingCode(false, true, true, false, true));

        // [GIVEN] Positive adjustment with Lot = "X" and ExpirationDate = D1 , Lot = "Y" and ExpirationDate = D2 and D2 > D1.
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        SelectItemJournalAndPostItemJournalLine(
          LotNo[1], Bin.Code, '', Item."No.", Location.Code, '', Quantity, ExpirationDate,
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", false);
        SelectItemJournalAndPostItemJournalLine(
          LotNo[2], Bin.Code, '', Item."No.", Location.Code, '', Quantity,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ExpirationDate),
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", false);

        // [GIVEN] Sales order, Warehouse Shipment from this Sales Order, Pick From Warehouse Shipment.
        CreatePickFromSOAndPostShipment(SalesHeader, Item."No.", Location.Code, Quantity);

        // [GIVEN] Undo Posted Shipment Line.
        UndoPostedShipmentLine(SalesHeader."No.", Item."No.");

        // [GIVEN] Return inventory from shipment bin to current bin using Item Reclassification Journal.
        SelectItemJournalAndPostItemJournalLine(
          LotNo[1], ShipmentBinCode, Bin.Code, Item."No.", Location.Code, LotNo[1], Quantity, ExpirationDate,
          ItemJournalBatch."Template Type"::Transfer, ItemJournalLine."Entry Type"::Transfer, true);

        // [GIVEN] Delete Sales Order.
        SalesHeader.Find();
        SalesHeader.Delete(true);

        // [GIVEN] Sales order and Warehouse Shipment from this Sales Order.
        CreateAndReleaseSO(SalesHeader, Item."No.", Location.Code, Quantity);
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Pick From Warehouse Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Warehouse Activity Line with Lot = "X" is created.
        VerifyLotNoInWarehouseActivityLine(Item."No.", SalesHeader."No.", LotNo[1]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,InvokeItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesLineErrorUsingOrderTracking()
    var
        SalesLine: Record "Sales Line";
    begin
        // Verify error for Sales Line deletion using Order Tracking.

        // Setup: Delete Sales Line after assigning Item Tracking with Order Tracking.
        Initialize();
        CreatePOAndDeleteSalesLineWithOrderTracking(SalesLine);
        SalesLine.Delete(true);

        // Exercise: Get Sales Line.
        asserterror SalesLine.Get(SalesLine."Document Type"::Order, SalesLine."Document No.", SalesLine."Line No.");

        // Verify: Verify error for Sales Line deletion using Order Tracking.
        Assert.ExpectedErrorCannotFind(Database::"Sales Line");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,InvokeItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesLineWithBinAndIT()
    begin
        // Verify Item Tracking Message using Delete Sales Line with Item Tracking and and Bin.

        // Setup: Delete Sales Line with Bin after assigning Item Tracking.
        Initialize();

        // Exercise:
        DeleteSalesLineUsingBinWithIT();

        // Verify: Verify Item Tracking Message using Delete Sales Line with Item Tracking and and Bin., verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,InvokeItemTrackingSummaryPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryUsingDeleteSalesLineWithBinAndIT()
    var
        DocumentNo: Code[20];
    begin
        // Verify Reservation error message after deleting Sales Line using Bin and Item Tracking.

        // Setup: Delete Sales Line with Bin after assigning Item Tracking.
        Initialize();
        DocumentNo := DeleteSalesLineUsingBinWithIT();

        // Exercise: Find Reservation Entry for Sales Line with Bin.
        asserterror FindReservEntry(DocumentNo);

        // Verify: Verify Reservation error message after deleting Sales Line using Bin and Item Tracking.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesLineUsingWhseShptWithIT()
    var
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // Verify Item Tracking Message using Delete Sales Line with Item Tracking and Warehouse Shipment

        // Setup: Create Warhouse Location, create Sales Order assign Item Tracking and Release.
        Initialize();
        CreateWhseShptWithIT(SalesLine, TrackingOption::AssignSerialNo);
        LibraryVariableStorage.Enqueue(ITConfirmMessage);  // Enqueue value for ConfirmHandler.

        // Exercise:
        SalesLineReserve.DeleteLineConfirm(SalesLine);
        SalesLineReserve.DeleteLine(SalesLine);

        // Verify: Verify Item Tracking Message using Delete Sales Line with Item Tracking and Warehouse Shipment, verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteSalesLineUsingWhseShptWithITNoConfirm()
    var
        SalesLine: Record "Sales Line";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // Verify NO confirm message using Delete Sales Line with Item Tracking and Warehouse Shipment

        // Setup: Create Warhouse Location, create Sales Order assign Item Tracking and Release.
        Initialize();
        CreateWhseShptWithIT(SalesLine, TrackingOption::AssignSerialNo);

        // Exercise:
        SalesLineReserve.SetDeleteItemTracking(true);
        SalesLineReserve.DeleteLine(SalesLine);

        // Verify: Verify Item Tracking Message using Delete Sales Line with Item Tracking and Warehouse Shipment, verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseShptErrorUsingDeleteSalesLineWithIT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesWarehouseMgt: Codeunit "Sales Warehouse Mgt.";
    begin
        // Verify Warehouse Shipment exit error using Item Tracking Message using Delete Sales Line with Item Tracking and Warehouse Shipment

        // Setup: Create Warhouse Location, create Sales Order assign Item Tracking and Release.
        Initialize();
        CreateWhseShptWithIT(SalesLine, TrackingOption::AssignSerialNo);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Get(SalesLine."Document Type"::Order, SalesHeader."No.", SalesLine."Line No.");
        DeleteSalesLine(SalesLine);

        // Exercise:
        asserterror SalesWarehouseMgt.SalesLineDelete(SalesLine);

        // Verify: Verify Warehouse Shipment exit error using Item Tracking Message using Delete Sales Line with Item Tracking and Warehouse Shipment, verification done in ConfirmHandler.
        Assert.ExpectedError(DeleteSalesLineWhseShptError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WhseShptErrorAfterDeleteWhseShptLine()
    var
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Verify Warehouse Shipment error after create and delete Warehouse Shipment Line.

        // Setup: Create Warhouse Location, create Sales Order assign Item Tracking and Release.
        Initialize();
        CreateWhseShptWithIT(SalesLine, TrackingOption::AssignSerialNo);
        FindWhseShptLine(
            WarehouseShipmentLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.");
        WarehouseShipmentLine.Delete(true);
        WarehouseShipmentLine.SetRange("Source No.", SalesLine."Document No.");

        // Exercise.
        asserterror WarehouseShipmentLine.FindFirst();

        // Verify: Verify Warehouse Shipment error after create and delete Warehouse Shipment Line.
        Assert.ExpectedError(WhseShptError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ITMessageUsingDeletePurchaseLine()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Item Tracking Message using Delete Purchase Line.

        // Setup: Create Tracked Item, create Purchase Order with Item Tracking and delete the Tracking Lines.
        Initialize();

        // Exercise: Delete Purchase Line.
        DeleteTrackingOnPurchaseLine(PurchaseLine);

        // Verify: Verify Item Tracking Message using Delete Purchase Line, verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletePurchaseLineErrorWithIT()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error for Purchase Line deletion.

        // Setup: Create Tracked Item, create Purchase Order with Item Tracking and delete the Tracking Lines.
        Initialize();
        DeleteTrackingOnPurchaseLine(PurchaseLine);
        PurchaseLine.Delete(true);

        // Exercise: Get Purchase Line.
        asserterror PurchaseLine.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.", PurchaseLine."Line No.");

        // Verify: Verify error for Purchase Line deletion.
        Assert.ExpectedErrorCannotFind(Database::"Purchase Line");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryErrorUsingDeletePurchaseLineWithIT()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error for deleted Reservation Entry.

        // Setup: Create Tracked Item, create Purchase Order with Item Tracking and delete the Tracking Lines.
        Initialize();
        DeleteTrackingOnPurchaseLine(PurchaseLine);
        PurchaseLine.Delete(true);

        // Exercise: Find Reservation Entry for Purchase Line.
        asserterror FindReservEntry(PurchaseLine."Document No.");

        // Verify: Verify error for deleted Reservation Entry.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SerialNoErrorUsingDeletePurchaseLineWithIT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error while posting Purchase Order after deleting Item Tracking Lines.

        // Setup: Create Tracked Item, create Purchase Order with Item Tracking and delete the Tracking Lines.
        Initialize();
        DeleteTrackingOnPurchaseLine(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");

        // Exercise.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify error while posting Purchase Order after deleting Item Tracking Lines.
        Assert.ExpectedError(StrSubstNo(SerialNoError, PurchaseLine."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseHeaderExistErrorWithIT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify error while finding Purchase Order after deleting Item Tracking Lines and Purchase Header.

        // Setup: Create Tracked Item, create Purchase Order with Item Tracking and delete the Tracking Lines.
        Initialize();
        DeleteTrackingOnPurchaseLine(PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Delete(true);

        // Exercise: Find Purchase Order.
        asserterror PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");

        // Verify: Verify error while finding Purchase Order after deleting Item Tracking Lines and Purchase Header.
        Assert.ExpectedErrorCannotFind(Database::"Purchase Header");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure MessageUsingDeletePOWithIT()
    begin
        // Verify Item Tracking Message while deleting Purchase Order.

        // Setup: Create Tracked Item, create Purchase Order with Item Tracking and delete the Tracking Lines.
        Initialize();

        // Exercise: Create and delete Purchase Order.
        CreateAndDeletePurchaseHeader();

        // Verify: Verify Item Tracking Message while deleting Purchase Order, verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryErrorAfterDeletePOWithIT()
    var
        DocumentNo: Code[20];
    begin
        // Verify Reservation Entry error after deleting Purchase Order.

        // Setup: Create Tracked Item, create Purchase Order with Item Tracking and delete the Tracking Lines.
        Initialize();
        DocumentNo := CreateAndDeletePurchaseHeader();

        // Exercise: Find Reservation Entry for Purchase Line.
        asserterror FindReservEntry(DocumentNo);

        // Verify: Verify Reservation Entry error after deleting Purchase Order.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithDeleteRequisitionLine()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Verify error for deleted Requisition Line.

        // Setup: Create Tracked Item, create Vendor, create Requisition Line assign Item Tracking and delete the Requisition Line.
        Initialize();
        DeleteRequisitionLine(RequisitionLine);
        RequisitionLine.SetRange("No.", RequisitionLine."No.");

        // Exercise.
        asserterror RequisitionLine.FindFirst();

        // Verify: Verify error for deleted Requisition Line.
        Assert.ExpectedError(RequisitionLineError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryErrorForDeletedRequistionLine()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Verify error for deleted Reservation Entry.

        // Setup: Create Tracked Item, create Vendor, create Requisition Line assign Item Tracking and delete the Requisition Line.
        Initialize();
        DeleteRequisitionLine(RequisitionLine);

        // Exercise: Find Reservation Entry for Requisition Line.
        asserterror FindReservEntry(RequisitionLine."Worksheet Template Name");

        // Verify: Verify error for deleted Reservation Entry.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ErrorForDeleteItemJnlLineWithIT()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Item Tracking error message while deleting Item Journal Lines.

        // Setup: Create Item Journal Line with Item Tracking.
        Initialize();
        CreateItemJnlLineWithIT(ItemJournalLine, '', '');

        // Exercise:
        asserterror ItemJournalLine.Delete(true);

        // Verify: Verify Item Tracking error message while deleting Item Journal Lines.
        Assert.ExpectedError(ITConfirmMessage);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryUsingItemJnlLineWithIT()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Verify Reservation Entry must be exist after creating Item Journal Line with Item Tracking Line.

        // Setup.
        Initialize();

        // Exercise: Create Item Journal Line with Item Tracking.
        CreateItemJnlLineWithIT(ItemJournalLine, '', '');

        // Verify: Verify Reservation Entry must be exist after creating Item Journal Line with Item Tracking Line.
        VerifyReservationEntry(ItemJournalLine."Item No.", 1);  // Taken 1 because only one Quantity is assigned at the time of Assingning Serial No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ErrorForDeletedPlanningWkshWithComponent()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Verify error for deleted Requisition Line with Component Line.

        // Setup: Create Requisition Line assign Item Tracking and delete the Requisition Line with Component.
        Initialize();
        CreateAndDeletedPlanningWkshWithComponent(RequisitionLine);
        RequisitionLine.SetRange("No.", RequisitionLine."No.");

        // Exercise.
        asserterror RequisitionLine.FindFirst();

        // Verify: Verify error for deleted Requisition Line with Component Line.
        Assert.ExpectedError(RequisitionLineError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ErrorWithReservEntryForDeletedPlanningWksh()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // Verify Reservation Entry error for deleted Requisition Line with Component Line.

        // Setup: Create Requisition Line assign Item Tracking and delete the Requisition Line with Component.
        Initialize();
        CreateAndDeletedPlanningWkshWithComponent(RequisitionLine);

        // Exercise: Find Reservation Entry for Requisition Line.
        asserterror FindReservEntry(RequisitionLine."Worksheet Template Name");

        // Verify: Verify Reservation Entry error for deleted Requisition Line with Component Line.
        Assert.ExpectedError(ReservEntryError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ProdOrderDeletionError()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Verify error message for deletion of Production Order Line with Item Tracking.

        // Setup: Create and find Production Order using Item Tracking.
        Initialize();
        CreateAndFindProdOrderWithIT(ProdOrderLine);

        // Exercise.
        asserterror ProdOrderLine.Delete(true);

        // Verify: Verify error message for deletion of Production Order Line with Item Tracking.
        Assert.ExpectedError(ITConfirmMessage);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryForProdOrderWithIT()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Verify Reservation Entry must be exist after creating Released Production Order with Item Tracking Line.

        // Setup: .
        Initialize();

        // Exercise: Create and find Production Order using Item Tracking.
        CreateAndFindProdOrderWithIT(ProdOrderLine);

        // Verify: Verify Reservation Entry must be exist after creating Released Production Order with Item Tracking Line.
        VerifyReservationEntry(ProdOrderLine."Item No.", 1);  // Taken 1 because only one Quantity is assigned at the time of Assingning Serial No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeleteProdOrderHeader()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
    begin
        // Verify message while deleting Production Order.

        // Setup: Create tracked Item, create and refresh Production Order and assign Item Tracking.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        OpenItemTrackingLinesForProduction(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(DeletionMessage);  // Enqueue value for ConfirmHandler.

        // Exercise.
        ProductionOrder.Delete(true);

        // Verify: Verify message while deleting Production Order. Verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletionErrorWithProdOrderComponent()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ComponentItem: Code[20];
    begin
        // Verify error message for deletion of Production Order Component with Item Tracking.

        // Setup: Create tracked Items for Production Order Component, create Production BOM, attach it to Item, create and refresh Production Order and assign Item Tracking and find Production Order Component.
        Initialize();
        ComponentItem := CreateProdOrderComponentWithIT(ProductionOrder);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ComponentItem);

        // Exercise.
        asserterror ProdOrderComponent.Delete(true);

        // Verify: Verify error message for deletion of Production Order Component with Item Tracking.
        Assert.ExpectedError(ITConfirmMessage);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryUsingProdOrderComponent()
    var
        ProductionOrder: Record "Production Order";
        ComponentItem: Code[20];
    begin
        // Verify Reservation Entry must be exist after creating Released Production Order with Component Item and Item Tracking Line.

        // Setup: Create tracked Items for Production Order Component, create Production BOM, attach it to Item, create and refresh Production Order and assign Item Tracking and find Production Order Component.
        Initialize();

        // Exercise.
        ComponentItem := CreateProdOrderComponentWithIT(ProductionOrder);

        // Verify: Verify Reservation Entry must be exist after creating Released Production Order with Component Item and Item Tracking Line.
        VerifyReservationEntry(ComponentItem, -1);  // Taken -1 because only one Quantity is assigned at the time of Assingning Serial No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletionErrorUsingTransferLine()
    var
        TransferLine: Record "Transfer Line";
    begin
        // Verify error while deleting Transfer Line with Item Tracking.

        // Setup: Create Transfer Order with Item Tracking.
        Initialize();
        CreateTransferOrderWithIT(TransferLine);

        // Exercise.
        asserterror TransferLine.Delete(true);

        // Verify: Verify error while deleting Transfer Line with Item Tracking.
        Assert.ExpectedError(ITConfirmMessage);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryUsingTransferOrder()
    var
        TransferLine: Record "Transfer Line";
    begin
        // Verify Reservation Entry must be exist after creating Transfer Order with Item Tracking Line.

        // Setup.
        Initialize();

        // Exercise: Create Transfer Order with Item Tracking.
        CreateTransferOrderWithIT(TransferLine);

        // Verify: Verify Reservation Entry must be exist after creating Transfer Order with Item Tracking Line.
        VerifyReservationEntry(TransferLine."Item No.", -1);  // Taken -1 because only one Quantity is assigned at the time of Assingning Serial No.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletionForTransferOrder()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
    begin
        // Verify message while deleting Transfer Order.

        // Setup: Create Transfer Order with Item Tracking.
        Initialize();
        CreateTransferOrderWithIT(TransferLine);
        TransferHeader.Get(TransferLine."Document No.");
        LibraryVariableStorage.Enqueue(DeletionMessage);  // Enqueue value for ConfirmHandler.

        // Exercise.
        TransferHeader.Delete(true);

        // Verify: Verify message while deleting Transfer Order. Verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateWithGivenQtyPageHandler,InvokeItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure LateBindingSerial()
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup.
        Initialize();

        // Exercise.
        LateBindingSalesVsPurchase(SalesLine, true, false, 1);

        // Verify: Verify Reservation Entry after posting should cover only the unreceived qty.
        VerifyReservationEntry(SalesLine."No.", -SalesLine."Qty. to Ship");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreateWithGivenQtyPageHandler,InvokeItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure LateBindingSerialMultipleReceipts()
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup.
        Initialize();

        // Exercise.
        LateBindingSalesVsPurchase(SalesLine, true, false, LibraryRandom.RandIntInRange(2, 4));

        // Verify: Verify Reservation Entry after posting should cover only the unreceived qty.
        VerifyReservationEntry(SalesLine."No.", -SalesLine."Qty. to Ship");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure LateBindingLot()
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup.
        Initialize();

        // Exercise.
        LateBindingSalesVsPurchase(SalesLine, false, true, 1);

        // Verify: Verify Reservation Entry after posting should cover only the unreceived qty.
        VerifyReservationEntry(SalesLine."No.", -SalesLine."Qty. to Ship");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler,ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure LateBindingLotMultipleReceipts()
    var
        SalesLine: Record "Sales Line";
    begin
        // Setup.
        Initialize();

        // Exercise.
        LateBindingSalesVsPurchase(SalesLine, false, true, LibraryRandom.RandIntInRange(2, 4));

        // Verify: Verify Reservation Entry after posting should cover only the unreceived qty.
        VerifyReservationEntry(SalesLine."No.", -SalesLine."Qty. to Ship");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseShptAfterPickDeletion()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Can post Warehouse Shipment for tracked Item, first partially picked, then Warehouse Pick deleted.

        // [GIVEN] Sales Order with tracked Item, Location require Pick/Put-Away.
        Initialize();

        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true, true, false, false));

        CreatePurchaseOrder(PurchaseLine, Item."No.");
        PurchaseLine.Validate("Location Code", CreateWhseLocation(true));
        PurchaseLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        CreatePostWhseRcpt(PurchaseHeader);
        FindRegisterPutAway(PurchaseHeader);

        CreateSalesDocument(SalesLine, PurchaseLine."No.", PurchaseLine."Location Code", PurchaseLine.Quantity);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries); // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWhseShpt(SalesLine."Document No.");
        FindWhseShptLine(
            WarehouseShipmentLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.");

        // [GIVEN] Register Warehouse Pick with partial Quantity, then delete Warehouse Pick.
        CreateRegisterWhsePick(WarehouseActivityHeader, WarehouseShipmentLine, SalesLine.Quantity - 1);
        WarehouseActivityHeader.Find();
        WarehouseActivityHeader.Delete(true);

        // [WHEN] Post Warehouse Shipment.
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Posted Warehouse Shipment created successfully.
        VerifyPostedWhseShipment(WarehouseShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler,ProductionJournalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostWhseShptPartiallyPickedProductionItem()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Can post Warehouse Shipment for partially produced and picked tracked Item.

        // [GIVEN] Sales Order with tracked Item (replenished with production), Quantity = 3 * X, Location require Pick/Put-Away.
        Initialize();

        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode(false, true, true, false, false));
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);
        CreateSalesDocument(SalesLine, Item."No.", CreateWhseLocation(false), 3 * LibraryRandom.RandIntInRange(10, 20));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibraryVariableStorage.Enqueue(ProdOrderCreatedMsg); // Enqueue value for MessagePageHandler.

        // [GIVEN] Create Produciton Order from Sales Order.
        LibraryManufacturing.CreateProductionOrderFromSalesOrder(SalesHeader, ProductionOrder.Status::Released, "Create Production Order Type"::ItemOrder);

        // [GIVEN] Post production with two lines of quantities X, assign different lots.
        LotNo := PostProductionOutputWithIT(Item."No.", SalesLine.Quantity / 3, SalesLine.Quantity / 3);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWhseShpt(SalesLine."Document No.");
        FindWhseShptHeader(WarehouseShipmentHeader, SalesLine."Document Type".AsInteger(), SalesLine."Document No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);

        // [GIVEN] Register Pick for first lot, Quantity of X.
        LibraryVariableStorage.Enqueue(OrderToOrderBindingOnSalesLineQst);
        ModifyRegisterWhsePick(WarehouseShipmentHeader, LotNo);

        // [WHEN] Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Posted Warehouse Shipment created successfully.
        VerifyPostedWhseShipment(WarehouseShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWithDiffTrackedItems()
    var
        Item: Record Item;
        Item2: Record Item;
        ManufItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
        LotNo: Code[10];
    begin
        // [FEATURE] [Item Tracking]
        // [SCENARIO] Warehouse Pick posted successfully when having two items, first is Lot tracked, second is not tracked.

        // [GIVEN] Two Items, one (A) is lot tracked, another (B) is not tracked.
        Initialize();

        CreateTrackedItem(
          Item, Item."Order Tracking Policy"::"Tracking Only", CreateItemTrackingCode(false, true, true, false, false));
        LibraryVariableStorage.Enqueue(TrackingPolicyMessage);
        LibraryInventory.CreateItem(Item2);
        Item2.Validate("Order Tracking Policy", Item2."Order Tracking Policy"::"Tracking Only");
        Item2.Modify(true);

        // [GIVEN] Create manufactured Item with Item B as BOM component.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, Item."No.", 1);
        CreateItem(ManufItem, '');
        ManufItem.Validate("Replenishment System", ManufItem."Replenishment System"::"Prod. Order");
        ManufItem.Validate("Reordering Policy", ManufItem."Reordering Policy"::Order);
        ManufItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ManufItem.Modify(true);

        // [GIVEN] Add stock for Items A and B (warehouse location).
        LocationCode := CreateWhseLocation(false);
        SetBinMandatory(LocationCode, false);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item."No.", LocationCode, '', LibraryRandom.RandIntInRange(10, 20),
          ItemJournalLine."Entry Type"::"Positive Adjmt.");
        LotNo := LibraryUtility.GenerateGUID();

        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(ItemJournalLine.Quantity);
        ItemJournalLine.OpenItemTrackingLines(false);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, Item2."No.", LocationCode, '', LibraryRandom.RandIntInRange(10, 20),
          ItemJournalLine."Entry Type"::"Positive Adjmt.");
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create Sales Order with two lines: Item A of Qty 1, Item B of Qty 1, create Warehouse Shipment, create Pick.
        CreateSalesDocument(SalesLine, Item."No.", LocationCode, 1);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item2."No.", 1);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWhseShpt(SalesLine."Document No.");
        FindWhseShptHeader(WarehouseShipmentHeader, SalesLine."Document Type".AsInteger(), SalesLine."Document No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        FindWhseActivityLine(WarehouseActivityLine, WarehouseShipmentHeader);
        WarehouseActivityLine.Validate("Lot No.", LotNo);
        WarehouseActivityLine.Modify(true);

        // [GIVEN] Create Planning Worksheet with manufactured Item, refresh worksheet.
        CreateRefreshPlanningWksh(ManufItem."No.", LocationCode, LibraryRandom.RandIntInRange(100, 200));

        // [WHEN] Register Pick.
        WarehouseActivityLine.Find();
        WarehouseActivityHeader.Init();
        RegisterWhsePick(WarehouseActivityHeader, WarehouseActivityLine);

        // [THEN] Pick registered successfully.
        VerifyRegisteredWhseActivity(Item."No.");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesSynchedAfterPartialShipmentAndInvoice()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Integer;
    begin
        // [FEATURE] [Sales Order] [Item Tracking] [Partial Shipment]
        // [SCENARIO 732242] "Item Tracking Lines" page should be synchronized with the database when sales order with tracking is partially shipped, then invoiced

        // [GIVEN] Item tracked by lot no.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '',
          CreateItemTrackingCode(false, false, true, false, false));
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        PostPositiveAdjustmentWithLotNo(Item."No.", Quantity);

        // [GIVEN] Sales order with one line: quantity = "X"
        // [GIVEN] Post partial shipment of the sales order. "Qty. to Ship" = "X / 2"
        CreateSalesDocument(SalesLine, Item."No.", '', Quantity);
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / 2);
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Set "Qty. to Invoice" = "X / 2" on the sales line
        SalesLine.Find();
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / 2);
        SalesLine.Modify(true);

        // [GIVEN] Open "Item Tracking Lines" page and set "Qty. to Invoice" = "X / 2"
        LibraryVariableStorage.Enqueue(TrackingOption::SetQtyToInvoice);
        LibraryVariableStorage.Enqueue(SalesLine."Qty. to Invoice");
        SalesLine.OpenItemTrackingLines();

        // [WHEN] Close "Item Tracking Lines"
        // [THEN] "Qty. to Invoice (Base)" in the item tracking specification = "X / 2"
        VerifyTrackingSpecQtyToInvoice(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure LateBindingOnTwoSalesLinesLotTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        LotNo: array[2] of Code[20];
        LotQty: array[2] of Decimal;
        DeltaQty: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Reservation] [Late Binding]
        // [SCENARIO] Late binding should create reservation for the specified lot no. when updating non-specific reservation

        Initialize();

        // [GIVEN] Item "I" with lot tracking
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '',
          CreateItemTrackingCode(false, false, true, false, false));
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        LotQty[2] := LibraryRandom.RandDecInRange(10, 20, 2);
        LotQty[1] := LotQty[2] * 2;
        DeltaQty := LibraryRandom.RandDecInDecimalRange(LotQty[2], LotQty[1] - 1, 2);

        // [GIVEN] Stock of item "I" in two lots: 20 pcs of "LotA" and 10 pcs of "LotB"
        PostPositiveAdjustmentWithLotTracking(Item."No.", '', '', LotNo[1], LotQty[1]);
        PostPositiveAdjustmentWithLotTracking(Item."No.", '', '', LotNo[2], LotQty[2]);

        // [GIVEN] Sales order with 2 lines (11 pcs and 19 pcs). Both have non-specific reservation of item "I" against inventory
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, Item."No.", LotQty[2] + DeltaQty);
        LibrarySales.AutoReserveSalesLine(SalesLine[1]);
        LibrarySales.CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item."No.", LotQty[1] - DeltaQty);
        LibrarySales.AutoReserveSalesLine(SalesLine[2]);

        // [WHEN] Open "Item Tracking Lines" and create specific reservation of 19 pcs of "LotA" for the second sales line
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(SalesLine[2].Quantity);
        SalesLine[2].OpenItemTrackingLines();

        // [THEN] 11 pcs of item "I" are reserved for the first sales line with no lot specified
        VerifyLotReservation(SalesLine[1], '');
        // [THEN] 19 pcs of item "I" are reserved for the second line with "Lot No." = "LotA"
        VerifyLotReservation(SalesLine[2], LotNo[1]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure LateBindingOnTwoSalesLinesSNTracking()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        SerialNo: array[2] of Code[20];
    begin
        // [FEATURE] [Item Tracking] [Reservation] [Late Binding]
        // [SCENARIO] Late binding should create reservation for the specified serial no. when updating non-specific reservation

        Initialize();

        // [GIVEN] Item "I" with serial no. tracking
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        SerialNo[1] := LibraryUtility.GenerateGUID();
        SerialNo[2] := LibraryUtility.GenerateGUID();

        // [GIVEN] 2 pcs of item "I" on inventory: "SN1" and "SN2"
        PostPositiveAdjustmentWithSNTracking(Item."No.", SerialNo[1]);
        PostPositiveAdjustmentWithSNTracking(Item."No.", SerialNo[2]);

        // [GIVEN] Sales order with 2 lines, both have non-specific reservation of item "I". "SN1" is reserved for the first line, "SN2" - second line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::Item, Item."No.", 1);
        LibrarySales.AutoReserveSalesLine(SalesLine[1]);
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item."No.", 1);
        LibrarySales.AutoReserveSalesLine(SalesLine[2]);

        // [WHEN] Open "Item Tracking Lines" and create specific reservation of "SN1" for the second sales line
        LibraryVariableStorage.Enqueue(TrackingOption::AssignManualSN);
        LibraryVariableStorage.Enqueue(SerialNo[1]);
        SalesLine[2].OpenItemTrackingLines();

        // [THEN] Non-specific reservation of item "I" exists for the first line
        VerifySerialReservation(SalesLine[1], '');
        // [THEN] Item "I" with serial no. = "SN1" is reserved for the second line
        VerifySerialReservation(SalesLine[2], SerialNo[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RetrieveInvoiceSpecificationClear()
    var
        SalesLine: Record "Sales Line";
        TrackingSpecification: Record "Tracking Specification";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        // [FEATURE] [Tracking Specification] [UT]

        // [GIVEN] Tracking Specification for Sales with "Entry No." = "X"
        SalesLine.Init();
        SalesLine.Type := SalesLine.Type::Item;
        TrackingSpecification.Init();
        TrackingSpecification."Entry No." := LibraryRandom.RandInt(5);

        // [WHEN] Call RetrieveInvoiceSpecification in Sales Line-Reserve codeunit
        SalesLineReserve.RetrieveInvoiceSpecification(SalesLine, TrackingSpecification);

        // [THEN] Tracking Specification has "Entry No." = 0
        TrackingSpecification.TestField("Entry No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseRetrieveInvoiceSpecificationClear()
    var
        PurchaseLine: Record "Purchase Line";
        TrackingSpecification: Record "Tracking Specification";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
    begin
        // [FEATURE] [Tracking Specification] [UT]
        // [SCENARIO 379053] Item tracking specification should be deleted when new purchase line is considered in the posting routine.

        // [GIVEN] Tracking Specification for Purchase with "Entry No." = "X"
        PurchaseLine.Init();
        PurchaseLine.Type := PurchaseLine.Type::Item;
        TrackingSpecification.Init();
        TrackingSpecification."Entry No." := LibraryRandom.RandInt(5);

        // [WHEN] Call RetrieveInvoiceSpecification in Purch. Line-Reserve codeunit
        PurchLineReserve.RetrieveInvoiceSpecification(PurchaseLine, TrackingSpecification);

        // [THEN] Tracking Specification has "Entry No." = 0
        TrackingSpecification.TestField("Entry No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceRetrieveInvoiceSpecificationClear()
    var
        ServiceLine: Record "Service Line";
        TrackingSpecification: Record "Tracking Specification";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        // [FEATURE] [Tracking Specification] [UT]
        // [SCENARIO 379053] Item tracking specification should be deleted when new service line is considered in the posting routine.

        // [GIVEN] Tracking Specification for Service with "Entry No." = "X"
        ServiceLine.Init();
        ServiceLine.Type := ServiceLine.Type::Item;
        TrackingSpecification.Init();
        TrackingSpecification."Entry No." := LibraryRandom.RandInt(5);

        // [WHEN] Call RetrieveInvoiceSpecification in Service Line-Reserve codeunit
        ServiceLineReserve.RetrieveInvoiceSpecification(ServiceLine, TrackingSpecification, false);

        // [THEN] Tracking Specification has "Entry No." = 0
        TrackingSpecification.TestField("Entry No.", 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WhseItemTrackingCreatePickAfterTrackingUpdate()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: array[2] of Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[2] of Code[20];
        Quantity: array[2] of Decimal;
    begin
        // [FEATURE] [Warehouse] [Shipment] [Pick]
        // [SCENARIO 380440] Pick created after changing Lot No. in sales order should receive new Lot No.

        Initialize();

        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        Quantity[1] := LibraryRandom.RandDecInRange(10, 20, 2);
        Quantity[2] := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] Location "L" with "Require Ship" = TRUE and "Require Pick" = FALSE.
        CreateLocationWithRequireShipAndTwoBins(Location, Bin);

        // [GIVEN] Item "I" with lot tracking, stock on location "L" in two lots "LOT1" and "LOT2"
        CreateTrackedItemWithInventoryStock(Item, LotNo, Quantity, Bin[2]);

        // [GIVEN] Create sales order for item "I" on location "L", select lot no. "LOT1"
        CreateSalesDocumentWithTracking(SalesHeader, SalesLine, Item."No.", Location.Code, LibraryRandom.RandDecInRange(1, 10, 2));

        // [GIVEN] Create warehouse shipment from sales order
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Change lot no. in sales order line. New lot no. = "LOT2"
        AssignLotNoToSalesLine(SalesLine, LotNo[2]);

        // [WHEN] Create pick from warehouse shipment
        UpdateQtyToShipInWhseShipment(WarehouseShipmentHeader."No.", 0);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [THEN] Lot no. in pick line is "LOT2"
        FindWhseActivityLine(WarehouseActivityLine, WarehouseShipmentHeader);
        WarehouseActivityLine.TestField("Lot No.", LotNo[2]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WhseItemTrackingTryUpdateAfterPickCreated()
    var
        Item: Record Item;
        Location: Record Location;
        Bin: array[2] of Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        LotNo: array[2] of Code[20];
        Quantity: array[2] of Decimal;
    begin
        // [FEATURE] [Warehouse] [Shipment] [Pick]
        // [SCENARIO 380440] It should not be allowed to change Lot No. in sales order after pick is created

        Initialize();

        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        Quantity[1] := LibraryRandom.RandDecInRange(10, 20, 2);
        Quantity[2] := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] Location "L" with "Require Ship" = TRUE and "Require Pick" = FALSE.
        CreateLocationWithRequireShipAndTwoBins(Location, Bin);
        CreateTrackedItemWithInventoryStock(Item, LotNo, Quantity, Bin[2]);

        // [GIVEN] Create sales order for item "I" on location "L", select lot no. "LOT1"
        CreateSalesDocumentWithTracking(SalesHeader, SalesLine, Item."No.", Location.Code, LibraryRandom.RandDecInRange(1, 10, 2));

        // [GIVEN] Create warehouse shipment from sales order
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Create pick from warehouse shipment
        UpdateQtyToShipInWhseShipment(WarehouseShipmentHeader."No.", 0);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [WHEN] Change lot no. in sales order line. New lot no. = "LOT2"
        asserterror AssignLotNoToSalesLine(SalesLine, LotNo[2]);

        // [THEN] Field update fails with error
        Assert.ExpectedTestFieldError(WhseItemTrackingLine.FieldCaption("Quantity Handled (Base)"), Format(0));

        // [THEN] Lot No. in pick line is "LOT1"
        FindWhseActivityLine(WarehouseActivityLine, WarehouseShipmentHeader);
        WarehouseActivityLine.TestField("Lot No.", LotNo[1]);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WhseItemTrackingTryUpdateAfterShipPartiallyShipped()
    var
        Item: Record Item;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        TrackingSpecification: Record "Tracking Specification";
        LotNo: array[2] of Code[20];
        Quantity: array[2] of Decimal;
    begin
        // [FEATURE] [Warehouse] [Shipment]
        // [SCENARIO 380440] It should not be allowed to change Lot No. in sales order after warehouse shipment is partially shipped

        Initialize();

        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        Quantity[1] := LibraryRandom.RandDecInRange(10, 20, 2);
        Quantity[2] := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] Location "L" with "Require Ship" = TRUE and "Require Pick" = FALSE.
        CreateLocationWithRequireShip(Bin);
        CreateTrackedItemWithInventoryStock(Item, LotNo, Quantity, Bin);

        // [GIVEN] Create sales order for item "I" on location "L", select lot no. "LOT1". Quantity = "X"
        CreateSalesDocumentWithTracking(SalesHeader, SalesLine, Item."No.", Bin."Location Code", LibraryRandom.RandDecInRange(5, 10, 2));

        // [GIVEN] Create warehouse shipment from sales order
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader);

        // [GIVEN] Set "Qty. to Ship" in warehouse shipment line to "X" / 2 and post partial shipment
        UpdateQtyToShipInWhseShipment(WarehouseShipmentHeader."No.", LibraryRandom.RandDecInDecimalRange(1, SalesLine.Quantity / 2, 2));
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [WHEN] Change lot no. in sales order line. New lot no. = "LOT2"
        asserterror AssignLotNoToSalesLine(SalesLine, LotNo[2]);

        // [THEN] Field update fails with error
        Assert.ExpectedTestFieldError(TrackingSpecification.FieldCaption("Quantity Handled (Base)"), Format(0));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure WhseItemTrackingAssignTrackingAfterShipmentCreated()
    var
        Item: Record Item;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        LotNo: Code[50];
        Quantity: Decimal;
    begin
        // [FEATURE] [Warehouse] [Shipment]
        // [SCENARIO 380440] Warehouse item tracking line should be created when Lot No. is assigned to sales line after creating warehouse shipment

        Initialize();

        LotNo := LibraryUtility.GenerateGUID();
        Quantity := LibraryRandom.RandDecInRange(10, 20, 2);

        // [GIVEN] Location "L" with "Require Ship" = TRUE and "Require Pick" = FALSE.
        CreateLocationWithRequireShip(Bin);
        CreateItem(Item, CreateItemTrackingCode(false, true, true, false, false));  // Lot specific tracking without expiration date
        PostPositiveAdjustmentWithLotTracking(Item."No.", Bin."Location Code", Bin.Code, LotNo, Quantity);

        // [GIVEN] Create sales order for item "I" on location "L" without tracking code
        CreateSalesDocument(SalesLine, Item."No.", Bin."Location Code", LibraryRandom.RandDecInRange(1, 10, 2));
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");

        // [GIVEN] Create warehouse shipment from sales order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Assign lot no. = "LOT1" in sales line
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [THEN] Warehouse item tracking line is created with lot no. = "LOT1"
        WhseItemTrackingLine.SetRange("Item No.", Item."No.");
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.TestField("Lot No.", LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ProductionJournalPageHandler,ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickReservedSalesOrderWithQtyManuallyChanged()
    var
        Location: Record Location;
        Item: Record Item;
        WarehouseActivityLine: Record "Warehouse Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReservationEntries: TestPage "Reservation Entries";
        LotNos: array[2] of Code[20];
        LotQty: Decimal;
    begin
        // [FEATURE] [Pick] [Reservation]
        // [SCENARIO 201925] Registering pick should reserve sales order when reservation quantity is changed manually, and there is surplus from another source

        Initialize();

        // [GIVEN] Item "I" with lot tracking
        CreateItem(Item, CreateItemTrackingCode(false, true, true, false, false));
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);

        // [GIVEN] Post production output of 50 pcs of item "I" on a WMS location. Split output in 2 lots "L1" and "L2"
        LotQty := LibraryRandom.RandIntInRange(10, 50);
        PostProdOrderOutputWithLotTracking(
          Item."No.", Location.Code, FindPutPickBin(Location), LotQty * 2 + LibraryRandom.RandInt(20), LotQty, LotQty);
        FindPostedLotNos(LotNos, Location.Code, Item."No.");

        // [GIVEN] Create sales order for 40 pcs of item "I" and reserve
        CreateSalesDocument(SalesLine, Item."No.", Location.Code, LotQty * 2);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.AutoReserveSalesLine(SalesLine);

        // [GIVEN] Open reservation entries and change reserved quantity for lot "L2" from 20 to 19
        ReservationEntries.Trap();
        SalesLine.ShowReservationEntries(false);
        ReservationEntries.Last();
        ReservationEntries."Quantity (Base)".SetValue(-LotQty + LibraryRandom.RandInt(5));

        // [GIVEN] Create warehouse shipment and pick from the sales order
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [GIVEN] Split pick lines and assign lot numbers
        SplitWhseActivityLineAndUpdateTracking(Item."No.", WarehouseActivityLine."Action Type"::Take, LotQty, LotNos);
        SplitWhseActivityLineAndUpdateTracking(Item."No.", WarehouseActivityLine."Action Type"::Place, LotQty, LotNos);

        // [GIVEN] Register pick
        RegisterWarehouseActivity(WarehouseShipmentHeader);

        // [THEN] Total reserved quantity for the sales order is 50
        // Expected quantity is negative, since we are on the outbound side
        VerifyReservedQuantity(SalesHeader."Document Type".AsInteger(), SalesHeader."No.", -LotQty * 2);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandlerWithDequeue')]
    procedure RegisterPickWithTwoSimilarLinesWithDifferentBinsWhenCalcRegenPlan()
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        SalesHeader: Record "Sales Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        Item: Record Item;
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        StockQty: array[2] of Integer;
        LocationCode: Code[10];
        BinCode: array[2] of Code[20];
    begin
        // [FEATURE] [Regenerative Plan]
        // [SCENARIO 303965] Sales Order is completely reserved when Regenerative Plan is calculated and Pick is registered for Item with Reordering Policy "Lot-for-Lot"
        Initialize();
        LotNo := LibraryUtility.GenerateGUID();
        StockQty[1] := LibraryRandom.RandInt(20);
        StockQty[2] := LibraryRandom.RandInt(20);

        // [GIVEN] Location with Directed Put-away and Pick enabled and with 2 Pick Bins "PP1" and "PP2"
        LocationCode := CreateFullWMSLocationWithBins(2);
        FindTwoBinsInLocation(BinCode, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, true));

        // [GIVEN] Item with Lot Warehouse Tracking enabled and Reordering Policy = Lot-for-Lot
        CreateItemWithItemTrackingCode(
          Item, CreateItemTrackingCode(false, true, true, false, false), Item."Reordering Policy"::"Lot-for-Lot");

        // [GIVEN] Two Warehouse Journal Lines with the Item and same Lot: 1st Line with Bin "B1" and 20 PCS; 2nd Line has Bin "B2" and 30 PCS
        // [GIVEN] Resgistered the Lines
        CreateWhseJournalBatchInItemTemplate(WarehouseJournalBatch, LocationCode);
        CreateTwoWhseJournalLinesWithItemTracking(WarehouseJournalBatch, Item."No.", LotNo, BinCode, StockQty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, true);

        // [GIVEN] Calculated and Posted Whse Adjustment in Item Journal
        PostWhseAdjustmentItemJournal(Item."No.", WorkDate());

        // [GIVEN] Released Sales Order with 50 PCS of the Item in Location
        CreateSalesOrderWithItemAndLocation(SalesHeader, Item."No.", LocationCode, StockQty[1] + StockQty[2]);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Created Warehouse Shipment and Pick, set Lot in each Pick Line
        CreateWhsePickFromSO(WarehouseActivityHeader, SalesHeader);
        UpdateWhseActivityLinesLotNoForSales(WarehouseActivityHeader, LotNo);

        // [GIVEN] Calculated Regenerative Plan for Planning Worksheet for this Year
        LibraryPlanning.CalcRegenPlanForPlanWkshPlanningParams(
          Item, CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()), true);

        // [WHEN] Post Pick
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [THEN] Two Reservation Entries with status Reservation for the Sales Line with total 50 PCS
        ReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.CalcSums("Quantity (Base)");
        ReservationEntry.TestField("Quantity (Base)", -(StockQty[1] + StockQty[2]));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure ItemTrackingCanBeAssignedOnInvtPickEvenItExceedsTrackedQty()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[10];
        QtyStock: Decimal;
        QtySales: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Inventory Pick]
        // [SCENARIO 308832] User can assign lot no. on inventory pick for the quantity greater than on the item tracking lines on the source document line.
        Initialize();

        QtyStock := LibraryRandom.RandIntInRange(11, 20);
        QtySales := LibraryRandom.RandInt(10);

        // [GIVEN] Location with required pick.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode(false, true, true, false, false), "Reordering Policy"::" ");

        // [GIVEN] Create item journal for 20 pcs of the item, assign lot no. "L" and post the inventory.
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        SelectItemJournalAndPostItemJournalLine(
          LotNo, Bin.Code, '', Item."No.", Location.Code, '', QtyStock, 0D,
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", false);

        // [GIVEN] Create sales order for 10 pcs., select lot no. "L".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", QtySales, Location.Code, WorkDate());
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Increase quantity on the sales order line to 20. Now, only 10 pcs of 20 are tracked.
        SalesLine.Find();
        SalesLine.Validate(Quantity, QtyStock);
        SalesLine.Modify(true);

        // [GIVEN] Release the sales order and create inventory pick.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [GIVEN] Assign lot no. "L" to all 20 pcs to be picked.
        FindWhseActivityHeaderBySalesHeader(WarehouseActivityHeader, SalesHeader);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo, true);
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [WHEN] Post the inventory pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] The sales order is fully shipped.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.CalcSums(Quantity);
        ItemLedgerEntry.TestField(Quantity, -QtyStock);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure ItemTrackingCanBeAssignedOnInvtPickPartiallyPostedDocCase()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Code[10];
        QtyStock: Decimal;
        QtySales: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Inventory Pick] [Partial Shipment]
        // [SCENARIO 308832] User can assign lot no. on inventory pick for the quantity greater than on the item tracking lines on the source document line. The inventory pick is posted in several iterations.
        Initialize();

        QtyStock := LibraryRandom.RandIntInRange(20, 40);
        QtySales := LibraryRandom.RandInt(10);

        // [GIVEN] Location with required pick.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode(false, true, true, false, false), "Reordering Policy"::" ");

        // [GIVEN] Create item journal for 40 pcs of the item, assign lot no. "L" and post the inventory.
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        SelectItemJournalAndPostItemJournalLine(
          LotNo, Bin.Code, '', Item."No.", Location.Code, '', QtyStock, 0D,
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", false);

        // [GIVEN] Create sales order for 10 pcs., select lot no. "L".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", QtySales, Location.Code, WorkDate());
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Increase quantity on the sales order line to 40. Now, only 10 pcs of 40 are tracked.
        SalesLine.Find();
        SalesLine.Validate(Quantity, QtyStock);
        SalesLine.Modify(true);

        // [GIVEN] Release the sales order and create inventory pick.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [GIVEN] Assign lot no. "L" to all pick lines.
        // [GIVEN] Set "Qty. to Handle" on the pick lines to 20.
        FindWhseActivityHeaderBySalesHeader(WarehouseActivityHeader, SalesHeader);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity / 2);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        // [GIVEN] Partially post the inventory pick. Now, 20 of 40 pcs are shipped.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [GIVEN] Post the remaining quantity in the inventory pick.
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] The sales order is fully shipped.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.CalcSums(Quantity);
        ItemLedgerEntry.TestField(Quantity, -QtyStock);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,InvokeItemTrackingSummaryPageHandler,MessageHandlerSimple')]
    [Scope('OnPrem')]
    procedure ItemTrackingCannotBeAssignedOnInvtPickWhenNoRoomForTrackingOnSourceDoc()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[2] of Code[10];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [Inventory Pick]
        // [SCENARIO 308832] User cannot assign lot no. for greater quantity than on the item tracking lines if there is no undefined quantity in item tracking (all quantity is already tracked with other lot nos.).
        Initialize();

        Qty := LibraryRandom.RandIntInRange(20, 40);

        // [GIVEN] Location with required pick.
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);

        // [GIVEN] Lot-tracked item.
        CreateItemWithItemTrackingCode(Item, CreateItemTrackingCode(false, true, true, false, false), "Reordering Policy"::" ");

        // [GIVEN] Create item journal for 20 pcs of the item, assign lot no. "L1" and post the inventory.
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        SelectItemJournalAndPostItemJournalLine(
          LotNo[1], Bin.Code, '', Item."No.", Location.Code, '', Qty, 0D,
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", false);

        // [GIVEN] Create sales order for 20 pcs., select lot no. "L1".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, Location.Code, WorkDate());
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Create item journal for 20 pcs of the item, assign lot no. "L2" and post the inventory.
        SelectItemJournalAndPostItemJournalLine(
          LotNo[2], Bin.Code, '', Item."No.", Location.Code, '', Qty, 0D,
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", false);

        // [GIVEN] Release the sales order and create inventory pick.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateInvtPutPickSalesOrder(SalesHeader);

        // [GIVEN] Set lot no. "L2" on the pick lines.
        FindWhseActivityHeaderBySalesHeader(WarehouseActivityHeader, SalesHeader);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo[2], true);
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        // [WHEN] Post the inventory pick.
        asserterror LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);

        // [THEN] The posting fails with "Cannot match item tracking" error message.
        // [THEN] This is because lot no. "L1" is assigned to all quantity on the sales line and there is no room for the new lot no. "L2".
        Assert.ExpectedError(StrSubstNo(CannotMatchItemTrackingErr, SalesLine."Document No.", SalesLine."Line No.", SalesLine."No.", SalesLine.Description));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ReservationFromCurrentLineHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickWithNoErrorForFEFOLocation()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: array[2] of Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ExpirationDate: Date;
        ShipmentBinCode: Code[20];
        LotNo: array[2] of Code[10];
    begin

        // [SCENARIO 572962] No Error when Lot No. LOT0001 is available on inventory, when trying to register pick for item with reservation and item tracking with location set up FEFO
        Initialize();

        // [GIVEN] Set up Expiration Date for the Lot No.
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());

        // [GIVEN] Create Location with pick according to FEFO.
        CreateLocationWithPostingSetupAndPickAccordingTOFEFO(Location, ShipmentBinCode);

        // [GIVEN] Item with Lot No. tracking.
        LibraryInventory.CreateTrackedItem(Item, '', '', CreateItemTrackingCode(false, true, true, false, true));

        // [GIVEN] Positive adjustment with Lot = "X" and ExpirationDate = D1 , Lot = "Y" and ExpirationDate = D2 and D2 > D1.
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        SelectItemJournalAndPostItemJournalLine(
          LotNo[1], Bin.Code, '', Item."No.", Location.Code, '', 1, ExpirationDate,
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", false);
        SelectItemJournalAndPostItemJournalLine(
          LotNo[2], Bin.Code, '', Item."No.", Location.Code, '', 1,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', ExpirationDate),
          ItemJournalBatch."Template Type"::Item, ItemJournalLine."Entry Type"::"Positive Adjmt.", false);

        // [GIVEN] Create Sales order and reserve the first Lot No. "LOT0001" with Expiration Date = D1.
        CreateSOAndTrackInventory(SalesHeader[1], Item."No.", Location.Code, 1);

        // Create seconf sales order and reserve the second Lot No. "LOT0002" with Expiration Date = D2.
        CreateSOAndTrackInventory(SalesHeader[2], Item."No.", Location.Code, 1);

        // [GIVEN] Create Warehouse Shipment from Sales Order second.
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader[2]);

        // [WHEN] CreatePick From Warehouse Shipment.
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);

        // [WHEN] Register Pick should not fail with error "Lot No. is not available on inventory" for the first Lot No. "LOT0001" with Expiration Date = D1.
        WarehouseActivityLine.SetRange("Item No.", Item."No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [WHEN] Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [THEN] Item Ledger Entry for the first Lot No. "LOT0001" with Expiration Date = D1 should be created.
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        Assert.AreEqual(LotNo[1], ItemLedgerEntry."Lot No.", StrSubstNo(ILELotNotMatchedErr, LotNo[1]));
    end;

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Item Tracking");
        // Clear Global variables.
        LibraryVariableStorage.Clear();
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Item Tracking");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Item Tracking");
    end;

    local procedure CreateAndFindProdOrderWithIT(var ProdOrderLine: Record "Prod. Order Line")
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
    begin
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        OpenItemTrackingLinesForProduction(ProductionOrder.Status, ProductionOrder."No.");
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."No.");
    end;

    local procedure CreateAndPostMultipleItemJournalLineWithTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; BinCode2: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Variant;
    begin
        // Item Tracking Lines page is handled in ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Dequeue(Quantity);
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, ItemNo, LocationCode, BinCode, Quantity, ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.OpenItemTrackingLines(false);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, ItemNo, LocationCode, BinCode2, Quantity, ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndVerifyTrackingLinesForSales(LocationCode: Code[10]; BinCode: Code[20]; BinCode2: Code[20]; BinCode3: Code[20])
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Quantity: Variant;
    begin
        LibraryVariableStorage.Dequeue(Quantity);
        CreateItem(Item, CreateItemTrackingCode(false, true, true, false, false));
        CreateAndPostMultipleItemJournalLineWithTracking(Item."No.", LocationCode, BinCode, BinCode2);

        // Exercise: Create Sales Order with Location and Bin.
        CreateSalesOrderWithBin(SalesLine, Item."No.", Quantity, LocationCode, BinCode3);

        // Verify: Verify available Lot No. on Item Tracking Line.
        SalesLine.OpenItemTrackingLines();  // Item Tracking Lines page is handled in ItemTrackingLinesPageHandler and Verification done in ItemTrackingSummaryPageHandler.
    end;

    local procedure CreateAndReservSalesLine(var SalesLine: Record "Sales Line")
    var
        ItemJournalLine: Record "Item Journal Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries;
        ReservationOption: Option ReserveFromCurrentLine,CancelReservFromCurrentLine,VerifyQuantity;
    begin
        CreateAndPostItemJnlLine(ItemJournalLine, '', '');
        CreateSalesDocument(SalesLine, ItemJournalLine."Item No.", '', ItemJournalLine.Quantity);  // Take random for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();

        // Reserve from current line.
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationFromCurrentLineHandler.
        SalesLine.ShowReservation();

        // Cancel from current line.
        SalesLine.Get(SalesLine."Document Type"::Order, SalesLine."Document No.", SalesLine."Line No.");
        LibraryVariableStorage.Enqueue(LibraryInventory.GetReservConfirmText());  // Enqueue value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(ReservationOption::CancelReservFromCurrentLine);  // Enqueue value for ReservationFromCurrentLineHandler.
        LibraryVariableStorage.Enqueue(CancelReservMessage);  // Enqueue value for ConfirmHandler.
        SalesLine.ShowReservation();
    end;

    local procedure LateBindingSalesVsPurchase(var SalesLine: Record "Sales Line"; Serial: Boolean; Lot: Boolean; PartialReceipts: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        ReservationOption: Option ReserveFromCurrentLine,CancelReservFromCurrentLine,VerifyQuantity;
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries,AssignLot;
        QtyReceived: Decimal;
        "count": Integer;
        LotNo: Text;
    begin
        // Create Purchase Order.
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, Lot, Serial, false));
        CreatePurchaseOrder(PurchaseLine, Item."No.");
        UpdateGeneralPostingSetup(PurchaseLine);

        // Create Sales Order and reserve against purchase.
        CreateSalesDocument(SalesLine, Item."No.", '', PurchaseLine.Quantity);
        SalesLine.Validate("Shipment Date", PurchaseLine."Expected Receipt Date" + LibraryRandom.RandInt(7));
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(ReservationOption::ReserveFromCurrentLine);  // Enqueue value for ReservationFromCurrentLineHandler.
        SalesLine.ShowReservation();

        // Receive purchase order partially with item tracking.
        LotNo := LibraryUtility.GenerateRandomCode(ReservationEntry.FieldNo("Lot No."), DATABASE::"Reservation Entry");
        for count := 1 to PartialReceipts do begin
            PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
            PurchaseLine2.Validate("Qty. to Receive", count);
            PurchaseLine2.Modify(true);

            case true of
                Serial:
                    begin
                        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
                        LibraryVariableStorage.Enqueue(PurchaseLine2."Qty. to Receive"); // Specify the qty to create for serial nos.
                    end;
                Lot:
                    begin
                        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
                        LibraryVariableStorage.Enqueue(LotNo);
                        LibraryVariableStorage.Enqueue(PurchaseLine2.Quantity);
                    end;
            end;

            QtyReceived += PurchaseLine2."Qty. to Receive";
            AssignITAndPostPurchaseOrder(PurchaseLine2, false);
        end;

        // Assign item tracking on sales order.
        SalesLine.Validate("Qty. to Ship", QtyReceived);
        SalesLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();

        // Verify Reservation Entries after closing the item tracking page.
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.SetRange("Item Tracking", ReservationEntry."Item Tracking"::None);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Qty. to Invoice (Base)", -(SalesLine."Quantity (Base)" - SalesLine."Qty. to Ship (Base)"));
        ReservationEntry.TestField("Quantity (Base)", -(SalesLine.Quantity - SalesLine."Qty. to Ship"));

        // Post Sales Order.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    local procedure CreateAndPostItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreateItemJnlLineWithIT(ItemJournalLine, LocationCode, BinCode);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreatePOAndDeleteSalesLineWithOrderTracking(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries,AssignLot;
    begin
        LibraryVariableStorage.Enqueue(TrackingPolicyMessage);  // Enqueue value for MessageHandler.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '',
          CreateItemTrackingCode(false, false, true, false, false));
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking Only");
        Item.Modify(true);

        // Create and Post Purchase Order with Item Tracking Lot.
        CreatePurchaseOrder(PurchaseLine, Item."No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);  // Enqueue value for ItemTrackingLinesPageHandler.
        AssignITAndPostPurchaseOrder(PurchaseLine, false);

        // Create Sales Order, assign Item Tracking and delete Sales Line.
        CreateSalesDocument(SalesLine, PurchaseLine."No.", '', PurchaseLine.Quantity);  // Take random for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        DeleteSalesLine(SalesLine);
    end;

    local procedure CreateAndDeletedPlanningWkshWithComponent(var RequisitionLine: Record "Requisition Line")
    var
        PlanningComponent: Record "Planning Component";
    begin
        // Setup: Create Tracked Item, create Requisition Line assign Item Tracking and delete the Requisition Line.
        CreateRequisitionLineWithIT(RequisitionLine);
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.Validate("Item No.", RequisitionLine."No.");
        PlanningComponent.Validate(Quantity, RequisitionLine.Quantity);
        PlanningComponent.Validate("Quantity per", RequisitionLine.Quantity);
        PlanningComponent.Modify(true);
        RequisitionLine.Delete(true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20])
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(10));  // Use Random value for Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Modify(true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; EntryType: Enum "Item Ledger Document Type")
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemJournalLinePrepareBatch(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item);
        CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch, ItemNo, LocationCode, BinCode, Quantity, ItemJournalLine."Entry Type"::"Positive Adjmt.");
    end;

    local procedure CreateItemJnlLineWithIT(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10]; BinCode: Code[20])
    var
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries;
    begin
        // Create Item Journal Line with Item Tracking.
        CreateItemJournalLinePrepareBatch(ItemJournalLine, CreateSerialTrackedItem(), LocationCode, BinCode, LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    local procedure CreateItemJournalForRevaluation(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        CreateRevaluationJournalBatch(ItemJournalBatch);
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, WorkDate(), LibraryUtility.GetGlobalNoSeriesCode(), "Inventory Value Calc. Per"::Item, false, false, false, "Inventory Value Calc. Base"::" ", false);
    end;

    local procedure CreateItemTrackingCode(ManExpirDateEntryReqd: Boolean; LotWarehouseTracking: Boolean; LOTSpecific: Boolean; SNSpecific: Boolean; UseExpirationDates: Boolean): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, SNSpecific, LOTSpecific);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", LotWarehouseTracking);
        ItemTrackingCode.Validate("Use Expiration Dates", UseExpirationDates);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", ManExpirDateEntryReqd);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; ItemTrackingCode: Code[10]; ReorderingPolicy: Enum "Reordering Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateWhsePickFromSO(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        FindWhseActivityHeaderBySalesHeader(WarehouseActivityHeader, SalesHeader);
    end;

    local procedure CreateWhseShipmentFromSO(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWhseShptHeader(WarehouseShipmentHeader, SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateSerialTrackedItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", CreateSerialTrackingCode());
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSerialTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate(Description, ItemTrackingCode.Code);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateTrackedItem(var Item: Record Item; OrderTrackingPolicy: Enum "Order Tracking Policy"; ItemTrackingCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(TrackingPolicyMessage);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateTrackedItemWithInventoryStock(var Item: Record Item; LotNos: array[2] of Code[20]; Quantity: array[2] of Decimal; Bin: Record Bin)
    var
        I: Integer;
    begin
        CreateItem(Item, CreateItemTrackingCode(false, true, true, false, false));  // Lot specific tracking without expiration date

        for I := 1 to ArrayLen(LotNos) do
            PostPositiveAdjustmentWithLotTracking(Item."No.", Bin."Location Code", Bin.Code, LotNos[I], Quantity[I]);
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

    local procedure CreateSalesOrderWithItemAndLocation(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Qty: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
    end;

    local procedure CreateSalesDocumentWithTracking(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        CreateSalesDocument(SalesLine, ItemNo, LocationCode, Quantity);
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesLine."Document No.");

        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);
        SalesLine.OpenItemTrackingLines();

        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateLocationWithPostingSetup(var Location: Record Location; BinMandatory: Boolean; DirectedPutawayAndPick: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", BinMandatory);
        Location.Validate("Directed Put-away and Pick", DirectedPutawayAndPick);
        Location.Modify(true);
    end;

    local procedure CreateFullWMSLocationWithBins(Bins: Integer): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, Bins);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        exit(Location.Code);
    end;

    local procedure CreateAndPostPurchaseOrderWithBin(ItemNo: Code[20]; BinCode: Code[20]; LocationCode: Code[10]; Invoice: Boolean): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
        UpdateGeneralPostingSetup(PurchaseLine);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        AssignITAndPostPurchaseOrder(PurchaseLine, Invoice);
        exit(PurchaseLine.Quantity);
    end;

    local procedure CreateAndReleaseSO(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(10, 50));  // Use random value for Quantity and taking integer value required for Test case.
    end;

    local procedure CreateProdOrderComponentWithIT(var ProductionOrder: Record "Production Order"): Code[20]
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
    begin
        // Create tracked Items for Production Order Component, create Production BOM, attach it to Item, create and refresh Production Order and assign Item Tracking and find Production Order Component.
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        LibraryInventory.CreateTrackedItem(Item2, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        LibraryInventory.CreateTrackedItem(Item3, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));

        // Random value taken for Quantity per.
        LibraryManufacturing.CreateCertifProdBOMWithTwoComp(ProductionBOMHeader, Item2."No.", Item3."No.", LibraryRandom.RandInt(5));
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
        CreateAndRefreshProdOrder(ProductionOrder, Item."No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        OpenItemTrackingLinesForProduction(ProductionOrder.Status, ProductionOrder."No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarining);  // Enqueue value for ConfirmHandler.
        OpenItemTrackingLinesForProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", Item2."No.");
        exit(Item2."No.");
    end;

    local procedure CreatePickFromSOAndPostShipment(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Integer)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        CreateAndReleaseSO(SalesHeader, ItemNo, LocationCode, Quantity);
        CreateWhseShipmentFromSO(WarehouseShipmentHeader, SalesHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    local procedure CreateLocationWithPostingSetupAndPickAccordingTOFEFO(var Location: Record Location; var ShipmentBinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        CreateLocationWithPostingSetup(Location, true, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        ShipmentBinCode := Bin.Code;
        Location.Validate("Require Pick", true);
        Location.Validate("Require Shipment", true);
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Validate("Pick According to FEFO", true);
        Location.Modify(true);
    end;

    local procedure CreateLocationWithRequireShip(var Bin: Record Bin)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", true);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
    end;

    local procedure CreateLocationWithRequireShipAndTwoBins(var Location: Record Location; var Bin: array[2] of Record Bin)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        LibraryWarehouse.CreateBin(Bin[1], Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, LibraryUtility.GenerateGUID(), '', '');

        Location.Validate("Require Shipment", true);
        Location.Validate("Bin Mandatory", true);
        Location.Validate("Shipment Bin Code", Bin[1].Code);
        Location.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateRefreshPlanningWksh(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        CleanUpAndCreateReqLine(RequisitionLine, ItemNo, '', Quantity);
        RequisitionLine.Validate("Location Code", LocationCode);
        RequisitionLine.Validate("Ending Date", WorkDate());
        RequisitionLine.Modify(true);
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        RequisitionLine.SetRange("Line No.", RequisitionLine."Line No.");
        REPORT.RunModal(REPORT::"Refresh Planning Demand", false, false, RequisitionLine);
    end;

    local procedure AssignITAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; Invoice: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseLine.OpenItemTrackingLines();
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);
    end;

    local procedure AssignLotNoToSalesLine(SalesLine: Record "Sales Line"; LotNo: Code[50])
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        SalesLine.OpenItemTrackingLines();
    end;

    local procedure CreateRevaluationJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateRequisitionLineWithIT(var RequisitionLine: Record "Requisition Line")
    var
        Item: Record Item;
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
    begin
        // Setup: Create Tracked Item, create Requisition Line assign Item Tracking and delete the Requisition Line.
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        CleanUpAndCreateReqLine(RequisitionLine, Item."No.", CreateVendor(), LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        RequisitionLine.OpenItemTrackingLines();
    end;

    local procedure CreateTransferOrderWithIT(var TransferLine: Record "Transfer Line")
    var
        Item: Record Item;
        Location: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries,AssignLot;
    begin
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(LocationTo);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, Location.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(10));
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarining);  // Enqueue value for ConfirmHandler.
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
    end;

    local procedure CleanUpAndCreateReqLine(var RequisitionLine: Record "Requisition Line"; No: Code[20]; VendorNo: Code[20]; QtyToSet: Decimal)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        FindWkshTemplate(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        RequisitionLine.DeleteAll(true);
        LibraryPlanning.CreateRequisitionLine(
          RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", No);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Validate(Quantity, QtyToSet);
        // Using Random value for Quantity.
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithBin(var SalesLine: Record "Sales Line"; No: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', No, Quantity, LocationCode, 0D);
        SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSilverLocation(var Bin: Record Bin)
    var
        Location: Record Location;
    begin
        CreateLocationWithPostingSetup(Location, true, false);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');  // Use blank values for Unit Of Measure Code and Zone Code.
    end;

    local procedure CreateTransitLocation(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateInTransitLocation(Location);
        exit(Location.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateWhseJournalBatchInItemTemplate(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationCode);
    end;

    local procedure CreateTwoWhseJournalLinesWithItemTracking(WarehouseJournalBatch: Record "Warehouse Journal Batch"; ItemNo: Code[20]; LotNo: Code[50]; BinCode: array[2] of Code[20]; StockQty: array[2] of Integer)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(BinCode) do begin
            Clear(WarehouseJournalLine);
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
              WarehouseJournalBatch."Location Code", '', BinCode[Index], WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
              ItemNo, StockQty[Index]);
            LibraryVariableStorage.Enqueue(LotNo);
            LibraryVariableStorage.Enqueue(WarehouseJournalLine.Quantity);
            WarehouseJournalLine.OpenItemTrackingLines();
        end;
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20])
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        // Use Random value for Quantity.
        LibraryWarehouse.CreateWarehouseJournalBatch(
            WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, ZoneCode, BinCode,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateWhiteLocation(var Bin: Record Bin; Item: Record Item)
    var
        BinContent: Record "Bin Content";
        Location: Record Location;
        Zone: Record Zone;
    begin
        CreateLocationWithPostingSetup(Location, true, true);
        CreateZone(Zone, Location.Code);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
        LibraryWarehouse.CreateBinContent(BinContent, Location.Code, Zone.Code, Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        Location.Validate("Adjustment Bin Code", Bin.Code);
        Location.Modify(true);
    end;

    local procedure CreateWhseShptWithIT(var SalesLine: Record "Sales Line"; TrackingOptionValue: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesLine, CreateSerialTrackedItem(), CreateWhseLocation(true), LibraryRandom.RandInt(10));  // Take random for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOptionValue);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarining);  // Enqueue value for ConfirmHandler.
        if TrackingOptionValue = TrackingOption::AssignLotNo then begin
            LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
            LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        end;
        SalesLine.OpenItemTrackingLines();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        CreateWhseShpt(SalesLine."Document No.");
    end;

    local procedure CreateWhseLocation(DirectedPutAwayPick: Boolean): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        Location.Validate("Directed Put-away and Pick", DirectedPutAwayPick);
        Location.Modify(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        exit(Location.Code);
    end;

    local procedure CreateWhseShpt(DocumentNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreatePostWhseRcpt(PurchHeader: Record "Purchase Header")
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchHeader);
        FindWhseRcptHeader(WarehouseReceiptHeader, PurchHeader."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateZone(var Zone: Record Zone; LocationCode: Code[10])
    var
        WarehouseClass: Record "Warehouse Class";
    begin
        // Select Bin Type where Receive, Ship is False and Put Away, Pick is True.
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);
        LibraryWarehouse.CreateZone(
          Zone, '', LocationCode, LibraryWarehouse.SelectBinType(false, false, true, true), WarehouseClass.Code, '', 0, false);  // Use zero for Zone Ranking and False for Cross-Dock Bin Zone.
    end;

    local procedure CreateRegisterWhsePick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseShipmentLine: Record "Warehouse Shipment Line"; QtyToPost: Decimal)
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        ModifyWhsePick(WarehouseActivityLine, WarehouseShipmentHeader, QtyToPost);
        RegisterWhsePick(WarehouseActivityHeader, WarehouseActivityLine);
    end;

    local procedure ModifyRegisterWhsePick(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LotNo: Code[50])
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        ModifyWhsePick(WarehouseActivityLine, WarehouseShipmentHeader, 0);
        WarehouseActivityHeader.Init();
        RegisterWhsePick(WarehouseActivityHeader, WarehouseActivityLine);
    end;

    local procedure ModifyWhsePick(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; QtyToSet: Decimal)
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseShipmentHeader);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QtyToSet);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure RegisterWhsePick(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SetBinMandatory(LocationCode: Code[10]; BinMandatoryToSet: Boolean)
    var
        Location: Record Location;
    begin
        Location.Get(LocationCode);
        Location.Validate("Bin Mandatory", BinMandatoryToSet);
        Location.Modify(true);
    end;

    local procedure SelectItemJournalAndPostItemJournalLine(var LotNo: Code[10]; BinCode: Code[20]; NewBinCode: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; NewLotNo: Code[10]; Quantity: Integer; ExpirationDate: Date; ItemJournalTemplateType: Enum "Item Journal Template Type"; EntryType: Enum "Item Ledger Document Type"; IsReclass: Boolean)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalTemplateType);
        CreateItemJournalLine(ItemJournalLine, ItemJournalBatch, ItemNo, LocationCode, BinCode, Quantity, EntryType);
        if NewBinCode <> '' then
            ItemJournalLine.Validate("New Bin Code", NewBinCode);
        ItemJournalLine.Modify(true);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        if LotNo = '' then
            LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        ItemJournalLine.OpenItemTrackingLines(IsReclass);
        SetExpirationDateAndLotNoInItemTrackingLine(ItemNo, ItemJournalBatch.Name, NewLotNo, ExpirationDate);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure PostProductionOutputWithIT(ItemNo: Code[20]; Quantity1: Decimal; Quantity2: Decimal) LotNo: Code[50]
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNos);
        LibraryVariableStorage.Enqueue(2);
        // Number of lines
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        // Lot No to assign
        LibraryVariableStorage.Enqueue(Quantity1);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(LotNo);
        // Lot no to assign
        LibraryVariableStorage.Enqueue(Quantity2);

        LibraryVariableStorage.Enqueue(Quantity1 + Quantity2);
        // Enqueue for ProductionJournalHandler
        LibraryVariableStorage.Enqueue(PostJournalQst);
        // Enqueue for ConfirmHandler
        LibraryVariableStorage.Enqueue(JournalPostedMsg); // Enqueue for MessageHandler

        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProductionOrder.Get(ProductionOrder.Status::Released, ProdOrderLine."Prod. Order No.");
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
    end;

    local procedure PostWhseAdjustmentItemJournal(ItemNo: Code[20]; PostingDate: Date)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        Item.Get(ItemNo);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, PostingDate, '');
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateWhseActivityLinesLotNoForSales(WarehouseActivityHeader: Record "Warehouse Activity Header"; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure DeleteTrackingOnPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries,AssignLot;
    begin
        // Create Tracked Item, create Purchase Order with Item Tracking and delete the Tracking Lines.
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        CreatePurchaseOrder(PurchaseLine, Item."No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ITConfirmMessage);  // Enqueue value for ConfirmHandler.
        PurchLineReserve.DeleteLineConfirm(PurchaseLine);
        PurchLineReserve.DeleteLine(PurchaseLine);
    end;

    local procedure CreateAndDeletePurchaseHeader(): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries,AssignLot;
    begin
        // Create Tracked Item, create Purchase Order with Item Tracking and delete the Purchase Header with Tracking Lines.
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        CreatePurchaseOrder(PurchaseLine, Item."No.");
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(DeletionMessage);  // Enqueue value for ConfirmHandler.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.Delete(true);
        exit(PurchaseHeader."No.");
    end;

    local procedure DeleteRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
        CreateRequisitionLineWithIT(RequisitionLine);
        RequisitionLine.Delete(true);
    end;

    local procedure DeleteSalesLineITWithConfirmFalse(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
        ConfirmOption: Option SerialSpecificTrue,SerialSpecificFalse;
    begin
        // Create Item with Item Tracking Code, create Sales Order and assign Item Tracking.
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        CreateSalesDocument(SalesLine, Item."No.", '', LibraryRandom.RandInt(10));  // Take random for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarining);  // Enqueue value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(ConfirmOption::SerialSpecificTrue);  // Enqueue value for ConfirmHandlerForReservation.
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(ITConfirmMessage);  // Enqueue value for ConfirmHandler.
        LibraryVariableStorage.Enqueue(ConfirmOption::SerialSpecificFalse);  // Enqueue value for ConfirmHandlerForReservation.
        SalesLineReserve.DeleteLineConfirm(SalesLine);
        asserterror SalesLineReserve.DeleteLine(SalesLine);
    end;

    local procedure DeleteSalesLineIT(var SalesLine: Record "Sales Line")
    var
        Item: Record Item;
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
    begin
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(),
          CreateItemTrackingCode(false, false, false, true, false));
        CreateSalesDocument(SalesLine, Item."No.", '', LibraryRandom.RandInt(10));  // Take random for Quantity.
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(AvailabilityWarining);  // Enqueue value for ConfirmHandler.
        SalesLine.OpenItemTrackingLines();
        DeleteSalesLine(SalesLine);
    end;

    local procedure DeleteSalesLineITWithCancelReserv(): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        CreateAndReservSalesLine(SalesLine);
        DeleteSalesLine(SalesLine);
        exit(SalesLine."Document No.");
    end;

    local procedure DeleteSalesLine(SalesLine: Record "Sales Line")
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
    begin
        LibraryVariableStorage.Enqueue(ITConfirmMessage);  // Enqueue value for ConfirmHandler.
        SalesLineReserve.DeleteLineConfirm(SalesLine);
        SalesLineReserve.DeleteLine(SalesLine);
    end;

    local procedure DeleteSalesLineUsingBinWithIT(): Code[20]
    var
        Bin: Record Bin;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo,SelectEntries,AssignLot;
    begin
        CreateSilverLocation(Bin);
        CreateAndPostItemJnlLine(ItemJournalLine, Bin."Location Code", Bin.Code);
        CreateSalesDocument(SalesLine, ItemJournalLine."Item No.", Bin."Location Code", ItemJournalLine.Quantity);  // Take random for Quantity.
        ModifySalesLine(SalesLine, ItemJournalLine."Bin Code");
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        DeleteSalesLine(SalesLine);
        exit(SalesLine."Document No.");
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; QuantityBase: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Quantity (Base)", QuantityBase);
    end;

    local procedure FilterReservationBySource(var ReservEntry: Record "Reservation Entry"; SourceType: Integer; SourceNo: Code[20]; SourceRefNo: Integer)
    begin
        ReservEntry.SetRange("Source Type", SourceType);
        ReservEntry.SetRange("Source ID", SourceNo);
        ReservEntry.SetRange("Source Ref. No.", SourceRefNo);
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindPostedLotNos(var LotNos: array[2] of Code[50]; LocationCode: Code[10]; ItemNo: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Location Code", LocationCode);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst();

        LotNos[1] := WarehouseEntry."Lot No.";
        WarehouseEntry.FindLast();
        LotNos[2] := WarehouseEntry."Lot No.";
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    begin
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindPutPickBin(Location: Record Location): Code[20]
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", Location.Code);
        Bin.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));
        Bin.SetRange("Cross-Dock Bin", false);
        Bin.FindFirst();

        exit(Bin.Code);
    end;

    local procedure FindTwoBinsInLocation(var BinCode: array[2] of Code[20]; LocationCode: Code[10]; BinTypeCode: Code[10])
    var
        Bin: Record Bin;
    begin
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Bin Type Code", BinTypeCode);
        Bin.FindSet();
        BinCode[1] := Bin.Code;
        Bin.Next();
        BinCode[2] := Bin.Code;
    end;

    local procedure FindReservEntry(SourceID: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.FindFirst();
    end;

    local procedure FindWhseShptHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; DocumentType: Option; DocumentNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWhseShptLine(WarehouseShipmentLine, DATABASE::"Sales Line", DocumentType, DocumentNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure FindWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Type", SourceType);
        WarehouseShipmentLine.SetRange("Source Subtype", SourceSubtype);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseActivityLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type"::Shipment);
        WarehouseActivityLine.SetRange("Whse. Document No.", WarehouseShipmentHeader."No.");
        WarehouseActivityLine.FindSet();
    end;

    local procedure FindWhseActivityHeaderBySalesHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.FindFirst();
        LibraryWarehouse.FindWhseActivityBySourceDoc(
          WarehouseActivityHeader, DATABASE::"Sales Line", 1, SalesHeader."No.", SalesLine."Line No.");
    end;

    local procedure FindWhseRcptHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SourceNo: Code[20])
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
    end;

    local procedure FindWkshTemplate(var RequisitionWkshName: Record "Requisition Wksh. Name"; TemplateType: Enum "Req. Worksheet Template Type")
    begin
        RequisitionWkshName.SetRange("Template Type", TemplateType);
        RequisitionWkshName.SetRange(Recurring, false);
        RequisitionWkshName.FindFirst();
    end;

    local procedure FindRegisterPutAway(PurchaseHeader: Record "Purchase Header")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseActivityLine.FindFirst();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ModifySalesLine(SalesLine: Record "Sales Line"; Bincode: Code[20])
    begin
        SalesLine.Validate("Bin Code", Bincode);
        SalesLine.Modify(true);
    end;

    local procedure OpenItemTrackingLinesForProduction(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        FindProductionOrderLine(ProdOrderLine, ProdOrderStatus, ProdOrderNo);
        ProdOrderLine.OpenItemTrackingLines();  // Open Item Tracking Lines on Page Handler.
    end;

    local procedure OpenItemTrackingLinesForProdOrderComponent(Status: Enum "Production Order Status"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        FindProdOrderComponent(ProdOrderComponent, Status, ProdOrderNo, ItemNo);
        ProdOrderComponent.OpenItemTrackingLines();  // Open Tracking Line on Page Handler.
    end;

    local procedure PostItemJournalLineWithTracking(ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure PostPositiveAdjustmentWithLotTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLinePrepareBatch(ItemJournalLine, ItemNo, LocationCode, BinCode, Quantity);

        LibraryVariableStorage.Enqueue(TrackingOption::AssignLotNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Quantity);
        PostItemJournalLineWithTracking(ItemJournalLine);
    end;

    local procedure PostPositiveAdjustmentWithLotNo(ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLinePrepareBatch(ItemJournalLine, ItemNo, '', '', Quantity);

        LibraryVariableStorage.Enqueue(TrackingOption::AssignLot);
        PostItemJournalLineWithTracking(ItemJournalLine);
    end;

    local procedure PostPositiveAdjustmentWithSNTracking(ItemNo: Code[20]; SerialNo: Code[50])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLinePrepareBatch(ItemJournalLine, ItemNo, '', '', 1);

        LibraryVariableStorage.Enqueue(TrackingOption::AssignManualSN);
        LibraryVariableStorage.Enqueue(SerialNo);
        PostItemJournalLineWithTracking(ItemJournalLine);
    end;

    local procedure PostProdOrderOutputWithLotTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; OutputQty: Decimal; Lot1Qty: Decimal; Lot2Qty: Decimal)
    var
        ProductionOrder: Record "Production Order";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, OutputQty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        PostProductionOutputWithIT(ItemNo, Lot1Qty, Lot2Qty);
    end;

    local procedure RegisterWarehouseActivity(WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWhseActivityLine(WarehouseActivityLine, WarehouseShipmentHeader);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; ItemJnlTemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJnlTemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJnlTemplateType, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetExpirationDateAndLotNoInItemTrackingLine(ItemNo: Code[20]; ItemJournalBatchName: Code[10]; NewLotNo: Code[10]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Batch Name", ItemJournalBatchName);
        ReservationEntry.FindFirst();
        ReservationEntry.Validate("Expiration Date", ExpirationDate);
        ReservationEntry.Validate("New Lot No.", NewLotNo);
        ReservationEntry.Modify(true);
    end;

    local procedure SplitWhseActivityLine(ItemNo: Code[20]; ActionType: Enum "Warehouse Action Type"; NewQtyToHandle: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.Validate("Qty. to Handle", NewQtyToHandle);
        WarehouseActivityLine.Modify(true);
        WarehouseActivityLine.SplitLine(WarehouseActivityLine);
    end;

    local procedure SplitWhseActivityLineAndUpdateTracking(ItemNo: Code[20]; ActionType: Enum "Warehouse Action Type"; NewQtyToHandle: Decimal; LotNos: array[2] of Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ZoneCode: Code[10];
        BinCode: Code[20];
    begin
        SplitWhseActivityLine(ItemNo, ActionType, NewQtyToHandle);

        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.FindFirst();
        ZoneCode := WarehouseActivityLine."Zone Code";
        BinCode := WarehouseActivityLine."Bin Code";
        WarehouseActivityLine.Validate("Lot No.", LotNos[1]);
        WarehouseActivityLine.Modify(true);

        WarehouseActivityLine.FindLast();
        WarehouseActivityLine.Validate("Zone Code", ZoneCode);
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Validate("Lot No.", LotNos[2]);
        WarehouseActivityLine.Modify(true);
    end;

    local procedure UpdateExpirationDateOnWhseItemTrackingLine(LocationCode: Code[10]; ItemNo: Code[20])
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ExpirationDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpirationDate);
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetup(PurchaseLine: Record "Purchase Line")
    var
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Purch. Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateQtyToShipInWhseShipment(WhseShipmentNo: Code[20]; NewQty: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", WhseShipmentNo);
        WarehouseShipmentLine.FindSet();
        repeat
            WarehouseShipmentLine.Validate("Qty. to Ship", NewQty);
            WarehouseShipmentLine.Modify();
        until WarehouseShipmentLine.Next() = 0;
    end;

    local procedure VerifyExpirationDateForItemTracking(LocationCode: Code[10]; ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
        ExpirationDate: Date;
    begin
        ExpirationDate := LibraryVariableStorage.DequeueDate();
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Expiration Date", ExpirationDate);
    end;

    local procedure VerifyQuantityOnTransferLine(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
        TransferLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedWhseShipment(WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", WarehouseShipmentHeader."No.");
        Assert.IsFalse(PostedWhseShipmentHeader.IsEmpty, WhseShpmtWasNotPostedErr);
    end;

    local procedure VerifyRegisteredWhseActivity(ItemNo: Code[20])
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        Assert.IsFalse(RegisteredWhseActivityLine.IsEmpty, CouldNotRegisterWhseActivityErr);
    end;

    local procedure VerifyLotReservation(SalesLine: Record "Sales Line"; LotNo: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
    begin
        FilterReservationBySource(ReservEntry, DATABASE::"Sales Line", SalesLine."Document No.", SalesLine."Line No.");
        ReservEntry.SetRange(Positive, false);
        ReservEntry.SetRange("Lot No.", LotNo);
        ReservEntry.CalcSums(Quantity);
        ReservEntry.TestField(Quantity, -SalesLine.Quantity);
    end;

    local procedure VerifyReservedQuantity(DocumentType: Option; DocumentNo: Code[20]; ExpectedQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Source Type", DATABASE::"Sales Line");
        ReservationEntry.SetRange("Source Subtype", DocumentType);
        ReservationEntry.SetRange("Source ID", DocumentNo);
        ReservationEntry.CalcSums(Quantity);

        ReservationEntry.TestField(Quantity, ExpectedQty);
    end;

    local procedure VerifySerialReservation(SalesLine: Record "Sales Line"; SerialNo: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
    begin
        FilterReservationBySource(ReservEntry, DATABASE::"Sales Line", SalesLine."Document No.", SalesLine."Line No.");
        ReservEntry.FindFirst();
        ReservEntry.TestField("Serial No.", SerialNo);
    end;

    local procedure VerifyTrackingSpecQtyToInvoice(SalesLine: Record "Sales Line")
    var
        TrackingSpec: Record "Tracking Specification";
    begin
        TrackingSpec.SetRange("Item No.", SalesLine."No.");
        TrackingSpec.SetRange("Source Type", DATABASE::"Sales Line");
        TrackingSpec.SetRange("Source Subtype", SalesLine."Document Type");
        TrackingSpec.SetRange("Source ID", SalesLine."Document No.");
        TrackingSpec.FindFirst();
        TrackingSpec.TestField("Qty. to Invoice (Base)", -SalesLine."Qty. to Invoice");
    end;

    local procedure VerifyLotNoInWarehouseActivityLine(ItemNo: Code[20]; SalesHeaderNo: Code[20]; ExpectedLotNo: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Source No.", SalesHeaderNo);
        WarehouseActivityLine.FindFirst();
        WarehouseActivityLine.TestField("Lot No.", ExpectedLotNo);
    end;

    local procedure UndoPostedShipmentLine(SalesHeaderNo: Code[20]; ItemNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.SetRange("Order No.", SalesHeaderNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure CreateSOAndTrackInventory(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        SalesLine.Modify(true);
        SalesLine.ShowReservation();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreateWithGivenQtyPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        DecimalValue: Variant;
        Qty: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DecimalValue);  // Dequeue variable.
        Qty := DecimalValue;  // To convert Variant into Option.
        EnterQuantityToCreate.QtyToCreate.SetValue(Qty);
        EnterQuantityToCreate.CreateNewLotNo.SetValue(false);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingOptionValue: Option;
    begin
        TrackingOptionValue := LibraryVariableStorage.DequeueInteger();
        case TrackingOptionValue of
            TrackingOption::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingOption::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
            TrackingOption::AssignLot:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingOption::AssignLotNo:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            TrackingOption::VerifyLotNo:
                ItemTrackingLines."Lot No.".AssistEdit();
            TrackingOption::AssignLotNos:
                AssignLotNos(ItemTrackingLines);
            TrackingOption::SetQtyToInvoice:
                ItemTrackingLines."Qty. to Invoice (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
            TrackingOption::AssignManualSN:
                begin
                    ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(1);
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    var
        BinQuantity: Variant;
        QuantityVariant: Variant;
        LotNo: Variant;
        Quantity: Decimal;
    begin
        LibraryVariableStorage.Dequeue(QuantityVariant);
        LibraryVariableStorage.Dequeue(BinQuantity);
        LibraryVariableStorage.Dequeue(LotNo);
        Quantity := QuantityVariant;
        ItemTrackingSummary."Lot No.".AssertEquals(LotNo);
        ItemTrackingSummary."Total Quantity".AssertEquals(2 * Quantity);
        ItemTrackingSummary."Total Available Quantity".AssertEquals(2 * Quantity);
        ItemTrackingSummary."Total Requested Quantity".AssertEquals(0);  // Total Requested Quantity must be zero before assigning the Lot No.
        ItemTrackingSummary."Bin Content".AssertEquals(BinQuantity);
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
    procedure InvokeItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure RegisterWhseMessageHandler(Message: Text[1024])
    begin
        // Message Handler.
        Assert.IsTrue(StrPos(Message, RegisterWhseMessage) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        WhseItemTrackingLines.Quantity.SetValue(WhseItemTrackingLines.Quantity3.AsInteger());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandlerWithDequeue(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        WhseItemTrackingLines.OK().Invoke();
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

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DummyConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        OptionValue: Variant;
        OptionString: Option ReserveFromCurrentLine,CancelReservFromCurrentLine,VerifyQuantity;
        ReservationOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        ReservationOption := OptionValue;  // To convert Variant into Option.
        case ReservationOption of
            OptionString::ReserveFromCurrentLine:
                Reservation."Reserve from Current Line".Invoke();
            OptionString::CancelReservFromCurrentLine:
                begin
                    Reservation.CancelReservationCurrentLine.Invoke();
                    Reservation.QtyReservedBase.AssertEquals(0);
                end;
        end;
        Reservation.OK().Invoke();
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

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.ItemTrackingLines.Invoke();
        ProductionJournal."Output Quantity".SetValue(LibraryVariableStorage.DequeueDecimal());
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReservationFromCurrentLineHandler(var Reservation: TestPage Reservation)
    begin
        Reservation."Reserve from Current Line".Invoke();
        Reservation.OK().Invoke();
    end;

    local procedure AssignLotNos(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        LinesToProcess: Integer;
        LotNo: Text;
        LotQty: Decimal;
    begin
        ItemTrackingLines.First();
        for LinesToProcess := LibraryVariableStorage.DequeueInteger() downto 1 do begin
            LotNo := LibraryVariableStorage.DequeueText();
            LotQty := LibraryVariableStorage.DequeueDecimal();
            ItemTrackingLines."Lot No.".SetValue(LotNo);
            ItemTrackingLines."Quantity (Base)".SetValue(LotQty);
            ItemTrackingLines.Next();
        end;
    end;
}

