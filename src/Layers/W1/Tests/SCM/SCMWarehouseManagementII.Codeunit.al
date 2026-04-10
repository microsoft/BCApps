codeunit 137154 "SCM Warehouse Management II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [SCM]
        isInitialized := false;
    end;

    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        LotItemTrackingCode: Record "Item Tracking Code";
        LocationBlack: Record Location;
        LocationBlue: Record Location;
        LocationGreen: Record Location;
        LocationIntransit: Record Location;
        LocationRed: Record Location;
        LocationSilver: Record Location;
        LocationWhite: Record Location;
        LocationYellow: Record Location;
        LocationOrange: Record Location;
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        OutputItemJournalTemplate: Record "Item Journal Template";
        OutputItemJournalBatch: Record "Item Journal Batch";
        PhysicalInventoryItemJournalTemplate: Record "Item Journal Template";
        PhysicalInventoryItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        BinContentMustBeEmpty: Label 'Bin Content must be empty.';
        ExpiredItemMessage: Label 'There is nothing to handle. \\Some items were not included in the pick due to their expiration date.';
        PickCreated: Label 'Number of Invt. Pick activities created';
        QuantityMustBeSame: Label 'Quantity must be same.';
        MustBeEmpty: Label '%1 must be empty.';
        TransferOrderDeleted: Label 'Transfer order %1 was successfully posted and is now deleted.', Comment = '%1 = Transfer Order No.';
        LotNumberRequiredForItem: Label 'You must assign a lot number for item %1', Comment = '%1 - Item No.';
        UndoConfirmMessage: Label 'Do you really want to undo the selected ';
        PickedConfirmMessage: Label 'The items have been picked.';
        UndoErrorMessage: Label 'You cannot undo line %1 because warehouse activity lines have already been created.';
        UndoErrorMessage_Shipment: Label 'You cannot undo line %1 because warehouse shipment lines have already been created.';
        CancelReservationConfirmMessage: Label 'Do you want to cancel all reservations in the %1?';
        GetSourceDocErr: Label '%1 source documents were not included because the customer is blocked.';
        CheckShipmentLineErr: Label 'Expect shipment line from Source No. %1 exist: %2, contrary to actual result';
        CheckReceiptLineErr: Label 'Expect Receipt Linefrom Source No. %1 exist: %2, contrary to actual result';
        ShipmentLinesNotCreatedErr: Label 'There are no warehouse shipment lines created.';
        ReceiptLinesNotCreatedErr: Label 'There are no warehouse receipt lines created.';
        ItemTrackingMode: Option " ","Assign Lot No.","Assign Multiple Lot No.","Assign Serial No.","Assign Lot And Serial","Select Entries","Blank Quantity Base","Assign Lot No. & Expiration Date","Assign Manual Lot Nos","Show Entries";
        DescriptionMustBeSame: Label 'Description must be same.';
        InputQtyErr: Label 'Input Quantity Must be %1 in %2', Comment = '1% = Remaining Quanity value, %2 = Prod. Order Routing Line';
        StartingDateTimeErr: Label 'Starting Date-Time must not be %1 in %2', Comment = '%1 = StartingDateTime value, %2 = Prod. Order Routing Line.';

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentReserveAgainstPurchaseOrder()
    begin
        // Setup.
        Initialize();
        PickFromWarehouseShipmentReserveAgainstPurchaseOrderAndAvailableInventory(false);  // Reserve against only Purchase Order.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromWarehouseShipmentReserveAgainstBothPurchaseOrderAndAvailableInventory()
    begin
        // Setup.
        Initialize();
        PickFromWarehouseShipmentReserveAgainstPurchaseOrderAndAvailableInventory(true);  // Reserve against both Purchase Order and Available Inventory.
    end;

    local procedure PickFromWarehouseShipmentReserveAgainstPurchaseOrderAndAvailableInventory(ReserveAgainstBothPurchaseOrderAndAvailableInventory: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        OldAlwaysCreatePickLine: Boolean;
        ReservationMode: Option "Reserve From Current Line","Reserve From First Line","Verify Reserve Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Update Always Create Pick Line on Location. Create and register Put Away from Purchase Order. Create and release another Purchase Order. Create and release Sales Order.
        UpdateAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine, true);
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(100, 2);  // Value required for test.
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', Quantity2, WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndReleasePurchaseOrder(
          PurchaseHeader2, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', Quantity,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), false);  // Value required for test. Tracking as False.
        LibraryVariableStorage.Enqueue(ReservationMode::"Reserve From Current Line");  // Enqueue for ReservationPageHandler.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", LocationWhite.Code, '', Quantity,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', PurchaseLine."Expected Receipt Date"), true, false);  // Value required for test.

        // Exercise: Create Pick for Quantity reserved against Purchase Order.
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // Verify.
        SalesLine.Find();
        VerifyReservationEntry(Item."No.", DATABASE::"Purchase Line", PurchaseHeader2."No.", Quantity);
        VerifyPickLine(WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Item."No.", Quantity);
        VerifyPickLine(WarehouseActivityLine."Action Type"::Place, SalesHeader."No.", Item."No.", Quantity);

        if ReserveAgainstBothPurchaseOrderAndAvailableInventory then begin
            // Exercise: Create Pick for Quantity reserved against both Purchase Order and Item Ledger Entry.
            DeletePick(SalesHeader."No.");
            ReopenAndDeleteWarehouseShipment(WarehouseShipmentHeader);
            LibrarySales.ReopenSalesDocument(SalesHeader);
            LibraryVariableStorage.Enqueue(ReservationMode::"Reserve From First Line");  // Enqueue for ReservationPageHandler.
            UpdateQuantityOnSalesLineAndReserve(SalesLine, Quantity + Quantity2);  // Value required for test.
            LibrarySales.ReleaseSalesDocument(SalesHeader);
            CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

            // Verify.
            VerifyReservationEntry(Item."No.", DATABASE::"Purchase Line", PurchaseHeader2."No.", Quantity);
            VerifyReservationEntry(Item."No.", DATABASE::"Item Ledger Entry", '', Quantity2);
            VerifyPickLine(WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Item."No.", Quantity + Quantity2);  // Value required for test.
            VerifyPickLine(WarehouseActivityLine."Action Type"::Place, SalesHeader."No.", Item."No.", Quantity + Quantity2);  // Value required for test.
        end;

        // Tear down.
        UpdateAlwaysCreatePickLineOnLocation(LocationWhite, OldAlwaysCreatePickLine, OldAlwaysCreatePickLine);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetWithReservationBeforeUpdateQuantityToHandle()
    begin
        // Setup.
        Initialize();
        AvailableQuantityToPickOnPickWorksheetWithReservation(false);  // Without Update Quantity to Handle on Pick Worksheet.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure AvailableQuantityToPickOnPickWorksheetWithReservationAfterUpdateQuantityToHandle()
    begin
        // Setup.
        Initialize();
        AvailableQuantityToPickOnPickWorksheetWithReservation(true);  // With Update Quantity to Handle on Pick Worksheet.
    end;

    local procedure AvailableQuantityToPickOnPickWorksheetWithReservation(UpdateQuantityToHandle: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentHeader2: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        ReservationMode: Option "Reserve From Current Line","Reserve From First Line","Verify Reserve Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create and register Put Away from Purchase Order. Create and release Warehouse Shipment from Sales Order with partially reserved Quantity.
        // Create and release another Warehouse Shipment from Sales Order with fully reserved Quantity.
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(100, 2);  // Value required for test.
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', Quantity + Quantity2, WorkDate(), false);  // Value required for test. Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.
        UpdateBinOnPutAwayAndRegisterPutAway(Bin, LocationWhite.Code, PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(ReservationMode::"Reserve From Current Line");  // Enqueue for ReservationPageHandler.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationWhite.Code, '', Quantity, WorkDate(), true, false);  // Reserve as True and Tracking as False.
        UpdateQuantityBaseOnReservationEntry(Item."No.");
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);
        LibraryVariableStorage.Enqueue(ReservationMode::"Reserve From Current Line");  // Enqueue for ReservationPageHandler.
        CreateAndReleaseSalesOrder(SalesHeader2, SalesLine, Item."No.", LocationWhite.Code, '', Quantity2, WorkDate(), true, false);  // Reserve as True and Tracking as False.
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader2, SalesHeader2);

        // Exercise.
        GetWarehouseDocumentOnPickWorksheet(WhseWorksheetName, LocationWhite.Code);

        // Verify.
        VerifyWarehouseWorksheetLine(WhseWorksheetName, WarehouseShipmentHeader."No.", Item."No.", Quantity, Quantity, Quantity);
        VerifyWarehouseWorksheetLine(WhseWorksheetName, WarehouseShipmentHeader2."No.", Item."No.", Quantity2, Quantity2, Quantity2);

        if UpdateQuantityToHandle then begin
            // Exercise.
            UpdateQuantityToHandleOnWarehouseWorksheetLine(WhseWorksheetName, WarehouseShipmentHeader."No.", Item."No.", Quantity / 2);  // Value required for test.

            // Verify.
            VerifyWarehouseWorksheetLine(WhseWorksheetName, WarehouseShipmentHeader."No.", Item."No.", Quantity, Quantity / 2, Quantity);  // Value required for test.
            VerifyWarehouseWorksheetLine(
              WhseWorksheetName, WarehouseShipmentHeader2."No.", Item."No.", Quantity2, Quantity2, Quantity2 + Quantity / 2);  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickFromPickWorksheetWithExpiredItem()
    var
        Bin: Record Bin;
        Item: Record Item;
        StrictExpirationLotItemTrackingCode: Record "Item Tracking Code";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        LotNo: Code[50];
        OldPickAccordingToFEFO: Boolean;
    begin
        // Setup: Update Pick According to FEFO on Location. Create Item with Strict Expiration Posting Item Tracking Code. Create and register Put Away from Purchase Order.
        // Create and release Warehouse Shipment from Sales Order. Get Warehouse Document on Pick Worksheet.
        Initialize();
        OldPickAccordingToFEFO := UpdatePickAccordingToFEFOOnLocation(LocationWhite, true);
        CreateItemTrackingCode(StrictExpirationLotItemTrackingCode, false, true, true);  // Lot With Strict Expiration Posting Item Tracking.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', StrictExpirationLotItemTrackingCode.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), true);  // Tracking as True.
        GetLotNoFromItemTrackingLinesPageHandler(LotNo);
        UpdateExpirationDateReservationEntry(Item."No.");
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.
        UpdateBinOnPutAwayAndRegisterPutAway(Bin, LocationWhite.Code, PurchaseHeader."No.");
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationWhite.Code, '', PurchaseLine.Quantity, WorkDate(), false, false);  // Reserve as False and Tracking as False.
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);
        GetWarehouseDocumentOnPickWorksheet(WhseWorksheetName, LocationWhite.Code);

        // Exercise.
        asserterror CreatePickFromPickWorksheetLine(WhseWorksheetName, WarehouseShipmentHeader."No.", Item."No.");

        // Verify.
        Assert.ExpectedError(ExpiredItemMessage);

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PickFromPickWorksheetOnlyForRegisteredPutAwayWithAlwaysReserveItem()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Item with Reserve as Always. Create and register Put Away from Purchase Order. Create Put Away from another Purchase Order.
        // Create and release Warehouse Shipment from Sales Order. Get Warehouse Document on Pick Worksheet.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateReserveOnItemAsAlways(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(100, 2);  // Value required for test.
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', Quantity, WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.
        UpdateBinOnPutAwayAndRegisterPutAway(Bin, LocationWhite.Code, PurchaseHeader."No.");
        CreateAndReleasePurchaseOrder(PurchaseHeader2, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', Quantity2, WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader2, false);  // Tracking as False.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", LocationWhite.Code, '', PurchaseLine.Quantity + Quantity2, WorkDate(), false, false);  // Value required for test. Reserve as False and Tracking as False.
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);
        GetWarehouseDocumentOnPickWorksheet(WhseWorksheetName, LocationWhite.Code);

        // Exercise.
        CreatePickFromPickWorksheetLine(WhseWorksheetName, WarehouseShipmentHeader."No.", Item."No.");

        // Verify.
        VerifyPickLine(WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Item."No.", Quantity);
        VerifyPickLine(WarehouseActivityLine."Action Type"::Place, SalesHeader."No.", Item."No.", Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickAgainstAvailableQuantityOnDifferentBinWithDifferentLot()
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Item: Record Item;
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LotNo: Code[50];
        LotNo2: Code[20];
        LotNo3: Code[20];
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Item with Lot Item Tracking. Update Inventory on different Bin. Create and release Sales Order. Create Pick from Warehouse Shipment.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', LotItemTrackingCode.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        Quantity2 := Quantity + LibraryRandom.RandDec(100, 2);  // Value required for test.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        CreateAndPostItemJournalLineWithNewBinUsingItemTracking(Bin, LotNo, Item."No.", LocationBlack.Code, Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        CreateAndPostItemJournalLineWithNewBinUsingItemTracking(Bin2, LotNo2, Item."No.", LocationBlack.Code, Quantity2);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        CreateAndPostItemJournalLineWithNewBinUsingItemTracking(
          Bin3, LotNo3, Item."No.", LocationBlack.Code, Quantity2 + LibraryRandom.RandDec(100, 2)); // Value required for test.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationBlack.Code, '', Quantity2, WorkDate(), false, false);  // Reserve as False and Tracking as False.
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // Exercise.
        UpdateBinQuantityToHandleAndLotNoOnPickAndRegisterPick(Bin2, SalesHeader."No.", Quantity2 / 2, LotNo2);  // Value required for test.
        UpdateBinQuantityToHandleAndLotNoOnPickAndRegisterPick(Bin3, SalesHeader."No.", Quantity2 / 2, LotNo3);  // Value required for test.

        // Verify : Value required for Quantity as Quantity2 / 2.
        VerifyRegisteredPickLine(
          RegisteredWhseActivityLine."Action Type"::Take, RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          Bin2, Item."No.", '', Item."Base Unit of Measure", LotNo2, Quantity2 / 2, false);
        VerifyRegisteredPickLine(
          RegisteredWhseActivityLine."Action Type"::Place, RegisteredWhseActivityLine."Source Document"::"Sales Order",
          SalesHeader."No.", Bin, Item."No.", '', Item."Base Unit of Measure", LotNo2, Quantity2 / 2, false);
        VerifyRegisteredPickLine(
          RegisteredWhseActivityLine."Action Type"::Take, RegisteredWhseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          Bin3, Item."No.", '', Item."Base Unit of Measure", LotNo3, Quantity2 / 2, false);
        VerifyRegisteredPickLine(
          RegisteredWhseActivityLine."Action Type"::Place, RegisteredWhseActivityLine."Source Document"::"Sales Order",
          SalesHeader."No.", Bin, Item."No.", '', Item."Base Unit of Measure", LotNo3, Quantity2 / 2, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PutAwayFromWarehouseReceiptWithItemPurchaseUOMUsingMultipleLots()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromWarehouseReceiptAndPickFromWarehouseShipmentWithItemPurchaseUOMUsingMultipleLots(false, false);  // RegisterPutAway as False and RegisterPick as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayFromWarehouseReceiptWithItemPurchaseUOMUsingMultipleLots()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromWarehouseReceiptAndPickFromWarehouseShipmentWithItemPurchaseUOMUsingMultipleLots(true, false);  // RegisterPutAway as True and RegisterPick as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickFromWarehouseShipmentWithItemPurchaseUOMUsingMultipleLots()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromWarehouseReceiptAndPickFromWarehouseShipmentWithItemPurchaseUOMUsingMultipleLots(true, true);  // RegisterPutAway as True and RegisterPick as True.
    end;

    local procedure RegisterPutAwayFromWarehouseReceiptAndPickFromWarehouseShipmentWithItemPurchaseUOMUsingMultipleLots(RegisterPutAway: Boolean; RegisterPick: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        OldPickAccordingToFEFO: Boolean;
        LotNo: Code[50];
        LotNo2: Code[20];
    begin
        // Update Pick According to FEFO on Location. Create Item with Lot Item Tracking. Create Item Purchase Unit of Measure. Create and release Purchase Order with multiple Lot No.
        OldPickAccordingToFEFO := UpdatePickAccordingToFEFOOnLocation(LocationWhite, true);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', LotItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        UpdatePurchaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Multiple Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), true);  // Tracking as True.
        GetLotNoFromItemTrackingLinesPageHandler(LotNo);
        GetLotNoFromItemTrackingLinesPageHandler(LotNo2);

        // Exercise.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.

        // Verify.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, Item."No.", LotNo,
          PurchaseLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure" / 2);  // Value required for test.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, Item."No.", LotNo2,
          PurchaseLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure" / 2);  // Value required for test.

        if RegisterPutAway then begin
            // Exercise.
            UpdateBinOnPutAwayAndRegisterPutAway(Bin, LocationWhite.Code, PurchaseHeader."No.");

            // Verify.
            Bin2.Get(LocationWhite.Code, LocationWhite."Receipt Bin Code");  // Find RECEIVE Bin.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Positive Adjmt.", Bin2, Item."No.", ItemUnitOfMeasure.Code, LotNo, PurchaseLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::"Positive Adjmt.", Bin2, Item."No.", ItemUnitOfMeasure.Code, LotNo2, PurchaseLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin2, Item."No.", ItemUnitOfMeasure.Code, LotNo, -PurchaseLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin2, Item."No.", ItemUnitOfMeasure.Code, LotNo2, -PurchaseLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin, Item."No.", ItemUnitOfMeasure.Code, LotNo, PurchaseLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin, Item."No.", ItemUnitOfMeasure.Code, LotNo2, PurchaseLine.Quantity / 2);  // Value required for test.
        end;

        if RegisterPick then begin
            // Exercise.
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
            CreateAndReleaseSalesOrder(
              SalesHeader, SalesLine, Item."No.", LocationWhite.Code, '',
              PurchaseLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", WorkDate(), false, true);  // Value required for test. Reserve as False and Tracking as True.
            CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            Bin3.Get(LocationWhite.Code, LocationWhite."Shipment Bin Code");  // Find SHIP Bin.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin3, Item."No.", Item."Base Unit of Measure", LotNo, SalesLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin3, Item."No.", Item."Base Unit of Measure", LotNo2, SalesLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin, Item."No.", Item."Base Unit of Measure", LotNo, SalesLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin, Item."No.", Item."Base Unit of Measure", LotNo2, SalesLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin, Item."No.", ItemUnitOfMeasure.Code, LotNo, PurchaseLine.Quantity / 2);  // Value required for test.
            VerifyWarehouseEntry(
              WarehouseEntry."Entry Type"::Movement, Bin, Item."No.", ItemUnitOfMeasure.Code, LotNo2, PurchaseLine.Quantity / 2);  // Value required for test.
        end;

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationWhite, OldPickAccordingToFEFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPutAwayFromWarehouseReceiptWithLocationBinMandatoryAsFalse()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromWarehouseReceiptAndPickFromWarehouseShipmentUsingReservationWithLocationBinMandatoryAsFalse(false, false);  // RegisterPick as False and PostWarehouseShipment as False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPickFromWarehouseShipmentUsingReservationWithLocationBinMandatoryAsFalse()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromWarehouseReceiptAndPickFromWarehouseShipmentUsingReservationWithLocationBinMandatoryAsFalse(true, false);  // RegisterPick as True and PostWarehouseShipment as False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityAllocatedInWarehouseAfterPostWarehouseShipmentUsingReservationWithLocationBinMandatoryAsFalse()
    begin
        // Setup.
        Initialize();
        RegisterPutAwayFromWarehouseReceiptAndPickFromWarehouseShipmentUsingReservationWithLocationBinMandatoryAsFalse(true, true);  // RegisterPick as True and PostWarehouseShipment as True.
    end;

    local procedure RegisterPutAwayFromWarehouseReceiptAndPickFromWarehouseShipmentUsingReservationWithLocationBinMandatoryAsFalse(RegisterPick: Boolean; PostWarehouseShipment: Boolean)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReservationMode: Option "Reserve From Current Line","Reserve From First Line","Verify Reserve Line";
    begin
        // Create and release Purchase Order. Create and post Warehouse Receipt from Purchase Order.
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationYellow.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Purchase, Item."No.", '', PurchaseLine.Quantity);
        VerifyRegisteredWarehouseActivityLine(
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Source Document"::"Purchase Order",
          PurchaseHeader."No.", LocationYellow.Code, Item."No.", PurchaseLine.Quantity);

        if RegisterPick then begin
            // Exercise.
            CreateAndReleasePurchaseOrder(
              PurchaseHeader2, PurchaseLine, Item."No.", '', '', LocationYellow.Code, '', PurchaseLine.Quantity, WorkDate(), false);  // Tracking as False.
            CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader2, false);  // Tracking as False.
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader2."No.",
              WarehouseActivityLine."Activity Type"::"Put-away");
            LibraryVariableStorage.Enqueue(ReservationMode::"Reserve From First Line");  // Enqueue for ReservationPageHandler.
            CreateAndReleaseSalesOrder(
              SalesHeader, SalesLine, Item."No.", LocationYellow.Code, '', PurchaseLine.Quantity + PurchaseLine.Quantity / 2, WorkDate(), true,
              false);  // Value required for test. Reserve as True and Tracking as False.
            SalesHeader.Validate("Posting Date", WorkDate() + 7);
            SalesHeader.Modify();
            CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
            UpdateQuantityToHandleAndLotNoOnPickLines(
              WarehouseActivityLine."Activity Type"::Pick, SalesHeader."No.", PurchaseLine.Quantity, '');
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyRegisteredWarehouseActivityLine(
              WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              LocationYellow.Code, Item."No.", PurchaseLine.Quantity);
        end;

        if PostWarehouseShipment then begin
            // Exercise.
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);  // Post as Ship and Invoice.

            // Verify : Verify Quantity allocated in Warehouse and verification performed into ReservationPageHandler.
            LibraryVariableStorage.Enqueue(ReservationMode::"Verify Reserve Line");  // Enqueue for ReservationPageHandler.
            LibraryVariableStorage.Enqueue(PurchaseLine.Quantity);  // Enqueue for ReservationPageHandler.
            LibraryVariableStorage.Enqueue(PurchaseLine.Quantity / 2);
            LibraryVariableStorage.Enqueue(0);
            SalesLine.ShowReservation();
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostRemainingInventoryPickAfterPostingPartialInventoryPickFromSalesOrderWithLotItemTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: Code[50];
    begin
        // Setup: Create Item with Lot Item Tracking. Create and release Purchase Order. Post Purchase Order as Receive and Invoice. Create and release Sales Order.
        // Create Inventory Pick from Sales Order. Post Inventory Pick with partial Quantity and Lot No.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', LotItemTrackingCode.Code);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationSilver.Code, Bin.Code, LibraryRandom.RandDec(100, 2), WorkDate(), true);  // Tracking as True.
        GetLotNoFromItemTrackingLinesPageHandler(LotNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post Receive and Invoice.
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", LocationSilver.Code, Bin.Code, PurchaseLine.Quantity, WorkDate(), false, false);  // Reserve as False and Tracking as False.
        LibraryVariableStorage.Enqueue(PickCreated);  // Enqueue for MessageHandler.
        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Sales Order", SalesHeader."No.", false, true, false);  // Use True for Pick.
        UpdateQuantityToHandleAndLotNoOnPickLines(
          WarehouseActivityLine."Activity Type"::"Invt. Pick", SalesHeader."No.", PurchaseLine.Quantity / 2, LotNo);  // Value required for test.
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Ship.

        // Exercise: Post remaining Inventory Pick.
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);  // Post as Ship.

        // Verify.
        VerifyPostedInventoryPickLines(Bin, SalesHeader."No.", Item."No.", LotNo, PurchaseLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyBinContentAfterPostingItemJournal()
    begin
        // Setup.
        Initialize();
        CalculatePhysicalInventoryAfterPostingItemJournalWithBin(false);  // Calculate Physical Inventory as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalculatePhysicalInventoryForItemWithEmptyBinContent()
    begin
        // Setup.
        Initialize();
        CalculatePhysicalInventoryAfterPostingItemJournalWithBin(true);  // Calculate Physical Inventory as True.
    end;

    local procedure CalculatePhysicalInventoryAfterPostingItemJournalWithBin(CalculatePhysicalInventory: Boolean)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item, Bin and Bin Content.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateBinContent(BinContent, Bin, Item);

        // Exercise.
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDec(100, 2),
          Bin."Location Code", Bin.Code);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", ItemJournalLine.Quantity, Bin."Location Code",
          Bin.Code);

        // Verify: Verify empty Bin Content.
        FindBinContent(BinContent, Bin, Item."No.");
        Assert.IsTrue(BinContent.IsEmpty, BinContentMustBeEmpty);

        if CalculatePhysicalInventory then begin
            // Exercise.
            CalculateInventoryOnPhysicalInventoryJournal(ItemJournalLine, Item, LocationSilver.Code);

            // Verify.
            VerifyItemJournalLine(ItemJournalLine, Bin, Item."No.", 0);  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseUOMConversionOnMovementUsingMultipleLots()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        LotNo: Code[50];
        LotNo2: Code[20];
    begin
        // Setup: Create Item with Lot Item Tracking. Create Item Purchase Unit of Measure. Create and release Purchase Order. Create and register Put Away from Warehouse Receipt. Get Bin Content on Movement Worksheet.
        Initialize();
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', LotItemTrackingCode.Code);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        UpdatePurchaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, true);  // Tracking as True.
        GetLotNoFromItemTrackingLinesPageHandler(LotNo);
        GetLotNoFromItemTrackingLinesPageHandler(LotNo2);
        UpdateBinOnPutAwayAndRegisterPutAway(Bin, LocationWhite.Code, PurchaseHeader."No.");
        GetBinContentOnMovementWorksheet(WhseWorksheetLine, LocationWhite.Code, Item."No.");

        // Exercise.
        CreateMovement(WhseWorksheetLine, Item."No.");

        // Verify.
        VerifyMovementLine(
          WarehouseActivityLine."Action Type"::Take, WhseWorksheetLine."Worksheet Template Name", Item."No.",
          ItemUnitOfMeasure.Code, LotNo, Bin."Location Code", Bin."Zone Code", Bin.Code, PurchaseLine.Quantity / 2);
        VerifyMovementLine(
          WarehouseActivityLine."Action Type"::Place, WhseWorksheetLine."Worksheet Template Name", Item."No.",
          ItemUnitOfMeasure.Code, LotNo, Bin."Location Code", '', '', PurchaseLine.Quantity / 2);
        VerifyMovementLine(
          WarehouseActivityLine."Action Type"::Take, WhseWorksheetLine."Worksheet Template Name", Item."No.",
          ItemUnitOfMeasure.Code, LotNo2, Bin."Location Code", Bin."Zone Code", Bin.Code, PurchaseLine.Quantity / 2);
        VerifyMovementLine(
          WarehouseActivityLine."Action Type"::Place, WhseWorksheetLine."Worksheet Template Name", Item."No.",
          ItemUnitOfMeasure.Code, LotNo2, Bin."Location Code", '', '', PurchaseLine.Quantity / 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatePickFromInternalPickAfterRegisterWarehouseMovementWithItemVariant()
    begin
        // Setup.
        Initialize();
        CreateAndRegisterPickFromInternalPickAfterRegisterWarehouseMovementWithItemVariant(false);  // RegisterPick as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickFromInternalPickAfterRegisterWarehouseMovementWithItemVariant()
    begin
        // Setup.
        Initialize();
        CreateAndRegisterPickFromInternalPickAfterRegisterWarehouseMovementWithItemVariant(true);  // RegisterPick as True.
    end;

    local procedure CreateAndRegisterPickFromInternalPickAfterRegisterWarehouseMovementWithItemVariant(RegisterPick: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Item with Item Variant. Update Inventory for Item with Variant. Create and register Movement.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        Quantity := LibraryRandom.RandDec(100, 2);
        Quantity2 := LibraryRandom.RandDec(100, 2);
        FindBin(Bin, LocationWhite.Code);
        LibraryWarehouse.CreateBin(Bin2, Bin."Location Code", LibraryUtility.GenerateGUID(), Bin."Zone Code", Bin."Bin Type Code");
        UpdateInventoryUsingWarehouseJournal(Bin, Item, ItemVariant.Code, Item."Base Unit of Measure", Quantity + Quantity2);  // Value required for test.
        LibraryWarehouse.CreateMovementWorksheetLine(WhseWorksheetLine, Bin, Bin2, Item."No.", ItemVariant.Code, Quantity);
        CreateAndRegisterMovement(WhseWorksheetLine, Item."No.");
        Bin3.Get(LocationWhite.Code, LocationWhite."Open Shop Floor Bin Code");

        // Exercise.
        CreatePickFromWarehouseInternalPick(WhseInternalPickHeader, Bin3, Item."No.", ItemVariant.Code, Quantity + Quantity2);  // Value required for test.

        // Verify.
        VerifyPickLineWithBin(
          Bin2, WarehouseActivityLine."Action Type"::Take, WhseInternalPickHeader."No.", Item."No.", ItemVariant.Code,
          Item."Base Unit of Measure", Quantity, false);
        VerifyPickLineWithBin(
          Bin3, WarehouseActivityLine."Action Type"::Place, WhseInternalPickHeader."No.", Item."No.", ItemVariant.Code,
          Item."Base Unit of Measure", Quantity, false);
        VerifyPickLineWithBin(
          Bin, WarehouseActivityLine."Action Type"::Take, WhseInternalPickHeader."No.", Item."No.", ItemVariant.Code,
          Item."Base Unit of Measure", Quantity2, false);
        VerifyPickLineWithBin(
          Bin3, WarehouseActivityLine."Action Type"::Place, WhseInternalPickHeader."No.", Item."No.", ItemVariant.Code,
          Item."Base Unit of Measure", Quantity2, true);  // Use True for Move Next Line.

        if RegisterPick then begin
            // Exercise.
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyRegisteredPickLine(
              WarehouseActivityLine."Action Type"::Take, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", Bin2,
              Item."No.", ItemVariant.Code, Item."Base Unit of Measure", '', Quantity, false);
            VerifyRegisteredPickLine(
              WarehouseActivityLine."Action Type"::Place, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", Bin3,
              Item."No.", ItemVariant.Code, Item."Base Unit of Measure", '', Quantity, false);
            VerifyRegisteredPickLine(
              WarehouseActivityLine."Action Type"::Take, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", Bin,
              Item."No.", ItemVariant.Code, Item."Base Unit of Measure", '', Quantity2, false);
            VerifyRegisteredPickLine(
              WarehouseActivityLine."Action Type"::Place, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", Bin3,
              Item."No.", ItemVariant.Code, Item."Base Unit of Measure", '', Quantity2, true);  // Move Next Line.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMConversionOnPickFromInternalPickWithItemVariant()
    begin
        // Setup.
        Initialize();
        CreateAndRegisterPickFromInternalPickWithItemVariantAndUOMConversion(false);  // RegisterPick as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UOMConversionOnRegisteredPickFromInternalPickWithItemVariant()
    begin
        // Setup.
        Initialize();
        CreateAndRegisterPickFromInternalPickWithItemVariantAndUOMConversion(true);  // RegisterPick as True.
    end;

    local procedure CreateAndRegisterPickFromInternalPickWithItemVariantAndUOMConversion(RegisterPick: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        Quantity: Decimal;
    begin
        // Create Item with Item Variant. Create another Item Unit of Measure. Update Inventory for Item with Variant.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        Quantity := LibraryRandom.RandDec(100, 2);
        FindBin(Bin, LocationWhite.Code);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, ItemVariant.Code, ItemUnitOfMeasure.Code, Quantity);
        Bin2.Get(LocationWhite.Code, LocationWhite."Open Shop Floor Bin Code");

        // Exercise.
        CreatePickFromWarehouseInternalPick(
          WhseInternalPickHeader, Bin2, Item."No.", ItemVariant.Code, Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for test.

        // Verify.
        VerifyPickLineWithBin(
          Bin, WarehouseActivityLine."Action Type"::Take, WhseInternalPickHeader."No.", Item."No.", ItemVariant.Code,
          ItemUnitOfMeasure.Code, Quantity, false);
        VerifyPickLineWithBin(
          Bin2, WarehouseActivityLine."Action Type"::Place, WhseInternalPickHeader."No.", Item."No.", ItemVariant.Code,
          Item."Base Unit of Measure", Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", false);
        // Value required for test.

        if RegisterPick then begin
            // Exercise.
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);

            // Verify.
            VerifyRegisteredPickLine(
              WarehouseActivityLine."Action Type"::Take, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", Bin,
              Item."No.", ItemVariant.Code, ItemUnitOfMeasure.Code, '', Quantity, false);
            VerifyRegisteredPickLine(
              WarehouseActivityLine."Action Type"::Place, WarehouseActivityLine."Source Document"::" ", WhseInternalPickHeader."No.", Bin2,
              Item."No.", ItemVariant.Code,
              Item."Base Unit of Measure", '', Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure", false);  // Value required for test.
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAfterCalculateCrossDockWithLotItemTracking()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterCalculateCrossDockWithItemTracking(ItemTrackingMode::"Assign Lot No.", LotItemTrackingCode.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAfterCalculateCrossDockWithSerialItemTracking()
    var
        SerialItemTrackingCode: Record "Item Tracking Code";
    begin
        // Setup.
        Initialize();
        CreateItemTrackingCode(SerialItemTrackingCode, true, false, false);  // Serial Item Tracking.
        PostWarehouseShipmentAfterCalculateCrossDockWithItemTracking(ItemTrackingMode::"Assign Serial No.", SerialItemTrackingCode.Code);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,EnterQuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAfterCalculateCrossDockWithLotAndSerialItemTracking()
    var
        LotAndSerialItemTrackingCode: Record "Item Tracking Code";
    begin
        // Setup.
        Initialize();
        CreateItemTrackingCode(LotAndSerialItemTrackingCode, true, true, false);  // Both Serial and Lot Item Tracking.
        PostWarehouseShipmentAfterCalculateCrossDockWithItemTracking(
          ItemTrackingMode::"Assign Lot And Serial", LotAndSerialItemTrackingCode.Code);
    end;

    local procedure PostWarehouseShipmentAfterCalculateCrossDockWithItemTracking(TrackingMode: Option; ItemTrackingCode: Code[10])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LotNo: Code[50];
    begin
        // Create Item with Item Tracking. Create and release Sales Order. Create and release Purchase Order. Create Warehouse Receipt and Calculate Cross Dock with Item Tracking.
        // Post Warehouse Receipt and register Put Away. Create and register Pick from Warehouse Shipment.
        LibraryInventory.CreateTrackedItem(
          Item, LibraryUtility.GetGlobalNoSeriesCode(), LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode);
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", LocationWhite.Code, '', LibraryRandom.RandInt(10), WorkDate(), false, false);  // Reserve as False and Tracking as False.
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', SalesLine.Quantity, WorkDate(), false);  // Tracking as False.
        CreateWarehouseReceiptAndCalculateCrossDockWithItemTracking(WarehouseReceiptLine, PurchaseHeader, TrackingMode);
        if TrackingMode <> ItemTrackingMode::"Assign Serial No." then
            GetLotNoFromItemTrackingLinesPageHandler(LotNo);
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        SalesLine.OpenItemTrackingLines();
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // Exercise.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, true);  // Post as Ship and Invoice.

        // Verify.
        if TrackingMode = ItemTrackingMode::"Assign Lot No." then begin
            VerifyCrossDockWarehouseEntry(
              WarehouseEntry."Source Document"::"P. Order", PurchaseHeader."No.", LocationWhite, Item."No.", LotNo, PurchaseLine.Quantity);
            VerifyCrossDockWarehouseEntry(
              WarehouseEntry."Source Document"::"S. Order", SalesHeader."No.", LocationWhite, Item."No.", LotNo, -SalesLine.Quantity);
        end;
        if TrackingMode = ItemTrackingMode::"Assign Serial No." then begin
            VerifyCrossDockWarehouseEntryWithSerialNo(
              WarehouseEntry."Source Document"::"P. Order", PurchaseHeader."No.", LocationWhite, Item."No.", '', PurchaseLine.Quantity, 1);  // Value required for test.
            VerifyCrossDockWarehouseEntryWithSerialNo(
              WarehouseEntry."Source Document"::"S. Order", SalesHeader."No.", LocationWhite, Item."No.", '', -SalesLine.Quantity, -1);  // Value required for test.
        end;
        if TrackingMode = ItemTrackingMode::"Assign Lot And Serial" then begin
            VerifyCrossDockWarehouseEntryWithSerialNo(
              WarehouseEntry."Source Document"::"P. Order", PurchaseHeader."No.", LocationWhite, Item."No.", LotNo, PurchaseLine.Quantity, 1);  // Value required for test.
            VerifyCrossDockWarehouseEntryWithSerialNo(
              WarehouseEntry."Source Document"::"S. Order", SalesHeader."No.", LocationWhite, Item."No.", LotNo, -SalesLine.Quantity, -1);  // Value required for test.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUnitOfMeasureOnWarehousePutAwayWithError()
    begin
        // Setup.
        Initialize();
        ChangeUnitOfMeasureOnWarehousePutAway(true);  // Use True for With Error.
    end;

    [Test]
    [HandlerFunctions('WarehouseChangeUnitOfMeasurePageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUnitOfMeasureOnWarehousePutAwayWithoutError()
    begin
        // Setup.
        Initialize();
        ChangeUnitOfMeasureOnWarehousePutAway(false);  // Use False for Without Error.
    end;

    local procedure ChangeUnitOfMeasureOnWarehousePutAway(ShowError: Boolean)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Create Item with Purchase Unit of Measure. Create and release Purchase Order. Create and post Warehouse Receipt from Purchase Order.
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        UpdatePurchaseUnitOfMeasureOnItem(Item, ItemUnitOfMeasure.Code);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.

        if ShowError then begin
            // Exercise.
            FindWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
              WarehouseActivityLine."Activity Type"::"Put-away");
            asserterror ChangeUnitOfMeasureOnPutAway(WarehouseActivityLine."No.");

            // Verify.
            Assert.ExpectedTestFieldError(WarehouseActivityLine.FieldCaption("Action Type"), Format(WarehouseActivityLine."Action Type"::Place));
        end else begin
            // Exercise.
            ChangeUnitOfMeasureOnWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place,
              WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."Base Unit of Measure");

            // Verify.
            VerifyWarehouseActivityLine(
              WarehouseActivityLine, Item."No.", Item."Base Unit of Measure",
              PurchaseLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for test.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeUnitOfMeasureOnWarehousePickWithError()
    begin
        // Setup.
        Initialize();
        ChangeUnitOfMeasureOnWarehousePick(true);  // Use True for With Error.
    end;

    [Test]
    [HandlerFunctions('WarehouseChangeUnitOfMeasurePageHandler')]
    [Scope('OnPrem')]
    procedure ChangeUnitOfMeasureOnWarehousePickWithoutError()
    begin
        // Setup.
        Initialize();
        ChangeUnitOfMeasureOnWarehousePick(false);  // Use False for Without Error.
    end;

    local procedure ChangeUnitOfMeasureOnWarehousePick(ShowError: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
    begin
        // Create Item. Create different Unit of Measure. Update Inventory with different Unit of Measure. Create and release Sales Order. Create Pick from Warehouse Shipment.
        LibraryInventory.CreateItem(Item);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        FindBin(Bin, LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, '', ItemUnitOfMeasure.Code, Quantity + LibraryRandom.RandDec(100, 2));  // Value required for Test.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationWhite.Code, '', Quantity, WorkDate(), false, false);  // Reserve as False and Tracking as False.
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
        WarehouseActivityLine.SetRange("Breakbulk No.", 0);  // Value required for Test.
        if ShowError then begin
            // Exercise.
            WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
            FindWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);
            asserterror ChangeUnitOfMeasureOnPick(WarehouseActivityLine."No.");

            // Verify.
            Assert.ExpectedTestFieldError(WarehouseActivityLine.FieldCaption("Action Type"), Format(WarehouseActivityLine."Action Type"::Take));
        end else begin
            // Exercise.
            ChangeUnitOfMeasureOnWarehouseActivityLine(
              WarehouseActivityLine, WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take,
              WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.", ItemUnitOfMeasure.Code);

            // Verify.
            VerifyWarehouseActivityLine(
              WarehouseActivityLine, Item."No.", ItemUnitOfMeasure.Code, Quantity / ItemUnitOfMeasure."Qty. per Unit of Measure");  // Value required for test.
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssignToMeActionOnWarehousePutawaysPageTest()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehousePutaways: TestPage "Warehouse Put-aways";
    begin
        // [FEATURE] [Warehouse Put-Away] [Assign to me action]
        // [SCENARIO] 'Assign to me' action work correctly for the Warehouse Put-Aways page.
        Initialize();

        // [GIVEN] Create Item with Purchase Unit of Measure. Create and release Purchase Order. Create and post Warehouse Receipt from Purchase Order.
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.

        // [GIVEN] Find Warehouse Activity Header 
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");

        // [WHEN] Open Warehouse Put-Aways page and 'Assign to me' action is invoked
        WarehouseActivityHeader.TestField("Assigned User ID", '');
        WarehousePutaways.OpenEdit();
        WarehousePutaways.GoToRecord(WarehouseActivityHeader);

        WarehousePutaways."Assign to me".Invoke();
        WarehouseActivityHeader.Find();

        // [THEN] Assigned User ID is set to current usert.
        WarehouseActivityHeader.TestField("Assigned User ID", UserId());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderAsReceiveUsingMultipleItemsWithAndWithoutLocation()
    var
        Bin: Record Bin;
        Item: Record Item;
        Item2: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Setup: Create two Items. Create Bin. Create First Purchase Line with Location and Bin. Create Second Purchase Line without Location and Bin.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", Item2."No.", '', Bin."Location Code", Bin.Code, LibraryRandom.RandDec(100, 2),
          WorkDate(), false);  // Tracking as False.

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.

        // Verify: Warehouse Entry is created only for First Item.
        VerifyWarehouseEntry(
          WarehouseEntry."Entry Type"::"Positive Adjmt.", Bin, Item."No.", Item."Base Unit of Measure", '', PurchaseLine.Quantity);
        VerifyEmptyWarehouseEntry(Item2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithMultipleBaseCalendars()
    var
        BaseCalendar: Record "Base Calendar";
        BaseCalendar2: Record "Base Calendar";
        BaseCalendar3: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShippingAgentServices: Record "Shipping Agent Services";
    begin
        // Setup: Create multiple Base Calendars. Update outbound Warehouse Handling Time and Base Calendar on Location. Create Shipping Agent with Shipping Agent Service. Create Customer with Shipping Agent and Base Calendar.
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        CreateBaseCalendarWithBaseCalendarChange(BaseCalendar);
        CreateBaseCalendarWithBaseCalendarChange(BaseCalendar2);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar2.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D,
          BaseCalendarChange.Day::Wednesday);  // Use 0D for Date.
        LibraryService.CreateBaseCalendar(BaseCalendar3);
        UpdateOutboundWarehouseHandlingTimeAndBaseCalendarOnLocation(Location, BaseCalendar3.Code);
        CreateShippingAgentWithShippingAgentService(ShippingAgentServices, BaseCalendar.Code);
        CreateCustomerWithShippingAgentAndBaseCalendar(Customer, ShippingAgentServices, BaseCalendar2.Code);
        LibraryInventory.CreateItem(Item);

        // Exercise.
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", Location.Code, '');

        // Verify.
        VerifySalesLine(SalesLine, ShippingAgentServices, Location."Outbound Whse. Handling Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterMovementAfterRegisterPutAwayUsingWarehouseClass()
    begin
        // Setup.
        Initialize();
        RegisterMovementAfterPutAwayAndPickUsingWarehouseClass(false, false);  // Pick as False and MovementAfterPick as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterPickAfterRegisterMovementUsingWarehouseClass()
    begin
        // Setup.
        Initialize();
        RegisterMovementAfterPutAwayAndPickUsingWarehouseClass(true, false);  // Pick as True and MovementAfterPick as False.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterMovementAfterRegisterPickUsingWarehouseClass()
    begin
        // Setup.
        Initialize();
        RegisterMovementAfterPutAwayAndPickUsingWarehouseClass(true, true);  // Pick as True and MovementAfterPick as True.
    end;

    local procedure RegisterMovementAfterPutAwayAndPickUsingWarehouseClass(Pick: Boolean; MovementAfterPick: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Bin3: Record Bin;
        Bin4: Record Bin;
        Item: Record Item;
        WarehouseClass: Record "Warehouse Class";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Create Item with Warehouse Class. Create Receive, Ship and Pick Bin with Warehouse Class. Create and post Warehouse Receipt from Purchase Order. Register Put Away.
        CreateItemWithWarehouseClass(WarehouseClass, Item);
        CreateZoneAndBin(Bin, LocationWhite.Code, WarehouseClass.Code, true, false, false, false);  // Receive Bin.
        CreateZoneAndBin(Bin2, LocationWhite.Code, WarehouseClass.Code, false, true, false, false);  // Ship Bin.
        CreateZoneAndBin(Bin3, LocationWhite.Code, WarehouseClass.Code, false, false, true, true);  // Pick Bin.
        CreateBinWithWarehouseClassCode(Bin4, Bin3."Location Code", Bin3."Zone Code", Bin3."Bin Type Code", Bin3."Warehouse Class Code");
        Quantity := LibraryRandom.RandDec(100, 2);
        Quantity2 := LibraryRandom.RandDec(100, 2);
        RegisterPutAwayAfterPostWarehouseReceiptWithUpdateBinUsingPurchaseOrder(Bin, Item."No.", LocationWhite.Code, Quantity + Quantity2);  // Value required for test and Tracking as False.

        // Exercise.
        CreateAndRegisterMovementAfterGetBinContentOnMovementWorksheet(Bin3, Item."No.");

        // Verify.
        VerifyBinContent(Bin3, Item."No.", Quantity + Quantity2);  // Value required for test.

        if Pick then begin
            // Exercise.
            RegisterPickAfterPostWarehouseShipmentWithUpdateBinUsingSalesOrder(
              WarehouseShipmentHeader, Bin2, Item."No.", LocationWhite.Code, Quantity);

            // Verify.
            VerifyBinContent(Bin2, Item."No.", Quantity);
        end;

        if MovementAfterPick then begin
            // Exercise.
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
            CreateAndRegisterMovementAfterGetBinContentOnMovementWorksheet(Bin4, Item."No.");

            // Verify.
            VerifyBinContent(Bin4, Item."No.", Quantity2);
        end;
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure RegisterPutAwayWithLotInformationItemTracking()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisterPutAwayAndPickWithLotInformationItemTracking(false);  // Warehouse Shipment as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PostWarehouseShipmentAfterRegisterPickWithLotInformationItemTracking()
    begin
        // Setup.
        Initialize();
        PostWarehouseShipmentAfterRegisterPutAwayAndPickWithLotInformationItemTracking(true);  // Warehouse Shipment as True.
    end;

    local procedure PostWarehouseShipmentAfterRegisterPutAwayAndPickWithLotInformationItemTracking(WarehouseShipment: Boolean)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotInformationItemTrackingCode: Record "Item Tracking Code";
        LotNoInformation: Record "Lot No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LotNo: Code[50];
    begin
        // Create Item with Lot Information Item Tracking. Create and release Purchase Order. Create and post Warehouse Receipt from Purchase Order.
        CreateItemTrackingCodeWithLotInformation(LotInformationItemTrackingCode);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', LotInformationItemTrackingCode.Code);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), true);  // Tracking as True.
        GetLotNoFromItemTrackingLinesPageHandler(LotNo);
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', LotNo);
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.

        // Exercise.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // Verify.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Purchase, Item."No.", LotNo, PurchaseLine.Quantity);

        if WarehouseShipment then begin
            // Exercise.
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
            CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationWhite.Code, '', PurchaseLine.Quantity, WorkDate(), false, true);  // Value required for test. Reserve as False and Tracking as True.
            CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
            RegisterWarehouseActivity(
              WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
              WarehouseActivityLine."Activity Type"::Pick);
            LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.

            // Verify.
            VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, Item."No.", LotNo, -SalesLine.Quantity);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromPurchaseOrderWithJobWithoutTask()
    var
        Item: Record Item;
        Job: Record Job;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        // [FEATURE] [WMS] Support inventory put-away and warehouse-receipts in purchase orders linked to projects (jobs).
        // [SCENARIO] [545709] To Release Purchase Order, if "Job No." is defined in Purchase Line then "Job Task No." is also needed.
        // Setup: Create Item and Job. Create and release Purchase Order with Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryJob.CreateJob(Job);

        // Exercise.
        asserterror CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', Job."No.", LocationBlue.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false);  // Tracking as False.

        // Verify: Expected error message: Project Task No. must have a value in Purchase Line...
        Assert.ExpectedTestFieldError(PurchaseLine.FieldCaption("Job Task No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderWithJob()
    var
        Item: Record Item;
        Job: Record Job;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        // Setup: Create Item and Job. Create and release Sales Order with Job.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryJob.CreateJob(Job);
        CreateSalesOrder(SalesHeader, SalesLine, '', Item."No.", LocationWhite.Code, Job."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // Verify: Warehouse Shipment Line must not exists.
        asserterror FindWarehouseShipmentLine(
            WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromTransferOrderWithReceiptPostingPolicyBeforePostingErrorsAreNotProcessed()
    begin
        // Setup.
        Initialize();
        WarehouseReceiptFromTransferOrderWithReceiptPostingPolicy(false);  // Use PostingErrorsNotProcessed as False.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromTransferOrderWithReceiptPostingPolicyAfterPostingErrorsAreNotProcessed()
    begin
        // Setup.
        Initialize();
        WarehouseReceiptFromTransferOrderWithReceiptPostingPolicy(true);  // Use PostingErrorsNotProcessed as True.
    end;

    local procedure WarehouseReceiptFromTransferOrderWithReceiptPostingPolicy(PostingErrorsNotProcessed: Boolean)
    var
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        TransferHeader: Record "Transfer Header";
        TransferHeader2: Record "Transfer Header";
        TransferHeader3: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferLine2: Record "Transfer Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LotNo: Code[50];
        Quantity: Decimal;
        OldReceiptPostingPolicy: Integer;
        OldReceiptPostingPolicy2: Integer;
    begin
        // Create two Items without Item Tracking. Create one Item with Lot Tracking. Update Inventory for Items. Create and release Transfer Order for first Item.
        // Create and release Transfer Order for second Item with Lot Item Tracking. Create and release Transfer Order for third Item. Create and post Warehouse Shipment with Get Source Document.
        // Update Quantity Base on Receipt Item Tracking Line for second Transfer Order. Create Warehouse Receipt with Get Source Document. Update Receipt Posting Policy on Warehouse Setup.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateTrackedItem(Item2, LibraryUtility.GetGlobalNoSeriesCode(), '', LotItemTrackingCode.Code);
        LibraryInventory.CreateItem(Item3);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, LocationBlue.Code, '');
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item2."No.", Quantity, LocationBlue.Code, '');
        GetLotNoFromItemTrackingLinesPageHandler(LotNo);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item3."No.", Quantity, LocationBlue.Code, '');
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationBlue.Code, LocationRed.Code, Item."No.", Quantity);
        CreateAndReleaseTransferOrder(TransferHeader2, TransferLine2, LocationBlue.Code, LocationRed.Code, Item2."No.", Quantity);
        UpdateItemTrackingOnTransferLine(TransferLine2, ItemTrackingMode::"Select Entries", "Transfer Direction"::Outbound);
        CreateAndReleaseTransferOrder(TransferHeader3, TransferLine, LocationBlue.Code, LocationRed.Code, Item3."No.", Quantity);
        CreateWarehouseShipmentWithGetSourceDocument(WarehouseShipmentHeader, LocationBlue.Code);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        UpdateItemTrackingOnTransferLine(TransferLine2, ItemTrackingMode::"Blank Quantity Base", "Transfer Direction"::Inbound);
        CreateWarehouseReceiptWithGetSourceDocument(WarehouseReceiptHeader, LocationRed.Code);
        UpdateReceiptPostingPolicyOnWarehouseSetup(
          OldReceiptPostingPolicy, WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");

        // Exercise.
        LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeleted, TransferHeader."No."));  // Enqueue for MessageHandler.
        asserterror LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        // Verify: Receipt posted only for first Transfer Order.
        VerifyPostedWarehouseReceiptLine(
          PostedWhseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader."No.", Item."No.", Quantity, false);
        Assert.ExpectedError(StrSubstNo(LotNumberRequiredForItem, Item2."No."));
        VerifyEmptyPostedWarehouseReceiptLine(TransferHeader2."No.", Item2."No.");
        VerifyEmptyPostedWarehouseReceiptLine(TransferHeader3."No.", Item3."No.");

        if PostingErrorsNotProcessed then begin
            // Exercise.
            UpdateReceiptPostingPolicyOnWarehouseSetup(
              OldReceiptPostingPolicy2, WarehouseSetup."Receipt Posting Policy"::"Posting errors are not processed");
            LibraryVariableStorage.Enqueue(StrSubstNo(TransferOrderDeleted, TransferHeader3."No."));  // Enqueue for MessageHandler.
            LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

            // Verify: Receipt posted for third Transfer Order.
            VerifyPostedWarehouseReceiptLine(
              PostedWhseReceiptLine."Source Document"::"Inbound Transfer", TransferHeader3."No.", Item3."No.", Quantity, false);
            VerifyEmptyPostedWarehouseReceiptLine(TransferHeader2."No.", Item2."No.");
        end;

        // Tear down.
        UpdateReceiptPostingPolicyOnWarehouseSetup(OldReceiptPostingPolicy, OldReceiptPostingPolicy);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentAfterPostWarehouseShipmentFromSalesOrderUsingPick()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create and register Put Away from Warehouse Receipt using Purchase Order. Create and register Pick from Warehouse Shipment using Sales Order. Post Warehouse Shipment.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(PurchaseHeader, Item."No.", LocationYellow.Code, Quantity);
        CreateAndRegisterPickFromWarehouseShipmentUsingSalesOrder(
          WarehouseShipmentHeader, SalesHeader, Item."No.", LocationYellow.Code, Quantity);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        UndoSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");

        // Verify: Posted Warehouse Shipment Line after Undo Sales Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", -Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyRndingPrecisionIsCopiedToPostedWhseShipmentLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Quantity: Decimal;
        QtyRndingPrecision: Decimal;
    begin
        // Setup: Create and register Put Away from Warehouse Receipt using Purchase Order. Create and register Pick from Warehouse Shipment using Sales Order. Post Warehouse Shipment.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        QtyRndingPrecision := 0.01; // Hardcoding the value is fine as the test veriifes that the value travels all the way to posted lines
        LibraryInventory.CreateItem(Item);
        ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
        ItemUnitOfMeasure.Validate("Qty. Rounding Precision", QtyRndingPrecision);
        ItemUnitOfMeasure.Modify();

        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(PurchaseHeader, Item."No.", LocationYellow.Code, Quantity);
        CreateAndRegisterPickFromWarehouseShipmentUsingSalesOrder(
          WarehouseShipmentHeader, SalesHeader, Item."No.", LocationYellow.Code, Quantity);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.

        // Verify: Posted Warehouse Shipment Line after Undo Sales Shipment.
        PostedWhseShipmentLine.SetRange("Source Document", PostedWhseShipmentLine."Source Document"::"Sales Order");
        PostedWhseShipmentLine.SetRange("Source No.", SalesHeader."No.");
        PostedWhseShipmentLine.SetRange("Item No.", Item."No.");
        //Assert.RecordCount(PostedWhseShipmentLine, 1);
        PostedWhseShipmentLine.FindFirst();

        PostedWhseShipmentLine.TestField("Qty. Rounding Precision", QtyRndingPrecision);
        PostedWhseShipmentLine.TestField("Qty. Rounding Precision (Base)", QtyRndingPrecision);

    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnShipmentAfterPostWarehouseShipmentFromPurchaseReturnOrderUsingPick()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create and register Put Away from Warehouse Receipt using Purchase Order. Create and register Pick from Warehouse Shipment using Purchase Return Order. Post Warehouse Shipment.
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(PurchaseHeader, Item."No.", LocationYellow.Code, Quantity);
        CreateAndRegisterPickFromWarehouseShipmentUsingPurchaseReturnOrder(
          WarehouseShipmentHeader, PurchaseHeader, Item."No.", LocationYellow.Code, Quantity);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        UndoReturnShipmentLine(ReturnShipmentLine, PurchaseHeader."No.");

        // Verify: Posted Warehouse Shipment Line after Undo Return Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", Item."No.", Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", Item."No.", -Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoPurchaseReceiptAfterPostWarehouseReceiptFromPurchaseOrderUsingPutAway()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Setup: Create and register Put Away from Warehouse Receipt using Purchase Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(
          PurchaseHeader, Item."No.", LocationYellow.Code, LibraryRandom.RandDec(100, 2));
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        asserterror UndoPurchaseReceiptLine(PurchRcptLine, PurchaseHeader."No.");

        // Verify.
        Assert.ExpectedError(StrSubstNo(UndoErrorMessage, PurchRcptLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoReturnReceiptAfterPostWarehouseReceiptFromSalesReturnOrderUsingPutAway()
    var
        Item: Record Item;
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create and register Put Away from Warehouse Receipt using Sales Return Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingSalesReturnOrder(SalesHeader, Item."No.", LocationYellow.Code);
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        asserterror UndoReturnReceiptLine(ReturnReceiptLine, SalesHeader."No.");

        // Verify.
        Assert.ExpectedError(StrSubstNo(UndoErrorMessage, ReturnReceiptLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentAfterPostSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Setup: Create and release Sales Order. Post Sales Order as Ship.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", LocationGreen.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false, false);  // Value required for test.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        UndoSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");

        // Verify: Sales Shipment Line after Undo Sales Shipment.
        VerifySalesShipmentLine(SalesShipmentLine, Item."No.", LocationGreen.Code, SalesLine.Quantity, false);
        VerifySalesShipmentLine(SalesShipmentLine, Item."No.", LocationGreen.Code, -SalesLine.Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnShipmentAfterPostPurchaseReturnOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentLine: Record "Return Shipment Line";
        Quantity: Decimal;
    begin
        // Setup: Create and release Purchase Return Order. Post Purchase Return Order as Ship.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", LocationGreen.Code, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        UndoReturnShipmentLine(ReturnShipmentLine, PurchaseHeader."No.");

        // Verify: Return Shipment Line after Undo Return Shipment.
        VerifyReturnShipmentLine(ReturnShipmentLine, Item."No.", LocationGreen.Code, Quantity, false);
        VerifyReturnShipmentLine(ReturnShipmentLine, Item."No.", LocationGreen.Code, -Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoSalesShipmentAfterPostWarehouseShipmentFromSalesOrder()
    var
        Item: Record Item;
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
    begin
        // Setup: Create and release Sales Order. Create and post Warehouse Shipment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", LocationBlue.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false, false);  // Reserve as False and Tracking as False.
        CreateAndReleaseWarehouseShipmentFromSalesOrder(WarehouseShipmentHeader, SalesHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        UndoSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");

        // Verify: Posted Warehouse Shipment Line after Undo Sales Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", SalesLine.Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.", Item."No.", -SalesLine.Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentWhseShipment()
    var
        Item: Record Item;
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ItemJnlLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Undo Transfer Shipment shipped as Warehouse Shipment
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Create and release Transfer Order.
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(ItemJnlLine, "Item Ledger Entry Type"::"Positive Adjmt.", Item."No.", Quantity, LocationBlue.Code, LocationBlue."Default Bin Code");
        CreateAndReleaseTransferOrder(
            TransferHeader, TransferLine, LocationBlue.Code, LocationRed.Code, Item."No.", Quantity);

        // [GIVEN] Create and post Warehouse Shipment.
        CreateAndReleaseWarehouseShipmentFromTransferOrder(WarehouseShipmentHeader, TransferHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // [WHEN] The Transfer Shipment is undone.
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] Verify The Posted Warehouse Shipment Line after Undo Transfer Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", TransferLine.Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", -TransferLine.Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentWhseShipmentUsingPick()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        Quantity: Decimal;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Undo Transfer Shipment shipped as Warehouse Shipment with Pick
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Item with available inventory in Location Yellow
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(PurchaseHeader, Item."No.", LocationYellow.Code, Quantity);

        // [GIVEN] Create and register Pick from Warehouse Shipment using Transfer Order. 
        // FromLocation (Yellow) has "Require Shipment" = true, "Require Pick" = true, "Directed Pick/Put-away" = false, "Bin Mandatory" = false,  
        CreateAndRegisterPickFromWarehouseShipmentUsingTransferOrder(
          WarehouseShipmentHeader, TransferHeader, Item."No.", LocationYellow.Code, LocationRed.Code, Quantity);

        // [GIVEN] The Warehouse Shipment is posted.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // [WHEN] The Transfer Shipment is undone.
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] Verify The Posted Warehouse Shipment Line after Undo Transfer Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", -Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentWhseShipment_FullWMS()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        Quantity: Decimal;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Undo Transfer Shipment shipped as WarehouseSshipment from full WMS Location
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2);

        // [GIVEN] Item with available inventory in Bin on Location White
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(PurchaseHeader, Item."No.", LocationWhite.Code, Quantity);

        // [GIVEN] Create and register Pick from Warehouse Shipment using Transfer Order. 
        // FromLocation (White) has "Require Shipment" = true, "Require Pick" = true, "Directed Pick/Put-away" = true, "Bin Mandatory" = true,  
        CreateAndRegisterPickFromWarehouseShipmentUsingTransferOrder(
          WarehouseShipmentHeader, TransferHeader, Item."No.", LocationWhite.Code, LocationRed.Code, Quantity);

        // [GIVEN] The Warehouse Shipment is posted.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // [WHEN] The Transfer Shipment line is undone.
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] Verify The Posted Warehouse Shipment Line after Undo Transfer Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", -Quantity, true);  // Use MoveNext as True.

        // [THEN] The sum of quantities of this item is equal to Quantity on both Whse Entry and Item Ledger Entry 
        Assert.AreEqual(Quantity, SumQtyOnItemLedgerEntries(Item."No."), 'Incorrect sum of quantities Item Ledger Entries after Undo Transfer Shipment');
        Assert.AreEqual(Quantity, SumQtyOnWhseEntries(Item."No."), 'Incorrect sum of quantities Warehouse Entries after Undo Transfer Shipment');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentWhseShipment_FullWMS_LotTracking()
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Undo Transfer Shipment shipped as Warehouse Shipment from full WMS Location with Lot Tracking
        Initialize();
        UndoTransferShipmentWhseShipment_FullWMS_Tracking(true, LibraryRandom.RandDec(100, 2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure UndoTransferShipmentWhseShipment_FullWMS_SNTracking()
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Undo Transfer Shipment shipped as Warehouse Shipment from full WMS Location with Serial No. Tracking
        Initialize();
        UndoTransferShipmentWhseShipment_FullWMS_Tracking(false, LibraryRandom.RandInt(10) + 2);
    end;

    local procedure UndoTransferShipmentWhseShipment_FullWMS_Tracking(LotTracking: Boolean; Quantity: Decimal)
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        LotNoInformation: Record "Lot No. Information";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        LotNo: Code[50];
    begin
        Initialize();

        // [GIVEN] Create Item with Item Tracking. Create and release Purchase Order. Create and post Warehouse Receipt from Purchase Order.
        if LotTracking then begin
            CreateItemTrackingCodeWithLotInformation(ItemTrackingCode);
            LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        end else begin
            CreateItemTrackingCode(ItemTrackingCode, true, false, false);
            LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), ItemTrackingCode.Code);
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Serial No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        end;
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationWhite.Code, '', Quantity, WorkDate(), true);  // Tracking as True.
        if LotTracking then begin
            GetLotNoFromItemTrackingLinesPageHandler(LotNo);
            LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', LotNo);
        end;
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.

        // [GIVEN] Put-away is registered, so we now have inventory of the tracked Item in LocationWhite
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        // [GIVEN] A Transfer Order with the tracked item is created from LocationWhite
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationWhite.Code, LocationRed.Code, Item."No.", Quantity);
        UpdateItemTrackingOnTransferLine(TransferLine, ItemTrackingMode::"Select Entries", "Transfer Direction"::Outbound);
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, TransferHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // [WHEN] The Transfer Shipment Line is undone.
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] Verify The Posted Warehouse Shipment Line after Undo Transfer Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", -Quantity, true);  // Use MoveNext as True.

        // [THEN] The sum of quantities of this item is equal to Quantity on both Whse Entry and Item Ledger Entry 
        Assert.AreEqual(Quantity, SumQtyOnItemLedgerEntries(Item."No."), 'Incorrect sum of quantities Item Ledger Entries after Undo Transfer Shipment');
        Assert.AreEqual(Quantity, SumQtyOnWhseEntries(Item."No."), 'Incorrect sum of quantities Warehouse Entries after Undo Transfer Shipment');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CannotUndoTransferShipmentWithOpenWarehousePick()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferShipmentLine: Record "Transfer Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity: Decimal;
    begin
        // [FEATURE 332164] [Transfer] [Order] [Undo Shipment]
        // [SCENARIO] Cannot undo Transfer Shipment if the Transfer Line has an open Warehouse Pick
        Initialize();
        Quantity := LibraryRandom.RandDec(100, 2) + 10.0;

        // [GIVEN] Create and register Put Away from Warehouse Receipt using Purchase Order. 
        LibraryInventory.CreateItem(Item);
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(PurchaseHeader, Item."No.", LocationYellow.Code, Quantity);

        // [GIVEN] Create Transfer Order with Pick for a Warehouse Shipment
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, LocationYellow.Code, LocationRed.Code, Item."No.", Quantity);
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, TransferHeader);

        // [GIVEN] Change pick quantity to subquantity and post it
        FindWarehouseActivityLine(
            WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.Validate("Qty. to Handle", Quantity / 2);
        WarehouseActivityLine.Validate("Qty. Outstanding", Quantity / 2);
        WarehouseActivityLine.Modify();
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);

        // [GIVEN] The Warehouse Shipment is posted.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // [GIVEN] Another pick is created and registered
        CreatePickForOutboundTransfer(WarehouseShipmentHeader, TransferHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // [WHEN] We attempt to undo the Transfer Shipment Line
        TransferShipmentLine.SetFilter("Transfer Order No.", TransferHeader."No.");
        TransferShipmentLine.FindFirst();
        asserterror LibraryInventory.UndoTransferShipmentLinesInFilter(TransferShipmentLine);

        // [THEN] We get an error because the Warehouse Shipment has posted Activitiy Lines 
        Assert.ExpectedError(StrSubstNo(UndoErrorMessage_Shipment, TransferShipmentLine."Line No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnShipmentAfterPostWarehouseShipmentFromPurchaseReturnOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        ReturnShipmentLine: Record "Return Shipment Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
    begin
        // Setup: Create and release Purchase Return Order. Create and post Warehouse Shipment.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, Item."No.", LocationBlue.Code, Quantity);
        CreateAndReleaseWarehouseShipmentFromPurchaseReturnOrder(WarehouseShipmentHeader, PurchaseHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        UndoReturnShipmentLine(ReturnShipmentLine, PurchaseHeader."No.");

        // Verify: Posted Warehouse Shipment Line after Undo Return Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", Item."No.", Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.", Item."No.", -Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptAfterPostWarehouseReceiptFromPurchaseOrder()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        // Setup: Create and release Purchase Order. Create and post Warehouse Receipt.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', LocationRed.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        UndoPurchaseReceiptLine(PurchRcptLine, PurchaseHeader."No.");

        // Verify: Posted Warehouse Receipt Line after Undo Purchase Receipt.
        VerifyPostedWarehouseReceiptLine(
          PostedWhseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."No.", PurchaseLine.Quantity, false);
        VerifyPostedWarehouseReceiptLine(
          PostedWhseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.", Item."No.", -PurchaseLine.Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoReturnReceiptAfterPostWarehouseReceiptFromSalesReturnOrder()
    var
        Item: Record Item;
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesHeader: Record "Sales Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        Quantity: Decimal;
    begin
        // Setup: Create and release Sales Return Order. Create and post Warehouse Receipt.
        Initialize();
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleaseSalesReturnOrder(SalesHeader, Item."No.", LocationRed.Code, Quantity);
        CreateAndPostWarehouseReceiptFromSalesReturnOrder(SalesHeader);
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        UndoReturnReceiptLine(ReturnReceiptLine, SalesHeader."No.");

        // Verify: Posted Warehouse Receipt Line after Undo Return Receipt.
        VerifyPostedWarehouseReceiptLine(
          PostedWhseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.", Item."No.", Quantity, false);
        VerifyPostedWarehouseReceiptLine(
          PostedWhseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.", Item."No.", -Quantity, true);  // Use MoveNext as True.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptBeforeCancelReservation()
    begin
        // Setup.
        Initialize();
        UndoPurchaseReceiptWithReservation(false);  // Use CancelReservation as False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure UndoPurchaseReceiptAfterCancelReservation()
    begin
        // Setup.
        Initialize();
        UndoPurchaseReceiptWithReservation(true);  // Use CancelReservation as True.
    end;

    local procedure UndoPurchaseReceiptWithReservation(CancelReservation: Boolean)
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReservationMode: Option "Reserve From Current Line","Reserve From First Line","Verify Reserve Line","Cancel Reservation Current Line";
    begin
        // Create and release Purchase Order. Create and release Sales Order.
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item."No.", '', '', Location.Code, '', LibraryRandom.RandDec(100, 2), WorkDate(), false);  // Tracking as False.
        LibraryVariableStorage.Enqueue(ReservationMode::"Reserve From Current Line");  // Enqueue for ReservationPageHandler.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", Location.Code, '', PurchaseLine.Quantity, WorkDate(), true, false);  // Use Reserve as True.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // Post as Receive.
        LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.

        // Exercise.
        asserterror UndoPurchaseReceiptLine(PurchRcptLine, PurchaseHeader."No.");

        // Verify.
        SalesLine.Find();
        ItemLedgerEntry.SetRange("Item No.", Item."No.");
        ItemLedgerEntry.FindFirst();
        Assert.ExpectedTestFieldError(ItemLedgerEntry.FieldCaption("Reserved Quantity"), Format(0));

        if CancelReservation then begin
            // Exercise.
            LibraryVariableStorage.Enqueue(ReservationMode::"Cancel Reservation Current Line");  // Enqueue for ReservationPageHandler.
            LibraryVariableStorage.Enqueue(CancelReservationConfirmMessage);  // Enqueue for ConfirmHandler.
            UpdateQuantityOnSalesLineAndReserve(SalesLine, PurchaseLine.Quantity);
            LibraryVariableStorage.Enqueue(UndoConfirmMessage);  // Enqueue for ConfirmHandler.
            LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);

            // Verify.
            VerifyPurchaseReceiptLine(PurchRcptLine, Item."No.", Location.Code, SalesLine.Quantity, false);
            VerifyPurchaseReceiptLine(PurchRcptLine, Item."No.", Location.Code, -SalesLine.Quantity, true);  // Use MoveNext as True.
        end;
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProductionOrderWithComponentFlushingMethodAsPickBackwardUsingPick()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        FinishedProductionOrderWithDifferentComponentFlushingMethodUsingPick(Item."Flushing Method"::"Pick + Backward", false);  // Use Pick Worksheet as False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProductionOrderWithComponentFlushingMethodAsPickForwardUsingPick()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        FinishedProductionOrderWithDifferentComponentFlushingMethodUsingPick(Item."Flushing Method"::"Pick + Forward", false);  // Use Pick Worksheet as False.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProductionOrderWithComponentFlushingMethodAsPickBackwardUsingPickWorksheet()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        FinishedProductionOrderWithDifferentComponentFlushingMethodUsingPick(Item."Flushing Method"::"Pick + Backward", true);  // Use Pick Worksheet as True.
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler')]
    [Scope('OnPrem')]
    procedure FinishedProductionOrderWithComponentFlushingMethodAsPickForwardUsingPickWorksheet()
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        FinishedProductionOrderWithDifferentComponentFlushingMethodUsingPick(Item."Flushing Method"::"Pick + Forward", true);  // Use Pick Worksheet as True.
    end;

    local procedure FinishedProductionOrderWithDifferentComponentFlushingMethodUsingPick(FlushingMethod: Enum "Flushing Method"; PickWorksheet: Boolean)
    var
        Bin: Record Bin;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ParentItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        ProdOrderComponent: Record "Prod. Order Component";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        ProductionOrderNo: Code[20];
        Quantity: Decimal;
    begin
        // Create Item with Production BOM. Create and release Purchase Order. Reserve Production Order Component on Firm Planned Production Order. Create and register Put Away.
        // Change Status Firm Plan to Released. Create and register Pick from Release Production Order. Post Consumption and Output Journal.
        CreateItemWithProductionBOM(ParentItem, ProductionBOMLine, FlushingMethod);
        Quantity := LibraryRandom.RandInt(100);
        CreateAndReleasePurchaseOrder(
          PurchaseHeader, PurchaseLine, ProductionBOMLine."No.", '', '', LocationWhite.Code, '', Quantity * ProductionBOMLine."Quantity per",
          CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), false);  // Value required for test. Tracking as False.
        CreateAndRefreshFirmPlannedProductionOrder(ProductionOrder, ParentItem."No.", LocationWhite.Code, Quantity);
        ReserveProductionOrderComponent(ProdOrderComponent, ProductionOrder);
        if FlushingMethod = ParentItem."Flushing Method"::"Pick + Forward" then
            UpdateRoutingLinkCodeOnProductionOrderComponent(ProdOrderComponent);
        CreateWarehouseReceiptWithGetSourceDocument(WarehouseReceiptHeader, LocationWhite.Code);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        UpdateBinOnPutAwayAndRegisterPutAway(Bin, LocationWhite.Code, PurchaseHeader."No.");
        ProductionOrderNo :=
          LibraryManufacturing.ChangeProuctionOrderStatus(
            ProductionOrder."No.", ProductionOrder.Status, ProductionOrder.Status::Released);
        if PickWorksheet then begin
            GetWarehouseDocumentOnPickWorksheet(WhseWorksheetName, LocationWhite.Code);
            CreatePickFromPickWorksheetLine(WhseWorksheetName, '', ProductionBOMLine."No.");
        end else begin
            ProductionOrder.Get(ProductionOrder.Status::Released, ProductionOrderNo);
            LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        end;
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrderNo,
          WarehouseActivityLine."Activity Type"::Pick);
        if FlushingMethod = ParentItem."Flushing Method"::"Pick + Forward" then
            CalculateAndPostConsumptionJournal(ProductionOrderNo);
        PostOutputJournalAfterExplodeRouting(ProductionOrderNo);

        // Exercise.
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);

        // Verify.
        VerifyFinishedProductionOrderLine(ProductionOrderNo, ParentItem."No.", Quantity);
        VerifyFinishedProductionOrderComponent(ProductionOrderNo, ProductionBOMLine."No.", FlushingMethod, PurchaseLine.Quantity);
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Consumption, ProductionBOMLine."No.", '', -PurchaseLine.Quantity);
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Output, ParentItem."No.", '', Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PositiveAdjustmentUsingWarehouseItemJournal()
    begin
        // Setup.
        Initialize();
        AdjustmentUsingWarehouseItemJournal(false);  // Use False for Positive Adjustment.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAdjustmentUsingWarehouseItemJournal()
    begin
        // Setup.
        Initialize();
        AdjustmentUsingWarehouseItemJournal(true);  // Use True for Negative Adjustment.
    end;

    local procedure AdjustmentUsingWarehouseItemJournal(NegativeAdjustment: Boolean)
    var
        Bin: Record Bin;
        Bin2: Record Bin;
        Item: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Quantity: Decimal;
    begin
        // Create Item and get Adjustment Bin.
        LibraryInventory.CreateItem(Item);
        Bin.Get(LocationWhite.Code, LocationWhite."Adjustment Bin Code");
        FindBin(Bin2, LocationWhite.Code);
        Quantity := LibraryRandom.RandDec(100, 2);

        // Exercise.
        CreateAndRegisterWarehouseJournalLine(
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Bin2, Item."No.", '', Item."Base Unit of Measure", Quantity);

        // Verify.
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Negative Adjmt.", Bin, Item."No.", Item."Base Unit of Measure", '', -Quantity);
        VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Bin2, Item."No.", Item."Base Unit of Measure", '', Quantity);
        VerifyBinContent(Bin2, Item."No.", Quantity);

        if NegativeAdjustment then begin
            // Exercise.
            CreateAndRegisterWarehouseJournalLine(
              WarehouseJournalLine."Entry Type"::"Negative Adjmt.", Bin2, Item."No.", '', Item."Base Unit of Measure", -Quantity);

            // Verify.
            VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Positive Adjmt.", Bin, Item."No.", Item."Base Unit of Measure", '', Quantity);
            VerifyWarehouseEntry(WarehouseEntry."Entry Type"::"Negative Adjmt.", Bin2, Item."No.", Item."Base Unit of Measure", '', -Quantity);
        end;
    end;

    [Test]
    [HandlerFunctions('FiltersToGetSourceDocsPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure GetSourceDocumentForShipmentWithBlockedCust()
    var
        Item: Record Item;
        Cust: Record Customer;
        SalesHeader: array[5] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseSourceFilter: Record "Warehouse Source Filter";
        WhseShipment: TestPage "Warehouse Shipment";
        I: Integer;
    begin
        // Setup: Create items, customers, sales orders and release the order
        Initialize();
        for I := 1 to ArrayLen(SalesHeader) do begin
            LibrarySales.CreateCustomer(Cust);
            CreateSalesOrder(SalesHeader[I], SalesLine, Cust."No.", LibraryInventory.CreateItem(Item), LocationWhite.Code, '');
            LibrarySales.ReleaseSalesDocument(SalesHeader[I]);
            Clear(Cust);
        end;

        // Set the Blocked to Ship, Invoice, All on 3 Customers respectively
        BlockCust(SalesHeader[2]."Sell-to Customer No.", Cust.Blocked::Ship);
        BlockCust(SalesHeader[3]."Sell-to Customer No.", Cust.Blocked::Invoice);
        BlockCust(SalesHeader[4]."Sell-to Customer No.", Cust.Blocked::All);
        // Set GDPPrivacyBlocked on Customer
        Cust.Init();
        Cust.Get(SalesHeader[5]."Sell-to Customer No.");
        Cust.Validate("Privacy Blocked", true);
        Cust.Modify();

        // Create Warehouse Source Filter like the Filter CUSTOMERS
        LibraryWarehouse.CreateWarehouseSourceFilter(WhseSourceFilter, WhseSourceFilter.Type::Outbound);
        Commit(); // Make sure the created Warehouse Source Filter goes into the table

        // Exercise: Create Warehouse Shipment and use Filters to Get Source documents Action
        CreateWarehouseShipmentHeaderWithLocation(WhseShipmentHeader, LocationWhite.Code);
        WhseShipment.OpenEdit();
        WhseShipment.FILTER.SetFilter("No.", WhseShipmentHeader."No.");
        LibraryVariableStorage.Enqueue(WhseSourceFilter.Code); // Enqueue for FiltersToGetSourceDocsPageHandler
        LibraryVariableStorage.Enqueue(StrSubstNo(GetSourceDocErr, 4)); // Enqueue for MessageHandler, 4 source document cannot be got due to blocked customers
        WhseShipment."Use Filters to Get Src. Docs.".Invoke(); // Invoke Action Use Filters to Get Src. Docs.

        // FiltersToGetSourceDocsPageHandler will invoke Run Action with using the enqueued Filter Code

        // Verify : MessageHandler will verify the warning Message
        // Check whether the warehouse shipment line for the items exist
        VerifyWhseShipmentLineExist(WhseShipmentHeader."No.", SalesHeader[1]."No.", true);
        VerifyWhseShipmentLineExist(WhseShipmentHeader."No.", SalesHeader[2]."No.", false);
        VerifyWhseShipmentLineExist(WhseShipmentHeader."No.", SalesHeader[3]."No.", false);
        VerifyWhseShipmentLineExist(WhseShipmentHeader."No.", SalesHeader[4]."No.", false);
        VerifyWhseShipmentLineExist(WhseShipmentHeader."No.", SalesHeader[5]."No.", false);
    end;

    [Test]
    [HandlerFunctions('FiltersToGetSourceDocsModifyActionPageHandler,SourceDocumentFilterCardPageHandler')]
    [Scope('OnPrem')]
    procedure PageSourceDocFilterCardShipmentPositive()
    begin
        PageSourceDocFilterCardShipment(true);
    end;

    [Test]
    [HandlerFunctions('FiltersToGetSourceDocsModifyActionPageHandler,SourceDocumentFilterCardPageHandler')]
    [Scope('OnPrem')]
    procedure PageSourceDocFilterCardShipmentNegative()
    begin
        asserterror PageSourceDocFilterCardShipment(false);
        Assert.ExpectedError(ShipmentLinesNotCreatedErr);
    end;

    [Test]
    [HandlerFunctions('FiltersToGetSourceDocsModifyActionPageHandler,SourceDocumentFilterCardPageHandler')]
    [Scope('OnPrem')]
    procedure PageSourceDocFilterCardReceiptPositive()
    begin
        PageSourceDocFilterCardReceipt(true);
    end;

    [Test]
    [HandlerFunctions('FiltersToGetSourceDocsModifyActionPageHandler,SourceDocumentFilterCardPageHandler')]
    [Scope('OnPrem')]
    procedure PageSourceDocFilterCardReceiptNegative()
    begin
        asserterror PageSourceDocFilterCardReceipt(false);
        Assert.ExpectedError(ReceiptLinesNotCreatedErr);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PickLotTrackedFEFOWarehouseShipment()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        LotNo: array[2] of Code[20];
        Quantity: Decimal;
        OldPickAccordingToFEFO: Boolean;
    begin
        // [FEATURE] [FEFO] [Item Tracking]
        // [SCENARIO 130268] Lot Tracked Item with Expiration Date on FEFO Location fully picked if inventory available.

        // [GIVEN] Location with Required: Receipt, Put-Away, Pick, Shipment; "Bin Mandarory" = TRUE, "Pick According to FEFO" = TRUE.
        Initialize();
        OldPickAccordingToFEFO := UpdatePickAccordingToFEFOOnLocation(LocationOrange, true);

        // [GIVEN] Create Lot tracked Item.
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);

        // [GIVEN] Add Item inventory of Quantity "B" to 3 bins: "X", "Y", "Z", each next bin has greater Expiration Date that previous.
        Quantity := 2 * LibraryRandom.RandIntInRange(50, 100);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No. & Expiration Date");
        LibraryVariableStorage.Enqueue(CalcDate('<+1Y>', WorkDate()));
        CreateAndPostItemJournalLineWithNewBinUsingItemTracking(Bin, LotNo[1], Item."No.", LocationOrange.Code, Quantity);

        // [GIVEN] Set "Receipt Bin Code" of Location to "X".
        LocationOrange.Validate("Receipt Bin Code", Bin.Code);
        LocationOrange.Modify(true);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No. & Expiration Date");
        LibraryVariableStorage.Enqueue(CalcDate('<+1Y+1M>', WorkDate()));
        CreateAndPostItemJournalLineWithNewBinUsingItemTracking(Bin, LotNo[2], Item."No.", LocationOrange.Code, Quantity);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No. & Expiration Date");
        LibraryVariableStorage.Enqueue(CalcDate('<+1Y+2M>', WorkDate()));
        CreateAndPostItemJournalLineWithNewBinUsingItemTracking(Bin, LotNo[2], Item."No.", LocationOrange.Code, Quantity);

        // [GIVEN] Create Sales Order with Quantity "Q", where "B" < "Q" <= (2 * "B").
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", LocationOrange.Code, '', 1.5 * Quantity, WorkDate(), false, false);

        // [WHEN] Create Pick.
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [THEN] Taken Quantity = "Q".
        VerifyPickLine(WarehouseActivityLine."Action Type"::Take, SalesHeader."No.", Item."No.", 1.5 * Quantity);

        // Tear down.
        UpdatePickAccordingToFEFOOnLocation(LocationOrange, OldPickAccordingToFEFO);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarehouseActivityLineAfterRenamingBin()
    var
        Bin: Record Bin;
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // [FEATURE] [UT] [Warehouse Activity] [Bin]
        // [SCENARIO 371808] Warehouse Activity Line should update Bin Code after renaming appropriate Bin

        // [GIVEN] Bin "X"
        // [GIVEN] Warehouse Activity Line with "Bin Code" = "X"
        MockWarehouseActivityLineAndBin(WarehouseActivityLine, Bin);

        // [WHEN] Rename Bin "X" to "Y"
        Bin.Rename(Bin."Location Code", LibraryUtility.GenerateGUID());

        // [THEN] Warehouse Activity Line has "Bin Code" = "Y"
        WarehouseActivityLine.Find();
        WarehouseActivityLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('ReservationPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DeletedShipmentIsExcludedFromQtyAllocatedInWhse()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        ReservationMode: Option "Reserve From Current Line","Reserve From First Line","Verify Reserve Line";
    begin
        // [FEATURE] [Warehouse Shipment] [Reservation]
        // [SCENARIO 382267] Quantity in shipment bin for location that is not set up for directed put-away and pick, should not be considered as allocated in warehouse if the related shipment has been picked and deleted.
        Initialize();

        // [GIVEN] Location "L" with mandatory bin set up for required receive, put-away, shipment and pick.
        LibraryInventory.CreateItem(Item);
        CreateLocationWithBulkReceiveShipmentBins(Location);

        // [GIVEN] Posted and put-away purchase order for "Q" pcs.
        CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(PurchaseHeader, Item."No.", Location.Code, 100);

        // [GIVEN] Released sales order "S1" with warehouse shipment and registered pick for "q1" < "Q" pcs.
        CreateAndRegisterPickFromWarehouseShipmentUsingSalesOrder(
          WarehouseShipmentHeader, SalesHeader, Item."No.", Location.Code, 20);

        // [GIVEN] The warehouse shipment is reopened and deleted.
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);
        ReopenAndDeleteWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Released sales order "S2" with warehouse shipment for "q2" pcs. "q1" < "q2" < "Q".
        CreateAndReleaseSalesOrder(
          SalesHeader, SalesLine, Item."No.", Location.Code, '', LibraryRandom.RandIntInRange(30, 50), WorkDate(), false, false);
        CreateWarehouseShipment(SalesHeader);

        // [GIVEN] Sales order "S3" for "q3" < "Q" pcs.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item."No.", Location.Code,
          LibraryRandom.RandIntInRange(10, 20));

        // [WHEN] Open reservation page for the sales line in "S3".
        LibraryVariableStorage.Enqueue(ReservationMode::"Verify Reserve Line");
        LibraryVariableStorage.Enqueue(100);
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(0);
        SalesLine.ShowReservation();

        // [THEN] Qty. allocated in warehouse = 0.
        // Verification is done in ReservationPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderExternalDocumentNoIsNotChangedOnPostCreatedWhseReceipt()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        SalesReturnExtDoc: Text[10];
        VendorShipmentDoc: Text[10];
    begin
        // [FEATURE] [Sales Return]
        // [SCENARIO 204590] "External Document No." for Sales Return Order is not changed when you create Whse. Receipt and post it with "Vendor Shipment No." populated.

        Initialize();

        LibraryInventory.CreateItem(Item);
        SalesReturnExtDoc := UpperCase(LibraryUtility.GenerateGUID());
        VendorShipmentDoc := UpperCase(LibraryUtility.GenerateGUID());

        // [GIVEN] Sales Return Order "SRO" where "External Document No." is populated with a value "VAL1".
        CreateAndReleaseSalesReturnOrder(SalesHeader, Item."No.", LocationYellow.Code, LibraryRandom.RandDec(100, 2));
        SalesHeader."External Document No." := SalesReturnExtDoc;
        SalesHeader.Modify();

        // [GIVEN] Whse. Receipt created for "SRO".
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.");

        // [GIVEN] Whse. Receipt's "Vendor Shipment No." is populated with a value "VAL2".
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        WarehouseReceiptHeader."Vendor Shipment No." := VendorShipmentDoc;
        WarehouseReceiptHeader.Modify();

        // [WHEN] Post Whse. Receipt.
        PostWarehouseReceipt(WarehouseReceiptLine."No.");

        // [THEN] "SRO" "External Document No." has still "VAL1".
        SalesHeader.Find();
        Assert.AreEqual(
          SalesReturnExtDoc, SalesHeader."External Document No.",
          'SalesHeader."External Document No." should not be changed');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure WarehouseShipmentFromSalesOrderWithBlankLocation()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // [FEATURE] [Sales] [Release] [Shipment] [Location]
        // [SCENARIO 222722] Cassie can create warehouse shipments from sales order having lines with blank and filled locaitons
        Initialize();

        // [GIVEN] "Require Shipment" = TRUE in warehouse setup
        LibraryWarehouse.SetRequireShipmentOnWarehouseSetup(true);

        // [GIVEN] Sales order with two lines
        // [GIVEN] "Sales Line"[1] with "Location Code" = "X" for item "A"
        // [GIVEN] "Sales Line"[2] with blank "Location Code" for item "B"
        LibraryInventory.CreateItem(Item);
        CreateSalesOrder(SalesHeader, SalesLineItem, '', Item."No.", LocationWhite.Code, '');
        CreateSalesLine(SalesLineItem, SalesHeader, Item."No.", '', '');

        // [WHEN] Release sales order and create warehouse shipment
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [THEN] Warehouse requests are created for location "X" and for blank location.
        WarehouseRequest.SetRange("Source Type", DATABASE::"Sales Line");
        WarehouseRequest.SetRange("Source Subtype", SalesHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", SalesHeader."No.");
        WarehouseRequest.SetRange("Document Status", SalesHeader.Status::Released);
        Assert.RecordCount(WarehouseRequest, 2);
        WarehouseRequest.SetRange("Location Code", LocationWhite.Code);
        Assert.RecordCount(WarehouseRequest, 1);
        WarehouseRequest.SetRange("Location Code", '');
        Assert.RecordCount(WarehouseRequest, 1);

        // [THEN] Shipment lines are created for location "X" and for blank location.
        FindWarehouseShipmentLine(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        Assert.RecordCount(WarehouseShipmentLine, 2);
        WarehouseShipmentLine.SetRange("Location Code", LocationWhite.Code);
        Assert.RecordCount(WarehouseShipmentLine, 1);
        WarehouseShipmentLine.SetRange("Location Code", '');
        Assert.RecordCount(WarehouseShipmentLine, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure WarehouseReceiptFromPurchaseOrderWithBlankLocation()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseRequest: Record "Warehouse Request";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // [FEATURE] [Purchase] [Release] [Receipt] [Location]
        // [SCENARIO 222722] Cassie can create warehouse shipments from sales order having lines with blank and filled locaitons
        Initialize();

        // [GIVEN] "Require Receive" = TRUE in warehouse setup
        LibraryWarehouse.SetRequireReceiveOnWarehouseSetup(true);

        // [GIVEN] Purchase order with two lines
        // [GIVEN] "Purchase Line"[1] with "Location Code" = "X" for item "A"
        // [GIVEN] "Purchase Line"[2] with blank "Location Code" for item "B"
        LibraryInventory.CreateItem(Item);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order,
          Item."No.", LocationWhite.Code, LibraryRandom.RandIntInRange(5, 10));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] Release purchase order and create warehouse receipt
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [THEN] Warehouse requests are created for location "X" and for blank location.
        WarehouseRequest.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseRequest.SetRange("Source Subtype", PurchaseHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseRequest.SetRange("Document Status", PurchaseHeader.Status::Released);
        Assert.RecordCount(WarehouseRequest, 2);
        WarehouseRequest.SetRange("Location Code", LocationWhite.Code);
        Assert.RecordCount(WarehouseRequest, 1);
        WarehouseRequest.SetRange("Location Code", '');
        Assert.RecordCount(WarehouseRequest, 1);

        // [THEN] Receipt lines are created for location "X" and for blank location.
        FindWarehouseReceiptLine(
          WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        Assert.RecordCount(WarehouseReceiptLine, 2);
        WarehouseReceiptLine.SetRange("Location Code", LocationWhite.Code);
        Assert.RecordCount(WarehouseReceiptLine, 1);
        WarehouseReceiptLine.SetRange("Location Code", '');
        Assert.RecordCount(WarehouseReceiptLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationValidationForPurchaseLineWithJobNoScenario1()
    var
        Item: Record Item;
        Job: Record Job;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        // [SCENARIO] [545709] Setting location with Directed Put-away and Pick on purchase line with job is allowed.

        // [GIVEN] Item and Job. Create purchase line with no job nor location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryJob.CreateJob(Job);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.", '', 1);

        // [WHEN] Setting job no.
        PurchaseLine.Validate("Job No.", Job."No.");

        // [THEN] No error occur.

        // [WHEN] Setting location with no Directed Put-away and Pick.
        PurchaseLine.Validate("Location Code", LocationBlue.Code);

        // [THEN] No error occur.

        // [WHEN] Setting location with Directed Put-away and Pick.
        PurchaseLine.Validate("Location Code", LocationWhite.Code);

        // [THEN] No error occur.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationValidationForPurchaseLineWithJobNoScenario2()
    var
        Item: Record Item;
        Job: Record Job;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        // [SCENARIO] Setting job on purchase line with location with Directed Put-away and Pick is allowed.

        // [GIVEN] Item and Job. Create purchase line with no job nor location.
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryJob.CreateJob(Job);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Item."No.", '', 1);

        // [WHEN] Setting location with Directed Put-away and Pick.
        PurchaseLine.Validate("Location Code", LocationWhite.Code);

        // [THEN] No error occur.

        // [WHEN] Setting job no.
        PurchaseLine.Validate("Job No.", Job."No.");

        // [THEN] No error occur.
    end;

    [Test]
    procedure LocationValidationForPurchaseLineWithGLAccountAndJobNo()
    var
        Job: Record Job;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        // [FEATURE] [Purchase] [Job]
        // [SCENARIO 430663] Setting job on purchase line for g/l account with Directed Put-away and Pick location is allowed.
        Initialize();

        // [GIVEN] Create purchase line at location with directed put-away and pick.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Location Code", LocationWhite.Code);

        // [WHEN] Set job no. on the purchase line. 
        LibraryJob.CreateJob(Job);
        PurchaseLine.Validate("Job No.", Job."No.");

        // [THEN] No error.
        PurchaseLine.TestField("Job No.", Job."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CalculatingAvailQtyToPickWithAnotherPickedShipmentDeleted()
    var
        Item: Record Item;
        Bin: Record Bin;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Shipment] [Pick] [Available Quantity to Pick]
        // [SCENARIO 391098] Calculating available quantity to pick when there was another warehouse shipment that was picked but deleted before posting.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Item "I". Post 10 pcs to location "White".
        LibraryInventory.CreateItem(Item);
        FindBin(Bin, LocationWhite.Code);
        UpdateInventoryUsingWarehouseJournal(Bin, Item, '', Item."Base Unit of Measure", Qty);

        // [GIVEN] Create sales order "SO1" for 6 pcs.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item."No.", LocationWhite.Code, Qty / 2);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse shipment "WS1" from the sales order "SO1".
        // [GIVEN] Create and register warehouse pick.
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // [GIVEN] Delete warehouse shipment "WS1".
        LibraryVariableStorage.Enqueue(PickedConfirmMessage);
        ReopenAndDeleteWarehouseShipment(WarehouseShipmentHeader);

        // [GIVEN] Create sales order "SO2" for 4 pcs.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Item."No.", LocationWhite.Code, Qty / 2);
        LibrarySales.AutoReserveSalesLine(SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [GIVEN] Create warehouse shipment "WS2" from the sales order "SO2".
        CreateWarehouseShipment(SalesHeader);

        // [WHEN] Create pick.
        CreatePick(WarehouseShipmentHeader, SalesHeader."No.");

        // [THEN] A warehouse pick has been created and can be registered.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] The warehouse shipment "WS2" can be posted.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure WhseShipmentBinFieldsDynamicVisibilty_OnValidate()
    var
        WhseShipment: TestPage "Warehouse Shipment";
    begin
        // [BUG 454137] Visiblity of Bin Code on Warehouse Shipment Lines is set dynamically from Location Code
        Initialize();
        Assert.IsTrue(LocationWhite."Bin Mandatory", 'White Location should have Bin Mandatory = true for this test.');
        Assert.IsFalse(LocationYellow."Bin Mandatory", 'Yellow Location should have Bin Mandatory = false for this test.');

        // [GIVEN] An empty Warehouse Receipt is opened
        WhseShipment.OpenNew();

        // [WHEN] Location Code is set to YELLOW, which has Bin Mandatory = false
        WhseShipment."Location Code".SetValue(LocationYellow.Code);

        // [THEN] Bin fields are NOT visible on the page
        Assert.IsFalse(WhseShipment.WhseShptLines."Bin Code".Visible(), 'Bin Code should not be visible by default on Warehouse Shipments with Bin Code NOT Mandatory');
        Assert.IsFalse(WhseShipment."Bin Code".Visible(), 'Bin Code should not be visible by default on Warehouse Shipments with Bin Code NOT Mandatory');
        Assert.IsFalse(WhseShipment."Zone Code".Visible(), 'Zone Code should not be visible by default on Warehouse Shipments with Bin Code NOT Mandatory');

        // [WHEN] Location Code is set to WHITE, which has Bin Mandatory = true
        WhseShipment."Location Code".SetValue(LocationWhite.Code);

        // [THEN] Bin Fields are visible on the page
        Assert.IsTrue(WhseShipment.WhseShptLines."Bin Code".Visible(), 'Bin Code should be visible by default on Warehouse Shipments with Bin Code Mandatory');
        Assert.IsTrue(WhseShipment."Bin Code".Visible(), 'Bin Code should be visible by default on Warehouse Shipments with Bin Code Mandatory');
        Assert.IsTrue(WhseShipment."Zone Code".Visible(), 'Zone Code should be visible by default on Warehouse Shipments with Bin Code Mandatory');
    end;

    [Test]
    procedure WhseReceiptBinFieldsCodeDynamicVisibilty_OnValidate()
    var
        WhseReceipt: TestPage "Warehouse Receipt";
    begin
        // [BUG 454137] Visiblity of Bin Code on Warehouse Shipment Lines is set dynamically from Location Code
        Initialize();
        Assert.IsTrue(LocationWhite."Bin Mandatory", 'White Location should have Bin Mandatory = true for this test.');
        Assert.IsFalse(LocationYellow."Bin Mandatory", 'Yellow Location should have Bin Mandatory = false for this test.');

        // [GIVEN] An empty Warehouse Receipt is opened
        WhseReceipt.OpenNew();

        // [WHEN] Location Code is set to YELLOW, which has Bin Mandatory = false
        WhseReceipt."Location Code".SetValue(LocationYellow.Code);

        // [THEN] Bin fields are NOT visible on the page
        Assert.IsFalse(WhseReceipt.WhseReceiptLines."Bin Code".Visible(), 'Bin Code should not be visible by default on Warehouse Receipts with Bin Code NOT Mandatory');
        Assert.IsFalse(WhseReceipt."Bin Code".Visible(), 'Bin Code should not be visible by default on Warehouse Receipts with Bin Code NOT Mandatory');
        Assert.IsFalse(WhseReceipt."Zone Code".Visible(), 'Zone Code should not be visible by default on Warehouse Receipts with Bin Code NOT Mandatory');

        // [WHEN] Location Code is set to WHITE, which has Bin Mandatory = true
        WhseReceipt."Location Code".SetValue(LocationWhite.Code);

        // [THEN] Bin Fields are visible on the page
        Assert.IsTrue(WhseReceipt.WhseReceiptLines."Bin Code".Visible(), 'Bin Code should be visible by default on Warehouse Receipts with Bin Code Mandatory');
        Assert.IsTrue(WhseReceipt."Bin Code".Visible(), 'Bin Code should be visible by default on Warehouse Receipts with Bin Code Mandatory');
        Assert.IsTrue(WhseReceipt."Zone Code".Visible(), 'Zone Code should be visible by default on Warehouse Receipts with Bin Code Mandatory');
    end;

    [Test]
    procedure WhseDocumentsBinFieldsDynamicVisibilty_BinMandatory()
    begin
        // [BUG 454137] Bin Code and Activity Type in Whse Documents are visible when Location uses Bins.
        Initialize();
        Assert.IsTrue(LocationWhite."Bin Mandatory", 'White Location should have Bin Mandatory = false for this test.');

        WhseDocumentsBinFieldsDynamicVisibilty(LocationWhite);
    end;

    [Test]
    procedure WhseDocumentsBinFieldsDynamicVisibilty_BinNotMandatory()
    begin
        // [BUG 454137] Bin Code and Activity Type in Whse Documents are not visible when Location does not use Bins.
        Initialize();
        Assert.IsFalse(LocationYellow."Bin Mandatory", 'Yellow Location should have Bin Mandatory = false for this test.');

        WhseDocumentsBinFieldsDynamicVisibilty(LocationYellow);
    end;

    local procedure WhseDocumentsBinFieldsDynamicVisibilty(Location: Record Location)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseReceipt: TestPage "Warehouse Receipt";
        WhseReceiptList: TestPage "Warehouse Receipts";
        WhsePutaway: TestPage "Warehouse Put-away";
        WhsePutawayList: TestPage "Warehouse Put-aways";
        WhseShipment: TestPage "Warehouse Shipment";
        WhseShipmentList: TestPage "Warehouse Shipment List";
        WhsePick: TestPage "Warehouse Pick";
        WhsePickList: TestPage "Warehouse Picks";
        WhseReceiptNo: Code[20];
        WhseShipmentNo: Code[20];
    begin
        // PART 1: Warehouse Receipt
        // [GIVEN] A Warehouse Receipt for Location
        WhseReceiptNo := CreateWhseReceiptForLocation(PurchaseHeader, PurchaseLine, Location.Code);
        WhseReceiptHeader.SetFilter("No.", WhseReceiptNo);
        WhseReceiptHeader.FindFirst();

        // [WHEN] The Receipt Page is opened (Has to be done through the list page to set the record before opening)
        WhseReceiptList.OpenView();
        WhseReceiptList.GoToRecord(WhseReceiptHeader);
        WhseReceipt.Trap();
        WhseReceiptList.Edit().Invoke();

        // [THEN] Bin fields are visible on the page IF Location."Bin Mandatory"
        Assert.AreEqual(Location."Bin Mandatory", WhseReceipt.WhseReceiptLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');
        Assert.AreEqual(Location."Bin Mandatory", WhseReceipt."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');
        Assert.AreEqual(Location."Bin Mandatory", WhseReceipt."Zone Code".Visible(), 'Zone Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');
        WhseReceipt.Close();


        // PART 2: Warehouse Put-away
        // [GIVEN] the Receipt is posted and a Put-away created
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);

        // Find the put-away
        LibraryWarehouse.FindWhseActivityBySourceDoc(WhseActivityHeader, DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", PurchaseLine."Line No.");

        // [WHEN] The Put-away Page is opened (same way as before)
        WhsePutawayList.OpenView();
        WhsePutawayList.GoToRecord(WhseActivityHeader);
        WhsePutaway.Trap();
        WhsePutawayList.Edit().Invoke();

        // [THEN] Bin fields are visible on the page IF Location."Bin Mandatory"
        Assert.AreEqual(Location."Bin Mandatory", WhsePutaway.WhseActivityLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Put-away only when Bin Mandatory is true');
        Assert.AreEqual(Location."Bin Mandatory", WhsePutaway.WhseActivityLines."Action Type".Visible(), 'Action Type should by default be visible on Warehouse Put-away only when Bin Mandatory is true');
        WhsePutaway.Close();

        // Register the Put-away so the Bin has content for next parts
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);


        // PART 3: Warehouse Shipment
        // [GIVEN] A Warehouse Shipment for Location is created
        WhseShipmentNo := CreateWhseShipmentForLocation(SalesHeader, SalesLine, Location.Code, PurchaseLine."No.");
        WhseShipmentHeader.Get(WhseShipmentNo);

        // [WHEN] The Shipment Page is opened (same way as before)
        WhseShipmentList.OpenView();
        WhseShipmentList.GoToKey(WhseShipmentNo);
        WhseShipment.Trap();
        WhseShipmentList.Edit().Invoke();

        // [THEN] Bin fields are visible on the page IF Location."Bin Mandatory"
        Assert.AreEqual(Location."Bin Mandatory", WhseShipment.WhseShptLines."Bin Code".Visible(), 'Bin Code should be visible by default on Warehouse Shipment only when Bin Code Mandatory is true');
        Assert.AreEqual(Location."Bin Mandatory", WhseShipment."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Shipment only when Bin Mandatory is true');
        Assert.AreEqual(Location."Bin Mandatory", WhseShipment."Zone Code".Visible(), 'Zone Code should by default be visible on Warehouse Shipment only when Bin Mandatory is true');
        WhseShipment.Close();


        // PART 4: Warehouse Pick
        // [GIVEN] A Pick is created from the Shipment
        CreatePick(WhseShipmentHeader, SalesHeader."No.");

        // Find the created Pick
        LibraryWarehouse.FindWhseActivityBySourceDoc(WhseActivityHeader, DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", SalesLine."Line No.");

        // [WHEN] The Pick Page is opened (same way as before)
        WhsePickList.OpenView();
        WhsePickList.GoToRecord(WhseActivityHeader);
        WhsePick.Trap();
        WhsePickList.Edit().Invoke();

        // [THEN] Bin fields are visible on the page IF Location."Bin Mandatory"
        Assert.AreEqual(Location."Bin Mandatory", WhsePick.WhseActivityLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Put-away only when Bin Mandatory is true');
        Assert.AreEqual(Location."Bin Mandatory", WhsePick.WhseActivityLines."Action Type".Visible(), 'Action Type should by default be visible on Warehouse Put-away only when Bin Mandatory is true');
        WhsePick.Close();
    end;

    [Test]
    procedure WhseDocumentsBinFieldsDynamicVisibilty_SwitchBetweenRecords()
    var
        YellowPurchaseHeader: Record "Purchase Header";
        WhitePurchaseHeader: Record "Purchase Header";
        YellowPurchaseLine: Record "Purchase Line";
        WhitePurchaseLine: Record "Purchase Line";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        YellowWhseActivityHeader: Record "Warehouse Activity Header";
        WhiteWhseActivityHeader: Record "Warehouse Activity Header";
        YellowSalesHeader: Record "Sales Header";
        WhiteSalesHeader: Record "Sales Header";
        YellowSalesLine: Record "Sales Line";
        WhiteSalesLine: Record "Sales Line";
        YellowWhseShipmentHeader: Record "Warehouse Shipment Header";
        WhiteWhseShipmentHeader: Record "Warehouse Shipment Header";
        WhsePutaway: TestPage "Warehouse Put-away";
        WhseReceipt: TestPage "Warehouse Receipt";
        WhseShipment: TestPage "Warehouse Shipment";
        WhsePick: TestPage "Warehouse Pick";
        YellowWhseReceiptNo: Code[20];
        WhiteWhseReceiptNo: Code[20];
        YellowWhseShipmentNo: Code[20];
        WhiteWhseShipmentNo: Code[20];
    begin
        // [BUG 457309] Visibility of Bin fields is updated when switching using "<" and ">" buttons to switch between records on warehouse document pages.
        Initialize();
        Assert.IsFalse(LocationYellow."Bin Mandatory", 'Yellow Location should have Bin Mandatory = false for this test.');
        Assert.IsTrue(LocationWhite."Bin Mandatory", 'White Location should have Bin Mandatory = true for this test.');


        // PART 1: Warehouse Receipt
        // [GIVEN] Two warehouse receipts for Location Yellow and White respectively
        YellowWhseReceiptNo := CreateWhseReceiptForLocation(YellowPurchaseHeader, YellowPurchaseLine, LocationYellow.Code);
        WhiteWhseReceiptNo := CreateWhseReceiptForLocation(WhitePurchaseHeader, WhitePurchaseLine, LocationWhite.Code);

        WhseReceipt.OpenEdit();
        WhseReceipt.GoToKey(WhiteWhseReceiptNo);

        // [WHEN] We simulate using the "<" button to move from the White WhseReceipt to the Yellow (Triggering OnAfterGetRecord but not OnOpenPage)
        WhseReceipt.GoToKey(YellowWhseReceiptNo);

        // [THEN] The visibility is set according to the Yellow location
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhseReceipt.WhseReceiptLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhseReceipt."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhseReceipt."Zone Code".Visible(), 'Zone Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');

        // [WHEN] We simulate using the ">" button to move from the Yellow WhseReceipt to the White
        WhseReceipt.GoToKey(WhiteWhseReceiptNo);

        // [THEN] The visibility is set according to the White location
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhseReceipt.WhseReceiptLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhseReceipt."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhseReceipt."Zone Code".Visible(), 'Zone Code should by default be visible on Warehouse Receipts only when Bin Mandatory is true');
        WhseReceipt.Close();


        // PART 2: Warehouse Put-away
        // [GIVEN] The Receipts are posted and Put-aways created
        WhseReceiptHeader.Get(YellowWhseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);
        LibraryWarehouse.FindWhseActivityBySourceDoc(YellowWhseActivityHeader, DATABASE::"Purchase Line", YellowPurchaseHeader."Document Type".AsInteger(), YellowPurchaseHeader."No.", WhitePurchaseLine."Line No.");

        WhseReceiptHeader.Get(WhiteWhseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WhseReceiptHeader);
        LibraryWarehouse.FindWhseActivityBySourceDoc(WhiteWhseActivityHeader, DATABASE::"Purchase Line", WhitePurchaseHeader."Document Type".AsInteger(), WhitePurchaseHeader."No.", WhitePurchaseLine."Line No.");

        // [GIVEN] The Put-away page is opened
        WhsePutaway.OpenEdit();
        WhsePutaway.GoToRecord(WhiteWhseActivityHeader);

        // [WHEN] We simulate using the "<" button to move from the White Put-away to the Yellow (Triggering OnAfterGetRecord but not OnOpenPage)
        WhsePutaway.GoToRecord(YellowWhseActivityHeader);

        // [THEN] The visibility is set according to the Yellow location
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhsePutaway.WhseActivityLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Put-away only when Bin Mandatory is true');
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhsePutaway.WhseActivityLines."Action Type".Visible(), 'Action Type should by default be visible on Warehouse Put-away only when Bin Mandatory is true');

        // [WHEN] We simulate using the ">" button to move from the Yellow Put-away to the White
        WhsePutaway.GoToRecord(WhiteWhseActivityHeader);

        // [THEN] The visibility is set according to the White location
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhsePutaway.WhseActivityLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Put-away only when Bin Mandatory is true');
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhsePutaway.WhseActivityLines."Action Type".Visible(), 'Action Type should by default be visible on Warehouse Put-away only when Bin Mandatory is true');
        WhsePutaway.Close();

        // Register the Put-away so the Bin has content for next parts
        LibraryWarehouse.RegisterWhseActivity(WhiteWhseActivityHeader);
        LibraryWarehouse.RegisterWhseActivity(YellowWhseActivityHeader);


        // PART 3: Warehouse Shipment
        // [GIVEN] Warehouse Shipments are created
        YellowWhseShipmentNo := CreateWhseShipmentForLocation(YellowSalesHeader, YellowSalesLine, LocationYellow.Code, YellowPurchaseLine."No.");
        WhiteWhseShipmentNo := CreateWhseShipmentForLocation(WhiteSalesHeader, WhiteSalesLine, LocationWhite.Code, WhitePurchaseLine."No.");

        // [WHEN] The Shipment Page is opened
        WhseShipment.OpenEdit();
        WhseShipment.GoToKey(WhiteWhseShipmentNo);

        // [WHEN] We simulate using the "<" button to move from the White WhseShipment to the Yellow
        WhseShipment.GoToKey(YellowWhseShipmentNo);

        // [THEN] The visibility is set according to the Yellow location
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhseShipment.WhseShptLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Shipments only when Bin Mandatory is true');
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhseShipment."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Shipments only when Bin Mandatory is true');
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhseShipment."Zone Code".Visible(), 'Zone Code should by default be visible on Warehouse Shipments only when Bin Mandatory is true');

        // [WHEN] We simulate using the ">" button to move from the Yellow WhseReceipt to the White
        WhseShipment.GoToKey(WhiteWhseShipmentNo);

        // [THEN] The visibility is set according to the White location
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhseShipment.WhseShptLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Shipments only when Bin Mandatory is true');
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhseShipment."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Shipments only when Bin Mandatory is true');
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhseShipment."Zone Code".Visible(), 'Zone Code should by default be visible on Warehouse Shipments only when Bin Mandatory is true');
        WhseShipment.Close();


        // PART 4: Warehouse Pick
        // [GIVEN] Picks are created from the Shipments
        YellowWhseShipmentHeader.Get(YellowWhseShipmentNo);
        CreatePick(YellowWhseShipmentHeader, YellowSalesHeader."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(YellowWhseActivityHeader, DATABASE::"Sales Line", YellowSalesHeader."Document Type".AsInteger(), YellowSalesHeader."No.", YellowSalesLine."Line No.");
        WhiteWhseShipmentHeader.Get(WhiteWhseShipmentNo);
        CreatePick(WhiteWhseShipmentHeader, WhiteSalesHeader."No.");
        LibraryWarehouse.FindWhseActivityBySourceDoc(WhiteWhseActivityHeader, DATABASE::"Sales Line", WhiteSalesHeader."Document Type".AsInteger(), WhiteSalesHeader."No.", WhiteSalesLine."Line No.");

        // [WHEN] The Pick Page is opened
        WhsePick.OpenEdit();
        WhsePick.GoToRecord(WhiteWhseActivityHeader);

        // [WHEN] We simulate using the "<" button to move from the White Pick to the Yellow
        WhsePick.GoToRecord(YellowWhseActivityHeader);

        // [THEN] The visibility is set according to the Yellow location
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhsePick.WhseActivityLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Pick only when Bin Mandatory is true');
        Assert.AreEqual(LocationYellow."Bin Mandatory", WhsePick.WhseActivityLines."Action Type".Visible(), 'Action Type should by default be visible on Warehouse Pick only when Bin Mandatory is true');

        // [WHEN] We simulate using the ">" button to move from the Yellow Put-away to the White
        WhsePick.GoToRecord(WhiteWhseActivityHeader);

        // [THEN] The visibility is set according to the White location
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhsePick.WhseActivityLines."Bin Code".Visible(), 'Bin Code should by default be visible on Warehouse Pick only when Bin Mandatory is true');
        Assert.AreEqual(LocationWhite."Bin Mandatory", WhsePick.WhseActivityLines."Action Type".Visible(), 'Action Type should by default be visible on Warehouse Pick only when Bin Mandatory is true');
        WhsePick.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDescriptionAndDescription2OnWarehouseMovementWithItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Bin: Record Bin;
        Bin2: Record Bin;
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        // [SCENARIO 479959] Description/Description 2 are not updated when user selects variant code: Movement Worksheet
        Initialize();

        // [GIVEN] Create Item with Item Variant. 
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant."Description 2" := LibraryUtility.GenerateRandomText(20);
        ItemVariant.Modify(true);

        // [THEN] Update Inventory for Item with Variant and Create Movement Worksheet Line
        FindBin(Bin, LocationWhite.Code);
        LibraryWarehouse.CreateBin(Bin2, Bin."Location Code", LibraryUtility.GenerateGUID(), Bin."Zone Code", Bin."Bin Type Code");
        UpdateInventoryUsingWarehouseJournal(
            Bin, Item, ItemVariant.Code, Item."Base Unit of Measure", LibraryRandom.RandDec(100, 2) + LibraryRandom.RandDec(100, 2));
        LibraryWarehouse.CreateMovementWorksheetLine(
            WhseWorksheetLine, Bin, Bin2, Item."No.", ItemVariant.Code, LibraryRandom.RandDec(100, 2));

        // [VERIFY] Verify: Description/Description 2 of "Whse. Worksheet Line" should be equal to "Item Variant" Description/Description 2
        Assert.AreEqual(ItemVariant.Description, WhseWorksheetLine.Description, DescriptionMustBeSame);
        Assert.AreEqual(ItemVariant."Description 2", WhseWorksheetLine."Description 2", DescriptionMustBeSame);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('GLPostingPreviewPageHandler')]
    procedure PostPreview_WarehouseShipmentWithMultipleSources()
    var
        Item: Record Item;
        Customer: Record Customer;
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipment: TestPage "Warehouse Shipment";
        Quantity: Decimal;
    begin
        // Bug - https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_workitems/edit/497530
        // [SCENARIO ] Posting Preview of Warehouse Shipment with lines from multiple Sales Orders, runs successfully.
        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a location with only 'Require Shipment' ON.
        CreateAndUpdateLocation(Location, false, false, true, false, false);  // With Shipment.

        // [GIVEN] Make current user as a warehouse employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] OR Create and post a positive adjustment journal line for the item and location and set the quantity as 5.
        Quantity := 5;
        CreateAndPostItemJournalLine(ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, Location.Code, '');

        // [GIVEN] Create sales order for item and location and set the quanntity as 1.
        LibrarySales.CreateCustomer(Customer);
        CreateAndReleaseSalesOrder(SalesHeader, Customer."No.", Item."No.", Location.Code, 1);

        // [GIVEN] Create the above 2 steps for another 4 times making 5 SOs with 1 quantity each.
        CreateAndReleaseSalesOrder(SalesHeader, Customer."No.", Item."No.", Location.Code, 1);
        CreateAndReleaseSalesOrder(SalesHeader, Customer."No.", Item."No.", Location.Code, 1);
        CreateAndReleaseSalesOrder(SalesHeader, Customer."No.", Item."No.", Location.Code, 1);
        CreateAndReleaseSalesOrder(SalesHeader, Customer."No.", Item."No.", Location.Code, 1);

        // [GIVEN] Create a warehouse shipment for the location.
        // [GIVEN] Create warehouse shipment lines by running 'Get Source Documents' action.
        GetSourceDocumentOnWarehouseShipment(WarehouseShipmentHeader, Location.Code, false);
        Commit();

        // [GIVEN] Open the warehouse shipment page.
        WarehouseShipment.OpenEdit();
        WarehouseShipment.GoToRecord(WarehouseShipmentHeader);

        // [WHEN] Preview Posting action is invoked.
        WarehouseShipment.PreviewPosting.Invoke();

        // [THEN] The action runs successfully.
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CloseGLPostingPreviewPageHandler')]
    procedure WarehouseReceiptPageRemainsOpenWhenRunPreviewPostAndCloseGLPostingPreviewPage()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceipt: TestPage "Warehouse Receipt";
    begin
        // [SCENARIO 540123] When Stan Preview Posts Warehouse Receipt and closes G/L Posting Preview page then
        // Warehouse Receipt page remains open.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a location with Require Receive and Require Putaway.
        CreateAndUpdateLocation(Location, true, true, false, false, false);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");

        // [GIVEN] Create a Purchase Line and Validate Location Code.
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 10));
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);

        // [GIVEN] Release Purchase Order.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Create Warehouse Receipt from Purchase Order.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        // [GIVEN] Find Warehouse Receipt Header.
        WarehouseReceiptHeader.SetRange("Location Code", Location.Code);
        WarehouseReceiptHeader.FindFirst();
        Commit();

        // [WHEN] Open Warehouse Receipt page and run Preview Posting action.
        WarehouseReceipt.OpenEdit();
        WarehouseReceipt.GoToRecord(WarehouseReceiptHeader);
        WarehouseReceipt.PreviewPosting.Invoke();

        // [THEN] Warehouse Receipt remains Open.
        WarehouseReceipt."No.".AssertEquals(Format(WarehouseReceiptHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler,ConfirmHandlerYes')]
    procedure UndoTransferShipmentWithAlternateUOMShowsCorrectItemTrackingQuantity()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Quantity: Decimal;
        QuantityPerUOM: Decimal;
        LotNo: array[4] of Code[50];
    begin
        // [SCENARIO 562010] Item Tracking Line show correct quantity and lines after undo Transfer shipment with alternate unit of measure.
        Initialize();

        // [GIVEN] Generate Quantity.
        Quantity := LibraryRandom.RandIntInRange(5, 5);

        // [GIVEN] Generate Quantity per unit of measure.
        QuantityPerUOM := LibraryRandom.RandIntInRange(500, 500);

        // [GIVEN] Generate Four Lot No.
        GenerateFourLot(LotNo);

        // [GIVEN] Create Item with Lot No. Tracking.
        LibraryInventory.CreateTrackedItem(Item, '', '', LotItemTrackingCode.Code);

        // [GIVEN] Create Item Unit of measure Code.
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QuantityPerUOM);

        // [GIVEN] Create Item Journal with Four lines of Item Tracking and Post.
        CreateItemJournalWithItemTrackingAndPost(ItemJournalLine, Quantity, ItemUnitOfMeasure.Code, Item."No.", LotNo);

        // [GIVEN] Create Transfer Order and assign Item tracking.
        CreateTransferOrderLineWithItemTracking(TransferHeader, TransferLine, LocationBlue.Code, LocationRed.Code, Item."No.", Quantity, ItemUnitOfMeasure.Code);

        // [GIVEN] Create Warehouse shipment for Transfer Order and Release. 
        CreateAndReleaseWarehouseShipmentFromTransferOrder(WarehouseShipmentHeader, TransferHeader);

        // [GIVEN] Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [GIVEN] Undo Transfer Order Shipment.
        LibraryInventory.UndoTransferShipments(TransferHeader."No.");

        // [THEN] Verify The Posted Warehouse Shipment Line after Undo Transfer Shipment.
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", TransferLine.Quantity, false);
        VerifyPostedWarehouseShipmentLine(
          PostedWhseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.", Item."No.", -TransferLine.Quantity, true);

        // [THEN] Verify Item Tracking Receipt Line on Transfer Line after Undo,verification done in ItemTrackingLinesPageHandler.
        VerifyTrackingOnTransferLineReceiptAfterUndo(TransferLine, 0, Quantity * QuantityPerUOM);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CloseGLPostingPreviewPageHandler')]
    procedure WarehouseShipmentPageRemainsOpenWhenRunPreviewPostAndCloseGLPostingPreviewPage()
    var
        Item: Record Item;
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipment: TestPage "Warehouse Shipment";
        Quatity: Decimal;
    begin
        // [SCENARIO 563377] When Preview Posts Warehouse Shipment and closes G/L Posting Preview page then
        // Warehouse Shipment page remains open.
        Initialize();

        // [GIVEN] Create a location with Require Receive and Require Shipment.
        CreateAndUpdateLocation(Location, true, false, true, false, false);

        // [GIVEN] Create Warehouse Employee.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Quantity.
        Quatity := LibraryRandom.RandInt(10);

        // [GIVEN] Post Positive Adjustment for the Item and Location.
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', Quatity, WorkDate(), Quatity);

        // [GIVEN] Create and Release Transfer Order.
        LibraryInventory.CreateTransferHeader(TransferHeader, Location.Code, LocationYellow.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", Quatity);
        LibraryInventory.ReleaseTransferOrder(TransferHeader);

        // [GIVEN] Create Warehouse Shipment from Transfer Order.
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);

        // [GIVEN] Find Warehouse Shipment Header.
        WarehouseShipmentHeader.SetRange("Location Code", Location.Code);
        WarehouseShipmentHeader.FindFirst();
        Commit();

        // [WHEN] Open Warehouse Shipment page and run Preview Posting action.
        WarehouseShipment.OpenEdit();
        WarehouseShipment.GoToRecord(WarehouseShipmentHeader);
        WarehouseShipment.PreviewPosting.Invoke();

        // [THEN] Warehouse Shipment remains Open.
        WarehouseShipment."No.".AssertEquals(Format(WarehouseShipmentHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryPageHandler')]
    procedure PostWarehouseShipmentWithMultipleRegisteredPicks()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        LotNo: Code[50];
        Counter: Integer;
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // [SCENARIO 563117] Post Warehouse Shipment with multiple Registered Pick.
        Initialize();

        // [GIVEN] Create Item with Lot No. Tracking.
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', LotItemTrackingCode.Code);

        // [GIVEN] Generate Quantity.
        Quantity := LibraryRandom.RandInt(5);
        Quantity2 := Quantity + LibraryRandom.RandInt(20);

        // [GIVEN] Generate Lot No.
        LotNo := LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Lot No."), Database::"Warehouse Activity Line");

        // [GIVEN] Post Positive Adjustment with Item Tracking.
        LibraryItemTracking.PostPositiveAdjustmentWithItemTracking(Item, LocationYellow.Code, '', Quantity2, WorkDate(), '', LotNo);

        // [GIVEN] Create and Release Sales Order.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Item."No.", LocationYellow.Code, '', Quantity2, WorkDate(), false, true);

        // [GIVEN] Post Negative Adjustment with Item Tracking.
        POSTNegativeAdjustmentWithItemTracking(Item, LocationYellow.Code, '', Quantity, WorkDate(), '', LotNo);

        // [GIVEN] Create Warehouse Shipment and Pick.
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);

        // [WHEN] Register Pick Multiple Times.
        for Counter := 1 to (Quantity2 - Quantity) do
            UpdateQuantityToHandleAndLotNoOnPickAndRegisterPick(SalesHeader."No.", 1, LotNo);

        // [THEN] Post the Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler,ConfirmHandlerYes,MessageHandlerNotext')]
    procedure InputQtyAndStartingDateTimeIsRecalculatedWhenReplanProdOrder()
    var
        CompItem, ProdItem : Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        Direction: Option Forward,Backward;
        CalcMethod: Option "No Levels","One level","All levels";
        StartingDateTime: DateTime;
    begin
        // [SCENARIO 565975] "Input Quantity" and "Starting Date-Time" in Prod. Order Routing Line is 
        // recalculated when Production Journal is posted and Stan runs Replan Production Order Report.
        Initialize();

        // [GIVEN] Create a Component Item and Validate "Replenishment System", 
        // "Manufacturing Policy" and "Flushing Method".
        LibraryInventory.CreateItem(CompItem);
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::Purchase);
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Stock");
        CompItem.Validate("Flushing Method", CompItem."Flushing Method"::"Pick + Manual");
        CompItem.Modify(true);

        // [GIVEN] Create a Work Center.
        CreateWorkCenter(WorkCenter);

        // [GIVEN] Create and Certify Routing.
        CreateAndCertifyRouting(RoutingHeader, WorkCenter);

        // [GIVEN] Create and Certify Production BOM.
        CreateAndCertifyProductionBOM(ProductionBOMLine, CompItem, LibraryRandom.RandIntInRange(10, 10));

        // [GIVEN] Create a Production Item and Validate "Replenishment System", 
        // "Manufacturing Policy", "Routing No." and "Production BOM No.".
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Stock");
        ProdItem.Validate("Routing No.", RoutingHeader."No.");
        ProdItem.Validate("Production BOM No.", ProductionBOMLine."Production BOM No.");
        ProdItem.Modify(true);

        // [GIVEN] Set Item Inventory.
        SetItemInventory(CompItem, LibraryRandom.RandIntInRange(500, 500));

        // [GIVEN] Create and Refresh Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ProdItem."No.", LibraryRandom.RandIntInRange(50, 50));

        // [GIVEN] Find Prod. Order Routing Line.
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        ProdOrderRoutingLine.FindFirst();

        // [GIVEN] Generate and save Starting Date-Time in a Variable.
        StartingDateTime := ProdOrderRoutingLine."Starting Date-Time";

        // [GIVEN] Open Production Journal.
        OpenProductionJournal(ProductionOrder."No.");

        // [GIVEN] Run Replan Production Order Report.
        LibraryManufacturing.RunReplanProductionOrder(ProductionOrder, Direction::Backward, CalcMethod::"No Levels");

        // [GIVEN] Find Prod. Order Line.
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        // [WHEN] Find Prod. Order Routing Line.
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        ProdOrderRoutingLine.FindFirst();

        // [THEN] "Input Quantity" in Prod. Order Routing Line is equal to "Remaining Quantity" of Prod. Order Line.
        Assert.AreEqual(
            ProdOrderLine."Remaining Quantity",
            ProdOrderRoutingLine."Input Quantity",
            StrSubstNo(
                InputQtyErr,
                ProdOrderLine."Remaining Quantity",
                ProdOrderRoutingLine.TableCaption()));

        // [THEN] "Starting Date-Time" in Prod. Order Routing Line is equal to StartingDateTime.
        Assert.AreNotEqual(
            StartingDateTime,
            ProdOrderRoutingLine."Starting Date-Time",
            StrSubstNo(
                StartingDateTimeErr,
                StartingDateTime,
                ProdOrderRoutingLine.TableCaption()));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse Management II");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse Management II");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();
        CreateLocationSetup();
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item);  // Item Journal Setup.
        ItemJournalSetup(
          PhysicalInventoryItemJournalTemplate, PhysicalInventoryItemJournalBatch,
          PhysicalInventoryItemJournalTemplate.Type::"Phys. Inventory");  // Physical Inventory Journal Setup.
        ItemJournalSetup(OutputItemJournalTemplate, OutputItemJournalBatch, OutputItemJournalTemplate.Type::Output);  // Output Journal Setup.
        ItemJournalSetup(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type::Consumption);  // Consumption Journal Setup.
        CreateItemTrackingCode(LotItemTrackingCode, false, true, false);  // Lot Item Tracking.

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Warehouse Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse Management II");
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify();

        // [GIVEN] Release the sales order.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure GetSourceDocumentOnWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10]; DoNotFillQtyToHandle: Boolean)
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        GetSourceDocuments: Report "Get Source Documents";
    begin
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationCode);
        GetSourceDocuments.SetOneCreatedShptHeader(WarehouseShipmentHeader);
        WarehouseSourceFilter.SetFilters(GetSourceDocuments, LocationCode);
        GetSourceDocuments.SetDoNotFillQtytoHandle(DoNotFillQtyToHandle);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.SetSkipBlockedItem(true);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.RunModal();
    end;

    local procedure CreateWhseReceiptForLocation(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
    begin
        // Create and release a Purchase Order
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        //Create a warehouse Receipt 
        GetSourceDocInbound.CreateFromPurchOrderHideDialog(PurchaseHeader);

        //Find and return the Receipt No
        exit(LibraryWarehouse.FindWhseReceiptNoBySourceDoc(DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No."));
    end;

    local procedure CreateWhseShipmentForLocation(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LocationCode: Code[20]; ItemNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
    begin
        // Create and release a Sales Order
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 1);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify();
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        //Create a warehouse Shipment 
        GetSourceDocOutbound.CreateFromSalesOrderHideDialog(SalesHeader);

        //Find and return the Shipment No
        exit(LibraryWarehouse.FindWhseShipmentNoBySourceDoc(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No."));
    end;

    local procedure PageSourceDocFilterCardReceipt(Positive: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        WhseReceiptHeader: Record "Warehouse Receipt Header";
        WhseSourceFilter: Record "Warehouse Source Filter";
        WhseReceipt: TestPage "Warehouse Receipt";
        DateFilter: Date;
    begin
        // Verify Page "Source Document Filter Card" filter Receipt Date
        Initialize();
        DateFilter := WorkDate();
        if not Positive then
            DateFilter := CalcDate('<1D>', DateFilter);

        CreateItemMakePositiveAdjustAndReleaseTransfer(TransferHeader, LocationBlue.Code, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseSourceFilter(WhseSourceFilter, WhseSourceFilter.Type::Inbound);
        CreateWarehouseReceiptHeaderWithLocation(WhseReceiptHeader, LocationWhite.Code);

        // Open Warehouse Receipt
        LibraryVariableStorage.Enqueue(WhseSourceFilter.Code);
        LibraryVariableStorage.Enqueue(Format(DateFilter));
        Commit();
        WhseReceipt.OpenEdit();
        WhseReceipt.FILTER.SetFilter("No.", WhseReceiptHeader."No.");

        // Invoke Action "Use Filters to Get Src. Docs."
        WhseReceipt."Use Filters to Get Src. Docs.".Invoke();
        VerifyWhseReceiptLineExist(WhseReceiptHeader."No.", TransferHeader."No.", Positive);
    end;

    local procedure PageSourceDocFilterCardShipment(Positive: Boolean)
    var
        TransferHeader: Record "Transfer Header";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseSourceFilter: Record "Warehouse Source Filter";
        WhseShipment: TestPage "Warehouse Shipment";
        DateFilter: Date;
    begin
        // Verify Page "Source Document Filter Card" filter Shipment Date
        Initialize();
        DateFilter := WorkDate();
        if not Positive then
            DateFilter := CalcDate('<1D>', DateFilter);

        CreateItemMakePositiveAdjustAndReleaseTransfer(TransferHeader, LocationWhite.Code, LocationBlue.Code, false);
        LibraryWarehouse.CreateWarehouseSourceFilter(WhseSourceFilter, WhseSourceFilter.Type::Outbound);
        CreateWarehouseShipmentHeaderWithLocation(WhseShipmentHeader, LocationWhite.Code);

        // Open Warehouse Shipment
        LibraryVariableStorage.Enqueue(WhseSourceFilter.Code);
        LibraryVariableStorage.Enqueue(Format(DateFilter));
        Commit();
        WhseShipment.OpenEdit();
        WhseShipment.FILTER.SetFilter("No.", WhseShipmentHeader."No.");

        // Invoke Action "Use Filters to Get Src. Docs."
        WhseShipment."Use Filters to Get Src. Docs.".Invoke();
        VerifyWhseShipmentLineExist(WhseShipmentHeader."No.", TransferHeader."No.", Positive);
    end;

    local procedure BlockCust(CustNo: Code[20]; BlockType: Enum "Customer Blocked")
    var
        Cust: Record Customer;
    begin
        Cust.Get(CustNo);
        Cust.Validate(Blocked, BlockType);
        Cust.Modify(true);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);
        CreateAndUpdateLocation(LocationBlack, false, false, true, true, true);  // With Require Shipment, Require Pick and Bin Mandatory.
        CreateAndUpdateLocation(LocationYellow, true, true, true, true, false);  // With Require Receive, Require Put Away, Require Shipment and Require Pick.
        CreateAndUpdateLocation(LocationSilver, false, true, false, true, true);  // With Require Put Away, Require Pick and Bin Mandatory.
        CreateAndUpdateLocation(LocationBlue, false, false, true, false, false);  // With Required Shipment.
        CreateAndUpdateLocation(LocationRed, true, false, true, false, false);  // With Required Receive.
        CreateAndUpdateLocation(LocationGreen, true, true, false, false, false);  // With Required Receive and Require Put Away.
        CreateAndUpdateLocation(LocationOrange, true, true, true, true, true);  // With Bin Mandatory and Required: Receive, Put Away, Pick, Shipment.
        LibraryWarehouse.CreateInTransitLocation(LocationIntransit);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationBlack.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationYellow.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationBlue.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationRed.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationGreen.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationOrange.Code, false);
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate2: Record "Item Journal Template"; var ItemJournalBatch2: Record "Item Journal Batch"; ItemJournalTemplateType: Enum "Item Journal Template Type")
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate2, ItemJournalTemplateType);
        ItemJournalTemplate2.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalTemplate2.Modify(true);

        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch2, ItemJournalTemplate2.Type, ItemJournalTemplate2.Name);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch2, '');
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
        LibrarySales.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
    end;

    local procedure CalculateAndPostConsumptionJournal(ProductionOrderNo: Code[20])
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalBatch."Journal Template Name", ConsumptionItemJournalBatch.Name);
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalBatch."Journal Template Name", ConsumptionItemJournalBatch.Name);
    end;

    local procedure CalculateInventoryOnPhysicalInventoryJournal(var ItemJournalLine: Record "Item Journal Line"; Item: Record Item; LocationCode: Code[10])
    begin
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", PhysicalInventoryItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", PhysicalInventoryItemJournalBatch.Name);
        ItemJournalLine."Document No." := LibraryUtility.GenerateGUID();
        Item.SetRange("No.", Item."No.");
        Item.SetRange("Location Filter", LocationCode);
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), true, false); // Item Not On Inventory as True.
    end;

    local procedure ChangeUnitOfMeasureOnPick(No: Code[20])
    var
        WarehousePick: TestPage "Warehouse Pick";
    begin
        WarehousePick.OpenEdit();
        WarehousePick.FILTER.SetFilter("No.", No);
        WarehousePick.WhseActivityLines.Last();  // Leave Break Bulk Lines.
        WarehousePick.WhseActivityLines.ChangeUnitOfMeasure.Invoke();  // Use for error message.
    end;

    local procedure ChangeUnitOfMeasureOnPutAway(No: Code[20])
    var
        WarehousePutAway: TestPage "Warehouse Put-away";
    begin
        WarehousePutAway.OpenEdit();
        WarehousePutAway.FILTER.SetFilter("No.", No);
        WarehousePutAway.WhseActivityLines.ChangeUnitOfMeasure.Invoke();  // Use for error message.
    end;

    local procedure ChangeUnitOfMeasureOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        LibraryVariableStorage.Enqueue(UnitOfMeasureCode);  // Enqueue for WarehouseChangeUnitOfMeasurePageHandler.
        LibraryWarehouse.ChangeUnitOfMeasure(WarehouseActivityLine);
    end;

    local procedure CreateItemMakePositiveAdjustAndReleaseTransfer(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; PostShip: Boolean)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        TransferLine: Record "Transfer Line";
        Quantity: Decimal;
    begin
        LibraryInventory.CreateItem(Item);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity, LocationBlue.Code, '');
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, FromLocationCode, ToLocationCode, Item."No.", Quantity);
        if PostShip then
            LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMLine: Record "Production BOM Line"; ParentItem: Record Item; ComponentItemNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItemNo, LibraryRandom.RandInt(5));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; BinCode: Code[20])
    var
        LotNo: Code[50];
        AssignExpDate: Boolean;
    begin
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, '');
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if LibraryVariableStorage.Length() > 0 then begin
            AssignExpDate := (LibraryVariableStorage.PeekInteger(1) = ItemTrackingMode::"Assign Lot No. & Expiration Date");
            ItemJournalLine.OpenItemTrackingLines(false);  // Use from Item Journal.
            if AssignExpDate then begin
                Evaluate(LotNo, LibraryVariableStorage.PeekText(2));
                SetExpirationDateReservationEntry(ItemNo, LotNo);
            end;
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostItemJournalLineWithNewBinUsingItemTracking(var Bin: Record Bin; var LotNo: Code[50]; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        CreateAndPostItemJournalLine(
          ItemJournalLine, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity, Bin."Location Code", Bin.Code);
        GetLotNoFromItemTrackingLinesPageHandler(LotNo);
    end;

    local procedure CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader: Record "Purchase Header"; Tracking: Boolean)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        ItemTrackingMode: Option " ","Assign Lot No.","Assign Multiple Lot No.","Select Entries";
    begin
        CreateWarehouseReceipt(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        if Tracking then begin
            LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Multiple Lot No.");  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
            WarehouseReceiptLine.OpenItemTrackingLines();
        end;
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
    end;

    local procedure SumQtyOnItemLedgerEntries(ItemNo: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetFilter("Item No.", ItemNo);
        ItemLedgerEntry.CalcSums(Quantity);
        exit(ItemLedgerEntry.Quantity);
    end;

    local procedure SumQtyOnWhseEntries(ItemNo: Code[20]): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.SetFilter("Item No.", ItemNo);
        WhseEntry.CalcSums(Quantity);
        exit(WhseEntry.Quantity);
    end;

    local procedure CreateAndPostWarehouseReceiptFromSalesReturnOrder(SalesHeader: Record "Sales Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromSalesReturnOrder(SalesHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Sales Return Order", SalesHeader."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
    end;

    local procedure CreateAndRegisterMovement(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ItemNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateMovement(WhseWorksheetLine, ItemNo);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::Movement);
    end;

    local procedure CreateAndRegisterMovementAfterGetBinContentOnMovementWorksheet(Bin: Record Bin; ItemNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        GetBinContentOnMovementWorksheet(WhseWorksheetLine, Bin."Location Code", ItemNo);
        CreateMovement(WhseWorksheetLine, ItemNo);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        UpdateBinOnWarehouseActivityLine(
          WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::Movement,
          WarehouseActivityLine."Action Type"::Place);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", '', WarehouseActivityLine."Activity Type"::Movement);
    end;

    local procedure CreateAndRegisterPickFromWarehouseShipmentUsingPurchaseReturnOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseReturnOrder(PurchaseHeader, ItemNo, LocationCode, Quantity);
        CreateAndReleaseWarehouseShipmentFromPurchaseReturnOrder(WarehouseShipmentHeader, PurchaseHeader);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPickFromWarehouseShipmentUsingSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, '', Quantity, WorkDate(), false, false);  // Value required for test.
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPickFromWarehouseShipmentUsingTransferOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var TransferHeader: Record "Transfer Header"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleaseTransferOrder(TransferHeader, TransferLine, FromLocationCode, ToLocationCode, ItemNo, Quantity);
        CreatePickFromWarehouseShipment(WarehouseShipmentHeader, TransferHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Outbound Transfer", TransferHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure CreateAndRegisterPutAwayFromWarehouseReceiptUsingPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, '', '', LocationCode, '', Quantity, WorkDate(), false);  // Tracking as False.
        CreateAndPostWarehouseReceiptFromPurchaseOrder(PurchaseHeader, false);  // Tracking as False.
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndRegisterPutAwayFromWarehouseReceiptUsingSalesReturnOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleaseSalesReturnOrder(SalesHeader, ItemNo, LocationCode, LibraryRandom.RandDec(100, 2));
        CreateAndPostWarehouseReceiptFromSalesReturnOrder(SalesHeader);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Return Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateAndRegisterWarehouseJournalLine(EntryType: Option; Bin: Record Bin; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.WarehouseJournalSetup(Bin."Location Code", WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", '', EntryType, ItemNo, Quantity);
        WarehouseJournalLine.Validate("Variant Code", VariantCode);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Validate("Bin Code", Bin.Code);
        WarehouseJournalLine.Modify(true);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code", true);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ItemNo2: Code[20]; JobNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date; Tracking: Boolean)
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, ItemNo, LocationCode, Quantity);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Validate("Job No.", JobNo);
        if BinCode <> '' then
            PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
        if Tracking then
            PurchaseLine.OpenItemTrackingLines();
        if ItemNo2 <> '' then
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleasePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal; ShipmentDate: Date; Reserve: Boolean; Tracking: Boolean)
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, ItemNo, LocationCode, Quantity);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        if BinCode <> '' then
            SalesLine.Validate("Bin Code", BinCode);
        SalesLine.Modify(true);
        if Reserve then
            SalesLine.ShowReservation();
        if Tracking then
            SalesLine.OpenItemTrackingLines();
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseSalesReturnOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", ItemNo, LocationCode, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseTransferOrder(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Qty. to Ship", Quantity);
        TransferLine.Modify(true);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromPurchaseReturnOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; PurchaseHeader: Record "Purchase Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        FindWarehouseShipmentLine(
          WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Purchase Return Order", PurchaseHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateWarehouseShipment(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipmentFromTransferOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferHeader: Record "Transfer Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateWarehouseShipment(TransferHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Outbound Transfer", TransferHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateAndRefreshFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequireReceive: Boolean; RequirePutAway: Boolean; RequireShipment: Boolean; RequirePick: Boolean; BinMandatory: Boolean)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Receive", RequireReceive);
        Location.Validate("Require Put-away", RequirePutAway);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Validate("Require Pick", RequirePick);
        Location."Bin Mandatory" := BinMandatory;
        Location.Modify(true);
    end;

    local procedure CreateLocationWithBulkReceiveShipmentBins(var Location: Record Location)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        CreateAndUpdateLocation(Location, true, true, true, true, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 3, false);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 1);
        Location.Validate("Receipt Bin Code", Bin.Code);
        LibraryWarehouse.FindBin(Bin, Location.Code, '', 2);
        Location.Validate("Shipment Bin Code", Bin.Code);
        Location.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateBaseCalendarWithBaseCalendarChange(var BaseCalendar: Record "Base Calendar")
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        LibraryService.CreateBaseCalendar(BaseCalendar);
        LibraryInventory.CreateBaseCalendarChange(
          BaseCalendarChange, BaseCalendar.Code, BaseCalendarChange."Recurring System"::"Weekly Recurring", 0D,
          BaseCalendarChange.Day::Sunday);  // Use 0D for Date.
    end;

    local procedure CreateBinWithWarehouseClassCode(var Bin: Record Bin; LocationCode: Code[10]; ZoneCode: Code[10]; BinTypeCode: Code[10]; WarehouseClassCode: Code[10])
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), ZoneCode, BinTypeCode);
        Bin.Validate("Warehouse Class Code", WarehouseClassCode);
        Bin.Modify(true);
    end;

    local procedure CreateBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; Item: Record Item)
    begin
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreateCustomerWithShippingAgentAndBaseCalendar(var Customer: Record Customer; ShippingAgentServices: Record "Shipping Agent Services"; BaseCalendarCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Agent Code", ShippingAgentServices."Shipping Agent Code");
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        Customer.Validate("Base Calendar Code", BaseCalendarCode);
        Customer.Modify(true);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Serial: Boolean; Lot: Boolean; StrictExpirationPosting: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Validate("Use Expiration Dates", StrictExpirationPosting);
        ItemTrackingCode.Validate("Man. Expir. Date Entry Reqd.", StrictExpirationPosting);
        ItemTrackingCode.Validate("Strict Expiration Posting", StrictExpirationPosting);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemTrackingCodeWithLotInformation(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        CreateItemTrackingCode(ItemTrackingCode, false, true, false);  // Lot Item Tracking.
        ItemTrackingCode.Validate("Lot Info. Inbound Must Exist", true);
        ItemTrackingCode.Validate("Lot Info. Outbound Must Exist", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemTrackingLine(var ItemTrackingLines: TestPage "Item Tracking Lines"; Quantity: Decimal)
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(Quantity);
        LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Enqueue Lot No.
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(5) + 1);
    end;

    local procedure CreateItemWithFlushingMethod(var Item: Record Item; FlushingMethod: Enum "Flushing Method")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure CreateItemWithProductionBOM(var ParentItem: Record Item; var ProductionBOMLine: Record "Production BOM Line"; FlushingMethod: Enum "Flushing Method")
    var
        ComponentItem: Record Item;
    begin
        LibraryInventory.CreateItem(ParentItem);
        CreateItemWithFlushingMethod(ComponentItem, FlushingMethod);
        CreateAndCertifyProductionBOM(ProductionBOMLine, ParentItem, ComponentItem."No.");
        ParentItem.Validate("Production BOM No.", ProductionBOMLine."Production BOM No.");
        ParentItem.Modify(true);
    end;

    local procedure CreateItemWithWarehouseClass(var WarehouseClass: Record "Warehouse Class"; var Item: Record Item)
    begin
        LibraryWarehouse.CreateWarehouseClass(WarehouseClass);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Warehouse Class Code", WarehouseClass.Code);
        Item.Modify(true);
    end;

    local procedure CreateMovement(var WhseWorksheetLine: Record "Whse. Worksheet Line"; ItemNo: Code[20])
    begin
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
        LibraryWarehouse.WhseSourceCreateDocument(WhseWorksheetLine, "Whse. Activity Sorting Method"::None, false, false, false);
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePickForOutboundTransfer(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SourceNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Outbound Transfer", SourceNo);
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure CreatePickFromPickWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; WarehouseDocumentNo: Code[20]; ItemNo: Code[20])
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, WarehouseDocumentNo, ItemNo);

        // Taking 0 for MaxNoOfLines, MaxNoOfSourceDoc and SortPick.
        LibraryWarehouse.CreatePickFromPickWorksheet(
          WhseWorksheetLine, WhseWorksheetLine."Line No.", WhseWorksheetName."Worksheet Template Name", WhseWorksheetName.Name,
          WhseWorksheetName."Location Code", '', 0, 0, "Whse. Activity Sorting Method"::None, false, false, false, false, false, false, false);
    end;

    local procedure CreatePickFromWarehouseInternalPick(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; Bin: Record Bin; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        CreateWarehouseInternalPickHeader(WhseInternalPickHeader, Bin);
        CreateWarehouseInternalPickLine(WhseInternalPickLine, WhseInternalPickHeader, ItemNo, VariantCode, Quantity);
        LibraryWarehouse.ReleaseWarehouseInternalPick(WhseInternalPickHeader);
        WhseInternalPickLine.SetHideValidationDialog(true);
        WhseInternalPickLine.CreatePickDoc(WhseInternalPickLine, WhseInternalPickHeader);
    end;

    local procedure CreatePickFromWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    begin
        CreateWarehouseShipment(SalesHeader);
        CreatePick(WarehouseShipmentHeader, SalesHeader."No.");
    end;

    local procedure CreatePickFromWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferHeader: Record "Transfer Header")
    begin
        CreateWarehouseShipment(TransferHeader);
        CreatePickForOutboundTransfer(WarehouseShipmentHeader, TransferHeader."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; JobNo: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Job No.", JobNo);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; JobNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, ItemNo, LocationCode, JobNo);
    end;

    local procedure CreateShippingAgentWithShippingAgentService(var ShippingAgentServices: Record "Shipping Agent Services"; BaseCalendarCode: Code[10])
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingTime: DateFormula;
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);
        ShippingAgentServices.Validate("Base Calendar Code", BaseCalendarCode);
        ShippingAgentServices.Modify(true);
    end;

    local procedure CreateWarehouseInternalPickHeader(var WhseInternalPickHeader: Record "Whse. Internal Pick Header"; Bin: Record Bin)
    begin
        LibraryWarehouse.CreateWhseInternalPickHeader(WhseInternalPickHeader, Bin."Location Code");
        WhseInternalPickHeader.Validate("To Zone Code", Bin."Zone Code");
        WhseInternalPickHeader.Validate("To Bin Code", Bin.Code);
        WhseInternalPickHeader.Modify(true);
    end;

    local procedure CreateWarehouseInternalPickLine(var WhseInternalPickLine: Record "Whse. Internal Pick Line"; WhseInternalPickHeader: Record "Whse. Internal Pick Header"; ItemNo: Code[20]; VariantCode: Code[10]; Quantity: Decimal)
    begin
        LibraryWarehouse.CreateWhseInternalPickLine(WhseInternalPickHeader, WhseInternalPickLine, ItemNo, Quantity);
        WhseInternalPickLine.Validate("Variant Code", VariantCode);
        WhseInternalPickLine.Modify(true);
    end;

    local procedure CreateWarehouseReceipt(PurchaseHeader: Record "Purchase Header")
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
    end;

    local procedure CreateWarehouseReceiptAndCalculateCrossDockWithItemTracking(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseHeader: Record "Purchase Header"; ItemTrackingMode: Option)
    var
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
    begin
        CreateWarehouseReceipt(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        LibraryWarehouse.CalculateCrossDockLines(
          WhseCrossDockOpportunity, '', WarehouseReceiptLine."No.", WarehouseReceiptLine."Location Code");
        LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        WarehouseReceiptLine.OpenItemTrackingLines();
    end;

    local procedure CreateWarehouseReceiptHeaderWithLocation(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseReceiptHeader(WarehouseReceiptHeader);
        WarehouseReceiptHeader.Validate("Location Code", LocationCode);
        WarehouseReceiptHeader.Modify(true);
    end;

    local procedure CreateWarehouseReceiptWithGetSourceDocument(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; LocationCode: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseReceiptHeaderWithLocation(WarehouseReceiptHeader, LocationCode);
        LibraryWarehouse.GetSourceDocumentsReceipt(WarehouseReceiptHeader, WarehouseSourceFilter, LocationCode);
    end;

    local procedure CreateWarehouseShipment(SalesHeader: Record "Sales Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
    end;

    local procedure CreateWarehouseShipment(TransferHeader: Record "Transfer Header")
    begin
        LibraryWarehouse.CreateWhseShipmentFromTO(TransferHeader);
    end;

    local procedure CreateWarehouseShipmentHeaderWithLocation(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    begin
        LibraryWarehouse.CreateWarehouseShipmentHeader(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Validate("Location Code", LocationCode);
        WarehouseShipmentHeader.Modify(true);
    end;

    local procedure CreateWarehouseShipmentWithGetSourceDocument(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; LocationCode: Code[10])
    var
        WarehouseSourceFilter: Record "Warehouse Source Filter";
    begin
        CreateWarehouseShipmentHeaderWithLocation(WarehouseShipmentHeader, LocationCode);
        LibraryWarehouse.GetSourceDocumentsShipment(WarehouseShipmentHeader, WarehouseSourceFilter, LocationCode);
    end;

    local procedure CreateZoneAndBin(var Bin: Record Bin; LocationCode: Code[10]; WarehouseClassCode: Code[10]; Receive: Boolean; Ship: Boolean; PutAway: Boolean; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        LibraryWarehouse.CreateZone(
          Zone,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Zone.FieldNo(Code), DATABASE::Zone), 1,
            LibraryUtility.GetFieldLength(DATABASE::Zone, Zone.FieldNo(Code))),
          LocationCode, LibraryWarehouse.SelectBinType(Receive, Ship, PutAway, Pick), WarehouseClassCode, '', 0, false);  // Use 0 for Zone Rank.
        CreateBinWithWarehouseClassCode(Bin, Zone."Location Code", Zone.Code, Zone."Bin Type Code", WarehouseClassCode);
    end;

    local procedure MockWarehouseActivityLineAndBin(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Bin: Record Bin)
    begin
        Bin.Code := LibraryUtility.GenerateGUID();
        Bin."Location Code" := LibraryUtility.GenerateGUID();
        Bin.Insert();

        WarehouseActivityLine."No." := LibraryUtility.GenerateGUID();
        WarehouseActivityLine."Bin Code" := Bin.Code;
        WarehouseActivityLine."Location Code" := Bin."Location Code";
        WarehouseActivityLine.Insert();
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

    local procedure GetBinContentOnMovementWorksheet(var WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhseWorksheetName: Record "Whse. Worksheet Name";
        BinContent: Record "Bin Content";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Movement);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhseWorksheetLine.Init();
        WhseWorksheetLine.Validate("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.Validate(Name, WhseWorksheetName.Name);
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        WhseInternalPutAwayHeader.Init();
        LibraryWarehouse.WhseGetBinContent(
            BinContent, WhseWorksheetLine, WhseInternalPutAwayHeader, "Warehouse Destination Type 2"::MovementWorksheet);
    end;

    local procedure GetLotNoFromItemTrackingLinesPageHandler(var LotNo: Code[50])
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
    end;

    local procedure FilterPostedWarehouseReceiptLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20])
    begin
        PostedWhseReceiptLine.SetRange("Source Document", SourceDocument);
        PostedWhseReceiptLine.SetRange("Source No.", SourceNo);
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
    end;

    local procedure FilterWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ActionType: Enum "Warehouse Action Type"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20])
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Zone Code", ZoneCode);
        WarehouseActivityLine.SetRange("Bin Code", BinCode);
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode);
        Bin.SetRange("Location Code", Zone."Location Code");
        Bin.SetRange("Zone Code", Zone.Code);
        LibraryWarehouse.FindBin(Bin, Zone."Location Code", Zone.Code, LibraryRandom.RandInt(Bin.Count));  // Find Random Bin.
    end;

    local procedure FindBinContent(var BinContent: Record "Bin Content"; Bin: Record Bin; ItemNo: Code[20])
    begin
        BinContent.SetRange("Location Code", Bin."Location Code");
        BinContent.SetRange("Zone Code", Bin."Zone Code");
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.SetRange("Item No.", ItemNo);
    end;

    local procedure FindCrossDockWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; Location: Record Location; SourceDocument: Enum "Warehouse Journal Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50])
    var
        Bin: Record Bin;
    begin
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        WarehouseEntry.SetRange("Source Document", SourceDocument);
        WarehouseEntry.SetRange("Source No.", SourceNo);
        FindWarehouseEntry(WarehouseEntry, WarehouseEntry."Entry Type"::Movement, Bin, ItemNo, LotNo);
    end;

    local procedure FindRegisteredWarehouseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; ActivityType: Enum "Warehouse Activity Type"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActionType: Enum "Warehouse Action Type"; LocationCode: Code[10]; ItemNo: Code[20])
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", ActivityType);
        RegisteredWhseActivityLine.SetRange("Source Document", SourceDocument);
        RegisteredWhseActivityLine.SetRange("Source No.", SourceNo);
        RegisteredWhseActivityLine.SetRange("Action Type", ActionType);
        RegisteredWhseActivityLine.SetRange("Location Code", LocationCode);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; Bin: Record Bin; ItemNo: Code[20]; LotNo: Code[50])
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Location Code", Bin."Location Code");
        WarehouseEntry.SetRange("Zone Code", Bin."Zone Code");
        WarehouseEntry.SetRange("Bin Code", Bin.Code);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindWarehouseWorksheetLine(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WhseWorksheetName: Record "Whse. Worksheet Name"; WarehouseDocumentNo: Code[20]; ItemNo: Code[20])
    begin
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetName."Worksheet Template Name");
        WhseWorksheetLine.SetRange(Name, WhseWorksheetName.Name);
        WhseWorksheetLine.SetRange("Location Code", WhseWorksheetName."Location Code");
        if WarehouseDocumentNo <> '' then begin
            WhseWorksheetLine.SetRange("Whse. Document Type", WhseWorksheetLine."Whse. Document Type"::Shipment);
            WhseWorksheetLine.SetRange("Whse. Document No.", WarehouseDocumentNo);
        end;
        WhseWorksheetLine.SetRange("Item No.", ItemNo);
        WhseWorksheetLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Warehouse Class Code", '');
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));  // Find PICK Zone.
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure GetWarehouseDocumentOnPickWorksheet(var WhseWorksheetName: Record "Whse. Worksheet Name"; LocationCode: Code[10])
    var
        WhseWorksheetTemplate: Record "Whse. Worksheet Template";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        LibraryWarehouse.SelectWhseWorksheetTemplate(WhseWorksheetTemplate, WhseWorksheetTemplate.Type::Pick);
        LibraryWarehouse.SelectWhseWorksheetName(WhseWorksheetName, WhseWorksheetTemplate.Name, LocationCode);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        LibraryWarehouse.GetOutboundSourceDocuments(WhsePickRequest, WhseWorksheetName, LocationCode);
    end;

    local procedure PostOutputJournalAfterExplodeRouting(ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(OutputItemJournalTemplate, OutputItemJournalBatch);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, OutputItemJournalTemplate, OutputItemJournalBatch, '', ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(OutputItemJournalBatch."Journal Template Name", OutputItemJournalBatch.Name);
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(WarehouseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure RegisterPickAfterPostWarehouseShipmentWithUpdateBinUsingSalesOrder(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; Bin: Record Bin; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, ItemNo, LocationCode, '', Quantity, WorkDate(), false, false);  // Reserve as False and Tracking as False.
        CreateWarehouseShipment(SalesHeader);
        UpdateBinOnWarehouseShipmentLine(WarehouseShipmentLine, Bin, SalesHeader."No.");
        CreatePick(WarehouseShipmentHeader, SalesHeader."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SalesHeader."No.",
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure RegisterPutAwayAfterPostWarehouseReceiptWithUpdateBinUsingPurchaseOrder(Bin: Record Bin; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, ItemNo, '', '', LocationCode, '', Quantity, WorkDate(), false);  // Tracking as False.
        CreateWarehouseReceipt(PurchaseHeader);
        UpdateBinOnWarehouseReceiptLine(WarehouseReceiptLine, Bin, PurchaseHeader."No.");
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure RegisterWarehouseActivity(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure ReopenAndDeleteWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseShipmentHeader.Find();
        LibraryWarehouse.ReopenWhseShipment(WarehouseShipmentHeader);
        WarehouseShipmentHeader.Find();
        WarehouseShipmentHeader.Delete(true);
    end;

    local procedure ReserveProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order")
    var
        ReservationMode: Option "Reserve From Current Line","Reserve From First Line","Verify Reserve Line";
    begin
        LibraryVariableStorage.Enqueue(ReservationMode::"Reserve From Current Line");
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.ShowReservation();
    end;

    local procedure UndoPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.FindFirst();
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UndoReturnReceiptLine(var ReturnReceiptLine: Record "Return Receipt Line"; ReturnOrderNo: Code[20])
    begin
        ReturnReceiptLine.SetRange("Return Order No.", ReturnOrderNo);
        ReturnReceiptLine.FindFirst();
        LibrarySales.UndoReturnReceiptLine(ReturnReceiptLine);
    end;

    local procedure UndoReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ReturnOrderNo: Code[20])
    begin
        ReturnShipmentLine.SetRange("Return Order No.", ReturnOrderNo);
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
    end;

    local procedure UndoSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure UpdateAlwaysCreatePickLineOnLocation(var Location: Record Location; var OldAlwaysCreatePickLine: Boolean; NewAlwaysCreatePickLine: Boolean)
    begin
        OldAlwaysCreatePickLine := Location."Always Create Pick Line";
        Location.Validate("Always Create Pick Line", NewAlwaysCreatePickLine);
        Location.Modify(true);
    end;

    local procedure UpdateBinOnPutAwayAndRegisterPutAway(var Bin: Record Bin; LocationCode: Code[10]; SourceNo: Code[20])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindBin(Bin, LocationCode);
        UpdateBinOnWarehouseActivityLine(
          WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away", WarehouseActivityLine."Action Type"::Place);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Purchase Order", SourceNo,
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure UpdateBinOnWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; Bin: Record Bin; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(WarehouseActivityLine, SourceDocument, SourceNo, ActivityType);
        WarehouseActivityLine.ModifyAll("Zone Code", Bin."Zone Code", true);
        WarehouseActivityLine.ModifyAll("Bin Code", Bin.Code, true);
    end;

    local procedure UpdateBinOnWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; Bin: Record Bin; SourceNo: Code[20])
    begin
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", SourceNo);
        WarehouseReceiptLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseReceiptLine.Validate("Bin Code", Bin.Code);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateBinOnWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; Bin: Record Bin; SourceNo: Code[20])
    begin
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SourceNo);
        WarehouseShipmentLine.Validate("Zone Code", Bin."Zone Code");
        WarehouseShipmentLine.Validate("Bin Code", Bin.Code);
        WarehouseShipmentLine.Modify(true);
    end;

    local procedure UpdateBinQuantityToHandleAndLotNoOnPickAndRegisterPick(Bin: Record Bin; SourceNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        UpdateBinOnWarehouseActivityLine(
          WarehouseActivityLine, Bin, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Action Type"::Take);
        UpdateQuantityToHandleAndLotNoOnPickLines(WarehouseActivityLine."Activity Type"::Pick, SourceNo, Quantity, LotNo);
        RegisterWarehouseActivity(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure UpdateExpirationDateReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Expiration Date", CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'Y>', WorkDate()), true);
    end;

    local procedure SetExpirationDateReservationEntry(ItemNo: Code[20]; LotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.ModifyAll("Expiration Date", LibraryVariableStorage.DequeueDate(), true);
    end;

    local procedure UpdateInventoryUsingWarehouseJournal(Bin: Record Bin; Item: Record Item; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        CreateAndRegisterWarehouseJournalLine(
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Bin, Item."No.", VariantCode, UnitOfMeasureCode, Quantity);
        UpdateNoSeriesOnItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemTrackingOnTransferLine(var TransferLine: Record "Transfer Line"; ItemTrackingMode: Option; Direction: Enum "Transfer Direction")
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode);  // Enqueue ItemTrackingMode for ItemTrackingLinesPageHandler.
        TransferLine.OpenItemTrackingLines(Direction);
    end;

    local procedure UpdateNoSeriesOnItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure UpdateOutboundWarehouseHandlingTimeAndBaseCalendarOnLocation(var Location: Record Location; BaseCalendarCode: Code[10])
    var
        OutboundWhseHandlingTime: DateFormula;
    begin
        Evaluate(OutboundWhseHandlingTime, '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        Location.Validate("Outbound Whse. Handling Time", OutboundWhseHandlingTime);
        Location.Validate("Base Calendar Code", BaseCalendarCode);
        Location.Modify(true);
    end;

    local procedure UpdatePickAccordingToFEFOOnLocation(var Location: Record Location; NewPickAccordingToFEFO: Boolean) OldPickAccordingToFEFO: Boolean
    begin
        OldPickAccordingToFEFO := Location."Pick According to FEFO";
        Location.Validate("Pick According to FEFO", NewPickAccordingToFEFO);
        Location.Modify(true);
    end;

    local procedure UpdatePurchaseUnitOfMeasureOnItem(var Item: Record Item; PurchaseUnitOfMeasure: Code[10])
    begin
        Item.Validate("Purch. Unit of Measure", PurchaseUnitOfMeasure);
        Item.Modify(true);
    end;

    local procedure UpdateQuantityBaseOnReservationEntry(ItemNo: Code[20])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.ModifyAll("Quantity (Base)", ReservationEntry."Quantity (Base)" / 2, true);  // Reserve partial Quantity.
    end;

    local procedure UpdateQuantityOnSalesLineAndReserve(var SalesLine: Record "Sales Line"; Quantity: Decimal)
    begin
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Modify(true);
        SalesLine.ShowReservation();
    end;

    local procedure UpdateQuantityToHandleAndLotNoOnPickLines(ActivityType: Enum "Warehouse Activity Type"; SourceNo: Code[20]; QuantityToHandle: Decimal; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo, ActivityType);
        WarehouseActivityLine.FindSet();
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", QuantityToHandle);
            WarehouseActivityLine.Validate("Lot No.", LotNo);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;
    end;

    local procedure UpdateQuantityToHandleOnWarehouseWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; WarehouseDocumentNo: Code[20]; ItemNo: Code[20]; QuantityToHandle: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, WarehouseDocumentNo, ItemNo);
        WhseWorksheetLine.Validate("Qty. to Handle", QuantityToHandle);
        WhseWorksheetLine.Modify(true);
    end;

    local procedure UpdateReceiptPostingPolicyOnWarehouseSetup(var OldReceiptPostingPolicy: Integer; NewReceiptPostingPolicy: Integer)
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        WarehouseSetup.Get();
        OldReceiptPostingPolicy := WarehouseSetup."Receipt Posting Policy";
        WarehouseSetup.Validate("Receipt Posting Policy", NewReceiptPostingPolicy);
        WarehouseSetup.Modify(true);
    end;

    local procedure UpdateReserveOnItemAsAlways(var Item: Record Item)
    begin
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);
    end;

    local procedure UpdateRoutingLinkCodeOnProductionOrderComponent(var ProdOrderComponent: Record "Prod. Order Component")
    var
        RoutingLink: Record "Routing Link";
    begin
        RoutingLink.FindFirst();
        ProdOrderComponent.Validate("Routing Link Code", RoutingLink.Code);
        ProdOrderComponent.Modify(true);
    end;

    local procedure VerifyBinContent(Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", Bin."Location Code");
        BinContent.SetRange("Zone Code", Bin."Zone Code");
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.SetRange("Warehouse Class Code", Bin."Warehouse Class Code");
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        BinContent.CalcFields(Quantity);
        BinContent.TestField(Quantity, Quantity);
    end;

    local procedure VerifyCrossDockWarehouseEntry(SourceDocument: Enum "Warehouse Journal Source Document"; SourceNo: Code[20]; Location: Record Location; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FindCrossDockWarehouseEntry(WarehouseEntry, Location, SourceDocument, SourceNo, ItemNo, LotNo);
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyCrossDockWarehouseEntryWithSerialNo(SourceDocument: Enum "Warehouse Journal Source Document"; SourceNo: Code[20]; Location: Record Location; ItemNo: Code[20]; LotNo: Code[50]; TotalQuantity: Decimal; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
        Quantity2: Decimal;
    begin
        FindCrossDockWarehouseEntry(WarehouseEntry, Location, SourceDocument, SourceNo, ItemNo, LotNo);
        WarehouseEntry.FindSet();
        repeat
            WarehouseEntry.TestField("Serial No.");
            WarehouseEntry.TestField(Quantity, Quantity);
            Quantity2 += WarehouseEntry.Quantity;
        until WarehouseEntry.Next() = 0;
        Assert.AreEqual(TotalQuantity, Quantity2, QuantityMustBeSame);
    end;

    local procedure VerifyEmptyPostedWarehouseReceiptLine(SourceNo: Code[20]; ItemNo: Code[20])
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        FilterPostedWarehouseReceiptLine(
          PostedWhseReceiptLine, PostedWhseReceiptLine."Source Document"::"Inbound Transfer", SourceNo, ItemNo);
        Assert.IsTrue(PostedWhseReceiptLine.IsEmpty, StrSubstNo(MustBeEmpty, PostedWhseReceiptLine.TableCaption()));
    end;

    local procedure VerifyEmptyWarehouseEntry(ItemNo: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        Assert.IsTrue(WarehouseEntry.IsEmpty, StrSubstNo(MustBeEmpty, WarehouseEntry.TableCaption()));
    end;

    local procedure VerifyFinishedProductionOrderComponent(ProductionOrderNo: Code[20]; ItemNo: Code[20]; FlushingMethod: Enum "Flushing Method"; ExpectedQuantity: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderComponent.Status::Finished);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.SetRange("Flushing Method", FlushingMethod);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField("Expected Quantity", ExpectedQuantity);
        ProdOrderComponent.TestField("Remaining Quantity", 0);  // Use 0 for fully consumed.
    end;

    local procedure VerifyFinishedProductionOrderLine(ProductionOrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Finished);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        ProdOrderLine.TestField(Quantity, Quantity);
        ProdOrderLine.TestField("Finished Quantity", Quantity);
    end;

    local procedure VerifyItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal)
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Location Code", Bin."Location Code");
        ItemJournalLine.TestField("Bin Code", Bin.Code);
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Lot No.", LotNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyMovementLine(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LotNo: Code[50]; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FilterWarehouseActivityLine(WarehouseActivityLine, ActionType, ItemNo, UnitOfMeasureCode, LocationCode, ZoneCode, BinCode);
        WarehouseActivityLine.SetRange("Lot No.", LotNo);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", SourceNo, WarehouseActivityLine."Activity Type"::Movement);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPickLine(ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Quantity2: Decimal;
    begin
        WarehouseActivityLine.SetRange("Item No.", ItemNo);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo,
          WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.FindSet();
        repeat
            Quantity2 += WarehouseActivityLine.Quantity;
        until WarehouseActivityLine.Next() = 0;
        Assert.AreEqual(Quantity, Quantity2, QuantityMustBeSame);
    end;

    local procedure VerifyPickLineWithBin(Bin: Record Bin; ActionType: Enum "Warehouse Action Type"; SourceNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; Quantity: Decimal; MoveNext: Boolean)
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FilterWarehouseActivityLine(
          WarehouseActivityLine, ActionType, ItemNo, UnitOfMeasureCode, Bin."Location Code", Bin."Zone Code", Bin.Code);
        WarehouseActivityLine.SetRange("Variant Code", VariantCode);
        FindWarehouseActivityLine(
          WarehouseActivityLine, WarehouseActivityLine."Source Document"::" ", SourceNo, WarehouseActivityLine."Activity Type"::Pick);
        if MoveNext then
            WarehouseActivityLine.Next();
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedInventoryPickLines(Bin: Record Bin; SourceNo: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; Quantity: Decimal)
    var
        PostedInvtPickLine: Record "Posted Invt. Pick Line";
        Quantity2: Decimal;
    begin
        PostedInvtPickLine.SetRange("Source Document", PostedInvtPickLine."Source Document"::"Sales Order");
        PostedInvtPickLine.SetRange("Source No.", SourceNo);
        PostedInvtPickLine.SetRange("Location Code", Bin."Location Code");
        PostedInvtPickLine.SetRange("Bin Code", Bin.Code);
        PostedInvtPickLine.SetRange("Item No.", ItemNo);
        PostedInvtPickLine.SetRange("Lot No.", LotNo);
        PostedInvtPickLine.FindSet();
        repeat
            Quantity2 += PostedInvtPickLine.Quantity;
        until PostedInvtPickLine.Next() = 0;
        Assert.AreEqual(Quantity, Quantity2, QuantityMustBeSame);
    end;

    local procedure VerifyPostedWarehouseReceiptLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; MoveNext: Boolean)
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
    begin
        FilterPostedWarehouseReceiptLine(PostedWhseReceiptLine, SourceDocument, SourceNo, ItemNo);
        PostedWhseReceiptLine.FindSet();
        if MoveNext then
            PostedWhseReceiptLine.Next();
        PostedWhseReceiptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPostedWarehouseShipmentLine(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; MoveNext: Boolean)
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
    begin
        PostedWhseShipmentLine.SetRange("Source Document", SourceDocument);
        PostedWhseShipmentLine.SetRange("Source No.", SourceNo);
        PostedWhseShipmentLine.SetRange("Item No.", ItemNo);
        PostedWhseShipmentLine.FindSet();
        if MoveNext then
            PostedWhseShipmentLine.Next();
        PostedWhseShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; MoveNext: Boolean)
    begin
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.SetRange("Location Code", LocationCode);
        PurchRcptLine.FindSet();
        if MoveNext then
            PurchRcptLine.Next();
        PurchRcptLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRegisteredPickLine(ActionType: Enum "Warehouse Action Type"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; Bin: Record Bin; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; LotNo: Code[50]; Quantity: Decimal; MoveNext: Boolean)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Bin Code", Bin.Code);
        RegisteredWhseActivityLine.SetRange("Zone Code", Bin."Zone Code");
        RegisteredWhseActivityLine.SetRange("Lot No.", LotNo);
        RegisteredWhseActivityLine.SetRange("Variant Code", VariantCode);
        RegisteredWhseActivityLine.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        FindRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Activity Type"::Pick, SourceDocument, SourceNo, ActionType,
          Bin."Location Code", ItemNo);
        if MoveNext then
            RegisteredWhseActivityLine.Next();
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyRegisteredWarehouseActivityLine(ActivityType: Enum "Warehouse Activity Type"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        FindRegisteredWarehouseActivityLine(
          RegisteredWhseActivityLine, ActivityType, SourceDocument, SourceNo, RegisteredWhseActivityLine."Action Type"::" ", LocationCode,
          ItemNo);
        RegisteredWhseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; SourceType: Integer; SourceID: Code[20]; Quantity: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; MoveNext: Boolean)
    begin
        ReturnShipmentLine.SetRange("No.", ItemNo);
        ReturnShipmentLine.SetRange("Location Code", LocationCode);
        ReturnShipmentLine.FindSet();
        if MoveNext then
            ReturnShipmentLine.Next();
        ReturnShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesLine(var SalesLine: Record "Sales Line"; ShippingAgentServices: Record "Shipping Agent Services"; OutboundWhseHandlingTime: DateFormula)
    var
        CustomizedCalendarChange: array[2] of Record "Customized Calendar Change";
        PlannedDeliveryDate: Date;
        PlannedShipmentDate: Date;
    begin
        CustomizedCalendarChange[1].SetSource(CustomizedCalendarChange[1]."Source Type"::Location, SalesLine."Location Code", '', '');
        CustomizedCalendarChange[2].SetSource(
            CustomizedCalendarChange[2]."Source Type"::"Shipping Agent", ShippingAgentServices."Shipping Agent Code", ShippingAgentServices.Code, '');
        PlannedShipmentDate := LibraryWarehouse.CalculatePlannedDate(Format(OutboundWhseHandlingTime), WorkDate(), CustomizedCalendarChange, true);

        CustomizedCalendarChange[1].SetSource(
            CustomizedCalendarChange[1]."Source Type"::"Shipping Agent", ShippingAgentServices."Shipping Agent Code", ShippingAgentServices.Code, '');
        CustomizedCalendarChange[2].SetSource(CustomizedCalendarChange[2]."Source Type"::Customer, SalesLine."Sell-to Customer No.", '', '');
        PlannedDeliveryDate :=
            LibraryWarehouse.CalculatePlannedDate(
                Format(ShippingAgentServices."Shipping Time"), PlannedShipmentDate, CustomizedCalendarChange, true);  // 0D required for test.

        SalesLine.TestField("Outbound Whse. Handling Time", OutboundWhseHandlingTime);
        SalesLine.TestField("Shipping Time", ShippingAgentServices."Shipping Time");
        SalesLine.TestField("Shipment Date", WorkDate());
        SalesLine.TestField("Planned Shipment Date", PlannedShipmentDate);
        SalesLine.TestField("Planned Delivery Date", PlannedDeliveryDate);
    end;

    local procedure VerifySalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; MoveNext: Boolean)
    begin
        SalesShipmentLine.SetRange("No.", ItemNo);
        SalesShipmentLine.SetRange("Location Code", LocationCode);
        SalesShipmentLine.FindSet();
        if MoveNext then
            SalesShipmentLine.Next();
        SalesShipmentLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseEntry(EntryType: Option; Bin: Record Bin; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; LotNo: Code[50]; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        FindWarehouseEntry(WarehouseEntry, EntryType, Bin, ItemNo, LotNo);
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    begin
        WarehouseActivityLine.Find();
        WarehouseActivityLine.TestField("Item No.", ItemNo);
        WarehouseActivityLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseActivityLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseWorksheetLine(WhseWorksheetName: Record "Whse. Worksheet Name"; WarehouseDocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; QuantityToHandle: Decimal; AvailableQuantityToPick: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        FindWarehouseWorksheetLine(WhseWorksheetLine, WhseWorksheetName, WarehouseDocumentNo, ItemNo);
        WhseWorksheetLine.TestField(Quantity, Quantity);
        WhseWorksheetLine.TestField("Qty. to Handle", QuantityToHandle);
        Assert.AreEqual(AvailableQuantityToPick, WhseWorksheetLine.AvailableQtyToPick(), QuantityMustBeSame);
    end;

    local procedure VerifyWhseShipmentLineExist(HeaderNo: Code[20]; SourceDocNo: Code[20]; Exist: Boolean)
    var
        WhseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WhseShipmentLine.SetRange("No.", HeaderNo);
        WhseShipmentLine.SetRange("Source No.", SourceDocNo);
        Assert.AreEqual(Exist, not WhseShipmentLine.IsEmpty, StrSubstNo(CheckShipmentLineErr, SourceDocNo, Format(Exist)));
    end;

    local procedure VerifyWhseReceiptLineExist(HeaderNo: Code[20]; SourceDocNo: Code[20]; Exist: Boolean)
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
    begin
        WhseReceiptLine.SetRange("No.", HeaderNo);
        WhseReceiptLine.SetRange("Source No.", SourceDocNo);
        Assert.AreEqual(Exist, not WhseReceiptLine.IsEmpty, StrSubstNo(CheckReceiptLineErr, SourceDocNo, Format(Exist)));
    end;

    local procedure GenerateFourLot(var LotNo: array[4] of Code[50])
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(LotNo) do
            LotNo[i] := LibraryUtility.GenerateGUID();
    end;

    local procedure CreateItemJournalWithItemTrackingAndPost(
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
        UOM: Code[20];
        ItemNo: Code[20];
        LotNo: array[4] of Code[50])
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationBlue.Code, '', Quantity);
        ItemJournalLine.Validate("Unit of Measure Code", UOM);
        ItemJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Manual Lot Nos");
        LibraryVariableStorage.Enqueue(4);
        LibraryVariableStorage.Enqueue(LotNo[1]);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(1900, 1900));

        LibraryVariableStorage.Enqueue(LotNo[2]);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(300, 300));

        LibraryVariableStorage.Enqueue(LotNo[3]);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(200, 200));

        LibraryVariableStorage.Enqueue(LotNo[4]);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandIntInRange(100, 100));

        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateTransferOrderLineWithItemTracking(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; FromLocationCode: Code[10]; ToLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal; ChangeUOM: Code[20])
    begin
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, ToLocationCode, LocationIntransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        TransferLine.Validate("Qty. to Ship", Quantity);
        TransferLine.Validate("Unit of Measure Code", ChangeUOM);
        TransferLine.Modify(true);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Select Entries");
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Outbound);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
    end;

    local procedure VerifyTrackingOnTransferLineReceiptAfterUndo(TransferLine: Record "Transfer Line"; TrackingQtyToHandle: Decimal; TrackingQty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Show Entries");
        LibraryVariableStorage.Enqueue(TrackingQtyToHandle);
        LibraryVariableStorage.Enqueue(TrackingQty);
        TransferLine.OpenItemTrackingLines("Transfer Direction"::Inbound);
    end;

    local procedure UpdateQuantityToHandleAndLotNoOnPickAndRegisterPick(SourceNo: Code[20]; Quantity: Decimal; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        UpdateQuantityToHandleAndLotNoOnPickLines(WarehouseActivityLine."Activity Type"::Pick, SourceNo, Quantity, LotNo);
        RegisterWarehouseActivity(WarehouseActivityLine, WarehouseActivityLine."Source Document"::"Sales Order", SourceNo, WarehouseActivityLine."Activity Type"::Pick);
    end;

    local procedure POSTNegativeAdjustmentWithItemTracking(Item: Record Item; LocationCode: Code[10]; VariantCode: Code[10]; Qty: Decimal; PostingDate: Date; SerialNo: Code[50]; LotNo: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
            ItemJournalLine, ItemJournalBatch, Item,
            LocationCode, VariantCode, PostingDate,
            ItemJournalLine."Entry Type"::"Negative Adjmt.", Qty, 0);
        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservEntry, ItemJournalLine, SerialNo, LotNo, Qty);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure SetItemInventory(Item: Record Item; Quantity: Decimal)
    var
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        Item.TestField("No.");

        LibraryInventory.CreateItemJournalTemplate(ItemJnlTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJnlBatch, ItemJnlTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJnlTemplate.Name, ItemJnlBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);

        LibraryInventory.PostItemJournalLine(ItemJnlTemplate.Name, ItemJnlBatch.Name);
    end;

    local procedure OpenProductionJournal(No: Code[20])
    var
        ReleasedProductionOrder: TestPage "Released Production Order";
    begin
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", No);
        ReleasedProductionOrder.ProdOrderLines.ProductionJournal.Invoke();
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

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    var
        DequeueVariable: Variant;
        CreateNewLotNo: Boolean;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        CreateNewLotNo := DequeueVariable;
        EnterQuantityToCreate.CreateNewLotNo.SetValue(CreateNewLotNo);
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Quantity: Decimal;
        TrackingQtyToHandle: Decimal;
        TrackingQty: Decimal;
        NoOfTrackingLines: Integer;
        I: Integer;
        QtyVar: Variant;
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::"Assign Lot No.", ItemTrackingMode::"Assign Lot No. & Expiration Date":
                begin
                    ItemTrackingLines."Assign Lot No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Enqueue Lot No.
                end;
            ItemTrackingMode::"Assign Multiple Lot No.":
                begin
                    Quantity := ItemTrackingLines.Quantity3.AsDecimal();
                    CreateItemTrackingLine(ItemTrackingLines, Quantity / 2);  // Value required for test.
                    ItemTrackingLines.Next();
                    CreateItemTrackingLine(ItemTrackingLines, Quantity / 2);  // Value required for test.
                end;
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
            ItemTrackingMode::"Assign Serial No.":
                begin
                    LibraryVariableStorage.Enqueue(false);  // Enqueue for EnterQuantityToCreatePageHandler.
                    ItemTrackingLines."Assign Serial No.".Invoke();
                end;
            ItemTrackingMode::"Assign Lot And Serial":
                begin
                    LibraryVariableStorage.Enqueue(true);  // Enqueue for EnterQuantityToCreatePageHandler.
                    ItemTrackingLines."Assign Serial No.".Invoke();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Enqueue Lot No.
                end;
            ItemTrackingMode::"Blank Quantity Base":
                begin
                    ItemTrackingLines."Quantity (Base)".SetValue(0);
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(0);
                end;
            ItemTrackingMode::"Assign Manual Lot Nos":
                begin
                    NoOfTrackingLines := LibraryVariableStorage.DequeueInteger();
                    for I := 1 to NoOfTrackingLines do begin
                        ItemTrackingLines.New();
                        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    end;
                end;
            ItemTrackingMode::"Show Entries":
                begin
                    //Verify qty that has tracking
                    LibraryVariableStorage.Dequeue(QtyVar);  // Dequeue variable.
                    TrackingQtyToHandle := QtyVar;  // To convert Variant into Integer.
                    Assert.AreEqual(TrackingQtyToHandle, ItemTrackingLines.Handle1.AsDecimal(), 'Wrong quantity to handle on Item Tracking Lines page');

                    //Verify qty that should have tracking
                    LibraryVariableStorage.Dequeue(QtyVar);
                    TrackingQty := QtyVar;
                    Assert.AreEqual(TrackingQty, ItemTrackingLines.Quantity_ItemTracking.AsDecimal(), 'Wrong quantity using tracking on Item Tracking Lines page');
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
    procedure ReservationPageHandler(var Reservation: TestPage Reservation)
    var
        DequeueVariable: Variant;
        ReservationMode: Option "Reserve From Current Line","Reserve From First Line","Verify Reserve Line","Cancel Reservation Current Line";
        Quantity: Decimal;
        ReservedQuantity: Decimal;
        QtyAllocatedInWhse: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ReservationMode := DequeueVariable;
        case ReservationMode of
            ReservationMode::"Reserve From Current Line":
                Reservation."Reserve from Current Line".Invoke();
            ReservationMode::"Reserve From First Line":
                begin
                    Reservation.First();
                    Reservation."Reserve from Current Line".Invoke();
                end;
            ReservationMode::"Verify Reserve Line":
                begin
                    Quantity := LibraryVariableStorage.DequeueDecimal();
                    ReservedQuantity := LibraryVariableStorage.DequeueDecimal();
                    QtyAllocatedInWhse := LibraryVariableStorage.DequeueDecimal();
                    Reservation."Total Quantity".AssertEquals(Quantity);
                    Reservation.TotalReservedQuantity.AssertEquals(ReservedQuantity);  // Value required for test.
                    Reservation.QtyAllocatedInWarehouse.AssertEquals(QtyAllocatedInWhse);
                    Reservation."Current Reserved Quantity".AssertEquals(ReservedQuantity);  // Value required for test.
                end;
            ReservationMode::"Cancel Reservation Current Line":
                Reservation.CancelReservationCurrentLine.Invoke();
        end;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WarehouseChangeUnitOfMeasurePageHandler(var WhseChangeUnitOfMeasure: TestRequestPage "Whse. Change Unit of Measure")
    var
        DequeueVariable: Variant;
        UnitOfMeasureCode: Code[10];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        UnitOfMeasureCode := DequeueVariable;
        WhseChangeUnitOfMeasure.UnitOfMeasureCode.SetValue(UnitOfMeasureCode);
        WhseChangeUnitOfMeasure.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FiltersToGetSourceDocsPageHandler(var FiltersToGetSourceDocs: TestPage "Filters to Get Source Docs.")
    var
        DequeueVariable: Variant;
        FilterCode: Code[20];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        FilterCode := DequeueVariable;
        while FiltersToGetSourceDocs.Code.Value <> FilterCode do
            FiltersToGetSourceDocs.Next();
        FiltersToGetSourceDocs.Run.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FiltersToGetSourceDocsModifyActionPageHandler(var FiltersToGetSourceDocs: TestPage "Filters to Get Source Docs.")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        FiltersToGetSourceDocs.FILTER.SetFilter(Code, DequeueVariable);
        FiltersToGetSourceDocs.Modify.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SourceDocumentFilterCardPageHandler(var SourceDocumentFilterCard: TestPage "Source Document Filter Card")
    var
        DequeueVariable: Variant;
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        SourceDocumentFilterCard.FILTER.SetFilter("Shipment Date Filter", DequeueVariable);
        SourceDocumentFilterCard.FILTER.SetFilter("Receipt Date Filter", DequeueVariable);
        SourceDocumentFilterCard."Sales Orders".SetValue(false);
        SourceDocumentFilterCard.Run.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.First();
        ProductionJournal.Quantity.SetValue(LibraryRandom.RandIntInRange(200, 200));
        ProductionJournal.Next();
        ProductionJournal."Setup Time".SetValue(LibraryRandom.RandIntInRange(10, 10));
        ProductionJournal."Run Time".SetValue(LibraryRandom.RandIntInRange(10, 10));
        ProductionJournal."Output Quantity".SetValue(LibraryRandom.RandIntInRange(20, 20));
        ProductionJournal.Post.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure GLPostingPreviewPageHandler(var ShowAllEntries: TestPage "G/L Posting Preview")
    begin
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CloseGLPostingPreviewPageHandler(var GLPostingPreview: TestPage "G/L Posting Preview")
    begin
        GLPostingPreview.Close();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, LocalMessage) > 0, Message);
    end;

    [MessageHandler]
    procedure MessageHandlerNotext(Message: Text[1024])
    begin
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
}

